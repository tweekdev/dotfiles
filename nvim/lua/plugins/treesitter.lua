return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		-- Setup nvim-treesitter (main branch API)
		require("nvim-treesitter").setup({
			install_dir = vim.fn.stdpath("data") .. "/site",
		})

		-- Install parsers (async, no-op if already installed)
		require("nvim-treesitter").install({
			"bash",
			"c",
			"css",
			"diff",
			"dockerfile",
			"elixir",
			"gitignore",
			"graphql",
			"heex",
			"html",
			"javascript",
			"json",
			"lua",
			"markdown",
			"markdown_inline",
			"query",
			"scala",
			"tsx",
			"typescript",
			"vim",
			"vimdoc",
			"yaml",
		})

		-- Enable treesitter highlighting + indentation for buffers that have a parser
		vim.api.nvim_create_autocmd("FileType", {
			callback = function()
				if pcall(vim.treesitter.start) then
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})
	end,
}
