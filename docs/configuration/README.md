# Configuration Guide

This section provides detailed information about configuring the Aurora MQTT Gateway add-on.

## Quick Links

- **[Basic Configuration](basic.md)** - Core add-on settings and options
- **[Network Adapters](network-adapters.md)** - Complete Waveshare setup guide
- **[MQTT Configuration](mqtt.md)** - MQTT broker setup and troubleshooting
- **[Advanced Settings](advanced.md)** - Web AID Tool, debugging, and advanced options

## Configuration File

The add-on is configured through the Home Assistant UI:

1. Navigate to **Settings** → **Add-ons**
2. Click on **Aurora MQTT Gateway**
3. Click the **Configuration** tab
4. Edit the YAML configuration
5. Click **Save**
6. Restart the add-on for changes to take effect

## Configuration Schema

All configuration is validated against a schema. If you enter invalid values, the add-on will not start and will show an error in the log.

### Required Fields

These fields must be configured:

- **connection_type**: `serial` or `network`
- **mqtt_username**: Your MQTT username
- **mqtt_password**: Your MQTT password

### Connection-Specific Fields

**If using serial connection**:

- **serial_port**: Device path (e.g., `/dev/ttyUSB0`)

**If using network connection**:

- **network_host**: IP address of adapter
- **network_port**: Port number (default `8899`)
- **network_protocol**: `tcp` or `telnet`

### Optional Fields

These have sensible defaults but can be customized:

- **mqtt_host**: Default `core-mosquitto`
- **mqtt_port**: Default `1883`
- **web_aid_tool_port**: Default `8080`
- **log_level**: Default `info`

## Common Configurations

### Serial USB Adapter

```yaml
connection_type: serial
serial_port: /dev/ttyUSB0
mqtt_host: core-mosquitto
mqtt_port: 1883
mqtt_username: homeassistant
mqtt_password: your_password
log_level: info
```

### Waveshare Network Adapter (Ethernet)

```yaml
connection_type: network
network_host: 192.168.1.100
network_port: 8899
network_protocol: tcp
mqtt_host: core-mosquitto
mqtt_port: 1883
mqtt_username: homeassistant
mqtt_password: your_password
log_level: info
```

### Waveshare Network Adapter (WiFi)

Same as Ethernet, but use the WiFi IP address:

```yaml
connection_type: network
network_host: 192.168.1.150
network_port: 8899
network_protocol: tcp
mqtt_host: core-mosquitto
mqtt_port: 1883
mqtt_username: homeassistant
mqtt_password: your_password
log_level: info
```

### External MQTT Broker

If using an external MQTT broker instead of core-mosquitto:

```yaml
connection_type: serial
serial_port: /dev/ttyUSB0
mqtt_host: 192.168.1.50
mqtt_port: 1883
mqtt_username: mqtt_user
mqtt_password: mqtt_password
log_level: info
```

## Configuration Validation

The add-on validates your configuration on startup. Common validation errors:

**"connection_type must be serial or network"**

- Check spelling of `connection_type`
- Must be exactly `serial` or `network` (lowercase)

**"serial_port is required when connection_type is serial"**

- You must specify `serial_port` when using serial mode
- Check device path with: `ls /dev/ttyUSB*`

**"network_host is required when connection_type is network"**

- You must specify `network_host` when using network mode
- Use IP address, not hostname

**"Invalid port number"**

- Port must be between 1-65535
- Default Waveshare port is `8899`

**"log_level must be one of: trace, debug, info, notice, warning, error, fatal"**

- Check spelling of `log_level`
- Must be lowercase

## Getting Help

- **Basic settings**: See [Basic Configuration](basic.md)
- **Network adapter setup**: See [Network Adapters](network-adapters.md)
- **MQTT issues**: See [MQTT Configuration](mqtt.md)
- **Debugging**: See [Advanced Settings](advanced.md)
- **Troubleshooting**: See [../troubleshooting/](../troubleshooting/)
