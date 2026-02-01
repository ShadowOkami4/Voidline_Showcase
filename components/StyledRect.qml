/*
 * ============================================================================
 *                           STYLED RECTANGLE
 * ============================================================================
 * 
 * Celestia Shell style Rectangle with built-in color animation.
 * Use throughout the shell instead of plain Rectangle for consistent
 * animated color transitions.
 * 
 * Reference: caelestia-dots/shell components/StyledRect.qml
 */

import QtQuick
import "../misc"

Rectangle {
    id: root
    
    color: "transparent"
    
    Behavior on color {
        CAnim {}
    }
}
