# AGENTS.md

## Project

Personal Neovim Configuration

## Goal

Maintain and improve a personal Neovim setup focused on productivity, readability, fast navigation, coding assistance, and long-term maintainability.

## Project summary

This repository contains a personal Neovim configuration. It is used as a daily development environment for software engineering work, including Python, Django, JavaScript, TypeScript, React, shell scripting, infrastructure files, and general text editing.

The configuration should remain clean, understandable, and easy to modify over time.

## Current stack direction

- Editor: Neovim
- Configuration language: Lua
- Plugin manager: lazy.nvim
- Main focus areas:
  - LSP support
  - Completion
  - Treesitter
  - Formatting and linting
  - File navigation
  - Git workflow
  - Telescope-style search
  - Developer ergonomics

## Core engineering principles

- Keep the config simple and maintainable
- Prefer clear Lua modules over clever abstractions
- Make the smallest useful change possible
- Avoid unnecessary plugin additions
- Prefer stable, well-maintained plugins
- Optimize for daily usability, startup time, and readability
- Keep keymaps predictable and easy to remember
- Avoid hidden behavior that is hard to debug
- Prefer explicit configuration over magic

## Working rules

- Only do the task that was requested
- Before coding, provide a short plan
- After completing the requested task, stop
- No file changes without explicit confirmation
- Do not add unrelated improvements
- Do not broadly refactor the config unless explicitly asked
- Do not replace existing plugins unless explicitly requested
- Do not change keymaps casually
- If something is ambiguous, choose the simplest sensible option and state it clearly
- Preserve the user’s existing workflow unless the task explicitly asks to change it

## Architecture constraints

- Use lazy.nvim as the plugin manager
- Keep plugin specs modular and easy to inspect
- Avoid large framework-style Neovim distributions
- Do not convert this config to LazyVim, AstroNvim, LunarVim, NvChad, or similar unless explicitly requested
- Avoid unnecessary dependencies
- Avoid adding external system dependencies unless clearly needed
- Do not introduce complex custom plugin infrastructure
- Do not add generated code or machine-specific paths unless explicitly requested

## File organization conventions

- Keep configuration split into clear Lua modules
- Prefer predictable file names
- Keep plugin configuration close to the plugin spec when practical
- Keep shared options, keymaps, and autocmds in obvious places
- Avoid deeply nested abstractions
- Avoid duplicate configuration across files
- Remove dead code when modifying related areas
- Keep comments useful and concise

## Lua conventions

- Use idiomatic Lua
- Prefer local variables where appropriate
- Keep functions small and readable
- Avoid clever metaprogramming
- Avoid global variables unless Neovim specifically requires them
- Prefer vim.keymap.set for keymaps
- Prefer vim.api.nvim_create_autocmd for autocommands
- Prefer vim.api.nvim_create_augroup for grouped autocmds
- Use pcall only when optional behavior needs graceful fallback

## Plugin conventions

- Add a new plugin only when it solves a clear problem
- Prefer configuring existing plugins before adding new ones
- Prefer mature plugins with active maintenance
- Keep plugin specs readable
- Use lazy-loading where it makes sense
- Avoid excessive lazy-loading that makes behavior confusing
- Do not add overlapping plugins for the same purpose unless explicitly requested
- Keep plugin options explicit
- Do not pin plugin versions unless there is a clear reason
- Do not run plugin update commands unless explicitly requested

## Keymap conventions

- Do not overwrite existing keymaps without calling it out
- Keep keymaps mnemonic and consistent
- Prefer <leader> mappings for custom actions
- Avoid mappings that conflict with common Vim behavior unless explicitly requested
- Add descriptions to keymaps where supported
- Keep related keymaps grouped together
- Do not introduce large keymap systems unless requested

## LSP conventions

- Keep LSP configuration simple and debuggable
- Prefer built-in Neovim LSP behavior where possible
- Keep server-specific settings isolated and readable
- Do not add language servers unless the user asks for that language or workflow
- Avoid global LSP changes that may affect unrelated languages
- Preserve existing diagnostics behavior unless explicitly asked to change it
- Prefer project-local tooling when available

## Formatting and linting conventions

- Do not enable format-on-save globally unless explicitly requested
- Prefer project-specific formatters and linters
- Avoid surprising automatic changes
- Make formatting behavior explicit
- Keep formatter configuration easy to disable or override
- Do not introduce new formatters that may conflict with existing project conventions

## Treesitter conventions

- Add parsers only for languages the user actually works with
- Avoid unnecessary parser lists
- Keep Treesitter configuration minimal and clear
- Do not rely on Treesitter for behavior that should be handled by LSP or editor options

## Completion conventions

- Keep completion behavior predictable
- Avoid noisy suggestions
- Avoid large completion frameworks unless already in use
- Do not change completion key behavior casually
- Preserve existing snippet behavior unless explicitly requested

## UI conventions

- Keep UI changes minimal and purposeful
- Avoid excessive visual noise
- Preserve readability
- Do not change colorschemes unless explicitly requested
- Do not add dashboards, animations, or decorative UI unless requested
- Prefer practical visibility improvements over aesthetic-only changes

## Git conventions

- Keep Git integrations lightweight
- Do not add complex Git workflows unless requested
- Avoid mappings that perform destructive Git actions
- Prefer read-only or confirmation-based Git actions by default

## Performance conventions

- Avoid plugins or configuration that noticeably slow startup
- Prefer lazy-loading for heavy plugins
- Do not add expensive autocommands
- Avoid running shell commands on startup unless necessary
- Keep startup behavior predictable and debuggable

## Machine-specific configuration

- Do not hardcode local absolute paths unless explicitly requested
- Prefer environment variables or documented local overrides
- Keep secrets out of the repository
- Do not include API keys, tokens, private hostnames, or credentials
- Do not assume a specific operating system unless the task requires it
- If OS-specific behavior is needed, keep it isolated and documented

## Documentation rules

- Update documentation when behavior changes in a way the user needs to know
- Document new keymaps, dependencies, or setup steps
- Keep documentation short and practical
- Do not write long explanations for obvious config changes
- Prefer examples over abstract descriptions

## Testing and verification

When changing the config, verify as much as practical:

- Run Lua formatting if configured
- Check that Neovim starts without errors
- Check plugin specs load correctly
- Check modified keymaps work
- Check affected LSP, formatter, or plugin behavior manually
- Use :checkhealth when relevant
- Use :Lazy when plugin loading or installation is affected
- Use :messages to inspect startup or runtime errors

## Common commands

Use only commands relevant to the task.

sh nvim

vim :checkhealth

vim :Lazy

vim :Lazy sync

vim :messages

vim :lua vim.print(vim.inspect(...))

## Expected output for each task

Return:

1. Plan
2. Changes made
3. Files created/edited
4. Commands to run
5. Verification steps
6. Decisions/tradeoffs

## Change discipline

Before making changes, explain what will change and why.

After making changes, summarize only the relevant edits.

Do not continue into additional improvements after the requested task is complete.
