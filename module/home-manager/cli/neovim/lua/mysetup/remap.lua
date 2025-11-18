vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set('n', 'gcc', '<Nop>', { silent = true })
--clear search on esc
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- open netrw
vim.keymap.set("n", "<leader>n", vim.cmd.Ex)

-- Move current line along with us when moving up and down
-- >+ moves current selection down a line (swap with current line)
-- <CR> newline
-- gv highlight using last selection
-- = indent
-- gv highlight using last select
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- mz add mark to register z
-- J join next line to this one
-- `z go to the mark set
-- basically make J not change cursor position
vim.keymap.set("n", "J", "mzJ`z")


-- keep curson in center of screen when half screen stepping
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- center cursor when stepping through search items n,zz,zv
-- zv unfolds if there are folds.  I don't use these but it doesn't hurt
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- avoid :q shenanigans
vim.keymap.set("n", "Q", "<nop>")

-- Change this mapping
-- vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

-- quickfix bindings, probably change these?
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

-- make file executable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- diagnostic keymaps, error message jumping
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- hover documentation
vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'Hover Documentation'})
vim.keymap.set('n', ' k', vim.lsp.buf.signature_help, { desc = 'Signature Documentation'})


-- ???
vim.keymap.set({"n", "v"}, "<leader>y", [["+y]], { desc = '[y]ank line or selection into system clipboard'})
vim.keymap.set({"n", "v"}, "<leader>d", [["_d]], { desc = 'delete and discard.  [d]on\'t put in any register' } )
vim.keymap.set("n", "<leader>rw", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = '[r]eplace [w]ord in file' })

vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = '[G]oto [D]eclaration' } )

-- vim.keymap.set("n", "<leader>vpp", "<cmd>e init.lua<CR>");

-- vim.keymap.set("n", "<leader>vwm", function()
--     require("vim-with-me").StartVimWithMe()
-- end)
-- vim.keymap.set("n", "<leader>svwm", function()
--     require("vim-with-me").StopVimWithMe()
-- end)
