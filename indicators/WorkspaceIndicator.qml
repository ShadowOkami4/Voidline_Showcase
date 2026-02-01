/*
 * ============================================================================
 *                        WORKSPACE INDICATOR
 * ============================================================================
 * 
 * FILE: indicators/WorkspaceIndicator.qml
 * PURPOSE: Shows dots representing Hyprland workspaces (clickable to switch)
 * 
 * ============================================================================
 *                              OVERVIEW
 * ============================================================================
 * 
 * This widget displays a row of dots representing workspaces 1-10.
 * Visual states:
 *   - Active workspace: Wide pill shape, full opacity
 *   - Workspace with windows: Circle, medium opacity
 *   - Empty workspace: Small circle, low opacity
 * 
 * Clicking a dot switches to that workspace using Hyprland IPC.
 * 
 * ============================================================================
 *                         HOW IT WORKS
 * ============================================================================
 * 
 * 1. HYPRLAND INTEGRATION:
 *    - Quickshell.Hyprland module provides access to Hyprland's state
 *    - Hyprland.focusedWorkspace: Currently active workspace object
 *    - Hyprland.workspaces: Object containing all workspace objects
 *    - Hyprland.dispatch(): Send commands to Hyprland
 * 
 * 2. WORKSPACE MODEL:
 *    - We use a Repeater with model: 10 to create 10 dots
 *    - Each dot's index property (0-9) maps to workspace ID (1-10)
 *    - We check Hyprland.workspaces to see if each workspace has windows
 * 
 * 3. VISUAL STATES:
 *    - isActive: true if this is the focused workspace
 *    - hasWindows: true if the workspace exists in Hyprland's list
 *      (Hyprland only tracks workspaces that have windows)
 *    - width: 20px when active (pill), 8px otherwise (circle)
 *    - color: White when active, dimmed when has windows, gray when empty
 *    - opacity: Full when active/has windows, 30% when empty
 * 
 * 4. ANIMATIONS:
 *    - Behaviors on width, color, opacity create smooth transitions
 *    - 150ms duration with OutCubic easing for natural feel
 * 
 * 5. SWITCHING WORKSPACES:
 *    - Click triggers: Hyprland.dispatch("workspace N")
 *    - This is the Hyprland IPC command to switch workspaces
 *    - dispatch() sends any Hyprland dispatcher command
 * 
 * ============================================================================
 *                      HYPRLAND DISPATCHER COMMANDS
 * ============================================================================
 * 
 * Hyprland.dispatch() can run any dispatcher command:
 *   - "workspace 3"          - Switch to workspace 3
 *   - "movetoworkspace 5"    - Move focused window to workspace 5
 *   - "togglefloating"       - Toggle floating on focused window
 *   - "fullscreen"           - Toggle fullscreen
 *   - "exec kitty"           - Launch terminal
 * 
 * See Hyprland wiki for full list of dispatchers.
 * 
 * ============================================================================
 */

import Quickshell
import Quickshell.Hyprland    // Provides Hyprland singleton
import QtQuick
import QtQuick.Layouts

// Import configuration singleton from the misc folder
import "../misc"

/*
 * ============================================================================
 *                          MAIN WIDGET
 * ============================================================================
 * 
 * Row arranges children horizontally with spacing.
 * It's simpler than RowLayout when you don't need Layout.* properties.
 */
Row {
    id: workspaceIndicator
    
    // Space between workspace dots
    spacing: 6
    
    /*
     * ========================================================================
     *                          WORKSPACE DOTS
     * ========================================================================
     * 
     * Repeater creates multiple items from a model.
     * With model: 10, it creates items with index 0-9.
     * 
     * Each item is a workspace dot that shows status and handles clicks.
     */
    Repeater {
        // Create 10 workspace indicators (for workspaces 1-10)
        model: 10
        
        /*
         * Delegate: The component created for each model item.
         * This Rectangle represents one workspace dot.
         */
        delegate: Rectangle {
            id: workspaceDot
            
            /*
             * required property: Must be set by the Repeater.
             * 'index' is automatically set to the item's position (0-9).
             */
            required property int index
            
            /*
             * ------------------------------------------------------------
             *                    COMPUTED PROPERTIES
             * ------------------------------------------------------------
             * 
             * These properties compute the workspace state dynamically.
             * They automatically update when Hyprland's state changes.
             */
            
            // Workspace IDs are 1-based, but index is 0-based
            property int workspaceId: index + 1
            
            /*
             * isActive: True if this workspace is currently focused.
             * 
             * Hyprland.focusedWorkspace is the currently active workspace object.
             * We compare its ID to our workspaceId.
             * 
             * The ?. (optional chaining) handles the case where
             * focusedWorkspace might be null during initialization.
             */
            property bool isActive: Hyprland.focusedWorkspace ? (Hyprland.focusedWorkspace.id === workspaceId) : false
            
            /*
             * hasWindows: True if the workspace has any windows.
             * 
             * Hyprland.workspaces is an object with workspace data.
             * Workspaces only exist in this list if they have windows.
             * 
             * We loop through looking for our workspace ID.
             * If found, the workspace has at least one window.
             */
            property bool hasWindows: {
                // Hyprland.workspaces.values gives array of workspace objects
                for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
                    let ws = Hyprland.workspaces.values[i]
                    if (ws.id === workspaceId) {
                        return true
                    }
                }
                return false
            }
            
            /*
             * ------------------------------------------------------------
             *            VISUAL APPEARANCE (M3 Expressive)
             * ------------------------------------------------------------
             * Larger, more colorful indicators with playful animations
             */
            
            // Width: Wide pill when active, medium when has windows, small when empty
            width: isActive ? 32 : (hasWindows ? 14 : 8)
            height: 12
            radius: 6  // Half of height = fully rounded ends
            
            /*
             * M3 Expressive colors - more vibrant
             */
            color: {
                if (isActive) return Config.accentColor
                if (hasWindows) return Config.foregroundColor
                return Config.dimmedColor
            }
            
            // Opacity: Full for active, high for occupied, low for empty
            opacity: isActive ? 1.0 : (hasWindows ? 0.7 : 0.25)
            
            // Scale effect on hover - more playful bounce
            scale: dotMouse.pressed ? 0.85 : (dotMouse.containsMouse ? 1.25 : 1.0)
            
            // Subtle glow for active workspace
            Rectangle {
                visible: isActive
                anchors.centerIn: parent
                width: parent.width + 8
                height: parent.height + 8
                radius: parent.radius + 4
                color: Config.accentColor
                opacity: 0.2
                z: -1
                
                // Pulsing animation for active
                SequentialAnimation on opacity {
                    running: isActive
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 1200; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 0.15; duration: 1200; easing.type: Easing.InOutQuad }
                }
            }
            
            /*
             * ------------------------------------------------------------
             *              ANIMATIONS (M3 Expressive)
             * ------------------------------------------------------------
             * Spring/bounce animations for more playful feel
             */
            Behavior on width {
                NumberAnimation { 
                    duration: Config.animSpring
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }
            }
            
            Behavior on color {
                ColorAnimation { duration: Config.animNormal }
            }
            
            Behavior on opacity {
                NumberAnimation { duration: Config.animNormal }
            }
            
            Behavior on scale {
                NumberAnimation { 
                    duration: 200
                    easing.type: Easing.OutBack
                    easing.overshoot: 2.0
                }
            }
            
            /*
             * ------------------------------------------------------------
             *                    CLICK HANDLER
             * ------------------------------------------------------------
             */
            MouseArea {
                id: dotMouse
                anchors.fill: parent
                anchors.margins: -4  // Larger touch target
                hoverEnabled: true
                
                // Show pointer cursor to indicate clickability
                cursorShape: Qt.PointingHandCursor
                
                onClicked: {
                    /*
                     * Hyprland.dispatch() sends a command to Hyprland.
                     * 
                     * "workspace N" is the Hyprland dispatcher command
                     * to switch to workspace N.
                     */
                    Hyprland.dispatch("workspace " + workspaceDot.workspaceId)
                }
            }
        }
    }
}