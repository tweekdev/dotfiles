-- Configuration Emmet simplifiée et stable
return {
	"mattn/emmet-vim",
	ft = { "html", "css", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" },
	init = function()
		-- Configuration globale Emmet simple
		vim.g.user_emmet_mode = "i" -- Seulement en mode insertion pour éviter les conflits
		vim.g.user_emmet_install_global = 0 -- Ne pas installer les mappings globaux
		vim.g.user_emmet_leader_key = "<C-z>" -- Leader key pour Emmet

		-- Settings spécifiques par filetype
		vim.g.user_emmet_settings = {
			javascript = { extends = "jsx" },
			typescript = { extends = "jsx" },
			javascriptreact = { extends = "jsx" },
			typescriptreact = { extends = "jsx" },
		}
	end,
	config = function()
		-- Configuration simple au chargement du plugin
		local emmet_group = vim.api.nvim_create_augroup("EmmetSetup", { clear = true })

		vim.api.nvim_create_autocmd("FileType", {
			group = emmet_group,
			pattern = {
				"html",
				"css",
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
				"vue",
				"svelte",
			},
			callback = function()
				-- Keymaps simples sans appel aux fonctions internes
				local opts = { buffer = true, silent = true, desc = "Emmet expand" }

				-- Raccourci principal pour l'expansion Emmet
				vim.keymap.set("i", "<C-z>,", "<C-y>,", opts)
				vim.keymap.set("n", "<C-z>,", "i<C-y>,<Esc>", opts)

				-- Raccourci alternatif
				vim.keymap.set("i", "<C-z>;", "<C-y>,", opts)
			end,
		})
	end,
}
