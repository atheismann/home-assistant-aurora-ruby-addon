# Troubleshooting Guide

This section helps you diagnose and fix common issues with the Aurora MQTT Gateway.

## Quick Links

- **[Connection Issues](connection-issues.md)** - Can't connect to heat pump
- **[RS-485 Communication](debug-rs485.md)** - Debugging RS-485 protocol issues
- **[Logging Problems](logging.md)** - Log output issues and interpretation
- **[MQTT Issues](mqtt-issues.md)** - MQTT broker connection and discovery problems

## Common Problems

### Add-on Won't Start

**Symptoms**: Add-on shows stopped, logs show configuration error

**Solutions**:

1. **Check configuration validation**:
   - View add-on logs for validation errors
   - Ensure all required fields are present
   - Verify YAML syntax (indentation matters)

2. **Common configuration errors**:
   - `connection_type` must be `serial` or `network` (lowercase)
   - `serial_port` required if using serial mode
   - `network_host` required if using network mode
   - Port numbers must be 1-65535

3. **Fix and restart**:
   - Correct configuration errors
   - Click **Save**
   - Click **Start**

### Can't Connect to Heat Pump

See **[Connection Issues](connection-issues.md)** for detailed troubleshooting.

**Quick checks:**

- Serial mode: Check USB device exists (`ls /dev/ttyUSB*`)
- Network mode: Ping adapter (`ping <network_host>`)
- Verify cable connections
- Try reversing A+/B- connections

### No Entities in Home Assistant

**Symptoms**: Add-on running, but no Aurora entities appear

**Solutions**:

1. **Check MQTT connection**:
   - Verify Mosquitto broker is running
   - Check add-on logs for "Connected to MQTT"
   - See **[MQTT Issues](mqtt-issues.md)**

2. **Check MQTT integration**:
   - **Settings** → **Devices & Services** → **MQTT**
   - Should show "Connected"
   - If not, reconfigure integration

3. **Verify topics are published**:

   ```bash
   mosquitto_sub -h core-mosquitto -u homeassistant -P your_password -t 'homie/aurora/#' -v
   ```

   - Should see messages
   - If not, add-on isn't publishing

4. **Restart Home Assistant**:
   - Sometimes needed for discovery
   - **Settings** → **System** → **Restart**

### Entities Show "Unavailable"

**Symptoms**: Entities exist but show unavailable or old data

**Solutions**:

1. **Check add-on is running**:
   - **Settings** → **Add-ons** → **Aurora MQTT Gateway**
   - Should show "Running"
   - Check logs for errors

2. **Check heat pump connection**:
   - Look for "Connected to heat pump" in logs
   - If connection lost, see [Connection Issues](connection-issues.md)

3. **Check MQTT connection**:
   - Look for "Connected to MQTT broker" in logs
   - If connection lost, see [MQTT Issues](mqtt-issues.md)

4. **Restart add-on**:
   - Sometimes fixes transient issues
   - Click **Restart**

### ModBus Timeout Errors

**Symptoms**: Logs show "ModBus timeout" or "No response from heat pump"

**This is the most common issue.** See:

- **[RS-485 Communication](debug-rs485.md)** - Detailed debugging guide
- **[Connection Issues](connection-issues.md)** - Physical connection troubleshooting

**Quick fixes to try**:

1. **Reverse A+/B- connections** (polarity is often confusing)
2. **Check serial parameters** (network mode: must be 19200 8E1)
3. **Verify cable** (pins 5-8 should NOT be connected)
4. **Enable debug logging** (set `log_level: debug`)

### Wrong Sensor Values

**Symptoms**: Temperatures or values seem incorrect

**Solutions**:

1. **Check units**:
   - Temperatures are in Celsius
   - Convert to Fahrenheit in Home Assistant if needed
   - Add template sensors for conversion

2. **Verify with AID Tool**:
   - Access web interface: `http://<home-assistant-ip>:8080`
   - Compare values with heat pump display
   - If web interface shows correct values, issue is in Home Assistant

3. **Check sensor entity**:
   - Navigate to **Developer Tools** → **States**
   - Find entity (e.g., `sensor.aurora_entering_water_temperature`)
   - Check `unit_of_measurement` attribute

## Diagnostic Steps

### Step 1: Check Add-on Status

1. Navigate to **Settings** → **Add-ons** → **Aurora MQTT Gateway**
2. Check status: Should show "Running"
3. If stopped, click **Start** and watch logs

### Step 2: Review Logs

1. Click **Log** tab in add-on
2. Look for errors (red text)
3. Common log messages:

   **Good**:

   ```
   [INFO] Starting Aurora MQTT Gateway...
   [INFO] Connected to MQTT broker
   [INFO] Connected to heat pump
   [INFO] Publishing sensor data...
   ```

   **Bad**:

   ```
   [ERROR] Could not open serial port /dev/ttyUSB0
   [ERROR] Connection refused (MQTT)
   [ERROR] ModBus timeout
   ```

### Step 3: Enable Debug Logging

For detailed diagnostics:

1. Edit add-on configuration
2. Set `log_level: debug`
3. Save and restart add-on
4. Watch logs for detailed output
5. See **[RS-485 Debug Guide](debug-rs485.md)** for interpreting debug output

### Step 4: Test Components Independently

**Test MQTT**:

```bash
mosquitto_sub -h core-mosquitto -u homeassistant -P your_password -t 'homie/aurora/#' -v
```

**Test heat pump connection**:

- Access web interface: `http://<home-assistant-ip>:8080`
- Should show JSON data if connected

**Test RS-485 adapter**:

- Serial: Check device exists (`ls /dev/ttyUSB*`)
- Network: Ping adapter (`ping <network_host>`)

### Step 5: Check Physical Connections

1. **Verify cable**:
   - RJ45 firmly seated in heat pump AID Tool port
   - Terminal screws tight on adapter
   - Unused wires (pins 5-8) capped

2. **Verify adapter**:
   - LED indicators (if present) should be lit
   - Power connected
   - USB/network cable connected

3. **Try swapping A+/B-**:
   - RS-485 polarity can be confusing
   - Swapping connections is safe
   - May fix "ModBus timeout" errors

## Getting Help

### Gathering Information

Before opening an issue, gather:

1. **Configuration**:
   - Connection type (serial or network)
   - Add-on version (see add-on info page)
   - Home Assistant version

2. **Logs**:
   - Full add-on log with `log_level: debug`
   - Relevant errors

3. **Environment**:
   - Home Assistant install method (OS, Supervised, Container)
   - USB adapter model (if serial)
   - Network adapter model (if network)

### Opening an Issue

1. Go to: <https://github.com/atheismann/home-assistant-aurora-ruby-addon/issues>
2. Click **New Issue**
3. Provide:
   - Clear description of problem
   - Steps to reproduce
   - Configuration (redact passwords)
   - Relevant logs
   - Environment details

### Community Help

- **Home Assistant Community**: <https://community.home-assistant.io/>
- **GitHub Discussions**: <https://github.com/atheismann/home-assistant-aurora-ruby-addon/discussions>

## Related Documentation

- **[Connection Issues](connection-issues.md)** - Detailed connection troubleshooting
- **[Debug RS-485](debug-rs485.md)** - RS-485 protocol debugging
- **[Logging Guide](logging.md)** - Understanding log output
- **[MQTT Issues](mqtt-issues.md)** - MQTT troubleshooting
- **[Configuration](../configuration/)** - Configuration reference
- **[Hardware Setup](../getting-started/hardware.md)** - Cable and connection guide
