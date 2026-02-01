/*
 * ============================================================================
 *                         HYPRLAND CONFIG HANDLER
 * ============================================================================
 * 
 * FILE: misc/HyprlandConfig.qml
 * PURPOSE: Read and write Hyprland configuration variables from config.conf
 * 
 * ============================================================================
 *                              OVERVIEW
 * ============================================================================
 * 
 * This singleton reads the Hyprland config file and parses $variable = value
 * pairs. It provides properties that can be bound to UI elements and
 * automatically writes changes back to the config file.
 * 
 * Config file: ~/.config/hypr/config.conf
 * 
 * ============================================================================
 *                         HOW IT WORKS
 * ============================================================================
 * 
 * 1. On startup, reads the config file
 * 2. Parses $variable = value lines using regex
 * 3. Exposes properties for each setting
 * 4. When a property changes, rewrites that line in the config
 * 5. Applies the change to Hyprland via hyprctl
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
    //                     CONFIG FILE PATH
    // ========================================================================
    
    readonly property string configFilePath: "/home/okami/.config/hypr/config.conf"
    
    // Flag to prevent saving during initial load
    property bool _isLoading: true
    
    // Raw config file content
    property string _configContent: ""
    
    // ========================================================================
    //                     DEFAULT PROGRAMS
    // ========================================================================
    
    property string terminal: "kitty"
    onTerminalChanged: if (!_isLoading) updateConfigValue("terminal", terminal)
    
    property string fileManager: "nautilus"
    onFileManagerChanged: if (!_isLoading) updateConfigValue("fileManager", fileManager)
    
    property string browser: "zen"
    onBrowserChanged: if (!_isLoading) updateConfigValue("browser", browser)
    
    // ========================================================================
    //                     ANIMATION
    // ========================================================================
    
    // Current animation path from config
    property string animationPath: "../animations/LimeFrenzy.conf"
    onAnimationPathChanged: if (!_isLoading) {
        updateConfigValue("ANIMATION_PATH", animationPath)
        // Reload Hyprland config to apply new animation
        reloadHyprland()
    }
    
    // Available animation paths (loaded from animation_paths file)
    property var animationPaths: []
    
    // Path to animation paths list file
    readonly property string animationPathsFile: "/home/okami/.config/hypr/animation_paths"
    
    // Get display name from path (e.g., "../animations/LimeFrenzy.conf" -> "LimeFrenzy")
    function getAnimationName(path) {
        let filename = path.split("/").pop()  // Get filename
        return filename.replace(".conf", "")   // Remove extension
    }
    
    // ========================================================================
    //                     GENERAL SETTINGS
    // ========================================================================
    
    property int windowGaps: 6
    onWindowGapsChanged: if (!_isLoading) {
        updateConfigValue("windowGaps", windowGaps)
        applyHyprctl("general:gaps_in", windowGaps)
    }
    
    property int screenGaps: 5
    onScreenGapsChanged: if (!_isLoading) {
        updateConfigValue("screenGaps", screenGaps)
        applyHyprctl("general:gaps_out", screenGaps)
    }
    
    property int borderSize: 4
    onBorderSizeChanged: if (!_isLoading) {
        updateConfigValue("borderSize", borderSize)
        applyHyprctl("general:border_size", borderSize)
    }
    
    property string activeColor: "rgba(f5c2e7ee) rgba(89b4faee) 45deg"
    onActiveColorChanged: if (!_isLoading) {
        updateConfigValue("activecolor", activeColor)
        // Border colors require reload to apply gradient
        reloadHyprland()
    }
    
    property string inactiveColor: "rgba(11111baa)"
    onInactiveColorChanged: if (!_isLoading) {
        updateConfigValue("inactivecolor", inactiveColor)
        reloadHyprland()
    }
    
    property bool borderResize: true
    onBorderResizeChanged: if (!_isLoading) {
        updateConfigValue("borderResize", borderResize ? "true" : "false")
        applyHyprctl("general:resize_on_border", borderResize ? "true" : "false")
    }

    property string layoutMode: "dwindle"
    onLayoutModeChanged: if (!_isLoading) {
        updateConfigValue("MODE", layoutMode)
        applyHyprctl("general:layout", layoutMode)
    }
    
    // ========================================================================
    //                     DECORATION SETTINGS
    // ========================================================================
    
    property int rounding: 10
    onRoundingChanged: if (!_isLoading) {
        updateConfigValue("rounding", rounding)
        applyHyprctl("decoration:rounding", rounding)
    }
    
    property real roundingPower: 2
    onRoundingPowerChanged: if (!_isLoading) {
        updateConfigValue("rounding_power", roundingPower)
        applyHyprctl("decoration:rounding_power", roundingPower)
    }
    
    property real activeOpacity: 1.0
    onActiveOpacityChanged: if (!_isLoading) {
        updateConfigValue("active_opacity", activeOpacity.toFixed(1))
        applyHyprctl("decoration:active_opacity", activeOpacity.toFixed(2))
    }
    
    property real inactiveOpacity: 0.9
    onInactiveOpacityChanged: if (!_isLoading) {
        updateConfigValue("inactive_opacity", inactiveOpacity.toFixed(1))
        applyHyprctl("decoration:inactive_opacity", inactiveOpacity.toFixed(2))
    }
    
    property bool dimInactive: true
    onDimInactiveChanged: if (!_isLoading) {
        updateConfigValue("dim_inactive", dimInactive ? "true" : "false")
        applyHyprctl("decoration:dim_inactive", dimInactive ? "true" : "false")
    }
    
    property bool shadowEnabled: true
    onShadowEnabledChanged: if (!_isLoading) {
        updateConfigValue("shadow_enabled", shadowEnabled ? "true" : "false")
        applyHyprctl("decoration:shadow:enabled", shadowEnabled ? "true" : "false")
    }
    
    property bool blurEnabled: true
    onBlurEnabledChanged: if (!_isLoading) {
        updateConfigValue("blur_enabled", blurEnabled ? "true" : "false")
        applyHyprctl("decoration:blur:enabled", blurEnabled ? "true" : "false")
    }
    
    property int blurSize: 4
    onBlurSizeChanged: if (!_isLoading) {
        updateConfigValue("blur_size", blurSize)
        applyHyprctl("decoration:blur:size", blurSize)
    }
    
    property int blurPasses: 3
    onBlurPassesChanged: if (!_isLoading) {
        updateConfigValue("blur_passes", blurPasses)
        applyHyprctl("decoration:blur:passes", blurPasses)
    }
    
    // ========================================================================
    //                     CONFIG FILE OPERATIONS
    // ========================================================================
    
    // Read the config file
    function loadConfig() {
        loadConfigProc.running = true
    }
    
    // ------------------------------------------------------------------------
    // Optimized Update Logic (Debounced & Batched)
    // ------------------------------------------------------------------------

    property var pendingConfigUpdates: ({})
    property var pendingHyprctlUpdates: ({})

    // Timer to batch writes to config file (reduces disk I/O and sed processes)
    property var saveConfigTimer: Timer {
        interval: 500
        onTriggered: flushConfigUpdates()
    }

    // Timer to throttle hyprctl commands (reduces process spawning on sliders)
    property var hyprctlTimer: Timer {
        interval: 50
        onTriggered: flushHyprctlUpdates()
    }

    // Timer to debounce Hyprland reloads (prevents hangs on rapid changes)
    property var reloadTimer: Timer {
        interval: 1000
        onTriggered: reloadHyprlandProc.running = true
    }

    // Update a single variable in the config (Batched)
    function updateConfigValue(varName, value) {
        pendingConfigUpdates[varName] = value
        saveConfigTimer.restart()
    }
    
    // Apply setting to running Hyprland (Throttled)
    function applyHyprctl(key, value) {
        pendingHyprctlUpdates[key] = value
        if (!hyprctlTimer.running) hyprctlTimer.restart()
    }
    
    // Reload Hyprland to apply animation changes (Debounced)
    function reloadHyprland() {
        reloadTimer.restart()
    }

    // Flush pending config updates to disk
    function flushConfigUpdates() {
        let args = ["sed", "-i"]
        let hasUpdates = false
        
        for (let varName in pendingConfigUpdates) {
            let value = pendingConfigUpdates[varName]
            // Use sed with | as delimiter to handle paths with /
            // Also escape any | in the value just in case
            let escapedValue = String(value).replace(/\|/g, "\\|")
            
            // Add -e expression for this variable
            args.push("-e")
            args.push("s|^\\$" + varName + " *=.*|$" + varName + " =" + escapedValue + "|")
            
            hasUpdates = true
        }
        
        if (hasUpdates) {
            args.push(configFilePath)
            updateConfigProc.command = args
            updateConfigProc.running = true
            console.log("HyprlandConfig: Flushing", Object.keys(pendingConfigUpdates).length, "config updates")
            pendingConfigUpdates = {}
        }
    }

    // Flush pending hyprctl commands
    function flushHyprctlUpdates() {
        // We can batch hyprctl commands using the batch keyword or just run them
        // hyprctl --batch "keyword key value ; keyword key2 value2"
        
        let batchCmd = []
        for (let key in pendingHyprctlUpdates) {
            let value = pendingHyprctlUpdates[key]
            batchCmd.push("keyword " + key + " " + String(value))
        }
        
        if (batchCmd.length > 0) {
            let finalCmd = batchCmd.join(" ; ")
            hyprctlProc.command = ["hyprctl", "--batch", finalCmd]
            hyprctlProc.running = true
            pendingHyprctlUpdates = {}
        }
    }
    
    // Parse a line and extract variable name and value
    function parseLine(line) {
        // Match $varName = value (with optional spaces)
        let match = line.match(/^\$(\w+)\s*=\s*(.*)$/)
        if (match) {
            return { name: match[1], value: match[2].trim() }
        }
        return null
    }
    
    // ========================================================================
    //                     PROCESSES
    // ========================================================================
    
    // Process to load config file
    property var loadConfigProc: Process {
        command: ["cat", root.configFilePath]
        
        stdout: SplitParser {
            onRead: data => {
                root._configContent += data + "\n"
            }
        }
        
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                // Parse the config content
                let lines = root._configContent.split("\n")
                
                for (let i = 0; i < lines.length; i++) {
                    let parsed = root.parseLine(lines[i])
                    if (parsed) {
                        // Map config variables to properties
                        switch (parsed.name) {
                            case "terminal":
                                root.terminal = parsed.value
                                break
                            case "fileManager":
                                root.fileManager = parsed.value
                                break
                            case "browser":
                                root.browser = parsed.value
                                break
                            case "ANIMATION_PATH":
                                root.animationPath = parsed.value
                                break
                            case "windowGaps":
                                root.windowGaps = parseInt(parsed.value) || 6
                                break
                            case "screenGaps":
                                root.screenGaps = parseInt(parsed.value) || 5
                                break
                            case "borderSize":
                                root.borderSize = parseInt(parsed.value) || 4
                                break
                            case "activecolor":
                                root.activeColor = parsed.value
                                break
                            case "inactivecolor":
                                root.inactiveColor = parsed.value
                                break
                            case "borderResize":
                                root.borderResize = parsed.value === "true"
                                break
                            case "MODE":
                                root.layoutMode = parsed.value
                                break
                            case "rounding":
                                root.rounding = parseInt(parsed.value) || 10
                                break
                            case "rounding_power":
                                root.roundingPower = parseFloat(parsed.value) || 2
                                break
                            case "active_opacity":
                                root.activeOpacity = parseFloat(parsed.value) || 1.0
                                break
                            case "inactive_opacity":
                                root.inactiveOpacity = parseFloat(parsed.value) || 0.9
                                break
                            case "dim_inactive":
                                root.dimInactive = parsed.value === "true"
                                break
                            case "shadow_enabled":
                                root.shadowEnabled = parsed.value === "true"
                                break
                            case "blur_enabled":
                                root.blurEnabled = parsed.value === "true"
                                break
                            case "blur_size":
                                root.blurSize = parseInt(parsed.value) || 4
                                break
                            case "blur_passes":
                                root.blurPasses = parseInt(parsed.value) || 3
                                break
                        }
                    }
                }
                
                console.log("HyprlandConfig: Loaded config from", root.configFilePath)
                
                // Now load animation paths
                loadAnimationPathsProc.running = true
            } else {
                console.log("HyprlandConfig: Failed to load config file")
                root._isLoading = false
            }
        }
    }
    
    // Process to load animation paths file
    property var loadAnimationPathsProc: Process {
        command: ["cat", root.animationPathsFile]
        
        property var pathList: []
        
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() !== "") {
                    loadAnimationPathsProc.pathList.push(data)
                }
            }
        }
        
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                let fullOutput = loadAnimationPathsProc.pathList.join("\n")
                let lines = fullOutput.trim().split("\n")
                let paths = []
                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim()
                    if (line !== "") {
                        paths.push(line)
                    }
                }
                root.animationPaths = paths
                console.log("HyprlandConfig: Loaded", paths.length, "animation paths")
            } else {
                console.log("HyprlandConfig: Failed to load animation paths")
            }
            
            // Clear buffer
            loadAnimationPathsProc.pathList = []
            
            // Done loading everything
            root._isLoading = false
        }
    }
    
    // Process to update config file
    property var updateConfigProc: Process {
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.log("HyprlandConfig: Failed to update config file")
            }
        }
    }
    
    // Process to run hyprctl commands
    property var hyprctlProc: Process {
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.log("HyprlandConfig: hyprctl command failed")
            }
        }
    }
    
    // Process to reload Hyprland (for animation changes)
    property var reloadHyprlandProc: Process {
        command: ["hyprctl", "reload"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                console.log("HyprlandConfig: Hyprland reloaded")
            } else {
                console.log("HyprlandConfig: Failed to reload Hyprland")
            }
        }
    }
    
    // Load config on startup
    Component.onCompleted: {
        loadConfig()
    }
}
