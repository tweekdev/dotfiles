-- Thème secondaire : :colorscheme anysphere pour l’activer
return {
	"dapovich/anysphere.nvim",
	name = "anysphere.nvim",
	lazy = true,
	priority = 50,
	config = function()
		require("anysphere").setup({
			transparent = true,
			colors = {
				white = "#ffffff",
				pink = "#ec6075",
			},
			themes = function(colors)
				return {
					Normal = { bg = colors.bg },
					DiffChange = { fg = colors.white:darken(0.3) },
					ErrorMsg = { fg = colors.pink, standout = true },
					["@lsp.type.keyword"] = { link = "@keyword" },
				}
			end,
			italics = false,
		})
	end,
}