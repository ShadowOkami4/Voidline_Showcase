# Recon Shell 🚀

A modern, Material You-inspired desktop shell for Hyprland, built with [Quickshell](https://github.com/quickshell-mirror/quickshell).

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Hyprland](https://img.shields.io/badge/Hyprland-compatible-cyan)
![QML](https://img.shields.io/badge/Qt-QML-green)

## ✨ Features

- **🎨 Material You Theming** - Dynamic color extraction from wallpaper
- **🖥️ Multi-Monitor Support** - Works seamlessly across multiple displays
- **📱 Action Center** - Quick settings and notifications in one place
- **🚀 App Launcher** - Fast application search and launch
- **🔊 Sound Panel** - Volume controls with device switching
- **📶 Network Panel** - WiFi management and connection status
- **📲 Bluetooth Panel** - Device pairing and management
- **⚡ System Indicators** - Battery, volume, network status at a glance
- **🖼️ Window Overview** - Hyprland workspace overview
- **⌨️ Keybinds Cheatsheet** - Quick reference for shortcuts
- **🔒 Lock Screen** - Beautiful lockscreen integration
- **⚙️ Settings Panel** - Comprehensive system configuration

## 📁 Project Structure

```
recon/
├── shell.qml              # Entry point - loads the shell
├── qmldir                 # Module registration
├── settings.json          # User preferences (gitignored)
│
├── components/            # Reusable UI components
│   ├── StyledRect.qml     # Styled rectangle with theming
│   ├── StyledText.qml     # Themed text component
│   ├── MaterialIcon.qml   # Material Design icons
│   ├── MarqueeText.qml    # Scrolling text
│   └── StateLayer.qml     # Ripple/hover effects
│
├── indicators/            # Bar widgets
│   ├── ClockWidget.qml    # Time and date display
│   ├── SystemIndicators.qml # Battery, volume, wifi icons
│   ├── WorkspaceIndicator.qml # Workspace dots/buttons
│   ├── MediaControl.qml   # Media playback controls
│   └── TrayItem.qml       # System tray items
│
├── misc/                  # Core services and configuration
│   ├── Config.qml         # Styling configuration (singleton)
│   ├── ShellState.qml     # Global state management (singleton)
│   ├── Bar.qml            # Top bar implementation
│   ├── ColorScheme.qml    # Material You color generation
│   ├── SoundHandler.qml   # Audio management (singleton)
│   ├── NetworkHandler.qml # Network management (singleton)
│   ├── BluetoothHandler.qml # Bluetooth management (singleton)
│   ├── DisplayHandler.qml # Display management (singleton)
│   └── Appearance.qml     # Visual appearance settings
│
├── panels/                # Popup panels and overlays
│   ├── ActionCenter.qml   # Quick settings + notifications
│   ├── AppLauncher.qml    # Application launcher
│   ├── NetworkPanel.qml   # WiFi configuration
│   ├── SoundPanel.qml     # Volume controls
│   ├── BluetoothPanel.qml # Bluetooth devices
│   ├── PowerPanel.qml     # Power options
│   ├── MediaPanel.qml     # Media controls
│   ├── SettingsPanel.qml  # Settings window
│   ├── LockScreen.qml     # Lock screen
│   └── WindowOverview.qml # Window overview
│
├── settings/              # Settings panel pages
│   ├── AboutPage.qml
│   ├── SoundPage.qml
│   ├── NetworkPage.qml
│   ├── BluetoothPage.qml
│   ├── DisplayPage.qml
│   └── PersonalizePage.qml
│
└── scripts/               # Helper scripts
    ├── colorgen.py        # Color extraction from images
    ├── bluetooth-agent.py # Bluetooth pairing agent
    └── apply-colors.sh    # Apply generated colors
```

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
   git clone https://github.com/YOUR_USERNAME/recon-shell.git ~/.config/quickshell/recon
   ```

2. **Copy the example settings:**
   ```bash
   cp ~/.config/quickshell/recon/settings.example.json ~/.config/quickshell/recon/settings.json
   ```

3. **Add to Hyprland config:**
   ```bash
   # ~/.config/hypr/hyprland.conf
   exec-once = quickshell -p ~/.config/quickshell/recon
   ```

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
