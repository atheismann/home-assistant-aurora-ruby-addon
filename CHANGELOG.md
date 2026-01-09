# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2026-01-09

### Added
- Support for network-based RS-485 adapters (Waveshare RS232/485_TO_WIFI_ETH_(B) and similar)
- New `connection_type` configuration option (serial or network)
- Network configuration options: `network_host`, `network_port`, `network_protocol`
- Support for both TCP and Telnet/RFC2217 network protocols
- Comprehensive Waveshare setup guide (WAVESHARE.md)

### Changed
- Updated configuration schema to support both serial and network connections
- Enhanced run.sh script to handle network URIs
- Updated documentation with network connection examples

## [1.0.0] - 2026-01-09

### Added
- Initial release of WaterFurnace Aurora MQTT Bridge add-on
- Support for RS-485 connection to WaterFurnace heat pumps
- MQTT bridge with automatic Home Assistant discovery
- Configurable MQTT connection (host, port, authentication, SSL)
- Optional web-based AID Tool interface
- Support for multiple serial port types
- Comprehensive documentation and setup instructions
- Based on waterfurnace_aurora gem v1.5.8
