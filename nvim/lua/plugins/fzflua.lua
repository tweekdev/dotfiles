if true then
	return {}
end
return {
	"ibhagwan/fzf-lua",
	-- optional for icon support
	-- dependencies = { "nvim-tree/nvim-web-devicons" },
	-- or if using mini.icons/mini.nvim
	dependencies = { "echasnovski/mini.icons" },
	opts = {
		files = {
			multiprocess = true, -- run command in a separate process
			find_opts = [[-type f \! -path '*/node_modules/*']],
			hidden = true, -- enable hidden files by default
			rg_opts = [[--color=never --hidden --files -g "!.git"]],
			fd_opts = [[--color=never --hidden --type f --type l --exclude .git]],
			dir_opts = [[/s/b/a:-d]],
			cmd = "fd --type file --follow --hidden --exclude .git",
		},
		live_grep = {
			cmd = "rg --column --line-number --no-heading --color=always --smart-case --",
		},
		lsp = {
			cwd = vim.uv.cwd(),
		},
		previewers = {
			cat = {
				cmd = "cat",
				args = "-n",
			},
			bat = {
				cmd = "bat",
				args = "--color=always --style=numbers,changes",
			},
			head = {
				cmd = "head",
				args = nil,
			},
			git_diff = {
				-- if required, use `{file}` for argument positioning
				-- e.g. `cmd_modified = "git diff --color HEAD {file} | cut -c -30"`
				cmd_deleted = "git diff --color HEAD --",
				cmd_modified = "git diff --color HEAD",
				cmd_untracked = "git diff --color --no-index /dev/null",
				-- git-delta is automatically detected as pager, set `pager=false`
				-- to disable, can also be set under 'git.status.preview_pager'
			},
			man = {
				-- NOTE: remove the `-c` flag when using man-db
				-- replace with `man -P cat %s | col -bx` on OSX
				cmd = "man -c %s | col -bx",
			},
			builtin = {
				syntax = true, -- preview syntax highlight?
				syntax_limit_l = 0, -- syntax limit (lines), 0=nolimit
				syntax_limit_b = 1024 * 1024, -- syntax limit (bytes), 0=nolimit
				limit_b = 1024 * 1024 * 10, -- preview limit (bytes), 0=nolimit
				-- previewer treesitter options:
				-- enable specific filetypes with: `{ enabled = { "lua" } }
				-- exclude specific filetypes with: `{ disabled = { "lua" } }
				-- disable `nvim-treesitter-context` with `context = false`
				-- disable fully with: `treesitter = false` or `{ enabled = false }`
				treesitter = {
					enabled = true,
					disabled = {},
					-- nvim-treesitter-context config options
					context = { max_lines = 1, trim_scope = "inner" },
				},
				-- By default, the main window dimensions are calculated as if the
				-- preview is visible, when hidden the main window will extend to
				-- full size. Set the below to "extend" to prevent the main window
				-- from being modified when toggling the preview.
				toggle_behavior = "default",
				-- Title transform function, by default only displays the tail
				-- title_fnamemodify = function(s) return vim.fn.fnamemodify(s, ":t") end,
				-- preview extensions using a custom shell command:
				-- for example, use `viu` for image previews
				-- will do nothing if `viu` isn't executable
				extensions = {
					-- neovim terminal only supports `viu` block output
					["png"] = { "viu", "-b" },
					-- by default the filename is added as last argument
					-- if required, use `{file}` for argument positioning
					["svg"] = { "chafa", "{file}" },
					["jpg"] = { "ueberzug" },
				},
				-- if using `ueberzug` in the above extensions map
				-- set the default image scaler, possible scalers:
				--   false (none), "crop", "distort", "fit_contain",
				--   "contain", "forced_cover", "cover"
				-- https://github.com/seebye/ueberzug
				ueberzug_scaler = "cover",
				-- render_markdown.nvim integration, enabled by default for markdown
				render_markdown = { enabled = true, filetypes = { ["markdown"] = true } },
				-- snacks.images integration, enabled by default
				snacks_image = { enabled = true, render_inline = true },
			},
			-- Code Action previewers, default is "codeaction" (set via `lsp.code_actions.previewer`)
			-- "codeaction_native" uses fzf's native previewer, recommended when combined with git-delta
			codeaction = {
				-- options for vim.diff(): https://neovim.io/doc/user/lua.html#vim.diff()
				diff_opts = { ctxlen = 3 },
			},
			codeaction_native = {
				diff_opts = { ctxlen = 3 },
				-- git-delta is automatically detected as pager, set `pager=false`
				-- to disable, can also be set under 'lsp.code_actions.preview_pager'
				-- recommended styling for delta
				--pager = [[delta --width=$COLUMNS --hunk-header-style="omit" --file-style="omit"]],
			},
		},
	},
	keys = {
		{
			"<leader>fF",
			function()
				require("fzf-lua").files()
			end,
			desc = "Find Files in project directory",
		},
		{
			"<leader>fg",
			function()
				require("fzf-lua").live_grep()
			end,
			desc = "Find by grepping in project directory",
		},
		{
			"<leader>fc",
			function()
				require("fzf-lua").files({ cwd = vim.fn.stdpath("config") })
			end,
			desc = "Find in neovim configuration",
		},
		{
			"<leader>fh",
			function()
				require("fzf-lua").helptags()
			end,
			desc = "[F]ind [H]elp",
		},
		{
			"<leader>fk",
			function()
				require("fzf-lua").keymaps()
			end,
			desc = "[F]ind [K]eymaps",
		},
		{
			"<leader>fw",
			function()
				require("fzf-lua").grep_cword()
			end,
			desc = "[F]ind current [W]ord",
		},
		{
			"<leader>fW",
			function()
				require("fzf-lua").grep_cWORD()
			end,
			desc = "[F]ind current [W]ORD",
		},
		{
			"<leader>ft",
			function()
				require("fzf-lua").diagnostics_document()
			end,
			desc = "[F]ind [D]iagnostics",
		},
		{
			"<leader>fd",
			function()
				require("fzf-lua").lsp_definitions()
			end,
			desc = "[F]ind [D]efinitions",
		},
		{
			"<leader>fD",
			function()
				require("fzf-lua").lsp_declarations()
			end,
			desc = "[F]ind [D]eclarations",
		},

		{
			"<leader>fi",
			function()
				require("fzf-lua").lsp_implementations()
			end,
			desc = "[F]ind [I]mplementations",
		},
		{
			"<leader>fR",
			function()
				require("fzf-lua").resume()
			end,
			desc = "[F]ind [R]esume",
		},
		{
			"<leader>fo",
			function()
				require("fzf-lua").oldfiles()
			end,
			desc = "[F]ind [O]ld Files",
		},
		{
			"<leader>fb",
			function()
				require("fzf-lua").buffers()
			end,
			desc = "[,] Find existing buffers",
		},
		{
			"<leader>/",
			function()
				require("fzf-lua").lgrep_curbuf()
			end,
			desc = "[/] Live grep the current buffer",
		},
		{
			"<leader>fr",
			function()
				require("fzf-lua").lsp_references()
			end,
			desc = "[F]ind [R]eferences",
		},
	},
}
