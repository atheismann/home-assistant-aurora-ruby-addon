# MQTT Configuration

This guide covers MQTT broker setup and configuration for the Aurora MQTT Gateway.

## MQTT Overview

The Aurora MQTT Gateway publishes heat pump data to an MQTT broker using the Homie convention. Home Assistant then subscribes to these MQTT topics and automatically creates entities.

**Why MQTT?**

- Standard protocol for IoT devices
- Lightweight and efficient
- Decouples data collection from Home Assistant
- Allows multiple subscribers
- Easy debugging with MQTT tools

## Mosquitto Broker Setup

### Installing Mosquitto (Recommended)

The easiest way is to use the official Mosquitto broker add-on:

1. Navigate to **Settings** → **Add-ons** → **Add-on Store**
2. Search for "Mosquitto broker"
3. Click on **Mosquitto broker**
4. Click **Install**
5. Wait for installation to complete
6. Click **Start**
7. Enable **Start on boot**

### Creating MQTT User

After installing Mosquitto, create a user for the Aurora add-on:

1. Navigate to **Settings** → **Add-ons** → **Mosquitto broker**
2. Click the **Configuration** tab
3. Add a user to the `logins` list:

   ```yaml
   logins:
     - username: homeassistant
       password: your_secure_password_here
   ```

4. Click **Save**
5. Restart Mosquitto broker

**Security notes:**

- Use a strong password (mix of letters, numbers, symbols)
- Don't reuse passwords from other systems
- This password will be stored in the Aurora add-on configuration

### Mosquitto Configuration Options

The Mosquitto add-on has sensible defaults. Optional settings:

```yaml
logins:
  - username: homeassistant
    password: your_secure_password_here
customize:
  active: false
  folder: mosquitto
certfile: fullchain.pem
keyfile: privkey.pem
require_certificate: false
```

**Options:**

- **logins**: List of username/password pairs
- **customize**: Advanced configuration (usually not needed)
- **certfile/keyfile**: For TLS/SSL (optional)
- **require_certificate**: Client certificate auth (optional)

For basic setup, you only need to configure `logins`.

## Home Assistant MQTT Integration

### Enabling MQTT Integration

The MQTT integration should be automatically discovered. If not:

1. Navigate to **Settings** → **Devices & Services**
2. Click **Add Integration**
3. Search for "MQTT"
4. Select **MQTT**
5. Configure broker settings:
   - **Broker**: `core-mosquitto` (for built-in broker)
   - **Port**: `1883`
   - **Username**: (same as in Mosquitto config)
   - **Password**: (same as in Mosquitto config)
6. Click **Submit**

### Verifying MQTT Integration

1. Navigate to **Settings** → **Devices & Services**
2. Find **MQTT** integration
3. Should show status: **Connected**
4. Click on **MQTT** to see discovered devices

## Aurora Add-on MQTT Configuration

Configure the Aurora add-on to connect to MQTT broker:

```yaml
mqtt_host: core-mosquitto
mqtt_port: 1883
mqtt_username: homeassistant
mqtt_password: your_secure_password_here
```

**Configuration details:**

- **mqtt_host**: Use `core-mosquitto` for built-in broker
- **mqtt_port**: Default is `1883` (unencrypted)
- **mqtt_username**: Must match user in Mosquitto config
- **mqtt_password**: Must match password in Mosquitto config

## MQTT Topics

The Aurora add-on publishes using the Homie convention:

### Device-Level Topics

```
homie/aurora/$homie → "4.0"
homie/aurora/$name → "WaterFurnace Aurora Heat Pump"
homie/aurora/$state → "ready"
homie/aurora/$nodes → "heat-pump"
```

### Node-Level Topics

```
homie/aurora/heat-pump/$name → "Heat Pump"
homie/aurora/heat-pump/$type → "heat-pump"
homie/aurora/heat-pump/$properties → "lockout-temp,entering-water-temp,..."
```

### Property Topics (Sensor Data)

```
homie/aurora/heat-pump/lockout-temp → "15.5"
homie/aurora/heat-pump/lockout-temp/$name → "Lockout Temperature"
homie/aurora/heat-pump/lockout-temp/$datatype → "float"
homie/aurora/heat-pump/lockout-temp/$unit → "°C"

homie/aurora/heat-pump/entering-water-temp → "38.2"
homie/aurora/heat-pump/leaving-water-temp → "42.1"
homie/aurora/heat-pump/outdoor-temp → "5.0"
...
```

**Topic structure:**

- Base: `homie/<device-id>`
- Nodes: `homie/<device-id>/<node-id>`
- Properties: `homie/<device-id>/<node-id>/<property-id>`
- Metadata: `homie/<device-id>/<node-id>/<property-id>/$<attribute>`

### Subscribing to Topics

Use MQTT Explorer or command line to view all topics:

```bash
# Subscribe to all aurora topics
mosquitto_sub -h core-mosquitto -u homeassistant -P your_password -t 'homie/aurora/#' -v
```

Expected output:

```
homie/aurora/$homie 4.0
homie/aurora/$name WaterFurnace Aurora Heat Pump
homie/aurora/$state ready
homie/aurora/heat-pump/lockout-temp 15.5
homie/aurora/heat-pump/entering-water-temp 38.2
...
```

## Home Assistant Auto-Discovery

The Aurora add-on publishes discovery messages that Home Assistant automatically detects:

**What gets created:**

- **Device**: "WaterFurnace Aurora Heat Pump"
- **Entities**: All sensors grouped under device
- **Entity IDs**: Named like `sensor.aurora_lockout_temperature`

**Discovery process:**

1. Aurora add-on publishes Homie topics
2. Home Assistant MQTT integration detects Homie devices
3. Entities are created automatically
4. No manual configuration needed

**Viewing discovered entities:**

1. Navigate to **Settings** → **Devices & Services** → **MQTT**
2. Click on **WaterFurnace Aurora Heat Pump** device
3. See all entities listed

## Testing MQTT Connection

### Using Mosquitto Command Line

Install mosquitto-clients on your workstation:

```bash
# Ubuntu/Debian
sudo apt-get install mosquitto-clients

# macOS
brew install mosquitto

# Windows
# Download from https://mosquitto.org/download/
```

**Subscribe to topics:**

```bash
mosquitto_sub -h <home-assistant-ip> -u homeassistant -P your_password -t 'homie/aurora/#' -v
```

**Publish test message:**

```bash
mosquitto_pub -h <home-assistant-ip> -u homeassistant -P your_password -t 'test/topic' -m 'Hello'
```

### Using MQTT Explorer

MQTT Explorer is a GUI tool for viewing MQTT topics:

1. Download from: http://mqtt-explorer.com/
2. Install and open
3. Configure connection:
   - **Host**: Your Home Assistant IP
   - **Port**: `1883`
   - **Username**: `homeassistant`
   - **Password**: Your password
4. Click **Connect**
5. Browse to `homie/aurora` to see all topics

## External MQTT Broker

If you want to use an external MQTT broker instead of Mosquitto:

### Aurora Add-on Configuration

```yaml
mqtt_host: 192.168.1.50
mqtt_port: 1883
mqtt_username: aurora_user
mqtt_password: external_broker_password
```

### Home Assistant MQTT Integration

1. Navigate to **Settings** → **Devices & Services**
2. Find **MQTT** integration
3. Click **Configure**
4. Update broker settings to match external broker
5. Click **Submit**

**Both the Aurora add-on and Home Assistant MQTT integration must connect to the same broker.**

## Troubleshooting

### Aurora Add-on Can't Connect to MQTT

**Error: "Connection refused"**

Possible causes:

1. **Mosquitto not running**
   - Check **Settings** → **Add-ons** → **Mosquitto broker**
   - Ensure it's started
   - Check logs for errors

2. **Wrong hostname**
   - Use `core-mosquitto` for built-in broker
   - NOT `localhost` or `127.0.0.1`
   - NOT your Home Assistant hostname

3. **Wrong credentials**
   - Username/password must match Mosquitto config
   - Check for typos
   - Passwords are case-sensitive

4. **Firewall blocking connection**
   - Usually not an issue with built-in broker
   - For external broker, check port 1883 is open

**Error: "Authentication failed"**

- Check username and password are correct
- Ensure user exists in Mosquitto `logins` list
- Restart Mosquitto after adding user

**Error: "Connection timeout"**

- Check `mqtt_host` IP/hostname is reachable
- Try pinging: `ping core-mosquitto`
- Check network connectivity

### No Entities Appearing in Home Assistant

**Mosquitto is running, Aurora add-on connected, but no entities**

1. **Check MQTT integration**:
   - Navigate to **Settings** → **Devices & Services**
   - Ensure **MQTT** integration is configured
   - Should show "Connected"

2. **Verify topics are published**:
   ```bash
   mosquitto_sub -h core-mosquitto -u homeassistant -P your_password -t 'homie/aurora/#' -v
   ```
   - Should see messages
   - If not, check Aurora add-on logs

3. **Check discovery settings**:
   - In MQTT integration configuration
   - Ensure discovery is enabled (default)

4. **Restart Home Assistant**:
   - Sometimes needed to pick up new devices
   - **Settings** → **System** → **Restart**

### Topics Published but Entities Not Updating

**Entities exist but show "Unavailable" or old data**

1. **Check Aurora add-on is running**:
   - **Settings** → **Add-ons** → **Aurora MQTT Gateway**
   - Should show "Running"
   - Check logs for errors

2. **Check heat pump connection**:
   - Aurora add-on may be running but not connected to heat pump
   - See [Connection Issues](../troubleshooting/connection-issues.md)

3. **Check entity state**:
   - Navigate to **Developer Tools** → **States**
   - Search for `sensor.aurora_`
   - Check `last_updated` timestamp

### MQTT Broker Using Too Much Memory/CPU

**Mosquitto consuming excessive resources**

1. **Check message retention**:
   - Retained messages accumulate over time
   - Clear retained messages: `mosquitto_sub -h core-mosquitto -u homeassistant -P your_password -t '#' --remove-retained`

2. **Restart Mosquitto**:
   - **Settings** → **Add-ons** → **Mosquitto broker** → **Restart**

3. **Check for message loops**:
   - Look for excessive publish/subscribe activity
   - Check Mosquitto logs

## Advanced Configuration

### Using TLS/SSL

To encrypt MQTT communication:

1. **Get SSL certificate**:
   - Use Let's Encrypt (recommended)
   - Self-signed certificate

2. **Configure Mosquitto**:
   ```yaml
   logins:
     - username: homeassistant
       password: your_password
   certfile: fullchain.pem
   keyfile: privkey.pem
   require_certificate: false
   ```

3. **Update Aurora add-on**:
   ```yaml
   mqtt_host: core-mosquitto
   mqtt_port: 8883  # TLS port
   mqtt_username: homeassistant
   mqtt_password: your_password
   ```

### Using Client Certificates

For even more security, use client certificates:

1. **Generate client certificates**
2. **Configure Mosquitto** to require certificates
3. **Mount certificates** in Aurora add-on (advanced)

This is rarely needed for local MQTT brokers.

### Custom MQTT Prefix

The Aurora add-on uses `homie/aurora` as the topic prefix. This is currently not configurable but may be added in future versions.

## Getting Help

- **Connection issues**: See [Troubleshooting](../troubleshooting/)
- **Mosquitto docs**: https://mosquitto.org/documentation/
- **Homie convention**: https://homieiot.github.io/
- **GitHub issues**: https://github.com/atheismann/home-assistant-aurora-ruby-addon/issues

## Next Steps

- **Basic configuration**: [Basic Configuration](basic.md)
- **Network adapters**: [Network Adapters](network-adapters.md)
- **Troubleshooting**: [../troubleshooting/](../troubleshooting/)
