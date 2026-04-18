#!/usr/bin/env bash
# ============================================================
#  Arch Linux — MangoWM + Kitty minimal install script
#  Phase 1 (partition): run from Arch live ISO as root
#  Phase 2 (chroot):    run inside arch-chroot as root
# ============================================================
set -euo pipefail

USER_NAME="${1:-archer}"
HOSTNAME_="${2:-archbox}"
TIMEZONE="Europe/Dublin"
LOCALE="en_IE.UTF-8"
KEYMAP="uk"
DISK="${3:-/dev/nvme0n1}"
EFI_PART="${DISK}p1"
SWAP_PART="${DISK}p2"
ROOT_PART="${DISK}p3"

# ── Phase 1: partition, format, mount, pacstrap ──────────────
partition_disk() {
  echo ">>> Partitioning $DISK — all data will be lost!"
  read -rp "Type YES to continue: " confirm
  [[ $confirm == YES ]] || { echo "Aborted."; exit 1; }

  sgdisk -Z "$DISK"
  sgdisk -n 1:0:+1G   -t 1:ef00 -c 1:"EFI"  "$DISK"
  sgdisk -n 2:0:+8G   -t 2:8200 -c 2:"SWAP" "$DISK"
  sgdisk -n 3:0:0     -t 3:8300 -c 3:"ROOT" "$DISK"

  mkfs.fat -F32 "$EFI_PART"
  mkswap        "$SWAP_PART"
  mkfs.ext4 -L ROOT "$ROOT_PART"

  mount "$ROOT_PART" /mnt
  mkdir -p /mnt/boot/efi
  mount "$EFI_PART" /mnt/boot/efi
  swapon "$SWAP_PART"
}

base_install() {
  pacstrap -K /mnt \
    base base-devel linux linux-firmware linux-headers \
    networkmanager sudo git neovim man-db man-pages \
    intel-ucode amd-ucode

  genfstab -U /mnt >> /mnt/etc/fstab

  echo ""
  echo ">>> pacstrap done. Next steps:"
  echo "  cp -r \$(pwd) /mnt/root/arch-mangowm-dotfiles"
  echo "  arch-chroot /mnt"
  echo "  bash /root/arch-mangowm-dotfiles/install.sh $USER_NAME $HOSTNAME_ $DISK chroot"
}

# ── Phase 2: chroot config ───────────────────────────────────
chroot_config() {
  ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
  hwclock --systohc

  sed -i "s/^#${LOCALE}/${LOCALE}/" /etc/locale.gen
  locale-gen
  echo "LANG=${LOCALE}" > /etc/locale.conf
  echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf

  echo "$HOSTNAME_" > /etc/hostname
  cat > /etc/hosts <<EOF
127.0.0.1 localhost
::1       localhost
127.0.1.1 ${HOSTNAME_}.localdomain ${HOSTNAME_}
EOF

  bootctl install
  cat > /boot/loader/loader.conf <<EOF
default arch.conf
timeout 3
console-mode max
editor no
EOF

  ROOT_UUID="$(blkid -s UUID -o value "$ROOT_PART")"
  # Remove whichever microcode line doesn't apply to your CPU
  cat > /boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /amd-ucode.img
initrd  /initramfs-linux.img
options root=UUID=${ROOT_UUID} rw quiet loglevel=3
EOF

  echo ">>> Set root password:"
  passwd

  useradd -m -G wheel,video,input,audio -s /bin/bash "$USER_NAME"
  echo ">>> Set password for $USER_NAME:"
  passwd "$USER_NAME"

  sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

  systemctl enable NetworkManager
}

# ── WM stack install ─────────────────────────────────────────
install_desktop() {
  pacman -S --noconfirm \
    wayland wayland-protocols xorg-xwayland wlroots \
    pipewire pipewire-pulse wireplumber \
    kitty waybar rofi-wayland \
    swww swaync wl-clipboard cliphist \
    xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
    polkit-gnome wlogout \
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji \
    brightnessctl playerctl pavucontrol \
    thunar gvfs fastfetch btop

  # yay for AUR
  su - "$USER_NAME" -c '
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
  '

  # MangoWM from AUR
  su - "$USER_NAME" -c 'yay -S --noconfirm mangowm-git'
}

# ── Entry ────────────────────────────────────────────────────
case "${4:-help}" in
  partition)
    partition_disk
    base_install
    ;;
  chroot)
    chroot_config
    install_desktop
    echo ""
    echo ">>> Done. Exit chroot, umount -R /mnt, reboot."
    echo ">>> After first login run: bash ~/arch-mangowm-dotfiles/post-install.sh"
    ;;
  *)
    echo "Usage:"
    echo "  bash install.sh <user> <hostname> <disk> partition"
    echo "  bash install.sh <user> <hostname> <disk> chroot"
    ;;
esac
