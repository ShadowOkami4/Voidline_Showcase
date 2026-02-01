/*
 * ============================================================================
 *                        MEDIA PANEL CONTENT (REWORKED)
 * ============================================================================
 * 
 * Expressive media player content with glass aesthetics and spring motion.
 * 
 * ============================================================================
 */

pragma ComponentBehavior: Bound

import "../../components"
import "../../misc"
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Effects

Item {
    id: root
    
    required property Item wrapper
    
    // Player progress for seek bar
    property real playerProgress: {
        const player = activePlayer;
        return player?.length > 0 ? player.position / player.length : 0;
    }
    
    // Get active MPRIS player
    readonly property MprisPlayer activePlayer: Mpris.players.values[0] ?? null
    readonly property bool isPlaying: activePlayer?.playbackState === MprisPlaybackState.Playing
    
    // Helper function to format time
    function formatTime(seconds: int): string {
        if (seconds < 0) return "0:00";
        const mins = Math.floor(seconds / 60);
        const secs = Math.floor(seconds % 60).toString().padStart(2, "0");
        return `${mins}:${secs}`;
    }
    
    implicitWidth: 320
    implicitHeight: layout.implicitHeight
    
    // Update position periodically
    Timer {
        running: root.isPlaying
        interval: 1000
        triggeredOnStart: true
        repeat: true
        onTriggered: root.activePlayer?.positionChanged()
    }
    
    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: 20
        
        // --------------------------------------------------------------------
        //                     ALBUM ART & VISUALIZER
        // --------------------------------------------------------------------
        Item {
            id: coverContainer
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 180
            Layout.preferredHeight: 180
            
            // Pulsing Background Glow (When Playing)
            Rectangle {
                anchors.centerIn: parent
                width: 160; height: 160; radius: 80
                color: Config.accentColor
                opacity: root.isPlaying ? 0.3 : 0
                scale: root.isPlaying ? 1.2 : 0.8
                
                SequentialAnimation on scale {
                    running: root.isPlaying
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.1; to: 1.3; duration: 2000; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.3; to: 1.1; duration: 2000; easing.type: Easing.InOutSine }
                }
                
                Behavior on opacity { NumberAnimation { duration: 500 } }
            }
            
            // Album Art
            Rectangle {
                id: coverArt
                anchors.fill: parent
                radius: 24
                color: Config.surfaceColor
                clip: true
                border.width: 1
                border.color: Config.borderColor
                
                Image {
                    id: albumImage
                    anchors.fill: parent
                    source: root.activePlayer?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }
                
                MaterialIcon {
                    anchors.centerIn: parent
                    visible: albumImage.status !== Image.Ready
                    text: "music_note"
                    font.pointSize: 48
                    color: Config.dimmedColor
                }
            }
            
            // Progress Ring
            Shape {
                anchors.fill: parent
                anchors.margins: -6
                
                ShapePath {
                    fillColor: "transparent"
                    strokeColor: Config.surfaceColorActive
                    strokeWidth: 4
                    capStyle: ShapePath.RoundCap
                    PathAngleArc {
                        centerX: 96; centerY: 96
                        radiusX: 96; radiusY: 96
                        startAngle: -90; sweepAngle: 360
                    }
                }
                
                ShapePath {
                    fillColor: "transparent"
                    strokeColor: Config.accentColor
                    strokeWidth: 4
                    capStyle: ShapePath.RoundCap
                    PathAngleArc {
                        centerX: 96; centerY: 96
                        radiusX: 96; radiusY: 96
                        startAngle: -90; sweepAngle: 360 * root.playerProgress
                    }
                }
            }
        }
        
        // --------------------------------------------------------------------
        //                     TRACK INFO
        // --------------------------------------------------------------------
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            
            Text {
                Layout.fillWidth: true
                text: root.activePlayer?.trackTitle ?? "No media playing"
                color: Config.foregroundColor
                font.family: Config.fontFamily
                font.pixelSize: 18
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
            
            Text {
                Layout.fillWidth: true
                text: root.activePlayer?.trackArtist ?? "Unknown Artist"
                color: Config.dimmedColor
                font.family: Config.fontFamily
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }
        
        // --------------------------------------------------------------------
        //                     SEEK BAR
        // --------------------------------------------------------------------
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Item {
                id: seekArea
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                
                Rectangle {
                    id: seekTrack
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: seekMouse.pressed ? 12 : 6
                    radius: height / 2
                    color: Config.surfaceColorActive
                    
                    Behavior on height { NumberAnimation { duration: 400; easing { type: Easing.OutBack; overshoot: 3.0 } } }
                    
                    Rectangle {
                        width: parent.width * root.playerProgress
                        height: parent.height
                        radius: parent.radius
                        color: Config.accentColor
                        
                        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                        
                        // Knob
                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: -9
                            width: 18; height: 18; radius: 9
                            color: Config.accentColor
                            border.width: 3; border.color: "#ffffff"
                            scale: seekMouse.pressed ? 1.4 : 0
                            Behavior on scale { NumberAnimation { duration: 400; easing { type: Easing.OutBack; overshoot: 4.0 } } }
                        }
                    }
                }
                
                MouseArea {
                    id: seekMouse
                    anchors.fill: parent; anchors.margins: -10
                    onPressed: updatePos(mouse)
                    onPositionChanged: if(pressed) updatePos(mouse)
                    function updatePos(m) {
                        if(activePlayer?.canSeek && activePlayer?.length > 0) {
                            activePlayer.position = Math.floor((Math.max(0, Math.min(1, m.x/width))) * activePlayer.length)
                        }
                    }
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                Text { text: root.formatTime(activePlayer?.position ?? 0); color: Config.dimmedColor; font.pixelSize: 11 }
                Item { Layout.fillWidth: true }
                Text { text: root.formatTime(activePlayer?.length ?? 0); color: Config.dimmedColor; font.pixelSize: 11 }
            }
        }
        
        // --------------------------------------------------------------------
        //                     CONTROLS
        // --------------------------------------------------------------------
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 24
            
            component ControlBtn: Rectangle {
                id: cBtn
                property string icon: ""
                property bool primary: false
                signal clicked()
                
                width: primary ? 64 : 48
                height: width; radius: width / 2
                color: primary ? Config.accentColor : "transparent"
                border.width: primary ? 0 : 1
                border.color: Config.borderColor
                
                scale: cMouse.pressed ? 0.88 : 1.0
                Behavior on scale { NumberAnimation { duration: 200; easing { type: Easing.OutBack; overshoot: 2.0 } } }
                
                Text {
                    anchors.centerIn: parent
                    text: cBtn.icon
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: cBtn.primary ? 32 : 24
                    color: cBtn.primary ? Config.onAccent : Config.foregroundColor
                    
                    rotation: cMouse.pressed ? (icon === "skip_next" ? 15 : (icon === "skip_previous" ? -15 : 0)) : 0
                    Behavior on rotation { NumberAnimation { duration: 300; easing { type: Easing.OutBack; overshoot: 3.0 } } }
                }
                
                MouseArea { id: cMouse; anchors.fill: parent; onClicked: cBtn.clicked() }
            }
            
            ControlBtn {
                icon: "skip_previous"
                onClicked: activePlayer?.previous()
            }
            
            ControlBtn {
                primary: true
                icon: root.isPlaying ? "pause" : "play_arrow"
                onClicked: activePlayer?.togglePlaying()
            }
            
            ControlBtn {
                icon: "skip_next"
                onClicked: activePlayer?.next()
            }
        }
    }
}
