#!/usr/bin/with-contenv bashio

# Set log level from configuration
LOG_LEVEL=$(bashio::config 'log_level')
bashio::log.level "${LOG_LEVEL}"

bashio::log.info "Starting WaterFurnace Aurora MQTT Bridge..."
bashio::log.info "Log level set to: ${LOG_LEVEL}"

# Get configuration values
CONNECTION_TYPE=$(bashio::config 'connection_type')
SERIAL_PORT=$(bashio::config 'serial_port')
NETWORK_HOST=$(bashio::config 'network_host')
NETWORK_PORT=$(bashio::config 'network_port')
NETWORK_PROTOCOL=$(bashio::config 'network_protocol')
MQTT_HOST=$(bashio::config 'mqtt_host')
MQTT_PORT=$(bashio::config 'mqtt_port')
MQTT_USERNAME=$(bashio::config 'mqtt_username')
MQTT_PASSWORD=$(bashio::config 'mqtt_password')
MQTT_SSL=$(bashio::config 'mqtt_ssl')
WEB_AID_TOOL_PORT=$(bashio::config 'web_aid_tool_port')

# State directory for MQTT command tracking and crash-recovery replay.
# Lives in tmpfs; intentionally cleared on container restart.
STATE_DIR="/tmp/aurora_mqtt_state"
mkdir -p "$STATE_DIR"

# Shared mosquitto CLI connection args (listener + replay both use these).
MQTT_CLI_ARGS="-h ${MQTT_HOST} -p ${MQTT_PORT}"
[ -n "$MQTT_USERNAME" ] && MQTT_CLI_ARGS="${MQTT_CLI_ARGS} -u ${MQTT_USERNAME} -P ${MQTT_PASSWORD}"
[ "$MQTT_SSL" = "true" ] && MQTT_CLI_ARGS="${MQTT_CLI_ARGS} --capath /etc/ssl/certs"

# Construct MQTT URI
if [ -z "$MQTT_USERNAME" ]; then
    if [ "$MQTT_SSL" = "true" ]; then
        MQTT_URI="mqtts://${MQTT_HOST}:${MQTT_PORT}/"
    else
        MQTT_URI="mqtt://${MQTT_HOST}:${MQTT_PORT}/"
    fi
else
    # URL encode username and password
    ENCODED_USERNAME=$(echo -n "$MQTT_USERNAME" | jq -sRr @uri)
    ENCODED_PASSWORD=$(echo -n "$MQTT_PASSWORD" | jq -sRr @uri)
    
    if [ "$MQTT_SSL" = "true" ]; then
        MQTT_URI="mqtts://${ENCODED_USERNAME}:${ENCODED_PASSWORD}@${MQTT_HOST}:${MQTT_PORT}/"
    else
        MQTT_URI="mqtt://${ENCODED_USERNAME}:${ENCODED_PASSWORD}@${MQTT_HOST}:${MQTT_PORT}/"
    fi
fi

# Determine connection URI
if [ "$CONNECTION_TYPE" = "network" ]; then
    if [ -z "$NETWORK_HOST" ]; then
        bashio::log.error "Network connection type selected but network_host is empty!"
        exit 1
    fi
    CONNECTION_URI="${NETWORK_PROTOCOL}://${NETWORK_HOST}:${NETWORK_PORT}/"
    bashio::log.info "Connection: Network (${CONNECTION_URI})"
else
    CONNECTION_URI="${SERIAL_PORT}"
    bashio::log.info "Connection: Serial (${SERIAL_PORT})"
    
    # Check if serial port exists
    if [ ! -e "$SERIAL_PORT" ]; then
        bashio::log.warning "Serial port ${SERIAL_PORT} does not exist. Please check your configuration and hardware connection."
        bashio::log.warning "Available serial devices:"
        ls -la /dev/tty* 2>/dev/null || bashio::log.warning "No serial devices found"
    fi
fi

bashio::log.info "MQTT Host: ${MQTT_HOST}:${MQTT_PORT}"
bashio::log.info "MQTT SSL: ${MQTT_SSL}"
if [ -n "$MQTT_USERNAME" ]; then
    bashio::log.debug "MQTT Authentication: Enabled (username: ${MQTT_USERNAME})"
else
    bashio::log.debug "MQTT Authentication: Disabled"
fi

# Build command
CMD="aurora_mqtt_bridge ${CONNECTION_URI} ${MQTT_URI}"

# Add web AID tool if port is specified
if [ "$WEB_AID_TOOL_PORT" -gt 0 ]; then
    bashio::log.info "Enabling Web AID Tool on port ${WEB_AID_TOOL_PORT}"
    CMD="${CMD} --web-aid-tool=${WEB_AID_TOOL_PORT}"
    export APP_ENV=production
fi

bashio::log.info "Starting: ${CMD}"

# Internal watchdog HTTP server for Home Assistant
# This simple server responds to watchdog pings and monitors the bridge process
WATCHDOG_PORT=8099
bashio::log.info "Starting internal watchdog on port ${WATCHDOG_PORT}"

# Initialize PIDs to prevent unbound variable errors
CURRENT_BRIDGE_PID=""
MQTT_LISTENER_PID=""

# Start watchdog HTTP server in background
(
    while true; do
        # Simple HTTP server that responds with OK and checks if bridge is running
        echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 2\r\n\r\nOK" | \
            nc -l -p ${WATCHDOG_PORT} -q 1 >/dev/null 2>&1
        
        # Additional health check: verify bridge process is still alive
        # (This runs after each watchdog ping)
        if [ -n "$CURRENT_BRIDGE_PID" ] && ! kill -0 $CURRENT_BRIDGE_PID 2>/dev/null; then
            bashio::log.error "Watchdog detected bridge process died unexpectedly!"
        fi
    done
) &
WATCHDOG_PID=$!
bashio::log.info "Internal watchdog started (PID: ${WATCHDOG_PID})"

# -------------------------------------------------------------------
# mqtt_listener_loop
# Subscribes to all MQTT topics and persists the last value of any
# "set" topic (path segment IS "set" or starts with "set_"/"set/").
# These are the writable command topics aurora_mqtt_bridge listens on.
# Runs forever in the background; reconnects automatically after broker
# disconnects.  Written to STATE_DIR so replay_mqtt_commands can read
# them after a bridge crash.
# -------------------------------------------------------------------
mqtt_listener_loop() {
    bashio::log.info "MQTT command listener starting (broker: ${MQTT_HOST}:${MQTT_PORT})..."
    while true; do
        # shellcheck disable=SC2086
        mosquitto_sub ${MQTT_CLI_ARGS} -v -t '#' 2>/dev/null | \
        while IFS= read -r line; do
            # mosquitto_sub -v outputs: "<topic> <payload>" on one line.
            # MQTT topics cannot contain spaces, so splitting on the first
            # space is safe even when the payload contains spaces.
            topic="${line%% *}"
            payload="${line#"${topic}"}"
            payload="${payload# }"  # strip the single leading space
            # Match topics whose last (or only) path segment is "set",
            # starts with "set_", or starts with "set/".
            if echo "$topic" | grep -qE '(^|/)set([/_]|$)'; then
                safe_name=$(printf '%s' "$topic" | tr '/' '__' | tr -cs 'A-Za-z0-9._-' '_')
                printf '%s' "$payload" > "${STATE_DIR}/${safe_name}.val"
                printf '%s' "$topic"   > "${STATE_DIR}/${safe_name}.topic"
                bashio::log.debug "Tracked MQTT command: ${topic} = ${payload}"
            fi
        done
        # mosquitto_sub exited (broker disconnect / auth error).
        # Wait briefly before reconnecting to avoid spinning.
        sleep 5
    done
}

# -------------------------------------------------------------------
# replay_mqtt_commands
# Re-publishes every tracked "set" command with the retain flag so
# the bridge receives it immediately upon (re-)subscription, even if
# there is a brief timing gap between our publish and its subscribe.
# Call this a few seconds after a bridge restart.
# -------------------------------------------------------------------
replay_mqtt_commands() {
    local count=0
    for val_file in "${STATE_DIR}"/*.val; do
        [ -f "$val_file" ] || continue
        topic_file="${val_file%.val}.topic"
        [ -f "$topic_file" ] || continue
        local topic payload
        topic=$(cat "$topic_file")
        payload=$(cat "$val_file")
        bashio::log.info "Replaying MQTT command: ${topic} = ${payload}"
        # shellcheck disable=SC2086
        mosquitto_pub ${MQTT_CLI_ARGS} -r -t "$topic" -m "$payload" 2>/dev/null || \
            bashio::log.warning "Failed to replay command on topic: ${topic}"
        count=$((count + 1))
    done
    if [ "$count" -gt 0 ]; then
        bashio::log.info "Replayed ${count} MQTT command(s) after bridge restart"
    else
        bashio::log.debug "No MQTT commands to replay"
    fi
}

# Start MQTT command listener in the background
mqtt_listener_loop &
MQTT_LISTENER_PID=$!
bashio::log.info "MQTT command listener started (PID: ${MQTT_LISTENER_PID})"

# Disable Ruby warnings but ensure stdout/stderr are unbuffered for real-time logs
export RUBYOPT="-W0"
# Force Ruby to flush output immediately (unbuffered I/O)
export RUBY_IO_SYNC=1

# Enable detailed ModBus/serial communication logging
# This logs all bytes sent/received for RS-485 debugging
if [ "$LOG_LEVEL" = "debug" ] || [ "$LOG_LEVEL" = "trace" ]; then
    bashio::log.info "Debug mode enabled - logging all RS-485 communication"
    export MODBUS_DEBUG=1
    export RMODBUS_DEBUG=1
fi

# Start tcpdump for network traffic capture if using network mode
TCPDUMP_PID=""
if [ "$CONNECTION_TYPE" = "network" ] && [ "$LOG_LEVEL" = "debug" ]; then
    bashio::log.info "Starting network traffic capture for ${NETWORK_HOST}:${NETWORK_PORT}"
    # Capture traffic to/from the network adapter in the background
    tcpdump -i any -nn -X "host ${NETWORK_HOST} and port ${NETWORK_PORT}" 2>&1 | \
        while IFS= read -r line; do
            bashio::log.debug "[TCPDUMP] $line"
        done &
    TCPDUMP_PID=$!
    bashio::log.info "Network capture started (PID: ${TCPDUMP_PID})"
    sleep 1
fi

# For serial connections, enable strace to log all I/O operations in debug mode
STRACE_PREFIX=""
if [ "$CONNECTION_TYPE" = "serial" ] && [ "$LOG_LEVEL" = "debug" ]; then
    bashio::log.info "Enabling serial I/O tracing for ${SERIAL_PORT}"
    STRACE_PREFIX="strace -e trace=read,write,ioctl -s 1024 -xx"
fi

# Function to process log lines and ensure proper formatting for Home Assistant
process_logs() {
    while IFS= read -r line; do
        # Skip empty lines
        [ -z "$line" ] && continue
        
        # Check log level indicators in the output
        if echo "$line" | grep -qiE '(ERROR|FATAL|error:|failed)'; then
            bashio::log.error "$line"
        elif echo "$line" | grep -qiE '(WARN|WARNING|warn:)'; then
            bashio::log.warning "$line"
        elif echo "$line" | grep -qiE '(DEBUG|debug:)'; then
            bashio::log.debug "$line"
        else
            # Default to info level for all other output
            bashio::log.info "$line"
        fi
    done
}

bashio::log.info "Launching Aurora MQTT Bridge..."
bashio::log.info "Full command: $STRACE_PREFIX $CMD"

# Check if the command exists
if ! command -v aurora_mqtt_bridge &> /dev/null; then
    bashio::log.error "aurora_mqtt_bridge command not found! Check gem installation."
    exit 1
fi

# Log environment variables that affect output
bashio::log.debug "Environment: RUBYOPT=${RUBYOPT}, RUBY_IO_SYNC=${RUBY_IO_SYNC}"

# Automatic reconnection loop.
# The dominant failure is a TCP idle-timeout reset from the serial bridge
# (every ~300 s of inactivity).  For the first 3 consecutive failures we
# use a short 2-second fixed delay so the bridge comes back almost
# instantly.  Only after 3 consecutive failures do we apply exponential
# backoff (30 s, 60 s, 120 s … up to 300 s) to avoid hammering a
# genuinely broken connection.
RETRY_COUNT=0
MAX_RETRY_DELAY=300  # Maximum 5 minutes between retries
CONSECUTIVE_FAILURES=0  # Track consecutive failures for backoff

while true; do
    # Apply restart delay (skipped on the very first start)
    if [ "$CONSECUTIVE_FAILURES" -gt 0 ]; then
        if [ "$CONSECUTIVE_FAILURES" -le 3 ]; then
            # Short fixed delay: almost certainly a TCP idle-timeout reset.
            RETRY_DELAY=2
            bashio::log.info "Bridge disconnected (failure ${CONSECUTIVE_FAILURES}); restarting in ${RETRY_DELAY}s..."
        else
            # Exponential backoff for persistent failures: 30 s, 60 s, 120 s … 300 s
            RETRY_DELAY=$((30 * (2 ** (CONSECUTIVE_FAILURES - 4))))
            if [ "$RETRY_DELAY" -gt "$MAX_RETRY_DELAY" ]; then
                RETRY_DELAY=$MAX_RETRY_DELAY
            fi
            bashio::log.warning "Persistent failure (${CONSECUTIVE_FAILURES} consecutive). Waiting ${RETRY_DELAY}s before retry #$((RETRY_COUNT + 1))..."
        fi
        sleep "$RETRY_DELAY"
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    
    # For network connections, verify host is reachable before attempting connection
    if [ "$CONNECTION_TYPE" = "network" ]; then
        bashio::log.info "Testing network connectivity to ${NETWORK_HOST}..."
        if ! ping -c 1 -W 3 "$NETWORK_HOST" >/dev/null 2>&1; then
            bashio::log.warning "Network host ${NETWORK_HOST} is unreachable (attempt #${RETRY_COUNT})"
            CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
            continue
        fi
        bashio::log.info "Network host ${NETWORK_HOST} is reachable"
    fi
    
    bashio::log.info "Starting Aurora MQTT Bridge (attempt #${RETRY_COUNT})..."
    
    # Run the bridge with unbuffered output and pipe through log processor
    # stdbuf -oL forces line-buffered output, -eL for stderr
    # Add strace prefix for serial debugging if enabled
    if [ -n "$STRACE_PREFIX" ]; then
        bashio::log.info "Running with strace for serial debugging..."
        stdbuf -oL -eL $STRACE_PREFIX $CMD 2>&1 | process_logs &
    else
        # Run without strace but ensure unbuffered output
        stdbuf -oL -eL sh -c "$CMD 2>&1" | process_logs &
    fi
    BRIDGE_PID=$!
    CURRENT_BRIDGE_PID=$BRIDGE_PID  # Make available to watchdog
    
    # Brief pause to detect immediate crashes before declaring success.
    sleep 2

    # Check if process is still running
    if kill -0 $BRIDGE_PID 2>/dev/null; then
        bashio::log.info "Bridge process started successfully (PID: ${BRIDGE_PID}, attempt #${RETRY_COUNT})"
        # Reset consecutive failures on successful start
        CONSECUTIVE_FAILURES=0

        # After a restart, replay the last-known MQTT set commands so any
        # in-flight write that was interrupted by the crash is not silently
        # lost.  We wait 8 s to give the bridge time to connect and
        # subscribe before we publish.  Runs in a subshell so it does not
        # block the wait below.
        if [ "$RETRY_COUNT" -gt 1 ]; then
            (sleep 8 && replay_mqtt_commands) &
        fi

        # Wait for the process to complete
        wait $BRIDGE_PID
        EXIT_CODE=$?
        
        bashio::log.warning "Aurora MQTT Bridge exited with code ${EXIT_CODE}"
        
        # If exit code is 0, it was a clean shutdown - don't retry
        if [ $EXIT_CODE -eq 0 ]; then
            bashio::log.info "Clean shutdown detected, exiting..."
            break
        fi
        
        # Process ran but exited unexpectedly - increment failure counter
        CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
        bashio::log.warning "Unexpected exit detected, will attempt to reconnect..."
    else
        # Process failed to start or crashed immediately
        CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
        bashio::log.error "Bridge process failed to start or exited immediately (attempt #${RETRY_COUNT})"
        if [ "$CONNECTION_TYPE" = "network" ]; then
            bashio::log.error "Common causes: Network adapter unreachable, wrong IP/port, firewall blocking connection"
        else
            bashio::log.error "Common causes: Serial device not found, wrong device path, permissions issue"
        fi
    fi
done

# Cleanup
bashio::log.info "Shutting down..."

# Stop watchdog
if [ -n "$WATCHDOG_PID" ] && kill -0 $WATCHDOG_PID 2>/dev/null; then
    bashio::log.info "Stopping internal watchdog..."
    kill $WATCHDOG_PID 2>/dev/null || true
fi

# Stop MQTT command listener
if [ -n "$MQTT_LISTENER_PID" ] && kill -0 $MQTT_LISTENER_PID 2>/dev/null; then
    bashio::log.info "Stopping MQTT command listener..."
    kill $MQTT_LISTENER_PID 2>/dev/null || true
fi

# Stop tcpdump if it was started
if [ -n "$TCPDUMP_PID" ] && kill -0 $TCPDUMP_PID 2>/dev/null; then
    bashio::log.info "Stopping network capture..."
    kill $TCPDUMP_PID 2>/dev/null || true
fi

exit ${EXIT_CODE:-1}
