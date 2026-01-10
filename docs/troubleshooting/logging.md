# Troubleshooting Logging Issues

## Problem: Not Seeing Logs After Start Commands

If you see the initial startup logs but nothing after "Starting: aurora_mqtt_bridge...", here are the possible causes and solutions:

### 1. Check if the Bridge is Actually Running

**Via Home Assistant UI:**
- Go to Settings → Add-ons → WaterFurnace Aurora
- Check if the add-on shows as "Running" (green)
- Click the "Log" tab and look for any error messages

**Check the full logs:**
```bash
# SSH into Home Assistant or use Terminal add-on
docker logs addon_SLUG_NAME -f
```

### 2. Verify the Ruby Gem is Installed

The add-on relies on the `waterfurnace_aurora` gem. If it's not installed correctly, you'll see no output.

**Check installation:**
- Look in logs for: "aurora_mqtt_bridge command not found"
- This means the Docker build failed or the gem didn't install

**Solution:** Rebuild the add-on
1. Settings → Add-ons → WaterFurnace Aurora
2. Click the three dots menu → "Rebuild"
3. Wait for rebuild to complete
4. Restart the add-on

### 3. Connection Issues

The Ruby bridge might be failing to connect silently.

**For Serial Connection:**
- Check that your RS-485 adapter is plugged in
- Verify the serial port exists: `/dev/ttyUSB0`
- Look for warning: "Serial port does not exist"

**For Network Connection:**
- Verify you can ping the Waveshare device
- Check the IP address and port are correct
- Ensure the device is in TCP Server mode

### 4. MQTT Connection Issues

If MQTT broker is unreachable, the bridge may hang or fail silently.

**Check MQTT Broker:**
```bash
# From Home Assistant terminal
docker ps | grep mosquitto
# Should show running mosquitto container
```

**Verify MQTT credentials:**
- If using authentication, credentials must be correct
- Try without authentication first to test

**Test MQTT connectivity:**
```bash
# Install mosquitto clients if needed
apk add mosquitto-clients

# Test connection
mosquitto_pub -h core-mosquitto -p 1883 -t test -m "hello"
```

### 5. Enable Debug Logging

To see more detailed information:

1. Go to add-on Configuration
2. Change `log_level` from `info` to `debug`
3. Save and restart the add-on
4. Check logs again

Example config:
```yaml
log_level: debug
```

### 6. Test Logging Functionality

To verify the logging mechanism works, you can temporarily modify the command:

**SSH into the container:**
```bash
# Find the container ID
docker ps | grep waterfurnace

# Enter the container
docker exec -it CONTAINER_ID /bin/bash

# Test the logging pipeline
echo "Test message" | while IFS= read -r line; do echo "INFO: $line"; done
```

### 7. Check for Ruby Buffering Issues

Ruby may buffer output. The updated run.sh includes fixes for this:
- Sets `RUBYOPT="-W0"` to disable warnings
- Uses `stdbuf -oL -eL` to force line buffering
- Requires `coreutils` package (should be in Dockerfile)

### 8. Manual Test of the Bridge

Try running the bridge command directly to see raw output:

```bash
# SSH into add-on container
docker exec -it addon_ADDON_SLUG /bin/bash

# Run the bridge directly
aurora_mqtt_bridge /dev/ttyUSB0 mqtt://core-mosquitto:1883/
# Or for network:
aurora_mqtt_bridge tcp://192.168.1.100:2000/ mqtt://core-mosquitto:1883/
```

You should see output like:
```
Connected to heat pump
Publishing to MQTT...
Reading data...
```

### 9. Common Error Messages

**"Network connection type selected but network_host is empty"**
- Fill in the network_host field in configuration

**"Serial port /dev/ttyUSB0 does not exist"**
- Check Hardware tab: is the serial adapter listed?
- Try unplugging and replugging the USB adapter
- Try a different USB port
- Check if driver is loaded: `ls -la /dev/tty*`

**"Connection refused"**
- MQTT broker not running or wrong host/port
- For network mode: Waveshare device unreachable

**"aurora_mqtt_bridge command not found"**
- Gem installation failed
- Rebuild the add-on

### 10. Check Recent Changes

If logging worked before but stopped:
- Did you update the add-on?
- Did you change any configuration?
- Did you restart Home Assistant?
- Check if the problem appeared after any recent commits

### 11. Review Build Logs

When the add-on builds, check for errors:

1. Settings → Add-ons → WaterFurnace Aurora
2. Three dots menu → "Rebuild"  
3. Watch the build output for errors
4. Look for failed gem installations
5. Check for missing dependencies

### 12. Fallback: Simplified Logging

If all else fails, you can temporarily simplify the logging in run.sh:

```bash
# Replace the complex logging with simple echo
exec aurora_mqtt_bridge ${CONNECTION_URI} ${MQTT_URI}
```

This removes the log processing and shows raw output.

## Getting More Help

If you're still stuck:

1. **Collect information:**
   - Full add-on logs (with debug enabled)
   - Add-on configuration (redact passwords)
   - Home Assistant version
   - Hardware being used (USB adapter or Waveshare model)
   - Any error messages

2. **Check GitHub Issues:**
   - Search existing issues: https://github.com/atheismann/home-assistant-aurora-ruby-addon/issues
   - Look for similar problems

3. **Create a new issue:**
   - Include all information from step 1
   - Describe what you've already tried
   - Include any error messages verbatim

## Expected Log Output

When working correctly, you should see:

```
[INFO] Starting WaterFurnace Aurora MQTT Bridge...
[INFO] Log level set to: info
[INFO] Connection: Serial (/dev/ttyUSB0)
[INFO] MQTT Host: core-mosquitto:1883
[INFO] MQTT SSL: false
[INFO] Starting: aurora_mqtt_bridge /dev/ttyUSB0 mqtt://core-mosquitto:1883/
[INFO] Launching Aurora MQTT Bridge...
[INFO] Bridge process started successfully (PID: 123)
[INFO] Connected to heat pump on /dev/ttyUSB0
[INFO] MQTT connection established
[INFO] Publishing device info...
[INFO] Starting data collection loop...
[INFO] Reading data from heat pump...
[INFO] Publishing to homie/waterfurnace_aurora/...
```

And then periodic updates as data is published.
