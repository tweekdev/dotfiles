-- Shim for deprecated vim.lsp.buf_get_clients() (Neovim 0.11+) so plugins like blink.cmp keep working
if vim.lsp and vim.lsp.get_clients then
	vim.lsp.buf_get_clients = function(bufnr)
		return vim.lsp.get_clients({ bufnr = bufnr or 0 })
	end
end

-- Some keyboard mappings as I don't want to break my fingers, while typing on a "german" keyboard ;)
vim.opt.langmap = "+]ü["
-- Plain langmap remapping does not seem to do the trick :(
vim.keymap.set("n", "ü", "[", { remap = true })

vim.opt.expandtab = true -- Convert tabs to spaces
vim.opt.shiftwidth = 2 -- Amount to indent with << and >>
vim.opt.tabstop = 2 -- How many spaces are shown per Tab
vim.opt.softtabstop = 2 -- How many spaces are applied when pressing Tab

vim.opt.smarttab = true
vim.opt.smartindent = true
vim.opt.autoindent = true -- Keep identation from previous line

-- Enable break indent
vim.opt.breakindent = true

-- Always show relative line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Show line under cursor
vim.opt.cursorline = true

-- Sync clipboard with system
vim.opt.clipboard = "unnamedplus"

-- Store undos between sessions
vim.opt.undofile = true

-- Recherche
vim.opt.incsearch = true -- Recherche incrémentale
vim.opt.hlsearch = true -- Mettre en surbrillance les résultats de recherche
vim.opt.ignorecase = true -- Ignorer la casse dans les recherches
vim.opt.path:append({ "**" }) -- Chercher dans tous les sous-dossiers
vim.opt.wildignore:append({ "*/node_modules/*" }) -- Ignorer node_modules

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = "a"

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 5

-- Encodage et formats
vim.opt.isfname:append("@-@") -- Caractères autorisés dans les noms de fichiers
vim.scriptencoding = "utf-8"
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.opt.formatoptions:append({ "r" }) -- Ajouter des astérisques dans les commentaires en bloc

vim.opt.backspace = { "start", "eol", "indent" } -- Comportement de la touche backspace
vim.opt.inccommand = "split"

vim.g.lazyvim_picker = "snacks"

-- Afficher les remplacements en temps réel<D-s>
