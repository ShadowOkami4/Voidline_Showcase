#!/bin/bash
# Bluetooth Agent Starter
# Tries Python agent first, falls back to bluetoothctl

# Check if python gi module is available
if python3 -c "from gi.repository import GLib" 2>/dev/null; then
    # Use Python agent
    exec python3 "$(dirname "$0")/bluetooth-agent.py"
else
    # Fall back to bluetoothctl agent
    # We need to keep it running, so we use a pipe with sleep
    # The agent commands + a long sleep to keep the process alive
    {
        echo "agent NoInputNoOutput"
        echo "default-agent"
        # Keep the process running indefinitely
        while true; do
            sleep 3600
        done
    } | exec bluetoothctl
fi
