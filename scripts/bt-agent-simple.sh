#!/bin/bash
# Simple bluetooth agent that stays running
bluetoothctl <<EOF &
agent NoInputNoOutput
default-agent
EOF

# Keep the script running
wait
