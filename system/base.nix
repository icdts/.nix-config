{ config, pkgs, inputs, system, ... }:
let
  syspkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
in
{
  imports = [
    ../users/rn/default.nix
  ];

  sops = {
    defaultSopsFile = ../secrets.json;
    age.keyFile = "/var/lib/sops/key.txt";
    secrets = {
      "wifi.env" = { };
    };
  };

  boot.loader.systemd-boot.enable = inputs.nixpkgs.lib.mkIf (system == "x86_64-linux") true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = syspkgs.linuxPackages_latest;

  networking = {
    networkmanager = {
      enable = true;
      ensureProfiles = {
        environmentFiles = [
          config.sops.secrets."wifi.env".path
        ];
        profiles = {
          "home-wifi" = {
            connection = {
              id = "home-wifi";
              type = "wifi";
              interface-name = "wlp195s0";
            };
            wifi.ssid = "$HOME_SSID";
            wifi-security = {
              auth-alg = "open";
              key-mgmt = "wpa-psk";
              psk = "$HOME_PSK";
            };
          };
        };
      };
    };
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  time.timeZone = "America/Chicago";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    allowSFTP = true;
  };

  security.sudo = {
    wheelNeedsPassword = false;
    enable = true;
  };

  users.mutableUsers = false;

  system.stateVersion = "24.05";
  catppuccin = {
    enable = true;
    flavor = "mocha";
  };

  environment.systemPackages = with syspkgs; [
    git
    gnumake
  ];
  users.defaultUserShell = syspkgs.bash;

  fonts.enableDefaultPackages = true;
  fonts.packages = with syspkgs; [
    nerd-fonts.fira-code
    nerd-fonts.noto
  ];
}
