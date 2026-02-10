-- Désactivé : conflit de keymaps avec claudecode.lua (<leader>ac, etc.). On garde Claudecode + OpenCode.
return {
	"yetone/avante.nvim",
	build = vim.fn.has("win32") ~= 0 and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
	  or "make",
	event = "VeryLazy",
	opts = {
	  provider = "copilot",
	  selection = {
		hint_display = "none",
	  },
	  behaviour = {
		auto_set_keymaps = false,
	  },
	},
	cmd = {
	  "AvanteAsk",
	  "AvanteBuild",
	  "AvanteChat",
	  "AvanteClear",
	  "AvanteEdit",
	  "AvanteFocus",
	  "AvanteHistory",
	  "AvanteModels",
	  "AvanteRefresh",
	  "AvanteShowRepoMap",
	  "AvanteStop",
	  "AvanteSwitchProvider",
	  "AvanteToggle",
	},
	keys = {
	  { "<leader>aa", "<cmd>AvanteAsk<CR>", desc = "Ask Avante" },
	  { "<leader>ac", "<cmd>AvanteChat<CR>", desc = "Chat with Avante" },
	  { "<leader>ae", "<cmd>AvanteEdit<CR>", desc = "Edit Avante" },
	  { "<leader>af", "<cmd>AvanteFocus<CR>", desc = "Focus Avante" },
	  { "<leader>ah", "<cmd>AvanteHistory<CR>", desc = "Avante History" },
	  { "<leader>am", "<cmd>AvanteModels<CR>", desc = "Select Avante Model" },
	  { "<leader>an", "<cmd>AvanteChatNew<CR>", desc = "New Avante Chat" },
	  { "<leader>ap", "<cmd>AvanteSwitchProvider<CR>", desc = "Switch Avante Provider" },
	  { "<leader>ar", "<cmd>AvanteRefresh<CR>", desc = "Refresh Avante" },
	  { "<leader>as", "<cmd>AvanteStop<CR>", desc = "Stop Avante" },
	  { "<leader>at", "<cmd>AvanteToggle<CR>", desc = "Toggle Avante" },
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		--- The below dependencies are optional,
		"nvim-mini/mini.pick", -- for file_selector provider mini.pick
		"nvim-telescope/telescope.nvim", -- for file_selector provider telescope
		"hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
		"ibhagwan/fzf-lua", -- for file_selector provider fzf
		"stevearc/dressing.nvim", -- for input provider dressing
		"folke/snacks.nvim", -- for input provider snacks
		"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
		"zbirenbaum/copilot.lua", -- for providers='copilot'
		{
			-- support for image pasting
			"HakonHarnes/img-clip.nvim",
			event = "VeryLazy",
			opts = {
				-- recommended settings
				default = {
					embed_image_as_base64 = false,
					prompt_for_file_name = false,
					drag_and_drop = {
						insert_mode = true,
					},
					-- required for Windows users
					use_absolute_path = true,
				},
			},
		},
		{
			-- Make sure to set this up properly if you have lazy=true
			"MeanderingProgrammer/render-markdown.nvim",
			opts = {
				file_types = { "markdown", "Avante" },
			},
			ft = { "markdown", "Avante" },
		},
	},
}
