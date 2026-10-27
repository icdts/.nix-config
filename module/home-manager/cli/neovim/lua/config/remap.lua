vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

-- General
map({ "n", "v" }, "<Space>", "<Nop>", { silent = true })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "Q", "<Nop>", { silent = true })
map("n", "<leader>n", vim.cmd.Ex, { desc = "Open Netrw file explorer" })
map("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make file executable" })

-- Move selected lines up/down in visual mode
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Keep cursor position/centering during motions
map("n", "J", "mzJ`z", { desc = "Join line without moving cursor" })
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })
map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })

-- Clipboard & register helpers
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "[Y]ank into system clipboard" })
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "[D]elete without yanking" })
map("n", "<leader>rw", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "[R]eplace [W]ord in file" })

-- Quickfix & Location list navigation
map("n", "<C-k>", "<cmd>cnext<CR>zz", { desc = "Next quickfix item" })
map("n", "<C-j>", "<cmd>cprev<CR>zz", { desc = "Previous quickfix item" })
map("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Next location list item" })
map("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Previous location list item" })

-- Diagnostics
map("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Previous diagnostic" })
map("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open diagnostic float" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

-- Native LSP navigation & actions
map("n", "gd", vim.lsp.buf.definition, { desc = "[G]oto [D]efinition" })
map("n", "gD", vim.lsp.buf.declaration, { desc = "[G]oto [D]eclaration" })
map("n", "gi", vim.lsp.buf.implementation, { desc = "[G]oto [I]mplementation" })
map("n", "gr", vim.lsp.buf.references, { desc = "[G]oto [R]eferences" })
map("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
map({ "n", "i" }, "<C-s>", vim.lsp.buf.signature_help, { desc = "Signature documentation" })
map("n", "<leader>D", vim.lsp.buf.type_definition, { desc = "Type [D]efinition" })
map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "[R]e[n]ame symbol" })
map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "[C]ode [A]ction" })
map("n", "<leader>f", function()
	vim.lsp.buf.format({ async = true })
end, { desc = "[F]ormat buffer" })
map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, { desc = "[W]orkspace [A]dd folder" })
map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, { desc = "[W]orkspace [R]emove folder" })
map("n", "<leader>wl", function()
	print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
end, { desc = "[W]orkspace [L]ist folders" })

-- Telescope search & symbols
local builtin = require("telescope.builtin")
map("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
map("n", "<leader>gf", builtin.git_files, { desc = "Search [G]it [F]iles" })
map("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
map("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
map("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
map("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
map("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
map("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
map("n", "<leader>ds", builtin.lsp_document_symbols, { desc = "[D]ocument [S]ymbols" })
map("n", "<leader>ws", builtin.lsp_dynamic_workspace_symbols, { desc = "[W]orkspace [S]ymbols" })

-- Window navigation (from :help terminal-input)
map({ "t", "i" }, "<A-h>", "<C-\\><C-N><C-w>h", { desc = "Move focus to left window" })
map({ "t", "i" }, "<A-j>", "<C-\\><C-N><C-w>j", { desc = "Move focus to lower window" })
map({ "t", "i" }, "<A-k>", "<C-\\><C-N><C-w>k", { desc = "Move focus to upper window" })
map({ "t", "i" }, "<A-l>", "<C-\\><C-N><C-w>l", { desc = "Move focus to right window" })
map("n", "<A-h>", "<C-w>h", { desc = "Move focus to left window" })
map("n", "<A-j>", "<C-w>j", { desc = "Move focus to lower window" })
map("n", "<A-k>", "<C-w>k", { desc = "Move focus to upper window" })
map("n", "<A-l>", "<C-w>l", { desc = "Move focus to right window" })

-- AI CLI Sidebar
local ai = require("config.ai")
map("n", "<leader>ac", ai.toggle, { desc = "Toggle AI CLI Sidebar (agy / copilot)" })
map({ "n", "i", "v", "t" }, "<A-a>", function()
	vim.cmd("stopinsert")
	ai.toggle()
end, { desc = "Toggle AI CLI Sidebar (agy / copilot)" })
map("n", "<leader>as", ai.select_agent, { desc = "Select AI CLI Agent (agy / copilot)" })

local ok, wk = pcall(require, "which-key")
if ok and wk.add then
	wk.add({
		{ "<leader>a", group = "AI CLI (Antigravity & Copilot)" },
		{ "<leader>s", group = "[S]earch (Telescope)" },
		{ "<leader>w", group = "[W]orkspace" },
	})
end
