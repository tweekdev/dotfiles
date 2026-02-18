-- Theme persistence: when colorscheme changes (e.g. via Snack <leader>uC), updates theme_default.lua and lazy.lua.
local M = {}

local config_dir = vim.fn.stdpath("config")
local theme_default_path = config_dir .. "/lua/config/theme_default.lua"
local lazy_path = config_dir .. "/lua/config/lazy.lua"

---@class ThemeDef
---@field id string
---@field label string
---@field apply fun()

-- Charge le plugin rose-pine (son config fait le setup) puis applique le colorscheme.
local function rose_pine_moon_apply()
	require("lazy").load({ plugins = { "rose-pine" } })
	vim.cmd.colorscheme("rose-pine-moon")
end

-- Charge le plugin (son config fait le setup) puis applique le colorscheme.
local function kanagawa_apply()
	require("lazy").load({ plugins = { "kanagawa.nvim" } })
	vim.cmd.colorscheme("kanagawa")
end

-- Rosé Pine Main
local function rose_pine_main_apply()
	require("lazy").load({ plugins = { "rose-pine" } })
	vim.cmd.colorscheme("rose-pine-main")
end

-- Rosé Pine Dawn (clair)
local function rose_pine_dawn_apply()
	require("lazy").load({ plugins = { "rose-pine" } })
	vim.cmd.colorscheme("rose-pine-dawn")
end

-- Rosé Pine (défaut du plugin, suit dark_variant)
local function rose_pine_default_apply()
	require("lazy").load({ plugins = { "rose-pine" } })
	vim.cmd.colorscheme("rose-pine")
end

local function cursor_dark_midnight_apply()
	require("lazy").load({ plugins = { "cursor-dark.nvim" } })
	vim.cmd.colorscheme("cursor-dark-midnight")
end

local function vscode_modern_apply()
	require("lazy").load({ plugins = { "vscode-modern.nvim" } })
	vim.cmd.colorscheme("vscode-modern")
end

local function cursor_dark_auto_apply()
	require("lazy").load({ plugins = { "cursor-dark.nvim" } })
	vim.cmd.colorscheme("cursor-dark-auto")
end

local function kanagawa_wave_apply()
	require("lazy").load({ plugins = { "kanagawa.nvim" } })
	vim.cmd.colorscheme("kanagawa-wave")
end

local function kanagawa_lotus_apply()
	require("lazy").load({ plugins = { "kanagawa.nvim" } })
	vim.cmd.colorscheme("kanagawa-lotus")
end

local function kanagawa_dragon_apply()
	require("lazy").load({ plugins = { "kanagawa.nvim" } })
	vim.cmd.colorscheme("kanagawa-dragon")
end

M.THEMES = {
	-- Rosé Pine (4 variantes)
	{ id = "rose-pine", label = "Rosé Pine (défaut)", apply = rose_pine_default_apply },
	{ id = "rose-pine-main", label = "Rosé Pine (Main)", apply = rose_pine_main_apply },
	{ id = "rose-pine-moon", label = "Rosé Pine (Moon)", apply = rose_pine_moon_apply },
	{ id = "rose-pine-dawn", label = "Rosé Pine (Dawn)", apply = rose_pine_dawn_apply },
	-- Kanagawa (4 variantes)
	{ id = "kanagawa", label = "Kanagawa (défaut)", apply = kanagawa_apply },
	{ id = "kanagawa-wave", label = "Kanagawa (Wave)", apply = kanagawa_wave_apply },
	{ id = "kanagawa-dragon", label = "Kanagawa (Dragon)", apply = kanagawa_dragon_apply },
	{ id = "kanagawa-lotus", label = "Kanagawa (Lotus)", apply = kanagawa_lotus_apply },
}

---Apply a theme by id (loads plugin if needed).
function M.apply(theme_id)
	for _, t in ipairs(M.THEMES) do
		if t.id == theme_id then
			local ok, err = pcall(t.apply)
			if not ok then
				vim.notify("[theme] " .. tostring(err), vim.log.levels.ERROR)
			end
			return
		end
	end
	vim.notify("[theme] Unknown theme: " .. tostring(theme_id), vim.log.levels.ERROR)
end

---Read current default theme id from theme_default.lua (fichier ou require).
function M.get_default()
	-- 1) Require (utilise le cache Lua)
	local ok, name = pcall(require, "config.theme_default")
	if ok and type(name) == "string" and name ~= "" then
		return name
	end
	-- 2) Lecture directe du fichier (au cas où le require ne résout pas le bon fichier)
	local f = io.open(theme_default_path, "r")
	if f then
		local content = f:read("a")
		f:close()
		local match = content and content:match('return%s+["\']([^"\']+)["\']')
		if match and match ~= "" then
			return match
		end
	end
	return "rose-pine-moon"
end

---Write theme_default.lua and update lazy.lua install.colorscheme, then apply.
function M.set_default(theme_id)
	-- Write theme_default.lua
	local content = string.format(
		"-- Default theme (updated when you change it via Snack <leader>uC). Do not edit manually.\nreturn %q\n",
		theme_id
	)
	local f = io.open(theme_default_path, "w")
	if not f then
		vim.notify("[theme] Cannot write " .. theme_default_path, vim.log.levels.ERROR)
		return
	end
	f:write(content)
	f:close()

	-- Update lazy.lua: install = { colorscheme = { "..." } }
	local lazy_content = vim.fn.readfile(lazy_path)
	local out = {}
	local pattern = 'colorscheme = { "[^"]*" }'
	local replacement = ('colorscheme = { "%s" }'):format(theme_id)
	for _, line in ipairs(lazy_content) do
		table.insert(out, (line:gsub(pattern, replacement)))
	end
	vim.fn.writefile(out, lazy_path)

	M.apply(theme_id)
	vim.notify(("Theme set to %s (saved in config)."):format(theme_id), vim.log.levels.INFO)
end

---Open picker to choose theme (vim.ui.select).
function M.picker()
	local items = {}
	for _, t in ipairs(M.THEMES) do
		table.insert(items, { value = t.id, label = t.label })
	end
	vim.ui.select(items, {
		prompt = "Choose theme (updates lazy.lua)",
		format_item = function(item)
			return item.label
		end,
	}, function(choice)
		if choice then
			M.set_default(choice.value)
		end
	end)
end

---Apply the saved default theme. Call from lazy.lua after plugins load.
function M.apply_default()
	local name = M.get_default()
	-- Appliquer après la fin du démarrage pour que lazy et les plugins soient prêts.
	vim.schedule(function()
		local known = false
		for _, t in ipairs(M.THEMES) do
			if t.id == name then
				known = true
				M.apply(name)
				break
			end
		end
		if not known then
			pcall(vim.cmd.colorscheme, name)
		end
	end)
end

-- Nom du thème demandé (ex. "rose-pine-moon"), capturé dans ColorSchemePre avant que le plugin écrase g:colors_name.
M._pending_colorscheme_name = nil

---Persist theme name to theme_default.lua and lazy.lua. Si name est nil, utilise _pending (ColorSchemePre) puis g:colors_name.
function M.persist_current(name)
	name = name or M._pending_colorscheme_name or vim.g.colors_name
	M._pending_colorscheme_name = nil
	if not name or name == "" then
		return
	end
	-- _pending a été défini par ColorSchemePre (un autocmd par thème connu) pour avoir le nom exact.
	-- On n’utilise plus de fallback ici pour ne pas réécrire avec l’ancienne variante.
	local content = string.format(
		"-- Default theme (updated by Snack <leader>uC). Do not edit manually.\nreturn %q\n",
		name
	)
	local f = io.open(theme_default_path, "w")
	if not f then
		return
	end
	f:write(content)
	f:close()

	local lazy_content = vim.fn.readfile(lazy_path)
	local out = {}
	local pattern = 'colorscheme = { "[^"]*" }'
	local replacement = ('colorscheme = { "%s" }'):format(name)
	for _, line in ipairs(lazy_content) do
		table.insert(out, (line:gsub(pattern, replacement)))
	end
	vim.fn.writefile(out, lazy_path)
	-- Invalider le cache pour que get_default() relise le fichier au prochain appel.
	package.loaded["config.theme_default"] = nil
end

---Register autocmd to persist theme on change (e.g. Snack <leader>uC). Call once from lazy.lua.
function M.setup_persist_on_change()
	-- Un ColorSchemePre par thème connu : avec pattern = id, <amatch> vaut le nom du thème (ex. rose-pine-main).
	for _, t in ipairs(M.THEMES) do
		vim.api.nvim_create_autocmd("ColorSchemePre", {
			pattern = t.id,
			callback = function()
				M._pending_colorscheme_name = vim.fn.expand("<amatch>")
			end,
		})
	end
	-- Cas des thèmes hors liste (ex. autres colorschemes dans Snack) : pattern * pour tout capturer.
	vim.api.nvim_create_autocmd("ColorSchemePre", {
		pattern = "*",
		callback = function()
			local name = vim.fn.expand("<amatch>")
			if name and name ~= "" and name ~= "*" then
				-- Éviter d’écraser un nom déjà capturé par un autocmd spécifique ci‑dessus.
				if not M._pending_colorscheme_name then
					M._pending_colorscheme_name = name
				end
			end
		end,
	})
	vim.api.nvim_create_autocmd("ColorScheme", {
		callback = function()
			M.persist_current()
		end,
	})
end

return M
