# MQTT Issues

This guide helps troubleshoot MQTT broker connection and entity discovery issues.

## Overview

The Aurora add-on publishes data to an MQTT broker, which Home Assistant subscribes to. Both must be configured correctly for entities to appear.

**Architecture**:

```
Heat Pump → Aurora Add-on → MQTT Broker → Home Assistant MQTT Integration → Entities
```

## Mosquitto Broker Issues

### Broker Not Running

**Symptoms**: Aurora add-on shows "Connection refused" for MQTT

**Check broker status**:

1. Navigate to **Settings** → **Add-ons** → **Mosquitto broker**
2. Check status: Should show "Running"
3. If stopped, click **Start**

**If broker won't start**:

1. Check **Log** tab for errors
2. Common issues:
   - Configuration error
   - Port 1883 already in use
   - Permission problems

**Solution**:

- Fix configuration errors
- Check if another MQTT broker is running
- Restart Home Assistant

### Wrong Credentials

**Symptoms**: Aurora add-on shows "Authentication failed"

**Check credentials match**:

1. **Mosquitto configuration**:
   - Navigate to **Settings** → **Add-ons** → **Mosquitto broker**
   - Click **Configuration** tab
   - Note the username/password in `logins` list

2. **Aurora add-on configuration**:
   - Navigate to **Settings** → **Add-ons** → **Aurora MQTT Gateway**
   - Click **Configuration** tab
   - Verify `mqtt_username` and `mqtt_password` match exactly

**Common mistakes**:

- Typos in username or password
- Passwords are case-sensitive
- Extra spaces in username/password
- Username without password (or vice versa)

**Solution**:

- Correct credentials in Aurora configuration
- Save and restart Aurora add-on

### Forgot to Create User

**Symptoms**: Authentication failed, no users exist in Mosquitto

**Create MQTT user**:

1. Navigate to **Settings** → **Add-ons** → **Mosquitto broker**
2. Click **Configuration** tab
3. Add user to `logins` list:

   ```yaml
   logins:
     - username: homeassistant
       password: your_secure_password_here
   ```

4. Click **Save**
5. Restart Mosquitto broker
6. Update Aurora add-on configuration with same credentials
7. Restart Aurora add-on

## Aurora Add-on MQTT Issues

### Wrong MQTT Host

**Symptoms**: Connection timeout or refused

**Check mqtt_host setting**:

For built-in Mosquitto broker, use:

```yaml
mqtt_host: core-mosquitto
```

**Common mistakes**:

- ❌ `localhost` - Won't work in Docker container
- ❌ `127.0.0.1` - Won't work in Docker container
- ❌ `mosquitto` - Wrong hostname
- ❌ Your Home Assistant hostname - Wrong for built-in broker

**Correct values**:

- ✅ `core-mosquitto` - For built-in Mosquitto broker add-on
- ✅ `192.168.1.50` - For external MQTT broker (use actual IP)

### Wrong MQTT Port

**Symptoms**: Connection refused or timeout

**Check mqtt_port setting**:

Default unencrypted MQTT:

```yaml
mqtt_port: 1883
```

**Common mistakes**:

- Using TLS port (8883) when broker doesn't have TLS enabled
- Custom port without updating broker configuration
- Port blocked by firewall

**Solution**:

- Use `1883` for standard MQTT
- Use `8883` only if broker has TLS enabled
- Ensure port matches broker configuration

## Home Assistant MQTT Integration Issues

### MQTT Integration Not Installed

**Symptoms**: No MQTT device/integration in Home Assistant

**Install MQTT integration**:

1. Navigate to **Settings** → **Devices & Services**
2. Click **Add Integration**
3. Search for "MQTT"
4. Select **MQTT**
5. Configure:
   - Broker: `core-mosquitto`
   - Port: `1883`
   - Username: (same as Mosquitto config)
   - Password: (same as Mosquitto config)
6. Click **Submit**

### MQTT Integration Shows Disconnected

**Symptoms**: MQTT integration exists but shows "Connection failed"

**Check integration configuration**:

1. Navigate to **Settings** → **Devices & Services** → **MQTT**
2. Click **Configure**
3. Verify broker settings:
   - Broker should be `core-mosquitto` for built-in
   - Port should be `1883`
   - Credentials should match Mosquitto config

**Solution**:

- Update broker settings
- Click **Submit**
- Integration should reconnect

**If still disconnected**:

- Check Mosquitto broker is running
- Check credentials are correct
- Restart Home Assistant

### MQTT Integration Credentials Wrong

**Symptoms**: Integration shows authentication error

**Both Aurora add-on and HA MQTT integration must use same credentials**:

- Aurora add-on `mqtt_username`/`mqtt_password`
- HA MQTT integration username/password
- Mosquitto broker `logins` configuration

All three must match exactly.

**Solution**:

1. Choose one username/password
2. Update Mosquitto broker `logins`
3. Update Aurora add-on configuration
4. Update HA MQTT integration configuration
5. Restart Mosquitto, Aurora add-on, and Home Assistant

## Entity Discovery Issues

### No Aurora Device Appears

**Symptoms**: Aurora add-on connected to MQTT, but no device in Home Assistant

**Verify topics are published**:

```bash
mosquitto_sub -h core-mosquitto -u homeassistant -P your_password -t 'homie/aurora/#' -v
```

Expected output:

```
homie/aurora/$homie 4.0
homie/aurora/$name WaterFurnace Aurora Heat Pump
homie/aurora/$state ready
...
```

**If no output**:

- Aurora add-on not connected to heat pump
- See [Connection Issues](connection-issues.md)

**If topics are published but no device**:

1. **Check discovery is enabled**:
   - Navigate to **Settings** → **Devices & Services** → **MQTT**
   - Click **Configure**
   - Ensure "Enable discovery" is checked

2. **Restart Home Assistant**:
   - **Settings** → **System** → **Restart**
   - Discovery sometimes needs restart

3. **Clear MQTT discovery cache**:
   ```bash
   # In Home Assistant host
   rm -rf /config/.storage/mqtt.config
   ```
   - Then restart Home Assistant

### Entities Show "Unavailable"

**Symptoms**: Device exists, entities exist, but show unavailable

**Check Aurora add-on status**:

1. Navigate to **Settings** → **Add-ons** → **Aurora MQTT Gateway**
2. Should show "Running"
3. Check **Log** tab:
   - Look for "Connected to MQTT broker"
   - Look for "Connected to heat pump"
   - Look for "Publishing sensor data"

**If add-on stopped**:

- Check logs for errors
- Start add-on
- See [Troubleshooting Guide](README.md)

**If add-on running but entities unavailable**:

1. **Check MQTT messages**:
   ```bash
   mosquitto_sub -h core-mosquitto -u homeassistant -P your_password -t 'homie/aurora/#' -v
   ```
   - Should see recent messages
   - Check timestamps are current

2. **Check entity state**:
   - Navigate to **Developer Tools** → **States**
   - Find entity (e.g., `sensor.aurora_lockout_temperature`)
   - Check `last_updated` timestamp
   - Check `state` value

3. **Restart Aurora add-on**:
   - Sometimes fixes transient issues

### Wrong Entity Names or Values

**Symptoms**: Entities created but names are wrong or values don't make sense

**Check entity attributes**:

1. Navigate to **Developer Tools** → **States**
2. Find entity
3. Check attributes:
   - `unit_of_measurement`
   - `device_class`
   - `friendly_name`

**Common issues**:

- **Temperature units**: Add-on uses Celsius
  - Convert to Fahrenheit in Home Assistant if needed
  - Use template sensors for conversion

- **Wrong friendly name**: Can be customized
  - Click entity
  - Click gear icon
  - Change name
  - Click **Update**

## Testing MQTT Communication

### Using Mosquitto Command Line

**Subscribe to all aurora topics**:

```bash
mosquitto_sub -h core-mosquitto -u homeassistant -P your_password -t 'homie/aurora/#' -v
```

**Subscribe to specific topic**:

```bash
mosquitto_sub -h core-mosquitto -u homeassistant -P your_password -t 'homie/aurora/heat-pump/lockout-temp' -v
```

**Publish test message** (to verify MQTT works):

```bash
mosquitto_pub -h core-mosquitto -u homeassistant -P your_password -t 'test/topic' -m 'Hello MQTT'
```

**Subscribe to test topic**:

```bash
mosquitto_sub -h core-mosquitto -u homeassistant -P your_password -t 'test/topic' -v
```

Should see: `test/topic Hello MQTT`

### Using MQTT Explorer

**MQTT Explorer** is a GUI tool for viewing MQTT topics:

1. Download from: http://mqtt-explorer.com/
2. Install and open
3. Configure connection:
   - **Host**: Your Home Assistant IP
   - **Port**: `1883`
   - **Username**: `homeassistant`
   - **Password**: Your MQTT password
4. Click **Connect**
5. Browse to `homie/aurora` to see all topics
6. Right-click topics to see historical values

### Checking Home Assistant MQTT Entities

**Using Developer Tools**:

1. Navigate to **Developer Tools** → **States**
2. Search for: `sensor.aurora_`
3. Should see all Aurora entities
4. Click entity to see attributes and history

**Using Services**:

1. Navigate to **Developer Tools** → **Services**
2. Service: `mqtt.publish`
3. Service data:
   ```yaml
   topic: test/topic
   payload: Hello from HA
   ```
4. Click **Call Service**

5. Subscribe to see message:
   ```bash
   mosquitto_sub -h core-mosquitto -u homeassistant -P your_password -t 'test/topic' -v
   ```

## External MQTT Broker Issues

### Using External Broker

If using external MQTT broker instead of Mosquitto add-on:

**Aurora add-on configuration**:

```yaml
mqtt_host: 192.168.1.50  # External broker IP
mqtt_port: 1883
mqtt_username: aurora_user
mqtt_password: external_password
```

**Home Assistant MQTT integration**:

1. Navigate to **Settings** → **Devices & Services** → **MQTT**
2. Click **Configure**
3. Update to same external broker settings

**Both Aurora add-on and HA MQTT integration must connect to same broker!**

### External Broker Connection Issues

**Check broker is reachable**:

```bash
# Ping broker
ping 192.168.1.50

# Test MQTT port
telnet 192.168.1.50 1883
```

**Check firewall**:

- Port 1883 must be open
- Check broker firewall rules
- Check network firewall rules

**Check broker authentication**:

- Verify username/password are correct
- Check broker allows external connections
- Some brokers require IP whitelisting

## Advanced Debugging

### Enable Mosquitto Logging

For Mosquitto add-on:

1. Navigate to **Settings** → **Add-ons** → **Mosquitto broker**
2. Click **Configuration** tab
3. Add customize section:

   ```yaml
   logins:
     - username: homeassistant
       password: your_password
   customize:
     active: true
     folder: mosquitto
   ```

4. Create `/config/mosquitto/mosquitto.conf`:

   ```
   log_type all
   log_dest stdout
   ```

5. Restart Mosquitto broker
6. Check logs for detailed MQTT activity

### Clear Retained Messages

Old retained messages can cause issues:

```bash
# Remove all retained messages
mosquitto_sub -h core-mosquitto -u homeassistant -P your_password -t '#' --remove-retained
```

**Warning**: This removes ALL retained messages, including from other integrations.

### Reset MQTT Integration

If nothing else works:

1. Navigate to **Settings** → **Devices & Services** → **MQTT**
2. Click three dots (⋮) → **Delete**
3. Confirm deletion
4. Restart Home Assistant
5. Re-add MQTT integration
6. Configure with correct settings
7. Restart Aurora add-on

## Common Error Messages

### "Connection refused"

**Cause**: Broker not running or wrong host/port

**Solution**:

- Check Mosquitto broker is running
- Verify `mqtt_host` is correct
- Verify `mqtt_port` is correct

### "Authentication failed"

**Cause**: Wrong username or password

**Solution**:

- Verify credentials match Mosquitto config
- Check for typos
- Ensure user exists in broker

### "Connection timeout"

**Cause**: Network issue or firewall blocking connection

**Solution**:

- Check network connectivity
- Verify broker is reachable
- Check firewall rules
- Use `core-mosquitto` for built-in broker

### "Socket error"

**Cause**: Broker crashed or network interrupted

**Solution**:

- Check Mosquitto broker logs
- Restart Mosquitto broker
- Check network stability

## Getting Help

If MQTT issues persist:

1. **Gather information**:
   - Aurora add-on log (with `log_level: debug`)
   - Mosquitto broker log
   - MQTT integration status
   - Output of `mosquitto_sub` command

2. **Check configuration**:
   - Aurora add-on MQTT settings
   - Mosquitto broker `logins`
   - HA MQTT integration settings
   - Ensure all three match

3. **Open an issue**:
   - https://github.com/atheismann/home-assistant-aurora-ruby-addon/issues
   - Include configuration (redact passwords)
   - Include relevant logs

## Related Documentation

- **[MQTT Configuration](../configuration/mqtt.md)** - Detailed MQTT setup
- **[MQTT Setup Guide](../getting-started/mqtt-setup.md)** - Initial MQTT setup
- **[Basic Configuration](../configuration/basic.md)** - Configuration reference
- **[Troubleshooting Guide](README.md)** - General troubleshooting
