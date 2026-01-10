# WaterFurnace Aurora Add-on - Quick Start

This is a condensed reference for users already familiar with the add-on. **First-time setup?** See the [full documentation](README.md).

## Quick Install

1. **Add repository**: Settings → Add-ons → Add-on Store → ⋮ → Repositories
   - Add: `https://github.com/atheismann/home-assistant-aurora-ruby-addon`
2. **Install add-on**: Find "Aurora MQTT Gateway" and click Install
3. **Configure**: See examples below
4. **Start**: Click Start and check logs

## Configuration Examples

### USB Serial

```yaml
connection_type: serial
serial_port: /dev/ttyUSB0
mqtt_host: core-mosquitto
mqtt_port: 1883
mqtt_username: homeassistant
mqtt_password: your_password
log_level: info
```

### Network (Waveshare)

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

## Prerequisites Checklist

- [ ] MQTT broker running (Mosquitto add-on)
- [ ] MQTT user created with username/password
- [ ] RS-485 adapter connected (USB or network)
- [ ] Custom cable created and connected to AID Tool port
- [ ] For network: Adapter configured (19200 8E1, Transparent mode)

## Common Commands

**Find USB device:**

```bash
ls -la /dev/ttyUSB*
```

**Test MQTT:**

```bash
mosquitto_sub -h core-mosquitto -u homeassistant -P password -t 'homie/aurora/#' -v
```

**Enable debug:**

```yaml
log_level: debug
```

## Quick Troubleshooting

| Problem | Solution | Guide |
|---------|----------|-------|
| ModBus timeout | Swap A+/B- wires | [Connection Issues](docs/troubleshooting/connection-issues.md) |
| No entities | Check MQTT broker running | [MQTT Issues](docs/troubleshooting/mqtt-issues.md) |
| Device not found | Check `/dev/ttyUSB*` | [Connection Issues](docs/troubleshooting/connection-issues.md) |
| Auth failed | Check MQTT username/password | [MQTT Configuration](docs/configuration/mqtt.md) |

## Full Documentation

**Getting Started:**

- [Prerequisites](docs/getting-started/prerequisites.md)
- [Hardware Setup](docs/getting-started/hardware.md)
- [MQTT Setup](docs/getting-started/mqtt-setup.md)
- [Installation](docs/getting-started/installation.md)

**Configuration:**

- [Basic Configuration](docs/configuration/basic.md)
- [Network Adapters](docs/configuration/network-adapters.md)
- [MQTT Configuration](docs/configuration/mqtt.md)

**Troubleshooting:**

- [Connection Issues](docs/troubleshooting/connection-issues.md)
- [Debug RS-485](docs/troubleshooting/debug-rs485.md)
- [Logging Guide](docs/troubleshooting/logging.md)
- [MQTT Issues](docs/troubleshooting/mqtt-issues.md)

## Key Features

✅ **Serial & Network Support** - USB or Waveshare network adapters  
✅ **MQTT Auto-Discovery** - Entities appear automatically  
✅ **40+ Sensors** - Temperatures, power, system status  
✅ **Web Debug Interface** - Built-in diagnostics tool  
✅ **Debug Logging** - Packet-level RS-485 debugging  
✅ **Multi-Architecture** - ARM, AMD64 support

## Hardware Requirements

- **USB adapter**: FTDI-based RS-485 adapter (NOT MAX485)
- **Network adapter**: Waveshare RS232/485_TO_WIFI_ETH or similar
- **Cable**: RJ45 to bare wires (pins 1+3→A+, pins 2+4→B-)
- **Heat pump**: WaterFurnace with AID Tool port

See [Hardware Setup Guide](docs/getting-started/hardware.md) for wiring details.

## Support

- **GitHub**: [Issues](https://github.com/atheismann/home-assistant-aurora-ruby-addon/issues) | [Discussions](https://github.com/atheismann/home-assistant-aurora-ruby-addon/discussions)
- **Community**: [Home Assistant Forum](https://community.home-assistant.io/)
- **Upstream**: [waterfurnace_aurora gem](https://github.com/ccutrer/waterfurnace_aurora)
