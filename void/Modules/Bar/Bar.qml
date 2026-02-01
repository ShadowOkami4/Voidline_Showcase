import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../Assets/ConcaveCorners.js" as Corners

PanelWindow {
    id: bar
    
    anchors {
        top: true
        left: true
        right: true
    }
    height: Config.barHeight + Config.radius
    color: "transparent"
    
    // Main bar background
    Rectangle {
        id: barBackground
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: Config.barHeight
        color: Config.backgroundColor
    }

    // Concave corners
    Canvas {
        id: leftCorner
        width: Config.radius
        height: Config.radius
        anchors {
            top: barBackground.bottom
            left: parent.left
        }
        antialiasing: true
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            
            ctx.fillStyle = Config.backgroundColor
            ctx.fillRect(0, 0, width, height)
            
            ctx.globalCompositeOperation = "destination-out"
            Corners.cutConcaveCorner(ctx, width, "bottomRight")
        }
    }

    Canvas {
        id: rightCorner
        width: Config.radius
        height: Config.radius
        anchors {
            top: barBackground.bottom
            right: parent.right
        }
        antialiasing: true
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            
            ctx.fillStyle = Config.backgroundColor
            ctx.fillRect(0, 0, width, height)
            
            ctx.globalCompositeOperation = "destination-out"
            Corners.cutConcaveCorner(ctx, width, "bottomLeft")
        }
    }
    
    RowLayout {
        height: Config.barHeight
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: Config.padding + Config.radius
        anchors.rightMargin: Config.padding + Config.radius
        
        Text {
            text: "Void Shell"
            color: Config.foregroundColor
            font.bold: true
        }
        
        Item { Layout.fillWidth: true }
        
        Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: Config.radius / 2
            color: mouseArea.containsMouse ? Config.accentColor : "gray"
            
            Text {
                anchors.centerIn: parent
                text: "AC"
                color: "black"
                font.pixelSize: 10
            }
            
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: ShellState.toggleActionCenter()
            }
        }
    }
    
    ActionCenter {
        parentBar: bar
    }
}
