/*
 * ============================================================================
 *                          DISPLAY HANDLER
 * ============================================================================
 * 
 * FILE: misc/DisplayHandler.qml
 * PURPOSE: Singleton for Hyprland display/monitor management
 * 
 * ============================================================================
 *                              OVERVIEW
 * ============================================================================
 * 
 * This handler manages display settings:
 *   - Screen brightness (via brightnessctl)
 *   - Monitor configuration (via hyprctl)
 *   - Night light / color temperature (via hyprsunset)
 * 
 * ============================================================================
 *                         DEPENDENCIES
 * ============================================================================
 * 
 * Brightness control:
 *   sudo pacman -S brightnessctl
 *   # May need to add user to video group:
 *   sudo usermod -aG video $USER
 * 
 * Night light:
 *   yay -S hyprsunset  (or build from source)
 * 
 * ============================================================================
 *                         HYPRCTL MONITOR COMMANDS
 * ============================================================================
 * 
 * LIST MONITORS:
 *   hyprctl monitors         <- Human readable
 *   hyprctl monitors -j      <- JSON format
 * 
 * CONFIGURE MONITOR:
 *   hyprctl keyword monitor <name>,<res>@<hz>,<pos>,<scale>
 *   
 *   Examples:
 *   hyprctl keyword monitor DP-1,1920x1080@60,0x0,1
 *   hyprctl keyword monitor eDP-1,2560x1440@165,auto,1.5
 *   hyprctl keyword monitor HDMI-A-1,disable
 * 
 * RESOLUTION FORMAT:
 *   1920x1080    <- specific resolution
 *   preferred    <- use monitor's preferred resolution
 *   highres      <- highest available resolution
 *   highrr       <- highest available refresh rate
 * 
 * POSITION FORMAT:
 *   0x0          <- specific position (x,y)
 *   auto         <- automatic positioning
 * 
 * TRANSFORM VALUES:
 *   0 = normal
 *   1 = 90 degrees
 *   2 = 180 degrees
 *   3 = 270 degrees
 *   4 = flipped
 *   5 = flipped + 90
 *   6 = flipped + 180
 *   7 = flipped + 270
 * 
 * VRR (Variable Refresh Rate):
 *   0 = off
 *   1 = on
 *   2 = fullscreen only
 * 
 * ============================================================================
 *                         BRIGHTNESS COMMANDS
 * ============================================================================
 * 
 * brightnessctl g              <- Get current brightness
 * brightnessctl m              <- Get max brightness
 * brightnessctl s 50%          <- Set to 50%
 * brightnessctl s +10%         <- Increase by 10%
 * brightnessctl s 10%-         <- Decrease by 10%
 * 
 * ============================================================================
 */

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/*
 * ============================================================================
 *                          QTOBJECT SINGLETON
 * ============================================================================
 */
QtObject {
    id: root
    
    // ========================================================================
    //                     STATE PROPERTIES
    // ========================================================================
    
    // Current screen brightness (0-100)
    property int brightness: 100
    
    // List of connected monitors
    // Each: { name: string, width: int, height: int, refreshRate: float, x: int, y: int, scale: float }
    property var monitors: []
    
    // Is night light (warm color temperature) enabled?
    property bool nightLightEnabled: false
    
    // ========================================================================
    //                     REFRESH FUNCTION
    // ========================================================================
    function refresh() {
        getBrightnessProc.running = true
        getMonitorsProc.running = true
    }
    
    // ========================================================================
    //                     BRIGHTNESS FUNCTIONS
    // ========================================================================
    
    // Timer to debounce brightness commands
    property var brightnessDebounceTimer: Timer {
        interval: 100
        onTriggered: setBrightnessProc.running = true
    }
    
    // Set screen brightness (0-100)
    function setBrightness(value) {
        root.brightness = value
        setBrightnessProc.targetBrightness = value
        brightnessDebounceTimer.restart()
    }
    
    // Enable warm color temperature (reduce blue light)
    function enableNightLight() {
        root.nightLightEnabled = true
        enableNightLightProc.running = true
    }
    
    // Disable night light (normal colors)
    function disableNightLight() {
        root.nightLightEnabled = false
        disableNightLightProc.running = true
    }
    
    // ========================================================================
    //                     MONITOR FUNCTIONS
    // ========================================================================
    
    // Apply settings to a specific monitor
    function applyMonitorSettings(monitorName, resolution, refreshRate, x, y, scale, transform, enabled, vrr) {
        applyMonitorProc.monitorName = monitorName
        applyMonitorProc.resolution = resolution
        applyMonitorProc.refreshRate = refreshRate
        applyMonitorProc.posX = x
        applyMonitorProc.posY = y
        applyMonitorProc.scale = scale
        applyMonitorProc.transform = transform
        applyMonitorProc.enabled = enabled
        applyMonitorProc.vrr = vrr
        applyMonitorProc.running = true
    }
    
    // ========================================================================
    //                     PROCESSES
    // ========================================================================
    
    // Get current brightness level
    property var getBrightnessProc: Process {
        command: ["brightnessctl", "g"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                let current = parseInt(this.text.trim())
                getMaxBrightnessProc.currentBrightness = current
                getMaxBrightnessProc.running = true
            }
        }
    }
    
    // Get maximum brightness (to calculate percentage)
    property var getMaxBrightnessProc: Process {
        property int currentBrightness: 0
        command: ["brightnessctl", "m"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                let max = parseInt(this.text.trim())
                if (max > 0) {
                    root.brightness = Math.round((getMaxBrightnessProc.currentBrightness / max) * 100)
                }
            }
        }
    }
    
    property var setBrightnessProc: Process {
        property int targetBrightness: 100
        command: ["brightnessctl", "set", targetBrightness + "%"]
    }
    
    property var enableNightLightProc: Process {
        command: ["sh", "-c", "pkill hyprsunset; hyprsunset -t 4500 &"]
    }
    
    property var disableNightLightProc: Process {
        command: ["pkill", "hyprsunset"]
    }
    
    property var getMonitorsProc: Process {
        command: ["hyprctl", "monitors", "-j"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text)
                    let monitors = data.map(mon => ({
                        name: mon.name,
                        description: mon.description || "",
                        make: mon.make || "",
                        model: mon.model || "",
                        serial: mon.serial || "",
                        width: mon.width,
                        height: mon.height,
                        refreshRate: mon.refreshRate,
                        x: mon.x,
                        y: mon.y,
                        scale: mon.scale,
                        transform: mon.transform,
                        focused: mon.focused,
                        dpmsStatus: mon.dpmsStatus,
                        vrr: mon.vrr,
                        disabled: mon.disabled || false,
                        availableModes: mon.availableModes || []
                    }))
                    root.monitors = monitors
                } catch(e) {
                    console.log("DisplayHandler: Failed to parse monitors:", e)
                    root.monitors = []
                }
            }
        }
    }
    
    property var applyMonitorProc: Process {
        property string monitorName: ""
        property string resolution: ""
        property real refreshRate: 60.0
        property int posX: 0
        property int posY: 0
        property real scale: 1.0
        property int transform: 0
        property bool enabled: true
        property string vrr: "off"
        
        command: {
            if (!enabled) {
                return ["hyprctl", "keyword", "monitor", monitorName + ",disable"]
            }
            
            var configStr = monitorName + "," + 
                            resolution + "@" + refreshRate.toFixed(2) + "," +
                            posX + "x" + posY + "," +
                            scale.toFixed(2)
            
            if (transform !== 0) {
                configStr += ",transform," + transform
            }
            
            if (vrr !== "off") {
                configStr += ",vrr," + (vrr === "on" ? "1" : "2")
            }
            
            return ["hyprctl", "keyword", "monitor", configStr]
        }
        
        onExited: getMonitorsProc.running = true
    }
}
