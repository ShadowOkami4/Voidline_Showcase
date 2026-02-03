/*
 * ============================================================================
 *                        DISPLAY SETTINGS - NEW DESIGN
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import "../../misc"
import "../../Handlers"

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
            spacing: 12
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
    
    component SettingRow: RowLayout {
        property string label: ""
        property string icon: ""
        default property alias rowContent: contentHolder.data
        
        Layout.fillWidth: true
        height: 40
        spacing: 12
        
        Text {
            text: icon
            font.family: "Material Symbols Rounded"
            font.pixelSize: 18
            color: Config.dimmedColor
        }
        
        Text {
            text: label
            font.family: Config.fontFamily
            font.pixelSize: 13
            color: Config.foregroundColor
            Layout.fillWidth: true
        }
        
        Item {
            id: contentHolder
            Layout.preferredWidth: 140
            Layout.preferredHeight: 36
        }
    }
    
    component Dropdown: ComboBox {
        id: dropdown
        property string selectedText: ""
        signal selected(int index)
        
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
            radius: 8
            color: dropdown.hovered ? Config.surfaceColorHover : Qt.rgba(1,1,1,0.04)
            border.width: 1
            border.color: dropdown.popup.visible ? Config.accentColor : Config.borderColor
        }
        
        contentItem: Text {
            leftPadding: 10
            rightPadding: 24
            text: dropdown.selectedText || dropdown.currentText
            font.family: Config.fontFamily
            font.pixelSize: 12
            color: Config.foregroundColor
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        
        indicator: Text {
            x: dropdown.width - width - 8
            y: (dropdown.height - height) / 2
            text: dropdown.popup.visible ? "expand_less" : "expand_more"
            font.family: "Material Symbols Rounded"
            font.pixelSize: 16
            color: Config.dimmedColor
        }
        
        popup: Popup {
            y: dropdown.height + 4
            width: dropdown.width
            implicitHeight: Math.min(contentItem.implicitHeight + 8, 180)
            padding: 4
            
            background: Rectangle {
                radius: 10
                color: Config.surfaceColor
                border.width: 1
                border.color: Config.borderColor
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.25)
                    shadowBlur: 0.4
                    shadowVerticalOffset: 3
                }
            }
            
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: dropdown.popup.visible ? dropdown.delegateModel : null
                currentIndex: dropdown.highlightedIndex
            }
        }
        
        delegate: ItemDelegate {
            width: dropdown.width - 8
            height: 32
            
            background: Rectangle {
                radius: 6
                color: parent.hovered ? Config.surfaceColorHover : "transparent"
            }
            
            contentItem: Text {
                text: modelData
                font.family: Config.fontFamily
                font.pixelSize: 12
                color: Config.foregroundColor
                verticalAlignment: Text.AlignVCenter
                leftPadding: 6
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
            
            // Brightness Section
            Section {
                title: "BRIGHTNESS"
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14
                    
                    Text {
                        text: "brightness_low"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 20
                        color: Config.dimmedColor
                    }
                    
                    Item {
                        Layout.fillWidth: true
                        height: 32
                        
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 4
                            radius: 2
                            color: Qt.rgba(1,1,1,0.08)
                            
                            Rectangle {
                                width: parent.width * (DisplayHandler.brightness / 100)
                                height: parent.height
                                radius: 2
                                color: Config.accentColor
                                
                                Behavior on width { 
                                    enabled: !brightMouse.pressed
                                    NumberAnimation { duration: 80 } 
                                }
                            }
                        }
                        
                        Rectangle {
                            x: parent.width * (DisplayHandler.brightness / 100) - 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16
                            radius: 8
                            color: Config.accentColor
                            scale: brightMouse.pressed ? 1.15 : (brightMouse.containsMouse ? 1.08 : 1)
                            
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }
                        
                        MouseArea {
                            id: brightMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            
                            onPressed: (mouse) => setBright(mouse)
                            onPositionChanged: (mouse) => { if (pressed) setBright(mouse) }
                            
                            function setBright(mouse) {
                                var val = Math.round((mouse.x / width) * 100)
                                val = Math.max(0, Math.min(100, val))
                                DisplayHandler.setBrightness(val)
                            }
                        }
                    }
                    
                    Text {
                        text: "brightness_high"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 20
                        color: Config.dimmedColor
                    }
                    
                    Text {
                        text: DisplayHandler.brightness + "%"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Config.foregroundColor
                        Layout.preferredWidth: 36
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
            
            // Monitor Selection (if multiple)
            Section {
                visible: DisplayHandler.monitors.length > 1
                title: "MONITORS"
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Repeater {
                        model: DisplayHandler.monitors
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: 8
                            color: index === selectedMonitorIndex
                                   ? Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.15)
                                   : (monMouse.containsMouse ? Config.surfaceColorHover : Qt.rgba(1,1,1,0.04))
                            border.width: index === selectedMonitorIndex ? 1 : 0
                            border.color: Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.4)
                            
                            Behavior on color { ColorAnimation { duration: 100 } }
                            
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                
                                Text {
                                    text: "desktop_windows"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 16
                                    color: index === selectedMonitorIndex ? Config.accentColor : Config.dimmedColor
                                }
                                
                                Text {
                                    text: modelData.name
                                    font.family: Config.fontFamily
                                    font.pixelSize: 12
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
            
            // Display Settings
            Section {
                title: "DISPLAY"
                
                SettingRow {
                    label: "Resolution"
                    icon: "aspect_ratio"
                    
                    Dropdown {
                        anchors.fill: parent
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
                
                SettingRow {
                    label: "Refresh Rate"
                    icon: "speed"
                    
                    Dropdown {
                        anchors.fill: parent
                        model: getRefreshRatesForResolution(pendingResolution).map(r => r.toFixed(2) + " Hz")
                        selectedText: pendingRefreshRate.toFixed(2) + " Hz"
                        onSelected: (idx) => {
                            var rates = getRefreshRatesForResolution(pendingResolution)
                            if (rates[idx]) pendingRefreshRate = rates[idx]
                            checkForChanges()
                        }
                    }
                }
                
                SettingRow {
                    label: "Scale"
                    icon: "zoom_in"
                    
                    Dropdown {
                        anchors.fill: parent
                        model: scaleOptions.map(s => (s * 100) + "%")
                        selectedText: (pendingScale * 100) + "%"
                        onSelected: (idx) => {
                            pendingScale = scaleOptions[idx]
                            checkForChanges()
                        }
                    }
                }
                
                SettingRow {
                    label: "Rotation"
                    icon: "screen_rotation"
                    
                    Dropdown {
                        anchors.fill: parent
                        model: transformOptions.map(t => t.label)
                        selectedText: transformOptions.find(t => t.value === pendingTransform)?.label || "Normal"
                        onSelected: (idx) => {
                            pendingTransform = transformOptions[idx].value
                            checkForChanges()
                        }
                    }
                }
                
                SettingRow {
                    label: "VRR"
                    icon: "sync"
                    
                    Dropdown {
                        anchors.fill: parent
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
                height: 44
                radius: 22
                color: hasPendingChanges
                       ? (applyMouse.containsMouse ? Qt.lighter(Config.accentColor, 1.1) : Config.accentColor)
                       : Qt.rgba(1,1,1,0.04)
                border.width: hasPendingChanges ? 0 : 1
                border.color: Config.borderColor
                
                Behavior on color { ColorAnimation { duration: 100 } }
                
                Text {
                    anchors.centerIn: parent
                    text: "Apply Changes"
                    font.family: Config.fontFamily
                    font.pixelSize: 13
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
            
            // Confirmation Section
            Section {
                visible: showConfirmation
                title: "CONFIRM CHANGES"
                
                Text {
                    text: "Keep these display settings?"
                    font.family: Config.fontFamily
                    font.pixelSize: 13
                    color: Config.foregroundColor
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: timerText.width + 20
                    height: 28
                    radius: 14
                    color: Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.15)
                    
                    Text {
                        id: timerText
                        anchors.centerIn: parent
                        text: "Reverting in " + confirmationTimer + "s"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Config.accentColor
                    }
                }
                
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12
                    
                    Rectangle {
                        width: 90
                        height: 36
                        radius: 18
                        color: revertMouse.containsMouse ? Qt.rgba(1,0.3,0.3,0.15) : Qt.rgba(1,1,1,0.06)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Revert"
                            font.family: Config.fontFamily
                            font.pixelSize: 12
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
                        width: 90
                        height: 36
                        radius: 18
                        color: keepMouse.containsMouse ? Qt.lighter(Config.accentColor, 1.1) : Config.accentColor
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Keep"
                            font.family: Config.fontFamily
                            font.pixelSize: 12
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
        }
    }
}
