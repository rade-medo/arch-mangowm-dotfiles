# arch-mangowm-dotfiles

Minimal Arch Linux setup with MangoWM (Wayland compositor), Kitty terminal, Waybar, Rofi, and SwayNC.

**Target machine:** Beelink SER8 — Ryzen 7 8745HS, Radeon 780M iGPU (RDNA 3)

## Structure

```
.
├── install.sh              # Chroot install script (locale, boot, user, WM stack)
├── post-install.sh         # Run as your user after first boot to deploy dotfiles
├── .bashrc                 # Bash config, Wayland env vars, aliases
├── .bash_profile           # Sources .bashrc + auto-starts MangoWM on TTY1
└── .config/
    ├── mango/config.conf   # MangoWM keybinds, autostart, gaps, decoration
    ├── kitty/kitty.conf    # Kitty terminal — Nord palette, JetBrainsMono Nerd
    ├── waybar/config.jsonc # Top bar — workspaces, clock, battery, network
    ├── waybar/style.css    # Dark Nord bar styling
    ├── rofi/config.rasi    # App launcher
    └── swaync/config.json  # Notification daemon
```

## Install

### Prerequisites

Before running `install.sh` you need to have done the following manually from the Arch live ISO:

**1. Partition and format your disk:**
```bash
# Example layout (adjust to your disk)
cfdisk /dev/nvme0n1
# EFI  — 512MB–1G, type EFI System
# SWAP — 8G,       type Linux swap
# ROOT — rest,     type Linux filesystem

mkfs.fat -F32 /dev/nvme0n1p1
mkswap        /dev/nvme0n1p2
mkfs.ext4     /dev/nvme0n1p3
```

**2. Mount:**
```bash
mount /dev/nvme0n1p3 /mnt
mkdir -p /mnt/boot/efi
mount /dev/nvme0n1p1 /mnt/boot/efi
swapon /dev/nvme0n1p2
```

**3. pacstrap + genfstab:**
```bash
pacstrap -K /mnt base base-devel linux linux-firmware linux-headers \
  networkmanager sudo git neovim man-db man-pages
genfstab -U /mnt >> /mnt/etc/fstab
```

### Run the install script

**4. Clone this repo into the new system and chroot:**
```bash
cp -r arch-mangowm-dotfiles /mnt/root/
arch-chroot /mnt
```

**5. Run install.sh inside chroot:**
```bash
bash /root/arch-mangowm-dotfiles/install.sh <username> <hostname> <root-partition>
# e.g.
bash /root/arch-mangowm-dotfiles/install.sh archer archbox /dev/nvme0n1p3
```

This will:
- Set locale, timezone (Europe/Dublin), keyboard (UK)
- Configure hostname and `/etc/hosts`
- Install `systemd-boot` with AMD microcode
- Install AMD GPU drivers (mesa, vulkan-radeon, libva)
- Create your user with wheel/sudo access
- Install the full Wayland + MangoWM stack via pacman
- Install `yay` and `mangowm-git` from the AUR
- Log everything to `/var/log/arch-install.log`

**6. Exit, unmount, reboot:**
```bash
exit
umount -R /mnt
reboot
```

### Deploy dotfiles

**7. After first login on TTY, clone and deploy:**
```bash
git clone https://github.com/rade-medo/arch-mangowm-dotfiles
bash ~/arch-mangowm-dotfiles/post-install.sh
```

MangoWM will auto-start on next login via `.bash_profile`.

## Keybinds

| Key | Action |
|-----|--------|
| `Alt + Enter` | Open Kitty |
| `Alt + Space` | Rofi launcher |
| `Alt + Q` | Kill window |
| `Super + M` | Exit MangoWM |
| `Super + F` | Fullscreen |
| `Super + E` | Thunar file manager |
| `Super + L` | Wlogout |
| `Alt + V` | Clipboard history (cliphist + rofi) |
| `Alt + H/J/K/L` | Focus left/down/up/right |
| `Alt + Shift + H/J/K/L` | Move window |
| `Alt + 1–5` | Switch workspace |
| `Alt + Shift + 1–5` | Move window to workspace |
| `Print` | Screenshot (full) |
| `Shift + Print` | Screenshot (region select) |
| Media keys | Volume, brightness, playback |

## Stack

| Component | Package |
|-----------|--------|
| Compositor | `mangowm-git` (AUR) |
| Terminal | `kitty` |
| Bar | `waybar` |
| Launcher | `rofi-wayland` |
| Notifications | `swaync` |
| Wallpaper | `swww` |
| Clipboard | `wl-clipboard` + `cliphist` |
| Audio | `pipewire` + `pipewire-pulse` + `pipewire-alsa` + `wireplumber` |
| GPU | `mesa` + `vulkan-radeon` + `libva-mesa-driver` |
| Screenshots | `grim` + `slurp` |
| Shell | `bash` + `starship` |
| Font | `ttf-jetbrains-mono-nerd` |
