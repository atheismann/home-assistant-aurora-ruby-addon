# Waveshare RS232/485_TO_WIFI_ETH_(B) Setup Guide

## Overview

The Waveshare RS232/485_TO_WIFI_ETH_(B) is a network-based RS-485 adapter that allows you to connect your WaterFurnace heat pump over Ethernet or WiFi instead of USB. This is useful for:

- Remote installations where the heat pump is far from your Home Assistant server
- Cleaner cable management (use existing network infrastructure)
- Wireless connectivity options

## Hardware Setup

### 1. Connect the Waveshare Device to Your Heat Pump

Create the same cable as described in [Hardware Setup](../getting-started/hardware.md):

## Cable Wiring

Your heat pump uses a standard ethernet cable for the RS-485 connection:

- Pins 1+3 (white-orange + white-green) → A+ terminal on Waveshare
- Pins 2+6 (orange + green)             → B- terminal on Waveshare

Alternatively (TIA-568-B standard):

- Pins 1+2 (white-orange + orange)     → A+ terminal on Waveshare
- Pins 3+6 (white-green + green)       → B- terminal on Waveshare

### 2. Configure the Waveshare Device

The Waveshare device needs to be configured for RS-485 communication with the correct serial parameters.

#### Initial Connection

1. **Power the device**: Connect power via the included adapter or USB port
2. **Network connection**:
   - **Ethernet**: Connect an Ethernet cable to the device and your network switch/router
   - **WiFi**: The device may create a WiFi access point initially (look for "Waveshare_XXXX" network)
3. **Find the IP address**:
   - Check your router's DHCP client list
   - Use the Waveshare configuration tool (if provided)
   - Try the default IP: `192.168.1.200` (varies by model)
   - For WiFi AP mode, it's typically `192.168.1.1`

#### Web Interface Configuration (Step by Step)

##### Step 1: Access the Web Interface

1. Open a web browser (Chrome, Firefox, Safari, etc.)
2. Navigate to the device's IP address: `http://192.168.1.200` (use your actual IP)
3. **Login credentials** (try these defaults):
   - Username: `admin` Password: `admin`
   - Or blank username with password: `admin`
   - Some models use: `root`/`root`

##### Step 2: Configure Serial Port Settings

Navigate to the **Serial Port** or **COM Settings** or **UART Settings** section:

**Data Transfer Mode:**

| Setting              | Value                |
|----------------------|----------------------|
| Data Transfer Mode   | **Transparent Mode** |
| Mode                 | **Transparent Mode** |

**UART Settings (Critical - MUST match exactly):**

| Setting                          | Value      | Notes                                 |
|----------------------------------|------------|---------------------------------------|
| Baudrate                         | **19200**  | This is the Aurora protocol speed     |
| Data Bits                        | **8**      | Standard                              |
| Parity                           | **Even**   | Very important! Not None, not Odd     |
| Stop (Stop Bits)                 | **1**      | Standard                              |
| Baudrate adaptive (RFC2117)      | **Enable** | Allows automatic serial config        |
| Flow Control                     | **None**   | No hardware/software flow control     |
| Interface / Working Mode         | **RS-485** | NOT RS-232 or RS-422                  |

**Common mistakes to avoid:**

- ❌ Wrong baud rate (9600, 38400, 115200 won't work)
- ❌ Using "None" for parity (must be EVEN/Even)
- ❌ Selecting RS-232 instead of RS-485 mode
- ❌ Wrong data transfer mode (use Transparent, not Modbus or others)

##### Step 3: Configure Network Settings

Navigate to the **Network** or **Socket** settings section:

**TCP Server Mode (Recommended):**

| Setting         | Value                 | Notes                                |
|---------------- |-----------------------|--------------------------------------|
| Work Mode       | **TCP Server**        | Device listens for connections       |
| Local Port      | **2000**              | Any unused port (remember this!)     |
| TCP Timeout     | **0** or **disabled** | Keep connection open                 |
| TCP Keepalive   | **Enabled**           | Prevents disconnections              |
| Max Connections | **1**                 | Only HA will connect                 |

**Important:** Use TCP Server mode, NOT TCP Client mode. The add-on will connect TO the device.

##### Step 4: Configure RS-485 Specific Settings

If your device has RS-485 termination or bias settings:

| Setting              | Value                | Notes                                 |
|----------------------|----------------------|---------------------------------------|
| Termination Resistor | **Auto** or **120Ω** | Depends on cable length               |
| Bias Resistors       | **Disabled**         | Usually not needed for point-to-point |

##### Step 5: Save and Reboot

1. **Click "Save" or "Apply"** at the bottom of each configuration page
2. **Reboot the device** - there's usually a "Reboot" or "Restart" button
3. Wait 30-60 seconds for the device to restart
4. Verify it reconnects to your network (check router or ping the IP)

#### Advanced: Static IP Configuration (Recommended)

To avoid IP address changes:

1. Go to **Network Settings** or **LAN Settings**
2. Set a **Static IP address**:

   ```text
   IP Address: 192.168.1.100 (choose one in your network range)
   Subnet Mask: 255.255.255.0
   Gateway: 192.168.1.1 (your router IP)
   DNS: 192.168.1.1 (your router IP or 8.8.8.8)
   ```

3. **OR** configure a DHCP reservation in your router for the device's MAC address

#### Configuration Examples by Model

**For Waveshare RS232/485 TO ETH (B):**

- Navigate to "Data Transfer Mode" → Select **"Transparent Mode"**
- Navigate to "UART Settings":
  - Baudrate → **19200**
  - Data Bits → **8**
  - Parity → **Even**
  - Stop → **1**
  - Baudrate adaptive (RFC2117) → **Enable**
- Navigate to "Work Mode" → Select **"TCP Server"**
- Set "Local Port" → **2000**
- Under "Serial Port" or "Working Mode" → Select **"RS485"**

**For Waveshare with Web UI v2.x:**

- Navigate to: Setup → Serial Settings
  - Mode: Transparent Mode
  - Baudrate: 19200
  - Data Bits: 8
  - Parity: Even
  - Stop Bits: 1
  - Baudrate adaptive: Enable
- Navigate to: Setup → Socket Settings
  - Protocol: TCP Server
- Port: 2000
- Navigate to: Setup → Serial Settings  
- Configure baud, parity, etc. as above

#### Alternative: Telnet/RFC2217 Mode

If the device supports RFC2217 protocol, you can use telnet mode which allows the serial parameters to be set automatically by the software:

**When to use RFC2217:**

- ✅ Device explicitly supports RFC2217/Telnet protocol
- ✅ You want serial parameters configured automatically
- ✅ You need more control over serial settings remotely

**Configuration:**

| Setting  | Value                 |
|----------|-----------------------|
| Protocol | RFC2217 or Telnet     |
| Port     | 2217 (or your choice) |

**Note:** Most simple TCP server configurations work better than RFC2217 for this use case. Only use RFC2217 if you know your device supports it properly.

## Add-on Configuration

After configuring your Waveshare device, update the add-on configuration in Home Assistant:

### For TCP Connection (Most Common)

```yaml
connection_type: network
serial_port: /dev/ttyUSB0  # Ignored when using network mode
network_host: 192.168.1.100  # Your Waveshare device IP
network_port: 2000  # Port configured on Waveshare
network_protocol: tcp
mqtt_host: core-mosquitto
mqtt_port: 1883
mqtt_username: ""
mqtt_password: ""
mqtt_ssl: false
web_aid_tool_port: 0
log_level: info
```

**Important fields:**

- `network_host`: Must match the IP address of your Waveshare device
- `network_port`: Must match the "Local Port" you configured (e.g., 2000)
- `network_protocol`: Use `tcp` for standard TCP server mode

### For Telnet/RFC2217 Connection (Advanced)

```yaml
connection_type: network
serial_port: /dev/ttyUSB0  # Ignored when using network mode
network_host: 192.168.1.100  # Your Waveshare device IP
network_port: 2217  # RFC2217 port
network_protocol: telnet
mqtt_host: core-mosquitto
mqtt_port: 1883
mqtt_username: ""
mqtt_password: ""
mqtt_ssl: false
web_aid_tool_port: 0
log_level: info
```

## Testing Your Configuration

### Step 1: Test Network Connectivity

Before starting the add-on, verify you can reach the device:

```bash
# From a computer on the same network:
ping 192.168.1.100

# Test if the port is open:
telnet 192.168.1.100 2000
# Or using netcat:
nc -zv 192.168.1.100 2000

# Should show: "Connection succeeded" or "Connected to..."
```

### Step 2: Start the Add-on

1. Navigate to **Settings** → **Add-ons** → **WaterFurnace Aurora**
2. Click **Start**
3. Click **Log** tab to watch the startup

### Step 3: Verify Logs

Look for these successful connection messages:

```text
[INFO] Starting WaterFurnace Aurora MQTT Bridge...
[INFO] Log level set to: info
[INFO] Connection: Network (tcp://192.168.1.100:2000/)
[INFO] MQTT Host: core-mosquitto:1883
[INFO] Starting: aurora_mqtt_bridge tcp://192.168.1.100:2000/ mqtt://core-mosquitto:1883/
[INFO] Connected to heat pump
[INFO] Publishing data to MQTT...
```

### Step 4: Check MQTT Messages

In Home Assistant:

1. Go to **Developer Tools** → **MQTT**
2. Subscribe to: `homie/#`
3. You should see messages like:

   ```text
   homie/waterfurnace_aurora/<device_id>/$state = ready
   homie/waterfurnace_aurora/<device_id>/iz2activerelay/$properties
   ```

### Step 5: Check Auto-Discovery

Within a few minutes, check **Settings** → **Devices & Services**:

- Look for a new **MQTT** device named after your heat pump
- It should have 50+ entities (sensors, switches, etc.)

## Verification

After starting the add-on, check the logs. You should see:

```text
[INFO] Starting WaterFurnace Aurora MQTT Bridge...
[INFO] Connection: Network (tcp://192.168.1.100:2000/)
[INFO] MQTT Host: core-mosquitto:1883
[INFO] MQTT SSL: false
[INFO] Starting: aurora_mqtt_bridge tcp://192.168.1.100:2000/ mqtt://core-mosquitto:1883/
```

## Troubleshooting

### Cannot Connect to Waveshare Web Interface

**Problem:** Cannot access `http://192.168.1.x` in browser

**Solutions:**

1. **Find the correct IP**:
   - Check router DHCP leases
   - Look for device named "Waveshare" or similar MAC address vendor
   - Try default IPs: `192.168.1.200`, `192.168.1.1`, `192.168.0.7`

2. **Connect to WiFi AP mode**:
   - Look for WiFi network named "Waveshare_XXXX"
   - Connect to it (password may be on device label or `12345678`)
   - Access web UI at `192.168.1.1` or `192.168.10.1`

3. **Reset the device**:
   - Hold reset button for 10+ seconds
   - Device will return to factory settings

### Cannot Connect to Device from Add-on

**Problem:** Add-on log shows connection errors

**Check these in order:**

1. **Verify device is reachable**:

   ```bash
   # SSH into Home Assistant or use Terminal add-on:
   ping 192.168.1.100
   ```

   - If ping fails: Network issue, wrong IP, or firewall blocking

2. **Verify port is open**:

   ```bash
   telnet 192.168.1.100 2000
   # Or:
   nc -zv 192.168.1.100 2000
   ```

   - If "Connection refused": Wrong port or device not in server mode
   - If timeout: Firewall blocking or device offline

3. **Check Waveshare is in TCP Server mode**:
   - Log back into web interface
   - Verify "Work Mode" = "TCP Server" (NOT "TCP Client")
   - Verify "Local Port" matches your config

4. **Check network configuration**:
   - Home Assistant and Waveshare must be on the same network
   - Or router must allow routing between networks/VLANs
   - Check firewall rules on router

### No Data Received from Heat Pump

**Problem:** Add-on connects but no sensor data appears

**Serial parameters issue (most common):**

1. **Verify EXACT settings in Waveshare web interface**:
   - Baud Rate: **19200** (not 9600, 38400, etc.)
   - Parity: **EVEN** (not None or Odd) ← This is critical!
   - Data Bits: **8**
   - Stop Bits: **1**
   - Flow Control: **None**

2. **Verify RS-485 mode**:
   - Must be "RS-485" not "RS-232"
   - Some devices have a physical switch or jumper

3. **Check wiring**:

   ```text
   Heat Pump AID Port    Waveshare RS-485
   ═══════════════════   ════════════════
   Pins 1+3 (A+)    →    A+ or T/R+ terminal
   Pins 2+6 (B-)    →    B- or T/R- terminal
   ```

4. **Try reversing polarity**:
   - Swap A+ and B- connections
   - RS-485 can be confusing; reversing sometimes helps

5. **Check cable quality**:
   - Use Cat5e or Cat6 ethernet cable (not flat cable)
   - Keep cable under 50 feet if possible
   - Avoid running parallel to power lines

### Connection Drops Repeatedly

**Problem:** Add-on connects briefly then disconnects

**Solutions:**

1. **Enable TCP Keepalive** in Waveshare:
   - Web interface → Network settings
   - Enable "TCP Keepalive" or "Heartbeat"
   - Set keepalive interval to 60-120 seconds

2. **Disable connection timeout**:
   - Set "TCP Timeout" to **0** or **Disabled**
   - This keeps connection open indefinitely

3. **Check power supply**:
   - Use official power adapter (not USB power from PC)
   - Insufficient power causes instability

4. **Network stability** (for WiFi):
   - WiFi can drop connections
   - Switch to Ethernet if possible
   - Move closer to WiFi access point
   - Use 2.4GHz band (better range than 5GHz)

5. **Router firewall/NAT**:
   - Some routers terminate idle connections
   - Add firewall rule to allow connection
   - Check router logs for blocks

### Add-on Shows Errors in Log

#### Error: "Network connection type selected but network_host is empty"

- Solution: Fill in the `network_host` field with your Waveshare IP

#### Error: "Connection refused"

- Wrong port number
- Waveshare not in TCP Server mode
- Waveshare not powered on

#### Error: "Connection timeout"

- Wrong IP address
- Network/firewall blocking connection
- Waveshare on different subnet/VLAN

#### Error: "No route to host"

- IP address not reachable
- Check network configuration
- Try pinging the device

### Data is Corrupted or Gibberish

**Problem:** Receiving data but it's unreadable

**Solutions:**

1. **Wrong baud rate**:
   - MUST be exactly 19200
   - Double-check in web interface

2. **Wrong parity**:
   - MUST be EVEN (not None)
   - This is the most common mistake

3. **RS-485 vs RS-232 mode**:
   - Must be in RS-485 mode
   - Check physical switch if device has one

4. **Electrical interference**:
   - Separate RS-485 cable from power cables
   - Use shielded cable if near motors/pumps
   - Add ferrite cores if needed

### WiFi Connection Issues

**Problem:** Device won't connect to WiFi

**Solutions:**

1. **Check WiFi settings**:
   - SSID must be exactly correct (case-sensitive)
   - Password must be exactly correct
   - Some devices don't show passwords when typing

2. **WiFi band compatibility**:
   - Most Waveshare devices only support 2.4GHz
   - Cannot connect to 5GHz-only networks
   - If router has both, ensure 2.4GHz is enabled

3. **WiFi security**:
   - Supports WPA2-PSK (most common)
   - May not support WPA3 or enterprise (WPA2-EAP)
   - Try WPA2-PSK if having issues

4. **Signal strength**:
   - Device must be within WiFi range
   - Metal heat pump cabinet may block signal
   - Use WiFi analyzer app to check signal strength

## Advantages of Network Connection

✅ **Flexibility**: Place your Home Assistant server anywhere on your network  
✅ **No USB cables**: Cleaner installation without long USB cables running through house  
✅ **WiFi option**: Can use WiFi if Ethernet is not available at heat pump location  
✅ **Remote location**: Heat pump can be in basement/garage while HA is elsewhere  
✅ **Multiple connections**: Can potentially share RS-485 with other monitoring tools  
✅ **No USB reliability issues**: Network protocols more robust than USB serial  
✅ **Easier troubleshooting**: Can test connection with standard network tools  

## Important Notes

⚠️ **Critical Configuration Requirements:**

- The Waveshare device must be configured as **TCP Server** (waiting for connections), NOT TCP Client
- **Data Transfer Mode** must be set to **Transparent Mode** (not Modbus or other modes)
- Serial parameters must be **exactly**: 19200 baud, 8 data bits, **EVEN parity**, 1 stop bit
- Enable **Baudrate adaptive (RFC2117)** if available
- The **parity setting is critical** - using "None" will not work
- **TCP mode is recommended** over Telnet/RFC2217 for better reliability
- Keep the device on a **stable network connection** (Ethernet strongly preferred over WiFi)

🔒 **Security Considerations:**

- Waveshare devices typically have minimal security
- Consider placing on isolated VLAN if security is a concern
- Change default passwords immediately
- Don't expose to internet without VPN

⚡ **Power Recommendations:**

- Use official power adapter for best reliability
- USB power from computers can be unstable
- Consider UPS backup if network stability is critical

## Quick Reference: Serial Parameters

**Remember these EXACT values:**

| Parameter                   | Value                | Why                                |
|-----------------------------|----------------------|------------------------------------|
| Data Transfer Mode          | Transparent Mode     | Passes data without modification   |
| Baudrate                    | 19200                | Aurora protocol requirement        |
| Data Bits                   | 8                    | Standard byte size                 |
| **Parity**                  | **Even**             | Required by Aurora protocol        |
| Stop (Stop Bits)            | 1                    | Standard                           |
| Baudrate adaptive (RFC2117) | Enable               | Allows automatic configuration     |
| Flow Control                | None                 | Not needed for RS-485              |
| Mode / Interface            | RS-485               | Physical layer requirement         |

**Copy these into Waveshare:** `19200 8E1` (shorthand notation for UART settings)

## Supported Waveshare Models

### Recommended Models

**RS232/485_TO_WIFI_ETH_(B)** ⭐ Best Choice

- Supports both Ethernet and WiFi
- Dual connectivity options
- Most flexible installation
- [Product Link](https://www.waveshare.com/rs232-485-to-wifi-eth-b.htm)

#### RS232/485_TO_ETH

- Ethernet only (no WiFi)
- More stable than WiFi
- Good for permanent installations
- Lower cost

### Configuration Differences

**Model B (newer):**

- Modern web interface
- Better WiFi support
- Easier configuration
- More stable firmware

**Older models:**

- May require Windows configuration tool
- Serial port for initial setup
- More complex to configure

### Other Compatible Devices

✅ **USR-TCP232-410s** - Popular alternative, similar features  
✅ **HI-FLYING HF5142B** - Budget option, works well  
✅ **ZLAN ZLM232** - Industrial grade, very reliable  
✅ **Moxa NPort 5110** - Enterprise grade (expensive but bulletproof)  

**Requirements for any device:**

- Must support TCP Server mode
- Must support RS-485 (not just RS-232)
- Must allow manual serial parameter configuration
- Should support configurable local port

❌ **Not compatible:**

- Devices that only support USB-to-Serial (no network)
- Devices that only support RS-232 (RS-485 required)
- Devices locked to specific protocols/software

## Alternative Setup: ser2net

If you have a USB RS-485 adapter connected to another machine (like a Raspberry Pi near your heat pump), you can use `ser2net` to create a network serial port bridge.

### When to Use ser2net

✅ Already have a spare Raspberry Pi or Linux machine near heat pump  
✅ Want to reuse existing USB RS-485 adapter  
✅ More comfortable with Linux command line  
✅ Want more control and flexibility  
✅ Already have USB adapter and don't want to buy Waveshare  

### Installation Steps

#### 1. Install ser2net

On Raspberry Pi or Debian/Ubuntu:

```bash
sudo apt update
sudo apt install ser2net
```

On other Linux distributions:

```bash
# Fedora/RHEL
sudo dnf install ser2net

# Arch
sudo pacman -S ser2net
```

#### 2. Find Your USB Device

```bash
# List USB serial devices
ls -l /dev/ttyUSB*
# or
dmesg | grep tty

# Example output: /dev/ttyUSB0
```

#### 3. Configure ser2net

Modern ser2net (version 4.x+) uses YAML format:

**Edit `/etc/ser2net.yaml`:**

```yaml
%YAML 1.1
---
connection: &aurora
    accepter: tcp,2000
    enable: on
    options:
      kickolduser: true
      telnet-brk-on-sync: true
    connector: serialdev,
              /dev/ttyUSB0,
              19200,
              8DATABITS,
              EVEN,
              1STOPBIT,
              -XONXOFF,
              -RTSCTS
```

**For older ser2net (version 3.x):**

**Edit `/etc/ser2net.conf`:**

```text
# Port:baudrate:parity:databits:stopbits:flow
2000:raw:600:/dev/ttyUSB0:19200 8DATABITS EVEN 1STOPBIT -XONXOFF -RTSCTS
```

#### 4. Start ser2net Service

```bash
# Enable and start
sudo systemctl enable ser2net
sudo systemctl start ser2net

# Check status
sudo systemctl status ser2net

# View logs
sudo journalctl -u ser2net -f
```

#### 5. Test Connection

From another machine:

```bash
# Test if port is accessible
telnet 192.168.1.50 2000  # Use your Raspberry Pi's IP

# Should connect successfully
# Ctrl+] then 'quit' to exit
```

#### 6. Configure Add-on

Use the IP of your Raspberry Pi/Linux machine:

```yaml
connection_type: network
network_host: 192.168.1.50  # Your ser2net machine IP
network_port: 2000
network_protocol: tcp
mqtt_host: core-mosquitto
mqtt_port: 1883
```

### Troubleshooting ser2net

**Permission denied on /dev/ttyUSB0:**

```bash
# Add user to dialout group
sudo usermod -a -G dialout $USER
# Or give permissions directly
sudo chmod 666 /dev/ttyUSB0
```

**ser2net won't start:**

```bash
# Check configuration syntax
sudo ser2net -c /etc/ser2net.yaml -d

# Check if port 2000 is already in use
sudo netstat -tlnp | grep 2000
sudo lsof -i :2000
```

**Connection works but no data:**

- Verify baud rate: **19200**
- Verify parity: **EVEN** (critical!)
- Check USB device path is correct
- Try different USB port

### ser2net vs Waveshare

**ser2net Advantages:**

- ✅ Free (if you have spare hardware)
- ✅ More control and flexibility
- ✅ Open source software
- ✅ Can log serial data for debugging
- ✅ Can share serial port with multiple TCP connections

**Waveshare Advantages:**

- ✅ Purpose-built hardware
- ✅ No separate machine needed
- ✅ Lower power consumption
- ✅ Web interface (easier configuration)
- ✅ More compact
- ✅ WiFi option

## See Also

- [Basic Configuration](basic.md) - Add-on configuration options
- [Hardware Setup](../getting-started/hardware.md) - Cable creation and USB connections
- [MQTT Setup](../getting-started/mqtt-setup.md) - MQTT broker setup instructions
- [Troubleshooting](../troubleshooting/connection-issues.md) - Connection issues and debugging
- Waveshare product page and manual for device-specific details

## Troubleshooting Flowchart

**Start here when things don't work:**

```text
┌─────────────────────────────────────┐
│  Can you ping the Waveshare IP?    │
└────────────┬────────────────────────┘
             │
       ┌─────┴─────┐
       │    NO     │
       └─────┬─────┘
             │
   ┌─────────▼──────────┐
   │ Check:             │
   │ • Power connected  │
   │ • Ethernet cable   │
   │ • Correct IP       │
   │ • Same network     │
   └────────────────────┘
             
       ┌─────┴─────┐
       │    YES    │
       └─────┬─────┘
             │
┌────────────▼──────────────────────┐
│ Can you telnet to port 2000?      │
│ (telnet IP 2000)                   │
└────────────┬───────────────────────┘
             │
       ┌─────┴─────┐
       │    NO     │
       └─────┬─────┘
             │
   ┌─────────▼──────────────┐
   │ Check Waveshare:       │
   │ • In TCP Server mode?  │
   │ • Port = 2000?         │
   │ • Firewall disabled?   │
   │ • Reboot device        │
   └────────────────────────┘
             
       ┌─────┴─────┐
       │    YES    │
       └─────┬─────┘
             │
┌────────────▼──────────────────────┐
│ Does add-on start and connect?    │
└────────────┬───────────────────────┘
             │
       ┌─────┴─────┐
       │    NO     │
       └─────┬─────┘
             │
   ┌─────────▼──────────────┐
   │ Check add-on config:   │
   │ • network_host = IP?   │
   │ • network_port = 2000? │
   │ • Check add-on logs    │
   └────────────────────────┘
             
       ┌─────┴─────┐
       │    YES    │
       └─────┬─────┘
             │
┌────────────▼──────────────────────┐
│ Do you see MQTT messages?         │
│ (Developer Tools → MQTT)           │
└────────────┬───────────────────────┘
             │
       ┌─────┴─────┐
       │    NO     │
       └─────┬─────┘
             │
   ┌─────────▼─────────────────────┐
   │ Check serial parameters:      │
   │ • Baud = 19200?               │
   │ • Parity = EVEN? ←CRITICAL    │
   │ • Mode = RS-485?              │
   │ • Check A+/B- wiring          │
   │ • Try swap A+ and B-          │
   └───────────────────────────────┘
             
       ┌─────┴─────┐
       │    YES    │
       └─────┬─────┘
             │
    ┌────────▼────────┐
    │ ✅ SUCCESS!     │
    │ Check Devices   │
    │ & Services for  │
    │ new entities    │
    └─────────────────┘
```

## Common Configuration Mistakes

❌ **Wrong:** Modbus or other mode → ✅ **Correct:** Transparent Mode  
❌ **Wrong:** Baud rate 9600 → ✅ **Correct:** Baudrate 19200  
❌ **Wrong:** Parity None → ✅ **Correct:** Parity Even  
❌ **Wrong:** Baudrate adaptive disabled → ✅ **Correct:** Baudrate adaptive (RFC2117) Enabled  
❌ **Wrong:** TCP Client mode → ✅ **Correct:** TCP Server mode  
❌ **Wrong:** RS-232 mode → ✅ **Correct:** RS-485 mode  
❌ **Wrong:** Using port 23 (telnet) → ✅ **Correct:** Use port 2000+ (or your choice)  
❌ **Wrong:** Dynamic IP (changes) → ✅ **Correct:** Static IP or DHCP reservation  

## Getting Help

If you're still stuck after following this guide:

1. **Check add-on logs** - Settings → Add-ons → WaterFurnace Aurora → Log tab
2. **Enable debug logging** - Set `log_level: debug` in add-on configuration
3. **Test with tools** - Use ping, telnet, netcat to test connectivity
4. **Verify serial settings** - Triple-check 19200 8E1 in Waveshare config
5. **Check GitHub Issues** - [Search existing issues](https://github.com/atheismann/home-assistant-aurora-ruby-addon/issues)
6. **Create issue** - Include logs, config, and what you've already tried

**When asking for help, provide:**

- Full add-on logs (with debug enabled)
- Waveshare model and firmware version  
- Network topology (same VLAN? WiFi? Ethernet?)
- What you've already tried from this guide
