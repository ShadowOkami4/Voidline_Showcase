/*
 * ============================================================================
 *                     MEDIA PANEL BACKGROUND
 * ============================================================================
 * 
 * Celestia Shell style ShapePath background for the media panel.
 * Creates a rounded rectangle with reverse corners (concave arcs) at the
 * edges where it connects to the screen border.
 * 
 * This follows the exact pattern from Celestia Shell's panel backgrounds.
 * 
 * Reference: caelestia-dots/shell modules/osd/Background.qml
 *            caelestia-dots/shell modules/session/Background.qml
 */

import "../../components"
import "../../misc"
import QtQuick
import QtQuick.Shapes

ShapePath {
    id: root
    
    required property Item wrapper
    
    // Corner rounding configuration
    readonly property real rounding: Appearance.border.rounding
    readonly property bool flatten: wrapper.width < rounding * 2
    readonly property real roundingX: flatten ? wrapper.width / 2 : rounding
    
    // ShapePath configuration
    strokeWidth: -1
    fillColor: Config.surfaceColor
    
    /*
     * Draw the shape starting from top-left, going clockwise.
     * The shape has REVERSE (concave) corners at the top-left and top-right
     * to create the "notch" effect that merges with screen edges.
     */
    
    // Top-left: Reverse/concave arc pointing inward
    PathArc {
        relativeX: -root.roundingX
        relativeY: root.rounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
    }
    
    // Left edge going down
    PathLine {
        relativeX: -(root.wrapper.width - root.roundingX * 2)
        relativeY: 0
    }
    
    // Top-right: Reverse/concave arc
    PathArc {
        relativeX: -root.roundingX
        relativeY: root.rounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
        direction: PathArc.Counterclockwise
    }
    
    // Right edge going down
    PathLine {
        relativeX: 0
        relativeY: root.wrapper.height - root.rounding * 2
    }
    
    // Bottom-right: Normal convex arc
    PathArc {
        relativeX: root.roundingX
        relativeY: root.rounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
        direction: PathArc.Counterclockwise
    }
    
    // Bottom edge
    PathLine {
        relativeX: root.wrapper.width - root.roundingX * 2
        relativeY: 0
    }
    
    // Bottom-left: Normal convex arc
    PathArc {
        relativeX: root.roundingX
        relativeY: -root.rounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
        direction: PathArc.Counterclockwise
    }
    
    // Animate fill color
    Behavior on fillColor {
        CAnim {}
    }
}
