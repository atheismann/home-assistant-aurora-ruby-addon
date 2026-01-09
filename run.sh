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

# Function to process log lines and ensure proper formatting for Home Assistant
process_logs() {
    while IFS= read -r line; do
        # Check log level indicators in the output
        if echo "$line" | grep -qiE '^\s*(ERROR|FATAL)'; then
            bashio::log.error "$line"
        elif echo "$line" | grep -qiE '^\s*(WARN|WARNING)'; then
            bashio::log.warning "$line"
        elif echo "$line" | grep -qiE '^\s*(DEBUG)'; then
            bashio::log.debug "$line"
        else
            # Default to info level for all other output
            bashio::log.info "$line"
        fi
    done
}

# Run the bridge and pipe all output through log processor
# This ensures all stdout/stderr is captured at info level or higher
$CMD 2>&1 | process_logs

# If the bridge exits, log it and exit with the same code
EXIT_CODE=${PIPESTATUS[0]}
bashio::log.warning "Aurora MQTT Bridge exited with code ${EXIT_CODE}"
exit $EXIT_CODE
