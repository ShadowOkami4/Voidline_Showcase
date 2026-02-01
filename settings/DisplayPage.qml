/*
 * ============================================================================
 *                            DISPLAY SETTINGS
 * ============================================================================
 *
 * FILE: settings/DisplayPage.qml
 * PURPOSE: Settings UI for display configuration (resolution, scale, refresh)
 *
 * OVERVIEW:
 *   - Provides controls for monitor arrangement, scale, and refresh rate.
 *   - Offers per-monitor wallpaper and display-specific options.
 *   - Binds values to Hyprland or system commands where applicable.
 *
 * NOTE: This file is a UI page only — configuration persistence is handled
 *       by the central settings mechanism in `Config.qml`.
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import "../misc"

Item {
    id: root
    
    property int selectedMonitorIndex: 0
    property var selectedMonitor: DisplayHandler.monitors.length > 0 ? DisplayHandler.monitors[selectedMonitorIndex] : null
    property string initializedMonitorName: ""
    
    property bool hasPendingChanges: false
    property int confirmationTimer: 0
    property bool showConfirmation: false
    
    property string originalResolution: ""
    property real originalRefreshRate: 0
    property real originalScale: 1
    property int originalTransform: 0
    property string originalVrr: "off"
    property int originalX: 0
    property int originalY: 0
    
    property string pendingResolution: ""
    property real pendingRefreshRate: 0
    property real pendingScale: 1
    property int pendingTransform: 0
    property string pendingVrr: "off"
    property int pendingX: 0
    property int pendingY: 0
    
    readonly property var transformOptions: [
        { value: 0, label: "Normal" },
        { value: 1, label: "90°" },
        { value: 2, label: "180°" },
        { value: 3, label: "270°" }
    ]
    
    readonly property var vrrOptions: [
        { value: "off", label: "Off" },
        { value: "on", label: "On" },
        { value: "fullscreen", label: "Fullscreen" }
    ]
    
    readonly property var scaleOptions: [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]
    
    function getResolutionList() {
        if (!selectedMonitor || !selectedMonitor.availableModes) return []
        var resSet = {}
        for (var i = 0; i < selectedMonitor.availableModes.length; i++) {
            var modeStr = selectedMonitor.availableModes[i]
            var match = modeStr.match(/(\d+)x(\d+)@/)
            if (match) resSet[match[1] + "x" + match[2]] = true
        }
        var result = Object.keys(resSet)
        result.sort((a, b) => {
            var ap = a.split("x").map(Number), bp = b.split("x").map(Number)
            return bp[0] !== ap[0] ? bp[0] - ap[0] : bp[1] - ap[1]
        })
        return result
    }
    
    function getRefreshRatesForResolution(resolution) {
        if (!selectedMonitor || !selectedMonitor.availableModes) return []
        var rates = []
        for (var i = 0; i < selectedMonitor.availableModes.length; i++) {
            var modeStr = selectedMonitor.availableModes[i]
            if (modeStr.startsWith(resolution + "@")) {
                var match = modeStr.match(/@([\d.]+)Hz/)
                if (match) rates.push(parseFloat(match[1]))
            }
        }
        rates.sort((a, b) => b - a)
        return rates
    }
    
    function initializeFromMonitor() {
        if (!selectedMonitor) return
        if (initializedMonitorName === selectedMonitor.name) return
        
        var res = selectedMonitor.width + "x" + selectedMonitor.height
        originalResolution = res
        originalRefreshRate = selectedMonitor.refreshRate
        originalScale = selectedMonitor.scale || 1
        originalTransform = selectedMonitor.transform || 0
        originalVrr = selectedMonitor.vrr ? "on" : "off"
        originalX = selectedMonitor.x || 0
        originalY = selectedMonitor.y || 0
        
        pendingResolution = originalResolution
        pendingRefreshRate = originalRefreshRate
        pendingScale = originalScale
        pendingTransform = originalTransform
        pendingVrr = originalVrr
        pendingX = originalX
        pendingY = originalY
        
        hasPendingChanges = false
        initializedMonitorName = selectedMonitor.name
    }
    
    function checkForChanges() {
        hasPendingChanges = pendingResolution !== originalResolution ||
                           Math.abs(pendingRefreshRate - originalRefreshRate) > 0.1 ||
                           Math.abs(pendingScale - originalScale) > 0.01 ||
                           pendingTransform !== originalTransform ||
                           pendingVrr !== originalVrr
    }
    
    function applyChanges() {
        if (!selectedMonitor) return
        DisplayHandler.applyMonitorSettings(
            selectedMonitor.name, pendingResolution, pendingRefreshRate,
            pendingX, pendingY, pendingScale, pendingTransform, true, pendingVrr
        )
        confirmationTimer = 15
        showConfirmation = true
        confirmTimer.start()
    }
    
    function revertChanges() {
        pendingResolution = originalResolution
        pendingRefreshRate = originalRefreshRate
        pendingScale = originalScale
        pendingTransform = originalTransform
        pendingVrr = originalVrr
        hasPendingChanges = false
        
        if (showConfirmation && selectedMonitor) {
            DisplayHandler.applyMonitorSettings(
                selectedMonitor.name, originalResolution, originalRefreshRate,
                originalX, originalY, originalScale, originalTransform, true, originalVrr
            )
        }
        showConfirmation = false
        confirmTimer.stop()
    }
    
    function keepChanges() {
        originalResolution = pendingResolution
        originalRefreshRate = pendingRefreshRate
        originalScale = pendingScale
        originalTransform = pendingTransform
        originalVrr = pendingVrr
        hasPendingChanges = false
        showConfirmation = false
        confirmTimer.stop()
    }
    
    Timer {
        id: confirmTimer
        interval: 1000
        repeat: true
        onTriggered: {
            confirmationTimer--
            if (confirmationTimer <= 0) revertChanges()
        }
    }
    
    onSelectedMonitorChanged: initializeFromMonitor()
    Component.onCompleted: initializeFromMonitor()
    
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
        clip: false
        
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
    
    component MD3Dropdown: ComboBox {
        id: dropdownRoot
        property string selectedText: ""
        
        signal selected(int index)
        
        Layout.preferredWidth: 160
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        
        currentIndex: {
            if (selectedText && model) {
                for (var i = 0; i < model.length; i++) {
                    if (model[i] === selectedText) return i
                }
            }
            return 0
        }
        
        onActivated: (idx) => selected(idx)
        
        background: Rectangle {
            radius: 12
            color: dropdownRoot.hovered ? Config.surfaceColorHover : Qt.rgba(1,1,1,0.04)
            border.width: 1
            border.color: dropdownRoot.popup.visible ? Config.accentColor : Config.borderColor
            
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
        }
        
        contentItem: Text {
            leftPadding: 12
            rightPadding: 30
            text: dropdownRoot.selectedText || dropdownRoot.currentText
            font.family: Config.fontFamily
            font.pixelSize: 13
            color: Config.foregroundColor
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        
        indicator: Text {
            x: dropdownRoot.width - width - 12
            y: (dropdownRoot.height - height) / 2
            text: dropdownRoot.popup.visible ? "expand_less" : "expand_more"
            font.family: "Material Symbols Outlined"
            font.pixelSize: 18
            color: Config.dimmedColor
        }
        
        popup: Popup {
            y: dropdownRoot.height + 4
            width: dropdownRoot.width
            implicitHeight: Math.min(contentItem.implicitHeight + 8, 200)
            padding: 4
            
            background: Rectangle {
                radius: 12
                color: Config.surfaceColor
                border.width: 1
                border.color: Config.borderColor
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.3)
                    shadowBlur: 0.5
                    shadowVerticalOffset: 4
                }
            }
            
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: dropdownRoot.popup.visible ? dropdownRoot.delegateModel : null
                currentIndex: dropdownRoot.highlightedIndex
            }
        }
        
        delegate: ItemDelegate {
            width: dropdownRoot.width - 8
            height: 40
            
            background: Rectangle {
                radius: 8
                color: parent.hovered ? Config.surfaceColorHover : "transparent"
            }
            
            contentItem: Text {
                text: modelData
                font.family: Config.fontFamily
                font.pixelSize: 13
                color: Config.foregroundColor
                verticalAlignment: Text.AlignVCenter
                leftPadding: 8
            }
        }
    }
    
    component SettingRow: RowLayout {
        property string label: ""
        property string icon: ""
        default property alias content: contentItem.data
        
        Layout.fillWidth: true
        spacing: 16
        
        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 10
            color: Qt.rgba(1,1,1,0.06)
            
            Text {
                anchors.centerIn: parent
                text: icon
                font.family: "Material Symbols Outlined"
                font.pixelSize: 20
                color: Config.dimmedColor
            }
        }
        
        Text {
            text: label
            font.family: Config.fontFamily
            font.pixelSize: 14
            color: Config.foregroundColor
            Layout.preferredWidth: 100
        }
        
        Item {
            id: contentItem
            Layout.fillWidth: true
            Layout.preferredHeight: 44
        }
    }
    
    // ========================================================================
    //                          MAIN LAYOUT
    // ========================================================================
    
    Flickable {
        anchors.fill: parent
        contentHeight: mainLayout.height + 32
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
            
            // Brightness Card
            MD3Card {
                title: "Brightness"
                icon: "brightness_6"
                accentColor: Config.accentColor
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    
                    Text {
                        text: "brightness_low"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 22
                        color: Config.dimmedColor
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: Qt.rgba(1,1,1,0.1)
                        
                        Rectangle {
                            width: parent.width * (DisplayHandler.brightness / 100)
                            height: parent.height
                            radius: 4
                            color: Config.accentColor
                            
                            Behavior on width { 
                                enabled: !brightMouse.pressed
                                NumberAnimation { duration: 100 } 
                            }
                        }
                        
                        Rectangle {
                            x: parent.width * (DisplayHandler.brightness / 100) - 10
                            y: -6
                            width: 20
                            height: 20
                            radius: 10
                            color: Config.accentColor
                            visible: brightMouse.containsMouse || brightMouse.pressed
                            
                            Behavior on x { 
                                enabled: !brightMouse.pressed
                                NumberAnimation { duration: 100 } 
                            }
                        }
                        
                        MouseArea {
                            id: brightMouse
                            anchors.fill: parent
                            anchors.margins: -10
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            
                            onPositionChanged: (mouse) => {
                                if (pressed) {
                                    var val = Math.round(Math.max(0, Math.min(100, ((mouse.x - 10) / (parent.width)) * 100)))
                                    DisplayHandler.setBrightness(val)
                                }
                            }
                            onClicked: (mouse) => {
                                var val = Math.round(Math.max(0, Math.min(100, ((mouse.x - 10) / (parent.width)) * 100)))
                                DisplayHandler.setBrightness(val)
                            }
                        }
                    }
                    
                    Text {
                        text: "brightness_high"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 22
                        color: Config.dimmedColor
                    }
                    
                    Rectangle {
                        Layout.preferredWidth: 50
                        Layout.preferredHeight: 32
                        radius: 8
                        color: Qt.rgba(1,1,1,0.06)
                        
                        Text {
                            anchors.centerIn: parent
                            text: DisplayHandler.brightness + "%"
                            font.family: Config.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Config.foregroundColor
                        }
                    }
                }
            }
            
            // Monitor Selection Card (only if multiple monitors)
            MD3Card {
                visible: DisplayHandler.monitors.length > 1
                title: "Monitors"
                icon: "monitor"
                accentColor: Config.accentColor
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Repeater {
                        model: DisplayHandler.monitors
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 48
                            radius: 12
                            color: index === selectedMonitorIndex ? 
                                   Qt.rgba(1, 0.43, 0, 0.15) : 
                                   (monMouse.containsMouse ? Config.surfaceColorHover : Qt.rgba(1,1,1,0.04))
                            border.width: index === selectedMonitorIndex ? 1 : 0
                            border.color: Config.accentColor
                            
                            Behavior on color { ColorAnimation { duration: 150 } }
                            
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                
                                Text {
                                    text: "desktop_windows"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 18
                                    color: index === selectedMonitorIndex ? Config.accentColor : Config.dimmedColor
                                }
                                
                                Text {
                                    text: modelData.name
                                    font.family: Config.fontFamily
                                    font.pixelSize: 13
                                    font.weight: index === selectedMonitorIndex ? Font.Medium : Font.Normal
                                    color: Config.foregroundColor
                                }
                            }
                            
                            MouseArea {
                                id: monMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    initializedMonitorName = ""
                                    selectedMonitorIndex = index
                                }
                            }
                        }
                    }
                }
            }
            
            // Display Settings Card
            MD3Card {
                title: "Display Settings"
                icon: "tune"
                accentColor: Config.accentColor
                
                SettingRow {
                    label: "Resolution"
                    icon: "aspect_ratio"
                    
                    MD3Dropdown {
                        model: getResolutionList()
                        selectedText: pendingResolution
                        onSelected: (idx) => {
                            pendingResolution = model[idx]
                            var rates = getRefreshRatesForResolution(pendingResolution)
                            if (rates.length > 0) pendingRefreshRate = rates[0]
                            checkForChanges()
                        }
                    }
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant }
                
                SettingRow {
                    label: "Refresh Rate"
                    icon: "speed"
                    
                    MD3Dropdown {
                        model: getRefreshRatesForResolution(pendingResolution).map(r => r.toFixed(2) + " Hz")
                        selectedText: pendingRefreshRate.toFixed(2) + " Hz"
                        onSelected: (idx) => {
                            var rates = getRefreshRatesForResolution(pendingResolution)
                            if (rates[idx]) pendingRefreshRate = rates[idx]
                            checkForChanges()
                        }
                    }
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant }
                
                SettingRow {
                    label: "Scale"
                    icon: "zoom_in"
                    
                    MD3Dropdown {
                        model: scaleOptions.map(s => (s * 100) + "%")
                        selectedText: (pendingScale * 100) + "%"
                        onSelected: (idx) => {
                            pendingScale = scaleOptions[idx]
                            checkForChanges()
                        }
                    }
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant }
                
                SettingRow {
                    label: "Rotation"
                    icon: "screen_rotation"
                    
                    MD3Dropdown {
                        model: transformOptions.map(t => t.label)
                        selectedText: transformOptions.find(t => t.value === pendingTransform)?.label || "Normal"
                        onSelected: (idx) => {
                            pendingTransform = transformOptions[idx].value
                            checkForChanges()
                        }
                    }
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant }
                
                SettingRow {
                    label: "VRR"
                    icon: "sync"
                    
                    MD3Dropdown {
                        model: vrrOptions.map(v => v.label)
                        selectedText: vrrOptions.find(v => v.value === pendingVrr)?.label || "Off"
                        onSelected: (idx) => {
                            pendingVrr = vrrOptions[idx].value
                            checkForChanges()
                        }
                    }
                }
            }
            
            // Apply Button
            Rectangle {
                visible: !showConfirmation
                Layout.fillWidth: true
                height: 52
                radius: 26
                color: hasPendingChanges ? 
                       (applyMouse.containsMouse ? Qt.lighter(Config.accentColor, 1.1) : Config.accentColor) : 
                       Qt.rgba(1,1,1,0.04)
                border.width: hasPendingChanges ? 0 : 1
                border.color: Config.borderColor
                
                Behavior on color { ColorAnimation { duration: 150 } }
                
                Text {
                    anchors.centerIn: parent
                    text: "Apply Changes"
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: hasPendingChanges ? Config.onAccent : Config.dimmedColor
                }
                
                MouseArea {
                    id: applyMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: hasPendingChanges ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: if (hasPendingChanges) applyChanges()
                }
            }
            
            // Confirmation Card
            MD3Card {
                visible: showConfirmation
                title: "Confirm Changes"
                icon: "check_circle"
                accentColor: Config.accentColor
                
                Text {
                    text: "Keep these display settings?"
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    color: Config.foregroundColor
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: timerText.width + 24
                    height: 32
                    radius: 16
                    color: Qt.rgba(1, 0.43, 0, 0.15)
                    
                    Text {
                        id: timerText
                        anchors.centerIn: parent
                        text: "Reverting in " + confirmationTimer + "s"
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Config.accentColor
                    }
                }
                
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16
                    
                    Rectangle {
                        Layout.preferredWidth: 110
                        Layout.preferredHeight: 44
                        radius: 22
                        color: revertMouse.containsMouse ? Qt.rgba(1,0.3,0.3,0.2) : Qt.rgba(1,1,1,0.06)
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Revert"
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: revertMouse.containsMouse ? Config.errorColor : Config.foregroundColor
                        }
                        
                        MouseArea {
                            id: revertMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: revertChanges()
                        }
                    }
                    
                    Rectangle {
                        Layout.preferredWidth: 110
                        Layout.preferredHeight: 44
                        radius: 22
                        color: keepMouse.containsMouse ? Qt.lighter(Config.accentColor, 1.1) : Config.accentColor
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Keep"
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: Config.onAccent
                        }
                        
                        MouseArea {
                            id: keepMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: keepChanges()
                        }
                    }
                }
            }
            
            Item { height: 8 }
        }
    }
}
