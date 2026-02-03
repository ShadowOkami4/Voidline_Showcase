/*
 * ============================================================================
 *                       LOCK SURFACE (REFINED)
 * ============================================================================
 * 
 * FILE: panels/LockSurface.qml
 * PURPOSE: Modern lock screen with cohesive animations and Face ID visuals
 * 
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell

import "../../misc"

Rectangle {
    id: root
    required property LockContext context
    
    // Root should be transparent to reveal desktop during fade
    color: "transparent"
    
    // ========================================================================
    //                     BACKGROUND FADER
    // ========================================================================
    
    Rectangle {
        id: backgroundContainer
        anchors.fill: parent
        color: "#000000"
        
        // Blurred Wallpaper
        Image {
            id: wallpaperImage
            anchors.fill: parent
            source: Config.wallpaperPath ? "file://" + Config.wallpaperPath : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }
        
        MultiEffect {
            id: backgroundEffect
            source: wallpaperImage
            anchors.fill: parent
            blurEnabled: true
            blurMax: 64
            blur: 1.0
            brightness: -0.3
            saturation: 0.4
        }
        
        // Dark Tint
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)
        }
        
        // FADE ANIMATION
        opacity: root.context.isExiting ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
    }
    
    // ========================================================================
    //                     MAIN CONTENT
    // ========================================================================
    
    Item {
        id: contentContainer
        anchors.fill: parent
        
        // Animation State Logic
        opacity: 0
        transform: Translate { id: contentTranslate; y: 40 }
        
        states: [
            State {
                name: "visible"
                when: !root.context.isExiting
                PropertyChanges { target: contentContainer; opacity: 1 }
                PropertyChanges { target: contentTranslate; y: 0 }
            },
            State {
                name: "exiting"
                when: root.context.isExiting
                PropertyChanges { target: contentContainer; opacity: 0 }
                PropertyChanges { target: contentTranslate; y: -40 }
            }
        ]
        
        transitions: [
            Transition {
                from: ""; to: "visible"
                NumberAnimation { properties: "opacity"; duration: 600; easing.type: Easing.OutCubic }
                NumberAnimation { target: contentTranslate; property: "y"; duration: 800; easing.type: Easing.OutQuint }
            },
            Transition {
                from: "visible"; to: "exiting"
                NumberAnimation { properties: "opacity"; duration: 400; easing.type: Easing.OutQuad }
                NumberAnimation { target: contentTranslate; property: "y"; duration: 500; easing.type: Easing.InQuint }
            }
        ]
        
        Component.onCompleted: root.context.startAuth()

        // Time logic
        property string currentTime: ""
        property string currentDate: ""
        
        Timer {
            interval: 1000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: {
                let now = new Date()
                contentContainer.currentTime = now.toLocaleTimeString(Qt.locale(), "HH:mm")
                contentContainer.currentDate = now.toLocaleDateString(Qt.locale(), "dddd, MMMM d")
            }
        }
        
        // --------------------------------------------------------------------
        //                     CLOCK (TOP)
        // --------------------------------------------------------------------
        ColumnLayout {
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: parent.height * 0.12
            }
            spacing: 0
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: contentContainer.currentTime
                font.family: "Roboto Flex"
                font.pixelSize: 120
                font.weight: Font.Thin
                color: "#ffffff"
                renderType: Text.NativeRendering
            }
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: contentContainer.currentDate
                font.family: "Roboto Flex"
                font.pixelSize: 22
                font.weight: Font.Medium
                color: Qt.rgba(1, 1, 1, 0.7)
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 2
            }
        }
        
        // --------------------------------------------------------------------
        //                     AUTH SECTION (CENTER)
        // --------------------------------------------------------------------
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 32
            
            // AVATAR & FACE ID INDICATOR
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 120
                Layout.preferredHeight: 120
                
                // Pulsing Scan Effect
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 20
                    height: parent.height + 20
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: Config.accentColor
                    opacity: 0
                    
                    SequentialAnimation on opacity {
                        running: root.context.authStatus === "scanning"
                        loops: Animation.Infinite
                        NumberAnimation { from: 0; to: 0.6; duration: 800; easing.type: Easing.OutQuad }
                        NumberAnimation { from: 0.6; to: 0; duration: 800; easing.type: Easing.OutQuad }
                    }
                    
                    SequentialAnimation on scale {
                        running: root.context.authStatus === "scanning"
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.9; to: 1.1; duration: 1600; easing.type: Easing.OutQuad }
                    }
                }
                
                // Avatar Circle
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Config.surfaceColor
                    border.width: 2
                    border.color: {
                        if (root.context.authStatus === "success") return Config.successColor
                        if (root.context.authStatus === "failure") return Config.errorColor
                        return Qt.rgba(1,1,1,0.1)
                    }
                    clip: true
                    
                    // Profile Picture
                    Image {
                        anchors.fill: parent
                        anchors.margins: 4
                        source: Config.profilePicturePath ? "file://" + Config.profilePicturePath : ""
                        visible: Config.profilePicturePath !== ""
                        fillMode: Image.PreserveAspectCrop
                        
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                        }
                    }
                    
                    // Fallback Icon
                    Text {
                        anchors.centerIn: parent
                        text: "person"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 64
                        color: Qt.rgba(1,1,1,0.2)
                        visible: Config.profilePicturePath === ""
                    }
                }

                // Face ID Status Icon Overlay
                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: 36
                    height: 36
                    radius: 18
                    color: {
                        if (root.context.authStatus === "success") return Config.successColor
                        if (root.context.authStatus === "failure") return Config.errorColor
                        return Config.accentColor
                    }
                    visible: root.context.authStatus !== "idle"
                    
                    Text {
                        anchors.centerIn: parent
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 20
                        color: "#ffffff"
                        text: {
                            if (root.context.authStatus === "success") return "check"
                            if (root.context.authStatus === "failure") return "close"
                            return "face"
                        }
                    }
                }
            }
            
            // PASSWORD PILL
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 320
                height: 54
                radius: 27
                color: Qt.rgba(0, 0, 0, 0.3)
                border.width: 1
                border.color: passwordField.activeFocus ? Config.accentColor : Qt.rgba(1,1,1,0.1)
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 8
                    spacing: 12
                    
                    Text {
                        text: "lock"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 20
                        color: Qt.rgba(1, 1, 1, 0.5)
                    }
                    
                    TextField {
                        id: passwordField
                        Layout.fillWidth: true
                        placeholderText: "Enter Password"
                        echoMode: TextInput.Password
                        inputMethodHints: Qt.ImhSensitiveData
                        
                        background: Item {}
                        color: "#ffffff"
                        placeholderTextColor: Qt.rgba(1, 1, 1, 0.3)
                        font.family: "Roboto Flex"
                        font.pixelSize: 15
                        
                        enabled: !root.context.unlockInProgress
                        onTextChanged: root.context.currentText = text
                        onAccepted: root.context.tryUnlock()
                        
                        Connections {
                            target: root.context
                            function onCurrentTextChanged() {
                                if (passwordField.text !== root.context.currentText) {
                                    passwordField.text = root.context.currentText
                                }
                            }
                        }
                    }
                    
                    // Action Icon
                    Item {
                        Layout.preferredWidth: 40; Layout.preferredHeight: 40
                        Text {
                            anchors.centerIn: parent
                            visible: root.context.unlockInProgress
                            text: "progress_activity"
                            font.family: "Material Symbols Rounded"; font.pixelSize: 24; color: Config.accentColor
                            RotationAnimation on rotation {
                                from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: root.context.unlockInProgress
                            }
                        }
                        Rectangle {
                            visible: !root.context.unlockInProgress && passwordField.text.length > 0
                            anchors.centerIn: parent; width: 36; height: 36; radius: 18; color: Config.accentColor
                            Text { anchors.centerIn: parent; text: "arrow_forward"; font.family: "Material Symbols Rounded"; font.pixelSize: 20; color: Config.onAccent }
                            MouseArea { anchors.fill: parent; onClicked: root.context.tryUnlock() }
                        }
                    }
                }
            }
            
            // STATUS MESSAGE
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.context.showFailure ? "Incorrect Password" : 
                      (root.context.authStatus === "scanning" ? "Scanning Face..." : 
                      (root.context.authStatus === "failure" ? "Face Not Recognized" : "Type password to unlock"))
                font.family: "Roboto Flex"
                font.pixelSize: 13
                color: root.context.showFailure ? Config.errorColor : Qt.rgba(1, 1, 1, 0.5)
            }
        }
    }
}