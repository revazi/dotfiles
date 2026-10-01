# Dotfiles

Portable macOS shell, Git, tmux, Neovim, btop, and selected Pi settings.
The installer uses ordinary symlinks—no dotfile manager required.

## New Mac

Install Apple's command-line tools first:

```bash
xcode-select --install
```

Then clone and bootstrap:

```bash
git clone https://github.com/revazi/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

`bootstrap.sh` installs the curated Homebrew packages, Oh My Zsh and its
plugins, then runs `install.sh`. Open Neovim once afterward so lazy.nvim can
install the pinned plugins.

If the repository is already cloned and dependencies are installed, only run:

```bash
~/dotfiles/install.sh
```

Existing files are moved to a timestamped directory under
`~/.dotfiles-backup/` before symlinks are created. Re-running the installer is
safe.

## Secrets and machine-local configuration

Secrets are deliberately excluded. Put values such as `NPM_TOKEN` in:

```bash
~/.zshrc.local
```

That file is sourced by `.zshrc` but is not tracked. Authentication files such
as `~/.npmrc`, SSH keys, GitHub CLI hosts, cloud credentials, and Pi auth files
must be transferred through their own secure login/import flows.

## Updating

Edit the linked files normally, then commit from this repository:

```bash
cd ~/dotfiles
git status
git add -A
git commit -m "Update dotfiles"
git push
```

Homebrew packages are intentionally curated in `Brewfile`; add tools there as
needed instead of dumping every package installed on one machine.
