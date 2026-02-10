-- opencode.nvim: intégration OpenCode (opencode.ai) avec Neovim.
-- Utilise GitHub Copilot (ou tout provider OpenCode) une fois connecté via le CLI.
--
-- Prérequis:
-- 1. Installer le CLI OpenCode: brew install anomalyco/tap/opencode
--    ou: npm i -g opencode-ai
-- 2. Lancer une fois en terminal: opencode
--    Puis dans le TUI: /connect → choisir "GitHub Copilot" → auth via github.com/login/device
--    Les credentials sont stockés dans ~/.local/share/opencode/auth.json
--
-- Doc: https://opencode.ai/docs/providers/#github-copilot
-- Plugin: https://github.com/NickvanDyke/opencode.nvim
return {
	"nickjvandyke/opencode.nvim",
	dependencies = {
		{ "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
	},
	event = "VeryLazy",
	config = function()
		vim.g.opencode_opts = {
			-- Démarre opencode via un terminal Snacks à droite si aucun processus n'est trouvé.
			provider = {
				enabled = "snacks",
				cmd = "opencode --port",
				snacks = {
					auto_close = true,
					win = {
						position = "right",
						enter = false,
						on_buf = function(win)
							require("opencode.keymaps").apply(win.buf)
						end,
						wo = { winbar = "" },
						bo = { filetype = "opencode_terminal" },
					},
				},
			},
			-- Contexte envoyé aux prompts
			contexts = nil, -- garde les défauts (@this, @buffer, @diagnostics, @diff, etc.)
			-- Prompts disponibles dans select()
			prompts = nil, -- garde les défauts (explain, review, fix, implement, etc.)
			ask = {
				prompt = "Ask opencode: ",
				blink_cmp_sources = { "opencode", "buffer" },
			},
			events = {
				enabled = true,
				reload = true,
				permissions = { enabled = true, idle_delay_ms = 1000 },
			},
		}

		vim.o.autoread = true -- requis pour opts.events.reload

		local opencode = require("opencode")
		-- Ask: saisir un prompt (avec @this, @buffer, etc.)
		vim.keymap.set({ "n", "x" }, "<leader>oa", function()
			opencode.ask("@this: ", { submit = true })
		end, { desc = "OpenCode: ask (with @this)" })
		vim.keymap.set({ "n", "x" }, "<leader>oA", function()
			opencode.ask("", { submit = false })
		end, { desc = "OpenCode: ask (free prompt)" })
		-- Select: prompts, commandes, contrôle du provider
		vim.keymap.set({ "n", "x" }, "<leader>os", opencode.select, { desc = "OpenCode: select action/prompt" })
		-- Toggle: afficher/masquer le TUI OpenCode
		vim.keymap.set({ "n", "t" }, "<leader>ot", opencode.toggle, { desc = "OpenCode: toggle" })
		-- Operator: appliquer un prompt à une range (ex. goip = ligne + "implement")
		vim.keymap.set({ "n", "x" }, "<leader>go", function()
			return opencode.operator("@this ")
		end, { desc = "OpenCode: add range to prompt", expr = true })
		-- Scroll dans le TUI (quand le focus est dans le terminal opencode)
		vim.keymap.set("n", "<leader>o<C-u>", function()
			opencode.command("session.half.page.up")
		end, { desc = "OpenCode: scroll up" })
		vim.keymap.set("n", "<leader>o<C-d>", function()
			opencode.command("session.half.page.down")
		end, { desc = "OpenCode: scroll down" })
	end,
}
