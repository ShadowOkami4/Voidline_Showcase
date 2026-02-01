#!/bin/bash
# ============================================================================
#                         BLUETOOTH AGENT (SHELL)
# ============================================================================
#
# FILE: scripts/bluetooth-agent.sh
# PURPOSE: Simple shell wrapper to run a bluetoothctl agent that accepts
#          pairing requests automatically. Useful for quick pairing during
#          Quickshell sessions.
#
# OVERVIEW:
#   - Ensures no duplicate agent is running, then starts `bluetoothctl` in
#     agent mode with `NoInputNoOutput`.
#   - Keeps the agent running to handle pairing requests from devices.
#
# NOTE: This is a lightweight helper. For production use prefer the Python
#       D-Bus based agent which integrates more cleanly with BlueZ.
# ============================================================================

# Kill any existing agent
pkill -f "bluetoothctl agent" 2>/dev/null

# Start agent in background
exec bluetoothctl << EOF
agent NoInputNoOutput
default-agent
EOF

# Keep running to handle pairing requests
# The agent needs to stay active
