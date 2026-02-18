-- Scala-specific indentation
-- smartindent/cindent sont du C-style et n'ont pas leur place ici
vim.opt_local.smartindent = false
vim.opt_local.cindent = false
vim.opt_local.autoindent = true

-- Les indent queries Scala de treesitter sont incomplètes (mauvaise indentation sur Enter).
-- On efface indentexpr après que le FileType autocmd de treesitter l'ait défini,
-- pour que autoindent prenne le relais (même niveau que la ligne précédente).
vim.schedule(function()
	vim.bo.indentexpr = ""
end)
