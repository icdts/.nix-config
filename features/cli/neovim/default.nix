{ pkgs, config, lib, ... }: 
  with lib; let
    cfg = config.custom.cli.neovim;
  in {
  	options.custom.cli.neovim.enable = mkEnableOption "neovim";

	config = mkIf cfg.enable {

    home.sessionVariables = {
      EDITOR = "nvim";
    };
		programs.neovim = {
			enable = true;
			defaultEditor = true;
			plugins = with pkgs.vimPlugins; [ 
				catppuccin-nvim # coloring
				nvim-treesitter.withAllGrammars # syntax highlighting`
				which-key-nvim # popup showing what key presses do what
				indent-blankline-nvim #highlighting indent
				nvim-lspconfig # lsp integration
				lualine-nvim # status line
				telescope-nvim # file nav
				telescope-fzf-native-nvim # use fzf integration

				nvim-cmp # completion engine
				cmp-buffer	# completion sourced from buffer
				cmp-path # completion of filesystem paths
				cmp-cmdline # vim's command line completion 
				cmp-nvim-lsp # completion sourced from lsp
			];
			extraLuaConfig = builtins.readFile ./init.lua;
		};
    home.file = {
      ".config/nvim/lua" = {
        source = ./lua;
        recursive = true;
      };
    };
		home.packages = with pkgs; [
			ccls
			nil
			ruby-lsp
			gopls
			zls
			lua-language-server
		];
	};
}
