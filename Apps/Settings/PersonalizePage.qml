/*
 * ============================================================================
 *                     PERSONALIZE SETTINGS - NEW DESIGN
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../misc"

Item {
    id: root
    
    // Settings state
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
    
    // Bindings
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
    
    // Wallpaper list
    property var wallpaperList: []
    property string backgroundFolder: Quickshell.env("HOME") + "/.background"
    
    Process {
        id: listWallpapersProcess
        command: ["bash", "-c", "find " + root.backgroundFolder + " -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) 2>/dev/null | sort"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let output = this.text.trim()
                root.wallpaperList = output ? output.split("\n").filter(p => p.length > 0) : []
            }
        }
    }
    
    Process {
        id: filePickerProcess
        command: ["zenity", "--file-selection", "--file-filter=Images | *.png *.jpg *.jpeg *.webp", "--title=Select Wallpaper"]
        stdout: StdioCollector {
            onStreamFinished: {
                let path = this.text.trim()
                if (path) {
                    Config.wallpaperPath = path
                    if (Config.dynamicColors) ColorScheme.applyWallpaper(path)
                }
            }
        }
    }
    
    function selectWallpaper(path) {
        Config.wallpaperPath = path
        if (Config.dynamicColors) ColorScheme.applyWallpaper(path)
    }
    
    // ========================================================================
    //                          REUSABLE COMPONENTS
    // ========================================================================
    
    component Section: Rectangle {
        default property alias content: sectionContent.data
        property string title: ""
        
        Layout.fillWidth: true
        implicitHeight: sectionContent.implicitHeight + 56
        radius: 12
        color: Config.surfaceColor
        
        ColumnLayout {
            id: sectionContent
            anchors.fill: parent
            anchors.topMargin: 48
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 12
            spacing: 10
        }
        
        Text {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: 16
            anchors.leftMargin: 16
            text: title
            font.family: Config.fontFamily
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: Config.dimmedColor
            opacity: 0.8
        }
    }
    
    component Toggle: Rectangle {
        property bool checked: false
        signal toggled(bool value)
        
        width: 44
        height: 24
        radius: 12
        color: checked ? Config.accentColor : Qt.rgba(1,1,1,0.12)
        
        Behavior on color { ColorAnimation { duration: 150 } }
        
        Rectangle {
            width: 18
            height: 18
            radius: 9
            color: "#fff"
            x: parent.checked ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
        
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.toggled(!parent.checked)
        }
    }
    
    component SettingRow: RowLayout {
        property string label: ""
        property string sublabel: ""
        property string icon: ""
        default property alias rowContent: contentHolder.children
        
        Layout.fillWidth: true
        height: sublabel ? 52 : 40
        spacing: 12
        
        Text {
            text: icon
            font.family: "Material Symbols Rounded"
            font.pixelSize: 18
            color: Config.dimmedColor
        }
        
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            
            Text {
                text: label
                font.family: Config.fontFamily
                font.pixelSize: 13
                color: Config.foregroundColor
            }
            
            Text {
                visible: sublabel
                text: sublabel
                font.family: Config.fontFamily
                font.pixelSize: 10
                color: Config.dimmedColor
            }
        }
        
        Row {
            id: contentHolder
            spacing: 8
        }
    }
    
    component Slider: Item {
        id: sliderRoot
        property real value: 0
        property real from: 0
        property real to: 100
        property real stepSize: 1
        signal moved(real val)
        
        width: 100
        height: 28
        
        // Use internal value during drag, external value otherwise
        readonly property real displayValue: sliderMouse.pressed ? _internalValue : value
        property real _internalValue: value
        
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 4
            radius: 2
            color: Qt.rgba(1,1,1,0.08)
            
            Rectangle {
                width: Math.max(0, parent.width * (sliderRoot.displayValue - sliderRoot.from) / (sliderRoot.to - sliderRoot.from))
                height: parent.height
                radius: 2
                color: Config.accentColor
            }
        }
        
        Rectangle {
            x: Math.max(-7, parent.width * (sliderRoot.displayValue - sliderRoot.from) / (sliderRoot.to - sliderRoot.from) - 7)
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            radius: 7
            color: Config.accentColor
            scale: sliderMouse.pressed ? 1.15 : 1
            
            Behavior on scale { NumberAnimation { duration: 80 } }
        }
        
        MouseArea {
            id: sliderMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            
            onPressed: (mouse) => {
                sliderRoot._internalValue = sliderRoot.value
                doUpdate(mouse)
            }
            onPositionChanged: (mouse) => { if (pressed) doUpdate(mouse) }
            
            function doUpdate(mouse) {
                var ratio = Math.max(0, Math.min(1, mouse.x / width))
                var raw = sliderRoot.from + ratio * (sliderRoot.to - sliderRoot.from)
                var stepped = Math.round(raw / sliderRoot.stepSize) * sliderRoot.stepSize
                stepped = Math.max(sliderRoot.from, Math.min(sliderRoot.to, stepped))
                sliderRoot._internalValue = stepped
                sliderRoot.moved(stepped)
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
                width: 64
                height: 28
                radius: 6
                color: selected === modelData ? Config.accentColor : Qt.rgba(1,1,1,0.04)
                border.width: selected === modelData ? 0 : 1
                border.color: Config.borderColor
                
                Behavior on color { ColorAnimation { duration: 100 } }
                
                Text {
                    anchors.centerIn: parent
                    text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                    font.family: Config.fontFamily
                    font.pixelSize: 10
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
    //                              MAIN LAYOUT
    // ========================================================================
    
    Flickable {
        anchors.fill: parent
        contentHeight: mainCol.height + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 3
                radius: 1.5
                color: Qt.rgba(1,1,1,0.2)
            }
        }
        
        ColumnLayout {
            id: mainCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 20
            spacing: 16
            
            // Wallpaper Section
            Section {
                title: "WALLPAPER"
                
                // Preview
                Rectangle {
                    Layout.fillWidth: true
                    height: 120
                    radius: 10
                    color: Qt.rgba(0,0,0,0.3)
                    clip: true
                    
                    Image {
                        anchors.fill: parent
                        source: Config.wallpaperPath ? "file://" + Config.wallpaperPath : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 350
                        sourceSize.height: 200
                    }
                    
                    // Color chips
                    Row {
                        visible: Config.wallpaperPath && Config.dynamicColors
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 8
                        spacing: 3
                        
                        Repeater {
                            model: [Config.accentColor, Config.backgroundColor, Config.foregroundColor]
                            Rectangle {
                                width: 16
                                height: 16
                                radius: 3
                                color: modelData
                                border.width: 1
                                border.color: Qt.rgba(1,1,1,0.2)
                            }
                        }
                    }
                    
                    // Browse button
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 8
                        width: 32
                        height: 32
                        radius: 8
                        color: browseMouse.containsMouse ? Qt.rgba(0,0,0,0.7) : Qt.rgba(0,0,0,0.5)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "folder_open"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 16
                            color: "#fff"
                        }
                        
                        MouseArea {
                            id: browseMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: filePickerProcess.running = true
                        }
                    }
                }
                
                // Gallery (collapsed)
                Rectangle {
                    id: galleryContainer
                    visible: root.wallpaperList.length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: galleryExpanded ? Math.min(220, 52 + Math.ceil(root.wallpaperList.length / 4) * 68) : 44
                    radius: 8
                    color: Qt.rgba(1,1,1,0.02)
                    clip: true
                    
                    property bool galleryExpanded: false
                    
                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    
                    // Header row (always visible)
                    RowLayout {
                        id: galleryHeader
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 12
                        height: 20
                        
                        Text {
                            text: "photo_library"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 16
                            color: Config.dimmedColor
                        }
                        
                        Text {
                            text: "Gallery (" + root.wallpaperList.length + ")"
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            color: Config.dimmedColor
                            Layout.fillWidth: true
                        }
                        
                        Text {
                            text: galleryContainer.galleryExpanded ? "expand_less" : "expand_more"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 18
                            color: Config.dimmedColor
                        }
                    }
                    
                    // Grid (only when expanded)
                    Flickable {
                        anchors.top: galleryHeader.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 8
                        anchors.topMargin: 12
                        contentHeight: galleryGrid.height
                        clip: true
                        visible: galleryContainer.galleryExpanded
                        boundsBehavior: Flickable.StopAtBounds
                        
                        GridLayout {
                            id: galleryGrid
                            width: parent.width
                            columns: 4
                            columnSpacing: 6
                            rowSpacing: 6
                            
                            Repeater {
                                model: root.wallpaperList
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 60
                                    radius: 6
                                    color: Qt.rgba(0,0,0,0.3)
                                    clip: true
                                    border.width: Config.wallpaperPath === modelData ? 2 : 0
                                    border.color: Config.accentColor
                                    
                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        source: "file://" + modelData
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        sourceSize.width: 120
                                        sourceSize.height: 80
                                    }
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.selectWallpaper(modelData)
                                    }
                                }
                            }
                        }
                    }
                    
                    MouseArea {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 44
                        cursorShape: Qt.PointingHandCursor
                        onClicked: galleryContainer.galleryExpanded = !galleryContainer.galleryExpanded
                    }
                }
                
                SettingRow {
                    label: "Dynamic Colors"
                    sublabel: "Generate from wallpaper"
                    icon: "palette"
                    
                    Toggle {
                        checked: Config.dynamicColors
                        onToggled: (val) => Config.dynamicColors = val
                    }
                }
                
                // Regenerate button
                Rectangle {
                    visible: Config.wallpaperPath && Config.dynamicColors
                    Layout.fillWidth: true
                    height: 36
                    radius: 18
                    color: regenMouse.containsMouse ? Qt.lighter(Config.accentColor, 1.1) : Config.accentColor
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        
                        Text {
                            text: "auto_awesome"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 16
                            color: Config.onAccent
                        }
                        
                        Text {
                            text: "Regenerate Colors"
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Config.onAccent
                        }
                    }
                    
                    MouseArea {
                        id: regenMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ColorScheme.applyWallpaper(Config.wallpaperPath)
                    }
                }
            }
            
            // Bar Section
            Section {
                title: "BAR"
                
                SettingRow {
                    label: "Style"
                    icon: "view_day"
                    
                    SegmentedButton {
                        options: ["fullwidth", "floating"]
                        selected: root.barStyle
                        onOptionSelected: (val) => root.barStyle = val
                    }
                }
                
                SettingRow {
                    label: "Auto-Hide"
                    icon: "visibility_off"
                    
                    Toggle {
                        checked: root.barAutoHide
                        onToggled: (val) => root.barAutoHide = val
                    }
                }
            }
            
            // Window Section
            Section {
                title: "WINDOWS"
                
                SettingRow {
                    label: "Layout"
                    icon: "view_quilt"
                    
                    SegmentedButton {
                        options: ["dwindle", "master"]
                        selected: root.layout
                        onOptionSelected: (val) => root.layout = val
                    }
                }
                
                SettingRow {
                    label: "Window Gaps"
                    icon: "space_dashboard"
                    
                    Text {
                        text: root.gapsIn + "px"
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        color: Config.dimmedColor
                    }
                    
                    Slider {
                        value: root.gapsIn
                        from: 0; to: 30; stepSize: 1
                        onMoved: (val) => root.gapsIn = val
                    }
                }
                
                SettingRow {
                    label: "Screen Gaps"
                    icon: "padding"
                    
                    Text {
                        text: root.gapsOut + "px"
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        color: Config.dimmedColor
                    }
                    
                    Slider {
                        value: root.gapsOut
                        from: 0; to: 60; stepSize: 1
                        onMoved: (val) => root.gapsOut = val
                    }
                }
                
                SettingRow {
                    label: "Rounding"
                    icon: "rounded_corner"
                    
                    Text {
                        text: root.rounding + "px"
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        color: Config.dimmedColor
                    }
                    
                    Slider {
                        value: root.rounding
                        from: 0; to: 30; stepSize: 1
                        onMoved: (val) => root.rounding = val
                    }
                }
                
                SettingRow {
                    label: "Border Size"
                    icon: "border_style"
                    
                    Text {
                        text: root.borderSize + "px"
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        color: Config.dimmedColor
                    }
                    
                    Slider {
                        value: root.borderSize
                        from: 0; to: 8; stepSize: 1
                        onMoved: (val) => root.borderSize = val
                    }
                }
            }
            
            // Effects Section
            Section {
                title: "EFFECTS"
                
                SettingRow {
                    label: "Window Blur"
                    icon: "blur_on"
                    
                    Toggle {
                        checked: root.blurEnabled
                        onToggled: (val) => root.blurEnabled = val
                    }
                }
                
                SettingRow {
                    label: "Shadows"
                    icon: "ev_shadow"
                    
                    Toggle {
                        checked: root.shadowEnabled
                        onToggled: (val) => root.shadowEnabled = val
                    }
                }
                
                SettingRow {
                    label: "Dim Inactive"
                    icon: "brightness_low"
                    
                    Toggle {
                        checked: root.dimInactive
                        onToggled: (val) => root.dimInactive = val
                    }
                }
                
                SettingRow {
                    label: "Active Opacity"
                    icon: "opacity"
                    
                    Text {
                        text: Math.round(root.activeOpacity * 100) + "%"
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        color: Config.dimmedColor
                    }
                    
                    Slider {
                        value: root.activeOpacity
                        from: 0.5; to: 1.0; stepSize: 0.05
                        onMoved: (val) => root.activeOpacity = val
                    }
                }
                
                SettingRow {
                    label: "Inactive Opacity"
                    icon: "blur_linear"
                    
                    Text {
                        text: Math.round(root.inactiveOpacity * 100) + "%"
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        color: Config.dimmedColor
                    }
                    
                    Slider {
                        value: root.inactiveOpacity
                        from: 0.5; to: 1.0; stepSize: 0.05
                        onMoved: (val) => root.inactiveOpacity = val
                    }
                }
            }
            
            // Apps Section
            Section {
                title: "DEFAULT APPS"
                
                SettingRow {
                    label: "Terminal"
                    icon: "terminal"
                    
                    Rectangle {
                        width: 100
                        height: 28
                        radius: 6
                        color: Qt.rgba(1,1,1,0.04)
                        border.width: 1
                        border.color: termInput.activeFocus ? Config.accentColor : Config.borderColor
                        
                        TextInput {
                            id: termInput
                            anchors.fill: parent
                            anchors.margins: 8
                            text: root.defaultTerminal
                            color: Config.foregroundColor
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            clip: true
                            onEditingFinished: root.defaultTerminal = text
                        }
                    }
                }
                
                SettingRow {
                    label: "File Manager"
                    icon: "folder"
                    
                    Rectangle {
                        width: 100
                        height: 28
                        radius: 6
                        color: Qt.rgba(1,1,1,0.04)
                        border.width: 1
                        border.color: fmInput.activeFocus ? Config.accentColor : Config.borderColor
                        
                        TextInput {
                            id: fmInput
                            anchors.fill: parent
                            anchors.margins: 8
                            text: root.defaultFileManager
                            color: Config.foregroundColor
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            clip: true
                            onEditingFinished: root.defaultFileManager = text
                        }
                    }
                }
                
                SettingRow {
                    label: "Browser"
                    icon: "public"
                    
                    Rectangle {
                        width: 100
                        height: 28
                        radius: 6
                        color: Qt.rgba(1,1,1,0.04)
                        border.width: 1
                        border.color: browserInput.activeFocus ? Config.accentColor : Config.borderColor
                        
                        TextInput {
                            id: browserInput
                            anchors.fill: parent
                            anchors.margins: 8
                            text: root.defaultBrowser
                            color: Config.foregroundColor
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            clip: true
                            onEditingFinished: root.defaultBrowser = text
                        }
                    }
                }
            }
        }
    }
}
