# Changelog

All notable changes to this project will be documented in this file.

## [1.2.6] - 2026-01-10

### Changes
- update logs (by Andrew J Theismann)

## [1.2.5] - 2026-01-10

### Changes
- update documentation (by Andrew J Theismann)

## [1.2.4] - 2026-01-10

### Changes
- add rs-485 troubleshooting logging (by Andrew J Theismann)

## [1.2.3] - 2026-01-10

### Changes
- add logs and troubleshooting (by Andrew J Theismann)

## [1.2.2] - 2026-01-09

### Changes
- add documentation (by Andrew J Theismann)

## [1.2.1] - 2026-01-09

### Changes
- update logging (by Andrew J Theismann)

## [1.2.0] - 2026-01-09

### Changes
- Revert "feat: add auto-update and watchdog capabilities" (by Andrew J Theismann)

## [1.1.3] - 2026-01-09

### Changes
- fix: auto-release only triggers after successful build (by Andrew J Theismann)

## [1.1.2] - 2026-01-09

### Changes
- fix: add push trigger to auto-release workflow (by Andrew J Theismann)

## [1.1.1] - 2026-01-09

### Changes
- fix: add docker-hub parameter to build workflow (by Andrew J Theismann)

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

### Features

- Initial release of WaterFurnace Aurora MQTT Bridge add-on
- Support for RS-485 connection to WaterFurnace heat pumps
- MQTT bridge with automatic Home Assistant discovery
- Configurable MQTT connection (host, port, authentication, SSL)
- Optional web-based AID Tool interface
- Support for multiple serial port types
- Comprehensive documentation and setup instructions
- Based on waterfurnace_aurora gem v1.5.8
