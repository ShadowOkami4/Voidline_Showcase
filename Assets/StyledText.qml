/*
 * ============================================================================
 *                            STYLED TEXT
 * ============================================================================
 * 
 * Celestia Shell style Text with built-in color animation and
 * optional text change animation.
 * 
 * Reference: caelestia-dots/shell components/StyledText.qml
 */

pragma ComponentBehavior: Bound

import QtQuick
import "../misc"

Text {
    id: root
    
    property bool animate: false
    property string animateProp: "scale"
    property real animateFrom: 0
    property real animateTo: 1
    property int animateDuration: Appearance.anim.durations.normal
    
    renderType: Text.NativeRendering
    textFormat: Text.PlainText
    color: Config.foregroundColor
    font.family: Appearance.font.family.sans
    font.pointSize: Appearance.font.size.smaller
    
    Behavior on color {
        CAnim {}
    }
    
    Behavior on text {
        enabled: root.animate
        
        SequentialAnimation {
            Anim {
                to: root.animateFrom
                easing.bezierCurve: Appearance.anim.curves.standardAccel
            }
            PropertyAction {}
            Anim {
                to: root.animateTo
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
        }
    }
    
    component Anim: NumberAnimation {
        target: root
        property: root.animateProp
        duration: root.animateDuration / 2
        easing.type: Easing.BezierSpline
    }
}
