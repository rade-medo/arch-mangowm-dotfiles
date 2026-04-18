#!/usr/bin/env bash
# ============================================================
#  Arch Linux — MangoWM chroot install script
#  Target: Beelink SER8 (Ryzen 7 8745HS, Radeon 780M iGPU)
#
#  Run inside arch-chroot after:
#    1. Partitioned + formatted disk manually
#    2. Mounted root to /mnt (and EFI to /mnt/boot or /mnt/boot/efi)
#    3. pacstrap + genfstab done
#
#  Usage:
#    bash install.sh <username> <hostname> <root-partition>
#    e.g. bash install.sh archer archbox /dev/nvme0n1p3
# ============================================================
set -euo pipefail

exec > >(tee /var/log/arch-install.log) 2>&1

# ── Guards ────────────────────────────────────────────────
[[ -f /etc/arch-release ]] || { echo "ERROR: Run inside arch-chroot."; exit 1; }
[[ $EUID -eq 0 ]]          || { echo "ERROR: Run as root."; exit 1; }

[[ -s /etc/fstab ]] || echo "WARNING: /etc/fstab is empty — did you run genfstab?"

if ! mountpoint -q /boot && ! mountpoint -q /boot/efi; then
  echo "ERROR: No EFI partition mounted at /boot or /boot/efi"
  exit 1
fi

# ── Args ─────────────────────────────────────────────────────
if [[ $# -lt 3 ]]; then
  echo "Usage: bash install.sh <username> <hostname> <root-partition>"
  echo "  e.g. bash install.sh archer archbox /dev/nvme0n1p3"
  exit 1
fi

USER_NAME="$1"
HOSTNAME_="$2"
ROOT_PART="$3"

# ── Hardcoded: SER8 / Ireland ──────────────────────────────────
TIMEZONE="Europe/Dublin"
LOCALE="en_IE.UTF-8"
KEYMAP="uk"

echo ">>> Starting Arch install for SER8 | user=$USER_NAME host=$HOSTNAME_"

# ── 1. Essential base packages ──────────────────────────────
echo ">>> Installing base packages..."
pacman -S --needed --noconfirm \
  linux linux-firmware linux-headers \
  sudo networkmanager base-devel \
  git dbus pciutils \
  man-db man-pages

systemctl enable NetworkManager
systemctl enable dbus

# ── 2. AMD CPU — microcode ──────────────────────────────────
echo ">>> Installing AMD microcode..."
pacman -S --noconfirm amd-ucode

# ── 3. AMD GPU — Radeon 780M (RDNA 3) ──────────────────────
echo ">>> Installing AMD GPU drivers (Radeon 780M / RDNA 3)..."
pacman -S --noconfirm \
  mesa \
  vulkan-radeon \
  libva-mesa-driver \
  libva-utils \
  lib32-mesa \
  lib32-vulkan-radeon

# ── 4. Locale + time ─────────────────────────────────────────
echo ">>> Configuring locale and time..."
ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
hwclock --systohc

sed -i "s/^#${LOCALE}/${LOCALE}/" /etc/locale.gen || true
locale-gen

echo "LANG=${LOCALE}"   > /etc/locale.conf
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf

# ── 5. Hostname ───────────────────────────────────────────────
echo ">>> Setting hostname to $HOSTNAME_..."
echo "$HOSTNAME_" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1 localhost
::1       localhost
127.0.1.1 ${HOSTNAME_}.localdomain ${HOSTNAME_}
EOF

# ── 6. Bootloader (systemd-boot) ─────────────────────────────
echo ">>> Installing systemd-boot..."
bootctl install

cat > /boot/loader/loader.conf <<EOF
default arch.conf
timeout 3
console-mode max
editor no
EOF

ROOT_UUID="$(blkid -s UUID -o value "$ROOT_PART")"
[[ -n "$ROOT_UUID" ]] || { echo "ERROR: Could not get UUID for $ROOT_PART"; exit 1; }

cat > /boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /amd-ucode.img
initrd  /initramfs-linux.img
options root=UUID=${ROOT_UUID} rw quiet loglevel=3 amdgpu.sg_display=0
EOF

# ── 7. Regenerate initramfs ───────────────────────────────────
echo ">>> Regenerating initramfs..."
mkinitcpio -P

# ── 8. Root password ─────────────────────────────────────────
echo ">>> Set root password:"
passwd

# ── 9. User ──────────────────────────────────────────────────
echo ">>> Creating user $USER_NAME..."
if ! id "$USER_NAME" &>/dev/null; then
  useradd -m -G wheel,video,input,audio -s /bin/bash "$USER_NAME"
fi

echo ">>> Set password for $USER_NAME:"
passwd "$USER_NAME"

echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel
visudo -cf /etc/sudoers.d/wheel || { echo "ERROR: sudoers syntax invalid"; exit 1; }

# ── 10. Wayland / MangoWM stack ───────────────────────────────
echo ">>> Installing WM stack..."
pacman -S --noconfirm \
  wayland wayland-protocols wlroots xorg-xwayland \
  pipewire pipewire-pulse pipewire-alsa wireplumber \
  kitty waybar rofi-wayland \
  swww swaync wl-clipboard cliphist \
  xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
  xdg-user-dirs \
  polkit-gnome wlogout grim slurp \
  ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji \
  brightnessctl playerctl pavucontrol \
  thunar gvfs fastfetch btop starship

# ── 11. yay (AUR helper) ──────────────────────────────────────
echo ">>> Installing yay..."
su - "$USER_NAME" -c '
  cd /tmp
  rm -rf yay
  git clone https://aur.archlinux.org/yay.git
  cd yay
  MAKEFLAGS="-j$(nproc)" makepkg -si --noconfirm
'

# ── 12. MangoWM (AUR) ──────────────────────────────────────────
echo ">>> Installing MangoWM..."
su - "$USER_NAME" -c 'yay -S --noconfirm mangowm-git'

# ── 13. XDG user dirs ───────────────────────────────────────────
su - "$USER_NAME" -c 'xdg-user-dirs-update'

# ── Done ─────────────────────────────────────────────────────
echo ""
echo "=================================================="
echo " Install Complete"
echo "=================================================="
echo " User:      $USER_NAME"
echo " Hostname:  $HOSTNAME_"
echo " Root UUID: $ROOT_UUID"
echo " GPU:       Radeon 780M (RDNA 3) — mesa + vulkan-radeon"
echo " Log:       /var/log/arch-install.log"
echo "=================================================="
echo ""
echo " Next:"
echo "   exit"
echo "   umount -R /mnt"
echo "   reboot"
echo ""
echo " After first login:"
echo "   git clone https://github.com/rade-medo/arch-mangowm-dotfiles"
echo "   bash ~/arch-mangowm-dotfiles/post-install.sh"
echo ""
