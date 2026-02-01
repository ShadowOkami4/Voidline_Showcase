#!/bin/bash
# ============================================================================
#                     WALLPAPER COLOR APPLY SCRIPT
# ============================================================================
#
# FILE: scripts/apply-colors.sh
# PURPOSE: Generate colors from wallpaper and apply to shell
#
# USAGE:
#   ./apply-colors.sh [wallpaper_path] [--mode dark|light] [--scheme name]
#
# If no wallpaper is provided, tries to get it from:
#   1. hyprctl getoption misc:background_color (Hyprland)
#   2. swww query (swww wallpaper daemon)
#   3. Environment variable WALLPAPER
#
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell"
VENV_DIR="$HOME/.local/share/quickshell-venv"

# Output file for generated colors
COLORS_FILE="$STATE_DIR/generated/colors.json"

# Default values
MODE="dark"
SCHEME="tonal-spot"
WALLPAPER=""

# ============================================================================
#                          PARSE ARGUMENTS
# ============================================================================

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)
            MODE="$2"
            shift 2
            ;;
        --scheme)
            SCHEME="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [wallpaper_path] [--mode dark|light] [--scheme name]"
            echo ""
            echo "Schemes: tonal-spot, content, expressive, fidelity, monochrome,"
            echo "         neutral, vibrant, fruit-salad, rainbow"
            exit 0
            ;;
        *)
            if [[ -z "$WALLPAPER" && -f "$1" ]]; then
                WALLPAPER="$1"
            fi
            shift
            ;;
    esac
done

# ============================================================================
#                     DETECT WALLPAPER IF NOT PROVIDED
# ============================================================================

detect_wallpaper() {
    # Method 1: Check swww
    if command -v swww &>/dev/null; then
        local swww_output
        swww_output=$(swww query 2>/dev/null | head -1 | grep -oP 'image: \K.*' || true)
        if [[ -n "$swww_output" && -f "$swww_output" ]]; then
            echo "$swww_output"
            return 0
        fi
    fi
    
    # Method 2: Check hyprpaper
    if command -v hyprctl &>/dev/null; then
        local hyprpaper_output
        hyprpaper_output=$(hyprctl hyprpaper listactive 2>/dev/null | head -1 | awk '{print $2}' || true)
        if [[ -n "$hyprpaper_output" && -f "$hyprpaper_output" ]]; then
            echo "$hyprpaper_output"
            return 0
        fi
    fi
    
    # Method 3: Check WALLPAPER environment variable
    if [[ -n "$WALLPAPER" && -f "$WALLPAPER" ]]; then
        echo "$WALLPAPER"
        return 0
    fi
    
    # Method 4: Check common wallpaper locations
    local common_locations=(
        "$HOME/.config/hypr/wallpaper.jpg"
        "$HOME/.config/hypr/wallpaper.png"
        "$HOME/Pictures/Wallpapers/current.jpg"
        "$HOME/Pictures/Wallpapers/current.png"
        "$HOME/Pictures/wallpaper.jpg"
        "$HOME/Pictures/wallpaper.png"
    )
    
    for loc in "${common_locations[@]}"; do
        if [[ -f "$loc" ]]; then
            echo "$loc"
            return 0
        fi
    done
    
    return 1
}

if [[ -z "$WALLPAPER" ]]; then
    WALLPAPER=$(detect_wallpaper) || {
        echo "ERROR: Could not detect wallpaper. Please provide path as argument." >&2
        exit 1
    }
fi

if [[ ! -f "$WALLPAPER" ]]; then
    echo "ERROR: Wallpaper file not found: $WALLPAPER" >&2
    exit 1
fi

echo "Generating colors from: $WALLPAPER"
echo "Mode: $MODE, Scheme: $SCHEME"

# ============================================================================
#                          ENSURE DIRECTORIES
# ============================================================================

mkdir -p "$STATE_DIR/generated"

# ============================================================================
#                          CHECK/SETUP VIRTUAL ENVIRONMENT
# ============================================================================

# Ensure virtual environment exists
if [[ ! -d "$VENV_DIR" ]]; then
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
    "$VENV_DIR/bin/pip" install materialyoucolor Pillow
fi

# Check if dependencies are installed in venv
if ! "$VENV_DIR/bin/python3" -c "from materialyoucolor.quantize import QuantizeCelebi; from PIL import Image" 2>/dev/null; then
    echo "Installing Python dependencies in venv..."
    "$VENV_DIR/bin/pip" install materialyoucolor Pillow || {
        echo "ERROR: Failed to install dependencies." >&2
        exit 1
    }
fi

# ============================================================================
#                          GENERATE COLORS
# ============================================================================

"$VENV_DIR/bin/python3" "$SCRIPT_DIR/colorgen.py" \
    --path "$WALLPAPER" \
    --mode "$MODE" \
    --scheme "$SCHEME" \
    --output "$COLORS_FILE"

if [[ $? -eq 0 ]]; then
    echo "Colors generated: $COLORS_FILE"
    
    # Generate Ghostty colors if Ghostty is installed
    if command -v ghostty &>/dev/null; then
        echo "Applying colors to Ghostty..."
        "$SCRIPT_DIR/generate-ghostty-colors.sh" "$COLORS_FILE" 2>/dev/null && \
            echo "Ghostty colors updated" || \
            echo "Warning: Failed to update Ghostty colors"
    fi
    
    # Generate Vencord theme colors if theme file exists
    VENCORD_THEME="$HOME/.config/Vencord/themes/combined-discord-material3.css"
    if [[ -f "$VENCORD_THEME" ]]; then
        echo "Applying colors to Vencord theme..."
        "$SCRIPT_DIR/generate-vencord-colors.sh" "$COLORS_FILE" "$VENCORD_THEME" 2>/dev/null && \
            echo "Vencord theme colors updated" || \
            echo "Warning: Failed to update Vencord theme colors"
    fi
    
    # Generate Hyprland border colors if Hyprland config exists
    HYPR_CONFIG="$HOME/.config/hypr/config.conf"
    if [[ -f "$HYPR_CONFIG" ]]; then
        echo "Applying colors to Hyprland borders..."
        "$SCRIPT_DIR/generate-hyprland-colors.sh" "$COLORS_FILE" "$HYPR_CONFIG" 2>/dev/null && \
            echo "Hyprland border colors updated" || \
            echo "Warning: Failed to update Hyprland border colors"
    fi
    
    # Notify quickshell to reload colors (via IPC if available)
    if command -v quickshell-ipc &>/dev/null; then
        quickshell-ipc colorscheme reload 2>/dev/null || true
    fi
else
    echo "ERROR: Color generation failed" >&2
    exit 1
fi
