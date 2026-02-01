/*
 * ============================================================================
 *                            CONFIGURATION
 * ============================================================================
 * 
 * FILE: misc/Config.qml
 * PURPOSE: Central configuration singleton for all styling and sizing values
 * 
 * ============================================================================
 *                              OVERVIEW
 * ============================================================================
 * 
 * This file defines all the visual properties used throughout the shell:
 *   - Colors (backgrounds, text, accents)
 *   - Sizes (bar dimensions, padding, icon sizes)
 *   - Font settings
 *   - Persistent settings (bar style, auto-hide, Hyprland settings, etc.)
 * 
 * By centralizing these values, you can easily customize the entire look
 * by modifying just this one file.
 * 
 * ============================================================================
 *                         PERSISTENT SETTINGS
 * ============================================================================
 * 
 * Settings are saved to a JSON file and persist across reboots:
 *   ~/.config/quickshell/settings.json
 * 
 * Currently saved settings:
 *   BAR:
 *     - barStyle: "fullwidth" or "floating"
 *     - barAutoHide: true/false
 *     - profilePicturePath: path to profile picture
 * 
 *   HYPRLAND GENERAL:
 *     - gapsIn: inner gaps between windows
 *     - gapsOut: outer gaps (window to screen edge)
 *     - borderSize: window border thickness
 *     - hyprlandLayout: "dwindle" or "master"
 * 
 *   HYPRLAND DECORATION:
 *     - rounding: window corner radius
 *     - activeOpacity: active window opacity
 *     - inactiveOpacity: inactive window opacity
 *     - blurEnabled: background blur on/off
 *     - blurSize: blur size
 *     - blurPasses: blur quality passes
 *     - shadowEnabled: window shadows on/off
 *     - dimInactive: dim inactive windows on/off
 * 
 *   HYPRLAND ANIMATIONS:
 *     - animationsEnabled: animations on/off
 *     - currentAnimation: animation preset name
 * 
 *   DEFAULT PROGRAMS:
 *     - defaultTerminal: terminal emulator
 *     - defaultFileManager: file manager
 *     - defaultBrowser: web browser
 * 
 * The file is automatically:
 *   - Loaded on startup (Component.onCompleted)
 *   - Saved whenever a persistent property changes
 *   - Applied to Hyprland on startup (applyHyprlandSettings)
 * 
 * ============================================================================
 *                         HOW IT WORKS
 * ============================================================================
 * 
 * 1. PRAGMA SINGLETON:
 *    - 'pragma Singleton' at the top marks this as a singleton
 *    - Singletons can only have one instance
 *    - All other files access the same instance
 * 
 * 2. SINGLETON TYPE:
 *    - Quickshell's 'Singleton' component is a QtObject-based singleton
 *    - It can be accessed by its filename: Config.propertyName
 *    - For this to work, the file MUST be in a qmldir file
 * 
 * 3. READONLY PROPERTIES:
 *    - 'readonly' makes properties immutable after initialization
 *    - This prevents accidental changes and improves performance
 * 
 * 4. USAGE IN OTHER FILES:
 *    - Simply use: Config.backgroundColor, Config.barHeight, etc.
 *    - No import needed (Quickshell handles singleton resolution)
 * 
 * ============================================================================
 *                         CUSTOMIZATION GUIDE
 * ============================================================================
 * 
 * COLORS:
 *   - backgroundColor: Main panel/popup background
 *   - backgroundColorHover: Hover state for buttons
 *   - foregroundColor: Primary text color
 *   - accentColor: Highlights, active states, accent buttons
 *   - dimmedColor: Secondary text, inactive items
 * 
 * WORKSPACE COLORS:
 *   - workspaceActive: Currently focused workspace dot
 *   - workspaceInactive: Empty workspace dots
 *   - workspaceUrgent: Workspace with urgent window (not implemented yet)
 * 
 * SIZING:
 *   - barHeight: Height of the floating island bar
 *   - barWidth: Width of the floating island bar
 *   - borderRadius: Roundness of corners (half of barHeight = pill shape)
 *   - padding: Inner spacing in panels
 *   - iconSize: Size of Material Symbols icons
 *   - spacing: Gap between elements
 *   - topMargin: Gap between bar and screen edge
 * 
 * FONTS:
 *   - fontFamily: Primary font (Inter is a clean modern font)
 *   - fontSize: Normal text size
 *   - fontSizeSmall: Labels, secondary text
 * 
 * ============================================================================
 *                         COLOR FORMAT
 * ============================================================================
 * 
 * QML accepts colors in several formats:
 *   - Hex: "#1a1a1a" or "#1a1a1a80" (with alpha)
 *   - Named: "red", "blue", "transparent"
 *   - Qt.rgba(r, g, b, a): Values from 0.0 to 1.0
 *   - Qt.lighter/darker(color, factor): Modify existing colors
 * 
 * ============================================================================
 */

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/*
 * ============================================================================
 *                          SINGLETON DEFINITION
 * ============================================================================
 * 
 * Singleton is a Quickshell component that ensures only one instance exists.
 * All properties defined here are globally accessible as Config.propertyName
 */
Singleton {
    id: root
    
    // ========================================================================
    //                     SETTINGS FILE PATH
    // ========================================================================
    
    // Path to the persistent settings file
    readonly property string settingsFilePath: Quickshell.shellDir + "/settings.json"
    
    // Flag to prevent saving during initial load
    property bool _isLoading: true

    /*
     * ========================================================================
     *                     WALLPAPER SETTINGS
     * ========================================================================
     * Configure the desktop wallpaper rendered by Quickshell.
     * The wallpaper is also used for Material You color generation.
     */
    
    // Path to the wallpaper image file
    property string wallpaperPath: ""
    onWallpaperPathChanged: if (!_isLoading) saveSettings()
    
    // Fill mode: "cover", "contain", "stretch", "tile"
    property string wallpaperFillMode: "cover"
    onWallpaperFillModeChanged: if (!_isLoading) saveSettings()
    
    // Enable smooth transition when wallpaper changes
    property bool wallpaperTransition: true
    onWallpaperTransitionChanged: if (!_isLoading) saveSettings()
    
    // Transition duration in milliseconds
    property int wallpaperTransitionDuration: 500
    onWallpaperTransitionDurationChanged: if (!_isLoading) saveSettings()
    
    // Enable Quickshell wallpaper rendering (disable if using swww/hyprpaper)
    property bool wallpaperEnabled: true
    onWallpaperEnabledChanged: if (!_isLoading) saveSettings()

    /*
     * ========================================================================
     *                     DYNAMIC COLORS (MATERIAL YOU)
     * ========================================================================
     * When enabled, colors are generated from your wallpaper using the
     * Material You algorithm. Disable to use static colors defined below.
     */
    
    // Enable dynamic wallpaper-based colors
    property bool dynamicColors: true
    onDynamicColorsChanged: if (!_isLoading) saveSettings()

    /*
     * ========================================================================
     *                          COLORS
     * ========================================================================
     * When dynamicColors is enabled, these pull from ColorScheme.
     * When disabled, they use the static fallback values.
     */
    
    // Main background color for the bar and panels
    readonly property color backgroundColor: dynamicColors ? ColorScheme.backgroundColor : "#1a1a1a"
    
    // Hover/pressed state background
    readonly property color backgroundColorHover: dynamicColors ? ColorScheme.backgroundColorHover : "#2a2a2a"
    
    // Primary text and icon color
    readonly property color foregroundColor: dynamicColors ? ColorScheme.foregroundColor : "#ffffff"
    
    // Accent color for highlights, active items, buttons
    readonly property color accentColor: dynamicColors ? ColorScheme.accentColor : "#007AFF"
    
    // Dimmed text for secondary information
    readonly property color dimmedColor: dynamicColors ? ColorScheme.dimmedColor : "#888888"
    
    // Error/danger color (disconnected, low battery, etc.)
    readonly property color errorColor: dynamicColors ? ColorScheme.errorColor : "#ff6b6b"
    
    // Success color (connected, charging, etc.)
    readonly property color successColor: dynamicColors ? ColorScheme.successColor : "#4ade80"
    
    // Warning color (connecting, pending, etc.)
    readonly property color warningColor: dynamicColors ? ColorScheme.warningColor : "#ffa726"

    /*
     * ========================================================================
     *                     WORKSPACE INDICATOR COLORS
     * ========================================================================
     */
    
    // Active (focused) workspace dot
    readonly property color workspaceActive: dynamicColors ? ColorScheme.workspaceActive : "#ffffff"
    
    // Empty workspace dots
    readonly property color workspaceInactive: dynamicColors ? ColorScheme.workspaceInactive : "#555555"
    
    // Workspace with urgent window (e.g., notification)
    readonly property color workspaceUrgent: dynamicColors ? ColorScheme.workspaceUrgent : "#ff5555"
    
    // Surface colors for layered UI (Material Design elevation)
    readonly property color surfaceColor: Qt.rgba(foregroundColor.r, foregroundColor.g, foregroundColor.b, 0.05)
    readonly property color surfaceColorHover: Qt.rgba(foregroundColor.r, foregroundColor.g, foregroundColor.b, 0.08)
    readonly property color surfaceColorActive: Qt.rgba(foregroundColor.r, foregroundColor.g, foregroundColor.b, 0.12)
    readonly property color surfaceContainerLow: Qt.rgba(foregroundColor.r, foregroundColor.g, foregroundColor.b, 0.04)
    readonly property color surfaceContainerHigh: Qt.rgba(foregroundColor.r, foregroundColor.g, foregroundColor.b, 0.10)
    readonly property color borderColor: Qt.rgba(foregroundColor.r, foregroundColor.g, foregroundColor.b, 0.12)
    readonly property color borderColorHover: Qt.rgba(foregroundColor.r, foregroundColor.g, foregroundColor.b, 0.16)
    readonly property color outlineVariant: Qt.rgba(foregroundColor.r, foregroundColor.g, foregroundColor.b, 0.20)
    
    // Accent variants (Material Design tonal palette)
    readonly property color accentColorHover: Qt.lighter(accentColor, 1.15)
    readonly property color accentColorPressed: Qt.darker(accentColor, 1.1)
    readonly property color accentColorDim: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.20)
    readonly property color accentColorSurface: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.12)
    readonly property color accentColorContainer: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.25)
    readonly property color onAccent: dynamicColors ? ColorScheme.accentTextColor : "#ffffff"
    
    // Material 3 Color Aliases (Celestia Shell compatibility)
    // These provide clearer semantic naming matching M3 guidelines
    readonly property color primaryColor: accentColor
    readonly property color primaryForegroundColor: onAccent
    readonly property color secondaryForegroundColor: dimmedColor
    readonly property color surfaceContainerColor: surfaceContainerHigh
    readonly property color outlineColor: Qt.rgba(foregroundColor.r, foregroundColor.g, foregroundColor.b, 0.38)
    
    /*
     * ========================================================================
     *                  SIZING (Material 3 Expressive)
     * ========================================================================
     * M3 Expressive uses larger, more generous sizing with squircle corners.
     * Key principle: "Joyful, playful, personality-forward"
     */
    
    // Height of the floating island bar (larger for better touch targets)
    readonly property int barHeight: 48
    
    // Width of the floating island bar in pixels
    readonly property int barWidth: 480
    
    // Corner radius for fully rounded elements (pill shape)
    readonly property int borderRadius: 24
    
    // Panel corner radius (M3 Expressive uses 28-32dp for large surfaces)
    readonly property int panelRadius: 28
    
    // Card corner radius (M3 Expressive uses 20-24dp for cards)
    readonly property int cardRadius: 20
    
    // Generic radius alias for compatibility
    readonly property int radius: panelRadius
    
    // Small radius for buttons and chips (M3 Expressive uses 14-16dp)
    readonly property int smallRadius: 14
    
    // Extra small radius for tiny elements
    readonly property int xsRadius: 10
    
    // Internal padding for panels and containers (20dp for more breathing room)
    readonly property int padding: 20
    
    // Size of Material Symbols icons (24dp is standard)
    readonly property int iconSize: 22
    
    // Large icon size for headers
    readonly property int iconSizeLarge: 26
    
    // Extra large icon size for expressive elements
    readonly property int iconSizeXL: 32
    
    // Gap between elements in layouts (10dp for M3 Expressive)
    readonly property int spacing: 10
    
    // Larger spacing for section separators
    readonly property int spacingLarge: 18
    
    // Extra large spacing for major sections
    readonly property int spacingXL: 24
    
    // Gap between bar and top of screen
    readonly property int topMargin: 8
    
    // Animation durations (M3 Expressive Motion - more playful)
    readonly property int animFast: 120
    readonly property int animNormal: 250
    readonly property int animSlow: 350
    readonly property int animEmphasis: 500
    readonly property int animSpring: 400  // For spring/bounce animations

    /*
     * ========================================================================
     *                     BAR STYLE (PERSISTENT)
     * ========================================================================
     * These settings are saved to settings.json and persist across reboots.
     */
    
    // Bar style: "fullwidth" or "floating"
    property string barStyle: "fullwidth"
    onBarStyleChanged: if (!_isLoading) saveSettings()
    
    // Auto-hide the bar when not in use
    // When enabled, bar slides away and windows can use full screen height
    property bool barAutoHide: false
    onBarAutoHideChanged: if (!_isLoading) saveSettings()

    /*
     * ========================================================================
     *                     HYPRLAND SETTINGS (PERSISTENT)
     * ========================================================================
     * These settings are applied to Hyprland and persist across reboots.
     * They are applied on Quickshell startup via applyHyprlandSettings().
     */
    
    // General settings
    property int gapsIn: 5
    onGapsInChanged: if (!_isLoading) saveSettings()
    
    property int gapsOut: 20
    onGapsOutChanged: if (!_isLoading) saveSettings()
    
    property int borderSize: 2
    onBorderSizeChanged: if (!_isLoading) saveSettings()
    
    property string hyprlandLayout: "dwindle"
    onHyprlandLayoutChanged: if (!_isLoading) saveSettings()
    
    // Decoration settings
    property int rounding: 10
    onRoundingChanged: if (!_isLoading) saveSettings()
    
    property real activeOpacity: 1.0
    onActiveOpacityChanged: if (!_isLoading) saveSettings()
    
    property real inactiveOpacity: 1.0
    onInactiveOpacityChanged: if (!_isLoading) saveSettings()
    
    property bool blurEnabled: true
    onBlurEnabledChanged: if (!_isLoading) saveSettings()
    
    property int blurSize: 8
    onBlurSizeChanged: if (!_isLoading) saveSettings()
    
    property int blurPasses: 2
    onBlurPassesChanged: if (!_isLoading) saveSettings()
    
    property bool shadowEnabled: true
    onShadowEnabledChanged: if (!_isLoading) saveSettings()
    
    property bool dimInactive: false
    onDimInactiveChanged: if (!_isLoading) saveSettings()
    
    // Animation settings
    property bool animationsEnabled: true
    onAnimationsEnabledChanged: if (!_isLoading) saveSettings()
    
    property string currentAnimation: "dynamic"
    onCurrentAnimationChanged: if (!_isLoading) saveSettings()
    
    // Default programs
    property string defaultTerminal: "kitty"
    onDefaultTerminalChanged: if (!_isLoading) saveSettings()
    
    property string defaultFileManager: "nautilus"
    onDefaultFileManagerChanged: if (!_isLoading) saveSettings()
    
    property string defaultBrowser: "firefox"
    onDefaultBrowserChanged: if (!_isLoading) saveSettings()

    /*
     * ========================================================================
     *                    FONTS (M3 Expressive Typography)
     * ========================================================================
     * M3 Expressive uses more expressive weights and larger sizes
     * for a more personality-forward look.
     */
    
    // Primary font family - Rubik (rounded, friendly, expressive)
    // Install: sudo pacman -S ttf-rubik-vf
    readonly property string fontFamily: "Rubik"
    
    // Display text (large headings, hero text)
    readonly property int fontSizeDisplay: 28
    
    // Headline text (section titles)
    readonly property int fontSizeHeadline: 20
    
    // Title text (card headers)
    readonly property int fontSizeTitle: 16
    
    // Body text (standard content)
    readonly property int fontSize: 14
    readonly property int fontSizeBody: 14
    
    // Label text (buttons, chips)
    readonly property int fontSizeLabel: 13
    
    // Caption text (secondary info)
    readonly property int fontSizeSmall: 11
    
    // Font weights (M3 Expressive uses bolder weights)
    readonly property int fontWeightRegular: Font.Normal
    readonly property int fontWeightMedium: Font.Medium
    readonly property int fontWeightSemiBold: Font.DemiBold
    readonly property int fontWeightBold: Font.Bold
    
    /*
     * ========================================================================
     *                     USER PROFILE (PERSISTENT)
     * ========================================================================
     */
    
    // Profile picture path (can be changed by user)
    // Set to empty string to show initial letter instead
    property string profilePicturePath: ""
    onProfilePicturePathChanged: if (!_isLoading) saveSettings()
    
    // Convenience property to check if profile picture is set
    readonly property bool hasProfilePicture: profilePicturePath !== ""
    
    /*
     * ========================================================================
     *                     SETTINGS PERSISTENCE
     * ========================================================================
     */
    
    // Timer to debounce settings save (prevents disk thrashing on sliders)
    property var saveDebounceTimer: Timer {
        interval: 1000
        onTriggered: {
            let settings = {
                // Wallpaper settings
                wallpaperPath: root.wallpaperPath,
                wallpaperFillMode: root.wallpaperFillMode,
                wallpaperTransition: root.wallpaperTransition,
                wallpaperTransitionDuration: root.wallpaperTransitionDuration,
                wallpaperEnabled: root.wallpaperEnabled,
                
                // Appearance settings
                dynamicColors: root.dynamicColors,
                
                // Bar settings
                barStyle: root.barStyle,
                barAutoHide: root.barAutoHide,
                profilePicturePath: root.profilePicturePath,
                
                // Hyprland general settings
                gapsIn: root.gapsIn,
                gapsOut: root.gapsOut,
                borderSize: root.borderSize,
                hyprlandLayout: root.hyprlandLayout,
                
                // Hyprland decoration settings
                rounding: root.rounding,
                activeOpacity: root.activeOpacity,
                inactiveOpacity: root.inactiveOpacity,
                blurEnabled: root.blurEnabled,
                blurSize: root.blurSize,
                blurPasses: root.blurPasses,
                shadowEnabled: root.shadowEnabled,
                dimInactive: root.dimInactive,
                
                // Hyprland animation settings
                animationsEnabled: root.animationsEnabled,
                currentAnimation: root.currentAnimation,
                
                // Default programs
                defaultTerminal: root.defaultTerminal,
                defaultFileManager: root.defaultFileManager,
                defaultBrowser: root.defaultBrowser
            }
            
            let json = JSON.stringify(settings, null, 2)
            saveSettingsProc.settingsJson = json
            saveSettingsProc.running = true
        }
    }
    
    // Save settings to JSON file (Debounced)
    function saveSettings() {
        saveDebounceTimer.restart()
    }
    
    // Load settings from JSON file
    function loadSettings() {
        loadSettingsProc.running = true
    }
    
    // Apply all Hyprland settings (called after loading)
    function applyHyprlandSettings() {
        // General settings
        applyHyprlandSetting("general:gaps_in", root.gapsIn)
        applyHyprlandSetting("general:gaps_out", root.gapsOut)
        applyHyprlandSetting("general:border_size", root.borderSize)
        applyHyprlandSetting("general:layout", root.hyprlandLayout)
        
        // Decoration settings
        applyHyprlandSetting("decoration:rounding", root.rounding)
        applyHyprlandSetting("decoration:active_opacity", root.activeOpacity)
        applyHyprlandSetting("decoration:inactive_opacity", root.inactiveOpacity)
        applyHyprlandSetting("decoration:blur:enabled", root.blurEnabled ? "true" : "false")
        applyHyprlandSetting("decoration:blur:size", root.blurSize)
        applyHyprlandSetting("decoration:blur:passes", root.blurPasses)
        applyHyprlandSetting("decoration:shadow:enabled", root.shadowEnabled ? "true" : "false")
        applyHyprlandSetting("decoration:dim_inactive", root.dimInactive ? "true" : "false")
        
        // Animation settings
        applyHyprlandSetting("animations:enabled", root.animationsEnabled ? "true" : "false")
        
        // Apply animation preset if animations are enabled
        if (root.animationsEnabled && root.currentAnimation !== "disable") {
            applyAnimationPreset(root.currentAnimation)
        }
        
        console.log("Config: Hyprland settings applied")
    }
    
    // Apply a single Hyprland setting via hyprctl
    function applyHyprlandSetting(key, value) {
        hyprctlProcess.command = ["hyprctl", "keyword", key, String(value)]
        hyprctlProcess.running = true
    }
    
    // Animation presets data
    readonly property var animationPresets: {
        "classic": {
            beziers: ["myBezier, 0.05, 0.9, 0.1, 1.05"],
            animations: [
                "windows, 1, 7, myBezier",
                "windowsOut, 1, 7, default, popin 80%",
                "border, 1, 10, default",
                "borderangle, 1, 8, default",
                "fade, 1, 7, default",
                "workspaces, 1, 6, default"
            ]
        },
        "dynamic": {
            beziers: [
                "wind, 0.05, 0.9, 0.1, 1.05",
                "winIn, 0.1, 1.1, 0.1, 1.1",
                "winOut, 0.3, -0.3, 0, 1",
                "liner, 1, 1, 1, 1"
            ],
            animations: [
                "windows, 1, 6, wind, slide",
                "windowsIn, 1, 6, winIn, slide",
                "windowsOut, 1, 5, winOut, slide",
                "windowsMove, 1, 5, wind, slide",
                "border, 1, 1, liner",
                "borderangle, 1, 30, liner, loop",
                "fade, 1, 10, default",
                "workspaces, 1, 5, wind"
            ]
        },
        "fast": {
            beziers: [
                "linear, 0, 0, 1, 1",
                "md3_standard, 0.2, 0, 0, 1",
                "md3_decel, 0.05, 0.7, 0.1, 1",
                "md3_accel, 0.3, 0, 0.8, 0.15",
                "overshot, 0.05, 0.9, 0.1, 1.1",
                "easeOutExpo, 0.16, 1, 0.3, 1"
            ],
            animations: [
                "windows, 1, 3, md3_decel, popin 60%",
                "border, 1, 10, default",
                "fade, 1, 2.5, md3_decel",
                "workspaces, 1, 3.5, easeOutExpo, slide",
                "specialWorkspace, 1, 3, md3_decel, slidevert"
            ]
        },
        "end4": {
            beziers: [
                "linear, 0, 0, 1, 1",
                "md3_standard, 0.2, 0, 0, 1",
                "md3_decel, 0.05, 0.7, 0.1, 1",
                "md3_accel, 0.3, 0, 0.8, 0.15",
                "overshot, 0.05, 0.9, 0.1, 1.1",
                "menu_decel, 0.1, 1, 0, 1",
                "menu_accel, 0.38, 0.04, 1, 0.07",
                "easeOutCirc, 0, 0.55, 0.45, 1",
                "easeOutExpo, 0.16, 1, 0.3, 1"
            ],
            animations: [
                "windows, 1, 3, md3_decel, popin 60%",
                "windowsIn, 1, 3, md3_decel, popin 60%",
                "windowsOut, 1, 3, md3_accel, popin 60%",
                "border, 1, 10, default",
                "fade, 1, 3, md3_decel",
                "layersIn, 1, 3, menu_decel, slide",
                "layersOut, 1, 1.6, menu_accel",
                "fadeLayersIn, 1, 2, menu_decel",
                "fadeLayersOut, 1, 4.5, menu_accel",
                "workspaces, 1, 7, menu_decel, slide",
                "specialWorkspace, 1, 3, md3_decel, slidevert"
            ]
        },
        "high": {
            beziers: [
                "wind, 0.05, 0.9, 0.1, 1.05",
                "winIn, 0.1, 1.1, 0.1, 1.1",
                "winOut, 0.3, -0.3, 0, 1",
                "liner, 1, 1, 1, 1"
            ],
            animations: [
                "windows, 1, 6, wind, slide",
                "windowsIn, 1, 6, winIn, slide",
                "windowsOut, 1, 5, winOut, slide",
                "windowsMove, 1, 5, wind, slide",
                "border, 1, 1, liner",
                "borderangle, 1, 30, liner, loop",
                "fade, 1, 10, default",
                "workspaces, 1, 5, wind"
            ]
        }
    }
    
    // Apply an animation preset by name
    function applyAnimationPreset(presetName) {
        let preset = animationPresets[presetName]
        if (!preset) return
        
        // Apply bezier curves
        for (let i = 0; i < preset.beziers.length; i++) {
            applyHyprlandSetting("bezier", preset.beziers[i])
        }
        
        // Apply animations (with slight delay to ensure beziers are set)
        for (let j = 0; j < preset.animations.length; j++) {
            applyHyprlandSetting("animation", preset.animations[j])
        }
    }
    
    // Process for running hyprctl commands
    property var hyprctlProcess: Process {
        command: ["hyprctl", "keyword"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.log("Config: hyprctl command failed with exit code:", exitCode)
            }
        }
    }
    
    // Process to save settings file
    property var saveSettingsProc: Process {
        property string settingsJson: ""
        command: ["sh", "-c", "cat > '" + root.settingsFilePath + "' << 'SETTINGS_EOF'\n" + settingsJson + "\nSETTINGS_EOF"]
    }
    
    // Process to load settings file
    property var loadSettingsProc: Process {
        command: ["sh", "-c", "cat '" + root.settingsFilePath + "' 2>/dev/null || echo '{}'"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let settings = JSON.parse(this.text)
                    
                    // Apply wallpaper settings
                    if (settings.wallpaperPath !== undefined) {
                        root.wallpaperPath = settings.wallpaperPath
                    }
                    if (settings.wallpaperFillMode !== undefined) {
                        root.wallpaperFillMode = settings.wallpaperFillMode
                    }
                    if (settings.wallpaperTransition !== undefined) {
                        root.wallpaperTransition = settings.wallpaperTransition
                    }
                    if (settings.wallpaperTransitionDuration !== undefined) {
                        root.wallpaperTransitionDuration = settings.wallpaperTransitionDuration
                    }
                    if (settings.wallpaperEnabled !== undefined) {
                        root.wallpaperEnabled = settings.wallpaperEnabled
                    }
                    
                    // Apply appearance settings
                    if (settings.dynamicColors !== undefined) {
                        root.dynamicColors = settings.dynamicColors
                    }
                    
                    // Apply loaded bar settings
                    if (settings.barStyle !== undefined) {
                        root.barStyle = settings.barStyle
                    }
                    if (settings.barAutoHide !== undefined) {
                        root.barAutoHide = settings.barAutoHide
                    }
                    if (settings.profilePicturePath !== undefined) {
                        root.profilePicturePath = settings.profilePicturePath
                    }
                    
                    // Apply loaded Hyprland general settings
                    if (settings.gapsIn !== undefined) {
                        root.gapsIn = settings.gapsIn
                    }
                    if (settings.gapsOut !== undefined) {
                        root.gapsOut = settings.gapsOut
                    }
                    if (settings.borderSize !== undefined) {
                        root.borderSize = settings.borderSize
                    }
                    if (settings.hyprlandLayout !== undefined) {
                        root.hyprlandLayout = settings.hyprlandLayout
                    }
                    
                    // Apply loaded Hyprland decoration settings
                    if (settings.rounding !== undefined) {
                        root.rounding = settings.rounding
                    }
                    if (settings.activeOpacity !== undefined) {
                        root.activeOpacity = settings.activeOpacity
                    }
                    if (settings.inactiveOpacity !== undefined) {
                        root.inactiveOpacity = settings.inactiveOpacity
                    }
                    if (settings.blurEnabled !== undefined) {
                        root.blurEnabled = settings.blurEnabled
                    }
                    if (settings.blurSize !== undefined) {
                        root.blurSize = settings.blurSize
                    }
                    if (settings.blurPasses !== undefined) {
                        root.blurPasses = settings.blurPasses
                    }
                    if (settings.shadowEnabled !== undefined) {
                        root.shadowEnabled = settings.shadowEnabled
                    }
                    if (settings.dimInactive !== undefined) {
                        root.dimInactive = settings.dimInactive
                    }
                    
                    // Apply loaded animation settings
                    if (settings.animationsEnabled !== undefined) {
                        root.animationsEnabled = settings.animationsEnabled
                    }
                    if (settings.currentAnimation !== undefined) {
                        root.currentAnimation = settings.currentAnimation
                    }
                    
                    // Apply loaded default programs
                    if (settings.defaultTerminal !== undefined) {
                        root.defaultTerminal = settings.defaultTerminal
                    }
                    if (settings.defaultFileManager !== undefined) {
                        root.defaultFileManager = settings.defaultFileManager
                    }
                    if (settings.defaultBrowser !== undefined) {
                        root.defaultBrowser = settings.defaultBrowser
                    }
                    
                    console.log("Config: Settings loaded from", root.settingsFilePath)
                    
                    // Apply Hyprland settings after loading
                    root.applyHyprlandSettings()
                    
                } catch (e) {
                    console.log("Config: Could not parse settings file, using defaults")
                }
                
                // Done loading, enable saving
                root._isLoading = false
            }
        }
    }
    
    // Load settings on startup
    Component.onCompleted: {
        loadSettings()
    }
}
