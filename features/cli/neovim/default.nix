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
			plugins = with pkgs.vimPlugins; [ catppuccin-nvim nvim-treesitter.withAllGrammars ];
			extraLuaConfig = builtins.readFile ./init.lua;
		};
    home.file = {
      ".config/nvim/lua" = {
        source = ./lua;
        recursive = true;
      };
    };
	};
}
