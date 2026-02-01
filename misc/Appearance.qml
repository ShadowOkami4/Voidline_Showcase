/*
 * ============================================================================
 *                          APPEARANCE SINGLETON
 * ============================================================================
 * 
 * Celestia Shell-inspired appearance configuration.
 * Provides consistent rounding, spacing, padding, fonts, and animation
 * settings throughout the shell.
 * 
 * All values are accessed as: Appearance.rounding.normal, Appearance.anim.curves.emphasized, etc.
 * 
 * This follows Material 3 Expressive design principles.
 */

pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root
    
    /*
     * ========================================================================
     *                              ROUNDING
     * ========================================================================
     * Corner radius values following M3 Expressive guidelines.
     * Use scale to uniformly adjust all rounding values.
     */
    readonly property QtObject rounding: QtObject {
        readonly property real scale: 1
        readonly property int small: Math.round(12 * scale)     // Buttons, chips
        readonly property int normal: Math.round(17 * scale)    // Cards, containers  
        readonly property int large: Math.round(25 * scale)     // Large surfaces, panels
        readonly property int full: 1000                        // Fully rounded (pill shape)
    }
    
    /*
     * ========================================================================
     *                              SPACING
     * ========================================================================
     * Gap/spacing values between elements.
     */
    readonly property QtObject spacing: QtObject {
        readonly property real scale: 1
        readonly property int small: Math.round(7 * scale)
        readonly property int smaller: Math.round(10 * scale)
        readonly property int normal: Math.round(12 * scale)
        readonly property int larger: Math.round(15 * scale)
        readonly property int large: Math.round(20 * scale)
    }
    
    /*
     * ========================================================================
     *                              PADDING
     * ========================================================================
     * Internal padding for containers and controls.
     */
    readonly property QtObject padding: QtObject {
        readonly property real scale: 1
        readonly property int small: Math.round(5 * scale)
        readonly property int smaller: Math.round(7 * scale)
        readonly property int normal: Math.round(10 * scale)
        readonly property int larger: Math.round(12 * scale)
        readonly property int large: Math.round(15 * scale)
    }
    
    /*
     * ========================================================================
     *                                FONTS
     * ========================================================================
     * Font families and sizes for consistent typography.
     */
    readonly property QtObject font: QtObject {
        readonly property QtObject family: QtObject {
            readonly property string sans: "Rubik"
            readonly property string mono: "CaskaydiaCove NF"
            readonly property string material: "Material Symbols Rounded"
            readonly property string clock: "Rubik"
        }
        
        readonly property QtObject size: QtObject {
            readonly property real scale: 1
            readonly property int small: Math.round(11 * scale)
            readonly property int smaller: Math.round(12 * scale)
            readonly property int normal: Math.round(13 * scale)
            readonly property int larger: Math.round(15 * scale)
            readonly property int large: Math.round(18 * scale)
            readonly property int extraLarge: Math.round(28 * scale)
        }
    }
    
    /*
     * ========================================================================
     *                            ANIMATIONS
     * ========================================================================
     * 
     * M3 Expressive animation curves and durations.
     * These are bezier curves that create smooth, expressive motion.
     * 
     * Curve categories:
     *   - emphasized: Strong start/end, dramatic motion (enter/exit)
     *   - standard: Balanced, default curve for most animations
     *   - expressiveFast/Default: Playful, bouncy for spatial animations
     */
    readonly property QtObject anim: QtObject {
        readonly property QtObject curves: QtObject {
            // M3 Emphasized - Strong start, soft end. For enter/exit transitions.
            readonly property list<real> emphasized: [0.05, 0, 0.133, 0.06, 0.167, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
            readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
            readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
            
            // M3 Standard - Balanced curve for general purpose
            readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
            readonly property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
            readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
            
            // M3 Expressive - Playful, bouncy. For spatial, joyful animations.
            readonly property list<real> expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
            readonly property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
            readonly property list<real> expressiveEffects: [0.34, 0.8, 0.34, 1, 1, 1]
        }
        
        readonly property QtObject durations: QtObject {
            readonly property real scale: 1
            readonly property int small: Math.round(200 * scale)               // Quick transitions
            readonly property int normal: Math.round(400 * scale)              // Default duration
            readonly property int large: Math.round(600 * scale)               // Complex animations
            readonly property int extraLarge: Math.round(1000 * scale)         // Very slow, dramatic
            readonly property int expressiveFastSpatial: Math.round(350 * scale)
            readonly property int expressiveDefaultSpatial: Math.round(500 * scale)
            readonly property int expressiveEffects: Math.round(200 * scale)
        }
    }
    
    /*
     * ========================================================================
     *                           BORDER CONFIG
     * ========================================================================
     * Border rounding and thickness for the Celestia-style outer border.
     */
    readonly property QtObject border: QtObject {
        readonly property int thickness: padding.normal
        readonly property int rounding: 16  // Same as rounding.large
    }
}
