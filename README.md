# arch-mangowm-dotfiles

Minimal Arch Linux setup with MangoWM (Wayland compositor), Kitty terminal, Waybar, Rofi, and SwayNC.

## Structure

```
.
├── install.sh              # Full install script (partition → chroot → WM stack)
├── post-install.sh         # Run as user after first boot to deploy dotfiles
├── .bashrc                 # Bash config
├── .bash_profile           # Auto-start MangoWM on TTY1
└── .config/
    ├── mango/config.conf   # MangoWM keybinds, rules, autostart
    ├── kitty/kitty.conf    # Kitty terminal (Nord palette, JetBrainsMono Nerd)
    ├── waybar/config.jsonc # Minimal top bar
    ├── waybar/style.css    # Bar styling
    ├── rofi/config.rasi    # App launcher
    └── swaync/config.json  # Notification daemon
```

## Usage

### 1. Boot Arch ISO, then:
```bash
bash install.sh <user> <hostname> <disk> partition
# e.g. bash install.sh archer archbox /dev/nvme0n1 partition
```

### 2. Copy this repo into the new system and chroot:
```bash
cp -r arch-mangowm-dotfiles /mnt/root/
arch-chroot /mnt
bash /root/arch-mangowm-dotfiles/install.sh <user> <hostname> <disk> chroot
```

### 3. Reboot, log in on TTY, then:
```bash
bash ~/arch-mangowm-dotfiles/post-install.sh
```

## Keybinds

| Key | Action |
|-----|--------|
| `Alt + Enter` | Open Kitty |
| `Alt + Space` | Rofi launcher |
| `Alt + Q` | Kill window |
| `Super + M` | Exit MangoWM |
| `Super + F` | Fullscreen |
| `Alt + H/J/K/L` | Focus direction |
| `Alt + Shift + H/J/K/L` | Move window |
| `Alt + 1-5` | Switch workspace |
| `Alt + Shift + 1-5` | Move to workspace |

## Dependencies (auto-installed)

- `mangowm-git` (AUR)
- `kitty`, `waybar`, `rofi-wayland`
- `swww`, `swaync`, `wl-clipboard`, `cliphist`
- `pipewire`, `pipewire-pulse`, `wireplumber`
- `ttf-jetbrains-mono-nerd`, `starship`, `fastfetch`, `btop`
