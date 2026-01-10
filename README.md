# WaterFurnace Aurora MQTT Gateway

[![GitHub Release](https://img.shields.io/github/v/release/atheismann/home-assistant-aurora-ruby-addon)](https://github.com/atheismann/home-assistant-aurora-ruby-addon/releases)
[![License](https://img.shields.io/github/license/atheismann/home-assistant-aurora-ruby-addon)](LICENSE)

This Home Assistant add-on connects directly to your WaterFurnace Aurora-based heat pump system via RS-485 and publishes all sensor data to MQTT using the Homie convention. Home Assistant automatically discovers all entities through MQTT.

## Features

✅ **Direct RS-485 Connection** - No cloud dependency  
✅ **Auto-Discovery** - Entities appear automatically in Home Assistant  
✅ **Serial & Network Support** - USB adapters or Waveshare network adapters  
✅ **Comprehensive Sensors** - Temperatures, power usage, system status, and more  
✅ **Web Debug Interface** - Built-in web tool for diagnostics  
✅ **Debug Logging** - Packet-level RS-485 communication debugging  

## Quick Start

**New to this add-on?** Follow these guides in order:

1. **[Prerequisites](docs/getting-started/prerequisites.md)** - Check compatibility and requirements
2. **[Hardware Setup](docs/getting-started/hardware.md)** - Create cable and connect to heat pump
3. **[MQTT Setup](docs/getting-started/mqtt-setup.md)** - Install and configure Mosquitto broker
4. **[Installation](docs/getting-started/installation.md)** - Install and configure the add-on

**Already set up?** See [Quick Start Guide](QUICKSTART.md) for a condensed reference.

## Documentation

### Getting Started

- **[Prerequisites](docs/getting-started/prerequisites.md)** - Hardware/software requirements and compatibility
- **[Hardware Setup](docs/getting-started/hardware.md)** - Cable creation, wiring diagram, physical connections
- **[MQTT Setup](docs/getting-started/mqtt-setup.md)** - Mosquitto broker installation and user creation
- **[Installation Guide](docs/getting-started/installation.md)** - Add-on installation, configuration, verification

### Configuration

- **[Basic Configuration](docs/configuration/basic.md)** - Connection types, MQTT settings, log levels
- **[Network Adapters](docs/configuration/network-adapters.md)** - Complete Waveshare setup guide (900+ lines)
- **[MQTT Configuration](docs/configuration/mqtt.md)** - Detailed MQTT broker setup and troubleshooting

### Troubleshooting

- **[Troubleshooting Guide](docs/troubleshooting/README.md)** - Common issues and solutions
- **[Connection Issues](docs/troubleshooting/connection-issues.md)** - Heat pump connection problems
- **[Debug RS-485](docs/troubleshooting/debug-rs485.md)** - Packet-level communication debugging
- **[Logging Guide](docs/troubleshooting/logging.md)** - Understanding and troubleshooting logs
- **[MQTT Issues](docs/troubleshooting/mqtt-issues.md)** - MQTT broker and entity discovery problems

### Development

- **[Releasing Guide](docs/development/releasing.md)** - Automated release process and versioning

## Hardware Requirements

**You need:**

1. **WaterFurnace heat pump** with Aurora control system (AID Tool port)
2. **RS-485 adapter** - Choose one:
   - **USB RS-485 adapter** (e.g., [FTDI adapter](https://www.amazon.com/dp/B07B416CPK)) - Direct connection to Home Assistant
   - **Network adapter** (e.g., Waveshare RS232/485_TO_WIFI_ETH) - Connect over Ethernet/WiFi
3. **Custom cable** - RJ45 to bare wires (see [Hardware Setup](docs/getting-started/hardware.md))
4. **MQTT broker** - Mosquitto broker add-on (see [MQTT Setup](docs/getting-started/mqtt-setup.md))

See **[Prerequisites Guide](docs/getting-started/prerequisites.md)** for detailed compatibility and requirements.

## Installation

### Quick Install

1. In Home Assistant: **Settings** → **Add-ons** → **Add-on Store**
2. Click ⋮ (top right) → **Repositories**
3. Add: `https://github.com/atheismann/home-assistant-aurora-ruby-addon`
4. Find **Aurora MQTT Gateway** and click **Install**
5. Configure (see below) and click **Start**

**Need help?** See the [Installation Guide](docs/getting-started/installation.md) for detailed instructions.

## Basic Configuration

### USB Serial Connection

```yaml
connection_type: serial
serial_port: /dev/ttyUSB0
mqtt_host: core-mosquitto
mqtt_port: 1883
mqtt_username: homeassistant
mqtt_password: your_secure_password
log_level: info
```

### Network Connection (Waveshare)

```yaml
connection_type: network
network_host: 192.168.1.100
network_port: 8899
network_protocol: tcp
mqtt_host: core-mosquitto
mqtt_port: 1883
mqtt_username: homeassistant
mqtt_password: your_secure_password
log_level: info
```

**For detailed configuration:**

- **[Basic Configuration](docs/configuration/basic.md)** - All configuration options explained
- **[Network Adapters](docs/configuration/network-adapters.md)** - Waveshare serial parameters (19200 8E1)
- **[MQTT Configuration](docs/configuration/mqtt.md)** - MQTT broker setup

## What You Get

Once running, Home Assistant automatically discovers:

**Climate & Temperatures:**

- Entering/leaving water temperature
- Outdoor temperature
- Lockout temperature
- Zone temperatures

**System Status:**

- Operating mode (heating, cooling, idle)
- Active zones
- Compressor speed & power
- Pump & fan speeds

**Power & Energy:**

- Compressor power & amperage
- Total system power
- Daily/monthly energy usage

**And 40+ more sensors** depending on your equipment configuration.

## Supported Equipment

**Tested and working with:**

- WaterFurnace 7 Series with IntelliZone 2
- WaterFurnace 5 Series
- GeoSmart systems
- Various configurations with DHW, ECM blowers, VS drives, VS pumps

**Requirements:**

- Aurora control system with AID Tool port (RJ45 diagnostic port)
- Compatible with most WaterFurnace heat pumps manufactured after 2008

## Troubleshooting

Having issues? Check these guides:

- **[Connection Issues](docs/troubleshooting/connection-issues.md)** - Can't connect to heat pump? Start here
- **[MQTT Issues](docs/troubleshooting/mqtt-issues.md)** - No entities appearing in Home Assistant?
- **[Debug RS-485](docs/troubleshooting/debug-rs485.md)** - ModBus timeout errors?
- **[Logging Guide](docs/troubleshooting/logging.md)** - Understanding log output

**Common Problems:**

| Problem | Quick Solution | Guide |
|---------|----------------|-------|
| ModBus timeout | Try reversing A+/B- connections | [Connection Issues](docs/troubleshooting/connection-issues.md) |
| No entities | Check MQTT broker is running | [MQTT Issues](docs/troubleshooting/mqtt-issues.md) |
| Device not found | Check `/dev/ttyUSB*` exists | [Connection Issues](docs/troubleshooting/connection-issues.md) |
| Wrong values | Enable debug logging | [Debug RS-485](docs/troubleshooting/debug-rs485.md) |

## Debug Mode

Enable detailed RS-485 communication logging:

```yaml
log_level: debug
```

This enables:

- **Network mode**: tcpdump packet capture of all RS-485 communication
- **Serial mode**: strace system call tracing
- **ModBus protocol**: Request/response byte-level logging

See [Debug RS-485 Guide](docs/troubleshooting/debug-rs485.md) for interpreting debug output.

## Releases

This add-on follows [semantic versioning](https://semver.org/) with **automated releases**.

When a PR is merged to main, a new version is automatically:

- Calculated based on PR labels (`major`, `minor`, or `patch`)
- Tagged and released on GitHub
- Built and published to GitHub Container Registry

See [Releasing Guide](docs/development/releasing.md) for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request
5. Label your PR: `major`, `minor`, or `patch` for semantic versioning

See [Releasing Guide](docs/development/releasing.md) for release process details.

## Support & Help

- **Documentation**: Browse the [docs/](docs/) folder for comprehensive guides
- **Issues**: [Report bugs or request features](https://github.com/atheismann/home-assistant-aurora-ruby-addon/issues)
- **Discussions**: [Ask questions or share your setup](https://github.com/atheismann/home-assistant-aurora-ruby-addon/discussions)
- **Community**: [Home Assistant Community Forum](https://community.home-assistant.io/)

## Credits

This add-on packages the excellent [waterfurnace_aurora](https://github.com/ccutrer/waterfurnace_aurora) Ruby gem by [@ccutrer](https://github.com/ccutrer).

**Built with:**

- [waterfurnace_aurora](https://github.com/ccutrer/waterfurnace_aurora) - Ruby library for Aurora protocol
- Alpine Linux - Lightweight container base
- Home Assistant - Home automation platform

## License

This add-on is licensed under the MIT License. The underlying waterfurnace_aurora library is also MIT licensed.

---

**Made with ❤️ for WaterFurnace heat pump owners**
