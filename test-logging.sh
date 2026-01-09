#!/bin/bash
# Test script to verify logging works properly
# This simulates what the Ruby bridge would output

echo "Test message 1: Starting connection"
sleep 1
echo "Test message 2: Connected successfully"
sleep 1
echo "WARNING: This is a warning message"
sleep 1
echo "ERROR: This is an error message"
sleep 1
echo "Test message 3: Publishing data..."
sleep 1
echo "DEBUG: Debug information here"
sleep 1
echo "Test message 4: Normal operation continuing"

# Keep running to simulate long-running process
echo "Entering main loop (press Ctrl+C to stop)..."
counter=0
while true; do
    counter=$((counter + 1))
    echo "Loop iteration $counter - All systems operational"
    sleep 5
done
