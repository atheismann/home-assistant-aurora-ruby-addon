# Prerequisites

Before you begin, make sure you have everything you need.

## Hardware Requirements

### Choose Your Connection Method

#### Option A: USB RS-485 Adapter (Direct)

**Required:**

- USB to RS-485 adapter
  - ✅ **Recommended**: Adapters based on FTDI or CH340 chips
  - ❌ **NOT Compatible**: Adapters based on MAX485 chip
  - Examples: [This adapter](https://www.amazon.com/dp/B07B416CPK) or [this one](https://www.amazon.com/dp/B081MB6PN2)
- Custom cable (RJ45 to bare wires)
- WaterFurnace Aurora heat pump with AID Tool port

**Pros:**

- Simpler setup
- Lower cost
- Direct connection

**Cons:**

- Home Assistant must be physically close to heat pump
- USB cable length limitations

#### Option B: Network RS-485 Adapter (Ethernet/WiFi)

**Required:**

- Waveshare RS232/485_TO_WIFI_ETH_(B) or similar network adapter
- Custom cable (RJ45 to bare wires)
- WaterFurnace Aurora heat pump with AID Tool port
- Network connection (Ethernet or WiFi)

**Pros:**

- Flexible placement - heat pump can be anywhere on network
- No USB cables running through house
- WiFi option available

**Cons:**

- Additional hardware cost (~$30-50)
- Requires network configuration
- See [Configuration Guide](../configuration/network-adapters.md) for detailed setup

## Software Requirements

### 1. Home Assistant

Any installation method works:

- Home Assistant OS (recommended)
- Home Assistant Container
- Home Assistant Supervised
- Home Assistant Core

### 2. MQTT Broker (REQUIRED!)

**This add-on REQUIRES an MQTT broker** - it does NOT include its own.

If you don't already have it:

1. Install the **Mosquitto broker** add-on
2. See [MQTT Setup Guide](mqtt-setup.md) for complete instructions

⚠️ **Important**: The MQTT broker must be running before you start this add-on!

## Heat Pump Compatibility

### Compatible Systems

✅ **WaterFurnace heat pumps with Aurora control boards**

- Most models from 2010 or newer
- Look for "Aurora" branding on the control board
- Must have an **AID Tool** port (RJ45 jack)

### How to Check

1. Locate your heat pump's control board (usually inside the unit)
2. Look for an RJ45 jack labeled "AID Tool" or "Service Port"
3. Check the board for "Aurora" or "ABC" (Aurora Board Controller) markings

### Not Compatible

❌ Older WaterFurnace systems without Aurora boards  
❌ Non-WaterFurnace heat pumps  
❌ Systems with different control systems  

**If unsure**: Contact your WaterFurnace dealer with your model and serial number.

## Cable Materials

To create the custom connection cable, you'll need:

### Materials List

- **RJ45 connector** (or existing ethernet cable to modify)
- **CAT5e or CAT6 ethernet cable** (recommended)
  - Length depends on your setup
  - For USB: Up to 15-20 feet
  - For network: Any length your network supports
- **Crimping tool** (if making RJ45 connector from scratch)
- **Wire strippers**
- **Heat shrink tubing or electrical tape** (for insulation)

### Where to Buy

- Local hardware store
- Amazon/online retailers
- Electronics suppliers

## Tools Needed

- Wire strippers
- Small screwdriver (for RS-485 terminal blocks)
- Multimeter (optional, for testing continuity)
- Label maker or tape (optional, for marking wires)

## Network Requirements (For Network Adapters Only)

If using a Waveshare or similar network adapter:

- **Static IP address** or DHCP reservation recommended
- **Same network/VLAN** as Home Assistant (or routing configured)
- **Port access**: Typically TCP port 2000 (configurable)
- **Web browser access** to adapter for initial configuration

## Pre-Installation Checklist

Before proceeding to installation, confirm:

- [ ] I have chosen my connection method (USB or Network)
- [ ] I have the required hardware adapter
- [ ] Home Assistant is installed and running
- [ ] I have or will install the Mosquitto broker add-on
- [ ] My heat pump has an AID Tool port
- [ ] I have materials to create the cable
- [ ] For network: I can access my network adapter's web interface

## What's Next?

Once you have everything ready:

1. **[Hardware Setup](hardware.md)** - Create the cable and make connections
2. **[MQTT Setup](mqtt-setup.md)** - Install and configure MQTT broker
3. **[Installation](installation.md)** - Install and configure the add-on

## Still Have Questions?

- **Network adapter setup**: See [Network Adapters Guide](../configuration/network-adapters.md)
- **Troubleshooting**: See [Troubleshooting Index](../troubleshooting/)
- **Configuration options**: See [Configuration Guide](../configuration/basic.md)
