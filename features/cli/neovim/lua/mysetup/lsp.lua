-- lua/lsp.lua
-- local lspconfig = require'lspconfig'
local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

vim.diagnostic.config({
	virtual_text = true,
	signs = true,
	update_in_insert = true,
	underline = true,
	severity_sort = true,
	float = {
		source = true,
	},
})

local function merge_tables(t1, t2)
	local result = {}
	for k, v in pairs(t1) do result[k] = v end
	for k, v in pairs(t2) do result[k] = v end
	return result
end

local on_attach = function(client, bufnr)
	vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'
	local opts = { buffer = bufnr, silent = true }

	vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
	vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
	vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
	vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
	vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
	vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
	vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
	vim.keymap.set('n', '<space>wl', function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, opts)
	vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
	vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
	vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
	vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)

	-- Use modern APIs for diagnostics and formatting
	vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
	vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)
	vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
	vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)
	vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, opts)
end

local hostname = vim.fn.system("hostname -s"):match("([^\r\n]+)")
local username = vim.fn.system("whoami"):match("([^\r\n]+)")
hostname = hostname or "my-host"
username = username or "my-user"

local nixos_options_expr = string.format(
  [[(builtins.getFlake ("git+file://" + toString ./.)).nixosConfigurations."%s".options]],
  hostname
)

local servers = {
	ccls = {},
	ruby_lsp = {},
	gopls = {},
	zls = {},
	lua_ls = {
		settings = {
			Lua = {
				runtime = { version = 'LuaJIT' },
				diagnostics = { globals = { 'vim' } },
				workspace = {
					library = vim.api.nvim_get_runtime_file("", true),
					checkThirdParty = false,
				},
				telemetry = { enable = true },
			},
		},
	},
	nixd = {
		settings = {
			nixd = {
				nixpkgs = {
					expr = "import <nixpkgs> { }",
				},
				formatting = {
					command = { "nixfmt" },
				},
				options = {
					nixos = {
						expr = nixos_options_expr,
					},
				},
			},
		},
	},
}

local capabilities = require('cmp_nvim_lsp').default_capabilities()
for server_name, custom_settings in pairs(servers) do
	local server_config = {
		on_attach = on_attach,
		capabilities = capabilities,
	}

	server_config = vim.tbl_deep_extend('force', server_config, custom_settings)

	vim.lsp.config(server_name, server_config)
	vim.lsp.enable({ server_name })
end
