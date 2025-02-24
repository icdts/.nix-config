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
				indent-blankline-nvim
				comment-nvim
				nvim-lspconfig
				nvim-cmp
				cmp-buffer
				cmp-path
				cmp-cmdline
				cmp-nvim-lsp
				lualine-nvim
				telescope-nvim
				telescope-fzf-native-nvim
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
