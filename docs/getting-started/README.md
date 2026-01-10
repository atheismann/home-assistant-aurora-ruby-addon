# Getting Started with WaterFurnace Aurora Add-on

Welcome! This guide will help you get your WaterFurnace heat pump connected to Home Assistant.

## Quick Navigation

- **[📋 Prerequisites](prerequisites.md)** - What you need before starting
- **[🔌 Hardware Setup](hardware.md)** - Cable creation and physical connections
- **[💬 MQTT Setup](mqtt-setup.md)** - Setting up the MQTT broker (required!)
- **[⚙️ Installation](installation.md)** - Step-by-step installation and configuration

## Overview

This add-on connects your WaterFurnace Aurora heat pump to Home Assistant via RS-485, allowing you to:

✅ Monitor temperatures, power usage, and system status  
✅ Control thermostat settings  
✅ View diagnostics and performance data  
✅ Create automations based on heat pump state  

## Installation Path

Choose your connection method:

### Option A: USB RS-485 Adapter (Direct Connection)

```
Heat Pump → Custom Cable → USB Adapter → Home Assistant
```

**Best for:** Heat pump close to Home Assistant server

### Option B: Network RS-485 Adapter (Waveshare)

```
Heat Pump → Custom Cable → Waveshare → Network → Home Assistant
```

**Best for:** Heat pump far from server, or WiFi/Ethernet preferred

## Estimated Time

- **First-time setup**: 30-60 minutes
- **If you have experience**: 15-30 minutes
- **Cable creation**: 10-20 minutes (if making from scratch)

## What's Next?

1. Start with **[Prerequisites](prerequisites.md)** to see what hardware you need
2. Follow **[Hardware Setup](hardware.md)** to create the cable
3. Set up **[MQTT](mqtt-setup.md)** (required!)
4. Complete the **[Installation](installation.md)**

## Need Help?

- **Configuration help**: See [../configuration/](../configuration/)
- **Troubleshooting**: See [../troubleshooting/](../troubleshooting/)
- **Network adapters**: See [../configuration/network-adapters.md](../configuration/network-adapters.md)

## Quick Links

- [Main README](../../README.md)
- [Configuration Options](../configuration/basic.md)
- [Troubleshooting Index](../troubleshooting/)
