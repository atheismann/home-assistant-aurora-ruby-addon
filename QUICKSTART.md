# WaterFurnace Aurora Add-on - Quick Start

## What You Have

A complete Home Assistant add-on that integrates WaterFurnace Aurora heat pump systems via RS-485 communication.

## File Structure

```
aurora-ruby-addon/
├── .github/
│   └── workflows/
│       └── build.yml          # GitHub Actions build workflow
├── .gitignore                 # Git ignore rules
├── build.json                 # Multi-architecture build config
├── build.sh                   # Local build script
├── CHANGELOG.md               # Version history
├── config.json                # Add-on configuration (JSON format)
├── config.yaml                # Add-on configuration (YAML format)
├── docker-compose.yml         # Docker Compose for local testing
├── Dockerfile                 # Container image definition
├── DOCS.md                    # Add-on store documentation
├── ICON_INFO.md              # Icon setup instructions
├── INSTALL.md                # Detailed installation guide
├── LICENSE                   # MIT License
├── README.md                 # Main documentation
├── repository.yaml           # Add-on repository metadata
└── run.sh                    # Add-on startup script
```

## Next Steps

### 1. Testing Locally

```bash
cd /Users/atheismann/dev/home-automation/aurora-ruby-addon
./build.sh
```

### 2. Publishing to GitHub

```bash
cd /Users/atheismann/dev/home-automation/aurora-ruby-addon
git init
git add .
git commit -m "Initial commit: WaterFurnace Aurora add-on"
git branch -M main
git remote add origin https://github.com/yourusername/aurora-ruby-addon.git
git push -u origin main
```

### 3. Installing in Home Assistant

1. Go to **Settings** → **Add-ons** → **Add-on Store**
2. Click **⋮** → **Repositories**
3. Add: `https://github.com/yourusername/aurora-ruby-addon`
4. Install "WaterFurnace Aurora"
5. Configure and start

### 4. Configuration Required

Before using, you need to:
- Update `repository.yaml` with your GitHub username and info
- Update `config.json` image URL with your GitHub username
- Optionally add icon.png and logo.png files

## Key Features

✅ **RS-485 Serial Connection**: Direct USB connection with heat pump
✅ **Network Connection**: Ethernet/WiFi via Waveshare or similar adapters
✅ **MQTT Integration**: Publishes to Home Assistant via MQTT
✅ **Auto-Discovery**: All entities automatically appear in HA
✅ **Multi-Architecture**: Supports ARM, AMD64, and i386
✅ **Web AID Tool**: Optional web interface for diagnostics
✅ **ModBus Pass-Through**: Direct register access via MQTT

## Requirements

**Hardware:**
- USB RS-485 adapter (NOT MAX485-based) **OR** Waveshare network RS-485 adapter
- Custom RJ45 cable (see INSTALL.md for wiring)
- WaterFurnace heat pump with AID Tool port

**Software:**
- Home Assistant Mosquitto MQTT broker add-on (or another MQTT broker)
  - **Important**: This add-on does NOT include its own MQTT server
  - Install \"Mosquitto broker\" from the Home Assistant add-on store if you don't have it
  - This add-on does NOT include its own MQTT server
  - Install "Mosquitto broker" from the Home Assistant add-on store if you don't have it

## Documentation

- **README.md**: Overview and features
- **INSTALL.md**: Step-by-step installation guide
- **MQTT_SETUP.md**: MQTT broker setup and troubleshooting
- **WAVESHARE.md**: Network adapter setup guide
- **DOCS.md**: Add-on store documentation
- **config.yaml**: Configuration options

## Support

- Upstream library: https://github.com/ccutrer/waterfurnace_aurora
- Home Assistant: https://www.home-assistant.io/

## Credits

Based on the excellent waterfurnace_aurora Ruby gem by @ccutrer.
