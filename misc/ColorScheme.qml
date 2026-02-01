/*
 * ============================================================================
 *                         COLOR SCHEME SERVICE
 * ============================================================================
 * 
 * FILE: misc/ColorScheme.qml
 * PURPOSE: Dynamically load Material You colors from wallpaper
 * 
 * ============================================================================
 *                              OVERVIEW
 * ============================================================================
 * 
 * This service watches a generated colors JSON file and provides dynamic
 * color properties that update when the wallpaper changes.
 * 
 * The color generation workflow:
 *   1. User changes wallpaper (via swww, hyprpaper, etc.)
 *   2. scripts/apply-colors.sh is called (manually or via hook)
 *   3. scripts/colorgen.py extracts colors using Material You algorithm
 *   4. Colors are saved to ~/.local/state/quickshell/generated/colors.json
 *   5. This service watches the file and updates all color properties
 *   6. UI components automatically update via property bindings
 * 
 * ============================================================================
 *                         HOW TO USE
 * ============================================================================
 * 
 * 1. AUTOMATIC COLORS:
 *    In your components, use ColorScheme properties instead of hardcoded:
 *    
 *    // Instead of:
 *    color: "#1a1a1a"
 *    
 *    // Use:
 *    color: ColorScheme.backgroundColor
 * 
 * 2. MANUAL REFRESH:
 *    Call ColorScheme.refresh() to reload colors from file
 * 
 * 3. APPLY NEW WALLPAPER:
 *    Call ColorScheme.applyWallpaper("/path/to/image.jpg")
 * 
 * ============================================================================
 *                         COLOR PROPERTIES
 * ============================================================================
 * 
 * BACKGROUNDS:
 *   - backgroundColor: Main panel/popup background
 *   - backgroundColorDim: Darker variant
 *   - backgroundColorBright: Lighter variant
 *   - backgroundColorHover: Hover state
 * 
 * TEXT:
 *   - foregroundColor: Primary text
 *   - dimmedColor: Secondary/inactive text
 * 
 * ACCENT:
 *   - accentColor: Primary accent (buttons, highlights)
 *   - accentColorDim: Darker accent variant
 *   - accentTextColor: Text on accent backgrounds
 * 
 * WORKSPACE:
 *   - workspaceActive: Active workspace indicator
 *   - workspaceInactive: Inactive workspace
 *   - workspaceUrgent: Urgent notification
 * 
 * ============================================================================
 */

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    
    // ========================================================================
    //                          CONFIGURATION
    // ========================================================================
    
    // Path to generated colors file
    readonly property string colorsFilePath: {
        let stateHome = Quickshell.env("XDG_STATE_HOME") || 
                        Quickshell.env("HOME") + "/.local/state"
        return stateHome + "/quickshell/generated/colors.json"
    }
    
    // Path to the color generation script
    readonly property string applyScriptPath: Quickshell.shellDir + "/scripts/apply-colors.sh"
    
    // Whether dynamic colors are enabled
    property bool enabled: true
    
    // Current color mode (dark/light)
    property string mode: "dark"
    
    // Current scheme type
    property string scheme: "tonal-spot"
    
    // The seed color extracted from wallpaper
    property color seedColor: "#007AFF"
    
    // Current wallpaper path
    property string wallpaperPath: ""
    
    // ========================================================================
    //                     SHELL COLORS (Dynamic)
    // ========================================================================
    
    // Main background color for the bar and panels
    property color backgroundColor: "#1a1a1a"
    property color backgroundColorDim: "#141414"
    property color backgroundColorBright: "#2a2a2a"
    property color backgroundColorHover: "#2a2a2a"
    
    // Primary text and icon color
    property color foregroundColor: "#ffffff"
    
    // Dimmed text for secondary information
    property color dimmedColor: "#888888"
    
    // Accent color for highlights, active items
    property color accentColor: "#007AFF"
    property color accentColorDim: "#004c99"
    property color accentTextColor: "#ffffff"
    
    // Secondary and tertiary colors
    property color secondaryColor: "#666666"
    property color tertiaryColor: "#888888"
    
    // Surface containers (layered backgrounds)
    property color surfaceContainer: "#1e1e1e"
    property color surfaceContainerLow: "#1a1a1a"
    property color surfaceContainerHigh: "#282828"
    
    // Workspace indicator colors
    property color workspaceActive: "#ffffff"
    property color workspaceInactive: "#555555"
    property color workspaceUrgent: "#ff5555"
    
    // Error colors
    property color errorColor: "#ff5555"
    property color errorTextColor: "#ffffff"
    
    // Success color (connected, charging, etc.)
    property color successColor: "#4ade80"
    
    // Warning color (connecting, pending, etc.)
    property color warningColor: "#ffa726"
    
    // Border and shadow
    property color borderColor: "#333333"
    property color shadowColor: "#000000"
    
    // ========================================================================
    //                     RAW MATERIAL COLORS
    // ========================================================================
    
    // Store all raw Material colors for advanced usage
    property var materialColors: ({})
    
    // ========================================================================
    //                     COLOR FILE WATCHER
    // ========================================================================
    
    // Load colors from file using Process
    function loadColors() {
        loadColorsProc.running = true
    }
    
    Process {
        id: loadColorsProc
        command: ["cat", root.colorsFilePath]
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.trim()) {
                    root.parseColors(this.text)
                    console.log("[ColorScheme] Colors loaded from file")
                } else {
                    console.log("[ColorScheme] Colors file empty or not found, using defaults")
                }
            }
        }
    }
    
    // Watch for file changes using a timer that checks modification time
    Timer {
        id: colorWatchTimer
        interval: 2000
        repeat: true
        running: true
        
        property string lastModTime: ""
        
        onTriggered: {
            checkModTimeProc.running = true
        }
    }
    
    Process {
        id: checkModTimeProc
        command: ["stat", "-c", "%Y", root.colorsFilePath]
        
        stdout: StdioCollector {
            onStreamFinished: {
                let modTime = this.text.trim()
                if (modTime && modTime !== colorWatchTimer.lastModTime) {
                    if (colorWatchTimer.lastModTime !== "") {
                        console.log("[ColorScheme] Colors file changed, reloading...")
                        root.loadColors()
                    }
                    colorWatchTimer.lastModTime = modTime
                }
            }
        }
    }
    
    // ========================================================================
    //                          METHODS
    // ========================================================================
    
    // Parse and apply colors from JSON
    function parseColors(jsonText) {
        try {
            let data = JSON.parse(jsonText)
            
            // Update mode and scheme
            if (data.mode) root.mode = data.mode
            if (data.scheme) root.scheme = data.scheme
            if (data.seedColor) root.seedColor = data.seedColor
            
            // Store raw material colors
            if (data.material) root.materialColors = data.material
            
            // Apply shell colors
            if (data.shell) {
                let shell = data.shell
                
                // Backgrounds
                if (shell.backgroundColor) root.backgroundColor = shell.backgroundColor
                if (shell.backgroundColorDim) root.backgroundColorDim = shell.backgroundColorDim
                if (shell.backgroundColorBright) root.backgroundColorBright = shell.backgroundColorBright
                if (shell.backgroundColorHover) root.backgroundColorHover = shell.backgroundColorHover
                
                // Text
                if (shell.foregroundColor) root.foregroundColor = shell.foregroundColor
                if (shell.dimmedColor) root.dimmedColor = shell.dimmedColor
                
                // Accent
                if (shell.accentColor) root.accentColor = shell.accentColor
                if (shell.accentColorDim) root.accentColorDim = shell.accentColorDim
                if (shell.onAccentColor) root.accentTextColor = shell.onAccentColor
                
                // Secondary
                if (shell.secondaryColor) root.secondaryColor = shell.secondaryColor
                if (shell.tertiaryColor) root.tertiaryColor = shell.tertiaryColor
                
                // Surface
                if (shell.surfaceContainer) root.surfaceContainer = shell.surfaceContainer
                if (shell.surfaceContainerLow) root.surfaceContainerLow = shell.surfaceContainerLow
                if (shell.surfaceContainerHigh) root.surfaceContainerHigh = shell.surfaceContainerHigh
                
                // Workspace
                if (shell.workspaceActive) root.workspaceActive = shell.workspaceActive
                if (shell.workspaceInactive) root.workspaceInactive = shell.workspaceInactive
                if (shell.workspaceUrgent) root.workspaceUrgent = shell.workspaceUrgent
                
                // Error
                if (shell.errorColor) root.errorColor = shell.errorColor
                if (shell.onErrorColor) root.errorTextColor = shell.onErrorColor
                
                // Success/Warning
                if (shell.successColor) root.successColor = shell.successColor
                if (shell.warningColor) root.warningColor = shell.warningColor
                
                // Border/Shadow
                if (shell.borderColor) root.borderColor = shell.borderColor
                if (shell.shadowColor) root.shadowColor = shell.shadowColor
            }
            
            console.log("[ColorScheme] Colors loaded - Accent:", root.accentColor)
            
        } catch (e) {
            console.log("[ColorScheme] Failed to parse colors:", e)
        }
    }
    
    // Manually refresh colors from file
    function refresh() {
        // Trigger file load
        loadColors()
    }
    
    // Debounce timer for expensive color generation
    property var pendingApplyCommand: null
    
    Timer {
        id: applyDebounceTimer
        interval: 500
        onTriggered: {
            if (root.pendingApplyCommand) {
                applyProcess.command = root.pendingApplyCommand
                applyProcess.running = true
                root.pendingApplyCommand = null
            }
        }
    }
    
    // Apply colors from a wallpaper
    function applyWallpaper(imagePath, modeOverride, schemeOverride) {
        let mode = modeOverride || root.mode
        let scheme = schemeOverride || root.scheme
        
        root.wallpaperPath = imagePath
        
        root.pendingApplyCommand = ["bash", root.applyScriptPath, imagePath, "--mode", mode, "--scheme", scheme]
        applyDebounceTimer.restart()
    }
    
    // Apply colors from a specific color
    function applyColor(hexColor, modeOverride, schemeOverride) {
        let mode = modeOverride || root.mode
        let scheme = schemeOverride || root.scheme
        
        // Use colorgen.py directly with --color via venv
        let scriptPath = Quickshell.shellDir + "/scripts/colorgen.py"
        let outputPath = root.colorsFilePath
        let venvPython = Quickshell.env("HOME") + "/.local/share/quickshell-venv/bin/python3"
        
        root.pendingApplyCommand = [
            venvPython, scriptPath,
            "--color", hexColor,
            "--mode", mode,
            "--scheme", scheme,
            "--output", outputPath
        ]
        applyDebounceTimer.restart()
    }
    
    // Toggle between dark and light mode
    function toggleMode() {
        root.mode = (root.mode === "dark") ? "light" : "dark"
        if (root.wallpaperPath) {
            applyWallpaper(root.wallpaperPath)
        }
    }
    
    // Process for running color generation script
    Process {
        id: applyProcess
        
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                console.log("[ColorScheme] Color generation completed")
                // File watcher will pick up the change
            } else {
                console.log("[ColorScheme] Color generation failed:", exitCode)
            }
        }
    }
    
    // ========================================================================
    //                     HELPER FUNCTIONS
    // ========================================================================
    
    // Get a color with adjusted alpha
    function withAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }
    
    // Mix two colors
    function mix(color1, color2, ratio) {
        let r = color1.r * (1 - ratio) + color2.r * ratio
        let g = color1.g * (1 - ratio) + color2.g * ratio
        let b = color1.b * (1 - ratio) + color2.b * ratio
        return Qt.rgba(r, g, b, 1)
    }
    
    // Lighten a color
    function lighten(color, amount) {
        return Qt.lighter(color, 1 + amount)
    }
    
    // Darken a color
    function darken(color, amount) {
        return Qt.darker(color, 1 + amount)
    }
    
    // ========================================================================
    //                          INITIALIZATION
    // ========================================================================
    
    Component.onCompleted: {
        console.log("[ColorScheme] Initialized, watching:", root.colorsFilePath)
        // Load colors on startup
        root.loadColors()
    }
}
