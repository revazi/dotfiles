#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
backed_up=false

link_file() {
  local source="$DOTFILES/$1"
  local target="$HOME/$2"

  mkdir -p "$(dirname "$target")"

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    printf 'ok      %s\n' "$target"
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    local backup="$BACKUP_DIR/$2"
    mkdir -p "$(dirname "$backup")"
    mv "$target" "$backup"
    backed_up=true
    printf 'backup  %s -> %s\n' "$target" "$backup"
  fi

  ln -s "$source" "$target"
  printf 'link    %s -> %s\n' "$target" "$source"
}

link_file zsh/.zshrc .zshrc
link_file bash/.bashrc .bashrc
link_file bash/.profile .profile
link_file git/.gitconfig .gitconfig
link_file config/nvim .config/nvim
link_file config/tmux .config/tmux
link_file config/tmux/tmux.conf .tmux.conf
link_file config/btop .config/btop
link_file config/pai-pi/settings.json .config/pai-pi/settings.json

if [[ ! -e "$HOME/.zshrc.local" ]]; then
  cat > "$HOME/.zshrc.local" <<'LOCAL'
# Secrets and settings specific to this machine belong here.
# This file is intentionally not tracked by the dotfiles repository.
# export NPM_TOKEN='...'
LOCAL
  chmod 600 "$HOME/.zshrc.local"
  printf 'create  %s\n' "$HOME/.zshrc.local"
fi

if [[ "$backed_up" == true ]]; then
  printf '\nPrevious files were preserved in %s\n' "$BACKUP_DIR"
fi

printf '\nDotfiles installed. Open a new shell or run: exec zsh\n'
