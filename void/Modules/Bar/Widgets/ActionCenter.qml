import Quickshell
import QtQuick

PopupWindow {
    id: popup
    property var parentBar
    
    anchor.window: parentBar
    anchor.rect.x: (parentBar?.width ?? 0) - width - Config.padding - Config.radius
    anchor.rect.y: Config.barHeight + Config.padding
    
    width: 300
    height: 400
    visible: ShellState.actionCenterVisible
    
    Rectangle {
        anchors.fill: parent
        color: Config.backgroundColor
        radius: Config.radius
        border.color: Config.accentColor
        border.width: 1
        
        Text {
            anchors.centerIn: parent
            text: "Action Center Content"
            color: Config.foregroundColor
        }
    }
}
