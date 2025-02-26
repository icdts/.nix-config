local cmp = require'cmp'

cmp.setup {
  snippet = {
    -- REQUIRED - you must specify a snippet engine
    expand = function(args)
			vim.snippet.expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(), -- Or <cmd> lua vim.lsp.buf.complete()<CR> if you prefer
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select = false` to only confirm explicitly selected items.
  }),
  sources = cmp.config.sources({
    { name = 'path' },
    { name = 'nvim_lsp' },
    { name = 'nvim_lua' },
    { name = 'luasnip' }, -- Snippets, you'll need to install a snippet plugin (like luasnip)
    { name = 'buffer' },
    { name = 'cmdline' },
  }),
}
