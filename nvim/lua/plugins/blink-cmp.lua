return {
	{
		"saghen/blink.compat",
		-- use the latest release, via version = '*', if you also use the latest release for blink.cmp
		version = "*",
		-- lazy.nvim will automatically load the plugin when it's required by blink.cmp
		lazy = true,
		-- make sure to set opts so that lazy.nvim calls blink.compat's setup
		opts = {},
	},
	-- GitHub Copilot : suggestions IA dans le menu blink.cmp (via copilot.lua + blink-copilot)
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		opts = {
			suggestion = { enabled = false },
			panel = { enabled = false },
			filetypes = { markdown = true, help = true },
		},
	},
	{
		"saghen/blink.cmp",
		-- optional: provides snippets for the snippet source
		dependencies = {
			"rafamadriz/friendly-snippets",
			"fang2hou/blink-copilot",
			"zbirenbaum/copilot.lua",
		},

		-- use a release tag to download pre-built binaries
		version = "1.*",
		-- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
		-- build = 'cargo build --release',
		-- If you use nix, you can build from source using latest nightly rust with:
		-- build = 'nix run .#build-plugin',

		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			-- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
			-- 'super-tab' for mappings similar to vscode (tab to accept)
			-- 'enter' for enter to accept
			-- 'none' for no mappings
			--
			-- All presets have the following mappings:
			-- C-space: Open menu or open docs if already open
			-- C-n/C-p or Up/Down: Select next/previous item
			-- C-e: Hide menu
			-- C-k: Toggle signature help (if signature.enabled = true)
			--
			-- See :h blink-cmp-config-keymap for defining your own keymap
			-- preset "super-tab" : Tab = accepter, Enter = nouvelle ligne
			-- Navigation (inclus dans le preset) : C-n / Down = suivant, C-p / Up = précédent, C-Space = ouvrir menu, C-e = fermer
			keymap = {
				preset = "super-tab",
				["<C-Z>"] = { "accept", "fallback" },
			},

			appearance = {
				use_nvim_cmp_as_default = true,
				nerd_font_variant = "mono",
				kind_icons = {
					Copilot = "",
					Codeium = "󰘦",
					Text = "󰉿",
					Method = "󰆧",
					Function = "󰊕",
					Constructor = "",
					Field = "󰜢",
					Variable = "󰀫",
					Class = "󰠱",
					Interface = "",
					Module = "",
					Property = "󰜢",
					Unit = "󰑭",
					Value = "󰎠",
					Enum = "",
					Keyword = "󰌋",
					Snippet = "",
					Color = "󰏘",
					File = "󰈙",
					Reference = "󰈇",
					Folder = "󰉕",
					EnumMember = "",
					Constant = "󰏿",
					Struct = "󰙅",
					Event = "",
					Operator = "󰆕",
					TypeParameter = "",
				},

				-- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
				-- Adjusts spacing to ensure icons are aligned
				nerd_font_variant = "mono",
			},
			-- (Default) Only show the documentation popup when manually triggered
			completion = {
				documentation = { auto_show = true },
				accept = {
					create_undo_point = true,
					auto_brackets = {
						enabled = true,
					},
				},
				menu = {
					auto_show = true, -- afficher la complétion en tapant (LSP, buffer, etc.)
					enabled = true,
					min_width = 15,
					max_height = 10,
					border = "none",
					winblend = 0,
					scrollbar = true,
					direction_priority = { "s", "n" },

					draw = {
						treesitter = { "lsp" },
						columns = {
							{ "kind_icon" },
							{ "label", "label_description", gap = 1 },
							{ "source_name" },
						},
						components = {
							source_name = {
								width = { fill = true },
								text = function(ctx)
									local source_display = {
										lsp = "[LSP]",
										copilot = "[Copilot]",
										path = "[Path]",
										snippets = "[Snip]",
										buffer = "[Buf]",
									}
									return source_display[ctx.source_name] or string.format("[%s]", ctx.source_name)
								end,
								highlight = "BlinkCmpSource",
							},
						},
					},
				},

				-- 🌟 GHOST TEXT (Virtual Text) pour les suggestions IA
				ghost_text = {
					enabled = true,
				},
			},
			signature = { enabled = true },
			-- Default list of enabled providers (LSP + Copilot IA + path, snippets, buffer)
			sources = {
				default = { "lsp", "copilot", "path", "snippets", "buffer" },
				providers = {
					copilot = {
						name = "copilot",
						module = "blink-copilot",
						async = true,
						score_offset = 100,
					},
				},
			},

			-- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
			-- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
			-- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
			--
			-- See the fuzzy documentation for more information
			fuzzy = { implementation = "prefer_rust_with_warning" },
		},
		opts_extend = { "sources.default", "sources.providers" },
	},
	-- IA : Copilot dans le menu (ci‑dessus) ; OpenCode pour ask/prompts : <leader>oa, <leader>os (voir opencode.lua)
}
