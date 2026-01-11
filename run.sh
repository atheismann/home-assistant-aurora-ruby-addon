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

# Automatic reconnection with exponential backoff
RETRY_COUNT=0
MAX_RETRY_DELAY=300  # Maximum 5 minutes between retries
INITIAL_RETRY_DELAY=5  # Start with 5 seconds

while true; do
    if [ $RETRY_COUNT -gt 0 ]; then
        # Calculate exponential backoff delay (doubles each time, up to max)
        RETRY_DELAY=$((INITIAL_RETRY_DELAY * (2 ** (RETRY_COUNT - 1))))
        if [ $RETRY_DELAY -gt $MAX_RETRY_DELAY ]; then
            RETRY_DELAY=$MAX_RETRY_DELAY
        fi
        
        bashio::log.warning "Connection lost. Retry attempt #${RETRY_COUNT} in ${RETRY_DELAY} seconds..."
        sleep $RETRY_DELAY
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    
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
    
    # Wait a moment to see if it starts successfully
    sleep 2
    
    # Check if process is still running
    if kill -0 $BRIDGE_PID 2>/dev/null; then
        bashio::log.info "Bridge process started successfully (PID: ${BRIDGE_PID}, attempt #${RETRY_COUNT})"
        # Reset retry count on successful start
        RETRY_COUNT=0
        
        # Wait for the process to complete
        wait $BRIDGE_PID
        EXIT_CODE=$?
        
        bashio::log.warning "Aurora MQTT Bridge exited with code ${EXIT_CODE}"
        
        # If exit code is 0, it was a clean shutdown - don't retry
        if [ $EXIT_CODE -eq 0 ]; then
            bashio::log.info "Clean shutdown detected, exiting..."
            break
        fi
        
        # Otherwise, will retry after backoff
        bashio::log.warning "Unexpected exit detected, will attempt to reconnect..."
    else
        bashio::log.error "Bridge process failed to start or exited immediately (attempt #${RETRY_COUNT})"
    fi
done

# Stop tcpdump if it was started
if [ -n "$TCPDUMP_PID" ] && kill -0 $TCPDUMP_PID 2>/dev/null; then
    bashio::log.info "Stopping network capture..."
    kill $TCPDUMP_PID 2>/dev/null || true
fi

exit ${EXIT_CODE:-1}
