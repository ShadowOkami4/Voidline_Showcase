/*
 * ============================================================================
 *                           APP LAUNCHER
 * ============================================================================
 * 
 * FILE: panels/AppLauncher.qml
 * PURPOSE: Application launcher popup with search and wallpaper tabs
 * 
 * ============================================================================
 *                              OVERVIEW
 * ============================================================================
 * 
 * Features:
 *   - Two tabs: Apps and Wallpaper
 *   - Grid view of installed applications
 *   - Wallpaper gallery from ~/.background
 *   - Real-time search filtering
 *   - Full arrow key navigation (Up/Down/Left/Right)
 *   - Tab key to switch between tabs
 *   - Click outside to close
 * 
 * ============================================================================
 */

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

import "../misc"

PopupWindow {
    id: launcher
    
    // Parent window to anchor to (set by Bar.qml)
    property var parentBar
    
    // Track open state separately from visibility for exit animations
    property bool isOpen: ShellState.launcherVisible
    property bool isClosing: false
    
    // Position relative to parent bar
    anchor.window: parentBar
    anchor.rect.x: (parentBar?.width ?? 0) / 2 - implicitWidth / 2
    anchor.rect.y: Config.barHeight + Config.topMargin + 8
    
    // Popup dimensions
    implicitWidth: 560
    implicitHeight: 520
    
    // Stay visible during close animation
    visible: isOpen || isClosing
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
        onTriggered: launcher.isClosing = false
    }
    
    // ========================================================================
    //                     STATE PROPERTIES
    // ========================================================================
    
    property int currentTab: 0           // 0 = Apps, 1 = Wallpaper
    property string filterText: ""       // Current search text
    property int selectedIndex: 0        // Currently highlighted item index
    property var filteredApps: []        // Apps matching search filter
    property var filteredWallpapers: []  // Wallpapers matching search filter
    property int columnsCount: 5         // Number of columns in grid
    
    // Terminal emulator for terminal apps
    property string terminalCommand: "gostty"
    
    // Wallpaper list from ~/.background
    property var wallpaperList: []
    property string backgroundFolder: Quickshell.env("HOME") + "/.background"

    onWallpaperListChanged: updateFilters()
    
    // ========================================================================
    //                     WALLPAPER LOADING
    // ========================================================================
    
    Process {
        id: listWallpapersProcess
        command: ["bash", "-c", "find " + launcher.backgroundFolder + " -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \\) 2>/dev/null | sort"]
        running: ShellState.launcherVisible
        stdout: StdioCollector {
            onStreamFinished: {
                let output = this.text.trim()
                if (output) {
                    launcher.wallpaperList = output.split("\n").filter(p => p.length > 0)
                } else {
                    launcher.wallpaperList = []
                }
            }
        }
    }
    
    Process {
        id: applyColorsProcess
        command: ["bash", "-c", Qt.resolvedUrl("../scripts/apply-colors.sh").toString().replace("file://", "") + " \"" + Config.wallpaperPath + "\""]
    }
    
    function selectWallpaper(path) {
        Config.wallpaperPath = path
        if (Config.dynamicColors) {
            applyColorsProcess.running = true
        }
        ShellState.launcherVisible = false
    }
    
    // ========================================================================
    //                     FOCUS GRAB
    // ========================================================================
    
    HyprlandFocusGrab {
        windows: [launcher]
        active: ShellState.launcherVisible
        onCleared: ShellState.launcherVisible = false
    }
    
    // ========================================================================
    //                     LAUNCH FUNCTION
    // ========================================================================
    
    function launchApp(app) {
        if (!app) return
        
        let needsTerminal = app.runInTerminal === true
        
        if (needsTerminal) {
            let cmd = app.command || []
            if (cmd.length > 0) {
                let termCmd = [terminalCommand, "-e"].concat(cmd)
                Quickshell.execDetached({
                    command: termCmd,
                    workingDirectory: app.workingDirectory || ""
                })
            }
        } else {
            app.execute()
        }
        
        ShellState.launcherVisible = false
        searchField.text = ""
    }
    
    // ========================================================================
    //                     FILTER LOGIC
    // ========================================================================
    
    onFilterTextChanged: {
        updateFilters()
        selectedIndex = 0
    }
    
    function updateFilters() {
        let search = filterText.toLowerCase()

        // 1. Filter Apps
        let apps = DesktopEntries.applications.values
        if (!filterText) {
            filteredApps = apps.slice().sort((a, b) => {
                let nameA = (a.name || "").toLowerCase()
                let nameB = (b.name || "").toLowerCase()
                return nameA.localeCompare(nameB)
            })
        } else {
            filteredApps = apps.filter(app => {
                let name = (app.name || "").toLowerCase()
                let genericName = (app.genericName || "").toLowerCase()
                let keywords = (app.keywords || []).join(" ").toLowerCase()
                let comment = (app.comment || "").toLowerCase()
                return name.includes(search) || 
                       genericName.includes(search) ||
                       keywords.includes(search) ||
                       comment.includes(search)
            }).sort((a, b) => {
                let nameA = (a.name || "").toLowerCase()
                let nameB = (b.name || "").toLowerCase()
                let aStarts = nameA.startsWith(search)
                let bStarts = nameB.startsWith(search)
                if (aStarts && !bStarts) return -1
                if (!aStarts && bStarts) return 1
                return nameA.localeCompare(nameB)
            })
        }

        // 2. Filter Wallpapers
        if (!filterText) {
            filteredWallpapers = wallpaperList
        } else {
            filteredWallpapers = wallpaperList.filter(path => {
                let filename = path.split("/").pop().toLowerCase()
                return filename.includes(search)
            })
        }
    }
    
    Component.onCompleted: updateFilters()
    
    // ========================================================================
    //                     NAVIGATION HELPERS
    // ========================================================================
    
    function getCurrentItemCount() {
        return currentTab === 0 ? filteredApps.length : filteredWallpapers.length
    }
    
    function getColumnsForCurrentTab() {
        return currentTab === 0 ? columnsCount : 3
    }
    
    function navigateUp() {
        let count = getCurrentItemCount()
        let cols = getColumnsForCurrentTab()
        if (count === 0) return
        
        if (selectedIndex >= cols) {
            selectedIndex -= cols
        } else {
            selectedIndex = 0
        }
        positionGrid()
    }
    
    function navigateDown() {
        let count = getCurrentItemCount()
        let cols = getColumnsForCurrentTab()
        if (count === 0) return
        
        if (selectedIndex + cols < count) {
            selectedIndex += cols
        } else {
            selectedIndex = count - 1
        }
        positionGrid()
    }
    
    function navigateLeft() {
        let count = getCurrentItemCount()
        if (count === 0) return
        
        if (selectedIndex > 0) {
            selectedIndex--
        }
        positionGrid()
    }
    
    function navigateRight() {
        let count = getCurrentItemCount()
        if (count === 0) return
        
        if (selectedIndex < count - 1) {
            selectedIndex++
        }
        positionGrid()
    }
    
    function positionGrid() {
        if (currentTab === 0) {
            appGrid.positionViewAtIndex(selectedIndex, GridView.Contain)
        } else {
            wallpaperGrid.positionViewAtIndex(selectedIndex, GridView.Contain)
        }
    }
    
    function activateSelected() {
        if (currentTab === 0) {
            if (filteredApps.length > 0 && selectedIndex < filteredApps.length) {
                launchApp(filteredApps[selectedIndex])
            }
        } else {
            if (filteredWallpapers.length > 0 && selectedIndex < filteredWallpapers.length) {
                selectWallpaper(filteredWallpapers[selectedIndex])
            }
        }
    }
    
    function switchTab() {
        currentTab = currentTab === 0 ? 1 : 0
        selectedIndex = 0
    }
    
    // ========================================================================
    //               MAIN CONTAINER (Polished Glass)
    // ========================================================================
    
    Rectangle {
        id: container
        anchors.fill: parent
        radius: Config.panelRadius
        // slightly transparent background for "glass" feel
        color: Qt.rgba(Config.backgroundColor.r, Config.backgroundColor.g, Config.backgroundColor.b, 0.95)
        border.width: 1
        border.color: Config.borderColor
        clip: true
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: false
        }
        
        opacity: launcher.isOpen ? 1 : 0
        scale: launcher.isOpen ? 1 : 0.9
        transformOrigin: Item.Top
        
        // Polished spring animation
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { 
            NumberAnimation { 
                duration: 400
                easing.type: Easing.OutBack
                easing.overshoot: 1.1
            } 
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Config.padding
            spacing: 16
            
            // ================================================================
            //                  TAB HEADER
            // ================================================================
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                
                // Tab buttons - pill container
                Rectangle {
                    Layout.preferredWidth: tabRow.width + 10
                    Layout.preferredHeight: 44
                    radius: 22
                    color: Config.surfaceColor
                    border.width: 1
                    border.color: Qt.rgba(Config.borderColor.r, Config.borderColor.g, Config.borderColor.b, 0.5)
                    
                    // Sliding Highlight Background
                    Rectangle {
                        id: tabHighlight
                        width: 100
                        height: 36
                        radius: 18
                        color: Config.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                        // Calculate position: 5px padding + index * (100px width + 6px spacing)
                        x: 5 + (launcher.currentTab * 106)
                        
                        Behavior on x { 
                            NumberAnimation { 
                                duration: 300
                                easing.type: Easing.OutBack
                                easing.overshoot: 0.8
                            } 
                        }
                    }
                    
                    Row {
                        id: tabRow
                        anchors.centerIn: parent
                        spacing: 6
                        
                        Repeater {
                            model: [
                                { label: "Apps", icon: "apps" },
                                { label: "Wallpaper", icon: "wallpaper" }
                            ]
                            
                            // Tab Item Container
                            Item {
                                width: 100
                                height: 36
                                
                                // Hover state (only when not selected)
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 18
                                    color: tabMouse.containsMouse && launcher.currentTab !== index ? Config.surfaceColorHover : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    
                                    Text {
                                        text: modelData.icon
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 18
                                        color: launcher.currentTab === index ? Config.onAccent : Config.dimmedColor
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                    
                                    Text {
                                        text: modelData.label
                                        font.family: Config.fontFamily
                                        font.pixelSize: 13
                                        font.weight: launcher.currentTab === index ? Font.DemiBold : Font.Normal
                                        color: launcher.currentTab === index ? Config.onAccent : Config.dimmedColor
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                }
                                
                                MouseArea {
                                    id: tabMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        launcher.currentTab = index
                                        launcher.selectedIndex = 0
                                        searchField.forceActiveFocus()
                                    }
                                }
                            }
                        }
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                // Item count - Reworked to be minimal text
                Text {
                    id: countText
                    text: (launcher.currentTab === 0 
                        ? launcher.filteredApps.length + " apps"
                        : launcher.filteredWallpapers.length + " wallpapers")
                    color: Config.dimmedColor
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    font.family: Config.fontFamily
                    
                    // Subtle background container
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -8
                        radius: 8
                        color: Config.surfaceColor
                        z: -1
                    }
                }
            }
            
            // ================================================================
            //                  SEARCH BAR
            // ================================================================
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                radius: 26
                color: Config.surfaceColor
                
                // Subtle glow when focused
                border.width: searchField.activeFocus ? 2 : 1
                border.color: searchField.activeFocus ? Config.accentColor : Config.borderColor
                
                Behavior on border.width { NumberAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 14
                    
                    Text {
                        text: "search"
                        color: searchField.activeFocus ? Config.accentColor : Config.dimmedColor
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 22
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        
                        color: Config.foregroundColor
                        font.pixelSize: 16
                        font.family: Config.fontFamily
                        verticalAlignment: TextInput.AlignVCenter
                        selectionColor: Config.accentColor
                        selectedTextColor: Config.onAccent
                        
                        Text {
                            anchors.fill: parent
                            text: launcher.currentTab === 0 ? "Search apps..." : "Search wallpapers..."
                            color: Config.dimmedColor
                            font: searchField.font
                            verticalAlignment: Text.AlignVCenter
                            visible: !searchField.text && !searchField.activeFocus
                            opacity: 0.7
                        }
                        
                        onTextChanged: {
                            launcher.filterText = text.toLowerCase()
                        }
                        
                        Keys.onEscapePressed: {
                            if (text.length > 0) {
                                text = ""
                            } else {
                                ShellState.launcherVisible = false
                            }
                        }
                        
                        Keys.onReturnPressed: launcher.activateSelected()
                        Keys.onUpPressed: launcher.navigateUp()
                        Keys.onDownPressed: launcher.navigateDown()
                        Keys.onLeftPressed: launcher.navigateLeft()
                        Keys.onRightPressed: launcher.navigateRight()
                        Keys.onTabPressed: launcher.switchTab()
                    }
                    
                    // Clear button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: clearMouse.containsMouse ? Config.surfaceColorActive : "transparent"
                        visible: searchField.text.length > 0
                        
                        scale: clearMouse.pressed ? 0.85 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuart } }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "close"
                            color: clearMouse.containsMouse ? Config.foregroundColor : Config.dimmedColor
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 18
                        }
                        
                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: searchField.text = ""
                        }
                    }
                }
            }
            
            // ================================================================
            //              CONTENT AREA
            // ================================================================
            
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                // Apps Grid
                GridView {
                    id: appGrid
                    anchors.fill: parent
                    visible: launcher.currentTab === 0
                    
                    cellWidth: width / launcher.columnsCount
                    cellHeight: 110
                    clip: true
                    
                    model: launcher.filteredApps
                    
                    // Cascading entry animation
                    populate: Transition {
                        NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 200 }
                        NumberAnimation { properties: "scale"; from: 0.8; to: 1; duration: 200; easing.type: Easing.OutBack }
                    }
                    add: Transition {
                        NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 200 }
                        NumberAnimation { properties: "scale"; from: 0.8; to: 1; duration: 200 }
                    }
                    
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 4
                        contentItem: Rectangle {
                            implicitWidth: 4
                            radius: 2
                            color: Qt.rgba(Config.foregroundColor.r, Config.foregroundColor.g, Config.foregroundColor.b, 0.2)
                        }
                    }
                    
                    delegate: Item {
                        id: appItem
                        width: appGrid.cellWidth
                        height: appGrid.cellHeight
                        
                        required property var modelData
                        required property int index
                        
                        property bool isSelected: index === launcher.selectedIndex
                        property bool isHovered: itemMouse.containsMouse
                        
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 6
                            radius: Config.cardRadius
                            color: appItem.isSelected ? Config.accentColorContainer :
                                   appItem.isHovered ? Config.surfaceColorHover : "transparent"
                            
                            // Subtle border on selection for better contrast
                            border.width: appItem.isSelected ? 1 : 0
                            border.color: Config.accentColor
                            
                            Behavior on color { ColorAnimation { duration: 100 } }
                            
                            // Bounce scale
                            scale: itemMouse.pressed ? 0.95 : 1
                            Behavior on scale { 
                                NumberAnimation { 
                                    duration: 200
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.5
                                } 
                            }
                            
                            ColumnLayout {
                                anchors.centerIn: parent
                                width: parent.width - 16
                                spacing: 8
                                
                                // Icon
                                Image {
                                    id: appIcon
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: 48
                                    Layout.preferredHeight: 48
                                    source: {
                                        let icon = appItem.modelData.icon
                                        if (!icon || icon === "") return ""
                                        if (icon.startsWith("/")) return "file://" + icon
                                        return "image://icon/" + icon
                                    }
                                    sourceSize: Qt.size(64, 64) // Load larger for crispness
                                    smooth: true
                                    mipmap: true
                                    visible: status === Image.Ready
                                    asynchronous: true
                                    cache: true
                                }
                                
                                // Fallback Icon
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "deployed_code"
                                    color: Config.dimmedColor
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 32
                                    visible: appIcon.status !== Image.Ready
                                }
                                
                                Text {
                                    Layout.fillWidth: true
                                    text: appItem.modelData.name || "Unknown"
                                    color: appItem.isSelected ? Config.accentColor : Config.foregroundColor
                                    font.pixelSize: 13
                                    font.family: Config.fontFamily
                                    font.weight: appItem.isSelected ? Font.DemiBold : Font.Normal
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }
                            }
                            
                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: launcher.launchApp(appItem.modelData)
                                onEntered: launcher.selectedIndex = appItem.index
                            }
                        }
                    }
                }
                
                // Wallpaper Grid
                GridView {
                    id: wallpaperGrid
                    anchors.fill: parent
                    visible: launcher.currentTab === 1
                    
                    cellWidth: width / 3
                    cellHeight: 120
                    clip: true
                    
                    model: launcher.filteredWallpapers
                    
                    populate: Transition {
                        NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 200 }
                        NumberAnimation { properties: "y"; from: 20; to: 0; duration: 300; easing.type: Easing.OutQuart }
                    }
                    
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 4
                        contentItem: Rectangle {
                            implicitWidth: 4
                            radius: 2
                            color: Qt.rgba(Config.foregroundColor.r, Config.foregroundColor.g, Config.foregroundColor.b, 0.2)
                        }
                    }
                    
                    delegate: Item {
                        id: wpItem
                        width: wallpaperGrid.cellWidth
                        height: wallpaperGrid.cellHeight
                        
                        required property string modelData
                        required property int index
                        
                        property bool isSelected: index === launcher.selectedIndex
                        property bool isCurrentWallpaper: Config.wallpaperPath === modelData
                        property bool isHovered: wpMouse.containsMouse
                        
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 6
                            radius: 12
                            color: "transparent"
                            clip: true
                            
                            border.width: wpItem.isSelected ? 2 : (wpItem.isCurrentWallpaper ? 2 : 1)
                            border.color: wpItem.isSelected ? Config.accentColor : 
                                         (wpItem.isCurrentWallpaper ? Config.accentColor : 
                                         (wpItem.isHovered ? Config.outlineVariant : Config.borderColor))
                            
                            Behavior on border.color { ColorAnimation { duration: 100 } }
                            
                            Image {
                                anchors.fill: parent
                                anchors.margins: 2
                                source: "file://" + wpItem.modelData
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                sourceSize.width: 300
                                sourceSize.height: 200
                                
                                opacity: status === Image.Ready ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                                
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    saturation: wpItem.isHovered ? 1.0 : 0.9
                                    brightness: wpItem.isHovered ? 0.0 : -0.1
                                }
                            }
                            
                            // Current wallpaper indicator
                            Rectangle {
                                visible: wpItem.isCurrentWallpaper
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 8
                                width: 24
                                height: 24
                                radius: 12
                                color: Config.accentColor
                                border.width: 1
                                border.color: Config.onAccent
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "check"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 16
                                    color: Config.onAccent
                                }
                            }
                            
                            MouseArea {
                                id: wpMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: launcher.selectWallpaper(wpItem.modelData)
                                onEntered: launcher.selectedIndex = wpItem.index
                            }
                        }
                    }
                }
                
                // Empty state for wallpapers
                Rectangle {
                    anchors.centerIn: parent
                    width: 220
                    height: 90
                    radius: 16
                    color: Config.surfaceColor
                    visible: launcher.currentTab === 1 && launcher.filteredWallpapers.length === 0
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "image_not_supported"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 32
                            color: Config.dimmedColor
                        }
                        
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No wallpapers found"
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: Config.foregroundColor
                        }
                        
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "~/.background is empty"
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            color: Config.dimmedColor
                        }
                    }
                }
            }
            
            // ========================================================================
            //                     STATUS FOOTER
            // ========================================================================
            
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                spacing: 24
                
                // Helper for key caps
                component KeyCap: Row {
                    spacing: 8
                    property string key: ""
                    property string label: ""
                    
                    Rectangle {
                        height: 20
                        width: Math.max(20, keyText.contentWidth + 10)
                        radius: 6
                        color: Config.surfaceColorActive
                        anchors.verticalCenter: parent.verticalCenter
                        
                        Text {
                            id: keyText
                            anchors.centerIn: parent
                            text: parent.parent.key
                            color: Config.foregroundColor
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            font.family: Config.fontFamily
                        }
                    }
                    
                    Text {
                        text: parent.label
                        color: Config.dimmedColor
                        font.pixelSize: 12
                        font.family: Config.fontFamily
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Item { Layout.fillWidth: true }
                
                KeyCap { key: "↑↓"; label: "Navigate" }
                KeyCap { key: "↵"; label: "Open" }
                KeyCap { key: "Tab"; label: "Switch" }
                KeyCap { key: "Esc"; label: "Close" }
                
                Item { Layout.fillWidth: true }
            }
        }
    }
    
    // Focus search when opened
    Connections {
        target: ShellState
        function onLauncherVisibleChanged() {
            if (ShellState.launcherVisible) {
                launcher.updateFilters()
                listWallpapersProcess.running = true
                launcher.selectedIndex = 0
                launcher.currentTab = 0
                searchField.text = ""
                searchField.forceActiveFocus()
            }
        }
    }
}
