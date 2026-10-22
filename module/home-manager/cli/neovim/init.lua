require("config.set")

-- Briefly highlight what is being yanked
vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
	pattern = "*",
	callback = function()
		vim.highlight.on_yank()
	end,
})

vim.cmd.colorscheme("catppuccin-mocha")

require("nvim-treesitter.config").setup({
	highlight = { enable = true },
})

local ibl_highlight = { "CursorColumn", "Whitespace" }
require("ibl").setup({
	indent = { highlight = ibl_highlight, char = "" },
	whitespace = { highlight = ibl_highlight, remove_blankline_trail = false },
	scope = { enabled = true },
})

require("lualine").setup({
	options = {
		icons_enabled = false,
		theme = "auto",
		component_separators = "|",
		section_separators = "",
	},
})

require("telescope").setup({
	defaults = {
		mappings = {
			i = {
				["<C-u>"] = false,
				["<C-d>"] = false,
			},
		},
	},
})
pcall(require("telescope").load_extension, "fzf")

require("which-key").setup()

require("config.nvim-cmp")
require("config.lsp")
require("config.ai")
require("config.remap")
