/*
 * ============================================================================
 *                           MATERIAL ICON
 * ============================================================================
 * 
 * Material Symbols icon component with animation support.
 * Uses Material Symbols Rounded font for consistent iconography.
 * 
 * USAGE:
 *   MaterialIcon {
 *       text: "play_arrow"
 *       color: Config.foregroundColor
 *       font.pointSize: Appearance.font.size.large
 *   }
 * 
 * Reference: caelestia-dots/shell components/MaterialIcon.qml
 */

import QtQuick
import "../misc"

Text {
    id: root
    
    property bool animate: false
    property int fill: 0          // 0 = outline, 1 = filled
    property int grade: 0         // -25 to 200, affects weight/boldness
    
    renderType: Text.NativeRendering
    color: Config.foregroundColor
    font.family: Appearance.font.family.material
    font.pointSize: Appearance.font.size.normal
    
    Behavior on color {
        enabled: root.animate
        CAnim {}
    }
    
    Behavior on fill {
        enabled: root.animate
        Anim {}
    }
}
