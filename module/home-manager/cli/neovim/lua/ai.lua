require("codecompanion").setup({
	adapters = {
		http = {
			gemini = function()
				return require("codecompanion.adapters").extend("gemini", {
					env = {
						api_key = "file:/run/secrets/google-api-key",
					},
					schema = {
						model = {
							-- Pick your default model (you can still switch mid-chat with 'ga')
							default = "gemini-3.1-pro",
						},
					},
				})
			end,
		},
	},
	interactions = {
		chat = {
			adapter = "gemini",
		},
		inline = {
			adapter = "gemini",
		},
		cmd = {
			adapter = "gemini",
		},
	},
	display = {
		action_palette = {
			provider = "telescope", -- Uses your telescope-nvim setup for :CodeCompanionActions
		},
		chat = {
			window = {
				layout = "vertical", -- Opens like a VSCode sidebar split
				width = 0.4,
			},
		},
		diff = {
			enabled = true,
			provider = "default", -- Native Neovim inline diff
		},
	},
})

-- Keymaps
local map = vim.keymap.set

map({ "n", "v" }, "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "Toggle Gemini Chat" })
map({ "n", "v" }, "<leader>aa", "<cmd>CodeCompanionActions<cr>", { desc = "AI Actions (Telescope)" })
map("v", "<leader>ai", ":CodeCompanion ", { desc = "AI Inline Rewrite" })
map("v", "ga", "<cmd>CodeCompanionChat Add<cr>", { desc = "Add selection to AI Chat" })

-- Command-line shorthand (:cc instead of :CodeCompanion)
vim.cmd([[cab cc CodeCompanion]])

-- Register prefix with which-key (if loaded)
local ok, wk = pcall(require, "which-key")
if ok and wk.add then
	wk.add({
		{ "<leader>a", group = "AI (CodeCompanion)" },
	})
end
