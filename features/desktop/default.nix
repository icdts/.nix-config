{ config, lib, ... } :
  with lib; let
    cfg = config.custom.desktop;
  in {
    imports = [
      ./hyprland.nix
      ./wayland.nix
    ];

    options	= {
			custom.desktop.enable = mkEnableOption "desktop config";
		};

    config = mkIf cfg.enable {
      custom.desktop.hyprland.enable = true;
      custom.desktop.wayland.enable = true;
			catppuccin.ghostty = {
				enable = true;
				flavor = "mocha";
			};
      programs = {
        google-chrome.enable = true;
        firefox.enable = true;
        ghostty = {
          enable = true;
          enableZshIntegration = true;
          installVimSyntax = true;
          settings = {
            font-size = 10;
            window-decoration = false;
            window-theme = "ghostty";
            background-opacity = 0.85;
          };
        };
      };
    };
  }
