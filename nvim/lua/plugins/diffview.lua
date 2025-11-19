return {
	"sindrets/diffview.nvim",
	event = "VeryLazy",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("diffview").setup({
			enhanced_diff_hl = true,
			use_icons = true,
			file_panel = {
				win_config = {
					position = "left",
					width = 35,
				},
			},
		})
	end,
}
