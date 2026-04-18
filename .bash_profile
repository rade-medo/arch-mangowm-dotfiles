# ~/.bash_profile
# Source .bashrc
[[ -f ~/.bashrc ]] && . ~/.bashrc

# Auto-start MangoWM on TTY1
if [ -z "${WAYLAND_DISPLAY}" ] && [ "${XDG_VTNR:-0}" -eq 1 ]; then
  exec mango
fi
