# Basic Configuration

This guide covers the core configuration options for the Aurora MQTT Gateway add-on.

## Configuration Overview

Configuration is done through the Home Assistant UI in YAML format. All settings are validated before the add-on starts.

## Connection Type

### Serial Connection

Use this mode for USB RS-485 adapters connected directly to your Home Assistant host.

```yaml
connection_type: serial
serial_port: /dev/ttyUSB0
```

**Configuration options:**

- **serial_port**: The device path of your USB adapter
  - Most commonly: `/dev/ttyUSB0`
  - Check available devices: `ls /dev/ttyUSB*`
  - May be `/dev/ttyUSB1` or higher if multiple adapters are connected

**When to use serial**:

- USB RS-485 adapter plugged directly into Home Assistant host
- Running Home Assistant OS, Supervised, or Container with USB passthrough
- Simpler setup, no network configuration needed

**Limitations**:

- Physical USB connection required
- Limited cable length (USB extension cables may not work reliably)
- USB adapter must be passed through to container (if using Docker)

### Network Connection

Use this mode for network-connected RS-485 adapters like Waveshare.

```yaml
connection_type: network
network_host: 192.168.1.100
network_port: 8899
network_protocol: tcp
```

**Configuration options:**

- **network_host**: IP address of the network adapter
  - Must be a valid IPv4 address
  - Use static IP or DHCP reservation (recommended)
  - Example: `192.168.1.100`

- **network_port**: TCP/Telnet port of the adapter
  - Waveshare default: `8899`
  - Range: `1-65535`
  - Must match port configured in adapter

- **network_protocol**: Communication protocol
  - Options: `tcp` or `telnet`
  - Waveshare uses: `tcp`
  - Most adapters use: `tcp`

**When to use network**:

- Heat pump is far from Home Assistant host
- Using Waveshare or similar network adapter
- Want flexibility to move adapter without USB constraints
- Multiple instances need to access heat pump (not recommended, but possible)

**Advantages**:

- No USB cable length limitations
- Can be placed anywhere on network
- Ethernet provides reliable connection
- WiFi option available (though Ethernet recommended)

**Additional setup required**:

- Must configure network adapter serial parameters
- See **[Network Adapters Configuration](network-adapters.md)** for complete Waveshare setup

## MQTT Configuration

### Basic MQTT Settings

```yaml
mqtt_host: core-mosquitto
mqtt_port: 1883
mqtt_username: homeassistant
mqtt_password: your_secure_password
```

**Configuration options:**

- **mqtt_host**: Hostname or IP of MQTT broker
  - Built-in broker: `core-mosquitto`
  - External broker: IP address (e.g., `192.168.1.50`)
  - External broker: Hostname (e.g., `mqtt.local`)

- **mqtt_port**: MQTT broker port
  - Default: `1883` (unencrypted)
  - TLS: `8883` (if broker supports TLS)

- **mqtt_username**: MQTT username
  - Must match user created in Mosquitto broker
  - See [MQTT Setup](../getting-started/mqtt-setup.md) for creating users

- **mqtt_password**: MQTT password
  - Password for the MQTT user
  - Keep secure, avoid simple passwords

### MQTT Topic Structure

The add-on publishes to MQTT using the Homie convention:

```
homie/aurora/$homie
homie/aurora/$name
homie/aurora/$state
homie/aurora/heat-pump/lockout-temp
homie/aurora/heat-pump/entering-water-temp
...
```

**Topics are automatically created**, you don't need to configure them.

**Home Assistant auto-discovery**:

- The add-on publishes discovery messages
- Entities appear automatically in Home Assistant
- Device name: "WaterFurnace Aurora Heat Pump"
- All sensors are grouped under this device

### Testing MQTT Connection

Use MQTT Explorer or command line:

```bash
# Subscribe to all aurora topics
mosquitto_sub -h core-mosquitto -u homeassistant -P your_password -t 'homie/aurora/#' -v
```

See **[MQTT Configuration](mqtt.md)** for detailed MQTT troubleshooting.

## Log Level

Control the verbosity of logging:

```yaml
log_level: info
```

**Available levels** (from most to least verbose):

| Level   | When to Use                                                      | Details Logged                                          |
|---------|------------------------------------------------------------------|---------------------------------------------------------|
| trace   | Extreme debugging, every operation                               | Every function call, loop iteration                     |
| debug   | Troubleshooting communication issues                             | **RS-485 packets, ModBus frames, network traffic**      |
| info    | Normal operation (recommended)                                   | Startup, configuration, data publishing                 |
| notice  | Important events only                                            | Configuration changes, reconnections                    |
| warning | Only warnings and errors                                         | Retry attempts, recoverable errors                      |
| error   | Only errors                                                      | Failed connections, unrecoverable errors                |
| fatal   | Only critical failures that stop the add-on                      | Crashes, configuration errors                           |

**Recommended settings:**

- **Production use**: `info` - Provides enough detail without flooding logs
- **Initial setup**: `info` or `debug` - Help verify everything is working
- **Troubleshooting**: `debug` - See RS-485 communication packets
- **RS-485 issues**: `debug` - Enable packet capture (see below)

### Debug Mode Features

When `log_level: debug` is set, the add-on enables additional debugging:

**For network connections:**

- tcpdump packet capture
- All packets to/from network adapter are logged
- See exact bytes sent/received over network

**For serial connections:**

- strace system call tracing
- All read/write/ioctl operations logged
- See exact bytes sent/received over serial port

**ModBus protocol debugging:**

- `MODBUS_DEBUG` environment variable is set
- `waterfurnace_aurora` gem logs ModBus frames
- See request/response details

See **[Debug RS-485 Communication](../troubleshooting/debug-rs485.md)** for interpreting debug output.

## Web AID Tool

The add-on includes a simple web interface for debugging:

```yaml
web_aid_tool_port: 8080
```

**Configuration:**

- **web_aid_tool_port**: Port for web interface
  - Default: `8080`
  - Range: `1-65535`
  - Must not conflict with other services

**Accessing the web interface:**

1. Open browser to: `http://<home-assistant-ip>:8080`
2. You'll see heat pump data in JSON format
3. Data updates periodically

**Use cases:**

- Verify add-on is reading data from heat pump
- Check data values without Home Assistant UI
- Debug MQTT issues (if web shows data, problem is MQTT)
- API access for custom integrations

**Example output:**

```json
{
  "lockout_temp": 15.5,
  "entering_water_temp": 38.2,
  "leaving_water_temp": 42.1,
  "outdoor_temp": 5.0,
  "compressor_speed": 1200,
  ...
}
```

## Complete Configuration Example

### Serial Connection (Full)

```yaml
connection_type: serial
serial_port: /dev/ttyUSB0
mqtt_host: core-mosquitto
mqtt_port: 1883
mqtt_username: homeassistant
mqtt_password: my_secure_mqtt_password_123
web_aid_tool_port: 8080
log_level: info
```

### Network Connection (Full)

```yaml
connection_type: network
network_host: 192.168.1.100
network_port: 8899
network_protocol: tcp
mqtt_host: core-mosquitto
mqtt_port: 1883
mqtt_username: homeassistant
mqtt_password: my_secure_mqtt_password_123
web_aid_tool_port: 8080
log_level: info
```

### Debug Configuration

For troubleshooting, increase logging:

```yaml
connection_type: network
network_host: 192.168.1.100
network_port: 8899
network_protocol: tcp
mqtt_host: core-mosquitto
mqtt_port: 1883
mqtt_username: homeassistant
mqtt_password: my_secure_mqtt_password_123
web_aid_tool_port: 8080
log_level: debug  # <-- Enable debug mode
```

## Configuration Workflow

1. **Initial setup**: Start with `log_level: info`
2. **Verify connectivity**: Check logs for successful connection
3. **If issues arise**: Change to `log_level: debug`
4. **Restart add-on**: Changes require restart
5. **Check logs**: Look for detailed debug output
6. **Once working**: Return to `log_level: info`

## Next Steps

- **Network adapters**: See [Network Adapters Configuration](network-adapters.md)
- **MQTT details**: See [MQTT Configuration](mqtt.md)
- **Advanced settings**: See [Advanced Settings](advanced.md)
- **Troubleshooting**: See [../troubleshooting/](../troubleshooting/)

## Troubleshooting Configuration

**Add-on won't start:**

- Check logs for validation errors
- Ensure all required fields are present
- Verify YAML syntax (indentation matters)

**Can't connect to heat pump:**

- Serial: Check `serial_port` device path
- Network: Verify `network_host` IP address
- See [Connection Issues](../troubleshooting/connection-issues.md)

**MQTT not working:**

- Verify Mosquitto broker is running
- Check `mqtt_username` and `mqtt_password`
- See [MQTT Configuration](mqtt.md)

**Need more help:**

- [Troubleshooting Guide](../troubleshooting/)
- [GitHub Issues](https://github.com/atheismann/home-assistant-aurora-ruby-addon/issues)
