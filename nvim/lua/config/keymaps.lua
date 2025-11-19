local wk = require("which-key")

vim.keymap.set("n", "-", "<CMD>Oil --float<CR>", { desc = "Open parent directory" })

vim.keymap.set("n", "gl", function()
	vim.diagnostic.open_float()
end, { desc = "Open Diagnostics in Float" })

vim.keymap.set("n", "<leader>cf", function()
	require("conform").format({
		lsp_format = "fallback",
	})
end, { desc = "Format current file" })

-- Window management
-- Split windows
vim.keymap.set("n", "<leader>|", vim.cmd.vs, { desc = "Split window vertically" })
vim.keymap.set("n", "<leader>-", vim.cmd.sp, { desc = "Split window horizontally" })

-- Navigate between windows
vim.keymap.set("n", "<c-h>", ":wincmd h<CR>", { desc = "Navigate to left window" })
vim.keymap.set("n", "<c-j>", ":wincmd j<CR>", { desc = "Navigate to bottom window" })
vim.keymap.set("n", "<c-k>", ":wincmd k<CR>", { desc = "Navigate to top window" })
vim.keymap.set("n", "<c-l>", ":wincmd l<CR>", { desc = "Navigate to right window" })

-- Alternative window navigation with 's' prefix
vim.keymap.set("n", "sh", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "sj", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "sk", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set("n", "sl", "<C-w>l", { desc = "Move to right window" })

-- Specific tools
-- Navigation
vim.keymap.set("n", "<leader>e", function()
	_G.neotree.toggle_root()
end, { desc = "Explorer NeoTree (Root Dir)" })
vim.keymap.set("n", "<leader>E", function()
	_G.neotree.toggle_cwd()
end, { desc = "Explorer NeoTree (CWD)" })

-- Which-key configuration for group labels and advanced mappings
wk.add({
	-- Hidden groups
	{ "<leader>a", hidden = true },

	-- Sessions
	{ "<leader>s", group = "+sessions" },

	-- LSP and Code actions
	{ "<leader>c", group = "+code" },
	{ "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", desc = "Code action" },
	{ "<leader>rn", ":IncRename ", desc = "Rename" },
	{ "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP references (Trouble)" },
	{ "<leader>cs", "<cmd>Trouble symbols toggle<CR>", desc = "Symbols (Trouble)" },

	-- Debugger
	{ "<leader>d", group = "+debugger" },
	{ "<leader>dt", "<cmd>DapToggleBreakpoint<CR>", desc = "Toggle Breakpoint" },
	{ "<leader>dc", "<cmd>DapContinue<CR>", desc = "Continue" },
	{ "<leader>dx", "<cmd>DapTerminate<CR>", desc = "Terminate" },
	{ "<leader>do", "<cmd>DapStepOver<CR>", desc = "Step Over" },

	-- Git - utilise notre système Git unifié
	{ "<leader>G", group = "+git" },
	{ "<leader>Gs", "<cmd>Git<CR>", desc = "Git status" },
	{ "<leader>Gg", "<cmd>LazyGit<CR>", desc = "LazyGit" },
	{ "<leader>Gf", "<cmd>LazyGitFilterCurrentFile<CR>", desc = "File history" },
	{ "<leader>Gl", "<cmd>LazyGitFilter<CR>", desc = "Git log" },
	{ "<leader>Gb", "<cmd>Git blame<CR>", desc = "Git blame" },
	{ "<leader>Gd", "<cmd>Gdiffsplit<CR>", desc = "Git diff split" },
	{ "<leader>Gdo", "<cmd>DiffviewOpen<CR>", desc = "DiffView: Open" },
	{ "<leader>Gdh", "<cmd>DiffviewFileHistory %<CR>", desc = "DiffView: File History" },
	{
		"<leader>Ghp",
		function()
			_G.git.preview_hunk()
		end,
		desc = "Git: Preview hunk",
	},
	{
		"<leader>Ghb",
		function()
			_G.git.blame_line()
		end,
		desc = "Git: Blame line",
	},
	{
		"<leader>GhB",
		function()
			_G.git.toggle_blame()
		end,
		desc = "Git: Toggle blame",
	},

	-- Git Telescope
	{ "<leader>gts", "<cmd>Telescope git_status<CR>", desc = "Git Status" },
	{ "<leader>gtc", "<cmd>Telescope git_commits<CR>", desc = "Git Commits" },
	{ "<leader>gtb", "<cmd>Telescope git_branches<CR>", desc = "Git Branches" },

	-- LSP
	{ "<leader>l", group = "+lsp" },
	{ "<leader>K", "<cmd>lua vim.lsp.buf.hover()<CR>", desc = "LSP hover" },
	-- Trouble
	{ "<leader>x", group = "+trouble" },
	{ "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Toggle" },
	{ "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Buffer Diagnostics" },
	{ "<leader>xd", "<cmd>TroubleToggle document_diagnostics<CR>", desc = "Document Diagnostics" },
	{ "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix" },
	{ "<leader>xL", "<cmd>Trouble loclist toggle<CR>", desc = "Loclist" },

	-- Corrections d'affichage
	{ "<leader>r", group = "+redraw" },
	{ "<leader>rr", "<cmd>redraw!<cr>", desc = "Force Redraw complet" },
	{ "<leader>rf", "<cmd>mode<cr>", desc = "Rafraîchir le mode" },
	{ "<leader>rc", "<cmd>redraw<cr>", desc = "Redraw simple" },
})
