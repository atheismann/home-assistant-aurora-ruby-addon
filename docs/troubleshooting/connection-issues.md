# Connection Issues

This guide helps you troubleshoot connection problems between the add-on and your heat pump.

## Symptoms

- Add-on logs show "Connection refused", "Connection timeout", or "ModBus timeout"
- Add-on starts but never connects to heat pump
- Entities show "Unavailable" in Home Assistant
- Web AID Tool (`http://<home-assistant-ip>:8080`) shows no data or error

## Serial Connection Issues

For USB RS-485 adapters connected directly to Home Assistant.

### Device Not Found

**Error**: `Could not open serial port /dev/ttyUSB0`

**Solutions**:

1. **Check device exists**:
   ```bash
   ls -la /dev/ttyUSB*
   ```
   - Should show device like `/dev/ttyUSB0`
   - If not found, USB adapter not recognized

2. **Try different USB port**:
   - Unplug USB adapter
   - Plug into different port
   - Wait 10 seconds
   - Check `ls -la /dev/ttyUSB*` again

3. **Check USB adapter**:
   - Try adapter on another computer
   - Some adapters have LED indicators (should be lit)
   - Verify it's a data cable, not charge-only

4. **Check Home Assistant OS USB passthrough**:
   - Some virtualization platforms require USB device passthrough
   - Check VM/container settings
   - Ensure USB device is passed through to Home Assistant

5. **Reboot Home Assistant**:
   - Sometimes needed for USB recognition
   - **Settings** → **System** → **Restart**

### Permission Denied

**Error**: `Permission denied: /dev/ttyUSB0`

**Solutions**:

1. **Check device permissions**:
   ```bash
   ls -la /dev/ttyUSB0
   ```
   - Should show: `crw-rw---- 1 root dialout`

2. **Add-on should have access**:
   - Home Assistant OS handles permissions automatically
   - If using Container/Supervised, check Docker permissions

3. **Try different adapter**:
   - Some cheap adapters have driver issues
   - FTDI-based adapters are most reliable

### ModBus Timeout (Serial)

**Error**: `ModBus timeout` or `No response from heat pump`

**This is the most common issue**. Possible causes:

#### 1. Wrong Polarity

RS-485 uses A+/B- (or T+/T-). Polarity matters!

**Solution**: Try swapping A+ and B- connections

- Disconnect power from adapter
- Swap the two wires on adapter terminal
- Reconnect power
- Restart add-on

**This is safe and often fixes the problem.**

#### 2. Incorrect Cable Wiring

**Check your cable**:

- Pins 1+3 should go to A+ (or T+)
- Pins 2+4 should go to B- (or T-)
- Pins 5-8 should NOT be connected (24VAC power)

**If you connected pins 5-8**:

- ⚠️ **STOP IMMEDIATELY**
- Disconnect cable
- Check heat pump fuse (may be blown)
- Insulate pins 5-8 with electrical tape
- See [Hardware Setup](../getting-started/hardware.md)

#### 3. Loose Connections

**Check all connections**:

- RJ45 connector firmly seated in heat pump
- Terminal screws tight on adapter
- USB connector firmly in Home Assistant host

#### 4. Wrong AID Tool Port

Some heat pumps have multiple RJ45 ports:

- **AID Tool port**: Correct port for RS-485 diagnostics
- **Thermostat port**: Wrong port, won't work
- **Network port**: Wrong port, won't work

**Solution**: Verify you're using the correct port labeled "AID Tool" or "Service Port"

#### 5. Heat Pump Not Powered

**Check heat pump has power**:

- Thermostat display should be on
- Indoor unit should have power
- Check circuit breakers

#### 6. USB Cable Too Long

**USB has distance limitations**:

- Standard USB: 5 meters (16 feet) maximum
- Longer distances may cause signal degradation
- Active USB extension cables can help

**Solution**: Move Home Assistant closer or use network adapter

### Debugging Serial Connection

Enable debug logging to see RS-485 communication:

1. Set `log_level: debug` in add-on configuration
2. Restart add-on
3. Check logs for packet details

See **[Debug RS-485 Guide](debug-rs485.md)** for interpreting output.

## Network Connection Issues

For Waveshare or other network RS-485 adapters.

### Can't Reach Network Adapter

**Error**: `Connection refused` or `Connection timeout`

**Solutions**:

1. **Verify adapter IP address**:
   ```bash
   ping <network_host>
   ```
   - Should get responses
   - If not, adapter is unreachable

2. **Check network connection**:
   - **Ethernet**: Cable plugged into adapter and switch
   - **WiFi**: Adapter connected to WiFi network
   - LED indicators (if present) should show network activity

3. **Check IP address**:
   - Did adapter IP change? (DHCP may assign new IP)
   - Check router DHCP client list
   - Use DHCP reservation for static IP
   - Try accessing adapter web interface

4. **Check network configuration**:
   - Is adapter on same network/VLAN?
   - Firewall blocking connection?
   - Try from another device: `telnet <network_host> <network_port>`

5. **Verify port number**:
   - Default Waveshare port: `8899`
   - Must match port configured in adapter
   - Check adapter web interface

6. **Power cycle adapter**:
   - Unplug power
   - Wait 10 seconds
   - Plug back in
   - Wait for adapter to boot (30-60 seconds)

### Wrong Protocol

**Error**: Connection established but no data or garbled data

**Solutions**:

1. **Check protocol setting**:
   - Waveshare: Use `tcp` protocol
   - Some adapters: Use `telnet` protocol
   - Try both if unsure

2. **Test with netcat**:
   ```bash
   nc <network_host> <network_port>
   ```
   - Type some text and press Enter
   - Should see response (may be binary data)
   - Ctrl+C to exit

### ModBus Timeout (Network)

**Error**: `ModBus timeout` or `No response from heat pump`

**Network adapters require correct serial parameters!**

#### 1. Wrong Serial Parameters

**CRITICAL**: Adapter must be configured for Aurora protocol.

**Required settings**:

- Baud rate: **19200**
- Data bits: **8**
- Parity: **Even**
- Stop bits: **1**
- Flow control: **None**

**Solution**: Configure adapter serial parameters

See **[Network Adapters Configuration](../configuration/network-adapters.md)** for Waveshare setup.

**Common mistakes**:

- ❌ Wrong baud rate (9600, 38400, 115200 won't work)
- ❌ Using "None" for parity (must be EVEN/Even)
- ❌ Wrong adapter mode (use Transparent mode, not Modbus mode)

#### 2. Wrong Work Mode

**Waveshare adapters have multiple modes**:

- **Transparent mode**: Correct for Aurora (passes data through)
- **Modbus mode**: Wrong (interprets data as Modbus RTU)
- **HTTP mode**: Wrong

**Solution**: Set adapter to Transparent mode

#### 3. Wrong Polarity (Network)

Same as serial - try swapping A+ and B-:

- Power off adapter
- Swap wires on RS-485 terminals
- Power on adapter
- Restart add-on

#### 4. Network Latency

**High latency can cause timeouts**:

- WiFi adapters more prone to latency than Ethernet
- Network congestion
- Weak WiFi signal

**Solutions**:

- Use Ethernet instead of WiFi (strongly recommended)
- Move adapter closer to WiFi access point
- Use 5 GHz WiFi instead of 2.4 GHz
- Check network for congestion

#### 5. Incorrect Cable Wiring

Same checks as serial connection:

- Verify pins 1+3 → A+
- Verify pins 2+4 → B-
- Verify pins 5-8 NOT connected
- See [Hardware Setup](../getting-started/hardware.md)

### Debugging Network Connection

Enable debug logging to see network packets:

1. Set `log_level: debug` in add-on configuration
2. Restart add-on
3. Check logs for tcpdump output (packet capture)

See **[Debug RS-485 Guide](debug-rs485.md)** for interpreting output.

## General Troubleshooting

### Try Different Adapter

If you have a spare USB or network adapter, try swapping:

- Rules out adapter hardware failure
- Different adapter may have better drivers
- Some cheap adapters are unreliable

### Check Heat Pump Communication

**Verify heat pump is responsive**:

1. Access heat pump control panel (if available)
2. Navigate to service/diagnostic menu
3. Check if heat pump responds to button presses

**Some heat pumps**:

- May have RS-485 disabled in settings
- May have communication lockout after too many errors
- May require power cycle to reset communication

**Solution**: Power cycle heat pump

- Turn off circuit breaker
- Wait 30 seconds
- Turn back on
- Wait for heat pump to fully boot (2-3 minutes)
- Try connecting again

### Check for Interference

**RS-485 can be affected by**:

- Electrical noise from motors, pumps
- Poor quality power supply
- Nearby high-voltage lines
- Fluorescent lights

**Solutions**:

- Use shielded cable (if using long runs)
- Route cable away from power lines
- Use ferrite beads on cable
- Ground shield at one end only

### Verify Add-on Configuration

Double-check configuration:

```yaml
# Serial example
connection_type: serial  # Must be lowercase
serial_port: /dev/ttyUSB0  # Exact device path

# Network example  
connection_type: network  # Must be lowercase
network_host: 192.168.1.100  # Valid IP address
network_port: 8899  # Valid port number
network_protocol: tcp  # Must be tcp or telnet
```

## Advanced Debugging

### Enable Maximum Logging

Set all logging to most verbose:

```yaml
log_level: debug
```

This enables:

- tcpdump (network mode) - captures all packets
- strace (serial mode) - traces system calls
- MODBUS_DEBUG - shows ModBus protocol details

See **[Debug RS-485 Guide](debug-rs485.md)** for details.

### Test with Web AID Tool

The add-on includes a debug web interface:

1. Open: `http://<home-assistant-ip>:8080`
2. If shows data: Heat pump connection works, issue is with MQTT
3. If shows error: Heat pump connection problem
4. If can't connect: Add-on not running

### Test with Manual Tools

**Serial mode** - test with screen:

```bash
screen /dev/ttyUSB0 19200,cs8,parenb,-parodd
```

- Should see binary data if heat pump is responding
- Ctrl+A, K to exit

**Network mode** - test with netcat:

```bash
nc <network_host> <network_port>
```

- Should be able to connect
- May see binary data

## Still Having Issues?

If none of the above helps:

1. **Enable debug logging**: `log_level: debug`
2. **Gather logs**: Copy full add-on log
3. **Document your setup**:
   - Connection type (serial/network)
   - Adapter model
   - Cable configuration
   - Configuration (redact passwords)
4. **Open an issue**: https://github.com/atheismann/home-assistant-aurora-ruby-addon/issues

See **[Troubleshooting Guide](README.md)** for more help.

## Related Documentation

- **[Hardware Setup](../getting-started/hardware.md)** - Cable creation and physical connections
- **[Network Adapters](../configuration/network-adapters.md)** - Waveshare configuration
- **[Debug RS-485](debug-rs485.md)** - Detailed RS-485 debugging
- **[Configuration](../configuration/basic.md)** - Configuration reference
