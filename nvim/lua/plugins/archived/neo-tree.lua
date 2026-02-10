if true then
	return {}
end
return {
	"nvim-neo-tree/neo-tree.nvim",

	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	cmd = "Neotree",

	-- Export commands for reuse
	init = function()
		-- Make neo-tree commands available globally
		_G.neotree = _G.neotree or {}
		_G.neotree.commands = require("neo-tree.command")

		-- Define reusable functions
		_G.neotree.toggle_root = function()
			_G.neotree.commands.execute({ toggle = true })
		end

		_G.neotree.toggle_cwd = function()
			_G.neotree.commands.execute({ toggle = true, dir = vim.uv.cwd() })
		end

		_G.neotree.toggle_git = function()
			_G.neotree.commands.execute({ source = "git_status", toggle = true })
		end

		_G.neotree.toggle_buffers = function()
			_G.neotree.commands.execute({ source = "buffers", toggle = true })
		end

		-- Auto-start if needed
		vim.api.nvim_create_autocmd("BufEnter", {
			group = vim.api.nvim_create_augroup("Neotree_start_directory", { clear = true }),
			desc = "Start Neo-tree with directory",
			once = true,
			callback = function()
				if package.loaded["neo-tree"] then
					return
				else
					local stats = vim.uv.fs_stat(vim.fn.argv(0))
					if stats and stats.type == "directory" then
						require("neo-tree")
					end
				end
			end,
		})
	end,

	-- Define keymaps
	keys = {
		{
			"<leader>fe",
			function()
				_G.neotree.toggle_root()
			end,
			desc = "Explorer NeoTree (Root Dir)",
		},
		{
			"<leader>fE",
			function()
				_G.neotree.toggle_cwd()
			end,
			desc = "Explorer NeoTree (cwd)",
		},
		{ "<leader>e", "<leader>fe", desc = "Explorer NeoTree (Root Dir)", remap = true },
		{ "<leader>E", "<leader>fE", desc = "Explorer NeoTree (cwd)", remap = true },
		{
			"<leader>ge",
			function()
				_G.neotree.toggle_git()
			end,
			desc = "Git Explorer",
		},
		{
			"<leader>be",
			function()
				_G.neotree.toggle_buffers()
			end,
			desc = "Buffer Explorer",
		},
	},
	deactivate = function()
		vim.cmd([[Neotree close]])
	end,
	opts = {
		sources = { "filesystem", "buffers", "git_status", "document_symbols" },
		source_selector = {
			winbar = true,
			content_layout = "center",
			sources = {
				{ source = "filesystem" },
				{ source = "buffers" },
				{ source = "git_status" },
				{ source = "document_symbols" },
			},
		},
		open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
		filesystem = {
			filtered_items = {
				hide_dotfiles = false,
				hide_gitignored = false,
				hide_hidden = false,
				hide_by_name = {
					".DS_Store",
					"thumbs.db",
					"node_modules",
					".git",
				},
				never_show = {
					".DS_Store",
					"thumbs.db",
					"node_modules",
					".git",
				},
			},
			bind_to_cwd = false,
			follow_current_file = { enabled = true },
			use_libuv_file_watcher = true,
		},
		window = {
			mappings = {
				["l"] = "open",
				["h"] = "close_node",
				["<space>"] = "none",
				["Y"] = {
					function(state)
						local node = state.tree:get_node()
						local path = node:get_id()
						vim.fn.setreg("+", path, "c")
					end,
					desc = "Copy Path to Clipboard",
				},
				["O"] = {
					function(state)
						require("lazy.util").open(state.tree:get_node().path, { system = true })
					end,
					desc = "Open with System Application",
				},
				["P"] = { "toggle_preview", config = { use_float = false } },
			},
		},
		default_component_configs = {
			indent = {
				with_expanders = true, -- if nil and file nesting is enabled, will enable expanders
				expander_collapsed = "",
				expander_expanded = "",
				expander_highlight = "NeoTreeExpander",
			},
			git_status = {
				symbols = {
					unstaged = "󰄱",
					staged = "󰱒",
				},
			},
		},
	},
	config = function(_, opts)
		-- Configuration des gestionnaires d'événements
		local events = require("neo-tree.events")
		opts.event_handlers = opts.event_handlers or {}

		-- Gestion des déplacements/renommages de fichiers
		local function on_move(data)
			-- Vérifier si Snacks est disponible pour éviter les erreurs
			if Snacks and Snacks.rename and Snacks.rename.on_rename_file then
				Snacks.rename.on_rename_file(data.source, data.destination)
			end
		end

		-- Ajouter les gestionnaires d'événements
		vim.list_extend(opts.event_handlers, {
			{ event = events.FILE_MOVED, handler = on_move },
			{ event = events.FILE_RENAMED, handler = on_move },
		})

		-- Initialiser neo-tree
		require("neo-tree").setup(opts)

		-- Rafraîchir git_status après l'utilisation de lazygit
		vim.api.nvim_create_autocmd("TermClose", {
			pattern = "*lazygit",
			callback = function()
				if package.loaded["neo-tree.sources.git_status"] then
					require("neo-tree.sources.git_status").refresh()
				end
			end,
		})
	end,
}
