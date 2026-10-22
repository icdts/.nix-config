vim.diagnostic.config({
	virtual_text = true,
	update_in_insert = true,
	underline = true,
	severity_sort = true,
	float = { source = true },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = " ",
			[vim.diagnostic.severity.WARN] = " ",
			[vim.diagnostic.severity.HINT] = " ",
			[vim.diagnostic.severity.INFO] = " ",
		},
	},
})

local hostname = vim.fn.system("hostname -s"):match("([^\r\n]+)") or "my-host"
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
				runtime = { version = "LuaJIT" },
				diagnostics = { globals = { "vim" } },
				workspace = {
					library = vim.api.nvim_get_runtime_file("", true),
					checkThirdParty = false,
				},
				telemetry = { enable = false },
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

vim.lsp.config("*", {
	capabilities = require("cmp_nvim_lsp").default_capabilities(),
})

for server_name, config in pairs(servers) do
	vim.lsp.config(server_name, config)
	vim.lsp.enable(server_name)
end
