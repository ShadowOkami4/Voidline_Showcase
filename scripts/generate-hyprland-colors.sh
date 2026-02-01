#!/bin/bash
# ============================================================================
#                     HYPRLAND BORDER COLOR GENERATOR
# ============================================================================
#
# FILE: scripts/generate-hyprland-colors.sh
# PURPOSE: Update Hyprland border colors from Material You JSON
#
# USAGE:
#   ./generate-hyprland-colors.sh [colors.json]
#
# ============================================================================

set -e

COLORS_FILE="${1:-$HOME/.local/state/quickshell/generated/colors.json}"
HYPR_CONFIG="${2:-$HOME/.config/hypr/config.conf}"

if [[ ! -f "$COLORS_FILE" ]]; then
    echo "ERROR: Colors file not found: $COLORS_FILE" >&2
    exit 1
fi

if [[ ! -f "$HYPR_CONFIG" ]]; then
    echo "ERROR: Hyprland config not found: $HYPR_CONFIG" >&2
    exit 1
fi

# Read colors from JSON
if command -v jq &>/dev/null; then
    read_color() {
        jq -r ".material.${1}" "$COLORS_FILE"
    }
else
    read_color() {
        python3 -c "import json; print(json.load(open('$COLORS_FILE'))['material']['$1'])"
    }
fi

# Read Material 3 colors for borders
PRIMARY=$(read_color "primary")
PRIMARY_CONTAINER=$(read_color "primaryContainer")
SECONDARY=$(read_color "secondary")
SURFACE_DIM=$(read_color "surfaceDim")

# Convert hex to rgba format for Hyprland
# Remove # and convert to rgba with alpha
hex_to_rgba() {
    local hex=$1
    local alpha=${2:-ee}  # Default alpha ee (93% opacity)
    
    # Remove # if present
    hex=${hex#\#}
    
    # Convert to lowercase and add alpha
    echo "rgba(${hex}${alpha})"
}

# Create active border with gradient (primary -> secondary)
ACTIVE_COLOR_1=$(hex_to_rgba "$PRIMARY" "ee")
ACTIVE_COLOR_2=$(hex_to_rgba "$SECONDARY" "ee")
ACTIVE_BORDER="$ACTIVE_COLOR_1 $ACTIVE_COLOR_2 45deg"

# Create inactive border (surface dim with transparency)
INACTIVE_BORDER=$(hex_to_rgba "$SURFACE_DIM" "aa")

# Backup config if not already backed up
if [[ ! -f "${HYPR_CONFIG}.backup" ]]; then
    cp "$HYPR_CONFIG" "${HYPR_CONFIG}.backup"
    echo "Backed up original Hyprland config to ${HYPR_CONFIG}.backup"
fi

# Update the border colors using sed
sed -i.tmp \
    -e "s|^\$activecolor\s*=.*|\$activecolor = $ACTIVE_BORDER|" \
    -e "s|^\$inactivecolor\s*=.*|\$inactivecolor = $INACTIVE_BORDER|" \
    "$HYPR_CONFIG"

rm -f "${HYPR_CONFIG}.tmp"

echo "Hyprland border colors updated: $HYPR_CONFIG"
echo "Tip: Border colors will update on next focus change, or run: hyprctl reload"
