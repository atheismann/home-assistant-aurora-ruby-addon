# Waveshare RS232/485_TO_WIFI_ETH_(B) Setup Guide

## Overview

The Waveshare RS232/485_TO_WIFI_ETH_(B) is a network-based RS-485 adapter that allows you to connect your WaterFurnace heat pump over Ethernet or WiFi instead of USB. This is useful for:

- Remote installations where the heat pump is far from your Home Assistant server
- Cleaner cable management (use existing network infrastructure)
- Wireless connectivity options

## Hardware Setup

### 1. Connect the Waveshare Device to Your Heat Pump

Create the same cable as described in INSTALL.md:

## Cable Wiring

Your heat pump uses a standard ethernet cable for the RS-485 connection:

- Pins 1+3 (white-orange + white-green) → A+ terminal on Waveshare
- Pins 2+6 (orange + green)             → B- terminal on Waveshare

Alternatively (TIA-568-B standard):

- Pins 1+2 (white-orange + orange)     → A+ terminal on Waveshare
- Pins 3+6 (white-green + green)       → B- terminal on Waveshare

### 2. Configure the Waveshare Device

The Waveshare device needs to be configured for RS-485 communication with the correct serial parameters.

#### Connection to Waveshare

1. Connect the Waveshare device to your network via Ethernet
2. Power it on (it can be powered via USB or the included power adapter)
3. Find its IP address (check your router's DHCP client list or use the manufacturer's tool)

#### Web Interface Configuration

1. Open a web browser and navigate to the device's IP address
2. Login (default username/password is usually `admin`/`admin`)
3. Configure the serial port settings:

**Required Serial Parameters:**

```text
Baud Rate: 19200
Data Bits: 8
Parity: EVEN
Stop Bits: 1
Flow Control: None
```

**Network Settings:**

```text
Protocol: TCP Server or TCP Client (TCP Server recommended)
Port: 2000 (or your choice)
```

**Operating Mode:**

- Select "RS-485" mode (NOT RS-232)

1. Save the configuration and reboot the device

#### Alternative: Telnet/RFC2217 Mode

If the device supports RFC2217 protocol, you can use telnet mode which allows the serial parameters to be set automatically:

```text
Protocol: RFC2217 (Telnet)
Port: 2217 (or your choice)
```

## Add-on Configuration

### For TCP Connection

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
```

### For Telnet/RFC2217 Connection

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
```

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

### Cannot Connect to Device

1. **Verify IP address**: Ping the device to ensure it's reachable

   ```bash
   ping 192.168.1.100
   ```

2. **Check port**: Use telnet to verify the port is open

   ```bash
   telnet 192.168.1.100 2000
   ```

3. **Firewall**: Ensure no firewall is blocking the connection

### No Data Received

1. **Verify serial settings**: Double-check baud rate (19200), parity (EVEN), and RS-485 mode
2. **Check wiring**: Ensure A+ and B- are correctly connected
3. **Try reversing A+ and B-**: Sometimes polarity can be confusing

### Connection Drops

1. **TCP Keepalive**: Enable TCP keepalive in the Waveshare settings
2. **Network stability**: Check for network issues or interference (if using WiFi)
3. **Power supply**: Ensure stable power to the Waveshare device

## Advantages of Network Connection

✅ **Flexibility**: Place your Home Assistant server anywhere on your network
✅ **No USB cables**: Cleaner installation without long USB cables
✅ **WiFi option**: Can use WiFi if Ethernet is not available
✅ **Multiple connections**: Can potentially share the RS-485 connection with other tools

## Important Notes

- The Waveshare device must be configured as a **server** (waiting for connections), not a client
- The serial parameters (19200, 8, EVEN, 1) are critical - incorrect settings will not work
- **TCP mode is recommended** over Telnet for better reliability
- Use RFC2217/Telnet mode only if you need automatic serial parameter configuration
- Keep the device on a stable network connection (Ethernet preferred over WiFi)

## Supported Waveshare Models

- **RS232/485_TO_WIFI_ETH_(B)** - Recommended, has both Ethernet and WiFi
- **RS232/485_TO_ETH** - Ethernet only version
- Similar devices from other manufacturers should work if they support TCP server mode

## Alternative Setup: ser2net

If you have a USB RS-485 adapter connected to another machine, you can also use `ser2net` to create a network serial port:

```bash
# Install ser2net on the machine with USB adapter
sudo apt install ser2net

# Configure ser2net (/etc/ser2net.yaml)
connection: &rs485
    accepter: tcp,2000
    connector: serialdev,/dev/ttyUSB0,19200e81
    options:
      kickolduser: true
```

Then use the same network configuration in the add-on, pointing to the machine running ser2net.

## See Also

- [INSTALL.md](INSTALL.md) - General installation guide
- [README.md](README.md) - Add-on overview
- Waveshare product page and manual for device-specific details
