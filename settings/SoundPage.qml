/*
 * ============================================================================
 *                            SOUND SETTINGS
 * ============================================================================
 *
 * FILE: settings/SoundPage.qml
 * PURPOSE: UI for audio settings and per-application volume/device controls
 *
 * FEATURES:
 *   - Output device selection and volume control
 *   - Input device selection and volume control
 *   - Per-application volume control
 *   - Per-application output device routing
 *   - Recording application controls
 *
 * NOTE: Uses PipeWire/PulseAudio via pactl commands
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../misc"

Item {
    id: root
    
    // Refresh on visibility
    Component.onCompleted: SoundHandler.refresh()
    
    // ========================================================================
    //                          MD3 COMPONENTS
    // ========================================================================
    
    // MD3 Card Component
    component MD3Card: Rectangle {
        default property alias content: cardContent.data
        property string title: ""
        property string icon: ""
        property color accentColor: Config.accentColor
        property bool collapsible: false
        property bool collapsed: false
        
        Layout.fillWidth: true
        implicitHeight: collapsed ? 72 : cardContent.implicitHeight + (title ? 88 : 32)
        radius: 16
        color: Config.surfaceColor
        border.width: 1
        border.color: Config.borderColor
        clip: true
        
        Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        
        ColumnLayout {
            id: cardContent
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: title ? 72 : 16
            anchors.bottomMargin: 16
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 12
            opacity: collapsed ? 0 : 1
            visible: !collapsed
            
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
        
        // Card header
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
            
            // Collapse button
            Rectangle {
                visible: collapsible
                width: 32
                height: 32
                radius: 16
                color: collapseMouse.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                
                Text {
                    anchors.centerIn: parent
                    text: collapsed ? "expand_more" : "expand_less"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: Config.dimmedColor
                }
                
                MouseArea {
                    id: collapseMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: collapsed = !collapsed
                }
            }
        }
    }
    
    // MD3 Device Item with full controls
    component DeviceItem: Rectangle {
        id: deviceItemRoot
        property string name: ""
        property string icon: "speaker"
        property bool isActive: false
        property bool isMuted: false
        property int volume: 100
        property color accentColor: Config.accentColor
        
        signal deviceClicked()
        signal deviceVolumeChanged(int vol)
        signal deviceMuteToggled()
        
        Layout.fillWidth: true
        height: 72
        radius: 12
        color: isActive ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.1) : 
               (deviceMouse.containsMouse ? Config.surfaceColorHover : "transparent")
        border.width: isActive ? 1 : 0
        border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3)
        
        Behavior on color { ColorAnimation { duration: 150 } }
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 16
            
            // Device icon with click to select
            Rectangle {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                radius: 12
                color: isActive ? accentColor : Qt.rgba(1,1,1,0.06)
                
                Behavior on color { ColorAnimation { duration: 150 } }
                
                Text {
                    anchors.centerIn: parent
                    text: icon
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 24
                    color: isActive ? Config.onAccent : Config.dimmedColor
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: deviceItemRoot.deviceClicked()
                }
            }
            
            // Name and slider
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Text {
                    text: name
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    font.weight: isActive ? Font.Medium : Font.Normal
                    color: Config.foregroundColor
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                
                // Volume slider
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: Qt.rgba(1,1,1,0.1)
                        
                        Rectangle {
                            width: parent.width * (volume / 100)
                            height: parent.height
                            radius: 3
                            color: isMuted ? Config.dimmedColor : accentColor
                            
                            Behavior on width { 
                                enabled: !sliderMouse.pressed
                                NumberAnimation { duration: 100 } 
                            }
                        }
                        
                        // Slider handle
                        Rectangle {
                            x: parent.width * (volume / 100) - 8
                            y: -5
                            width: 16
                            height: 16
                            radius: 8
                            color: isMuted ? Config.dimmedColor : accentColor
                            visible: sliderMouse.containsMouse || sliderMouse.pressed
                            
                            Behavior on x { 
                                enabled: !sliderMouse.pressed
                                NumberAnimation { duration: 100 } 
                            }
                        }
                        
                        MouseArea {
                            id: sliderMouse
                            anchors.fill: parent
                            anchors.margins: -8
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            
                            onPressed: (mouse) => updateVolume(mouse)
                            onPositionChanged: (mouse) => { if (pressed) updateVolume(mouse) }
                            
                            function updateVolume(mouse) {
                                var vol = Math.round(((mouse.x - 8) / (parent.width)) * 100)
                                vol = Math.max(0, Math.min(100, vol))
                                deviceItemRoot.deviceVolumeChanged(vol)
                            }
                        }
                    }
                    
                    Text {
                        text: volume + "%"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Config.dimmedColor
                        Layout.preferredWidth: 40
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
            
            // Mute button
            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 20
                color: muteMouse.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                
                Behavior on color { ColorAnimation { duration: 150 } }
                
                Text {
                    anchors.centerIn: parent
                    text: isMuted ? "volume_off" : "volume_up"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 22
                    color: isMuted ? Config.errorColor : Config.dimmedColor
                }
                
                MouseArea {
                    id: muteMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: deviceItemRoot.deviceMuteToggled()
                }
            }
        }
        
        MouseArea {
            id: deviceMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }
    
    // Enhanced App Volume Item with device selection
    component AppStreamItem: Rectangle {
        id: appStreamRoot
        property string name: ""
        property string appIcon: "play_arrow"
        property int volume: 100
        property bool isMuted: false
        property int streamIndex: 0
        property int currentSinkIndex: -1
        property bool isPlayback: true  // true for playback, false for recording
        property bool showDeviceSelector: false
        
        Layout.fillWidth: true
        implicitHeight: showDeviceSelector ? 110 : 64
        radius: 12
        color: appMouse.containsMouse ? Config.surfaceColorHover : "transparent"
        
        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on implicitHeight { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                // App icon
                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 10
                    color: Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.15)
                    
                    Text {
                        anchors.centerIn: parent
                        text: appStreamRoot.getAppIcon(name)
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: Config.accentColor
                    }
                }
                
                // App name
                Text {
                    text: name || "Application"
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: Config.foregroundColor
                    elide: Text.ElideRight
                    Layout.preferredWidth: 120
                }
                
                // Volume slider
                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: Qt.rgba(1,1,1,0.1)
                    
                    Rectangle {
                        width: parent.width * (volume / 100)
                        height: parent.height
                        radius: 3
                        color: isMuted ? Config.dimmedColor : Config.accentColor
                        
                        Behavior on width { NumberAnimation { duration: 100 } }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        onPressed: (mouse) => updateVol(mouse)
                        onPositionChanged: (mouse) => { if (pressed) updateVol(mouse) }
                        
                        function updateVol(mouse) {
                            var vol = Math.round((mouse.x / parent.width) * 100)
                            vol = Math.max(0, Math.min(100, vol))
                            if (isPlayback) {
                                SoundHandler.setSinkInputVolume(streamIndex, vol)
                            } else {
                                SoundHandler.setSourceOutputVolume(streamIndex, vol)
                            }
                        }
                    }
                }
                
                // Volume percentage
                Text {
                    text: volume + "%"
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: Config.dimmedColor
                    Layout.preferredWidth: 40
                    horizontalAlignment: Text.AlignRight
                }
                
                // Mute button
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    color: appMuteMouse.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                    
                    Text {
                        anchors.centerIn: parent
                        text: isMuted ? "volume_off" : "volume_up"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 18
                        color: isMuted ? Config.errorColor : Config.dimmedColor
                    }
                    
                    MouseArea {
                        id: appMuteMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (isPlayback) {
                                SoundHandler.toggleSinkInputMute(streamIndex)
                            } else {
                                SoundHandler.toggleSourceOutputMute(streamIndex)
                            }
                        }
                    }
                }
                
                // Device selector button
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    color: showDeviceSelector ? Config.accentColorContainer : 
                           (deviceBtnMouse.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent")
                    
                    Text {
                        anchors.centerIn: parent
                        text: isPlayback ? "speaker" : "mic"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 18
                        color: showDeviceSelector ? Config.accentColor : Config.dimmedColor
                    }
                    
                    MouseArea {
                        id: deviceBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: showDeviceSelector = !showDeviceSelector
                    }
                }
            }
            
            // Device selector dropdown
            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 8
                color: Config.surfaceColorActive
                visible: showDeviceSelector
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 8
                    
                    Text {
                        text: isPlayback ? "Output:" : "Input:"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: Config.dimmedColor
                    }
                    
                    // Device list - horizontal scroll
                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: deviceRow.width
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        
                        Row {
                            id: deviceRow
                            spacing: 6
                            height: parent.height
                            
                            Repeater {
                                model: isPlayback ? SoundHandler.outputDevices : SoundHandler.inputDevices
                                
                                Rectangle {
                                    property bool isCurrentDevice: isPlayback ? 
                                        (modelData.name === SoundHandler.defaultSink) :
                                        (modelData.name === SoundHandler.defaultSource)
                                    
                                    width: deviceText.implicitWidth + 20
                                    height: 28
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: 14
                                    color: isCurrentDevice ? Config.accentColor : 
                                           (deviceSelectMouse.containsMouse ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.08))
                                    
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    
                                    Text {
                                        id: deviceText
                                        anchors.centerIn: parent
                                        text: appStreamRoot.getShortDeviceName(modelData.description || modelData.name)
                                        font.family: Config.fontFamily
                                        font.pixelSize: 12
                                        color: isCurrentDevice ? Config.onAccent : Config.foregroundColor
                                    }
                                    
                                    MouseArea {
                                        id: deviceSelectMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (isPlayback) {
                                                SoundHandler.moveSinkInput(streamIndex, modelData.name)
                                            } else {
                                                SoundHandler.moveSourceOutput(streamIndex, modelData.name)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        MouseArea {
            id: appMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
        
        // Helper function to get app-specific icons
        function getAppIcon(appName) {
            let lower = (appName || "").toLowerCase()
            if (lower.includes("firefox")) return "public"
            if (lower.includes("chrome") || lower.includes("chromium")) return "language"
            if (lower.includes("spotify")) return "music_note"
            if (lower.includes("discord")) return "forum"
            if (lower.includes("slack")) return "tag"
            if (lower.includes("telegram")) return "send"
            if (lower.includes("vlc") || lower.includes("mpv") || lower.includes("video")) return "movie"
            if (lower.includes("game") || lower.includes("steam")) return "sports_esports"
            if (lower.includes("obs")) return "videocam"
            if (lower.includes("music") || lower.includes("audio")) return "music_note"
            if (lower.includes("zoom") || lower.includes("meet") || lower.includes("teams")) return "video_call"
            if (lower.includes("pipewire") || lower.includes("pulse")) return "settings"
            if (isPlayback) return "play_arrow"
            return "mic"
        }
        
        // Helper to shorten device names
        function getShortDeviceName(name) {
            if (!name) return "Unknown"
            if (name.length > 20) {
                // Try to extract meaningful part
                if (name.includes("Speaker")) return "Speaker"
                if (name.includes("Headphone")) return "Headphones"
                if (name.includes("HDMI")) return "HDMI"
                if (name.includes("Bluetooth") || name.includes("bluez")) return "Bluetooth"
                if (name.includes("ULT")) return "ULT WEAR"
                if (name.includes("USB")) return "USB Audio"
                if (name.includes("Microphone")) return "Mic"
                if (name.includes("Digital")) return "Digital"
                if (name.includes("Analog")) return "Analog"
                return name.substring(0, 16) + "…"
            }
            return name
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
            
            // Header with refresh button
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: "Sound Settings"
                    font.family: Config.fontFamily
                    font.pixelSize: 24
                    font.weight: Font.Medium
                    color: Config.foregroundColor
                }
                
                Item { Layout.fillWidth: true }
                
                Rectangle {
                    width: 40
                    height: 40
                    radius: 20
                    color: refreshMouse.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "refresh"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 22
                        color: Config.dimmedColor
                    }
                    
                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SoundHandler.refresh()
                    }
                }
            }
            
            // Output Devices Card
            MD3Card {
                title: "Output Devices"
                icon: "speaker"
                accentColor: Config.accentColor
                collapsible: true
                
                Repeater {
                    model: SoundHandler.outputDevices
                    
                    DeviceItem {
                        name: modelData.description || modelData.name
                        icon: {
                            let n = (modelData.name || "").toLowerCase()
                            if (n.includes("hdmi")) return "tv"
                            if (n.includes("headphone") || n.includes("bluez") || n.includes("bluetooth")) return "headphones"
                            if (n.includes("usb")) return "usb"
                            return "speaker"
                        }
                        isActive: modelData.name === SoundHandler.defaultSink
                        isMuted: modelData.muted
                        volume: modelData.volume
                        accentColor: Config.accentColor
                        
                        onDeviceClicked: SoundHandler.setDefaultSink(modelData.name)
                        onDeviceVolumeChanged: (vol) => SoundHandler.setSinkVolume(modelData.name, vol)
                        onDeviceMuteToggled: SoundHandler.toggleSinkMute(modelData.name)
                    }
                }
                
                Text {
                    visible: SoundHandler.outputDevices.length === 0
                    text: "No output devices found"
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    color: Config.dimmedColor
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 16
                    Layout.bottomMargin: 16
                }
            }
            
            // Input Devices Card
            MD3Card {
                title: "Input Devices"
                icon: "mic"
                accentColor: Config.accentColor
                collapsible: true
                
                Repeater {
                    model: SoundHandler.inputDevices
                    
                    DeviceItem {
                        name: modelData.description || modelData.name
                        icon: "mic"
                        isActive: modelData.name === SoundHandler.defaultSource
                        isMuted: modelData.muted
                        volume: modelData.volume
                        accentColor: Config.accentColor
                        
                        onDeviceClicked: SoundHandler.setDefaultSource(modelData.name)
                        onDeviceVolumeChanged: (vol) => SoundHandler.setSourceVolume(modelData.name, vol)
                        onDeviceMuteToggled: SoundHandler.toggleSourceMute(modelData.name)
                    }
                }
                
                Text {
                    visible: SoundHandler.inputDevices.length === 0
                    text: "No input devices found"
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    color: Config.dimmedColor
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 16
                    Layout.bottomMargin: 16
                }
            }
            
            // Applications Playing Audio Card
            MD3Card {
                visible: SoundHandler.playbackStreams.length > 0
                title: "Applications Playing"
                icon: "play_circle"
                accentColor: Config.accentColor
                
                Text {
                    text: "Click the speaker icon to route app to a different output"
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    color: Config.dimmedColor
                    Layout.bottomMargin: 4
                }
                
                Repeater {
                    model: SoundHandler.playbackStreams
                    
                    AppStreamItem {
                        name: modelData.name
                        volume: modelData.volume
                        isMuted: modelData.muted
                        streamIndex: modelData.index
                        currentSinkIndex: modelData.sinkIndex || -1
                        isPlayback: true
                    }
                }
            }
            
            // Applications Recording Audio Card
            MD3Card {
                visible: SoundHandler.recordingStreams.length > 0
                title: "Applications Recording"
                icon: "mic"
                accentColor: "#EF5350"  // Red accent for recording
                
                Text {
                    text: "Click the mic icon to route app to a different input"
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    color: Config.dimmedColor
                    Layout.bottomMargin: 4
                }
                
                Repeater {
                    model: SoundHandler.recordingStreams
                    
                    AppStreamItem {
                        name: modelData.name
                        volume: modelData.volume
                        isMuted: modelData.muted
                        streamIndex: modelData.index
                        currentSinkIndex: modelData.sourceIndex || -1
                        isPlayback: false
                    }
                }
            }
            
            // No Active Streams Message
            Rectangle {
                visible: SoundHandler.playbackStreams.length === 0 && SoundHandler.recordingStreams.length === 0
                Layout.fillWidth: true
                height: 120
                radius: 16
                color: Config.surfaceColor
                border.width: 1
                border.color: Config.borderColor
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    
                    Text {
                        text: "apps"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 40
                        color: Config.dimmedColor
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    Text {
                        text: "No applications currently using audio"
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        color: Config.dimmedColor
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    Text {
                        text: "Play some audio to see per-app controls"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: Qt.rgba(Config.dimmedColor.r, Config.dimmedColor.g, Config.dimmedColor.b, 0.6)
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
            
            Item { height: 16 }
        }
    }
    
    // Auto-refresh timer for stream updates
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: SoundHandler.refresh()
    }
}
