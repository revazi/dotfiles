# Load optional machine-local settings.
[[ -r "$HOME/.bashrc.local" ]] && source "$HOME/.bashrc.local"

# fzf shell integration, when installed.
[[ -r "$HOME/.fzf.bash" ]] && source "$HOME/.fzf.bash"
