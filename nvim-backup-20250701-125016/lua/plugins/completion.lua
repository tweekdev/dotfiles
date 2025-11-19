-- Système de complétion optimisé et simplifié
return {
	-- Sources de complétion LSP
	{
		"hrsh7th/cmp-nvim-lsp",
		dependencies = { "hrsh7th/cmp-emoji" },
	},

	-- Sources de complétion additionnelles
	{ "hrsh7th/cmp-buffer", event = "InsertEnter" },
	{ "hrsh7th/cmp-path", event = "InsertEnter" },
	{ "hrsh7th/cmp-cmdline", event = "CmdlineEnter" },
	{ "hrsh7th/cmp-nvim-lua", ft = "lua" },

	-- Système de snippets
	{
		"L3MON4D3/LuaSnip",
		build = "make install_jsregexp",
		dependencies = {
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
		},
		config = function()
			local luasnip = require("luasnip")
			luasnip.config.set_config({
				history = true,
				updateevents = "TextChanged,TextChangedI",
				enable_autosnippets = true,
			})
			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},

	-- Icônes pour la complétion
	{ "onsails/lspkind.nvim", lazy = true },

	-- Le moteur de complétion principal
	{
		"hrsh7th/nvim-cmp",
		event = { "InsertEnter", "CmdlineEnter" },
		dependencies = { "onsails/lspkind.nvim" },
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			local lspkind = require("lspkind")

			-- Configuration des commandes Vim
			cmp.setup.cmdline(":", {
				sources = cmp.config.sources({
					{ name = "path" },
					{ name = "cmdline" },
				}),
			})

			-- Configuration globale simplifiée
			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},

				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},

				formatting = {
					format = lspkind.cmp_format({
						mode = "symbol_text",
						maxwidth = 50,
						before = function(entry, vim_item)
							vim_item.menu = ({
								copilot = "[AI]",
								codeium = "[AI]",
								nvim_lsp = "[LSP]",
								luasnip = "[SNP]",
								buffer = "[BUF]",
								path = "[PTH]",
								cmdline = "[CMD]",
								emoji = "[EMJ]",
							})[entry.source.name]
							return vim_item
						end,
					}),
				},

				performance = {
					max_view_entries = 15, -- Limiter pour de meilleures performances
				},

				completion = {
					completeopt = "menu,menuone,noinsert",
					keyword_length = 1,
				},

				-- Mappings optimisés avec priorité IA
				mapping = {
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = false }),

					-- Tab avec priorité IA optimisée
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							local current_entry = cmp.get_selected_entry()

							-- Si l'entrée actuelle est de l'IA, l'accepter
							if
								current_entry
								and (current_entry.source.name == "copilot" or current_entry.source.name == "codeium")
							then
								cmp.confirm({ select = true })
								return
							end

							-- Chercher la première suggestion IA
							local entries = cmp.get_entries()
							for i, entry in ipairs(entries) do
								if entry.source.name == "copilot" or entry.source.name == "codeium" then
									cmp.select({ index = i - 1 })
									cmp.confirm({ select = true })
									return
								end
							end

							-- Pas d'IA, navigation normale
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),

					-- Shift+Tab pour LSP quand IA présente
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							local entries = cmp.get_entries()
							local has_ai = false

							-- Vérifier si IA disponible
							for _, entry in ipairs(entries) do
								if entry.source.name == "copilot" or entry.source.name == "codeium" then
									has_ai = true
									break
								end
							end

							-- Si IA présente, aller au LSP
							if has_ai then
								for i, entry in ipairs(entries) do
									if entry.source.name == "nvim_lsp" then
										cmp.select({ index = i - 1 })
										return
									end
								end
							end

							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				},

				-- Sources par ordre de priorité
				sources = cmp.config.sources({
					{ name = "copilot", group_index = 1, priority = 100 },
					{ name = "codeium", group_index = 1, priority = 90 },
					{ name = "nvim_lsp", group_index = 1, priority = 80 },
					{ name = "luasnip", group_index = 1, priority = 70 },
					{ name = "nvim_lua", group_index = 2, priority = 60 },
					{ name = "path", group_index = 2, priority = 50 },
					{ name = "buffer", group_index = 2, priority = 40 },
					{ name = "emoji", group_index = 3, priority = 30 },
				}),

				sorting = {
					comparators = {
						cmp.config.compare.exact,
						cmp.config.compare.score,
						cmp.config.compare.kind,
						cmp.config.compare.length,
						cmp.config.compare.order,
					},
				},
			})
		end,
	},
}
