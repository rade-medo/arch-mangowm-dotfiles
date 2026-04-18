# ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Environment
export EDITOR=nvim
export VISUAL=nvim
export TERMINAL=kitty
export BROWSER=firefox

# Wayland hints
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export SDL_VIDEODRIVER=wayland
export CLUTTER_BACKEND=wayland
export XDG_CURRENT_DESKTOP=mango
export XDG_SESSION_TYPE=wayland

# Prompt via starship (if installed), else minimal PS1
if command -v starship &>/dev/null; then
  eval "$(starship init bash)"
else
  PS1='[\u@\h \W]\$ '
fi

# Aliases
alias ll='ls -lah --color=auto'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias v='nvim'
alias vim='nvim'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph'
alias clip='wl-copy'
alias paste='wl-paste'
alias btop='btop'
alias ff='fastfetch'
alias ..='cd ..'
alias ...='cd ../..'

# fastfetch on interactive login
if command -v fastfetch &>/dev/null; then
  fastfetch
fi
