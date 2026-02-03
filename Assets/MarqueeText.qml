/*
 * ============================================================================
 *                          MARQUEE TEXT COMPONENT
 * ============================================================================
 * 
 * A text component that scrolls horizontally when the text is too long
 * to fit in the available width.
 * 
 * Features:
 *   - Smooth scrolling animation when text overflows
 *   - Configurable scroll speed and pause duration
 *   - Fade edges for smooth visual effect
 *   - Only scrolls when text actually overflows
 */

import QtQuick
import "../misc"

Item {
    id: root
    
    // Text properties
    property alias text: innerText.text
    property alias color: innerText.color
    property alias font: innerText.font
    property alias horizontalAlignment: innerText.horizontalAlignment
    
    // Scroll behavior
    property int scrollSpeed: 40              // Pixels per second
    property int pauseDuration: 2000          // Pause at start/end (ms)
    property int fadeWidth: 20                // Width of fade edges
    
    // Whether text needs scrolling
    readonly property bool needsScroll: innerText.implicitWidth > root.width
    
    implicitWidth: 200
    implicitHeight: innerText.implicitHeight
    
    clip: true
    
    // The actual text that scrolls
    Text {
        id: innerText
        
        anchors.verticalCenter: parent.verticalCenter
        
        // Start at the beginning
        x: 0
        
        renderType: Text.NativeRendering
        textFormat: Text.PlainText
        font.family: Appearance.font.family.sans
        font.pointSize: Appearance.font.size.normal
        
        // Scroll animation
        SequentialAnimation on x {
            id: scrollAnim
            running: root.needsScroll && root.visible
            loops: Animation.Infinite
            
            // Pause at the start
            PauseAnimation {
                duration: root.pauseDuration
            }
            
            // Scroll to show the end of the text
            NumberAnimation {
                to: -(innerText.implicitWidth - root.width)
                duration: Math.max(0, (innerText.implicitWidth - root.width) / root.scrollSpeed * 1000)
                easing.type: Easing.Linear
            }
            
            // Pause at the end
            PauseAnimation {
                duration: root.pauseDuration
            }
            
            // Scroll back to start
            NumberAnimation {
                to: 0
                duration: Math.max(0, (innerText.implicitWidth - root.width) / root.scrollSpeed * 1000)
                easing.type: Easing.Linear
            }
        }
    }
    
    // Left fade gradient
    Rectangle {
        visible: root.needsScroll && innerText.x < 0
        
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.fadeWidth
        
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Config.backgroundColor }
            GradientStop { position: 1.0; color: "transparent" }
        }
        
        opacity: Math.min(1, -innerText.x / root.fadeWidth)
    }
    
    // Right fade gradient
    Rectangle {
        visible: root.needsScroll && (innerText.x + innerText.implicitWidth) > root.width
        
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.fadeWidth
        
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Config.backgroundColor }
        }
        
        opacity: Math.min(1, (innerText.x + innerText.implicitWidth - root.width) / root.fadeWidth)
    }
    
    // Reset scroll position when text changes
    onTextChanged: {
        scrollAnim.stop()
        innerText.x = 0
        if (needsScroll) {
            scrollAnim.restart()
        }
    }
    
    onNeedsScrollChanged: {
        if (!needsScroll) {
            scrollAnim.stop()
            innerText.x = 0
        } else {
            scrollAnim.restart()
        }
    }
}
