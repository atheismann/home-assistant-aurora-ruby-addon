# Hardware Setup

This guide will help you create the cable and make the physical connections.

## Safety Warning

⚠️ **IMPORTANT SAFETY INFORMATION**

- Pins 5-8 on the AID Tool port carry **24VAC power**
- **DO NOT** connect these pins to anything
- **DO NOT** short power pins to ground or communication lines
- Doing so may blow a fuse or damage the control board
- When in doubt, consult a professional HVAC technician

## Cable Creation

### Understanding the Wiring

The heat pump's AID Tool port uses a standard RJ45 ethernet connector, but only uses 4 of the 8 pins for RS-485 communication.

**Pin Assignments:**

| RJ45 Pin | Wire Color (T568B) | Purpose     | Connection            |
|----------|-------------------|-------------|-----------------------|
| 1        | White-Orange      | RS-485 A+   | Connect to A+         |
| 2        | Orange            | RS-485 B-   | Connect to B-         |
| 3        | White-Green       | RS-485 A+   | Connect to A+         |
| 4        | Blue              | RS-485 B-   | Connect to B-         |
| 5        | White-Blue        | 24VAC (C)   | ❌ DO NOT CONNECT     |
| 6        | Green             | 24VAC (C)   | ❌ DO NOT CONNECT     |
| 7        | White-Brown       | 24VAC (R)   | ❌ DO NOT CONNECT     |
| 8        | Brown             | 24VAC (R)   | ❌ DO NOT CONNECT     |

### Wiring Diagram

```text
RJ45 Connector (AID Tool Port)               RS-485 Adapter
┌────────────────────┐
│ 1 2 3 4 5 6 7 8   │
│ │ │ │ │ X X X X   │              ┌──────────────┐
│ │ │ │ │           │              │              │
│ └─┴─┘ └─┘         │──────────────┤  A+ or T+    │
│   │     │         │              │  B- or T-    │
│   │     │         │              │              │
│   A+    B-        │              └──────────────┘
└────────────────────┘

Pins 1+3 twisted together → A+ terminal
Pins 2+4 twisted together → B- terminal
Pins 5-8 isolated and capped
```

### Step-by-Step Cable Creation

#### Option 1: Modify Existing Cable

**Materials**: Existing ethernet cable, wire strippers, electrical tape

**Steps**:

1. Take an ethernet cable (any length needed)
2. Cut off ONE end of the cable
3. Strip back about 2 inches of outer jacket
4. Untwist and identify the 8 wires by color
5. Group wires:
   - **A+ Group**: White-Orange (pin 1) + White-Green (pin 3)
   - **B- Group**: Orange (pin 2) + Blue (pin 4)
   - **DO NOT USE**: White-Blue, Green, White-Brown, Brown (pins 5-8)
6. Twist together each group:
   - Twist white-orange and white-green together tightly
   - Twist orange and blue together tightly
7. Strip 1/4" from the end of each twisted pair
8. **CRITICAL**: Cap/tape the unused wires (pins 5-8) individually
   - Wrap each unused wire tip with electrical tape
   - Ensure they cannot touch anything

#### Option 2: Crimp New Cable

**Materials**: Bulk CAT5/6 cable, RJ45 connectors, crimping tool

**Steps**:

1. Cut cable to desired length
2. Strip and crimp ONE end with RJ45 connector (T568B standard)
3. At OTHER end, follow "Option 1" steps 3-8 above
4. Test RJ45 end with cable tester (optional but recommended)

### Cable Testing (Optional but Recommended)

Use a multimeter to verify continuity:

1. Set multimeter to continuity/resistance mode
2. Touch probes to:
   - Pins 1 & 3 (should have continuity to each other and A+ wire)
   - Pins 2 & 4 (should have continuity to each other and B- wire)
   - Pins 5-8 (should have NO continuity to anything)

## Physical Connections

### Locating the AID Tool Port

**On your heat pump:**

1. Open the service panel (may require removing screws)
2. Locate the control board (usually labeled ABC or Aurora Board Controller)
3. Find the RJ45 jack labeled:
   - "AID Tool"
   - "Service Port"
   - "Diagnostic Port"
   - Or similar

**Common locations:**

- On the main control board
- Inside a weather-protected box
- Behind an access panel
- Near the thermostat connections

**What it looks like:**

- Standard ethernet jack (RJ45)
- Usually the only RJ45 port labeled for service/diagnostics
- May have a dust cover

### Connection Type A: USB RS-485 Adapter

**Equipment needed:**

- Your custom cable (RJ45 to bare wires)
- USB RS-485 adapter
- Your Home Assistant host with USB port

**Steps**:

1. **Power off heat pump** (recommended for safety, not required)
2. Plug RJ45 end into heat pump's AID Tool port
3. At adapter end:
   - Connect A+ twisted pair to adapter's A+/T+/D+ terminal
   - Connect B- twisted pair to adapter's B-/T-/D- terminal
   - Ensure unused wires are capped and not touching anything
4. Tighten terminal screws securely
5. Plug USB connector into Home Assistant host
6. **Power on heat pump** (if you powered it off)

**Terminal labels vary**:

- Some adapters use: A+/B-
- Some use: T+/T- or D+/D-
- Some use: +/- with 485 marking
- Check your adapter's documentation

### Connection Type B: Network RS-485 Adapter (Waveshare)

**Equipment needed:**

- Your custom cable (RJ45 to bare wires)
- Waveshare or similar network adapter
- Power supply for adapter
- Network connection (Ethernet cable or WiFi)

**Steps**:

1. **Power off heat pump** (recommended for safety, not required)
2. Plug RJ45 end into heat pump's AID Tool port
3. At adapter end:
   - Connect A+ twisted pair to adapter's RS-485 A+ terminal
   - Connect B- twisted pair to adapter's RS-485 B- terminal
   - Ensure unused wires are capped
4. Connect adapter to network:
   - **Ethernet**: Plug Ethernet cable into adapter and network switch
   - **WiFi**: Configure WiFi via adapter's web interface
5. Connect power to adapter
6. **Power on heat pump** (if you powered it off)

**Next steps for network adapters**:

- See [Network Adapters Configuration Guide](../configuration/network-adapters.md)
- You must configure the adapter's serial parameters (19200 8E1)

## Verification

### Visual Inspection

- [ ] RJ45 connector firmly seated in AID Tool port
- [ ] Terminal screws tight on adapter
- [ ] Unused wires (5-8) capped and isolated
- [ ] No exposed wire strands that could short
- [ ] Cable routed safely away from moving parts

### USB Adapter

If using USB adapter, check if recognized:

```bash
# SSH into Home Assistant
ls -la /dev/ttyUSB*
# Should show device like: /dev/ttyUSB0
```

### Network Adapter

If using network adapter:

```bash
# Ping the adapter
ping <ADAPTER_IP>
# Should get responses
```

## Troubleshooting

### No USB device appearing

- Try different USB port
- Check if adapter has LED indicator (should be lit)
- Verify USB cable is data capable (not charge-only)
- Reboot Home Assistant

### Can't ping network adapter

- Check power connection
- Verify Ethernet cable is good (test with laptop)
- Check if adapter is in same network/VLAN
- Look for adapter on router's DHCP list

### Heat pump seems unresponsive

- Verify heat pump has power (thermostat display on)
- Try reversing A+ and B- connections (polarity can be confusing)
- Check cable connections are secure
- Ensure using correct port (AID Tool, not thermostat port)

## What's Next?

Now that hardware is connected:

1. **[MQTT Setup](mqtt-setup.md)** - Install MQTT broker (if not done yet)
2. **[Installation](installation.md)** - Install and configure the add-on
3. **[Configuration](../configuration/)** - Configure connection settings

## Additional Resources

- **Network adapter details**: [Network Adapters Guide](../configuration/network-adapters.md)
- **Troubleshooting**: [Connection Issues](../troubleshooting/connection-issues.md)
- **Cable photos/diagrams**: Check the main repository for visual guides
