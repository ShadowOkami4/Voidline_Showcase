/*
 * ============================================================================
 *                           SOUND PANEL
 * ============================================================================
 * 
 * FILE: panels/SoundPanel.qml
 * PURPOSE: Volume control popup with device selection
 * 
 * ============================================================================
 *                              OVERVIEW
 * ============================================================================
 * 
 * This panel provides audio controls:
 *   - Volume slider for output (speakers/headphones)
 *   - Volume slider for input (microphone)
 *   - Output device selection
 *   - Input device selection
 *   - Per-app volume controls
 *   - Quick access to full Sound settings
 * 
 * Uses SoundHandler singleton for all audio operations via pactl.
 * 
 * ============================================================================
 *                         QML CONCEPTS USED
 * ============================================================================
 * 
 * TIMER:
 *   - Periodic refresh to keep volume in sync with external changes
 *   - interval: 1500 = refresh every 1.5 seconds
 *   - running: only when panel is visible
 * 
 * COMPUTED PROPERTY:
 *   - property var currentSink: { for loop to find device }
 *   - Automatically recomputes when SoundHandler.outputDevices changes
 * 
 * FLICKABLE:
 *   - Scrollable container for content
 *   - contentHeight: Total height of scrollable content
 *   - clip: true = hide content outside bounds
 * 
 * ============================================================================
 *                         SLIDER COMPONENT
 * ============================================================================
 * 
 * Slider {
 *     from: 0              <- Minimum value
 *     to: 100              <- Maximum value
 *     value: currentValue  <- Current position
 *     stepSize: 1          <- Snap to integers
 *     
 *     onMoved: {           <- Called when user drags
 *         // Apply new value
 *     }
 * }
 * 
 * ============================================================================
 */

import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import "../misc"

/*
 * ============================================================================
 *                          POPUP WINDOW
 * ============================================================================
 */
PopupWindow {
    id: soundPanel
    
    property var parentBar
    
    // Track open state separately from visibility for exit animations
    property bool isOpen: ShellState.soundPanelVisible
    property bool isClosing: false
    
    anchor.window: parentBar
    anchor.rect.x: (parentBar?.width ?? 0) / 2 - implicitWidth / 2
    anchor.rect.y: Config.barHeight + Config.topMargin + 8
    
    implicitWidth: 340
    implicitHeight: contentCol.implicitHeight + 32
    
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
        onTriggered: soundPanel.isClosing = false
    }
    
    // UI state
    property bool showDevices: false
    property bool showSources: false
    
    // Computed properties from handler
    property var currentSink: {
        for (let d of SoundHandler.outputDevices) {
            if (d.name === SoundHandler.defaultSink) return d
        }
        return { name: "", description: "No Output", volume: 0, muted: false }
    }
    
    property var currentSource: {
        for (let d of SoundHandler.inputDevices) {
            if (d.name === SoundHandler.defaultSource) return d
        }
        return { name: "", description: "No Input", volume: 0, muted: false }
    }
    
    // Focus grab
    HyprlandFocusGrab {
        active: soundPanel.visible
        windows: [soundPanel]
        onCleared: ShellState.soundPanelVisible = false
    }
    
    // Refresh on visibility
    onVisibleChanged: {
        if (visible) {
            SoundHandler.refresh()
            showDevices = false
            showSources = false
        }
    }
    
    // Periodic refresh
    Timer {
        interval: 1500
        running: soundPanel.visible
        repeat: true
        onTriggered: SoundHandler.refresh()
    }
    
    // Main container
    Rectangle {
        id: container
        anchors.fill: parent
        radius: Config.panelRadius
        color: Config.backgroundColor
        border.width: 1
        border.color: Config.borderColor
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#40000000"
            shadowBlur: 1.2
            shadowVerticalOffset: 8
            shadowHorizontalOffset: 0
        }
        
        opacity: soundPanel.isOpen ? 1 : 0
        scale: soundPanel.isOpen ? 1 : 0.9
        transformOrigin: Item.TopRight
        
        // M3 Expressive spring animation
        Behavior on opacity { NumberAnimation { duration: Config.animNormal; easing.type: Easing.OutCubic } }
        Behavior on scale { 
            NumberAnimation { 
                duration: Config.animSpring
                easing.type: Easing.OutBack
                easing.overshoot: 1.3
            } 
        }
        
        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: Config.padding
            spacing: Config.spacingLarge
            
            // Header (matches BluetoothPanel design)
            RowLayout {
                Layout.fillWidth: true
                spacing: Config.spacingLarge
                
                Rectangle {
                    width: 48
                    height: 48
                    radius: Config.cardRadius
                    color: soundPanel.currentSink.muted ? Qt.rgba(1,0.4,0.4,0.15) : Config.accentColorContainer
                    
                    Behavior on color { ColorAnimation { duration: Config.animNormal } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: soundPanel.currentSink.muted ? "volume_off" : "volume_up"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: Config.iconSizeLarge
                        color: soundPanel.currentSink.muted ? Config.errorColor : Config.accentColor
                    }
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    Text {
                        text: "Sound"
                        font.pixelSize: Config.fontSizeTitle
                        font.weight: Config.fontWeightMedium
                        font.family: Config.fontFamily
                        color: Config.foregroundColor
                    }
                    
                    Text {
                        text: soundPanel.currentSink.muted ? "Muted" : soundPanel.currentSink.volume + "%"
                        font.pixelSize: Config.fontSizeSmall
                        font.family: Config.fontFamily
                        color: Config.dimmedColor
                    }
                }
                
                // Mute toggle (Material Design Switch)
                Rectangle {
                    width: 52
                    height: 32
                    radius: 16
                    color: !soundPanel.currentSink.muted ? Config.accentColor : Config.surfaceColorActive
                    
                    Behavior on color { ColorAnimation { duration: Config.animNormal } }
                    
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: !soundPanel.currentSink.muted ? Config.onAccent : Config.dimmedColor
                        x: !soundPanel.currentSink.muted ? parent.width - width - 4 : 4
                        anchors.verticalCenter: parent.verticalCenter
                        
                        Behavior on x { NumberAnimation { duration: Config.animNormal; easing.type: Easing.OutQuart } }
                        Behavior on color { ColorAnimation { duration: Config.animNormal } }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SoundHandler.toggleSinkMute(SoundHandler.defaultSink)
                    }
                }
            }
            
            // Separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Config.borderColor
            }
            
            // Output section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Config.spacing
                
                Text {
                    text: "Output"
                    font.pixelSize: Config.fontSizeLabel
                    font.weight: Config.fontWeightMedium
                    font.family: Config.fontFamily
                    color: Config.dimmedColor
                    font.letterSpacing: 0.5
                }
                
                // Output volume card
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: outputCol.implicitHeight + 24
                    radius: Config.cardRadius
                    color: Config.surfaceColor
                    
                    ColumnLayout {
                        id: outputCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 12
                        }
                        spacing: 12
                        
                        // Device info row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            
                            Rectangle {
                                width: 40
                                height: 40
                                radius: Config.smallRadius
                                color: Config.accentColorContainer
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "speaker"
                                    color: Config.accentColor
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: Config.iconSize
                                }
                            }
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                
                                Text {
                                    text: soundPanel.currentSink.description
                                    color: Config.foregroundColor
                                    font.family: Config.fontFamily
                                    font.pixelSize: Config.fontSizeBody
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                
                                Text {
                                    text: soundPanel.currentSink.muted ? "Muted" : "Active"
                                    color: Config.dimmedColor
                                    font.family: Config.fontFamily
                                    font.pixelSize: Config.fontSizeSmall
                                }
                            }
                            
                            Text {
                                text: soundPanel.currentSink.volume + "%"
                                color: soundPanel.currentSink.muted ? Config.dimmedColor : Config.accentColor
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSizeTitle
                                font.weight: Font.DemiBold
                            }
                        }
                    
                    // Volume slider
                    Rectangle {
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: Config.surfaceColorActive
                        
                        Rectangle {
                            width: parent.width * Math.min(soundPanel.currentSink.volume / 100, 1)
                            height: parent.height
                            radius: 4
                            color: soundPanel.currentSink.muted ? Config.dimmedColor : Config.accentColor
                            
                            Behavior on width { NumberAnimation { duration: 50 } }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            
                            onClicked: (mouse) => {
                                let vol = Math.max(0, Math.min(100, Math.round((mouse.x / (width + 12)) * 100)))
                                SoundHandler.setSinkVolume(SoundHandler.defaultSink, vol)
                            }
                            
                            onPositionChanged: (mouse) => {
                                if (pressed) {
                                    let vol = Math.max(0, Math.min(100, Math.round((mouse.x / (width + 12)) * 100)))
                                    SoundHandler.setSinkVolume(SoundHandler.defaultSink, vol)
                                }
                            }
                        }
                    }
                    
                    // Device selector
                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: Config.smallRadius
                        color: deviceMouse.containsMouse ? Config.surfaceColorHover : Config.surfaceColor
                        visible: SoundHandler.outputDevices.length > 1
                        
                        Behavior on color { ColorAnimation { duration: Config.animFast } }
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: Config.spacing
                            
                            Text {
                                text: "speaker"
                                color: Config.dimmedColor
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: Config.iconSize
                            }
                            
                            Text {
                                Layout.fillWidth: true
                                text: soundPanel.currentSink.description
                                color: Config.dimmedColor
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSizeSmall
                                elide: Text.ElideRight
                            }
                            
                            Text {
                                text: soundPanel.showDevices ? "expand_less" : "expand_more"
                                color: Config.dimmedColor
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 14
                            }
                        }
                        
                        MouseArea {
                            id: deviceMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: soundPanel.showDevices = !soundPanel.showDevices
                        }
                    }
                    
                    // Device list
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: soundPanel.showDevices
                        
                        Repeater {
                            model: SoundHandler.outputDevices
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 48
                                radius: Config.smallRadius
                                color: modelData.name === SoundHandler.defaultSink ?
                                       Config.accentColorContainer :
                                       (sinkMouse.containsMouse ? Config.surfaceColorHover : "transparent")
                                
                                Behavior on color { ColorAnimation { duration: Config.animFast } }
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: Config.spacing
                                    
                                    Text {
                                        text: modelData.name === SoundHandler.defaultSink ? "check" : "speaker"
                                        color: modelData.name === SoundHandler.defaultSink ? Config.accentColor : Config.dimmedColor
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: Config.iconSize
                                    }
                                    
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.description
                                        color: Config.foregroundColor
                                        font.family: Config.fontFamily
                                        font.pixelSize: Config.fontSizeSmall
                                        elide: Text.ElideRight
                                    }
                                }
                                
                                MouseArea {
                                    id: sinkMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        SoundHandler.setDefaultSink(modelData.name)
                                        soundPanel.showDevices = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
            }
            
            // Input section
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: inputCol.implicitHeight + 24
                radius: Config.cardRadius
                color: Config.surfaceColor
                
                ColumnLayout {
                    id: inputCol
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 12
                    }
                    spacing: 10
                    
                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        Rectangle {
                            width: 44
                            height: 44
                            radius: Config.smallRadius
                            color: soundPanel.currentSource.muted ? Qt.rgba(1,0.4,0.4,0.15) : Config.surfaceColorActive
                            
                            Behavior on color { ColorAnimation { duration: Config.animNormal } }
                            
                            Text {
                                anchors.centerIn: parent
                                text: soundPanel.currentSource.muted ? "mic_off" : "mic"
                                color: soundPanel.currentSource.muted ? Config.errorColor : Config.foregroundColor
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: Config.iconSizeLarge
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SoundHandler.toggleSourceMute(SoundHandler.defaultSource)
                            }
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            
                            Text {
                                text: "Input"
                                color: Config.foregroundColor
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSizeBody
                                font.weight: Font.Medium
                            }
                            
                            Text {
                                text: soundPanel.currentSource.description
                                color: Config.dimmedColor
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSizeSmall
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                        
                        Text {
                            text: soundPanel.currentSource.volume + "%"
                            color: soundPanel.currentSource.muted ? Config.dimmedColor : Config.foregroundColor
                            font.family: Config.fontFamily
                            font.pixelSize: Config.fontSizeTitle
                            font.weight: Font.DemiBold
                        }
                    }
                    
                    // Volume slider
                    Rectangle {
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: Config.surfaceColorActive
                        
                        Rectangle {
                            width: parent.width * Math.min(soundPanel.currentSource.volume / 100, 1)
                            height: parent.height
                            radius: 4
                            color: soundPanel.currentSource.muted ? Config.dimmedColor : Config.foregroundColor
                            
                            Behavior on width { NumberAnimation { duration: 50 } }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            
                            onClicked: (mouse) => {
                                let vol = Math.max(0, Math.min(100, Math.round((mouse.x / (width + 12)) * 100)))
                                SoundHandler.setSourceVolume(SoundHandler.defaultSource, vol)
                            }
                            
                            onPositionChanged: (mouse) => {
                                if (pressed) {
                                    let vol = Math.max(0, Math.min(100, Math.round((mouse.x / (width + 12)) * 100)))
                                    SoundHandler.setSourceVolume(SoundHandler.defaultSource, vol)
                                }
                            }
                        }
                    }
                    
                    // Source selector
                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: Config.smallRadius
                        color: sourceMouse.containsMouse ? Config.surfaceColorHover : Config.surfaceColor
                        visible: SoundHandler.inputDevices.length > 1
                        
                        Behavior on color { ColorAnimation { duration: Config.animFast } }
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: Config.spacing
                            
                            Text {
                                text: "mic"
                                color: Config.dimmedColor
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: Config.iconSize
                            }
                            
                            Text {
                                Layout.fillWidth: true
                                text: soundPanel.currentSource.description
                                color: Config.dimmedColor
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSizeSmall
                                elide: Text.ElideRight
                            }
                            
                            Text {
                                text: soundPanel.showSources ? "expand_less" : "expand_more"
                                color: Config.dimmedColor
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: Config.iconSize
                            }
                        }
                        
                        MouseArea {
                            id: sourceMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: soundPanel.showSources = !soundPanel.showSources
                        }
                    }
                    
                    // Source list
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: soundPanel.showSources
                        
                        Repeater {
                            model: SoundHandler.inputDevices
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 48
                                radius: Config.smallRadius
                                color: modelData.name === SoundHandler.defaultSource ?
                                       Config.accentColorContainer :
                                       (srcMouse.containsMouse ? Config.surfaceColorHover : "transparent")
                                
                                Behavior on color { ColorAnimation { duration: Config.animFast } }
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: Config.spacing
                                    
                                    Text {
                                        text: modelData.name === SoundHandler.defaultSource ? "check" : "mic"
                                        color: modelData.name === SoundHandler.defaultSource ? Config.accentColor : Config.dimmedColor
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: Config.iconSize
                                    }
                                    
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.description
                                        color: Config.foregroundColor
                                        font.family: Config.fontFamily
                                        font.pixelSize: Config.fontSizeSmall
                                        elide: Text.ElideRight
                                    }
                                }
                                
                                MouseArea {
                                    id: srcMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        SoundHandler.setDefaultSource(modelData.name)
                                        soundPanel.showSources = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Settings button
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: Config.cardRadius
                color: settingsMouse.containsMouse ? Config.surfaceColorHover : Config.surfaceColor
                
                Behavior on color { ColorAnimation { duration: Config.animFast } }
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: Config.spacing
                    
                    Text {
                        text: "tune"
                        color: settingsMouse.containsMouse ? Config.foregroundColor : Config.dimmedColor
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: Config.iconSize
                        
                        Behavior on color { ColorAnimation { duration: Config.animFast } }
                    }
                    
                    Text {
                        text: "Sound Settings"
                        color: settingsMouse.containsMouse ? Config.foregroundColor : Config.dimmedColor
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSizeBody
                        font.weight: Font.Medium
                        
                        Behavior on color { ColorAnimation { duration: Config.animFast } }
                    }
                }
                
                MouseArea {
                    id: settingsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        ShellState.soundPanelVisible = false
                        ShellState.openSettings("sound")
                    }
                }
            }
        }
    }
}
