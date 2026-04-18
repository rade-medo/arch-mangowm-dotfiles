#!/usr/bin/env bash
# ============================================================
#  Arch Linux — MangoWM chroot install script
#
#  Run this INSIDE arch-chroot after you have:
#    1. Partitioned + formatted your disk manually
#    2. Mounted root to /mnt (and /mnt/boot/efi)
#    3. Run pacstrap and genfstab
#    4. Copied this repo into /mnt/root/
#
#  Usage:
#    bash install.sh <username> <hostname> <root-partition>
#    e.g. bash install.sh archer archbox /dev/nvme0n1p3
# ============================================================
set -euo pipefail

# ── Args ─────────────────────────────────────────────────────
if [[ $# -lt 3 ]]; then
  echo "Usage: bash install.sh <username> <hostname> <root-partition>"
  echo "  e.g. bash install.sh archer archbox /dev/nvme0n1p3"
  exit 1
fi

USER_NAME="$1"
HOSTNAME_="$2"
ROOT_PART="$3"

# ── Hardcoded to your setup ───────────────────────────────────
TIMEZONE="Europe/Dublin"
LOCALE="en_IE.UTF-8"
KEYMAP="uk"

# ── 1. Locale + time ─────────────────────────────────────────
echo ">>> Configuring locale and time..."
ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
hwclock --systohc

sed -i "s/^#${LOCALE}/${LOCALE}/" /etc/locale.gen
locale-gen
echo "LANG=${LOCALE}" > /etc/locale.conf
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf

# ── 2. Hostname ───────────────────────────────────────────────
echo ">>> Setting hostname to $HOSTNAME_..."
echo "$HOSTNAME_" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1 localhost
::1       localhost
127.0.1.1 ${HOSTNAME_}.localdomain ${HOSTNAME_}
EOF

# ── 3. Bootloader (systemd-boot) ─────────────────────────────
echo ">>> Installing systemd-boot..."
bootctl install

cat > /boot/loader/loader.conf <<EOF
default arch.conf
timeout 3
console-mode max
editor no
EOF

ROOT_UUID="$(blkid -s UUID -o value "$ROOT_PART")"
cat > /boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=${ROOT_UUID} rw quiet loglevel=3
EOF

# Detect and add the correct microcode
if grep -q AuthenticAMD /proc/cpuinfo 2>/dev/null; then
  sed -i '/\/vmlinuz-linux/a initrd  /amd-ucode.img' /boot/loader/entries/arch.conf
elif grep -q GenuineIntel /proc/cpuinfo 2>/dev/null; then
  sed -i '/\/vmlinuz-linux/a initrd  /intel-ucode.img' /boot/loader/entries/arch.conf
fi

# ── 4. Root password ─────────────────────────────────────────
echo ">>> Set root password:"
passwd

# ── 5. User ──────────────────────────────────────────────────
echo ">>> Creating user $USER_NAME..."
useradd -m -G wheel,video,input,audio -s /bin/bash "$USER_NAME"
echo ">>> Set password for $USER_NAME:"
passwd "$USER_NAME"
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# ── 6. Enable services ───────────────────────────────────────
echo ">>> Enabling services..."
systemctl enable NetworkManager

# ── 7. WM stack (pacman) ─────────────────────────────────────
echo ">>> Installing WM stack..."
pacman -S --noconfirm \
  wayland wayland-protocols xorg-xwayland wlroots \
  pipewire pipewire-pulse wireplumber \
  kitty waybar rofi-wayland \
  swww swaync wl-clipboard cliphist \
  xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
  polkit-gnome wlogout grim slurp \
  ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji \
  brightnessctl playerctl pavucontrol \
  thunar gvfs fastfetch btop starship

# ── 8. yay + MangoWM (AUR) ───────────────────────────────────
echo ">>> Installing yay..."
su - "$USER_NAME" -c '
  cd /tmp
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
'

echo ">>> Installing mangowm-git from AUR..."
su - "$USER_NAME" -c 'yay -S --noconfirm mangowm-git'

# ── Done ─────────────────────────────────────────────────────
echo ""
echo "  ✓ Install complete."
echo ""
echo "  Next steps:"
echo "    exit"
echo "    umount -R /mnt"
echo "    reboot"
echo ""
echo "  After first login:"
echo "    git clone https://github.com/rade-medo/arch-mangowm-dotfiles"
echo "    bash ~/arch-mangowm-dotfiles/post-install.sh"
