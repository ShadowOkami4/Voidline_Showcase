/*
 * ============================================================================
 *                    MEDIA PANEL (Celestia Shell Style)
 * ============================================================================
 * 
 * Implements Celestia Shell's popout architecture with:
 * 
 * - PanelWindow that only covers needed screen area
 * - Shape/ShapePath background with reverse corners that connect to bar
 * - Smooth M3 Expressive animations using Anim component
 * 
 * The reverse corners create the effect of the panel "emerging" from the bar.
 * 
 * Reference: caelestia-dots/shell modules/bar/popouts/Background.qml
 * 
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris

import "../misc"

PanelWindow {
    id: root
    
    // ========================================================================
    //                         CONFIGURATION
    // ========================================================================
    
    // Use Appearance for rounding (Celestia Shell style)
    readonly property real rounding: Appearance.border.rounding
    readonly property real panelWidth: 340
    readonly property real panelPadding: Appearance.padding.large
    
    // Panel position properties
    readonly property real panelHeight: content.implicitHeight + panelPadding * 2
    readonly property real panelX: (width - panelWidth) / 2
    readonly property real panelY: Config.barHeight + Config.topMargin
    
    // Computed shape dimensions
    readonly property bool flatten: panelWidth < rounding * 2
    readonly property real roundingX: flatten ? panelWidth / 2 : rounding
    
    // ========================================================================
    //                         WINDOW SETUP
    // ========================================================================
    
    anchors {
        top: true
        left: true
        right: true
    }
    
    // Layer shell configuration
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-media"
    
    // Don't reserve exclusive space
    exclusionMode: ExclusionMode.Ignore
    
    // Transparent background - we draw our own with Shape
    color: "transparent"
    
    // Height covers bar area + panel + extra for reverse corners
    implicitHeight: panelY + panelHeight + rounding
    
    // ========================================================================
    //                         VISIBILITY STATE
    // ========================================================================
    
    readonly property bool shouldBeActive: ShellState.mediaPanelVisible
    
    // Animated visibility with width (Celestia style)
    visible: panelShape.opacity > 0
    
    // Focus grab to close on outside click
    HyprlandFocusGrab {
        active: root.shouldBeActive
        windows: [root]
        onCleared: ShellState.mediaPanelVisible = false
    }
    
    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.mediaPanelVisible = false
    }
    
    // ========================================================================
    //                         MPRIS PLAYER STATE
    // ========================================================================
    
    property var playersList: Mpris.players.values
    
    function findActivePlayer() {
        if (!playersList || playersList.length === 0) return null
        for (let i = 0; i < playersList.length; i++) {
            let player = playersList[i]
            if (player && player.playbackState === MprisPlaybackState.Playing) {
                return player
            }
        }
        return playersList[0]
    }
    
    property var activePlayer: findActivePlayer()
    property bool hasPlayer: activePlayer !== null
    property bool isPlaying: activePlayer ? activePlayer.playbackState === MprisPlaybackState.Playing : false
    
    onPlayersListChanged: activePlayer = findActivePlayer()
    
    Timer {
        interval: 500
        repeat: true
        running: root.visible
        onTriggered: root.activePlayer = root.findActivePlayer()
    }
    
    // ========================================================================
    //                         CAVA VISUALIZATION
    // ========================================================================
    
    property int barCount: 24
    property var animatedBars: []
    
    Component.onCompleted: {
        let bars = []
        for (let i = 0; i < barCount; i++) bars.push(0.2)
        animatedBars = bars
    }
    
    Timer {
        running: root.isPlaying && root.visible
        interval: 60
        repeat: true
        onTriggered: {
            let newBars = []
            for (let i = 0; i < root.barCount; i++) {
                let current = root.animatedBars[i] || 0.2
                let target = Math.random() * 0.95 + 0.05
                newBars.push(current + (target - current) * 0.4)
            }
            root.animatedBars = newBars
        }
    }
    
    // ========================================================================
    //            BACKGROUND SHAPE (Celestia Shell Style Reverse Corners)
    // ========================================================================
    //
    // This uses the same pattern as Celestia Shell's popouts/Background.qml
    // 
    // The key insight: The ShapePath starts at the top edge with a reverse
    // arc that curves INTO the panel, creating the concave corner effect.
    //
    //        ════════════════ BAR ════════════════
    //                  ╱¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯╲         <- Reverse corners curve OUT
    //                 │                 │
    //                 │     PANEL       │
    //                 │                 │
    //                  ╲_______________╱         <- Normal rounded corners
    //
    // ========================================================================
    
    Shape {
        id: panelShape
        
        x: root.panelX - root.rounding
        y: root.panelY - root.rounding
        width: root.panelWidth + root.rounding * 2
        height: root.panelHeight + root.rounding * 2
        
        preferredRendererType: Shape.CurveRenderer
        
        // Animation state
        opacity: root.shouldBeActive ? 1 : 0
        scale: root.shouldBeActive ? 1 : 0.95
        transformOrigin: Item.Top
        
        Behavior on opacity {
            Anim {
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: root.shouldBeActive 
                    ? Appearance.anim.curves.expressiveDefaultSpatial 
                    : Appearance.anim.curves.emphasized
            }
        }
        
        Behavior on scale {
            Anim {
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }
        
        // Drop shadow
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.alpha(Config.backgroundColor, 0.7)
            blurMax: 15
        }
        
        ShapePath {
            strokeWidth: -1
            fillColor: Config.backgroundColor
            
            // Start at top-left corner of the "ear" area
            // This is at the outer edge where the reverse corner begins
            startX: 0
            startY: 0
            
            // TOP-LEFT REVERSE CORNER (concave - curves inward)
            // Arc goes DOWN and RIGHT, Clockwise makes it curve outward (concave effect)
            PathArc {
                x: root.rounding
                y: root.rounding
                radiusX: root.rounding
                radiusY: root.rounding
                direction: PathArc.Clockwise
            }
            
            // Top edge of panel body (across to right side)
            PathLine {
                x: panelShape.width - root.rounding
                y: root.rounding
            }
            
            // TOP-RIGHT REVERSE CORNER (concave - curves inward)
            // Arc goes UP and RIGHT, Clockwise makes it curve outward (concave effect)
            PathArc {
                x: panelShape.width
                y: 0
                radiusX: root.rounding
                radiusY: root.rounding
                direction: PathArc.Clockwise
            }
            
            // Right edge down to bottom
            PathLine {
                x: panelShape.width
                y: panelShape.height - root.rounding
            }
            
            // BOTTOM-RIGHT CORNER (normal convex corner)
            PathArc {
                x: panelShape.width - root.rounding
                y: panelShape.height
                radiusX: root.rounding
                radiusY: root.rounding
                direction: PathArc.Counterclockwise
            }
            
            // Bottom edge to left
            PathLine {
                x: root.rounding
                y: panelShape.height
            }
            
            // BOTTOM-LEFT CORNER (normal convex corner)
            PathArc {
                x: 0
                y: panelShape.height - root.rounding
                radiusX: root.rounding
                radiusY: root.rounding
                direction: PathArc.Counterclockwise
            }
            
            // Left edge back up to start
            PathLine {
                x: 0
                y: 0
            }
            
            Behavior on fillColor {
                CAnim {}
            }
        }
    }
    
    // ========================================================================
    //                         CONTENT AREA
    // ========================================================================
    
    Item {
        id: contentContainer
        
        x: root.panelX
        y: root.panelY
        width: root.panelWidth
        height: root.panelHeight
        
        // Animation synced with shape
        opacity: panelShape.opacity
        scale: panelShape.scale
        transformOrigin: Item.Top
        
        // Prevent clicks from closing panel
        MouseArea {
            anchors.fill: parent
            onClicked: (mouse) => mouse.accepted = true
        }
        
        ColumnLayout {
            id: content
            
            anchors {
                fill: parent
                margins: root.panelPadding
            }
            
            spacing: Appearance.spacing.large
            
            // ----------------------------------------------------------------
            //                         HEADER
            // ----------------------------------------------------------------
            
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: "Now Playing"
                    font.family: Appearance.font.family.sans
                    font.pixelSize: Appearance.font.size.larger
                    font.weight: Font.DemiBold
                    color: Config.foregroundColor
                }
                
                Item { Layout.fillWidth: true }
                
                Text {
                    text: root.activePlayer?.identity ?? ""
                    font.family: Appearance.font.family.sans
                    font.pixelSize: Appearance.font.size.small
                    color: Config.dimmedColor
                }
            }
            
            // ----------------------------------------------------------------
            //                      ALBUM ART WITH CAVA
            // ----------------------------------------------------------------
            
            Rectangle {
                id: albumContainer
                Layout.fillWidth: true
                Layout.preferredHeight: width
                radius: Appearance.rounding.normal
                color: Config.surfaceColor
                
                clip: true
                
                // Album art image
                Image {
                    id: albumArt
                    anchors.fill: parent
                    source: root.activePlayer?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                    asynchronous: true
                    cache: true
                    sourceSize.width: 340
                    sourceSize.height: 340
                }
                
                // Fallback when no art
                Rectangle {
                    anchors.fill: parent
                    visible: albumArt.status !== Image.Ready
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Config.accentColor }
                        GradientStop { position: 1.0; color: Qt.darker(Config.accentColor, 1.5) }
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "music_note"
                        font.family: Appearance.font.family.material
                        font.pixelSize: 64
                        color: Qt.rgba(1, 1, 1, 0.5)
                    }
                }
                
                // Cava visualization overlay
                Item {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: 100
                    
                    // Gradient fade
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.4; color: Qt.rgba(0, 0, 0, 0.4) }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.7) }
                        }
                    }
                    
                    // Animated bars
                    Row {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            leftMargin: Appearance.padding.normal
                            rightMargin: Appearance.padding.normal
                            bottomMargin: -16
                        }
                        height: 60
                        spacing: 2
                        
                        Repeater {
                            model: root.barCount
                            
                            Rectangle {
                                width: (parent.width - (root.barCount - 1) * 2) / root.barCount
                                height: root.isPlaying 
                                    ? Math.max(6, 50 * (root.animatedBars[index] || 0.2))
                                    : 6
                                radius: 2
                                anchors.bottom: parent.bottom
                                color: Config.accentColor
                                opacity: 0.85
                                
                                Behavior on height {
                                    Anim { 
                                        duration: 50
                                        easing.type: Easing.OutQuad 
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // ----------------------------------------------------------------
            //                       TRACK INFO
            // ----------------------------------------------------------------
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small / 2
                
                Text {
                    Layout.fillWidth: true
                    text: root.activePlayer?.trackTitle ?? "No media playing"
                    font.family: Appearance.font.family.sans
                    font.pixelSize: Appearance.font.size.large
                    font.weight: Font.DemiBold
                    color: Config.foregroundColor
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
                
                Text {
                    Layout.fillWidth: true
                    text: root.activePlayer?.trackArtist ?? ""
                    font.family: Appearance.font.family.sans
                    font.pixelSize: Appearance.font.size.normal
                    color: Config.dimmedColor
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    visible: text !== ""
                }
                
                Text {
                    Layout.fillWidth: true
                    text: root.activePlayer?.trackAlbum ?? ""
                    font.family: Appearance.font.family.sans
                    font.pixelSize: Appearance.font.size.small
                    color: Config.dimmedColor
                    opacity: 0.7
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    visible: text !== ""
                }
            }
            
            // ----------------------------------------------------------------
            //                  SQUIGGLY SEEK BAR
            // ----------------------------------------------------------------
            
            Item {
                id: seekBarContainer
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                visible: root.hasPlayer && (root.activePlayer?.lengthSupported ?? false)
                
                property real currentPosition: root.activePlayer?.position ?? 0
                property real trackLength: root.activePlayer?.length ?? 1
                property real progress: trackLength > 0 ? Math.min(1, currentPosition / trackLength) : 0
                property bool isDragging: false
                property real dragProgress: 0
                property real displayProgress: isDragging ? dragProgress : progress
                
                FrameAnimation {
                    running: root.isPlaying && root.visible && !seekBarContainer.isDragging
                    onTriggered: root.activePlayer?.positionChanged()
                }
                
                function formatTime(seconds) {
                    if (!isFinite(seconds) || seconds < 0) return "0:00"
                    let mins = Math.floor(seconds / 60)
                    let secs = Math.floor(seconds % 60)
                    return mins + ":" + (secs < 10 ? "0" : "") + secs
                }
                
                // Time labels
                RowLayout {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    
                    Text {
                        text: seekBarContainer.formatTime(
                            seekBarContainer.isDragging 
                                ? seekBarContainer.dragProgress * seekBarContainer.trackLength 
                                : seekBarContainer.currentPosition
                        )
                        font.family: Appearance.font.family.sans
                        font.pixelSize: Appearance.font.size.small
                        color: Config.dimmedColor
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Text {
                        text: seekBarContainer.formatTime(seekBarContainer.trackLength)
                        font.family: Appearance.font.family.sans
                        font.pixelSize: Appearance.font.size.small
                        color: Config.dimmedColor
                    }
                }
                
                // Squiggly progress bar
                Item {
                    id: progressBarArea
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        topMargin: 4
                    }
                    height: 20
                    
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width
                        height: 4
                        radius: 2
                        color: Config.surfaceColor
                    }
                    
                    Canvas {
                        id: squigglyCanvas
                        anchors.fill: parent
                        
                        property real progress: seekBarContainer.displayProgress
                        property real phase: 0
                        property real amplitude: root.isPlaying ? 4 : 0
                        property real frequency: 0.08
                        
                        Behavior on amplitude {
                            Anim { 
                                duration: Appearance.anim.durations.large
                                easing.bezierCurve: Appearance.anim.curves.emphasized
                            }
                        }
                        
                        NumberAnimation on phase {
                            from: 0
                            to: Math.PI * 2
                            duration: 800
                            loops: Animation.Infinite
                            running: root.isPlaying
                        }
                        
                        onProgressChanged: requestPaint()
                        onPhaseChanged: requestPaint()
                        onAmplitudeChanged: requestPaint()
                        
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            
                            var progressWidth = width * progress
                            var centerY = height / 2
                            var lineWidth = 4
                            
                            if (progressWidth < 2) return
                            
                            ctx.beginPath()
                            ctx.strokeStyle = Config.accentColor.toString()
                            ctx.lineWidth = lineWidth
                            ctx.lineCap = "round"
                            ctx.lineJoin = "round"
                            ctx.moveTo(0, centerY)
                            
                            for (var x = 0; x <= progressWidth; x += 2) {
                                var y = centerY + Math.sin((x * frequency) + phase) * amplitude
                                ctx.lineTo(x, y)
                            }
                            ctx.stroke()
                            
                            if (progressWidth < width - 2) {
                                ctx.beginPath()
                                ctx.strokeStyle = Qt.rgba(Config.foregroundColor.r, Config.foregroundColor.g, Config.foregroundColor.b, 0.15).toString()
                                ctx.lineWidth = lineWidth
                                ctx.moveTo(progressWidth, centerY)
                                ctx.lineTo(width, centerY)
                                ctx.stroke()
                            }
                        }
                    }
                    
                    Rectangle {
                        id: seekHandle
                        width: seekBarMouse.containsMouse || seekBarContainer.isDragging ? 16 : 12
                        height: width
                        radius: width / 2
                        color: Config.accentColor
                        x: (progressBarArea.width - width) * seekBarContainer.displayProgress
                        anchors.verticalCenter: parent.verticalCenter
                        scale: seekBarMouse.pressed ? 0.9 : 1.0
                        
                        Behavior on width {
                            Anim { duration: Appearance.anim.durations.small }
                        }
                        Behavior on scale {
                            Anim { duration: 100 }
                        }
                    }
                    
                    MouseArea {
                        id: seekBarMouse
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onPressed: (mouse) => {
                            if (!root.activePlayer?.canSeek) return
                            seekBarContainer.isDragging = true
                            seekBarContainer.dragProgress = Math.max(0, Math.min(1, mouse.x / progressBarArea.width))
                        }
                        
                        onPositionChanged: (mouse) => {
                            if (seekBarContainer.isDragging) {
                                seekBarContainer.dragProgress = Math.max(0, Math.min(1, mouse.x / progressBarArea.width))
                            }
                        }
                        
                        onReleased: {
                            if (seekBarContainer.isDragging && root.activePlayer?.canSeek) {
                                root.activePlayer.position = seekBarContainer.dragProgress * seekBarContainer.trackLength
                            }
                            seekBarContainer.isDragging = false
                        }
                        
                        onCanceled: seekBarContainer.isDragging = false
                    }
                }
            }
            
            // ----------------------------------------------------------------
            //                       PLAYBACK CONTROLS
            // ----------------------------------------------------------------
            
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: Appearance.spacing.large
                
                // Previous button
                Rectangle {
                    width: 44
                    height: 44
                    radius: Appearance.rounding.full
                    color: prevMouse.containsMouse ? Config.surfaceColorHover : "transparent"
                    visible: root.activePlayer?.canGoPrevious ?? false
                    
                    scale: prevMouse.pressed ? 0.9 : (prevMouse.containsMouse ? 1.1 : 1.0)
                    
                    Behavior on scale { 
                        Anim {
                            duration: Appearance.anim.durations.expressiveFastSpatial
                            easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                        }
                    }
                    Behavior on color { CAnim {} }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "skip_previous"
                        font.family: Appearance.font.family.material
                        font.pixelSize: 24
                        color: Config.foregroundColor
                    }
                    
                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activePlayer?.previous()
                    }
                }
                
                // Play/Pause - M3 Expressive dynamic shape
                Rectangle {
                    id: playButton
                    width: 56
                    height: 56
                    radius: root.isPlaying ? Appearance.rounding.full : Appearance.rounding.small
                    color: playMouse.containsMouse ? Qt.lighter(Config.accentColor, 1.15) : Config.accentColor
                    
                    scale: playMouse.pressed ? 0.9 : (playMouse.containsMouse ? 1.08 : 1.0)
                    
                    Behavior on radius { 
                        Anim {
                            duration: Appearance.anim.durations.expressiveDefaultSpatial
                            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                        }
                    }
                    Behavior on color { CAnim {} }
                    Behavior on scale { 
                        Anim {
                            duration: Appearance.anim.durations.expressiveFastSpatial
                            easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                        }
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: root.isPlaying ? "pause" : "play_arrow"
                        font.family: Appearance.font.family.material
                        font.pixelSize: 28
                        color: Config.onAccent
                        
                        scale: 1.0
                        SequentialAnimation on scale {
                            id: iconBounce
                            running: false
                            NumberAnimation { to: 0.7; duration: 80 }
                            NumberAnimation { 
                                to: 1.1
                                duration: 150
                                easing.type: Easing.OutBack 
                            }
                            NumberAnimation { to: 1.0; duration: 100 }
                        }
                    }
                    
                    onRadiusChanged: iconBounce.restart()
                    
                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activePlayer?.togglePlaying()
                    }
                }
                
                // Next button
                Rectangle {
                    width: 44
                    height: 44
                    radius: Appearance.rounding.full
                    color: nextMouse.containsMouse ? Config.surfaceColorHover : "transparent"
                    visible: root.activePlayer?.canGoNext ?? false
                    
                    scale: nextMouse.pressed ? 0.9 : (nextMouse.containsMouse ? 1.1 : 1.0)
                    
                    Behavior on scale { 
                        Anim {
                            duration: Appearance.anim.durations.expressiveFastSpatial
                            easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                        }
                    }
                    Behavior on color { CAnim {} }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "skip_next"
                        font.family: Appearance.font.family.material
                        font.pixelSize: 24
                        color: Config.foregroundColor
                    }
                    
                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activePlayer?.next()
                    }
                }
            }
        }
    }
}
