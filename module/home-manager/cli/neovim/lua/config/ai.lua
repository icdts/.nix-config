local M = {}

-- Auto-reload buffers when CLI AI agents (agy / copilot) edit a file on disk
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
	command = "silent! checktime",
})

-- CLI AI Agents Definition (Antigravity for Home, GitHub Copilot CLI for Work WSL)
local agents = {
	{
		label = "Antigravity CLI (agy)      [Google AI Pro]",
		cmd = "agy",
	},
	{
		label = "GitHub Copilot CLI         [Work WSL - Claude / GPT]",
		cmd = "copilot",
	},
}

local is_wsl = vim.fn.has("wsl") == 1
local current_agent = is_wsl and agents[2] or agents[1]

-- Store a persistent terminal buffer per agent so switching doesn't kill active sessions
local agent_bufs = {}
local sidebar_win = nil

local function show_agent_in_sidebar(agent)
	local buf = agent_bufs[agent.cmd]
	if buf and vim.api.nvim_buf_is_valid(buf) then
		vim.api.nvim_win_set_buf(sidebar_win, buf)
	else
		buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_win_set_buf(sidebar_win, buf)
		vim.fn.termopen(agent.cmd)
		agent_bufs[agent.cmd] = buf

		if M.on_term_buf then
			M.on_term_buf(buf)
		end
	end

	-- Clean up terminal split appearance (no line numbers or sign column)
	vim.wo[sidebar_win].number = false
	vim.wo[sidebar_win].relativenumber = false
	vim.wo[sidebar_win].signcolumn = "no"
end

function M.toggle()
	if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
		vim.api.nvim_win_hide(sidebar_win)
		sidebar_win = nil
		return
	end

	vim.cmd("botright vertical new")
	vim.cmd("vertical resize " .. math.floor(vim.o.columns * 0.4))
	sidebar_win = vim.api.nvim_get_current_win()

	show_agent_in_sidebar(current_agent)
	vim.cmd("startinsert")
end

function M.select_agent()
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	pickers
		.new({}, {
			prompt_title = "Select AI CLI Agent (Active: " .. current_agent.cmd .. ")",
			finder = finders.new_table({
				results = agents,
				entry_maker = function(entry)
					local is_active = (entry.cmd == current_agent.cmd)
					return {
						value = entry,
						display = (is_active and "* " or "  ") .. entry.label,
						ordinal = entry.label .. " " .. entry.cmd,
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
					current_agent = selection.value
					vim.notify("AI CLI Agent -> " .. current_agent.cmd, vim.log.levels.INFO)

					if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
						vim.api.nvim_set_current_win(sidebar_win)
						show_agent_in_sidebar(current_agent)
						vim.cmd("startinsert")
					end
				end)
				return true
			end,
		})
		:find()
end

return M
