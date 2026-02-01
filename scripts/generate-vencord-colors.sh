#!/bin/bash
# ============================================================================
#                     VENCORD THEME COLOR GENERATOR
# ============================================================================
#
# FILE: scripts/generate-vencord-colors.sh
# PURPOSE: Generate Vencord Discord theme colors from Material You JSON
#
# USAGE:
#   ./generate-vencord-colors.sh [colors.json]
#
# ============================================================================

set -e

COLORS_FILE="${1:-$HOME/.local/state/quickshell/generated/colors.json}"
VENCORD_THEME="${2:-$HOME/.config/Vencord/themes/combined-discord-material3.css}"

if [[ ! -f "$COLORS_FILE" ]]; then
    echo "ERROR: Colors file not found: $COLORS_FILE" >&2
    exit 1
fi

if [[ ! -f "$VENCORD_THEME" ]]; then
    echo "ERROR: Vencord theme not found: $VENCORD_THEME" >&2
    echo "Please ensure Vencord theme exists at the specified location" >&2
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

# Read Material 3 colors
PRIMARY=$(read_color "primary")
PRIMARY_CONTAINER=$(read_color "primaryContainer")
ON_PRIMARY=$(read_color "onPrimary")
ON_PRIMARY_CONTAINER=$(read_color "onPrimaryContainer")

SECONDARY=$(read_color "secondary")
SECONDARY_CONTAINER=$(read_color "secondaryContainer")
ON_SECONDARY=$(read_color "onSecondary")
ON_SECONDARY_CONTAINER=$(read_color "onSecondaryContainer")

TERTIARY=$(read_color "tertiary")
TERTIARY_CONTAINER=$(read_color "tertiaryContainer")
ON_TERTIARY=$(read_color "onTertiary")
ON_TERTIARY_CONTAINER=$(read_color "onTertiaryContainer")

ERROR=$(read_color "error")
ERROR_CONTAINER=$(read_color "errorContainer")
ON_ERROR=$(read_color "onError")
ON_ERROR_CONTAINER=$(read_color "onErrorContainer")

BACKGROUND=$(read_color "background")
ON_BACKGROUND=$(read_color "onBackground")

SURFACE=$(read_color "surface")
SURFACE_VARIANT=$(read_color "surfaceVariant")
SURFACE_DIM=$(read_color "surfaceDim")
SURFACE_CONTAINER=$(read_color "surfaceContainer")
SURFACE_CONTAINER_LOW=$(read_color "surfaceContainerLow")
SURFACE_CONTAINER_HIGH=$(read_color "surfaceContainerHigh")
SURFACE_CONTAINER_HIGHEST=$(read_color "surfaceContainerHighest")
ON_SURFACE=$(read_color "onSurface")
ON_SURFACE_VARIANT=$(read_color "onSurfaceVariant")

OUTLINE=$(read_color "outline")
OUTLINE_VARIANT=$(read_color "outlineVariant")

# Backup existing theme
if [[ ! -f "${VENCORD_THEME}.backup" ]]; then
    cp "$VENCORD_THEME" "${VENCORD_THEME}.backup"
    echo "Backed up original theme to ${VENCORD_THEME}.backup"
fi

# Use sed to replace colors
sed -i.tmp \
    -e "s/\(--md3-primary:\s*\)#[0-9A-Fa-f]\{6\}/\1$PRIMARY/" \
    -e "s/\(--md3-primary-container:\s*\)#[0-9A-Fa-f]\{6\}/\1$PRIMARY_CONTAINER/" \
    -e "s/\(--md3-on-primary:\s*\)#[0-9A-Fa-f]\{6\}/\1$ON_PRIMARY/" \
    -e "s/\(--md3-on-primary-container:\s*\)#[0-9A-Fa-f]\{6\}/\1$ON_PRIMARY_CONTAINER/" \
    -e "s/\(--md3-secondary:\s*\)#[0-9A-Fa-f]\{6\}/\1$SECONDARY/" \
    -e "s/\(--md3-secondary-container:\s*\)#[0-9A-Fa-f]\{6\}/\1$SECONDARY_CONTAINER/" \
    -e "s/\(--md3-on-secondary:\s*\)#[0-9A-Fa-f]\{6\}/\1$ON_SECONDARY/" \
    -e "s/\(--md3-on-secondary-container:\s*\)#[0-9A-Fa-f]\{6\}/\1$ON_SECONDARY_CONTAINER/" \
    -e "s/\(--md3-tertiary:\s*\)#[0-9A-Fa-f]\{6\}/\1$TERTIARY/" \
    -e "s/\(--md3-tertiary-container:\s*\)#[0-9A-Fa-f]\{6\}/\1$TERTIARY_CONTAINER/" \
    -e "s/\(--md3-on-tertiary:\s*\)#[0-9A-Fa-f]\{6\}/\1$ON_TERTIARY/" \
    -e "s/\(--md3-on-tertiary-container:\s*\)#[0-9A-Fa-f]\{6\}/\1$ON_TERTIARY_CONTAINER/" \
    -e "s/\(--md3-error:\s*\)#[0-9A-Fa-f]\{6\}/\1$ERROR/" \
    -e "s/\(--md3-error-container:\s*\)#[0-9A-Fa-f]\{6\}/\1$ERROR_CONTAINER/" \
    -e "s/\(--md3-on-error:\s*\)#[0-9A-Fa-f]\{6\}/\1$ON_ERROR/" \
    -e "s/\(--md3-on-error-container:\s*\)#[0-9A-Fa-f]\{6\}/\1$ON_ERROR_CONTAINER/" \
    -e "s/\(--md3-background:\s*\)#[0-9A-Fa-f]\{6\}/\1$BACKGROUND/" \
    -e "s/\(--md3-on-background:\s*\)#[0-9A-Fa-f]\{6\}/\1$ON_BACKGROUND/" \
    -e "s/\(--md3-surface:\s*\)#[0-9A-Fa-f]\{6\}/\1$SURFACE/" \
    -e "s/\(--md3-surface-variant:\s*\)#[0-9A-Fa-f]\{6\}/\1$SURFACE_VARIANT/" \
    -e "s/\(--md3-surface-container-low:\s*\)#[0-9A-Fa-f]\{6\}/\1$SURFACE_CONTAINER_LOW/" \
    -e "s/\(--md3-surface-container:\s*\)#[0-9A-Fa-f]\{6\}/\1$SURFACE_CONTAINER/" \
    -e "s/\(--md3-surface-container-high:\s*\)#[0-9A-Fa-f]\{6\}/\1$SURFACE_CONTAINER_HIGH/" \
    -e "s/\(--md3-surface-container-highest:\s*\)#[0-9A-Fa-f]\{6\}/\1$SURFACE_CONTAINER_HIGHEST/" \
    -e "s/\(--md3-on-surface:\s*\)#[0-9A-Fa-f]\{6\}/\1$ON_SURFACE/" \
    -e "s/\(--md3-on-surface-variant:\s*\)#[0-9A-Fa-f]\{6\}/\1$ON_SURFACE_VARIANT/" \
    -e "s/\(--md3-outline:\s*\)#[0-9A-Fa-f]\{6\}/\1$OUTLINE/" \
    -e "s/\(--md3-outline-variant:\s*\)#[0-9A-Fa-f]\{6\}/\1$OUTLINE_VARIANT/" \
    "$VENCORD_THEME"

rm -f "${VENCORD_THEME}.tmp"

echo "Vencord theme colors updated: $VENCORD_THEME"
echo "Tip: Restart Discord or reload Vencord to see changes (Ctrl+R)"
