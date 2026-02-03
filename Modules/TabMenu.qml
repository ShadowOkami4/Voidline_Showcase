/*
 * ============================================================================
 *                              TAB MENU
 * ============================================================================
 * 
 * Visual window management panel - see all windows across workspaces,
 * click to focus, drag to move between workspaces.
 * 
 * ============================================================================
 */

pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import "../misc"

PopupWindow {
    id: root
    
    required property var parentBar
    
    // ========================================================================
    //                              PROPERTIES
    // ========================================================================
    
    property bool isOpen: ShellState.tabMenuOpen
    property bool isClosing: false
    
    property var windowList: []
    property var windowsByWorkspace: ({})
    property int hoveredWorkspace: -1
    property string draggedWindowAddress: ""
    
    // ========================================================================
    //                              WINDOW CONFIG
    // ========================================================================
    
    anchor.window: parentBar
    anchor.rect.x: (parentBar?.width ?? 1920) / 2 - implicitWidth / 2
    anchor.rect.y: Config.barHeight + Config.topMargin + 8
    
    implicitWidth: 1200
    implicitHeight: 750
    
    visible: isOpen || isClosing
    color: "transparent"
    
    onIsOpenChanged: {
        if (!isOpen) {
            isClosing = true
            closeTimer.start()
        }
    }
    
    // ========================================================================
    //                              HELPERS
    // ========================================================================
    
    function refresh(): void {
        clientsProc.running = true
    }
    
    function focusWindow(address: string): void {
        Hyprland.dispatch("focuswindow address:" + address)
        ShellState.tabMenuOpen = false
    }
    
    function closeWindow(address: string): void {
        Hyprland.dispatch("closewindow address:" + address)
        refreshTimer.restart()
    }
    
    function moveWindowToWorkspace(address: string, workspaceId: int): void {
        Hyprland.dispatch("movetoworkspacesilent " + workspaceId + ",address:" + address)
        refreshTimer.restart()
    }
    
    function switchToWorkspace(workspaceId: int): void {
        Hyprland.dispatch("workspace " + workspaceId)
        ShellState.tabMenuOpen = false
    }
    
    function getIconForWindow(win: var): string {
        const cls = (win?.class ?? "").toLowerCase()
        if (!cls) return ""
        
        const apps = DesktopEntries.applications.values
        for (let i = 0; i < apps.length; i++) {
            const app = apps[i]
            const appId = (app.id ?? "").toLowerCase().replace(".desktop", "")
            const wmClass = (app.wmClass ?? "").toLowerCase()
            
            if (appId === cls || wmClass === cls || appId.includes(cls) || cls.includes(appId)) {
                if (app.icon) {
                    return app.icon.startsWith("/") ? "file://" + app.icon : "image://icon/" + app.icon
                }
            }
        }
        return "image://icon/" + cls
    }
    
    onVisibleChanged: { if (visible) refresh() }
    
    // ========================================================================
    //                              TIMERS
    // ========================================================================
    
    Timer {
        id: closeTimer
        interval: Config.animSpring
        onTriggered: root.isClosing = false
    }
    
    Timer {
        id: refreshTimer
        interval: 150
        onTriggered: root.refresh()
    }
    
    // ========================================================================
    //                              PROCESS
    // ========================================================================
    
    Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        
        property string output: ""
        
        stdout: SplitParser {
            onRead: data => { clientsProc.output += data }
        }
        
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && output.length > 0) {
                try {
                    const clients = JSON.parse(output)
                    root.windowList = clients
                    
                    let grouped = {}
                    for (const client of clients) {
                        const wsId = client.workspace?.id ?? -1
                        if (wsId < 1) continue
                        
                        if (!grouped[wsId]) grouped[wsId] = []
                        grouped[wsId].push(client)
                    }
                    root.windowsByWorkspace = grouped
                } catch (e) {
                    console.error("TabMenu: JSON parse error:", e)
                }
            }
            output = ""
        }
    }
    
    // ========================================================================
    //                              FOCUS GRAB
    // ========================================================================
    
    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: ShellState.tabMenuOpen = false
    }
    
    // ========================================================================
    //                              MAIN CONTENT
    // ========================================================================
    
    Rectangle {
        id: container
        anchors.fill: parent
        radius: Config.panelRadius
        color: Qt.rgba(Config.backgroundColor.r, Config.backgroundColor.g, Config.backgroundColor.b, 0.95)
        border.width: 1
        border.color: Config.borderColor
        
        opacity: root.isOpen ? 1 : 0
        scale: root.isOpen ? 1 : 0.9
        transformOrigin: Item.Top
        
        Behavior on opacity { NumberAnimation { duration: Config.animNormal; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Config.animSpring; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#50000000"
            shadowBlur: 1.2
            shadowVerticalOffset: 12
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12
            
            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                Text {
                    text: "grid_view"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 24
                    color: Config.accentColor
                }
                
                Text {
                    text: "Window Overview"
                    font { family: Config.fontFamily; pixelSize: 18; weight: Font.Medium }
                    color: Config.foregroundColor
                }
                
                Item { Layout.fillWidth: true }
                
                Text {
                    text: "Drag windows to workspaces below"
                    font { family: Config.fontFamily; pixelSize: 12 }
                    color: Config.dimmedColor
                }
                
                Rectangle {
                    width: 28; height: 28; radius: 8
                    color: closeHover.containsMouse ? Config.surfaceColorHover : "transparent"
                    
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
                        onClicked: ShellState.tabMenuOpen = false
                    }
                }
            }
            
            // Windows Grid
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: Config.surfaceColor
                
                GridView {
                    id: windowsGrid
                    anchors.fill: parent
                    anchors.margins: 12
                    
                    cellWidth: 300
                    cellHeight: 220
                    clip: true
                    
                    model: root.windowList.filter(w => (w.workspace?.id ?? 0) > 0)
                    
                    delegate: WindowCard {
                        required property var modelData
                        
                        windowData: modelData
                        onFocusRequested: root.focusWindow(modelData.address)
                        onCloseRequested: root.closeWindow(modelData.address)
                        onDragStarted: root.draggedWindowAddress = modelData.address
                        onDragEnded: {
                            if (root.hoveredWorkspace > 0) {
                                root.moveWindowToWorkspace(modelData.address, root.hoveredWorkspace)
                            }
                            root.draggedWindowAddress = ""
                            root.hoveredWorkspace = -1
                        }
                    }
                }
                
                Text {
                    anchors.centerIn: parent
                    visible: windowsGrid.count === 0
                    text: "No windows open"
                    font { family: Config.fontFamily; pixelSize: 16 }
                    color: Config.dimmedColor
                }
            }
            
            // Workspaces Row
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 160
                radius: 12
                color: Config.surfaceColor
                border.width: 1
                border.color: Config.borderColor
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 16
                    
                    property var workspaceIds: {
                        let ids = []
                        const activeWs = Hyprland.focusedWorkspace?.id ?? 1
                        
                        if (!ids.includes(activeWs)) ids.push(activeWs)
                        
                        for (const wsId in root.windowsByWorkspace) {
                            const id = parseInt(wsId)
                            if (!ids.includes(id)) ids.push(id)
                        }
                        
                        ids.sort((a, b) => a - b)
                        
                        let nextWs = 1
                        while (ids.includes(nextWs)) nextWs++
                        if (nextWs <= 10) ids.push(nextWs)
                        
                        return ids
                    }
                    
                    Repeater {
                        model: parent.workspaceIds
                        
                        delegate: WorkspaceCard {
                            required property int modelData
                            
                            workspaceId: modelData
                            windows: root.windowsByWorkspace[modelData] ?? []
                            isActive: Hyprland.focusedWorkspace?.id === modelData
                            isDropTarget: root.hoveredWorkspace === modelData
                            
                            onClicked: root.switchToWorkspace(modelData)
                            onDropEntered: root.hoveredWorkspace = modelData
                            onDropExited: { if (root.hoveredWorkspace === modelData) root.hoveredWorkspace = -1 }
                        }
                    }
                }
            }
        }
    }
    
    // ========================================================================
    //                         WORKSPACE CARD
    // ========================================================================
    
    component WorkspaceCard: Rectangle {
        id: wsCard
        
        property int workspaceId: 1
        property var windows: []
        property bool isActive: false
        property bool isDropTarget: false
        
        signal clicked()
        signal dropEntered()
        signal dropExited()
        
        width: 180; height: 140; radius: 10; clip: true
        
        color: isDropTarget ? Config.accentColorDim :
               isActive ? Config.surfaceColorActive : 
               wsHover.containsMouse ? Config.surfaceColorHover : Config.surfaceColor
        
        border.width: isDropTarget || isActive ? 2 : 1
        border.color: isDropTarget || isActive ? Config.accentColor : Config.borderColor
        
        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on border.color { ColorAnimation { duration: 100 } }
        
        // Workspace number
        Text {
            anchors { top: parent.top; left: parent.left; margins: 8 }
            text: wsCard.windows.length === 0 ? "+" : wsCard.workspaceId.toString()
            font { pixelSize: wsCard.windows.length === 0 ? 24 : 16; weight: Font.Bold }
            color: wsCard.isActive ? Config.foregroundColor : Config.dimmedColor
            z: 2
        }
        
        // "New" label for empty workspaces
        Text {
            anchors.centerIn: parent
            visible: wsCard.windows.length === 0
            text: "New"
            font { family: Config.fontFamily; pixelSize: 12 }
            color: Config.dimmedColor
            z: 2
        }
        
        // App icons row
        Row {
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 8 }
            spacing: 4
            visible: wsCard.windows.length > 0
            z: 2
            
            property int maxIcons: wsCard.windows.length > 4 ? 3 : Math.min(wsCard.windows.length, 4)
            property int remaining: wsCard.windows.length - maxIcons
            
            Repeater {
                model: wsCard.windows.slice(0, parent.maxIcons)
                
                delegate: Rectangle {
                    required property var modelData
                    width: 28; height: 28; radius: 6
                    color: Qt.rgba(0, 0, 0, 0.5)
                    
                    Image {
                        anchors.centerIn: parent
                        width: 22; height: 22
                        source: root.getIconForWindow(modelData)
                        sourceSize: Qt.size(22, 22)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }
                }
            }
            
            Rectangle {
                visible: parent.remaining > 0
                width: 28; height: 28; radius: 6
                color: Qt.rgba(0, 0, 0, 0.5)
                
                Text {
                    anchors.centerIn: parent
                    text: "+" + parent.parent.remaining
                    font { pixelSize: 11; weight: Font.Bold }
                    color: Config.foregroundColor
                }
            }
        }
        
        // Active indicator
        Rectangle {
            visible: wsCard.isActive
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 4 }
            width: 24; height: 3; radius: 1.5
            color: Config.accentColor
            z: 1
        }
        
        MouseArea {
            id: wsHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: wsCard.clicked()
            z: 2
        }
        
        DropArea {
            anchors.fill: parent
            keys: ["windowCard"]
            z: 2
            onEntered: wsCard.dropEntered()
            onExited: wsCard.dropExited()
        }
    }
    
    // ========================================================================
    //                         WINDOW CARD
    // ========================================================================
    
    component WindowCard: Rectangle {
        id: winCard
        
        property var windowData: ({})
        
        readonly property string windowAddress: windowData.address ?? ""
        readonly property string windowClass: windowData.class ?? ""
        
        readonly property string iconSource: root.getIconForWindow(windowData)
        
        signal focusRequested()
        signal closeRequested()
        signal dragStarted()
        signal dragEnded()
        
        width: 280; height: 200; radius: 10
        
        color: cardMouse.containsMouse ? Config.surfaceColorHover : Config.surfaceColor
        border.width: 1
        border.color: (windowData.workspace?.id ?? 0) === (Hyprland.focusedWorkspace?.id ?? 0) 
            ? Config.accentColor : Config.borderColor
        
        Behavior on color { ColorAnimation { duration: 100 } }
        
        Drag.active: cardMouse.drag.active
        Drag.keys: ["windowCard"]
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2
        
        property real startX: 0
        property real startY: 0
        
        // Close button
        Rectangle {
            anchors { top: parent.top; right: parent.right; margins: 6 }
            width: 22; height: 22; radius: 11
            color: closeBtn.containsMouse ? Config.errorColor : Qt.rgba(0, 0, 0, 0.5)
            z: 10
            
            Text {
                anchors.centerIn: parent
                text: "×"
                font { pixelSize: 14; weight: Font.Bold }
                color: Config.foregroundColor
            }
            
            MouseArea {
                id: closeBtn
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: winCard.closeRequested()
            }
        }
        
        // Preview area
        Rectangle {
            anchors.fill: parent
            radius: 10
            color: Qt.rgba(0, 0, 0, 0.3)
            clip: true
            
            Text {
                anchors.centerIn: parent
                visible: appIcon.status !== Image.Ready
                text: winCard.windowClass || "Window"
                font { family: Config.fontFamily; pixelSize: 14; weight: Font.Bold }
                color: Config.dimmedColor
            }
        }
        
        // App icon overlay
        Rectangle {
            anchors.centerIn: parent
            width: 64; height: 64; radius: 12
            color: Qt.rgba(0, 0, 0, 0.6)
            visible: appIcon.status === Image.Ready
            z: 5
            
            Image {
                id: appIcon
                anchors.centerIn: parent
                width: 48; height: 48
                source: winCard.iconSource
                sourceSize: Qt.size(48, 48)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
        }
        
        // Window title
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 6 }
            height: 24
            radius: 6
            color: Qt.rgba(0, 0, 0, 0.6)
            
            Text {
                anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                text: winCard.windowData.title ?? winCard.windowClass
                font { family: Config.fontFamily; pixelSize: 11 }
                color: Config.foregroundColor
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }
        
        // Workspace badge
        Rectangle {
            anchors { top: parent.top; left: parent.left; margins: 6 }
            width: 20; height: 20; radius: 4
            color: Qt.rgba(0, 0, 0, 0.6)
            
            Text {
                anchors.centerIn: parent
                text: winCard.windowData.workspace?.id ?? ""
                font { pixelSize: 10; weight: Font.Bold }
                color: Config.foregroundColor
            }
        }
        
        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            
            drag.target: winCard
            drag.axis: Drag.XAndYAxis
            
            onPressed: mouse => {
                if (mouse.button === Qt.LeftButton) {
                    winCard.startX = winCard.x
                    winCard.startY = winCard.y
                    winCard.dragStarted()
                }
            }
            
            onReleased: mouse => {
                if (mouse.button === Qt.LeftButton) {
                    const dx = Math.abs(winCard.x - winCard.startX)
                    const dy = Math.abs(winCard.y - winCard.startY)
                    
                    if (dx < 5 && dy < 5) {
                        winCard.focusRequested()
                    } else {
                        winCard.dragEnded()
                    }
                    
                    winCard.x = winCard.startX
                    winCard.y = winCard.startY
                }
            }
            
            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton) {
                    winCard.closeRequested()
                }
            }
        }
    }
}
