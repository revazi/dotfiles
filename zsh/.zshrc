pathprepend() {
  for ARG in "$@"
  do
    if [ -d "$ARG" ] && [[ ":$PATH:" != *":$ARG:"* ]]; then
        PATH="$ARG${PATH:+":$PATH"}"
    fi
  done
}

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Homebrew lives in different prefixes on Apple Silicon and Intel Macs.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export DISABLE_AUTO_TITLE='true'

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="agnoster"


# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git sudo history-substring-search zsh-autosuggestions zsh-syntax-highlighting poetry)

[[ -r "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

alias vi='nvim'
alias vim='nvim'
alias ovi='vim'
alias fabric='fabric-ai'

alias pai='PI_CODING_AGENT_DIR=~/.config/pai-pi pi'


autoload -Uz compinit && compinit -i

prompt_context(){}


pathprepend $HOME/bin
pathprepend $HOME/.local/bin

# Prepend editorconfig-checker to PATH
pathprepend /opt/homebrew/bin/editorconfig-checker

# Help pyenv compile Python against Homebrew's keg-only libraries.
if command -v brew >/dev/null 2>&1 && OPENSSL_PREFIX="$(brew --prefix openssl@3 2>/dev/null)"; then
  READLINE_PREFIX="$(brew --prefix readline 2>/dev/null)"
  SQLITE_PREFIX="$(brew --prefix sqlite3 2>/dev/null)"
  XZ_PREFIX="$(brew --prefix xz 2>/dev/null)"
  ZLIB_PREFIX="$(brew --prefix zlib 2>/dev/null)"

  export PYTHON_BUILD_HOMEBREW_OPENSSL_FORMULA="openssl@3"
  export LDFLAGS="-L$OPENSSL_PREFIX/lib -L$READLINE_PREFIX/lib -L$SQLITE_PREFIX/lib -L$XZ_PREFIX/lib -L$ZLIB_PREFIX/lib"
  export CPPFLAGS="-I$OPENSSL_PREFIX/include -I$READLINE_PREFIX/include -I$SQLITE_PREFIX/include -I$XZ_PREFIX/include -I$ZLIB_PREFIX/include"
  export PKG_CONFIG_PATH="$OPENSSL_PREFIX/lib/pkgconfig:$READLINE_PREFIX/lib/pkgconfig:$SQLITE_PREFIX/lib/pkgconfig:$XZ_PREFIX/lib/pkgconfig:$ZLIB_PREFIX/lib/pkgconfig"
  export PYTHON_CONFIGURE_OPTS="--enable-shared --with-openssl=$OPENSSL_PREFIX"
fi

export NVM_DIR="$HOME/.nvm"
if command -v brew >/dev/null 2>&1; then
  NVM_PREFIX="$(brew --prefix nvm 2>/dev/null)"
  [[ -s "$NVM_PREFIX/nvm.sh" ]] && source "$NVM_PREFIX/nvm.sh"
  [[ -s "$NVM_PREFIX/etc/bash_completion.d/nvm" ]] && source "$NVM_PREFIX/etc/bash_completion.d/nvm"
fi

# Golang environment variables
# export GOROOT=$(brew --prefix go)/libexec
# export GOPATH=$HOME/go
# export PATH=$GOPATH/bin:$GOROOT/bin:$HOME/.local/bin:$PATH

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
command -v pyenv >/dev/null 2>&1 && pathprepend "$(pyenv root)/shims"
pathprepend /usr/local/sbin

[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"


# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
pathprepend /opt/homebrew/opt/ruby/bin
pathprepend "$HOME/.gem/bin"
command -v rbenv >/dev/null 2>&1 && eval "$(rbenv init - zsh)"
pathprepend "$HOME/.docker/bin"

# Machine-local values and secrets (for example NPM_TOKEN) belong here.
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
