# Voidline 🚀

A modern, Material You-inspired desktop shell for Hyprland, built with [Quickshell](https://github.com/quickshell-mirror/quickshell).

> **⚠️ Design Showcase**  
> This is currently a **design showcase / prototype** that was AI-coded for rapid iteration.  
> This is **not the final production version** – a proper hand-coded release is planned.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Hyprland](https://img.shields.io/badge/Hyprland-compatible-cyan)
![QML](https://img.shields.io/badge/Qt-QML-green)

## 👤 Creator

**Okami** - Design & Development


## 🔧 Requirements

- [Quickshell](https://github.com/quickshell-mirror/quickshell) - The shell framework
- [Hyprland](https://hyprland.org/) - Wayland compositor
- Qt 6.x with QML support
- Python 3.x (for color generation scripts)
- `python-pillow` - Image processing for color extraction
- `python-gobject` - For Bluetooth agent (optional)

## 📦 Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/voidline.git ~/.config/quickshell/voidline
   ```

2. **Copy the example settings:**
   ```bash
   cp ~/.config/quickshell/voidline/settings.example.json ~/.config/quickshell/voidline/settings.json
   ```

3. **Install Hyprland configuration:**
   ```bash
   # Backup your existing Hyprland config first!
   cp -r ~/.config/hypr ~/.config/hypr.backup
   
   # Copy Voidline's Hyprland config
   cp -r ~/.config/quickshell/voidline/hypr/* ~/.config/hypr/
   ```
   
   > **Note:** The `hypr/` folder contains pre-configured Hyprland settings that work with Voidline.
   > Review and customize `hyprland.conf` for your monitor setup before using.

4. **Configure Hyprland keybinds:**
   ```bash
   # Add these to your hyprland.conf
   bind = SUPER, space, global, quickshell:toggleLauncher
   bind = SUPER, A, global, quickshell:toggleActionCenter
   bind = SUPER SHIFT, S, global, quickshell:toggleSettings
   ```

## ⌨️ Keybinds

| Shortcut | Action |
|----------|--------|
| `SUPER + Space` | Toggle App Launcher |
| `SUPER + A` | Toggle Action Center |
| `SUPER + Shift + S` | Toggle Settings |
| `SUPER + Tab` | Window Overview |

## 🎨 Customization

### Colors
The shell automatically extracts colors from your wallpaper using Material You algorithms. You can also manually set colors in the Settings panel.

### Configuration
Edit `misc/Config.qml` to customize:
- Bar dimensions and style
- Panel sizes and radii
- Animation durations
- Font settings
- Default applications

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Quickshell](https://github.com/quickshell-mirror/quickshell) - The amazing shell framework
- [Material Design](https://material.io/) - Design inspiration
- [Hyprland](https://hyprland.org/) - The compositor that makes this possible
