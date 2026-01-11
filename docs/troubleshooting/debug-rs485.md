# RS-485 Communication Debugging Guide

## How to Enable Communication Logging

To log all communication between the add-on and your RS-485 network adapter:

### Step 1: Enable Debug Logging

Edit your add-on configuration and set:

```yaml
log_level: debug
```

### Step 2: Rebuild the Add-on

The debug tools (tcpdump, strace) need to be installed:

1. Go to Settings → Add-ons → WaterFurnace Aurora
2. Click three dots menu → "Rebuild"
3. Wait for rebuild to complete

### Step 3: Restart the Add-on

After rebuild completes, restart the add-on.

### Step 4: View Logs

Go to the Log tab. You'll now see detailed communication logs:

## What You'll See

### For Network Connections (Waveshare/TCP)

**Network capture starts:**

```
[INFO] Starting network traffic capture for 192.168.1.100:2000
[INFO] Network capture started (PID: 234)
```

**Packet-level details:**

```
[DEBUG] [TCPDUMP] 19:01:12.345678 IP 192.168.1.10.54321 > 192.168.1.100.2000: Flags [P.], seq 1:8, ack 1, win 502, length 7
[DEBUG] [TCPDUMP] 0x0000:  4500 002f 1234 4000 4006 abcd c0a8 010a  E../..@.@.......
[DEBUG] [TCPDUMP] 0x0010:  c0a8 0164 d431 07d0 1234 5678 9abc def0  ...d.1...4Vx....
[DEBUG] [TCPDUMP] 0x0020:  5018 01f6 1234 0000 0103 0000 0002 c40b  P....4..........
```

**What this shows:**

- Timestamp of each packet
- Source and destination IP:port
- Raw hex bytes of the data
- TCP flags and sequence numbers

### For Serial Connections (USB)

**Serial tracing starts:**

```
[INFO] Enabling serial I/O tracing for /dev/ttyUSB0
```

**System call details:**

```
[DEBUG] write(3, "\x01\x03\x00\x00\x00\x02\xc4\x0b", 8) = 8
[DEBUG] ioctl(3, TCGETS, {B19200 opost isig icanon echo ...}) = 0
[DEBUG] read(3, "\x01\x03\x04\x00\x01\x00\x02\xc4\x0b", 512) = 9
```

**What this shows:**

- File descriptor (3) for the serial port
- Exact bytes written to the port
- Serial port settings (baud rate, flags)
- Bytes read from the port

## Understanding ModBus Communication

### Typical ModBus Request (Heat Pump Query)

```
01 03 00 00 00 02 c4 0b
│  │  │     │     └── CRC (2 bytes)
│  │  │     └──────── Register count (2)
│  │  └────────────── Starting address (0x0000)
│  └───────────────── Function code (03 = Read Holding Registers)
└──────────────────── Device address (01)
```

### Typical ModBus Response

```
01 03 04 00 01 00 02 c4 0b
│  │  │  │           └── CRC (2 bytes)
│  │  │  └──────────────  Data (4 bytes)
│  │  └─────────────────  Byte count (4)
│  └────────────────────  Function code (03)
└───────────────────────  Device address (01)
```

## Troubleshooting with Logs

### Problem: No Response from Heat Pump

**Look for:**

1. Request being sent (write or outgoing packet)
2. No corresponding read or incoming packet
3. Timeout error after 5-10 seconds

**Example:**

```
[DEBUG] [TCPDUMP] 19:01:12.345 IP ... > 192.168.1.100.2000: [OUTGOING DATA]
[DEBUG] [TCPDUMP] 0x0000:  01 03 00 00 00 02 c4 0b
... (10 seconds pass with no incoming traffic)
[ERROR] ModBus::Errors::ModBusTimeout: Timed out during read attempt
```

**This indicates:**

- Request is being sent correctly
- Heat pump is not responding
- Check wiring, parity settings, or heat pump power

### Problem: Garbled Response

**Look for:**

```
[DEBUG] write: 01 03 00 00 00 02 c4 0b (correct request)
[DEBUG] read: ff ff ff ff ff ff ff ff (garbage data)
[ERROR] Invalid CRC or unexpected response
```

**This indicates:**

- Communication is happening but data is corrupt
- Wrong serial parameters (baud rate, parity)
- Electrical noise or poor cable

### Problem: Connection Refused

**Look for:**

```
[DEBUG] [TCPDUMP] ... > 192.168.1.100.2000: Flags [S]
[DEBUG] [TCPDUMP] 192.168.1.100.2000 > ...: Flags [R]
```

**The "R" flag means RST (connection refused):**

- Waveshare not in TCP Server mode
- Wrong port number
- Firewall blocking connection

## Analyzing the Logs

### Check Request Timing

Count the time between request and response:

- **Normal:** < 100ms response time
- **Slow:** 500ms - 1000ms (marginal connection)
- **Timeout:** No response after 5-10 seconds

### Check Data Patterns

**Good ModBus traffic:**

- Regular requests every few seconds
- Matching responses for each request
- Valid CRC checksums
- Consistent byte counts

**Bad ModBus traffic:**

- Requests with no responses
- Responses with wrong byte counts
- CRC errors
- Partial or truncated packets

### Network Issues

**TCP retransmissions:**

```
[DEBUG] [TCPDUMP] ... Flags [P.], seq 1:8, ack 1 (ORIGINAL)
[DEBUG] [TCPDUMP] ... Flags [P.], seq 1:8, ack 1 (RETRANSMIT)
```

- Indicates packet loss
- Check network quality
- May need better cable or closer placement

## Saving Logs for Analysis

### Copy Full Logs

1. Settings → Add-ons → WaterFurnace Aurora → Log tab
2. Select all text (Cmd+A or Ctrl+A)
3. Copy to clipboard
4. Paste into text editor
5. Save as `add-on-debug.log`

### Filter for Communication Only

```bash
# SSH into Home Assistant
docker logs addon_SLUG 2>&1 | grep -E "TCPDUMP|write|read|ioctl" > rs485-comm.log
```

## Disabling Debug Logging

Debug logging is verbose and can fill logs quickly.

**When done troubleshooting:**

1. Change configuration back to:

   ```yaml
   log_level: info
   ```

2. Restart add-on
3. Logs will return to normal verbosity

## What to Share When Asking for Help

If you need help diagnosing the issue:

**Include:**

1. Full debug logs (especially the first 100-200 lines after startup)
2. Your configuration (redact passwords)
3. Hardware details (adapter model, cable type/length)
4. What you see in the logs (requests with no response? garbage data?)

**What to look for before asking:**

- Are requests being sent? (look for write/outgoing)
- Are responses received? (look for read/incoming)
- Is there a pattern to the errors?
- Does it work initially then fail?

## Common Patterns

### Pattern 1: Immediate Timeout (No Traffic)

**Logs show:**

- No tcpdump output at all
- Or write attempts with immediate errors

**Cause:**

- Network adapter unreachable
- Serial port doesn't exist
- Wrong connection URI

### Pattern 2: Request Sent, No Response

**Logs show:**

- Outgoing packets visible
- No incoming packets
- Timeout after ~10 seconds

**Cause:**

- Wrong wiring (A+/B- swapped or disconnected)
- Wrong serial parameters (especially parity)
- Heat pump not powered or wrong port

### Pattern 3: Rapid Errors

**Logs show:**

- Many requests/responses
- But all showing errors
- CRC failures

**Cause:**

- Baud rate mismatch
- Electrical interference
- Poor cable quality

## Technical Details

### tcpdump Options Used

```bash
tcpdump -i any -nn -X "host IP and port PORT"
```

- `-i any` - Capture on all interfaces
- `-nn` - Don't resolve hostnames or ports
- `-X` - Show packet contents in hex and ASCII
- Filter - Only capture traffic to/from the adapter

### strace Options Used

```bash
strace -e trace=read,write,ioctl -s 1024 -xx
```

- `-e trace=...` - Only trace these system calls
- `-s 1024` - Show up to 1024 bytes of data
- `-xx` - Show all bytes in hex

## Performance Impact

Debug logging has minimal performance impact:

- tcpdump: ~1-2% CPU usage
- strace: ~5% CPU overhead
- Logging: Increases log file size significantly

Safe to run continuously for troubleshooting, but not recommended for long-term production use.
