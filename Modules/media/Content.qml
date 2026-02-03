/*
 * ============================================================================
 *                          MEDIA PANEL CONTENT
 * ============================================================================
 * 
 * Expressive media player with M3-inspired design:
 *   - Sine wave progress bar when playing
 *   - Morphing play/pause button
 *   - Multi-player support
 * 
 * ============================================================================
 */

pragma ComponentBehavior: Bound

import "../../Assets"
import "../../misc"
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    
    required property Item wrapper
    
    // ========================================================================
    //                              PROPERTIES
    // ========================================================================
    
    property int currentPlayerIndex: 0
    
    readonly property var allPlayers: Mpris.players.values ?? []
    readonly property int playerCount: allPlayers.length
    readonly property MprisPlayer activePlayer: allPlayers[currentPlayerIndex] ?? null
    readonly property bool isPlaying: activePlayer?.playbackState === MprisPlaybackState.Playing
    
    property real playerProgress: {
        const player = activePlayer;
        return player?.length > 0 ? player.position / player.length : 0;
    }
    
    implicitWidth: 320
    implicitHeight: layout.implicitHeight
    
    // ========================================================================
    //                              HELPERS
    // ========================================================================
    
    function getPlayerName(player: MprisPlayer): string {
        if (!player) return "Unknown";
        if (player.identity) return player.identity;
        if (player.desktopEntry) {
            const name = player.desktopEntry;
            return name.charAt(0).toUpperCase() + name.slice(1);
        }
        return "Media Player";
    }
    
    function getPlayerIcon(player: MprisPlayer): string {
        if (!player) return "play_circle";
        const entry = player.desktopEntry?.toLowerCase() ?? "";
        if (entry.includes("spotify")) return "music_note";
        if (entry.includes("firefox") || entry.includes("chrome") || entry.includes("chromium")) return "language";
        if (entry.includes("vlc")) return "movie";
        if (entry.includes("mpv")) return "theaters";
        return "play_circle";
    }
    
    function formatTime(seconds: int): string {
        if (seconds < 0) return "0:00";
        const mins = Math.floor(seconds / 60);
        const secs = Math.floor(seconds % 60).toString().padStart(2, "0");
        return `${mins}:${secs}`;
    }
    
    // ========================================================================
    //                              TIMERS
    // ========================================================================
    
    Timer {
        running: root.isPlaying
        interval: 1000
        triggeredOnStart: true
        repeat: true
        onTriggered: root.activePlayer?.positionChanged()
    }
    
    onPlayerCountChanged: {
        if (currentPlayerIndex >= playerCount) {
            currentPlayerIndex = Math.max(0, playerCount - 1);
        }
    }
    
    // ========================================================================
    //                              LAYOUT
    // ========================================================================
    
    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: 16
        
        // ====================================================================
        //                        PLAYER SOURCE
        // ====================================================================
        
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 20
            color: Config.surfaceColor
            border.width: 1
            border.color: Config.borderColor
            visible: root.playerCount > 0
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                spacing: 8
                
                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: Config.accentColorDim
                    
                    Text {
                        anchors.centerIn: parent
                        text: root.getPlayerIcon(root.activePlayer)
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 16
                        color: Config.accentColor
                    }
                }
                
                Text {
                    Layout.fillWidth: true
                    text: root.getPlayerName(root.activePlayer)
                    color: Config.foregroundColor
                    font { family: Config.fontFamily; pixelSize: 13; weight: Font.Medium }
                    elide: Text.ElideRight
                }
                
                Row {
                    spacing: 4
                    visible: root.playerCount > 1
                    
                    Repeater {
                        model: root.playerCount
                        
                        Rectangle {
                            required property int index
                            width: 8; height: 8; radius: 4
                            color: index === root.currentPlayerIndex ? Config.accentColor : Config.surfaceColorActive
                            scale: dotMouse.containsMouse ? 1.3 : 1.0
                            
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                            
                            MouseArea {
                                id: dotMouse
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.currentPlayerIndex = parent.index
                            }
                        }
                    }
                }
                
                Rectangle {
                    width: 28; height: 28; radius: 8
                    color: nextPlayerMouse.containsMouse ? Config.surfaceColorHover : "transparent"
                    visible: root.playerCount > 1
                    
                    Text {
                        anchors.centerIn: parent
                        text: "chevron_right"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 18
                        color: Config.dimmedColor
                    }
                    
                    MouseArea {
                        id: nextPlayerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentPlayerIndex = (root.currentPlayerIndex + 1) % root.playerCount
                    }
                }
            }
        }
        
        // ====================================================================
        //                          ALBUM ART
        // ====================================================================
        
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 160
            Layout.preferredHeight: 160
            
            Rectangle {
                id: coverArt
                anchors.fill: parent
                radius: Config.cardRadius
                color: Config.surfaceColor
                clip: true
                
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
                    font.pointSize: 40
                    color: Config.dimmedColor
                }
            }
            
            Rectangle {
                anchors.fill: parent
                radius: Config.cardRadius
                color: "transparent"
                border.width: 1
                border.color: Config.borderColor
            }
        }
        
        // ====================================================================
        //                         TRACK INFO
        // ====================================================================
        
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            
            Text {
                Layout.fillWidth: true
                text: root.activePlayer?.trackTitle ?? "No media playing"
                color: Config.foregroundColor
                font { family: Config.fontFamily; pixelSize: 16; weight: Font.Bold }
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
            
            Text {
                Layout.fillWidth: true
                text: root.activePlayer?.trackArtist ?? "Unknown Artist"
                color: Config.dimmedColor
                font { family: Config.fontFamily; pixelSize: 13 }
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }
        
        // ====================================================================
        //                     SINE WAVE PROGRESS BAR
        // ====================================================================
        
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            
            Item {
                id: seekArea
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                
                Canvas {
                    id: progressCanvas
                    anchors.centerIn: parent
                    width: parent.width
                    height: 32
                    
                    property real progress: root.playerProgress
                    property real phase: 0
                    property real amplitude: root.isPlaying ? 7 : 0
                    property real frequency: 0.04
                    property real lineWidth: 4
                    
                    Behavior on amplitude { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                    
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        
                        var w = width, h = height, midY = h / 2;
                        var progressX = w * progress;
                        var amp = amplitude, freq = frequency, ph = phase, sw = lineWidth;
                        
                        ctx.lineCap = "round";
                        ctx.lineJoin = "round";
                        ctx.lineWidth = sw;
                        
                        // Remaining track (straight line)
                        if (progressX < w - sw) {
                            ctx.strokeStyle = Config.surfaceColorActive;
                            ctx.beginPath();
                            ctx.moveTo(Math.max(sw/2, progressX), midY);
                            ctx.lineTo(w - sw/2, midY);
                            ctx.stroke();
                            
                            ctx.fillStyle = Config.surfaceColorActive;
                            ctx.beginPath();
                            ctx.arc(w - sw/2 - 2, midY, 4, 0, Math.PI * 2);
                            ctx.fill();
                        }
                        
                        // Progress (sine wave)
                        if (progressX > sw) {
                            ctx.strokeStyle = Config.accentColor;
                            ctx.beginPath();
                            ctx.moveTo(sw/2, midY + Math.sin(ph) * amp);
                            
                            for (var x = sw/2; x <= Math.min(progressX, w - sw/2); x += 0.5) {
                                ctx.lineTo(x, midY + Math.sin((x * freq) + ph) * amp);
                            }
                            ctx.stroke();
                        }
                    }
                    
                    NumberAnimation on phase {
                        running: root.isPlaying
                        from: 0; to: Math.PI * 2
                        duration: 1200
                        loops: Animation.Infinite
                    }
                    
                    onPhaseChanged: requestPaint()
                    onProgressChanged: requestPaint()
                    onAmplitudeChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    
                    Rectangle {
                        id: knob
                        x: Math.max(0, progressCanvas.width * root.playerProgress - width/2)
                        y: (parent.height/2 - height/2) + Math.sin((x * progressCanvas.frequency) + progressCanvas.phase) * progressCanvas.amplitude
                        width: 12; height: 12; radius: 6
                        color: Config.accentColor
                        border { width: 2; color: "#ffffff" }
                        scale: seekMouse.pressed || seekMouse.containsMouse ? 1.5 : (root.isPlaying ? 1.0 : 0)
                        visible: root.playerProgress > 0
                        
                        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }
                    }
                }
                
                MouseArea {
                    id: seekMouse
                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    onPressed: (mouse) => seek(mouse)
                    onPositionChanged: (mouse) => { if (pressed) seek(mouse) }
                    
                    function seek(m) {
                        if (root.activePlayer?.canSeek && root.activePlayer?.length > 0) {
                            root.activePlayer.position = Math.floor(Math.max(0, Math.min(1, m.x/width)) * root.activePlayer.length)
                        }
                    }
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: root.formatTime(root.activePlayer?.position ?? 0)
                    color: Config.dimmedColor
                    font { family: Config.fontFamily; pixelSize: 11 }
                }
                
                Item { Layout.fillWidth: true }
                
                Text {
                    text: root.formatTime(root.activePlayer?.length ?? 0)
                    color: Config.dimmedColor
                    font { family: Config.fontFamily; pixelSize: 11 }
                }
            }
        }
        
        // ====================================================================
        //                       PLAYBACK CONTROLS
        // ====================================================================
        
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            
            ControlButton {
                icon: "skip_previous"
                onClicked: root.activePlayer?.previous()
                rotateOnPress: -20
            }
            
            Rectangle {
                id: playBtn
                width: 64; height: 64
                radius: root.isPlaying ? 32 : 16
                color: Config.accentColor
                scale: playMouse.pressed ? 0.88 : 1.0
                
                Behavior on radius { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }
                
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: parent.radius + 3
                    color: "transparent"
                    border { width: 2; color: Config.accentColor }
                    opacity: root.isPlaying ? 0.5 : 0
                    
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                    Behavior on radius { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                    
                    SequentialAnimation on scale {
                        running: root.isPlaying
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.1; duration: 600; easing.type: Easing.OutQuad }
                        NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InQuad }
                    }
                }
                
                Text {
                    anchors.centerIn: parent
                    text: root.isPlaying ? "pause" : "play_arrow"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 32
                    color: Config.onAccent
                    scale: playMouse.pressed ? 0.9 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }
                
                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activePlayer?.togglePlaying()
                }
            }
            
            ControlButton {
                icon: "skip_next"
                onClicked: root.activePlayer?.next()
                rotateOnPress: 20
            }
        }
        
        // ====================================================================
        //                       NO PLAYER STATE
        // ====================================================================
        
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 20
            spacing: 8
            visible: root.playerCount === 0
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "headphones_off"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 48
                color: Config.dimmedColor
                opacity: 0.5
            }
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "No media playing"
                color: Config.dimmedColor
                font { family: Config.fontFamily; pixelSize: 14 }
            }
        }
    }
    
    // ========================================================================
    //                         CONTROL BUTTON COMPONENT
    // ========================================================================
    
    component ControlButton: Rectangle {
        property string icon
        property int rotateOnPress: 0
        signal clicked()
        
        width: 48; height: 48; radius: 24
        color: "transparent"
        border.width: 1
        border.color: mouse.containsMouse ? Config.borderColorHover : Config.borderColor
        scale: mouse.pressed ? 0.85 : 1.0
        
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
        
        Text {
            anchors.centerIn: parent
            text: parent.icon
            font.family: "Material Symbols Rounded"
            font.pixelSize: 24
            color: Config.foregroundColor
            rotation: mouse.pressed ? parent.rotateOnPress : 0
            Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }
        }
        
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}
