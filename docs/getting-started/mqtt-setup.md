# MQTT Setup - Quick Reference

## Understanding the Architecture

```text
┌─────────────────────────────────────────────────────────┐
│                  Home Assistant                          │
│                                                          │
│  ┌──────────────────┐       ┌────────────────────┐     │
│  │  Mosquitto Broker│◄──────┤ WaterFurnace Aurora│     │
│  │    (Add-on)      │       │     (This Add-on)   │     │
│  │                  │       │                     │     │
│  │ Listens on       │       │ Connects to         │     │
│  │ port 1883        │       │ core-mosquitto:1883 │     │
│  └────────▲─────────┘       └─────────┬──────────┘     │
│           │                            │                 │
│           │                            │                 │
│  ┌────────┴─────────┐                 │                 │
│  │ MQTT Integration │                 │                 │
│  │ (Auto-discovery) │                 │                 │
│  └──────────────────┘                 │                 │
│                                        │                 │
└────────────────────────────────────────┼─────────────────┘
                                         │
                                         ▼
                              ┌──────────────────┐
                              │  Heat Pump       │
                              │  (via RS-485)    │
                              └──────────────────┘
```

## What You Need

### ✅ Required: Mosquitto Broker Add-on

**This is a separate add-on you must install first!**

1. Go to Settings → Add-ons → Add-on Store
2. Search for "Mosquitto broker"
3. Click Install
4. Click Start
5. Done! (No configuration needed for basic use)

### ✅ Then: WaterFurnace Aurora Add-on

**This add-on (the one you're setting up now):**

- Connects to your heat pump via RS-485
- Publishes data TO the Mosquitto broker
- Does NOT create its own MQTT server

## Configuration

In the WaterFurnace Aurora add-on configuration, use:

```yaml
mqtt_host: core-mosquitto  # This connects to the Mosquitto add-on
mqtt_port: 1883            # Default MQTT port
```

## Do I Need Authentication?

**For basic setups: No!**

The Mosquitto add-on allows connections from other Home Assistant add-ons without authentication by default.

**For advanced/secured setups:**

If you've configured the Mosquitto add-on with user authentication:

1. Create a user in Mosquitto configuration
2. Add credentials to WaterFurnace Aurora config:

```yaml
mqtt_username: "your-mqtt-user"
mqtt_password: "your-mqtt-password"
```

## Common Misconceptions

❌ **"I need to install a separate MQTT server"**

- No! The Mosquitto add-on IS your MQTT server

❌ **"This add-on includes an MQTT broker"**

- No! This add-on is a client that connects to Mosquitto

❌ **"I need to configure complex MQTT settings"**

- No! Default settings work for 99% of users

## Verification

### Check if Mosquitto is running

1. Go to Settings → Add-ons
2. Look for "Mosquitto broker"
3. Status should show "Running"

### Check if WaterFurnace is connecting

1. Start the WaterFurnace Aurora add-on
2. Check the logs - you should see:

   ```text
   [INFO] MQTT Host: core-mosquitto:1883
   [INFO] Starting: aurora_mqtt_bridge ...
   ```

### Check if data is flowing

1. Go to Settings → Devices & Services
2. Look for MQTT integration
3. You should see WaterFurnace devices appear automatically

## Troubleshooting

### "Connection refused" to MQTT

**Problem**: Mosquitto add-on is not running

**Solution**:

1. Go to Settings → Add-ons → Mosquitto broker
2. Click Start

### "Authentication failed"

**Problem**: Mosquitto requires authentication but credentials not provided

**Solution**: Either:

- Disable authentication in Mosquitto config, OR
- Add username/password to WaterFurnace Aurora config

### No devices appearing

**Problem**: MQTT discovery not enabled

**Solution**: Check that MQTT integration is set up in Home Assistant:

1. Go to Settings → Devices & Services
2. Look for MQTT integration
3. Ensure discovery is enabled (it is by default)

## Summary

**Two separate add-ons work together:**

1. **Mosquitto broker** = MQTT server (hub for messages)
2. **WaterFurnace Aurora** = MQTT client (sends heat pump data to the hub)

Both run inside Home Assistant, communicate with each other automatically, and require minimal configuration!
