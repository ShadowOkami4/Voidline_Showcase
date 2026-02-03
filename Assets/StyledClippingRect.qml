/*
 * ============================================================================
 *                      STYLED CLIPPING RECTANGLE
 * ============================================================================
 * 
 * Celestia Shell style ClippingRectangle with built-in color animation.
 * Use for containers that need to clip their contents with rounded corners.
 * 
 * Reference: caelestia-dots/shell components/StyledClippingRect.qml
 */

import QtQuick
import Quickshell.Widgets
import "../misc"

ClippingRectangle {
    id: root
    
    color: "transparent"
    
    Behavior on color {
        CAnim {}
    }
}
