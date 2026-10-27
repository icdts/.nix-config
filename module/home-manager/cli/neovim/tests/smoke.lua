local errors = {}

local function check(cond, msg)
	if not cond then
		table.insert(errors, "FAIL: " .. msg)
	else
		io.stdout:write("PASS: " .. msg .. "\n")
	end
end

-- 1. Startup & Colorscheme
check(vim.v.errmsg == "", "Clean startup with no vim.v.errmsg (got: '" .. vim.v.errmsg .. "')")
check(vim.g.colors_name == "catppuccin-mocha", "Colorscheme is catppuccin-mocha")
check(vim.g.mapleader == " ", "Leader key is space")

-- 2. Core Plugins & Config Modules Loaded
local expected_modules = {
	"config.set",
	"config.remap",
	"config.lsp",
	"config.nvim-cmp",
	"config.ai",
	"telescope",
	"cmp",
	"lualine",
	"ibl",
	"which-key",
	"nvim-treesitter.config",
}
for _, mod in ipairs(expected_modules) do
	check(package.loaded[mod] ~= nil, "Module loaded: " .. mod)
end

-- 3. Telescope FZF native extension
local telescope = require("telescope")
check(telescope.extensions and telescope.extensions.fzf ~= nil, "Telescope fzf-native extension loaded")

-- 4. Keymaps (ensuring no lost or broken bindings)
local expected_n_maps = {
	[" sf"] = "Telescope find_files (<leader>sf)",
	[" sg"] = "Telescope live_grep (<leader>sg)",
	[" ac"] = "AI CLI toggle (<leader>ac)",
	[" as"] = "AI CLI select agent (<leader>as)",
	["<M-a>"] = "AI CLI toggle (<A-a>)",
	["<M-h>"] = "Window focus left (<A-h>)",
	["<M-l>"] = "Window focus right (<A-l>)",
	["<C-K>"] = "Quickfix next (<C-k>)",
	["<C-J>"] = "Quickfix prev (<C-j>)",
	[" k"] = "Location list next (<leader>k)",
	[" j"] = "Location list prev (<leader>j)",
	["gd"] = "LSP goto definition (gd)",
	["gr"] = "LSP goto references (gr)",
	["<C-S>"] = "LSP signature help (<C-s>)",
}
for lhs, label in pairs(expected_n_maps) do
	local m = vim.fn.maparg(lhs, "n", false, true)
	check(m and not vim.tbl_isempty(m), "Normal keymap exists: " .. label)
end

-- 5. LSP servers enabled
local expected_servers = { "ccls", "ruby_lsp", "gopls", "zls", "lua_ls", "nixd" }
for _, srv in ipairs(expected_servers) do
	check(vim.lsp.is_enabled(srv), "LSP server enabled: " .. srv)
end

-- 6. Filetype plugin (after/ftplugin/nix.lua)
vim.cmd("edit test.nix")
check(vim.bo.expandtab == true, "nix ftplugin sets expandtab = true")
check(vim.bo.formatprg == "nixfmt", "nix ftplugin sets formatprg = 'nixfmt'")

-- 7. Bundled CLI & LSP binaries on PATH
local expected_bins = {
	"curl",
	"rg",
	"ccls",
	"ruby-lsp",
	"gopls",
	"lua-language-server",
	"nixd",
	"nixfmt",
}

local ai_bins_env = vim.env.EXPECTED_AI_BINS
if ai_bins_env == nil then
	ai_bins_env = "agy,copilot"
end
for bin in string.gmatch(ai_bins_env, "([^,]+)") do
	table.insert(expected_bins, bin)
end

for _, bin in ipairs(expected_bins) do
	check(vim.fn.executable(bin) == 1, "Executable in PATH: " .. bin)
end

if #errors > 0 then
	io.stderr:write("\nTest suite failed with " .. #errors .. " error(s):\n")
	for _, err in ipairs(errors) do
		io.stderr:write("  " .. err .. "\n")
	end
	vim.cmd("cquit 1")
end

io.stdout:write("\nAll checks passed!\n")
vim.cmd("qa!")
