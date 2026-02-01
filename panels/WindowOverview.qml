/*
 * ============================================================================
 *                         WINDOW OVERVIEW PANEL
 * ============================================================================
 * 
 * FILE: panels/WindowOverview.qml
 * PURPOSE: Visual window management - see all windows across workspaces,
 *          click to focus, drag to move between workspaces
 * 
 * ============================================================================
 *                              OVERVIEW
 * ============================================================================
 * 
 * This panel provides a visual overview of all open windows across all
 * workspaces, similar to Windows Task View or GNOME Activities.
 * 
 * Features:
 *   - Shows all workspaces in a row at the bottom
 *   - Each workspace shows miniature views of its windows
 *   - Click a window to focus it and close the overview
 *   - Click a workspace to switch to it
 *   - Drag windows between workspaces
 *   - Middle-click to close a window
 * 
 * ============================================================================
 *                         HOW IT WORKS
 * ============================================================================
 * 
 * 1. FETCHING WINDOW DATA:
 *    - Uses `hyprctl clients -j` to get JSON list of all windows
 *    - Parses the JSON to extract window info (address, title, class, 
 *      workspace, position, size)
 *    - Refreshes when the panel opens
 * 
 * 2. WORKSPACE VISUALIZATION:
 *    - Groups windows by workspace ID
 *    - Shows each workspace as a card with scaled-down window rectangles
 *    - Current workspace is highlighted
 * 
 * 3. WINDOW ACTIONS:
 *    - Left-click: Focus window and close overview
 *    - Middle-click: Close the window
 *    - Drag to workspace: Move window to that workspace
 * 
 * 4. HYPRLAND COMMANDS USED:
 *    - `focuswindow address:0x...` - Focus a specific window
 *    - `closewindow address:0x...` - Close a specific window
 *    - `movetoworkspacesilent N,address:0x...` - Move window to workspace
 *    - `workspace N` - Switch to workspace
 * 
 * ============================================================================
 *                       DRAG & DROP SYSTEM
 * ============================================================================
 * 
 * We use a simple mouse-based drag system:
 * 
 * 1. MouseArea with drag.target set to the card
 * 2. When drag starts, store the window address being dragged
 * 3. DropArea on each workspace detects when dragged item enters
 * 4. On mouse release, check if over a workspace and move the window
 * 
 * KEY PROPERTIES:
 * - Drag.active: True when item is being dragged
 * - Drag.source: The item being dragged (we set windowAddress on it)
 * - DropArea.containsDrag: True when a dragged item is over this area
 * 
 * ============================================================================
 */

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

// Import our styling config
import "../misc"

/*
 * ============================================================================
 *                          ICON LOOKUP HELPER
 * ============================================================================
 * 
 * To get app icons, we need to map window class names to desktop entries.
 * The window class (e.g., "firefox", "kitty") usually matches the icon name.
 * 
 * We use Quickshell's icon provider: "image://icon/iconname"
 */

/*
 * ============================================================================
 *                          POPUP WINDOW
 * ============================================================================
 * 
 * PopupWindow creates a floating panel anchored to the bar.
 */
PopupWindow {
    id: windowOverview
    
    // Parent bar to anchor to
    property var parentBar
    
    // Track open state separately from visibility for exit animations
    property bool isOpen: ShellState.windowOverviewOpen
    property bool isClosing: false
    
    // Position relative to parent bar - centered, below bar
    anchor.window: parentBar
    anchor.rect.x: (parentBar?.width ?? 1920) / 2 - implicitWidth / 2
    anchor.rect.y: Config.barHeight + Config.topMargin + 8
    
    // Popup dimensions - large but not fullscreen
    implicitWidth: 1200
    implicitHeight: 750
    
    // Stay visible during close animation
    visible: isOpen || isClosing
    
    // Transparent - we draw our own background
    color: "transparent"
    
    onIsOpenChanged: {
        if (!isOpen) {
            isClosing = true
            closeTimer.start()
        }
    }
    
    // Timer to hide after close animation
    Timer {
        id: closeTimer
        interval: Config.animSpring
        onTriggered: windowOverview.isClosing = false
    }
    
    // ========================================================================
    //                     WINDOW DATA
    // ========================================================================
    
    // List of all windows from hyprctl
    property var windowList: []
    
    // Grouped by workspace: { 1: [...], 2: [...] }
    property var windowsByWorkspace: ({})
    
    // Currently hovered workspace (for drag feedback)
    property int hoveredWorkspace: -1
    
    // Currently dragged window address
    property string draggedWindowAddress: ""
    
    // ========================================================================
    //                     REFRESH DATA
    // ========================================================================
    
    function refresh() {
        clientsProc.running = true
    }
    
    // Refresh when becoming visible
    onVisibleChanged: {
        if (visible) {
            refresh()
        }
    }
    
    // ========================================================================
    //                     HYPRCTL CLIENTS PROCESS
    // ========================================================================
    
    Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        
        property string output: ""
        
        stdout: SplitParser {
            onRead: data => {
                clientsProc.output += data
            }
        }
        
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && output.length > 0) {
                try {
                    let clients = JSON.parse(output)
                    windowOverview.windowList = clients
                    
                    // Group by workspace
                    let grouped = {}
                    for (let i = 0; i < clients.length; i++) {
                        let client = clients[i]
                        let wsId = client.workspace.id
                        
                        // Skip special workspaces (negative IDs)
                        if (wsId < 1) continue
                        
                        if (!grouped[wsId]) {
                            grouped[wsId] = []
                        }
                        grouped[wsId].push(client)
                    }
                    
                    windowOverview.windowsByWorkspace = grouped
                    console.log("WindowOverview: Loaded", clients.length, "windows")
                } catch (e) {
                    console.log("WindowOverview: JSON parse error:", e)
                }
            }
            output = ""
        }
    }
    
    // ========================================================================
    //                     WINDOW ACTIONS
    // ========================================================================
    
    function focusWindow(address) {
        Hyprland.dispatch("focuswindow address:" + address)
        ShellState.windowOverviewOpen = false
    }
    
    function closeWindow(address) {
        Hyprland.dispatch("closewindow address:" + address)
        refreshTimer.restart()
    }
    
    function moveWindowToWorkspace(address, workspaceId) {
        console.log("WindowOverview: Moving", address, "to workspace", workspaceId)
        Hyprland.dispatch("movetoworkspacesilent " + workspaceId + ",address:" + address)
        refreshTimer.restart()
    }
    
    function switchToWorkspace(workspaceId) {
        Hyprland.dispatch("workspace " + workspaceId)
        ShellState.windowOverviewOpen = false
    }
    
    Timer {
        id: refreshTimer
        interval: 150
        onTriggered: windowOverview.refresh()
    }
    
    // ========================================================================
    //                     FOCUS GRAB
    // ========================================================================
    
    HyprlandFocusGrab {
        windows: [windowOverview]
        active: windowOverview.visible
        onCleared: ShellState.windowOverviewOpen = false
    }
    
    // ========================================================================
    //                     MAIN BACKGROUND
    // ========================================================================
    
    Rectangle {
        id: background
        anchors.fill: parent
        radius: Config.panelRadius
        color: Config.backgroundColor
        border.width: 1
        border.color: Config.borderColor
        
        // M3 Expressive animations
        opacity: windowOverview.isOpen ? 1 : 0
        scale: windowOverview.isOpen ? 1 : 0.9
        transformOrigin: Item.Top
        
        Behavior on opacity { NumberAnimation { duration: Config.animNormal; easing.type: Easing.OutCubic } }
        Behavior on scale { 
            NumberAnimation { 
                duration: Config.animSpring
                easing.type: Easing.OutBack
                easing.overshoot: 1.3
            } 
        }
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#50000000"
            shadowBlur: 1.2
            shadowVerticalOffset: 12
            shadowHorizontalOffset: 0
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12
            
            // ================================================================
            //                     HEADER
            // ================================================================
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                Text {
                    text: "search"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 24
                    color: Config.accentColor
                }
                
                Text {
                    text: "Window Overview"
                    font.pixelSize: 18
                    font.weight: Font.Medium
                    color: Config.foregroundColor
                }
                
                Item { Layout.fillWidth: true }
                
                Text {
                    text: "Drag windows to workspaces below"
                    font.pixelSize: 12
                    color: Config.dimmedColor
                }
                
                // Close button
                Rectangle {
                    width: 28
                    height: 28
                    radius: 8
                    color: closeHover.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "close"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 18
                        color: Config.dimmedColor
                    }
                    
                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellState.windowOverviewOpen = false
                    }
                }
            }
            
            // ================================================================
            //                     WINDOWS AREA
            // ================================================================
            
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: Qt.rgba(0, 0, 0, 0.2)
                
                // Windows grid
                GridView {
                    id: windowsGrid
                    anchors {
                        fill: parent
                        margins: 12
                    }
                    
                    cellWidth: 300
                    cellHeight: 220
                    
                    clip: true
                    
                    // Show ALL windows, not just current workspace
                    model: windowOverview.windowList.filter(w => w.workspace.id > 0)
                    
                    delegate: WindowCard {
                        required property var modelData
                        required property int index
                        
                        windowData: modelData
                        
                        onFocusRequested: windowOverview.focusWindow(modelData.address)
                        onCloseRequested: windowOverview.closeWindow(modelData.address)
                        onDragStarted: windowOverview.draggedWindowAddress = modelData.address
                        onDragEnded: {
                            if (windowOverview.hoveredWorkspace > 0) {
                                windowOverview.moveWindowToWorkspace(
                                    modelData.address,
                                    windowOverview.hoveredWorkspace
                                )
                            }
                            windowOverview.draggedWindowAddress = ""
                            windowOverview.hoveredWorkspace = -1
                        }
                    }
                }
                
                // Empty state
                Text {
                    anchors.centerIn: parent
                    visible: windowsGrid.count === 0
                    text: "No windows open"
                    font.pixelSize: 16
                    color: Config.dimmedColor
                }
            }
            
            // ================================================================
            //                     WORKSPACES ROW
            // ================================================================
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 160
                radius: 12
                color: Qt.rgba(1, 1, 1, 0.03)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.06)
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 16
                    
                    // Get unique workspace IDs
                    property var workspaceIds: {
                        let ids = []
                        let activeWs = Hyprland.focusedWorkspace?.id ?? 1
                        
                        // Add active workspace
                        if (ids.indexOf(activeWs) === -1) ids.push(activeWs)
                        
                        // Add workspaces with windows
                        for (let wsId in windowOverview.windowsByWorkspace) {
                            let id = parseInt(wsId)
                            if (ids.indexOf(id) === -1) ids.push(id)
                        }
                        
                        // Sort
                        ids.sort((a, b) => a - b)
                        
                        // Add "new workspace" slot
                        let nextWs = 1
                        while (ids.indexOf(nextWs) !== -1) nextWs++
                        if (nextWs <= 10) ids.push(nextWs)
                        
                        return ids
                    }
                    
                    Repeater {
                        model: parent.workspaceIds
                        
                        delegate: WorkspaceCard {
                            required property int modelData
                            
                            workspaceId: modelData
                            windows: windowOverview.windowsByWorkspace[modelData] ?? []
                            isActive: Hyprland.focusedWorkspace?.id === modelData
                            isDropTarget: windowOverview.hoveredWorkspace === modelData
                            
                            onClicked: windowOverview.switchToWorkspace(modelData)
                            
                            onDropEntered: windowOverview.hoveredWorkspace = modelData
                            onDropExited: {
                                if (windowOverview.hoveredWorkspace === modelData)
                                    windowOverview.hoveredWorkspace = -1
                            }
                        }
                    }
                }
            }
        }
    }
    
    // ========================================================================
    //                     WORKSPACE CARD COMPONENT
    // ========================================================================
    
    component WorkspaceCard: Rectangle {
        id: wsCard
        
        property int workspaceId: 1
        property var windows: []
        property bool isActive: false
        property bool isDropTarget: false
        
        // Get the screen/output for live preview
        // For now, use the first screen (primary monitor)
        property var captureScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        
        signal clicked()
        signal dropEntered()
        signal dropExited()
        
        width: 180
        height: 140
        radius: 10
        clip: true
        
        color: isDropTarget ? Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.3) :
               isActive ? Qt.rgba(1, 1, 1, 0.1) : 
               wsHover.containsMouse ? Qt.rgba(1, 1, 1, 0.06) :
               Qt.rgba(1, 1, 1, 0.02)
        
        border.width: isDropTarget ? 2 : isActive ? 2 : 1
        border.color: isDropTarget ? Config.accentColor :
                      isActive ? Config.accentColor : Qt.rgba(1, 1, 1, 0.08)
        
        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on border.color { ColorAnimation { duration: 100 } }
        
        // Live workspace preview background
        ScreencopyView {
            id: wsPreview
            anchors.fill: parent
            anchors.margins: 1
            // Capture the screen output - only for current workspace
            captureSource: wsCard.isActive && wsCard.captureScreen ? wsCard.captureScreen : null
            live: wsCard.isActive && visible
            opacity: 0.3
            visible: wsCard.isActive && wsCard.windows.length > 0
        }
        
        // Workspace number (top-left)
        Text {
            anchors {
                top: parent.top
                left: parent.left
                margins: 8
            }
            text: windows.length === 0 ? "+" : wsCard.workspaceId.toString()
            font.pixelSize: windows.length === 0 ? 24 : 16
            font.weight: Font.Bold
            color: isActive ? Config.foregroundColor : Config.dimmedColor
            z: 2
        }
        
        // "New" label for empty workspaces
        Text {
            anchors.centerIn: parent
            visible: windows.length === 0
            text: "New"
            font.pixelSize: 12
            color: Config.dimmedColor
            z: 2
        }
        
        // App icons row at bottom
        Row {
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: 8
            }
            spacing: 4
            visible: windows.length > 0
            z: 2
            
            // Helper to get icon for a window
            function getIconSource(win) {
                let cls = (win.class || "").toLowerCase()
                if (!cls) return ""
                // Find desktop entry
                let apps = DesktopEntries.applications.values
                for (let i = 0; i < apps.length; i++) {
                    let app = apps[i]
                    let appId = (app.id || "").toLowerCase().replace(".desktop", "")
                    let wmClass = (app.wmClass || "").toLowerCase()
                    if (appId === cls || wmClass === cls || appId.includes(cls) || cls.includes(appId)) {
                        if (app.icon) {
                            if (app.icon.startsWith("/")) return "file://" + app.icon
                            return "image://icon/" + app.icon
                        }
                    }
                }
                return "image://icon/" + cls
            }
            
            // Show max 3 icons if more than 4 windows, otherwise show all up to 4
            property int maxIcons: windows.length > 4 ? 3 : Math.min(windows.length, 4)
            property int remaining: windows.length - maxIcons
            
            Repeater {
                model: wsCard.windows.slice(0, parent.maxIcons)
                
                delegate: Rectangle {
                    required property var modelData
                    width: 28
                    height: 28
                    radius: 6
                    color: Qt.rgba(0, 0, 0, 0.5)
                    
                    Image {
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        source: parent.parent.getIconSource(modelData)
                        sourceSize: Qt.size(22, 22)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        asynchronous: true
                    }
                }
            }
            
            // +X indicator for remaining apps
            Rectangle {
                visible: parent.remaining > 0
                width: 28
                height: 28
                radius: 6
                color: Qt.rgba(0, 0, 0, 0.5)
                
                Text {
                    anchors.centerIn: parent
                    text: "+" + parent.parent.remaining
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: Config.foregroundColor
                }
            }
        }
        
        // Active indicator bar
        Rectangle {
            visible: isActive
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: 4
            }
            width: 24
            height: 3
            radius: 1.5
            color: Config.accentColor
            z: 1
        }
        
        // Click & hover
        MouseArea {
            id: wsHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: wsCard.clicked()
            z: 2
        }
        
        // Drop area for receiving dragged windows
        DropArea {
            anchors.fill: parent
            keys: ["windowCard"]
            z: 2
            
            onEntered: drag => {
                wsCard.dropEntered()
            }
            
            onExited: {
                wsCard.dropExited()
            }
        }
    }
    
    // ========================================================================
    //                     WINDOW CARD COMPONENT
    // ========================================================================
    
    component WindowCard: Rectangle {
        id: windowCard
        
        property var windowData: ({})
        property string windowAddress: windowData.address ?? ""
        property string windowClass: windowData.class ?? ""
        
        // Try to find a matching toplevel for live preview
        property var matchingToplevel: {
            if (!windowAddress) return null
            // ToplevelManager provides access to all window toplevels
            let toplevels = ToplevelManager.toplevels.values
            for (let i = 0; i < toplevels.length; i++) {
                let tl = toplevels[i]
                // Match by address (Hyprland toplevel has address property)
                if (tl.HyprlandToplevel && tl.HyprlandToplevel.address === windowAddress.replace("0x", "")) {
                    return tl
                }
            }
            return null
        }
        
        // Find the desktop entry for this window to get its icon
        property var desktopEntry: {
            let cls = windowClass.toLowerCase()
            if (!cls || cls === "") return null
            // Search DesktopEntries for matching app
            let apps = DesktopEntries.applications.values
            for (let i = 0; i < apps.length; i++) {
                let app = apps[i]
                // Match by desktop file id, wmclass, or name
                let appId = (app.id || "").toLowerCase().replace(".desktop", "")
                let wmClass = (app.wmClass || "").toLowerCase()
                let name = (app.name || "").toLowerCase()
                if (appId === cls || wmClass === cls || name === cls || 
                    appId.includes(cls) || cls.includes(appId)) {
                    return app
                }
            }
            return null
        }
        
        // Icon source from desktop entry
        property string iconSource: {
            if (desktopEntry && desktopEntry.icon) {
                let icon = desktopEntry.icon
                if (icon.startsWith("/")) return "file://" + icon
                return "image://icon/" + icon
            }
            // Fallback to class name
            let cls = windowClass.toLowerCase()
            if (!cls || cls === "") return ""
            return "image://icon/" + cls
        }
        
        signal focusRequested()
        signal closeRequested()
        signal dragStarted()
        signal dragEnded()
        
        width: 280
        height: 200
        radius: 10
        
        color: cardMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.05)
        border.width: 1
        border.color: windowData.workspace?.id === Hyprland.focusedWorkspace?.id 
            ? Config.accentColor 
            : Qt.rgba(1, 1, 1, 0.08)
        
        Behavior on color { ColorAnimation { duration: 100 } }
        
        // Drag support
        Drag.active: cardMouse.drag.active
        Drag.keys: ["windowCard"]
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2
        
        // Track original position for drag reset
        property real startX: 0
        property real startY: 0
        
        // Close button (top-right corner)
        Rectangle {
            id: closeButton
            anchors {
                top: parent.top
                right: parent.right
                margins: 6
            }
            width: 22
            height: 22
            radius: 11
            color: closeBtn.containsMouse ? Config.errorColor : Qt.rgba(0, 0, 0, 0.5)
            z: 10
            
            Text {
                anchors.centerIn: parent
                text: "×"
                font.pixelSize: 14
                font.weight: Font.Bold
                color: Config.foregroundColor
            }
            
            MouseArea {
                id: closeBtn
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: windowCard.closeRequested()
            }
        }
        
        // Window preview area - fills the whole card
        Rectangle {
            anchors.fill: parent
            radius: 10
            color: Qt.rgba(0, 0, 0, 0.3)
            clip: true
            
            // Live window preview using ScreencopyView
            ScreencopyView {
                id: screencopy
                anchors.fill: parent
                anchors.margins: 2
                // Use the matching toplevel as capture source
                captureSource: windowCard.matchingToplevel
                visible: windowCard.matchingToplevel !== null && live
                live: windowCard.matchingToplevel !== null
            }
            
            // Fallback: Show class name if no live preview
            Text {
                anchors.centerIn: parent
                visible: !screencopy.visible && appIconOverlay.status !== Image.Ready
                text: windowCard.windowData.class ?? "Window"
                font.pixelSize: 14
                font.bold: true
                color: Config.dimmedColor
            }
        }
        
        // App icon overlay - centered on top of preview
        Rectangle {
            anchors.centerIn: parent
            width: 64
            height: 64
            radius: 12
            color: Qt.rgba(0, 0, 0, 0.6)
            visible: appIconOverlay.status === Image.Ready
            z: 5
            
            Image {
                id: appIconOverlay
                anchors.centerIn: parent
                width: 48
                height: 48
                source: windowCard.iconSource
                sourceSize: Qt.size(48, 48)
                fillMode: Image.PreserveAspectFit
                smooth: true
                antialiasing: true
                asynchronous: true
            }
        }
        
        // Main drag/click area
        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            
            drag.target: windowCard
            drag.axis: Drag.XAndYAxis
            
            onPressed: mouse => {
                if (mouse.button === Qt.LeftButton) {
                    windowCard.startX = windowCard.x
                    windowCard.startY = windowCard.y
                    windowCard.dragStarted()
                }
            }
            
            onReleased: mouse => {
                if (mouse.button === Qt.LeftButton) {
                    // Check if it was a drag or just a click
                    let dx = Math.abs(windowCard.x - windowCard.startX)
                    let dy = Math.abs(windowCard.y - windowCard.startY)
                    
                    if (dx < 5 && dy < 5) {
                        // It was a click, not a drag
                        windowCard.focusRequested()
                    } else {
                        // It was a drag
                        windowCard.dragEnded()
                    }
                    
                    // Reset position
                    windowCard.x = windowCard.startX
                    windowCard.y = windowCard.startY
                }
            }
            
            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton) {
                    windowCard.closeRequested()
                }
            }
        }
    }
}
