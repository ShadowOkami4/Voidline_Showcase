/*
 * ============================================================================
 *                         SOUND SETTINGS - NEW DESIGN
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../misc"
import "../../Handlers"

Item {
    id: root
    
    Component.onCompleted: SoundHandler.refresh()
    
    // ========================================================================
    //                          REUSABLE COMPONENTS  
    // ========================================================================
    
    // Section container
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
            spacing: 8
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
    
    // Device row with clean slider
    component DeviceRow: Rectangle {
        id: deviceRoot
        property string label: ""
        property string icon: "speaker"
        property bool active: false
        property bool muted: false
        property int volume: 100
        
        signal clicked()
        signal volumeAdjusted(int vol)
        signal muteToggled()
        
        Layout.fillWidth: true
        height: 56
        radius: 10
        color: active ? Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.12) 
                      : (deviceMouse.containsMouse ? Config.surfaceColorHover : "transparent")
        
        Behavior on color { ColorAnimation { duration: 120 } }
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12
            
            // Icon button
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 8
                color: active ? Config.accentColor : Qt.rgba(1,1,1,0.06)
                
                Text {
                    anchors.centerIn: parent
                    text: deviceRoot.icon
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 18
                    color: active ? Config.onAccent : Config.dimmedColor
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: deviceRoot.clicked()
                }
            }
            
            // Name
            Text {
                text: label
                font.family: Config.fontFamily
                font.pixelSize: 13
                color: Config.foregroundColor
                elide: Text.ElideRight
                Layout.preferredWidth: 140
            }
            
            // Slider track
            Item {
                Layout.fillWidth: true
                height: 36
                
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Qt.rgba(1,1,1,0.08)
                    
                    Rectangle {
                        width: parent.width * (volume / 100)
                        height: parent.height
                        radius: 2
                        color: muted ? Config.dimmedColor : Config.accentColor
                        
                        Behavior on width { 
                            enabled: !sliderArea.pressed
                            NumberAnimation { duration: 80 } 
                        }
                    }
                }
                
                // Thumb
                Rectangle {
                    x: parent.width * (volume / 100) - 7
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    height: 14
                    radius: 7
                    color: muted ? Config.dimmedColor : Config.accentColor
                    scale: sliderArea.pressed ? 1.15 : (sliderArea.containsMouse ? 1.08 : 1)
                    
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on x { 
                        enabled: !sliderArea.pressed
                        NumberAnimation { duration: 80 } 
                    }
                }
                
                MouseArea {
                    id: sliderArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onPressed: (mouse) => updateVol(mouse)
                    onPositionChanged: (mouse) => { if (pressed) updateVol(mouse) }
                    
                    function updateVol(mouse) {
                        let v = Math.round((mouse.x / width) * 100)
                        v = Math.max(0, Math.min(100, v))
                        deviceRoot.volume = v
                        deviceRoot.volumeAdjusted(v)
                    }
                }
            }
            
            // Volume text
            Text {
                text: volume + "%"
                font.family: Config.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Config.dimmedColor
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
            }
            
            // Mute button
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 8
                color: muteMouse.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                
                Text {
                    anchors.centerIn: parent
                    text: muted ? "volume_off" : "volume_up"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 18
                    color: muted ? Config.errorColor : Config.dimmedColor
                }
                
                MouseArea {
                    id: muteMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: deviceRoot.muteToggled()
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
    
    // App stream row
    component AppRow: Rectangle {
        id: appRoot
        property string name: ""
        property int volume: 100
        property bool muted: false
        property int streamIndex: 0
        property bool isPlayback: true
        
        Layout.fillWidth: true
        height: 48
        radius: 8
        color: appMouse.containsMouse ? Qt.rgba(1,1,1,0.04) : "transparent"
        
        Behavior on color { ColorAnimation { duration: 100 } }
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 10
            
            // App icon
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 6
                color: Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.12)
                
                Text {
                    anchors.centerIn: parent
                    text: appRoot.getIcon()
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: Config.accentColor
                }
            }
            
            // Name
            Text {
                text: name || "App"
                font.family: Config.fontFamily
                font.pixelSize: 12
                color: Config.foregroundColor
                elide: Text.ElideRight
                Layout.preferredWidth: 100
            }
            
            // Slider
            Item {
                Layout.fillWidth: true
                height: 28
                
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 3
                    radius: 1.5
                    color: Qt.rgba(1,1,1,0.06)
                    
                    Rectangle {
                        width: parent.width * (volume / 100)
                        height: parent.height
                        radius: 1.5
                        color: muted ? Config.dimmedColor : Config.accentColor
                    }
                }
                
                Rectangle {
                    x: parent.width * (volume / 100) - 5
                    anchors.verticalCenter: parent.verticalCenter
                    width: 10
                    height: 10
                    radius: 5
                    color: muted ? Config.dimmedColor : Config.accentColor
                    visible: appSlider.containsMouse || appSlider.pressed
                }
                
                MouseArea {
                    id: appSlider
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onPressed: (mouse) => setVol(mouse)
                    onPositionChanged: (mouse) => { if (pressed) setVol(mouse) }
                    
                    function setVol(mouse) {
                        let v = Math.round((mouse.x / width) * 100)
                        v = Math.max(0, Math.min(100, v))
                        appRoot.volume = v
                        if (isPlayback) SoundHandler.setSinkInputVolume(streamIndex, v)
                        else SoundHandler.setSourceOutputVolume(streamIndex, v)
                    }
                }
            }
            
            // Volume
            Text {
                text: volume + "%"
                font.family: Config.fontFamily
                font.pixelSize: 11
                color: Config.dimmedColor
                Layout.preferredWidth: 32
                horizontalAlignment: Text.AlignRight
            }
            
            // Mute
            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: 6
                color: appMuteMouse.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"
                
                Text {
                    anchors.centerIn: parent
                    text: muted ? "volume_off" : "volume_up"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: muted ? Config.errorColor : Config.dimmedColor
                }
                
                MouseArea {
                    id: appMuteMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (isPlayback) SoundHandler.toggleSinkInputMute(streamIndex)
                        else SoundHandler.toggleSourceOutputMute(streamIndex)
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
        
        function getIcon() {
            let n = (name || "").toLowerCase()
            if (n.includes("firefox")) return "public"
            if (n.includes("chrome")) return "language"
            if (n.includes("spotify")) return "music_note"
            if (n.includes("discord")) return "forum"
            if (n.includes("vlc") || n.includes("mpv")) return "movie"
            if (n.includes("game") || n.includes("steam")) return "sports_esports"
            if (n.includes("obs")) return "videocam"
            return isPlayback ? "play_arrow" : "mic"
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
            
            // Output Section
            Section {
                title: "OUTPUT"
                
                Repeater {
                    model: SoundHandler.outputDevices
                    
                    DeviceRow {
                        label: {
                            let desc = modelData.description || modelData.name
                            if (desc.length > 30) desc = desc.substring(0, 27) + "..."
                            return desc
                        }
                        icon: {
                            let n = (modelData.name || "").toLowerCase()
                            if (n.includes("hdmi")) return "tv"
                            if (n.includes("headphone") || n.includes("bluez")) return "headphones"
                            if (n.includes("usb")) return "usb"
                            return "speaker"
                        }
                        active: modelData.name === SoundHandler.defaultSink
                        muted: modelData.muted
                        volume: modelData.volume
                        
                        onClicked: SoundHandler.setDefaultSink(modelData.name)
                        onVolumeAdjusted: (v) => SoundHandler.setSinkVolume(modelData.name, v)
                        onMuteToggled: SoundHandler.toggleSinkMute(modelData.name)
                    }
                }
                
                // Empty state
                Text {
                    visible: SoundHandler.outputDevices.length === 0
                    text: "No output devices"
                    font.family: Config.fontFamily
                    font.pixelSize: 13
                    color: Config.dimmedColor
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8
                }
            }
            
            // Input Section
            Section {
                title: "INPUT"
                
                Repeater {
                    model: SoundHandler.inputDevices
                    
                    DeviceRow {
                        label: {
                            let desc = modelData.description || modelData.name
                            if (desc.length > 30) desc = desc.substring(0, 27) + "..."
                            return desc
                        }
                        icon: "mic"
                        active: modelData.name === SoundHandler.defaultSource
                        muted: modelData.muted
                        volume: modelData.volume
                        
                        onClicked: SoundHandler.setDefaultSource(modelData.name)
                        onVolumeAdjusted: (v) => SoundHandler.setSourceVolume(modelData.name, v)
                        onMuteToggled: SoundHandler.toggleSourceMute(modelData.name)
                    }
                }
                
                Text {
                    visible: SoundHandler.inputDevices.length === 0
                    text: "No input devices"
                    font.family: Config.fontFamily
                    font.pixelSize: 13
                    color: Config.dimmedColor
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8
                }
            }
            
            // Playing Apps Section
            Section {
                visible: SoundHandler.playbackStreams.length > 0
                title: "PLAYING"
                
                Repeater {
                    model: SoundHandler.playbackStreams
                    
                    AppRow {
                        name: modelData.name
                        volume: modelData.volume
                        muted: modelData.muted
                        streamIndex: modelData.index
                        isPlayback: true
                    }
                }
            }
            
            // Recording Apps Section
            Section {
                visible: SoundHandler.recordingStreams.length > 0
                title: "RECORDING"
                
                Repeater {
                    model: SoundHandler.recordingStreams
                    
                    AppRow {
                        name: modelData.name
                        volume: modelData.volume
                        muted: modelData.muted
                        streamIndex: modelData.index
                        isPlayback: false
                    }
                }
            }
            
            // Empty state for apps
            Rectangle {
                visible: SoundHandler.playbackStreams.length === 0 && SoundHandler.recordingStreams.length === 0
                Layout.fillWidth: true
                height: 80
                radius: 12
                color: Config.surfaceColor
                border.width: 1
                border.color: Config.borderColor
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    
                    Text {
                        text: "music_off"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 24
                        color: Config.dimmedColor
                    }
                    
                    Text {
                        text: "No apps playing audio"
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                        color: Config.dimmedColor
                    }
                }
            }
        }
    }
}
