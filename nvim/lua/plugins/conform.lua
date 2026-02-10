return {
    "stevearc/conform.nvim",
    opts = {
        formatters_by_ft = {
            lua = { "stylua" },
            python = { "isort", "black" },
            rust = { "rustfmt" },
            scala = { "scalafmt", lsp_format = "never" },
            sbt = { "scalafmt", lsp_format = "never" },
            javascript = { "prettierd", "prettier", stop_after_first = true },
            typescript = { "prettierd", "prettier", stop_after_first = true },
        },
        -- scalafmt : via coursier (cs launch) ; cwd = répertoire du fichier pour trouver api/.scalafmt.conf
        formatters = {
            scalafmt = {
                command = "cs",
                args = { "launch", "scalafmt", "--", "--stdin" },
                cwd = function(ctx)
                    local bufnr = (ctx and ctx.bufnr) or vim.api.nvim_get_current_buf()
                    local path = vim.api.nvim_buf_get_name(bufnr)
                    if path and path ~= "" then
                        return vim.fn.fnamemodify(path, ":h")
                    end
                    return nil
                end,
            },
        },
        -- Scala/sbt : pas de format Conform à la sauvegarde, on utilise Metals (LSP) dans scala.lua
        format_on_save = function(bufnr)
            local ft = vim.bo[bufnr].ft
            if ft == "scala" or ft == "sbt" then
                return nil
            end
            return {
                timeout_ms = 10000,
                lsp_format = "fallback",
            }
        end,
    },
}
