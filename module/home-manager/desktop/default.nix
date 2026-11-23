{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.custom.desktop;
  system = pkgs.stdenv.hostPlatform.system;
  hasAntigravity =
    inputs.llm-agents.packages ? ${system}
    && inputs.llm-agents.packages.${system} ? antigravity-cli;
  antigravityCliPkg = inputs.llm-agents.packages.${system}.antigravity-cli;
  antigravityLauncherPkg = pkgs.writeShellScriptBin "antigravity-launcher" ''
    set -euo pipefail

    WORKSPACE="''${HOME}/Workspace"
    mkdir -p "''${WORKSPACE}"

    selected="$(
      {
        printf '%s\n' "''${WORKSPACE}"
        ${pkgs.findutils}/bin/find "''${WORKSPACE}" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' \
          | ${pkgs.coreutils}/bin/sort -rn \
          | ${pkgs.coreutils}/bin/cut -d' ' -f2-
        if [ -d "''${HOME}/.nix-config" ]; then
          printf '%s\n' "''${HOME}/.nix-config"
        fi
        printf '%s\n' "''${HOME}"
      } | ${pkgs.gnused}/bin/sed "s|^''${HOME}|~|" \
        | ${pkgs.fzf}/bin/fzf \
            --reverse \
            --prompt="Antigravity dir > " \
            --header="Enter: open (default ~/Workspace) | Esc: cancel"
    )" || exit 0

    target="''${selected/#\~/''${HOME}}"
    cd "''${target}"
    exec ${antigravityCliPkg}/bin/agy "$@"
  '';
  usbMicroscopePkg = pkgs.writeShellScriptBin "usb-microscope" ''
    DEV="$(${pkgs.coreutils}/bin/readlink -f /dev/v4l/by-id/usb-Etron_Technology__Inc._USB_Microscope-video-index0)"
    exec ${pkgs.guvcview}/bin/guvcview -d "''${DEV}" "$@"
  '';
in
{
  imports = [
    ./hyprland
    ./niri
    ./wayland.nix
  ];

  options = {
    custom.desktop.enable = mkEnableOption "desktop config";
  };

  config = mkIf cfg.enable {
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };

    custom.desktop.hyprland.enable = false;
    custom.desktop.wayland.enable = true;
    catppuccin = {
      enable = true;
      autoEnable = true;
      ghostty = {
        enable = true;
        flavor = "mocha";
      };
    };

    gtk = {
      enable = true;
      gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
      gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
      gtk4.theme = null;
    };

    home.packages = with pkgs; [
      guvcview
      usbMicroscopePkg
    ];

    xdg.desktopEntries = {
      usb-microscope = {
        name = "USB Microscope";
        genericName = "Microscope Viewer";
        comment = "Open guvcview directly on the Etron USB Microscope";
        exec = "${usbMicroscopePkg}/bin/usb-microscope";
        icon = "guvcview";
        terminal = false;
        categories = [
          "AudioVideo"
          "Video"
        ];
      };
    }
    // optionalAttrs hasAntigravity {
      antigravity = {
        name = "Antigravity";
        genericName = "AI Coding Assistant";
        comment = "Select a directory in ~/Workspace and launch Antigravity CLI (agy)";
        exec = "${antigravityLauncherPkg}/bin/antigravity-launcher";
        icon = "utilities-terminal";
        terminal = true;
        categories = [
          "Development"
          "Utility"
          "ConsoleOnly"
        ];
        settings = {
          Path = "${config.home.homeDirectory}/Workspace";
          Keywords = "agy;ai;assistant;agent;antigravity;";
        };
      };
    };

    programs = {
      google-chrome.enable = true;
      firefox = {
        enable = true;
        configPath = "${config.xdg.configHome}/mozilla/firefox";
      };
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

    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [
          "NotoSerif Nerd Font"
          "FiraCode Nerd Font"
        ];
        sansSerif = [
          "NotoSans Nerd Font"
          "FiraCode Nerd Font"
        ];
        monospace = [
          "FiraCode Nerd Font"
          "NotoMono Nerd Font"
        ];
      };
    };

    home.pointerCursor = {
      enable = true;
      gtk.enable = true;
      x11.enable = true;
      name = "catppuccin-latte-light-cursors";
      package = pkgs.catppuccin-cursors.latteLight;
      size = 24;
    };
  };
}
