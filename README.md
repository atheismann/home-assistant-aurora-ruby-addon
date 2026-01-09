# WaterFurnace Aurora MQTT Bridge Add-on

This Home Assistant add-on runs the [WaterFurnace Aurora](https://github.com/ccutrer/waterfurnace_aurora) MQTT bridge to integrate WaterFurnace heat pump systems directly with Home Assistant.

## About

This add-on connects directly to your WaterFurnace Aurora-based heat pump system via RS-485 and publishes all sensor data and controls to MQTT using the Homie convention. Home Assistant will automatically discover all entities through MQTT discovery.

**Important**: This add-on does NOT include its own MQTT broker. It connects to your existing Home Assistant MQTT broker (typically the Mosquitto add-on). You must have an MQTT broker installed and running before using this add-on.

👉 **See [MQTT_SETUP.md](MQTT_SETUP.md) for a detailed guide on setting up the Mosquitto broker.**

## Hardware Requirements

### Connection Options

**Option 1: USB RS-485 Adapter (Direct)**
- USB to RS-485 adapter (such as [this one](https://www.amazon.com/dp/B07B416CPK) or [this one](https://www.amazon.com/dp/B081MB6PN2))
- **Note**: Adapters based on the MAX485 chip are NOT supported
- Custom cable to connect to the AID Tool port on your heat pump

**Option 2: Network RS-485 Adapter (Ethernet/WiFi)**
- Waveshare RS232/485_TO_WIFI_ETH_(B) or similar network RS-485 adapter
- Allows connection over your local network instead of USB
- See [WAVESHARE.md](WAVESHARE.md) for detailed setup instructions
- Custom cable to connect to the AID Tool port on your heat pump

## Cable Creation

Create an ethernet cable with one end terminated in RJ45 (TIA-568-B wiring) and the other end stripped:

- **Pins 1 & 3** (white-orange and white-green) → RS-485 A/+ terminal
- **Pins 2 & 4** (orange and blue) → RS-485 B/- terminal

**WARNING**: The other pins (C and R) carry 24VAC power. DO NOT SHORT THESE to anything or you may blow a fuse or damage your ABC board.

Connect the RJ45 end to the **AID Tool** port on your heat pump, and the USB RS-485 adapter to your Home Assistant system.

## Configuration

### connection_type (required)
The type of connection to use:
- `serial` - Direct USB RS-485 adapter
- `network` - Network-based RS-485 adapter (Waveshare or similar)

### serial_port (required for serial mode)
The serial port device path for your RS-485 adapter. Common values:
- `/dev/ttyUSB0` (most USB adapters)
- `/dev/ttyAMA0` (Raspberry Pi GPIO)
- `/dev/ttyACM0` (some USB adapters)

### network_host (required for network mode)
The IP address or hostname of your network RS-485 adapter (e.g., `192.168.1.100`).

### network_port (required for network mode)
The TCP/Telnet port configured on your network adapter. Default is `2000`.

### network_protocol (required for network mode)
The protocol to use:
- `tcp` - Standard TCP connection (recommended)
- `telnet` - RFC2217 telnet connection (for automatic serial parameter configuration)

### mqtt_host (required)
The hostname of your MQTT broker:
- Use `core-mosquitto` for the official Home Assistant Mosquitto add-on (recommended)
- Use `homeassistant.local` or your HA IP if using a different MQTT setup
- This add-on does NOT create its own broker - it connects to your existing one

### mqtt_port (required)
The MQTT broker port. Default is `1883` (or `8883` for SSL).

### mqtt_username (optional)
Username for MQTT authentication (if required).

### mqtt_password (optional)
Password for MQTT authentication (if required).

### mqtt_ssl (optional)
Enable SSL/TLS for MQTT connection. Default is `false`.

### web_aid_tool_port (optional)
Port number to enable the web-based AID tool interface. Set to `0` to disable. If enabled, you can access the web interface at `http://homeassistant.local:PORT/`.

## Example Configuration

### USB Serial Connection:
```yaml
connection_type: serial
serial_port: /dev/ttyUSB0
network_host: ""
network_port: 2000
network_protocol: tcp
mqtt_host: core-mosquitto
mqtt_port: 1883
mqtt_username: ""
mqtt_password: ""
mqtt_ssl: false
web_aid_tool_port: 4567
```

### Network Connection (Waveshare):
```yaml
connection_type: network
serial_port: /dev/ttyUSB0  # Ignored in network mode
network_host: 192.168.1.100
network_port: 2000
network_protocol: tcp
mqtt_host: core-mosquitto
mqtt_port: 1883
mqtt_username: ""
mqtt_password: ""
mqtt_ssl: false
web_aid_tool_port: 0
```

## Installation

1. Add this repository to your Home Assistant add-on store
2. Install the "WaterFurnace Aurora" add-on
3. Configure the add-on with your serial port and MQTT settings
4. Start the add-on
5. Check the logs to ensure it's connecting properly

## Releases

This add-on follows [semantic versioning](https://semver.org/) with **automated releases**.

When a PR is merged to main, a new version is automatically:
- Calculated based on PR labels (`major`, `minor`, or `patch`)
- Tagged and released on GitHub
- Built and published to GitHub Container Registry

See [RELEASING.md](RELEASING.md) for details on the release process.

## Home Assistant Integration

Once the add-on is running, all WaterFurnace entities will automatically appear in Home Assistant through MQTT discovery. You'll see:

- Climate controls (thermostat, setpoints, mode)
- Temperature sensors (air, water, ambient)
- Power usage sensors (compressor, blower, pump)
- System status and diagnostic information
- And many more sensors depending on your equipment

## Supported Equipment

This add-on has been tested with:
- WaterFurnace 7 Series with IntelliZone 2
- WaterFurnace 5 Series
- GeoSmart systems
- Various configurations with DHW, ECM blowers, VS drives, and VS pumps

## Troubleshooting

### Serial Port Not Found
Check the add-on logs for available serial devices. You may need to adjust the `serial_port` configuration to match your adapter.

### No Data in Home Assistant
1. Verify your MQTT broker is running and accessible
2. Check that MQTT discovery is enabled in Home Assistant
3. Review the add-on logs for connection errors
4. Ensure your cable is properly connected to the AID Tool port

### Connection Failures
- Verify the RS-485 wiring is correct (A+ and B-)
- Ensure your adapter is NOT based on the MAX485 chip
- Check that no other software is accessing the serial port

## Advanced Usage

### ModBus Pass Through
You can query or write individual registers via MQTT. Send a register number to the `$modbus` topic:

```
745-747 => homie/aurora-<serialno>/$modbus
```

### Web AID Tool
If enabled, the web-based AID tool provides a graphical interface to view and control your heat pump directly from a web browser.

## Support

For issues specific to this add-on, please open an issue in this repository.

For issues with the underlying waterfurnace_aurora library, see the [upstream repository](https://github.com/ccutrer/waterfurnace_aurora).

## Credits

This add-on packages the excellent [waterfurnace_aurora](https://github.com/ccutrer/waterfurnace_aurora) library by [@ccutrer](https://github.com/ccutrer).

## License

This add-on is licensed under the MIT License. The underlying waterfurnace_aurora library is also MIT licensed.
