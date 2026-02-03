/*
* ============================================================================
* ANIMATION HELPER
* ============================================================================
*
* Celestia Shell style NumberAnimation with M3 Expressive defaults.
* Use instead of NumberAnimation throughout the shell for consistent,
* buttery-smooth animations.
*
* Default curve: M3 Standard curve
* Default duration: 400ms (normal)
*
* USAGE:
* Behavior on x {
* Anim {}
* }
*
* Anim {
* target: item
* property: "opacity"
* to: 1
* duration: Appearance.anim.durations.small
* easing.bezierCurve: Appearance.anim.curves.emphasized
* }
*/

import QtQuick

NumberAnimation {
    duration: Appearance.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.anim.curves.standard
}
 