#!/bin/bash
# ============================================================================
#                     GHOSTTY COLOR GENERATOR
# ============================================================================
#
# FILE: scripts/generate-ghostty-colors.sh
# PURPOSE: Generate Ghostty terminal colors from Material You JSON
#
# USAGE:
#   ./generate-ghostty-colors.sh [colors.json]
#
# ============================================================================

set -e

COLORS_FILE="${1:-$HOME/.local/state/quickshell/generated/colors.json}"
GHOSTTY_CONFIG="${2:-$HOME/.config/ghostty/config}"

if [[ ! -f "$COLORS_FILE" ]]; then
    echo "ERROR: Colors file not found: $COLORS_FILE" >&2
    exit 1
fi

# Read colors from JSON using jq or python
if command -v jq &>/dev/null; then
    # Use jq if available
    read_color() {
        jq -r ".material.${1}" "$COLORS_FILE"
    }
else
    # Fallback to python
    read_color() {
        python3 -c "import json; print(json.load(open('$COLORS_FILE'))['material']['$1'])"
    }
fi

# Read Material You colors
BG=$(read_color "surface")
FG=$(read_color "onSurface")
CURSOR=$(read_color "primary")
CURSOR_TEXT=$(read_color "onPrimary")
SELECTION_BG=$(read_color "primaryContainer")
SELECTION_FG=$(read_color "onPrimaryContainer")

# ANSI colors (using Material 3 palette)
BLACK=$(read_color "surfaceDim")
RED=$(read_color "error")
GREEN=$(read_color "tertiary")
YELLOW=$(read_color "secondary")
BLUE=$(read_color "primary")
MAGENTA=$(read_color "tertiary")
CYAN=$(read_color "secondary")
WHITE=$(read_color "onSurface")

BRIGHT_BLACK=$(read_color "surfaceContainerHighest")
BRIGHT_RED=$(read_color "errorContainer")
BRIGHT_GREEN=$(read_color "tertiaryContainer")
BRIGHT_YELLOW=$(read_color "secondaryContainer")
BRIGHT_BLUE=$(read_color "primaryContainer")
BRIGHT_MAGENTA=$(read_color "tertiaryContainer")
BRIGHT_CYAN=$(read_color "secondaryContainer")
BRIGHT_WHITE=$(read_color "surfaceBright")

# Backup existing config if it exists and doesn't have our marker
if [[ -f "$GHOSTTY_CONFIG" ]] && ! grep -q "# AUTO-GENERATED COLORS" "$GHOSTTY_CONFIG"; then
    cp "$GHOSTTY_CONFIG" "${GHOSTTY_CONFIG}.backup"
    echo "Backed up existing config to ${GHOSTTY_CONFIG}.backup"
fi

# Remove old auto-generated color section if it exists
if [[ -f "$GHOSTTY_CONFIG" ]]; then
    # Remove everything between markers
    sed -i '/# AUTO-GENERATED COLORS - START/,/# AUTO-GENERATED COLORS - END/d' "$GHOSTTY_CONFIG"
fi

# Generate new color section
cat >> "$GHOSTTY_CONFIG" << EOF

# AUTO-GENERATED COLORS - START
# Generated from Material You colors
# DO NOT EDIT - This section will be regenerated

# Basic colors
background = $BG
foreground = $FG
cursor-color = $CURSOR
cursor-text = $CURSOR_TEXT
selection-background = $SELECTION_BG
selection-foreground = $SELECTION_FG

# ANSI colors (normal)
palette = 0=$BLACK
palette = 1=$RED
palette = 2=$GREEN
palette = 3=$YELLOW
palette = 4=$BLUE
palette = 5=$MAGENTA
palette = 6=$CYAN
palette = 7=$WHITE

# ANSI colors (bright)
palette = 8=$BRIGHT_BLACK
palette = 9=$BRIGHT_RED
palette = 10=$BRIGHT_GREEN
palette = 11=$BRIGHT_YELLOW
palette = 12=$BRIGHT_BLUE
palette = 13=$BRIGHT_MAGENTA
palette = 14=$BRIGHT_CYAN
palette = 15=$BRIGHT_WHITE

# AUTO-GENERATED COLORS - END
EOF

echo "Ghostty colors updated: $GHOSTTY_CONFIG"

# Reload Ghostty if it's running
if command -v ghostty &>/dev/null && pgrep -x ghostty &>/dev/null; then
    echo "Tip: Press Ctrl+Shift+, in Ghostty to reload config"
fi
