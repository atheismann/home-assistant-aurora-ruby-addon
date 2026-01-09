# Installation and Setup Guide

## Prerequisites

1. **Hardware** (choose one):
   - **Option A**: USB RS-485 adapter (NOT MAX485-based) + custom cable
   - **Option B**: Waveshare RS232/485_TO_WIFI_ETH_(B) or similar network adapter + custom cable
   - WaterFurnace Aurora heat pump with AID Tool port

2. **Software**:
   - Home Assistant (any installation method)
   - **MQTT broker** - Install the Mosquitto add-on if you don't already have one (required!)

## Step 1: Install MQTT Broker (Required)

**This add-on requires an existing MQTT broker** - it does not include its own. If you don't already have the Mosquitto add-on installed:

1. Go to **Settings** → **Add-ons** → **Add-on Store**
2. Search for "Mosquitto broker"
3. Click **Install**
4. Start the Mosquitto broker (no special configuration needed for basic use)
5. *(Optional)* Create MQTT users in the Mosquitto configuration if you want authentication

**Note**: Once Mosquitto is running, you can use `core-mosquitto` as the MQTT host in the WaterFurnace Aurora add-on configuration.

## Step 2: Create the Cable

You need to create a custom cable to connect your RS-485 adapter to the heat pump:

### Materials Needed

- 1x RJ45 connector or existing ethernet cable
- CAT5/CAT6 cable
- Crimping tool (if making from scratch)

### Wiring (TIA-568-B)

```text
RJ45 Pin | Wire Color        | RS-485 Terminal
---------|-------------------|----------------
1        | White-Orange      | A+ (positive)
2        | Orange            | B- (negative)
3        | White-Green       | A+ (positive)
4        | Blue              | B- (negative)
5        | White-Blue        | C (24VAC - DO NOT USE)
6        | Green             | C (24VAC - DO NOT USE)
7        | White-Brown       | R (24VAC - DO NOT USE)
8        | Brown             | R (24VAC - DO NOT USE)
```

**Instructions**:

1. Take an ethernet cable and cut off one end (or crimp a new RJ45 connector)
2. Strip the other end and identify the wires
3. Twist together pins 1+3 (white-orange + white-green) → RS-485 A+
4. Twist together pins 2+4 (orange + blue) → RS-485 B-
5. **IMPORTANT**: Isolate the other wires (pins 5-8). DO NOT connect them to anything!

### Connection

1. Plug RJ45 end into the **AID Tool** port on your heat pump
2. **For USB adapter**: Connect the A+/B- wires to your RS-485 adapter terminals, then plug USB adapter into your Home Assistant host
3. **For network adapter**: Connect the A+/B- wires to your Waveshare or similar device terminals (see [WAVESHARE.md](WAVESHARE.md) for detailed setup)

## Step 3: Add the Add-on Repository

1. Navigate to **Settings** → **Add-ons** → **Add-on Store**
2. Click the **⋮** (three dots) in the top right
3. Select **Repositories**
4. Add the repository URL: `https://github.com/yourusername/aurora-ruby-addon`
5. Click **Add**

## Step 4: Install the Add-on

1. Refresh the add-on store page
2. Find "WaterFurnace Aurora" in the list
3. Click on it and then click **Install**
4. Wait for the installation to complete

## Step 5: Configure the Add-on

1. Go to the **Configuration** tab
2. Set your parameters based on your connection type:

### For USB/Serial Connection

```yaml
connection_type: serial
serial_port: /dev/ttyUSB0  # Adjust to match your adapter
network_host: ""            # Leave empty for serial mode
network_port: 2000
network_protocol: tcp
mqtt_host: core-mosquitto   # Or your MQTT broker hostname
mqtt_port: 1883
mqtt_username: ""           # Optional
mqtt_password: ""           # Optional
mqtt_ssl: false
web_aid_tool_port: 0        # Set to 4567 to enable web interface
```

### For Network Connection (Waveshare)

```yaml
connection_type: network
serial_port: /dev/ttyUSB0   # Ignored in network mode
network_host: 192.168.1.100 # Your Waveshare device IP
network_port: 2000          # Port configured on Waveshare
network_protocol: tcp       # or 'telnet' for RFC2217
mqtt_host: core-mosquitto
mqtt_port: 1883
mqtt_username: ""
mqtt_password: ""
mqtt_ssl: false
web_aid_tool_port: 0
```

**Note**: For detailed Waveshare setup instructions, see [WAVESHARE.md](WAVESHARE.md).

### Finding Your Serial Port

If you're not sure which serial port to use:

1. Start the add-on with the default `/dev/ttyUSB0`
2. Check the add-on logs
3. Look for the "Available serial devices:" section
4. Update the configuration with the correct device path

Common serial ports:

- `/dev/ttyUSB0` - Most USB adapters
- `/dev/ttyUSB1` - Second USB adapter
- `/dev/ttyAMA0` - Raspberry Pi GPIO UART
- `/dev/ttyACM0` - Some USB-serial adapters

## Step 6: Start the Add-on

1. Go to the **Info** tab
2. Enable **Start on boot** (optional but recommended)
3. Enable **Watchdog** (optional but recommended)
4. Click **Start**
5. Check the **Log** tab for any errors

### Expected Log Output (Serial)

```text
[INFO] Starting WaterFurnace Aurora MQTT Bridge...
[INFO] Connection: Serial (/dev/ttyUSB0)
[INFO] MQTT Host: core-mosquitto:1883
[INFO] MQTT SSL: false
[INFO] Starting: aurora_mqtt_bridge /dev/ttyUSB0 mqtt://core-mosquitto:1883/
```

### Expected Log Output (Network)

```text
[INFO] Starting WaterFurnace Aurora MQTT Bridge...
[INFO] Connection: Network (tcp://192.168.1.100:2000/)
[INFO] MQTT Host: core-mosquitto:1883
[INFO] MQTT SSL: false
[INFO] Starting: aurora_mqtt_bridge tcp://192.168.1.100:2000/ mqtt://core-mosquitto:1883/
```

## Step 7: Verify Home Assistant Integration

1. Navigate to **Settings** → **Devices & Services**
2. Look for automatically discovered MQTT devices
3. You should see a "WaterFurnace" or "Aurora" device
4. Click on it to see all available entities

### Available Entities

Depending on your heat pump model, you may see:

- **Climate**: Thermostat control, setpoints, mode
- **Sensors**: Temperatures (air, water, ambient)
- **Sensors**: Power usage (total, compressor, blower, pump)
- **Sensors**: System status and diagnostics
- **Sensors**: Water flow rates
- **Sensors**: Relative humidity
- And many more...

## Step 8: Create Dashboard Cards (Optional)

Add controls to your dashboard using the UI or YAML:

```yaml
type: thermostat
entity: climate.waterfurnace_zone_1
```

Or for more advanced layouts, see the examples in README.md.

## Troubleshooting

### "Serial port does not exist" (Serial Mode Only)

- Check USB connection
- Verify device path in configuration
- Check add-on logs for available devices
- Try different USB ports

### "Network connection type selected but network_host is empty" (Network Mode)

- Ensure you've entered the IP address in the `network_host` field
- Verify the Waveshare device is powered on and connected to your network

### Cannot Connect to Network Device

- Ping the device: `ping <network_host>`
- Verify the port is open: `telnet <network_host> <network_port>`
- Check Waveshare device configuration (see [WAVESHARE.md](WAVESHARE.md))
- Ensure serial parameters are correct: 19200 baud, EVEN parity

### "Connection refused" or MQTT errors

- Verify MQTT broker is running
- Check MQTT credentials
- Ensure MQTT discovery is enabled in configuration.yaml

### No data appearing

- Check add-on logs for errors
- Verify cable wiring (A+ and B- correct)
- Ensure cable is plugged into AID Tool port (not thermostat port)
- Try reversing A+ and B- connections

### Entities not discovered

- Wait 1-2 minutes after startup
- Restart Home Assistant
- Check MQTT integration is installed and configured
- Use MQTT Explorer to verify data is being published

## Advanced Configuration

### Using MQTT Authentication

```yaml
mqtt_username: "hass-user"
mqtt_password: "your-secure-password"
```

### Enabling SSL/TLS

```yaml
mqtt_ssl: true
mqtt_port: 8883
```

### Enabling Web AID Tool

```yaml
web_aid_tool_port: 4567
```

Then access at: `http://homeassistant.local:4567`

Note: The web AID tool requires downloading assets from an actual AWL device. See the upstream documentation for details.

## Getting Help

- Check the [upstream repository](https://github.com/ccutrer/waterfurnace_aurora) for detailed protocol information
- Review add-on logs for specific error messages
- Open an issue in this repository with logs and configuration details

## Safety Warnings

⚠️ **DO NOT** short the C and R wires (24VAC power) to ground or communication lines
⚠️ Work carefully to avoid damaging the ABC board
⚠️ When in doubt, consult a professional HVAC technician
