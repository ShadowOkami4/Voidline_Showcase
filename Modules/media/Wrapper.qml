/*
 * ============================================================================
 *                        MEDIA PANEL WRAPPER
 * ============================================================================
 */

pragma ComponentBehavior: Bound

import "../../Assets"
import "../../misc"
import Quickshell
import QtQuick

Item {
    id: root
    
    required property bool shouldBeActive
    
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    
    Content {
        id: content
        
        anchors.fill: parent
        wrapper: root
    }
}
