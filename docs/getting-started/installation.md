# Installation Guide

This guide will walk you through installing and configuring the Aurora MQTT Gateway add-on.

## Prerequisites

Before starting, ensure you have completed:

- ✅ [Prerequisites](prerequisites.md) - System requirements verified
- ✅ [Hardware Setup](hardware.md) - Cable created and connected
- ✅ [MQTT Setup](mqtt-setup.md) - Mosquitto broker installed

## Installation Methods

### Method 1: Add-on Store (Recommended)

1. In Home Assistant, navigate to **Settings** → **Add-ons**
2. Click the **Add-on Store** button (bottom right)
3. Click the three dots (⋮) in the top right corner
4. Select **Repositories**
5. Add this repository URL:

   ```
   https://github.com/atheismann/home-assistant-aurora-ruby-addon
   ```

6. The add-on should now appear in your store
7. Click on **Aurora MQTT Gateway**
8. Click **Install**
9. Wait for installation to complete (may take several minutes)

### Method 2: Manual Installation

If the add-on store method doesn't work:

1. SSH into your Home Assistant host
2. Navigate to the add-ons directory:

   ```bash
   cd /addons
   ```

3. Clone the repository:

   ```bash
   git clone https://github.com/atheismann/home-assistant-aurora-ruby-addon.git aurora-mqtt-gateway
   ```

4. The add-on should now appear in **Settings** → **Add-ons** → **Local add-ons**

## Configuration

### Serial Connection Configuration

For **USB RS-485 adapters**:

```yaml
connection_type: serial
serial_port: /dev/ttyUSB0
mqtt_host: core-mosquitto
mqtt_port: 1883
mqtt_username: homeassistant
mqtt_password: your_secure_password_here
log_level: info
```

**Configuration details:**

- **connection_type**: Must be `serial`
- **serial_port**: Device path (usually `/dev/ttyUSB0`, check with `ls /dev/ttyUSB*`)
- **mqtt_host**: Use `core-mosquitto` for built-in broker
- **mqtt_port**: Default is `1883`
- **mqtt_username/password**: From your MQTT setup
- **log_level**: `info` for normal operation, `debug` for troubleshooting

### Network Connection Configuration

For **Waveshare or network RS-485 adapters**:

```yaml
connection_type: network
network_host: 192.168.1.100
network_port: 8899
network_protocol: tcp
mqtt_host: core-mosquitto
mqtt_port: 1883
mqtt_username: homeassistant
mqtt_password: your_secure_password_here
log_level: info
```

**Configuration details:**

- **connection_type**: Must be `network`
- **network_host**: IP address of your adapter
- **network_port**: Port configured in adapter (default `8899` for Waveshare)
- **network_protocol**: Either `tcp` or `telnet` (use `tcp` for Waveshare)
- **mqtt_host**: Use `core-mosquitto` for built-in broker
- **mqtt_port**: Default is `1883`
- **mqtt_username/password**: From your MQTT setup
- **log_level**: `info` for normal operation, `debug` for troubleshooting

**For Waveshare adapters**, you must also configure the adapter itself. See:

- **[Network Adapters Configuration Guide](../configuration/network-adapters.md)** - Complete Waveshare setup

### Configuration Options Reference

All available configuration options:

| Option              | Type    | Required | Default         | Description                                    |
|---------------------|---------|----------|-----------------|------------------------------------------------|
| connection_type     | string  | Yes      | -               | `serial` or `network`                          |
| serial_port         | string  | If serial| -               | Device path (e.g., `/dev/ttyUSB0`)             |
| network_host        | string  | If network| -              | IP address of network adapter                  |
| network_port        | int     | If network| 8899           | TCP/Telnet port of network adapter             |
| network_protocol    | string  | If network| tcp            | Protocol: `tcp` or `telnet`                    |
| mqtt_host           | string  | Yes      | core-mosquitto  | MQTT broker hostname                           |
| mqtt_port           | int     | No       | 1883            | MQTT broker port                               |
| mqtt_username       | string  | Yes      | -               | MQTT username                                  |
| mqtt_password       | password| Yes      | -               | MQTT password                                  |
| web_aid_tool_port   | int     | No       | 8080            | Port for debug web interface                   |
| log_level           | string  | No       | info            | Log level: trace/debug/info/notice/warning/error/fatal |

### Log Levels

Choose the appropriate log level for your needs:

- **trace**: Extremely verbose, every operation logged
- **debug**: Detailed logging including RS-485 communication packets (see [Debug RS-485](../troubleshooting/debug-rs485.md))
- **info**: Normal operational logs (recommended)
- **notice**: Important events
- **warning**: Warning messages only
- **error**: Error messages only
- **fatal**: Only critical failures

## Starting the Add-on

1. In Home Assistant, go to **Settings** → **Add-ons**
2. Click on **Aurora MQTT Gateway**
3. Click the **Start** button
4. Monitor the **Log** tab for startup messages

### Expected Startup Log

```
[INFO] Starting Aurora MQTT Gateway...
[INFO] Connection Type: serial
[INFO] Serial Port: /dev/ttyUSB0
[INFO] MQTT Host: core-mosquitto:1883
[INFO] Log Level: info
[INFO] Starting waterfurnace_aurora2mqtt...
[INFO] Connected to MQTT broker
[INFO] Connected to heat pump
[INFO] Publishing sensor data...
```

### Common Startup Issues

**Error: "Could not open serial port"**

- Check that `serial_port` matches your device (`ls /dev/ttyUSB*`)
- Verify USB adapter is connected
- Try unplugging and replugging USB adapter
- See [Troubleshooting](../troubleshooting/)

**Error: "Connection refused" (network mode)**

- Verify `network_host` IP address is correct
- Verify `network_port` matches adapter configuration
- Ensure adapter is powered and on same network
- Try pinging adapter: `ping <network_host>`

**Error: "ModBus timeout"**

- Check physical cable connections
- Verify adapter serial parameters (19200 8E1 for network adapters)
- Try reversing A+ and B- connections
- See [Debug RS-485](../troubleshooting/debug-rs485.md)

**Error: "MQTT connection failed"**

- Verify MQTT broker is running (**Settings** → **Add-ons** → **Mosquitto broker**)
- Check `mqtt_username` and `mqtt_password` are correct
- Ensure `mqtt_host` is `core-mosquitto` for built-in broker
- See [MQTT Setup](mqtt-setup.md)

## Verification

### Check MQTT Messages

Use MQTT Explorer or command line:

```bash
# Install mosquitto clients
sudo apt-get install mosquitto-clients

# Subscribe to all aurora topics
mosquitto_sub -h localhost -u homeassistant -P your_password -t 'homie/aurora/#' -v
```

You should see messages like:

```
homie/aurora/$homie 4.0
homie/aurora/$name WaterFurnace Aurora Heat Pump
homie/aurora/$state ready
homie/aurora/heat-pump/lockout-temp $name Lockout Temperature
homie/aurora/heat-pump/lockout-temp $datatype float
homie/aurora/heat-pump/lockout-temp 15.5
...
```

### Check Home Assistant Entities

1. Navigate to **Settings** → **Devices & Services**
2. Look for **MQTT** integration
3. Click on **MQTT**
4. You should see a device: **WaterFurnace Aurora Heat Pump**
5. Click on the device to see all sensors

**Expected entities include:**

- Temperatures: Entering water, leaving water, outdoor, lockout
- System status: Mode, zones, heating, cooling
- Compressor: Speed, power, amperage
- Pump/fan: Speed and power
- Energy: Daily, monthly readings

### Test Web AID Tool (Optional)

The add-on includes a debug web interface:

1. Open browser to: `http://<home-assistant-ip>:8080`
   - Default port is `8080`
   - Change with `web_aid_tool_port` option
2. You should see heat pump data in JSON format
3. This is useful for debugging

## Enable Auto-Start

Once verified working:

1. In Home Assistant, go to **Settings** → **Add-ons**
2. Click on **Aurora MQTT Gateway**
3. Click the **Configuration** tab
4. Enable:
   - ✅ **Start on boot**
   - ✅ **Watchdog** (auto-restart on crash)
   - ✅ **Auto update** (optional, for automatic updates)
5. Click **Save**

## Optional: Device Configuration

### Customize Device Name

By default, the device appears as "WaterFurnace Aurora Heat Pump". To customize:

1. Navigate to **Settings** → **Devices & Services** → **MQTT**
2. Click on the Aurora device
3. Click the gear icon (⚙️)
4. Change **Name**
5. Click **Update**

### Disable Unused Entities

If you don't need certain sensors:

1. Navigate to device page (as above)
2. Find the entity you want to disable
3. Click on the entity
4. Click the gear icon (⚙️)
5. Toggle **Enable** off
6. Click **Update**

### Add Device to Dashboard

1. Navigate to **Overview** dashboard
2. Click the three dots (⋮) → **Edit Dashboard**
3. Click **Add Card**
4. Search for entities starting with `sensor.aurora_`
5. Add desired entities to your dashboard

## What's Next?

- **[Configuration Details](../configuration/)** - Fine-tune settings
- **[Troubleshooting](../troubleshooting/)** - Solve common problems
- **[Dashboard Examples](#)** - Example Lovelace cards (coming soon)

## Additional Help

- **GitHub Issues**: [Report bugs or request features](https://github.com/atheismann/home-assistant-aurora-ruby-addon/issues)
- **Logging**: See [Troubleshooting Logging](../troubleshooting/logging.md)
- **RS-485 Debug**: See [Debug RS-485](../troubleshooting/debug-rs485.md)
