-- Auto-reload buffers when Antigravity CLI (agy) edits a file on disk
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
	command = "silent! checktime",
})

-- 1. Toggleable Antigravity CLI (agy) Sidebar inside Neovim (Uses Google AI Pro sub)
local agy_buf = nil
local agy_win = nil

local function toggle_agy()
	-- If the window is open, hide it
	if agy_win and vim.api.nvim_win_is_valid(agy_win) then
		vim.api.nvim_win_hide(agy_win)
		agy_win = nil
		return
	end

	-- Re-open existing agy buffer on the right, or spawn a fresh empty split
	if agy_buf and vim.api.nvim_buf_is_valid(agy_buf) then
		vim.cmd("botright vertical sbuffer " .. agy_buf)
		vim.cmd("vertical resize " .. math.floor(vim.o.columns * 0.4))
		agy_win = vim.api.nvim_get_current_win()
	else
		-- `vertical new` creates a brand new empty buffer so it doesn't overwrite your left pane!
		vim.cmd("botright vertical new")
		vim.cmd("vertical resize " .. math.floor(vim.o.columns * 0.4))
		agy_win = vim.api.nvim_get_current_win()
		vim.fn.termopen("agy")
		agy_buf = vim.api.nvim_get_current_buf()

		-- Clean up terminal split appearance (no line numbers or sign column)
		vim.wo[agy_win].number = false
		vim.wo[agy_win].relativenumber = false
		vim.wo[agy_win].signcolumn = "no"

		-- Navigation out of the agy terminal split:
		-- Ctrl+h jumps straight back to your code buffer on the left
		vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", { buffer = agy_buf, desc = "Jump left to code buffer" })
		-- Allow <leader>ag to close the sidebar even while typing inside agy
		vim.keymap.set("t", "<leader>ag", function()
			vim.cmd("stopinsert")
			toggle_agy()
		end, { buffer = agy_buf, desc = "Hide Antigravity Sidebar" })
	end

	vim.cmd("startinsert")
end

-- 2. Base Copilot setup (For Work WSL :Copilot auth)
require("copilot").setup({
	panel = { enabled = false },
	suggestion = { enabled = false },
})

-- 3. CodeCompanion Setup (Defaulted to Work GitHub Copilot, with Flash-Lite fallback)
local cc = require("codecompanion")
local cc_config = require("codecompanion.config")

local my_models = {
	-- === WORK (WSL): GITHUB COPILOT (:Copilot auth) ===
	{
		label = "Claude Sonnet 4        [Work GitHub Copilot]",
		adapter = "copilot",
		model = "claude-sonnet-4",
	},
	{
		label = "GPT-4.1                [Work GitHub Copilot - 0 Credit Base]",
		adapter = "copilot",
		model = "gpt-4.1",
	},
	{
		label = "Gemini 2.5 Pro         [Work GitHub Copilot]",
		adapter = "copilot",
		model = "gemini-2.5-pro",
	},
	-- === HOME API KEY FALLBACK (Least likely to 503 on Free Tier) ===
	{
		label = "Gemini 2.5 Flash-Lite  [Free API Key - Low Congestion]",
		adapter = "gemini",
		model = "gemini-2.5-flash-lite",
	},
}

local is_wsl = vim.fn.has("wsl") == 1
local current_selection = is_wsl and my_models[1] or my_models[4]

cc.setup({
	adapters = {
		http = {
			copilot = function()
				return require("codecompanion.adapters").extend("copilot", {
					schema = { model = { default = "claude-sonnet-4" } },
				})
			end,
			gemini = function()
				return require("codecompanion.adapters").extend("gemini", {
					env = { api_key = "file:/run/secrets/google-api-key" },
					schema = { model = { default = "gemini-2.5-flash-lite" } },
				})
			end,
		},
	},
	interactions = {
		chat = { adapter = { name = current_selection.adapter, model = current_selection.model } },
		inline = { adapter = { name = current_selection.adapter, model = current_selection.model } },
		cmd = { adapter = { name = current_selection.adapter, model = current_selection.model } },
	},
	display = {
		action_palette = { provider = "telescope" },
		chat = {
			window = {
				layout = "vertical",
				width = 0.4,
				opts = { wrap = true },
			},
			show_header_separator = true,
			intro_message = "💡 Cheat Sheet:  [ # ] Attach files/buffers  |  [ @ ] Run tools/edits  |  [ / ] Commands  |  [ ? ] Keymaps",
		},
		diff = { enabled = true, provider = "default" },
	},
})

-- 4. Custom Telescope Picker for <leader>as
local function select_ai_model()
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	pickers
		.new({}, {
			prompt_title = "Select AI Model (Active: " .. current_selection.model .. ")",
			finder = finders.new_table({
				results = my_models,
				entry_maker = function(entry)
					local is_active = (
						entry.model == current_selection.model and entry.adapter == current_selection.adapter
					)
					return {
						value = entry,
						display = (is_active and "* " or "  ") .. entry.label,
						ordinal = entry.label .. " " .. entry.model,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if not selection then
						return
					end
					current_selection = selection.value
					for _, s in ipairs({ "chat", "inline", "cmd" }) do
						if cc_config.interactions and cc_config.interactions[s] then
							cc_config.interactions[s].adapter = {
								name = current_selection.adapter,
								model = current_selection.model,
							}
						end
					end
					local last_chat = cc.last_chat()
					if last_chat and last_chat.change_adapter then
						last_chat:change_adapter(current_selection.adapter, current_selection.model)
					end
					vim.notify("AI Model -> " .. current_selection.model, vim.log.levels.INFO)
				end)
				return true
			end,
		})
		:find()
end

-- 5. Keymaps
local map = vim.keymap.set
map("n", "<leader>ag", toggle_agy, { desc = "Toggle Antigravity CLI (Google AI Pro)" })
map({ "n", "v" }, "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "Toggle CodeCompanion Chat (Work Copilot)" })
map({ "n", "v" }, "<leader>aa", "<cmd>CodeCompanionActions<cr>", { desc = "AI Actions (Telescope)" })
map("n", "<leader>as", select_ai_model, { desc = "Select AI Model (Filtered)" })
map("v", "<leader>ai", ":CodeCompanion ", { desc = "AI Inline Rewrite" })
map("v", "ga", "<cmd>CodeCompanionChat Add<cr>", { desc = "Add selection to AI Chat" })

local ok, wk = pcall(require, "which-key")
if ok and wk.add then
	wk.add({
		{ "<leader>a", group = "AI (Antigravity & CodeCompanion)" },
	})
end
