-- nvim-metals: Scala LSP (Metals) + DAP, style IntelliJ (scalafmt, code actions, etc.)
-- Doc: https://github.com/scalameta/nvim-metals
-- Prérequis: Coursier installé (brew install coursier/formulas/coursier), .scalafmt.conf à la racine du projet
return {
	{
		"scalameta/nvim-metals",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
			{
				"mfussenegger/nvim-dap",
				config = function()
					local dap = require("dap")
					dap.configurations.scala = {
						{
							type = "scala",
							request = "launch",
							name = "RunOrTest",
							metals = { runType = "runOrTestFile" },
						},
						{
							type = "scala",
							request = "launch",
							name = "Test Target",
							metals = { runType = "testTarget" },
						},
					}
				end,
			},
		},
		ft = { "scala", "sbt", "java" },
		opts = function()
			local metals_config = require("metals").bare_config()
			local map = vim.keymap.set

			-- Capabilities pour la complétion (blink.cmp comme le reste de la config)
			local caps = vim.lsp.protocol.make_client_capabilities()
			local ok, blink = pcall(require, "blink.cmp")
			if ok and blink and blink.get_lsp_capabilities then
				caps = blink.get_lsp_capabilities(caps)
			end
			metals_config.capabilities = caps

			-- Settings Metals (équivalent IntelliJ : implicits, format, etc.)
			metals_config.settings = {
				showImplicitArguments = true,
				showImplicitConversionsAndClasses = true,
				showInferredType = true,
				excludedPackages = { "akka.actor.typed.javadsl", "com.github.swagger.akka.javadsl" },
			}

			metals_config.init_options.statusBarProvider = "off"

			metals_config.on_attach = function(client, bufnr)
				require("metals").setup_dap()

				-- LSP (goto def, refs, hover, rename, format, code actions)
				map("n", "gD", vim.lsp.buf.definition, { buffer = bufnr, desc = "LSP: Definition" })
				map("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "LSP: Hover" })
				map("n", "gi", vim.lsp.buf.implementation, { buffer = bufnr, desc = "LSP: Implementation" })
				map("n", "gr", vim.lsp.buf.references, { buffer = bufnr, desc = "LSP: References" })
				map("n", "gds", vim.lsp.buf.document_symbol, { buffer = bufnr, desc = "LSP: Document symbol" })
				map("n", "gws", vim.lsp.buf.workspace_symbol, { buffer = bufnr, desc = "LSP: Workspace symbol" })
				map("n", "<leader>cl", vim.lsp.codelens.run, { buffer = bufnr, desc = "LSP: Code lens" })
				map("n", "<leader>sh", vim.lsp.buf.signature_help, { buffer = bufnr, desc = "LSP: Signature help" })
				map("n", "<leader>rn", vim.lsp.buf.rename, { buffer = bufnr, desc = "LSP: Rename" })
				map("n", "<leader>f", vim.lsp.buf.format, { buffer = bufnr, desc = "LSP: Format (scalafmt via Metals)" })
				map("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "LSP: Code action (Organize imports, etc.)" })

				map("n", "<leader>ws", function()
					require("metals").hover_worksheet()
				end, { buffer = bufnr, desc = "Metals: Hover worksheet" })

				-- Diagnostics
				map("n", "<leader>aa", vim.diagnostic.setqflist, { buffer = bufnr, desc = "All workspace diagnostics" })
				map("n", "<leader>ae", function()
					vim.diagnostic.setqflist({ severity = "E" })
				end, { buffer = bufnr, desc = "All workspace errors" })
				map("n", "<leader>aw", function()
					vim.diagnostic.setqflist({ severity = "W" })
				end, { buffer = bufnr, desc = "All workspace warnings" })
				map("n", "<leader>d", vim.diagnostic.setloclist, { buffer = bufnr, desc = "Buffer diagnostics" })
				map("n", "[c", function()
					vim.diagnostic.goto_prev({ wrap = false })
				end, { buffer = bufnr, desc = "Previous diagnostic" })
				map("n", "]c", function()
					vim.diagnostic.goto_next({ wrap = false })
				end, { buffer = bufnr, desc = "Next diagnostic" })

				-- DAP
				map("n", "<leader>dc", function() require("dap").continue() end, { buffer = bufnr, desc = "DAP: Continue" })
				map("n", "<leader>dr", function() require("dap").repl.toggle() end, { buffer = bufnr, desc = "DAP: REPL" })
				map("n", "<leader>dK", function() require("dap.ui.widgets").hover() end, { buffer = bufnr, desc = "DAP: Hover" })
				map("n", "<leader>dt", function() require("dap").toggle_breakpoint() end, { buffer = bufnr, desc = "DAP: Toggle breakpoint" })
				map("n", "<leader>dso", function() require("dap").step_over() end, { buffer = bufnr, desc = "DAP: Step over" })
				map("n", "<leader>dsi", function() require("dap").step_into() end, { buffer = bufnr, desc = "DAP: Step into" })
				map("n", "<leader>dl", function() require("dap").run_last() end, { buffer = bufnr, desc = "DAP: Run last" })
			end

			return metals_config
		end,
		config = function(self, metals_config)
			local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
			vim.api.nvim_create_autocmd("FileType", {
				pattern = self.ft,
				callback = function()
					require("metals").initialize_or_attach(metals_config)
				end,
				group = nvim_metals_group,
			})
			-- À la sauvegarde : Organize imports puis Format (Metals / api/.scalafmt.conf)
			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = { "*.scala", "*.sbt" },
				callback = function(event)
					local bufnr = event.buf
					-- 1) Organise les imports (code action Metals)
					vim.lsp.buf.code_action({
						context = { only = { "source.organizeImports" } },
						bufnr = bufnr,
						apply = true,
					})
					vim.wait(200, function() end, 10)
					-- 2) Format (scalafmt via Metals)
					vim.lsp.buf.format({ bufnr = bufnr, async = false })
				end,
				group = nvim_metals_group,
			})
		end,
	},
}
