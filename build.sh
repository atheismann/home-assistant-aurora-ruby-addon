#!/usr/bin/env bash
set -e

# Build script for local testing
docker build -t local/waterfurnace-aurora .

echo "Build complete! You can now run the addon with:"
echo "docker run --rm --device=/dev/ttyUSB0 -e SERIAL_PORT=/dev/ttyUSB0 -e MQTT_HOST=<your-mqtt-host> local/waterfurnace-aurora"
