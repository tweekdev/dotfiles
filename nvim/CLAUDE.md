# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal Neovim configuration using lazy.nvim as the plugin manager. All config is in Lua.

## Architecture

**Entry point:** `init.lua` -> `require("config.lazy")`

**Load order:**
1. `lua/config/lazy.lua` - Bootstraps lazy.nvim, sets leader keys (Space / backslash)
2. `lua/config/options.lua` - Loaded before plugins (vim options, 2-space indent, relative line numbers)
3. `lua/plugins/*.lua` - Auto-discovered by lazy.nvim (each file returns a plugin spec table)
4. `lua/config/keymaps.lua` - Loaded after plugins (global keymaps, which-key groups)
5. `lua/config/theme.lua` + `lua/config/theme_default.lua` - Theme persistence system (saves selected theme to `theme_default.lua` and updates `lazy.lua` install colorscheme)
6. `lua/config/autocmds.lua` - Autocommands (yank highlight, restore cursor, close with q, auto-create dirs)

**Plugin specs:** Each file in `lua/plugins/` returns a lazy.nvim spec table with optional `dependencies`, `opts`, `config`, `keys`, `event`, `ft`, `cmd` fields.

**Primary UI layer:** Snacks.nvim (`lua/plugins/snack.lua`) handles picker, explorer, terminal, notifications, dashboard, git browse, zen mode, and toggles. Telescope is a minimal fallback.

## Key Subsystems

- **LSP** (`lua/plugins/lsp.lua`): nvim-lspconfig + mason + mason-lspconfig. Servers: ts_ls, eslint, lua_ls, bashls, tailwindcss, cssls, emmet_ls, marksman. Uses blink.cmp for capabilities. LSP keymaps use Snacks picker with Telescope fallback.
- **Scala** (`lua/plugins/scala.lua`): nvim-metals (separate from mason LSP). Requires Coursier. Includes DAP integration.
- **Completion** (`lua/plugins/blink-cmp.lua`): blink.cmp with Copilot source via blink-copilot.
- **Formatting** (`lua/plugins/conform.lua`): conform.nvim - prettier/prettierd (JS/TS), stylua (Lua), isort+black (Python), rustfmt (Rust), scalafmt (Scala).
- **Theme** (`lua/config/theme.lua`): Custom theme manager with persistence. Supports rose-pine, kanagawa, cursor-dark, vscode-modern. Picker via `<leader>uC`.

## Conventions

- Leader key is Space. Local leader is backslash.
- German keyboard langmap is configured in options (e.g. `ü` -> `[`).
- Plugin files go in `lua/plugins/`. Archived/unused plugins go in `lua/plugins/archived/`.
- Keybinding groups: `<leader>a` AI, `<leader>c` code, `<leader>d` debugger, `<leader>f` find, `<leader>g` git, `<leader>s` search, `<leader>u` UI toggles, `<leader>x` trouble/diagnostics.
- Window navigation: `<C-h/j/k/l>` or `sh/sj/sk/sl`.
