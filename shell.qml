//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=0
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
/*
 * ============================================================================
 *                            SHELL ENTRY POINT
 * ============================================================================
 *  
 * FILE: shell.qml
 * PURPOSE: Main entry point for the Quickshell desktop environment
 * 
 * ============================================================================
 *                              OVERVIEW
 * ============================================================================
 * 
 * This is the root file that Quickshell loads when starting.
 * It's responsible for:
 * 
 *   1. Setting up global keyboard shortcuts
 *   2. Creating bars on all connected monitors
 *   3. Importing and making available all other components
 * 
 * ============================================================================
 *                         HOW IT WORKS
 * ============================================================================
 * 
 * 1. SCOPE:
 *    - Scope is the root container for a Quickshell configuration
 *    - It doesn't render anything itself
 *    - All visible elements are children of Scope 
 * 
 * 2. GLOBAL SHORTCUTS:
 *    - GlobalShortcut creates Hyprland keybinds
 *    - The 'name' property becomes the bind identifier
 *    - Must be bound in Hyprland config: bind = SUPER, space, global, quickshell:toggleLauncher
 * 
 * 3. MULTI-MONITOR SUPPORT:
 *    - Variants creates multiple instances from a model
 *    - Model is Quickshell.screens (list of all monitors)
 *    - Each monitor gets its own Bar instance
 *    - modelData contains the screen object for that instance
 * 
 * ============================================================================
 *                      HYPRLAND KEYBIND SETUP
 * ============================================================================
 * 
 * For GlobalShortcut to work, you must add the bind to Hyprland config:
 * 
 *   ~/.config/hypr/hyprland.conf:
 *   bind = SUPER, space, global, quickshell:toggleLauncher
 * 
 * Format: bind = MODIFIERS, KEY, global, quickshell:NAME
 * 
 * The NAME must match the 'name' property of GlobalShortcut.
 * 
 * ============================================================================
 *                      FILE STRUCTURE
 * ============================================================================
 * 
 * ~/.config/quickshell/
 * ├── shell.qml          <- YOU ARE HERE (entry point)
 * ├── qmldir             <- Module definition, registers components
 * │
 * ├── misc/              <- Core components
 * │   ├── Config.qml     <- Styling configuration
 * │   ├── ShellState.qml <- Global state management
 * │   └── Bar.qml        <- The floating top bar
 * │
 * ├── panels/            <- Popup panels
 * │   ├── AppLauncher.qml    <- Application launcher
 * │   ├── NetworkPanel.qml   <- WiFi settings
 * │   └── SoundPanel.qml     <- Volume controls
 * │
 * └── indicators/        <- Bar widgets
 *     ├── ClockWidget.qml       <- Time display
 *     ├── WorkspaceIndicator.qml <- Workspace dots
 *     └── SystemIndicators.qml  <- Volume/WiFi/Battery icons
 * 
 * ============================================================================
 *                      STARTING QUICKSHELL
 * ============================================================================
 * 
 * To start Quickshell with this configuration:
 * 
 *   quickshell
 * 
 * Or specify the config directory explicitly:
 * 
 *   quickshell -p ~/.config/quickshell
 * 
 * To run in the background: 
 * 
 *   quickshell &
 * 
 * Add to Hyprland autostart in hyprland.conf:
 * 
 *   exec-once = quickshell
 * 
 * ============================================================================
 */

import Quickshell
import Quickshell.Hyprland    // For GlobalShortcut
import Quickshell.Io          // For Process
import QtQuick

// Import our custom components from the misc folder
// This gives us access to Bar, Config, and ShellState
import "misc"

// Import panels for the standalone Settings window
import "panels"

/*
 * ============================================================================
 *                          SCOPE (ROOT ELEMENT)
 * ============================================================================
 * 
 * Scope is the required root element for Quickshell configurations.
 * It provides the context for all shell components.
 */
Scope {
    id: root
    
    /*
     * ========================================================================
     *                     BLUETOOTH AGENT
     * ========================================================================
     * 
     * Start the Bluetooth pairing agent when Quickshell starts.
     * This agent auto-accepts pairing requests from devices.
     * 
     * Uses start-bt-agent.sh which tries Python agent first, then falls back
     * to bluetoothctl if python-gobject is not installed.
     */
    Process {
        id: bluetoothAgent
        command: ["bash", Qt.resolvedUrl("scripts/start-bt-agent.sh").toString().replace("file://", "")]
        running: true
        
        stdout: SplitParser {
            onRead: data => console.log("[BT Agent]", data.trim())
        }
        stderr: SplitParser {
            onRead: data => console.error("[BT Agent Error]", data.trim())
        }
        
        onExited: (exitCode, exitStatus) => {
            console.log("[Bluetooth Agent] Exited with code:", exitCode)
            // Only restart if unexpected crash (not SIGTERM)
            if (exitCode !== 0 && exitCode !== 143) {
                restartTimer.start()
            }
        }
    }
    
    Timer {
        id: restartTimer
        interval: 5000
        onTriggered: bluetoothAgent.running = true  
    }

    /*
     * ========================================================================
     *                     GLOBAL KEYBOARD SHORTCUTS
     * ========================================================================
     * 
     * GlobalShortcut registers a global keybinding with Hyprland.
     * 
     * Properties:
     *   - name: Identifier used in Hyprland bind (quickshell:NAME)
     *   - description: Human-readable description (for documentation)
     * 
     * Signals:
     *   - onPressed: Called when the shortcut is triggered
     * 
     * IMPORTANT: You must add the bind to Hyprland config!
     * 
     *   ~/.config/hypr/hyprland.conf:
     *   bind = SUPER, space, global, quickshell:toggleLauncher
     */
    GlobalShortcut {
        name: "toggleLauncher"
        description: "Toggle App Launcher"
        
        // Toggle the launcher when shortcut is pressed
        onPressed: ShellState.toggleLauncher()
    }
    
    GlobalShortcut {
        name: "toggleSettings"
        description: "Toggle Settings Panel"
        
        onPressed: ShellState.toggleSettingsPanel()
    }
    
    GlobalShortcut {
        name: "toggleOverview"
        description: "Toggle Window Overview"
        
        onPressed: ShellState.toggleWindowOverview()
    }
    
    GlobalShortcut { 
        name: "toggleCheatsheet"
        description: "Toggle Keybinds Cheatsheet"
        
        onPressed: ShellState.toggleCheatsheet()
    }
    
    GlobalShortcut {
        name: "lockScreen"
        description: "Lock the screen"
        
        onPressed: ShellState.lockScreen()
    }
    
    // ========================================================================
    //                     OSD POPUP
    // ========================================================================
    // Listens to SoundHandler and DisplayHandler for volume/brightness changes
    // Shows a popup whenever these values change (from any source)
    
    OSDPopup {
        id: osdPopup
    }
    
    // ========================================================================
    //                     NOTIFICATION DAEMON
    // ========================================================================
    // Implements freedesktop.org notification specification
    // Shows notifications in top-right corner
    
    NotificationPopup {
        id: notificationPopup
    }
    
    /*
     * You can add more global shortcuts here:
     * 
     * GlobalShortcut {
     *     name: "toggleNetworkPanel"
     *     description: "Toggle Network Panel"
     *     onPressed: ShellState.toggleNetworkPanel()
     * }
     * 
     * Then add to Hyprland config:
     *   bind = SUPER, N, global, quickshell:toggleNetworkPanel
     */

    /*
     * ========================================================================
     *                     MULTI-MONITOR BAR CREATION
     * ========================================================================
     * 
     * Variants creates multiple instances of a component from a model.
     * 
     * Here we use Quickshell.screens as the model, which contains all
     * connected monitors. For each screen, a Bar is created.
     * 
     * The 'required property var modelData' line declares that the Bar
     * expects to receive the screen object from Variants.
     * 
     * Inside Bar, modelData is the screen object, which we assign to
     * the 'screen' property of PanelWindow.
     */
    
    /*
     * ========================================================================
     *                     WALLPAPER (BACKGROUND LAYER)
     * ========================================================================
     * 
     * Create a wallpaper on each screen when wallpaper rendering is enabled.
     * This uses the Background layer to render behind all other windows.
     */
    Variants {
        model: Config.wallpaperEnabled ? Quickshell.screens : []
        
        Wallpaper {
            required property var modelData
            screen: modelData
        }
    }
    
    /*
     * ========================================================================
     *                     BAR (TOP PANEL)
     * ========================================================================
     */
    Variants {
        // Model is the list of all screens/monitors
        model: Quickshell.screens

        /*
         * For each screen, create a Bar instance.
         * 
         * required property var modelData:
         *   - 'required' means this MUST be provided (Variants does this)
         *   - 'modelData' is the conventional name for Variants data
         *   - Contains the screen object for this instance
         * 
         * screen: modelData:
         *   - PanelWindow has a 'screen' property
         *   - Setting it positions the bar on that monitor
         */
        Bar {
            required property var modelData
            screen: modelData
        }
    }
    
    /*
     * ========================================================================
     *                     MEDIA PANEL (Celestia Style)
     * ========================================================================
     * 
     * Uses PanelWindow with layer shell, not PopupWindow.
     * Creates reverse corners that connect to the bar.
     */
    Variants {
        model: Quickshell.screens
        
        MediaPanel {
            required property var modelData
            screen: modelData
        }
    }
    
    /*
     * ========================================================================
     *                     SETTINGS WINDOW
     * ========================================================================
     * 
     * The Settings window is a standalone FloatingWindow that acts like
     * a regular application window. It's not attached to the bar.
     */
    SettingsPanel {}
    
    /*
     * ========================================================================
     *                     LOCK SCREEN
     * ========================================================================
     * 
     * Uses WlSessionLock for proper Wayland session locking.
     * Automatically creates lock surfaces on all monitors.
     * 
     * Bind in Hyprland config:
     *   bind = SUPER, L, global, quickshell:lockScreen
     */
    LockScreen {}
    
    /*
     * NOTE: WindowOverview and MediaPanel are now created inside Bar.qml,
     * just like AppLauncher, NetworkPanel, etc. This allows them to anchor
     * properly to the bar on each screen.
     * 
     * Bind in Hyprland config:
     *   bind = SUPER, Tab, global, quickshell:toggleOverview
     */
}
