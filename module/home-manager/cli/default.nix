{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.custom.cli;
in
{
  imports = [
    ./neovim
  ];

  options.custom.cli.enable = mkEnableOption "cli basics";

  config = mkIf cfg.enable {

    custom.cli.neovim.enable = true;

    programs.eza = {
      enable = true;
      enableBashIntegration = true;
      extraOptions = [
        "--icons"
        "--git"
      ];
    };
    programs.bat = {
      enable = true;
    };
    programs.fzf = {
      enable = true;
      enableBashIntegration = true;
      defaultCommand = "fd --type f --exclude .git --follow --hidden";
      changeDirWidgetCommand = "fd --type d --exclude .git --follow --hidden";
    };
    home.packages = with pkgs; [
      coreutils
      fd
      htop
      httpie
      jq
      procs
      ripgrep
      tldr
      zip
      unzip
    ];
  };
}
