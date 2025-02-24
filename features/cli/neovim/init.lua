require("lua.set");
require("lua.remap");

-- briefly highlight what is being yanked
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
  vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

vim.cmd.colorscheme 'catppuccin-mocha'

require('nvim-treesitter.configs').setup {
  highlight = {
    enable = true,
  },
}

require("lua.nvim-cmp")
require("lua.lsp")
require("lua.line")
require("lua.telescope")
