vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = false 

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = true
-- vim.opt.dir
vim.opt.backup = false

vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = true

vim.opt.incsearch = true
vim.opt.inccommand = 'split'

vim.opt.termguicolors = true

vim.opt.scrolloff = 10
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

vim.opt.colorcolumn = "80"

-- when in insert mode, show completion options even if only one match, and don't select or insert anything until they select an option
-- preview is extra information in a display window, might be too much
vim.o.completeopt = 'menuone,noselect,preview'

vim.o.mouse = 'a'

vim.o.clipboard = 'unnamedplus'

-- case insensitive search unless capitals are used
vim.o.ignorecase = true
vim.o.smartcase = true

