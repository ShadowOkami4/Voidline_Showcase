/*
 * ============================================================================
 *                            SHELL STATE
 * ============================================================================
 * 
 * FILE: misc/ShellState.qml
 * PURPOSE: Global state management singleton for the entire shell
 * 
 * ============================================================================
 *                              OVERVIEW
 * ============================================================================
 * 
 * This singleton manages the global state of the shell, primarily:
 *   - Which panels are currently visible
 *   - Functions to toggle panel visibility
 *   - Ensures only one panel is open at a time
 * 
 * Think of this as a simple "state machine" for the shell.
 * 
 * ============================================================================
 *                         HOW IT WORKS
 * ============================================================================
 * 
 * 1. VISIBILITY PROPERTIES:
 *    - launcherVisible: Is the app launcher panel open?
 *    - networkPanelVisible: Is the network settings panel open?
 *    - soundPanelVisible: Is the sound control panel open?
 * 
 * 2. TOGGLE FUNCTIONS:
 *    - toggleLauncher(), toggleNetworkPanel(), toggleSoundPanel()
 *    - These toggle the respective panel visibility
 *    - They also close any other open panel (mutual exclusion)
 * 
 * 3. MUTUAL EXCLUSION:
 *    - closeAll() closes all panels
 *    - Each toggle function calls closeAll() first
 *    - This ensures only one panel is open at a time
 *    - Creates a clean, focused user experience
 * 
 * 4. REACTIVE BINDINGS:
 *    - Other components bind to these properties
 *    - Example: visible: ShellState.launcherVisible
 *    - When the property changes, the binding updates automatically
 *    - This is the core of QML's reactive programming model
 * 
 * ============================================================================
 *                         USAGE EXAMPLES
 * ============================================================================
 * 
 * In a panel file:
 *   visible: ShellState.launcherVisible
 * 
 * In a button click handler:
 *   onClicked: ShellState.toggleLauncher()
 * 
 * In a keyboard shortcut:
 *   onPressed: ShellState.toggleLauncher()
 * 
 * Watching for changes:
 *   Connections {
 *       target: ShellState
 *       function onLauncherVisibleChanged() {
 *           console.log("Launcher visibility:", ShellState.launcherVisible)
 *       }
 *   }
 * 
 * ============================================================================
 *                         EXTENDING STATE
 * ============================================================================
 * 
 * To add a new panel:
 * 
 * 1. Add a visibility property:
 *    property bool myPanelVisible: false
 * 
 * 2. Add to closeAll():
 *    myPanelVisible = false
 * 
 * 3. Add a toggle function:
 *    function toggleMyPanel() {
 *        let wasVisible = myPanelVisible
 *        closeAll()
 *        myPanelVisible = !wasVisible
 *    }
 * 
 * ============================================================================
 */

pragma Singleton

import Quickshell
import QtQuick

/*
 * ============================================================================
 *                          SINGLETON DEFINITION
 * ============================================================================
 */
Singleton {
    id: root
    
    /*
     * ========================================================================
     *                     VISIBILITY PROPERTIES
     * ========================================================================
     * 
     * These control which panels are visible.
     * Unlike Config properties, these are NOT readonly because we
     * need to change them at runtime.
     */
    
    // App launcher popup visibility
    // Toggled by: Launcher button in bar, Super+Space shortcut
    property bool launcherVisible: false
    
    // Network settings panel visibility
    // Toggled by: WiFi icon in system indicators
    property bool networkPanelVisible: false
    
    // Sound control panel visibility
    // Toggled by: Volume icon in system indicators
    property bool soundPanelVisible: false
    
    // Bluetooth panel visibility
    // Toggled by: Bluetooth icon in system indicators
    property bool bluetoothPanelVisible: false
    
    // Settings panel visibility (full DE settings window)
    // Toggled by: Settings button in sound panel or other locations
    property bool settingsPanelVisible: false
    
    // Settings panel page to navigate to when opening
    property string settingsInitialPage: ""
    
    // Power menu visibility
    // Toggled by: Power button in system indicators
    property bool powerMenuVisible: false
    
    // Tab menu visibility (window overview)
    // Toggled by: Super+Tab or overview button
    // Shows all windows across workspaces for visual management
    property bool tabMenuOpen: false
    
    // Keybinds cheatsheet visibility
    // Toggled by: Super+/ or keybinds button
    // Shows all Hyprland keybinds in a searchable overlay
    property bool cheatsheetVisible: false
    
    // Media panel visibility
    // Toggled by: clicking media indicator in bar
    // Shows full media controls with album art and cava visualization
    property bool mediaPanelVisible: false
    
    // Action Center visibility
    // Toggled by: clicking system indicators in bar (replaces separate sound/network/bluetooth panels)
    // Shows unified controls panel with quick toggles, volume, network, bluetooth, and notifications
    property bool actionCenterVisible: false
    
    // Lock screen visibility
    // Toggled by: Super+L or lock button in power menu
    // Shows fullscreen lock requiring password to unlock
    property bool lockScreenVisible: false

    /*
     * ========================================================================
     *                     CLOSE ALL PANELS
     * ========================================================================
     * 
     * Utility function to close all panels at once.
     * Called at the start of each toggle function to ensure
     * only one panel is open at a time.
     * 
     * Add new panel properties here when extending.
     */
    function closeAll() {
        launcherVisible = false
        networkPanelVisible = false
        soundPanelVisible = false
        bluetoothPanelVisible = false
        settingsPanelVisible = false
        powerMenuVisible = false
        tabMenuOpen = false
        cheatsheetVisible = false
        mediaPanelVisible = false
        actionCenterVisible = false
    }
    
    // Close popups but keep settings panel open
    function closePopups() {
        launcherVisible = false
        networkPanelVisible = false
        soundPanelVisible = false
        bluetoothPanelVisible = false
        powerMenuVisible = false
        tabMenuOpen = false
        cheatsheetVisible = false
        mediaPanelVisible = false
        actionCenterVisible = false
    }
    
    /*
     * ========================================================================
     *                     TOGGLE FUNCTIONS
     * ========================================================================
     * 
     * Each function:
     * 1. Saves the current state (was it already visible?)
     * 2. Closes all panels
     * 3. Sets this panel to the opposite of what it was
     * 
     * This logic handles both opening (when closed) and closing (when open).
     */
    
    /*
     * Toggle app launcher visibility.
     * 
     * If launcher is closed: close other panels, open launcher
     * If launcher is open: close all panels (including launcher)
     */
    function toggleLauncher() {
        let wasVisible = launcherVisible  // Save current state
        closePopups()                      // Close popups but keep settings
        launcherVisible = !wasVisible      // Toggle (if was true, now false)
    }
    
    /*
     * Toggle network panel visibility.
     */
    function toggleNetworkPanel() {
        let wasVisible = networkPanelVisible
        closePopups()
        networkPanelVisible = !wasVisible
    }
    
    /*
     * Toggle sound panel visibility.
     */
    function toggleSoundPanel() {
        let wasVisible = soundPanelVisible
        closePopups()
        soundPanelVisible = !wasVisible
    }
    
    /*
     * Toggle Bluetooth panel visibility.
     */
    function toggleBluetoothPanel() {
        let wasVisible = bluetoothPanelVisible
        closePopups()
        bluetoothPanelVisible = !wasVisible
    }
    
    /*
     * Toggle settings panel visibility.
     */
    function toggleSettingsPanel() {
        let wasVisible = settingsPanelVisible
        closePopups()  // Only close popups, not settings itself
        settingsPanelVisible = !wasVisible
    }
    
    /*
     * Toggle media panel visibility.
     */
    function toggleMediaPanel() {
        let wasVisible = mediaPanelVisible
        closePopups()
        mediaPanelVisible = !wasVisible
    }
    
    /*
     * Toggle action center visibility.
     * The Action Center combines Sound, Network, Bluetooth controls and notifications.
     */
    function toggleActionCenter() {
        let wasVisible = actionCenterVisible
        closePopups()
        actionCenterVisible = !wasVisible
    }
    
    /*
     * Open settings panel and navigate to a specific page.
     * 
     * @param page - The page to navigate to: "sound", "network", "display", "appearance", "about"
     */
    function openSettings(page) {
        closePopups()  // Close popups but keep settings
        settingsInitialPage = page || ""
        settingsPanelVisible = true
    }
    
    /*
     * Toggle power menu visibility.
     */
    function togglePowerMenu() {
        let wasVisible = powerMenuVisible
        closePopups()
        powerMenuVisible = !wasVisible
    }
    
    /*
     * Toggle tab menu visibility.
     * Shows all windows across all workspaces for visual management.
     * Allows clicking to focus, middle-click to close, drag to move.
     */
    function toggleTabMenu() {
        let wasVisible = tabMenuOpen
        closePopups()
        tabMenuOpen = !wasVisible
    }
    
    /*
     * Toggle keybinds cheatsheet visibility.
     * Shows all Hyprland keybinds from config in a searchable overlay.
     */
    function toggleCheatsheet() {
        let wasVisible = cheatsheetVisible
        closePopups()
        cheatsheetVisible = !wasVisible
    }
    
    /*
     * Lock the screen.
     * Shows fullscreen lock overlay requiring password to unlock.
     * Note: This only sets visible to true - unlocking is handled in LockScreen.qml
     */
    function lockScreen() {
        closeAll()
        lockScreenVisible = true
    }
}
