/*
 * ============================================================================
 *                          PERSONALIZE SETTINGS
 * ============================================================================
 *
 * FILE: settings/PersonalizePage.qml
 * PURPOSE: UI for personalization options (wallpaper, themes, colors)
 *
 * OVERVIEW:
 *   - Lets the user change wallpaper, choose color schemes, and profile images.
 *   - Hooks into `scripts/colorgen.py` and `apply-colors.sh` for dynamic
 *     color generation from wallpaper.
 *   - Updates values stored in the central `settings.json` managed by Config.
 *
 * NOTE: This page is UI-only; persistent changes are saved through Config.
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../misc"

Item {
    id: root
    
    // ========================================================================
    //                     CURRENT SETTINGS STATE
    // ========================================================================
    
    property string defaultTerminal: HyprlandConfig.terminal || "kitty"
    property string defaultFileManager: HyprlandConfig.fileManager || "nautilus"
    property string defaultBrowser: HyprlandConfig.browser || "firefox"
    property string barStyle: Config.barStyle
    property bool barAutoHide: Config.barAutoHide
    property int gapsIn: HyprlandConfig.windowGaps
    property int gapsOut: HyprlandConfig.screenGaps
    property int borderSize: HyprlandConfig.borderSize
    property string layout: HyprlandConfig.layoutMode
    property int rounding: HyprlandConfig.rounding
    property real roundingPower: HyprlandConfig.roundingPower
    property real activeOpacity: HyprlandConfig.activeOpacity
    property real inactiveOpacity: HyprlandConfig.inactiveOpacity
    property bool blurEnabled: HyprlandConfig.blurEnabled
    property int blurSize: HyprlandConfig.blurSize
    property int blurPasses: HyprlandConfig.blurPasses
    property bool shadowEnabled: HyprlandConfig.shadowEnabled
    property bool dimInactive: HyprlandConfig.dimInactive
    property string activeColor: HyprlandConfig.activeColor
    property string inactiveColor: HyprlandConfig.inactiveColor
    property bool borderResize: HyprlandConfig.borderResize
    
    // Two-way bindings
    onDefaultTerminalChanged: if (defaultTerminal !== HyprlandConfig.terminal) HyprlandConfig.terminal = defaultTerminal
    onDefaultFileManagerChanged: if (defaultFileManager !== HyprlandConfig.fileManager) HyprlandConfig.fileManager = defaultFileManager
    onDefaultBrowserChanged: if (defaultBrowser !== HyprlandConfig.browser) HyprlandConfig.browser = defaultBrowser
    onGapsInChanged: if (gapsIn !== HyprlandConfig.windowGaps) HyprlandConfig.windowGaps = gapsIn
    onGapsOutChanged: if (gapsOut !== HyprlandConfig.screenGaps) HyprlandConfig.screenGaps = gapsOut
    onBorderSizeChanged: if (borderSize !== HyprlandConfig.borderSize) HyprlandConfig.borderSize = borderSize
    onLayoutChanged: if (layout !== HyprlandConfig.layoutMode) HyprlandConfig.layoutMode = layout
    onRoundingChanged: if (rounding !== HyprlandConfig.rounding) HyprlandConfig.rounding = rounding
    onRoundingPowerChanged: if (roundingPower !== HyprlandConfig.roundingPower) HyprlandConfig.roundingPower = roundingPower
    onActiveOpacityChanged: if (activeOpacity !== HyprlandConfig.activeOpacity) HyprlandConfig.activeOpacity = activeOpacity
    onInactiveOpacityChanged: if (inactiveOpacity !== HyprlandConfig.inactiveOpacity) HyprlandConfig.inactiveOpacity = inactiveOpacity
    onBlurEnabledChanged: if (blurEnabled !== HyprlandConfig.blurEnabled) HyprlandConfig.blurEnabled = blurEnabled
    onBlurSizeChanged: if (blurSize !== HyprlandConfig.blurSize) HyprlandConfig.blurSize = blurSize
    onBlurPassesChanged: if (blurPasses !== HyprlandConfig.blurPasses) HyprlandConfig.blurPasses = blurPasses
    onShadowEnabledChanged: if (shadowEnabled !== HyprlandConfig.shadowEnabled) HyprlandConfig.shadowEnabled = shadowEnabled
    onDimInactiveChanged: if (dimInactive !== HyprlandConfig.dimInactive) HyprlandConfig.dimInactive = dimInactive
    onActiveColorChanged: if (activeColor !== HyprlandConfig.activeColor) HyprlandConfig.activeColor = activeColor
    onInactiveColorChanged: if (inactiveColor !== HyprlandConfig.inactiveColor) HyprlandConfig.inactiveColor = inactiveColor
    onBorderResizeChanged: if (borderResize !== HyprlandConfig.borderResize) HyprlandConfig.borderResize = borderResize
    onBarStyleChanged: if (barStyle !== Config.barStyle) Config.barStyle = barStyle
    onBarAutoHideChanged: if (barAutoHide !== Config.barAutoHide) Config.barAutoHide = barAutoHide
    
    // ========================================================================
    //                          MD3 COMPONENTS
    // ========================================================================
    
    component MD3Card: Rectangle {
        default property alias content: cardContent.data
        property string title: ""
        property string icon: ""
        property color accentColor: Config.accentColor
        
        Layout.fillWidth: true
        implicitHeight: cardContent.implicitHeight + (title ? 88 : 32)
        radius: 16
        color: Config.surfaceColor
        border.width: 1
        border.color: Config.borderColor
        
        ColumnLayout {
            id: cardContent
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: title ? 72 : 16
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 12
        }
        
        RowLayout {
            visible: title !== ""
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 20
            height: 36
            spacing: 12
            
            Rectangle {
                width: 36
                height: 36
                radius: 10
                color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
                
                Text {
                    anchors.centerIn: parent
                    text: icon
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: accentColor
                }
            }
            
            Text {
                text: title
                font.family: Config.fontFamily
                font.pixelSize: 16
                font.weight: Font.Medium
                color: Config.foregroundColor
            }
            
            Item { Layout.fillWidth: true }
        }
    }
    
    component MD3Toggle: Rectangle {
        property bool checked: false
        signal toggled(bool value)
        
        width: 52
        height: 32
        radius: 16
        color: checked ? Config.accentColor : Qt.rgba(1,1,1,0.15)
        
        Behavior on color { ColorAnimation { duration: 200 } }
        
        Rectangle {
            width: 24
            height: 24
            radius: 12
            color: parent.checked ? Config.onAccent : "#FFFFFF"
            x: parent.checked ? parent.width - width - 4 : 4
            anchors.verticalCenter: parent.verticalCenter
            
            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
        
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.toggled(!parent.checked)
        }
    }
    
    component MD3Slider: Rectangle {
        property real value: 0
        property real from: 0
        property real to: 100
        property real stepSize: 1
        signal moved(real newValue)
        
        Layout.preferredWidth: 120
        height: 32
        color: "transparent"
        
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: Qt.rgba(1,1,1,0.1)
            
            Rectangle {
                width: Math.max(0, Math.min(parent.width, parent.width * ((parent.parent.value - parent.parent.from) / (parent.parent.to - parent.parent.from))))
                height: parent.height
                radius: 3
                color: Config.accentColor
            }
        }
        
        Rectangle {
            id: sliderHandle
            width: 18
            height: 18
            radius: 9
            color: sliderMouse.pressed ? Qt.lighter(Config.accentColor, 1.2) : Config.accentColor
            x: Math.max(0, Math.min(parent.width - width, (parent.width - width) * ((parent.parent.value - parent.parent.from) / (parent.parent.to - parent.parent.from))))
            anchors.verticalCenter: parent.verticalCenter
            
            Behavior on color { ColorAnimation { duration: 100 } }
        }
        
        MouseArea {
            id: sliderMouse
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            
            onPressed: updateValue(mouse)
            onPositionChanged: if (pressed) updateValue(mouse)
            
            function updateValue(mouse) {
                var ratio = Math.max(0, Math.min(1, mouse.x / parent.width))
                var range = parent.to - parent.from
                var rawValue = parent.from + ratio * range
                var steppedValue = Math.round(rawValue / parent.stepSize) * parent.stepSize
                steppedValue = Math.max(parent.from, Math.min(parent.to, steppedValue))
                if (steppedValue !== parent.value) parent.moved(steppedValue)
            }
        }
    }
    
    component MD3Input: Rectangle {
        property alias text: inputField.text
        property string placeholder: ""
        signal editingFinished()
        
        width: 160
        height: 40
        radius: 10
        color: Qt.rgba(1,1,1,0.04)
        border.width: 1
        border.color: inputField.activeFocus ? Config.accentColor : Config.borderColor
        
        Behavior on border.color { ColorAnimation { duration: 150 } }
        
        TextInput {
            id: inputField
            anchors.fill: parent
            anchors.margins: 12
            color: Config.foregroundColor
            font.family: Config.fontFamily
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
            selectByMouse: true
            clip: true
            onEditingFinished: parent.editingFinished()
            
            Text {
                visible: !parent.text && !parent.activeFocus
                text: parent.parent.placeholder
                font: parent.font
                color: Config.dimmedColor
            }
        }
    }
    
    // App icon component for showing current application icon
    component AppIcon: Rectangle {
        property string appName: ""
        
        width: 32
        height: 32
        radius: 8
        color: Qt.rgba(1,1,1,0.08)
        
        Text {
            anchors.centerIn: parent
            text: {
                // Map common app names to icons
                var name = appName.toLowerCase()
                if (name.includes("kitty") || name.includes("alacritty") || name.includes("foot") || name.includes("wezterm") || name.includes("terminal"))
                    return "terminal"
                else if (name.includes("nautilus") || name.includes("thunar") || name.includes("dolphin") || name.includes("pcmanfm") || name.includes("nemo") || name.includes("file"))
                    return "folder"
                else if (name.includes("firefox") || name.includes("chrome") || name.includes("chromium") || name.includes("brave") || name.includes("zen") || name.includes("browser"))
                    return "public"
                else
                    return "apps"
            }
            font.family: "Material Symbols Outlined"
            font.pixelSize: 18
            color: Config.dimmedColor
        }
    }
    
    component SettingRow: Rectangle {
        property string label: ""
        property string sublabel: ""
        property string icon: ""
        default property alias content: rowContent.data
        
        Layout.fillWidth: true
        implicitHeight: sublabel ? 64 : 56
        color: "transparent"
        
        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            spacing: 12
            
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 10
                color: Qt.rgba(1,1,1,0.06)
                
                Text {
                    anchors.centerIn: parent
                    text: icon
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 18
                    color: Config.accentColor
                }
            }
            
            Column {
                Layout.fillWidth: true
                spacing: 2
                
                Text {
                    text: label
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    color: Config.foregroundColor
                }
                
                Text {
                    visible: sublabel !== ""
                    text: sublabel
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    color: Config.dimmedColor
                }
            }
            
            Row {
                id: rowContent
                spacing: 8
            }
        }
    }
    
    component SegmentedButton: Row {
        property var options: []
        property string selected: ""
        signal optionSelected(string value)
        
        spacing: 0
        
        Repeater {
            model: options
            
            Rectangle {
                width: 72
                height: 36
                radius: 8
                color: selected === modelData ? Config.accentColor : Qt.rgba(1,1,1,0.04)
                border.width: selected === modelData ? 0 : 1
                border.color: Config.borderColor
                
                Behavior on color { ColorAnimation { duration: 150 } }
                
                Text {
                    anchors.centerIn: parent
                    text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    font.weight: selected === modelData ? Font.Medium : Font.Normal
                    color: selected === modelData ? Config.onAccent : Config.dimmedColor
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: optionSelected(modelData)
                }
            }
        }
    }
    
    // ========================================================================
    //                          PROCESSES
    // ========================================================================
    
    // List wallpapers from ~/.background folder
    property var wallpaperList: []
    property string backgroundFolder: Quickshell.env("HOME") + "/.background"
    
    Process {
        id: listWallpapersProcess
        command: ["bash", "-c", "find " + root.backgroundFolder + " -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \\) 2>/dev/null | sort"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let output = this.text.trim()
                if (output) {
                    root.wallpaperList = output.split("\n").filter(p => p.length > 0)
                } else {
                    root.wallpaperList = []
                }
            }
        }
    }
    
    // Refresh wallpaper list periodically or on demand
    Timer {
        id: refreshWallpapersTimer
        interval: 5000
        running: true
        repeat: true
        onTriggered: listWallpapersProcess.running = true
    }
    
    Process {
        id: filePickerProcess
        command: ["zenity", "--file-selection", "--file-filter=Images | *.png *.jpg *.jpeg *.webp *.gif", "--title=Select Wallpaper"]
        stdout: StdioCollector {
            onStreamFinished: {
                let path = this.text.trim()
                if (path) {
                    Config.wallpaperPath = path
                    // Auto-apply colors if dynamic colors is enabled
                    if (Config.dynamicColors) {
                        ColorScheme.applyWallpaper(path)
                    }
                }
            }
        }
    }
    
    // Function to select a wallpaper and optionally apply colors
    function selectWallpaper(path) {
        Config.wallpaperPath = path
        if (Config.dynamicColors) {
            ColorScheme.applyWallpaper(path)
        }
    }
    
    // ========================================================================
    //                          MAIN LAYOUT
    // ========================================================================
    
    Flickable {
        anchors.fill: parent
        contentHeight: mainLayout.height + 48
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: Qt.rgba(1,1,1,0.3)
            }
        }
        
        ColumnLayout {
            id: mainLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 24
            spacing: 20
            
            // ================================================================
            //                     DEFAULT APPLICATIONS
            // ================================================================
            
            MD3Card {
                title: "Default Applications"
                icon: "apps"
                accentColor: Config.accentColor
                
                SettingRow {
                    label: "Terminal"
                    sublabel: "Used for terminal shortcuts"
                    icon: "terminal"
                    
                    AppIcon { appName: root.defaultTerminal }
                    
                    MD3Input {
                        text: root.defaultTerminal
                        placeholder: "e.g. kitty"
                        onEditingFinished: root.defaultTerminal = text
                    }
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                SettingRow {
                    label: "File Manager"
                    sublabel: "Used for file manager shortcuts"
                    icon: "folder"
                    
                    AppIcon { appName: root.defaultFileManager }
                    
                    MD3Input {
                        text: root.defaultFileManager
                        placeholder: "e.g. nautilus"
                        onEditingFinished: root.defaultFileManager = text
                    }
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                SettingRow {
                    label: "Browser"
                    sublabel: "Used for browser shortcuts"
                    icon: "public"
                    
                    AppIcon { appName: root.defaultBrowser }
                    
                    MD3Input {
                        text: root.defaultBrowser
                        placeholder: "e.g. firefox"
                        onEditingFinished: root.defaultBrowser = text
                    }
                }
            }
            
            // ================================================================
            //                     WALLPAPER
            // ================================================================
            
            MD3Card {
                title: "Wallpaper"
                icon: "wallpaper"
                accentColor: Config.accentColor
                
                // Preview
                Rectangle {
                    Layout.fillWidth: true
                    height: 140
                    radius: 12
                    color: Qt.rgba(0,0,0,0.4)
                    clip: true
                    
                    Image {
                        anchors.fill: parent
                        source: Config.wallpaperPath ? "file://" + Config.wallpaperPath : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        // Use smaller size for preview to save memory
                        sourceSize.width: 400
                        sourceSize.height: 280
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: Config.wallpaperPath ? "" : "No wallpaper set"
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        color: Config.dimmedColor
                        visible: !Config.wallpaperPath
                    }
                    
                    // Color preview
                    Row {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 10
                        spacing: 4
                        visible: Config.wallpaperPath && Config.dynamicColors
                        
                        Repeater {
                            model: [Config.accentColor, Config.backgroundColor, Config.foregroundColor, Config.dimmedColor]
                            Rectangle {
                                width: 20
                                height: 20
                                radius: 4
                                color: modelData
                                border.width: 1
                                border.color: Qt.rgba(1,1,1,0.3)
                            }
                        }
                    }
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant }
                
                // Wallpaper Gallery from ~/.background (Collapsible)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: root.wallpaperList.length > 0
                    
                    property bool expanded: false
                    
                    // Header row (clickable to expand/collapse)
                    Rectangle {
                        Layout.fillWidth: true
                        height: 48
                        radius: 10
                        color: galleryHeaderMouse.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"
                        
                        Behavior on color { ColorAnimation { duration: 100 } }
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 8
                            spacing: 12
                            
                            Rectangle {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                radius: 10
                                color: Qt.rgba(1,1,1,0.06)
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "photo_library"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 18
                                    color: Config.accentColor
                                }
                            }
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                
                                Text {
                                    text: "Wallpaper Gallery"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 14
                                    color: Config.foregroundColor
                                }
                                
                                Text {
                                    text: "~/.background (" + root.wallpaperList.length + " images)"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    color: Config.dimmedColor
                                }
                            }
                            
                            Rectangle {
                                width: 32
                                height: 32
                                radius: 8
                                color: refreshM.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.04)
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "refresh"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 16
                                    color: Config.dimmedColor
                                }
                                
                                MouseArea {
                                    id: refreshM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        listWallpapersProcess.running = true
                                        mouse.accepted = true
                                    }
                                }
                            }
                            
                            // Expand/collapse chevron
                            Text {
                                text: parent.parent.parent.expanded ? "expand_less" : "expand_more"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 20
                                color: Config.dimmedColor
                            }
                        }
                        
                        MouseArea {
                            id: galleryHeaderMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: parent.parent.expanded = !parent.parent.expanded
                        }
                    }
                    
                    // Wallpaper grid (collapsible)
                    GridLayout {
                        id: wallpaperGrid
                        Layout.fillWidth: true
                        // Dynamic columns based on available width (min 120px per item)
                        columns: Math.max(2, Math.floor(width / 130))
                        columnSpacing: 8
                        rowSpacing: 8
                        visible: parent.expanded
                        
                        Repeater {
                            model: root.wallpaperList
                            
                            Rectangle {
                                id: wpCard
                                Layout.fillWidth: true
                                Layout.preferredHeight: 75
                                radius: 8
                                color: Qt.rgba(0, 0, 0, 0.3)
                                clip: true
                                
                                property bool isSelected: Config.wallpaperPath === modelData
                                
                                border.width: isSelected ? 2 : 1
                                border.color: isSelected ? Config.accentColor : (wpMouse.containsMouse ? Config.outlineVariant : Config.borderColor)
                                
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                
                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    source: "file://" + modelData
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    cache: true
                                    sourceSize.width: 200
                                    sourceSize.height: 120
                                    
                                    opacity: status === Image.Ready ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 200 } }
                                }
                                
                                // Loading placeholder
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    radius: parent.radius - 1
                                    color: Qt.rgba(1,1,1,0.05)
                                    visible: parent.children[0].status !== Image.Ready
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "image"
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 18
                                        color: Config.dimmedColor
                                        opacity: 0.5
                                    }
                                }
                                
                                // Checkmark for selected
                                Rectangle {
                                    visible: wpCard.isSelected
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 4
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: Config.accentColor
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "check"
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 12
                                        color: Config.onAccent
                                    }
                                }
                                
                                // Hover overlay
                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: wpMouse.containsMouse ? Qt.rgba(1,1,1,0.15) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                
                                MouseArea {
                                    id: wpMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectWallpaper(modelData)
                                }
                            }
                        }
                    }
                }
                
                // Show hint if no wallpapers found
                Rectangle {
                    visible: root.wallpaperList.length === 0
                    Layout.fillWidth: true
                    height: 60
                    radius: 10
                    color: Qt.rgba(1,1,1,0.04)
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 12
                        
                        Text {
                            text: "folder"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 24
                            color: Config.dimmedColor
                        }
                        
                        ColumnLayout {
                            spacing: 2
                            
                            Text {
                                text: "No wallpapers found"
                                font.family: Config.fontFamily
                                font.pixelSize: 13
                                color: Config.foregroundColor
                            }
                            
                            Text {
                                text: "Add images to ~/.background"
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                color: Config.dimmedColor
                            }
                        }
                    }
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant }
                
                SettingRow {
                    label: "Quickshell Wallpaper"
                    sublabel: "Render wallpaper via Quickshell"
                    icon: "desktop_windows"
                    
                    MD3Toggle {
                        checked: Config.wallpaperEnabled
                        onToggled: (val) => Config.wallpaperEnabled = val
                    }
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 10
                        color: Qt.rgba(1,1,1,0.06)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "image"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                            color: Config.accentColor
                        }
                    }
                    
                    Text {
                        text: "Path"
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        color: Config.foregroundColor
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: 10
                        color: Qt.rgba(1,1,1,0.04)
                        border.width: 1
                        border.color: wpInput.activeFocus ? Config.accentColor : Config.borderColor
                        
                        TextInput {
                            id: wpInput
                            anchors.fill: parent
                            anchors.margins: 12
                            text: Config.wallpaperPath
                            color: Config.foregroundColor
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            clip: true
                            onEditingFinished: Config.wallpaperPath = text
                            
                            Text {
                                visible: !parent.text && !parent.activeFocus
                                text: "Enter path..."
                                font: parent.font
                                color: Config.dimmedColor
                            }
                        }
                    }
                    
                    Rectangle {
                        width: 40
                        height: 40
                        radius: 10
                        color: browseM.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.04)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "folder_open"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                            color: Config.dimmedColor
                        }
                        
                        MouseArea {
                            id: browseM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: filePickerProcess.running = true
                        }
                    }
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 10
                        color: Qt.rgba(1,1,1,0.06)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "aspect_ratio"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                            color: Config.dimmedColor
                        }
                    }
                    
                    Text {
                        text: "Fill Mode"
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        color: Config.foregroundColor
                        Layout.fillWidth: true
                    }
                    
                    SegmentedButton {
                        options: ["cover", "contain", "stretch", "tile"]
                        selected: Config.wallpaperFillMode
                        onOptionSelected: (val) => Config.wallpaperFillMode = val
                    }
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                SettingRow {
                    label: "Dynamic Colors"
                    sublabel: "Generate UI colors from wallpaper"
                    icon: "palette"
                    
                    MD3Toggle {
                        checked: Config.dynamicColors
                        onToggled: (val) => Config.dynamicColors = val
                    }
                }
                
                // Regenerate button
                Rectangle {
                    visible: Config.wallpaperPath && Config.dynamicColors
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    height: 44
                    radius: 22
                    color: regenM.containsMouse ? Qt.lighter(Config.accentColor, 1.1) : Config.accentColor
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        
                        Text {
                            text: "auto_awesome"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                            color: Config.onAccent
                        }
                        
                        Text {
                            text: "Regenerate Colors"
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: Config.onAccent
                        }
                    }
                    
                    MouseArea {
                        id: regenM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ColorScheme.applyWallpaper(Config.wallpaperPath)
                    }
                }
            }
            
            // ================================================================
            //                     QUICKSHELL
            // ================================================================
            
            MD3Card {
                title: "Quickshell"
                icon: "dock_to_bottom"
                accentColor: Config.accentColor
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 10
                        color: Qt.rgba(1,1,1,0.06)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "view_day"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                            color: Config.accentColor
                        }
                    }
                    
                    Text {
                        text: "Bar Layout"
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        color: Config.foregroundColor
                        Layout.fillWidth: true
                    }
                    
                    SegmentedButton {
                        options: ["fullwidth", "floating"]
                        selected: root.barStyle
                        onOptionSelected: (val) => {
                            root.barStyle = val
                            Config.barStyle = val
                        }
                    }
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                SettingRow {
                    label: "Auto-Hide Bar"
                    icon: "visibility_off"
                    
                    MD3Toggle {
                        checked: root.barAutoHide
                        onToggled: (val) => {
                            root.barAutoHide = val
                            Config.barAutoHide = val
                        }
                    }
                }
            }
            
            // ================================================================
            //                     GENERAL
            // ================================================================
            
            MD3Card {
                title: "General"
                icon: "tune"
                accentColor: Config.accentColor
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 10
                        color: Qt.rgba(1,1,1,0.06)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "space_dashboard"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                            color: Config.accentColor
                        }
                    }
                    
                    Text {
                        text: "Window Gaps"
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        color: Config.foregroundColor
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        text: root.gapsIn + " px"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: Config.dimmedColor
                    }
                    
                    MD3Slider {
                        value: root.gapsIn
                        from: 0; to: 30; stepSize: 1
                        onMoved: (val) => root.gapsIn = val
                    }
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 10
                        color: Qt.rgba(1,1,1,0.06)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "padding"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                            color: Config.accentColor
                        }
                    }
                    
                    Text {
                        text: "Screen Gaps"
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        color: Config.foregroundColor
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        text: root.gapsOut + " px"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: Config.dimmedColor
                    }
                    
                    MD3Slider {
                        value: root.gapsOut
                        from: 0; to: 60; stepSize: 1
                        onMoved: (val) => root.gapsOut = val
                    }
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 10
                        color: Qt.rgba(1,1,1,0.06)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "border_style"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                            color: Config.accentColor
                        }
                    }
                    
                    Text {
                        text: "Border Size"
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        color: Config.foregroundColor
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        text: root.borderSize + " px"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: Config.dimmedColor
                    }
                    
                    MD3Slider {
                        value: root.borderSize
                        from: 0; to: 10; stepSize: 1
                        onMoved: (val) => root.borderSize = val
                    }
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 10
                        color: Qt.rgba(1,1,1,0.06)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "view_quilt"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                            color: Config.accentColor
                        }
                    }
                    
                    Text {
                        text: "Window Layout"
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        color: Config.foregroundColor
                        Layout.fillWidth: true
                    }
                    
                    SegmentedButton {
                        options: ["dwindle", "master"]
                        selected: root.layout
                        onOptionSelected: (val) => root.layout = val
                    }
                }
            }
            
            // ================================================================
            //                     BORDER
            // ================================================================
            
            MD3Card {
                title: "Border"
                icon: "border_style"
                accentColor: Config.accentColor
                
                SettingRow {
                    label: "Resize on Border"
                    sublabel: "Drag window border to resize"
                    icon: "drag_pan"
                    
                    MD3Toggle {
                        checked: root.borderResize
                        onToggled: (val) => root.borderResize = val
                    }
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 10
                        color: Qt.rgba(1,1,1,0.06)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "palette"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                            color: Config.accentColor
                        }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        
                        Text {
                            text: "Active Border Color"
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            color: Config.foregroundColor
                        }
                        
                        RowLayout {
                            spacing: 8
                            
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 6
                                border.width: 2
                                border.color: Qt.rgba(1,1,1,0.2)
                                color: {
                                    let match = root.activeColor.match(/rgba\(([a-fA-F0-9]{6,8})\)/)
                                    if (match) return "#" + match[1].substring(0,6)
                                    return Config.accentColor
                                }
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                radius: 8
                                color: Qt.rgba(1,1,1,0.04)
                                border.width: 1
                                border.color: acInput.activeFocus ? Config.accentColor : Config.borderColor
                                
                                TextInput {
                                    id: acInput
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    text: root.activeColor
                                    color: Config.foregroundColor
                                    font.family: "monospace"
                                    font.pixelSize: 11
                                    verticalAlignment: Text.AlignVCenter
                                    selectByMouse: true
                                    clip: true
                                    onEditingFinished: root.activeColor = text
                                }
                            }
                        }
                    }
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 10
                        color: Qt.rgba(1,1,1,0.06)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "format_color_fill"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                            color: Config.dimmedColor
                        }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        
                        Text {
                            text: "Inactive Border Color"
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            color: Config.foregroundColor
                        }
                        
                        RowLayout {
                            spacing: 8
                            
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 6
                                border.width: 2
                                border.color: Qt.rgba(1,1,1,0.2)
                                color: {
                                    let match = root.inactiveColor.match(/rgba\(([a-fA-F0-9]{6,8})\)/)
                                    if (match) return "#" + match[1].substring(0,6)
                                    return "#333"
                                }
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                radius: 8
                                color: Qt.rgba(1,1,1,0.04)
                                border.width: 1
                                border.color: inInput.activeFocus ? Config.accentColor : Config.borderColor
                                
                                TextInput {
                                    id: inInput
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    text: root.inactiveColor
                                    color: Config.foregroundColor
                                    font.family: "monospace"
                                    font.pixelSize: 11
                                    verticalAlignment: Text.AlignVCenter
                                    selectByMouse: true
                                    clip: true
                                    onEditingFinished: root.inactiveColor = text
                                }
                            }
                        }
                    }
                }
            }
            
            // ================================================================
            //                     DECORATION
            // ================================================================
            
            MD3Card {
                title: "Decoration"
                icon: "auto_awesome"
                accentColor: Config.accentColor
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 10
                        color: Qt.rgba(1,1,1,0.06)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "rounded_corner"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                            color: Config.accentColor
                        }
                    }
                    
                    Text {
                        text: "Corner Rounding"
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        color: Config.foregroundColor
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        text: root.rounding + " px"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: Config.dimmedColor
                    }
                    
                    MD3Slider {
                        value: root.rounding
                        from: 0; to: 30; stepSize: 1
                        onMoved: (val) => root.rounding = val
                    }
                }
                
                // Rounding Power sub-setting
                RowLayout {
                    visible: root.rounding > 0
                    Layout.fillWidth: true
                    Layout.leftMargin: 48
                    spacing: 12
                    
                    Text {
                        text: "Rounding Power"
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                        color: Config.dimmedColor
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        text: root.roundingPower.toFixed(1)
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: Config.dimmedColor
                    }
                    
                    MD3Slider {
                        value: root.roundingPower
                        from: 1; to: 5; stepSize: 0.5
                        onMoved: (val) => root.roundingPower = val
                    }
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 10
                        color: Qt.rgba(1,1,1,0.06)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "opacity"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                            color: Config.accentColor
                        }
                    }
                    
                    Text {
                        text: "Active Opacity"
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        color: Config.foregroundColor
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        text: Math.round(root.activeOpacity * 100) + "%"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: Config.dimmedColor
                    }
                    
                    MD3Slider {
                        value: root.activeOpacity
                        from: 0.1; to: 1.0; stepSize: 0.05
                        onMoved: (val) => root.activeOpacity = val
                    }
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 10
                        color: Qt.rgba(1,1,1,0.06)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "blur_linear"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                            color: Config.accentColor
                        }
                    }
                    
                    Text {
                        text: "Inactive Opacity"
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        color: Config.foregroundColor
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        text: Math.round(root.inactiveOpacity * 100) + "%"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: Config.dimmedColor
                    }
                    
                    MD3Slider {
                        value: root.inactiveOpacity
                        from: 0.1; to: 1.0; stepSize: 0.05
                        onMoved: (val) => root.inactiveOpacity = val
                    }
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                SettingRow {
                    label: "Window Blur"
                    icon: "blur_on"
                    
                    MD3Toggle {
                        checked: root.blurEnabled
                        onToggled: (val) => root.blurEnabled = val
                    }
                }
                
                // Blur sub-settings
                RowLayout {
                    visible: root.blurEnabled
                    Layout.fillWidth: true
                    Layout.leftMargin: 48
                    spacing: 12
                    
                    Text {
                        text: "Blur Size"
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                        color: Config.dimmedColor
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        text: root.blurSize.toString()
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: Config.dimmedColor
                    }
                    
                    MD3Slider {
                        value: root.blurSize
                        from: 1; to: 20; stepSize: 1
                        onMoved: (val) => root.blurSize = val
                    }
                }
                
                RowLayout {
                    visible: root.blurEnabled
                    Layout.fillWidth: true
                    Layout.leftMargin: 48
                    spacing: 12
                    
                    Text {
                        text: "Blur Passes"
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                        color: Config.dimmedColor
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        text: root.blurPasses.toString()
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: Config.dimmedColor
                    }
                    
                    MD3Slider {
                        value: root.blurPasses
                        from: 1; to: 6; stepSize: 1
                        onMoved: (val) => root.blurPasses = val
                    }
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                SettingRow {
                    label: "Window Shadows"
                    icon: "ev_shadow"
                    
                    MD3Toggle {
                        checked: root.shadowEnabled
                        onToggled: (val) => root.shadowEnabled = val
                    }
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                SettingRow {
                    label: "Dim Inactive"
                    icon: "brightness_low"
                    
                    MD3Toggle {
                        checked: root.dimInactive
                        onToggled: (val) => root.dimInactive = val
                    }
                }
            }
            
            // ================================================================
            //                     ANIMATIONS
            // ================================================================
            
            MD3Card {
                title: "Animations"
                icon: "animation"
                accentColor: Config.accentColor
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 10
                        color: Qt.rgba(1,1,1,0.06)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "animation"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                            color: Config.accentColor
                        }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        Text {
                            text: "Current Animation"
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            color: Config.foregroundColor
                        }
                        
                        Text {
                            text: HyprlandConfig.getAnimationName(HyprlandConfig.animationPath)
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Config.accentColor
                        }
                    }
                }
                
                Text {
                    text: "Choose an animation preset"
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    color: Config.dimmedColor
                    Layout.topMargin: 4
                }
                
                GridLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    columns: 3
                    columnSpacing: 8
                    rowSpacing: 8
                    
                    Repeater {
                        model: HyprlandConfig.animationPaths
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            radius: 12
                            
                            property bool isSelected: HyprlandConfig.animationPath === modelData
                            
                            color: isSelected ? Qt.rgba(0.91, 0.12, 0.39, 0.15) : (animM.containsMouse ? Qt.rgba(1,1,1,0.06) : Qt.rgba(1,1,1,0.03))
                            border.width: isSelected ? 2 : 1
                            border.color: isSelected ? Config.accentColor : Config.borderColor
                            
                            Behavior on color { ColorAnimation { duration: 150 } }
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8
                                
                                Text {
                                    text: isSelected ? "check_circle" : "radio_button_unchecked"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 18
                                    color: isSelected ? Config.accentColor : Config.dimmedColor
                                }
                                
                                Text {
                                    text: HyprlandConfig.getAnimationName(modelData)
                                    font.family: Config.fontFamily
                                    font.pixelSize: 12
                                    font.weight: isSelected ? Font.Medium : Font.Normal
                                    color: isSelected ? Config.foregroundColor : Config.dimmedColor
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }
                            
                            MouseArea {
                                id: animM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: HyprlandConfig.animationPath = modelData
                            }
                        }
                    }
                }
                
                Text {
                    Layout.topMargin: 8
                    text: "Animation files are loaded from ~/.config/hypr/animations/"
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    color: Config.dimmedColor
                }
            }
            
            Item { height: 24 }
        }
    }
}
