#!/usr/bin/env python3
"""
============================================================================
                    MATERIAL YOU COLOR GENERATOR
============================================================================

FILE: scripts/colorgen.py
PURPOSE: Extract colors from wallpaper and generate Material Design 3 scheme

USAGE:
    python colorgen.py --path /path/to/wallpaper.jpg --mode dark --output colors.json
    python colorgen.py --color "#ff5500" --mode dark --output colors.json

DEPENDENCIES:
    pip install materialyoucolor Pillow

============================================================================
"""

import argparse
import json
import sys
from pathlib import Path

# Lazy-loaded modules (improves startup time)
_PIL_Image = None
_QuantizeCelebi = None
_Score = None
_Hct = None
_MaterialDynamicColors = None


def _load_deps():
    """Lazy load dependencies only when needed."""
    global _PIL_Image, _QuantizeCelebi, _Score, _Hct, _MaterialDynamicColors
    
    if _PIL_Image is not None:
        return True
    
    try:
        from PIL import Image
        from materialyoucolor.quantize import QuantizeCelebi
        from materialyoucolor.score.score import Score
        from materialyoucolor.hct import Hct
        from materialyoucolor.dynamiccolor.material_dynamic_colors import MaterialDynamicColors
        
        _PIL_Image = Image
        _QuantizeCelebi = QuantizeCelebi
        _Score = Score
        _Hct = Hct
        _MaterialDynamicColors = MaterialDynamicColors
        return True
    except ImportError:
        print("ERROR: Missing dependencies. Install with:", file=sys.stderr)
        print("  pip install materialyoucolor Pillow", file=sys.stderr)
        sys.exit(1)


# ============================================================================
#                          HELPER FUNCTIONS
# ============================================================================

def argb_to_hex(argb):
    """Convert ARGB integer to hex string."""
    return "#{:02X}{:02X}{:02X}".format(
        (argb >> 16) & 0xFF,
        (argb >> 8) & 0xFF,
        argb & 0xFF
    )


def hex_to_argb(hex_code):
    """Convert hex string to ARGB integer."""
    hex_code = hex_code.lstrip('#')
    r = int(hex_code[0:2], 16)
    g = int(hex_code[2:4], 16)
    b = int(hex_code[4:6], 16)
    return (0xFF << 24) | (r << 16) | (g << 8) | b


def blend_colors(hex1, hex2, amount):
    """Blend two hex colors. amount: 0.0 = hex1, 1.0 = hex2."""
    r1, g1, b1 = int(hex1[1:3], 16), int(hex1[3:5], 16), int(hex1[5:7], 16)
    r2, g2, b2 = int(hex2[1:3], 16), int(hex2[3:5], 16), int(hex2[5:7], 16)
    
    r = int(r1 + (r2 - r1) * amount)
    g = int(g1 + (g2 - g1) * amount)
    b = int(b1 + (b2 - b1) * amount)
    
    return "#{:02X}{:02X}{:02X}".format(r, g, b)


# ============================================================================
#                          COLOR EXTRACTION
# ============================================================================

def calculate_saturation_sampled(pixels, sample_size=1000):
    """Calculate average saturation using sampling for large images."""
    if not pixels:
        return 0
    
    total = len(pixels)
    step = max(1, total // sample_size)
    
    total_sat = 0
    count = 0
    
    for i in range(0, total, step):
        r, g, b = pixels[i][0], pixels[i][1], pixels[i][2]
        max_c = max(r, g, b)
        min_c = min(r, g, b)
        
        if max_c > 0:
            total_sat += (max_c - min_c) / max_c
        count += 1
    
    return (total_sat / count * 100) if count > 0 else 0


def extract_color_from_image(image_path, size=64):
    """Extract dominant color from image using Material You quantization.
    
    Returns:
        tuple: (argb_color, is_grayscale)
    """
    _load_deps()
    
    image = _PIL_Image.open(image_path)
    
    # Handle animated images - just use first frame
    if hasattr(image, 'n_frames') and image.n_frames > 1:
        image.seek(0)
    
    # Convert to RGB
    if image.mode != 'RGB':
        if image.mode == 'RGBA':
            bg = _PIL_Image.new('RGB', image.size, (255, 255, 255))
            bg.paste(image, mask=image.split()[3])
            image = bg
        else:
            image = image.convert('RGB')
    
    # Calculate optimal size (maintain aspect ratio)
    w, h = image.size
    if w > size or h > size:
        scale = size / max(w, h)
        image = image.resize(
            (max(1, int(w * scale)), max(1, int(h * scale))),
            _PIL_Image.Resampling.LANCZOS
        )
    
    # Get pixel data (use new API if available)
    if hasattr(image, 'get_flattened_data'):
        pixels = list(image.get_flattened_data())
        # Reformat from flat to tuples if needed
        if pixels and not isinstance(pixels[0], tuple):
            pixels = [(pixels[i], pixels[i+1], pixels[i+2]) for i in range(0, len(pixels), 3)]
    else:
        pixels = list(image.getdata())
    
    # Check saturation (sample-based for speed)
    avg_sat = calculate_saturation_sampled(pixels)
    
    if avg_sat < 15:
        print(f"Low saturation ({avg_sat:.1f}%), using monochrome", file=sys.stderr)
        return (0xFF << 24) | (128 << 16) | (128 << 8) | 128, True
    
    # Quantize and score
    colors = _QuantizeCelebi(pixels, 128)
    scored = _Score.score(colors)
    
    if not scored:
        return None, False
    
    # Verify chroma
    best = scored[0]
    hct = _Hct.from_int(best)
    
    if hct.chroma < 10:
        print(f"Low chroma ({hct.chroma:.1f}), using monochrome", file=sys.stderr)
        return (0xFF << 24) | (128 << 16) | (128 << 8) | 128, True
    
    return best, False


# Scheme class cache
_scheme_cache = {}

def get_scheme_class(scheme_name):
    """Get scheme class with caching."""
    if scheme_name in _scheme_cache:
        return _scheme_cache[scheme_name]
    
    schemes = {
        'tonal-spot': ('materialyoucolor.scheme.scheme_tonal_spot', 'SchemeTonalSpot'),
        'content': ('materialyoucolor.scheme.scheme_content', 'SchemeContent'),
        'expressive': ('materialyoucolor.scheme.scheme_expressive', 'SchemeExpressive'),
        'fidelity': ('materialyoucolor.scheme.scheme_fidelity', 'SchemeFidelity'),
        'monochrome': ('materialyoucolor.scheme.scheme_monochrome', 'SchemeMonochrome'),
        'neutral': ('materialyoucolor.scheme.scheme_neutral', 'SchemeNeutral'),
        'vibrant': ('materialyoucolor.scheme.scheme_vibrant', 'SchemeVibrant'),
        'fruit-salad': ('materialyoucolor.scheme.scheme_fruit_salad', 'SchemeFruitSalad'),
        'rainbow': ('materialyoucolor.scheme.scheme_rainbow', 'SchemeRainbow'),
    }
    
    module_name, class_name = schemes.get(scheme_name, schemes['tonal-spot'])
    
    import importlib
    module = importlib.import_module(module_name)
    cls = getattr(module, class_name)
    _scheme_cache[scheme_name] = cls
    return cls


# ============================================================================
#                          SCHEME GENERATION
# ============================================================================

def generate_material_colors(argb, is_dark_mode, scheme_name='tonal-spot'):
    """Generate Material Design 3 color scheme from seed color."""
    _load_deps()
    
    hct = _Hct.from_int(argb)
    SchemeClass = get_scheme_class(scheme_name)
    scheme = SchemeClass(hct, is_dark_mode, 0.0)
    
    colors = {}
    
    for attr_name in dir(_MaterialDynamicColors):
        if attr_name.startswith('_'):
            continue
        
        attr = getattr(_MaterialDynamicColors, attr_name, None)
        if attr is None or not hasattr(attr, 'get_hct'):
            continue
        
        try:
            rgba = attr.get_hct(scheme).to_rgba()
            colors[attr_name] = "#{:02X}{:02X}{:02X}".format(
                int(rgba[0]), int(rgba[1]), int(rgba[2])
            )
        except Exception:
            pass
    
    return colors


def generate_shell_colors(material_colors, is_dark_mode):
    """Generate shell-specific colors from Material colors."""
    get = material_colors.get
    
    surface = get('surface', '#1a1a1a')
    surface_container = get('surfaceContainer', '#1e1e1e')
    surface_container_high = get('surfaceContainerHigh', '#282828')
    surface_container_highest = get('surfaceContainerHighest', '#333333')
    primary_container = get('primaryContainer', '#004c99')
    
    tint = 0.15
    
    return {
        'backgroundColor': blend_colors(surface_container, primary_container, tint),
        'backgroundColorDim': blend_colors(surface, primary_container, tint * 0.7),
        'backgroundColorBright': blend_colors(surface_container_highest, primary_container, tint),
        'backgroundColorHover': blend_colors(surface_container_highest, primary_container, tint * 1.3),
        
        'foregroundColor': get('onSurface', '#ffffff'),
        'dimmedColor': get('outline', '#888888'),
        
        'accentColor': get('primary', '#007AFF'),
        'accentColorDim': get('primaryContainer', '#004c99'),
        'onAccentColor': get('onPrimary', '#ffffff'),
        
        'secondaryColor': get('secondary', '#666666'),
        'tertiaryColor': get('tertiary', '#888888'),
        
        'surfaceContainer': get('surfaceContainerHigh', get('surfaceContainer', '#1e1e1e')),
        'surfaceContainerLow': get('surfaceContainer', get('surfaceContainerLow', '#1a1a1a')),
        'surfaceContainerHigh': get('surfaceContainerHighest', get('surfaceContainerHigh', '#282828')),
        
        'workspaceActive': get('primary', '#ffffff'),
        'workspaceInactive': get('outlineVariant', '#555555'),
        'workspaceUrgent': get('error', '#ff5555'),
        
        'errorColor': get('error', '#ff5555'),
        'onErrorColor': get('onError', '#ffffff'),
        'successColor': '#4ade80',
        'warningColor': '#ffa726',
        
        'borderColor': get('outlineVariant', '#333333'),
        'shadowColor': get('shadow', '#000000'),
    }


# ============================================================================
#                              MAIN
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description='Generate Material You colors from wallpaper or color'
    )
    
    input_group = parser.add_mutually_exclusive_group(required=True)
    input_group.add_argument('--path', type=str, help='Path to wallpaper image')
    input_group.add_argument('--color', type=str, help='Hex color code')
    
    parser.add_argument('--output', '-o', type=str, help='Output JSON file')
    parser.add_argument('--mode', choices=['dark', 'light'], default='dark')
    parser.add_argument('--scheme', default='tonal-spot',
                        choices=['tonal-spot', 'content', 'expressive', 'fidelity',
                                 'monochrome', 'neutral', 'vibrant', 'fruit-salad', 'rainbow'])
    parser.add_argument('--size', type=int, default=64, help='Resize for extraction')
    parser.add_argument('--debug', action='store_true')
    
    args = parser.parse_args()
    is_dark = args.mode == 'dark'
    use_mono = False
    
    if args.path:
        path = Path(args.path).expanduser()
        if not path.exists():
            print(f"ERROR: File not found: {path}", file=sys.stderr)
            sys.exit(1)
        
        result = extract_color_from_image(path, args.size)
        if not result or result[0] is None:
            print("ERROR: Could not extract color", file=sys.stderr)
            sys.exit(1)
        
        argb, use_mono = result
        
        if args.debug:
            print(f"Extracted: {argb_to_hex(argb)}", file=sys.stderr)
    else:
        argb = hex_to_argb(args.color)
    
    scheme = 'monochrome' if use_mono else args.scheme
    
    material = generate_material_colors(argb, is_dark, scheme)
    shell = generate_shell_colors(material, is_dark)
    
    output = {
        'mode': args.mode,
        'scheme': scheme,
        'seedColor': argb_to_hex(argb),
        'material': material,
        'shell': shell
    }
    
    if args.output:
        out_path = Path(args.output).expanduser()
        out_path.parent.mkdir(parents=True, exist_ok=True)
        with open(out_path, 'w') as f:
            json.dump(output, f, indent=2)
    else:
        print(json.dumps(output, indent=2))
    
    if args.debug:
        _load_deps()
        hct = _Hct.from_int(argb)
        print(f"HCT: H={hct.hue:.1f} C={hct.chroma:.1f} T={hct.tone:.1f}", file=sys.stderr)


if __name__ == '__main__':
    main()
