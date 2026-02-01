/*
 * ============================================================================
 *                          COLOR ANIMATION HELPER
 * ============================================================================
 * 
 * Celestia Shell style ColorAnimation with M3 Expressive defaults.
 * Use for animating color properties (background, text color, etc.)
 * 
 * USAGE:
 *   Behavior on color {
 *       CAnim {}
 *   }
 */

import QtQuick

ColorAnimation {
    duration: Appearance.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.anim.curves.standard
}
