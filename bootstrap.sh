#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(uname -s)" != Darwin ]]; then
  printf 'This bootstrap script currently supports macOS only.\n' >&2
  exit 1
fi

if ! xcode-select -p >/dev/null 2>&1; then
  printf 'Install the Xcode command-line tools, then run this script again:\n'
  printf '  xcode-select --install\n'
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

brew bundle --file "$DOTFILES/Brewfile"

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
clone_plugin() {
  local repository="$1"
  local destination="$ZSH_CUSTOM/plugins/$2"
  [[ -d "$destination" ]] || git clone --depth=1 "$repository" "$destination"
}
clone_plugin https://github.com/zsh-users/zsh-autosuggestions zsh-autosuggestions
clone_plugin https://github.com/zsh-users/zsh-syntax-highlighting zsh-syntax-highlighting
clone_plugin https://github.com/darvid/zsh-poetry poetry

"$DOTFILES/install.sh"

printf '\nBootstrap complete. Open Neovim once to install its plugins.\n'
