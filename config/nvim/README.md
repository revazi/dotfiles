# Nvim config

NeoVim configuration with custome keybinding.

## Plugins used

### Plugin manager

1. wbthomason/packer.nvim - Packer
2. nvim-lua/plenary.nvim - additional functions used in many plugins

### File explorer and icons

1. nvim-tree
2. nvim-web-devicons

### Essentials

1. lualine
2. vim-tmux-navigator - tmux & split window navigation
3. szw/vim-maximizer - zoom in and out of current pane
4. tpope/vim-surround - add, delete, change surroundings
5. vim-ReplaceWithRegister
6. numToStr/Comment.nvim - comment using `gc`
7. lewis6991/gitsigns.nvim - show line modifications on the left side
8. windwp/nvim-autopairs
9. windwp/nvim-ts-autotag

### FZF with telescope

1. nvim-telescope/telescope-fzf-native.nvim
2. nvim-telescope/telescope.nvim

### Formatting, linting, lsp, autocomplete

1. [hrsh7th/nvim-cmp](https://github.com/hrsh7th/nvim-cmp) - A completion engine plugin for neovim written in Lua.
2. [hrsh7th/cmp-buffer](https://github.com/hrsh7th/cmp-buffer) - source for text in buffer
3. [hrsh7th/cmp-path](https://github.com/hrsh7th/cmp-path) - source for file system paths
4. [L3MON4D3/LuaSnip](https://github.com/L3MON4D3/LuaSnip) - snippet engine
5. [saadparwaiz1/cmp_luasnip](https://github.com/saadparwaiz1/cmp_luasnip) - for autocompletion
6. [rafamadriz/friendly-snippets](https://github.com/rafamadriz/friendly-snippets) - Snippets collection for a set of different programming languages for faster development.
7. [williamboman/mason.nvim](https://github.com/williamboman/mason.nvim) - Portable package manager for Neovim that runs everywhere Neovim runs - manages lsp servers, linters, DAP(Debug Adapter Protocol) servers & formatters
8. [neovim/nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) - configure language servers
9. [williamboman/mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim) - connection between lspconfig and mason
10. [hrsh7th/cmp-nvim-lsp](https://github.com/hrsh7th/cmp-nvim-lsp) - nvim-cmp source for neovim's built-in language server client.
11. [glepnir/lspsaga.nvim](https://github.com/glepnir/lspsaga.nvim) - A light-weight lsp plugin based on neovim's built-in lsp with a highly performant UI.
12. [jose-elias-alvarez/typescript.nvim](https://github.com/jose-elias-alvarez/typescript.nvim) - additional functionality for typescript server (e.g. rename file & update imports)
13. [onsails/lspkind.nvim](https://github.com/onsails/lspkind.nvim) - This tiny plugin adds vscode-like pictograms to neovim built-in lsp
14. [jose-elias-alvarez/null-ls.nvim](https://github.com/jose-elias-alvarez/null-ls.nvim) - Use Neovim as a language server to inject LSP diagnostics, code actions, and more via Lua. - configuration for formatters & linters
15. [jayp0521/mason-null-ls.nvim](https://github.com/jay-babu/mason-null-ls.nvim) - mason-null-ls bridges mason.nvim with the null-ls plugin - making it easier to use both plugins together.
16. [tnvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) - The goal of nvim-treesitter is both to provide a simple and easy way to use the interface for tree-sitter in Neovim and to provide some basic functionality such as highlighting based on it.

### Theme

1. bluz71/vim-nightfly-guicolors

### Todo

1. [folke/trouble.nvim](https://github.com/folke/trouble.nvim) - A pretty list for showing diagnostics, references, telescope results, quickfix and location lists to help you solve all the trouble your code is causing.

## Installation

### Prerequisites for telescope

#### [fd](https://github.com/sharkdp/fd)

`brew install fd`

#### [ripgrep](https://github.com/BurntSushi/ripgrep)

`brew install ripgrep`

### Keymaps

#### nvim-tree

`<CR>` edit open a file or folder; root will cd to the above directory
`o`
`<2-LeftMouse>`
`<C-e>` edit_in_place edit the file in place, effectively replacing the tree explorer
`O` edit_no_picker same as (edit) with no window picker
`<C-]>` cd cd in the directory under the cursor
`<2-RightMouse>`
`<C-v>` vsplit open the file in a vertical split
`<C-x>` split open the file in a horizontal split
`<C-t>` tabnew open the file in a new tab
`<` prev_sibling navigate to the previous sibling of current file/directory
`>` next_sibling navigate to the next sibling of current file/directory
`P` parent_node move cursor to the parent directory
`<BS>` close_node close current opened directory or parent
`<Tab>` preview open the file as a preview (keeps the cursor in the tree)
`K` first_sibling navigate to the first sibling of current file/directory
`J` last_sibling navigate to the last sibling of current file/directory
`I` toggle_git_ignored toggle visibility of files/folders hidden via |git.ignore| option
`H` toggle_dotfiles toggle visibility of dotfiles via |filters.dotfiles| option
`U` toggle_custom toggle visibility of files/folders hidden via |filters.custom| option
`R` refresh refresh the tree
`a` create add a file; leaving a trailing `/` will add a directory
`d` remove delete a file (will prompt for confirmation)
`D` trash trash a file via |trash| option
`r` rename rename a file
`<C-r>` full_rename rename a file and omit the filename on input
`x` cut add/remove file/directory to cut clipboard
`c` copy add/remove file/directory to copy clipboard
`p` paste paste from clipboard; cut clipboard has precedence over copy; will prompt for confirmation
`y` copy_name copy name to system clipboard
`Y` copy_path copy relative path to system clipboard
`gy` copy_absolute_path copy absolute path to system clipboard
`[e` prev_diag_item go to next diagnostic item
`[c` prev_git_item go to next git item
`]e` next_diag_item go to prev diagnostic item
`]c` next_git_item go to prev git item
`-` dir_up navigate up to the parent directory of the current file/directory
`s` system_open open a file with default system application or a folder with default file manager, using |system_open| option
`f` live_filter live filter nodes dynamically based on regex matching.
`F` clear_live_filter clear live filter
`q` close close tree window
`W` collapse_all collapse the whole tree
`E` expand_all expand the whole tree, stopping after expanding |actions.expand_all.max_folder_discovery| folders; this might hang neovim for a while if running on a big folder
`S` search_node prompt the user to enter a path and then expands the tree to match the path
`.` run_file_command enter vim command mode with the file the cursor is on
`<C-k>` toggle_file_info toggle a popup with file infos about the file under the cursor
`g?` toggle_help toggle help
`m` toggle_mark Toggle node in bookmarks
`bmv` bulk_move Move all bookmarked nodes into specified location
