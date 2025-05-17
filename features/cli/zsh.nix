{ config, lib, pkgs, ... }: 
  with lib; let
    cfg = config.custom.cli.zsh;
  in {
    options.custom.cli.zsh.enable = mkEnableOption "zsh";

    config = mkIf cfg.enable {
      programs.eza = {
        enable = true;
        enableZshIntegration = true;
        extraOptions = ["--icons" "--git"];
      };

      programs.bat = {enable = true;};

      home.packages = with pkgs; [
        coreutils
        htop
        httpie
        jq
        procs
        tldr
        zip
        ripgrep
      ];

      programs.zsh = {
        enable = true;
        syntaxHighlighting.enable = true;
        enableCompletion = true;


        dotDir = ".config/zsh";

        initContent= ''
          export NIX_PATH nixpkgs=channel:nixos-unstable
          export NIX_LOG info

        '';

        shellAliases = {
          ls = "eza";
          grep = "rg";
          ps = "procs";
          cat = "bat";
        };

        history = {
          size = 10000;
          path = "${config.xdg.dataHome}/zsh/history";
          ignoreDups = true;
        };
      };
    };
  }
