#!/usr/bin/env bash
# ============================================================
#  Run as your user after first boot into Arch
#  Deploys dotfiles from this repo into ~/.config
# ============================================================
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo ">>> Deploying dotfiles from $DOTFILES"

mkdir -p \
  ~/.config/mango \
  ~/.config/kitty \
  ~/.config/waybar \
  ~/.config/rofi \
  ~/.config/swaync

cp -v "$DOTFILES/.config/mango/config.conf"    ~/.config/mango/config.conf
cp -v "$DOTFILES/.config/kitty/kitty.conf"     ~/.config/kitty/kitty.conf
cp -v "$DOTFILES/.config/waybar/config.jsonc"  ~/.config/waybar/config.jsonc
cp -v "$DOTFILES/.config/waybar/style.css"     ~/.config/waybar/style.css
cp -v "$DOTFILES/.config/rofi/config.rasi"     ~/.config/rofi/config.rasi
cp -v "$DOTFILES/.config/swaync/config.json"   ~/.config/swaync/config.json
cp -v "$DOTFILES/.bashrc"                       ~/.bashrc
cp -v "$DOTFILES/.bash_profile"                 ~/.bash_profile

echo ""
echo ">>> Done. Log out and back in, or run: source ~/.bashrc"
echo ">>> MangoWM will auto-start on TTY1 via .bash_profile"
