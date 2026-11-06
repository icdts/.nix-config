{
  config,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:
with lib;
let
  cfg = config.custom.cli;
  gpgKeyFingerprint = "E8FD78A26AC9B2EDDB7E99B2A5F5FD82064D3A6B";
  gpgKeySecretPath =
    if osConfig != null && osConfig ? sops && osConfig.sops.secrets ? icdts-gpg-key then
      osConfig.sops.secrets.icdts-gpg-key.path
    else
      "/run/secrets/icdts-gpg-key";
in
{
  imports = [
    ./neovim
  ];

  options.custom.cli.enable = mkEnableOption "cli basics";

  config = mkIf cfg.enable {

    custom.cli.neovim.enable = true;

    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "icdts";
          email = "icandothings@gmail.com";
        };
        init.defaultBranch = "main";
      };
      signing = {
        key = gpgKeyFingerprint;
        signByDefault = true;
      };
    };

    programs.gpg = {
      enable = true;
    };

    services.gpg-agent = {
      enable = true;
      enableBashIntegration = true;
      pinentry.package = pkgs.pinentry-curses;
    };

    home.activation.importGpgKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -r "${gpgKeySecretPath}" ]; then
        $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --import "${gpgKeySecretPath}"
        $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --import-ownertrust <<< "${gpgKeyFingerprint}:6:"
      fi
    '';

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
      changeDirWidget.command = "fd --type d --exclude .git --follow --hidden";
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
