{
  config,
  pkgs,
  inputs,
  system,
  lib,
  ...
}:
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

  nix.settings = {
    trusted-users = [ "@wheel" ];
    auto-optimise-store = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    warn-dirty = true;
    secret-key-files = [
      config.sops.secrets."build-key.sec".path
    ];
    trusted-public-keys = [ "rn-build-key-1:sPv68G4AoMOKjKbHbX8HL21esn+6R3Z9y1UnGNxvSyc=" ];
  };

  sops = {
    defaultSopsFile = ../secrets.json;
    age.keyFile = "/var/lib/sops/key.txt";
    secrets = {
      "build-key.sec" = {
        path = "/var/lib/sops/build-key.sec";
      };
      "key.pem" = {
        owner = config.users.users.rn.name;
      };
      "ca.pem" = {
        owner = config.users.users.rn.name;
      };
    };
  };

  custom.generate-cert = {
    caKeyFile = config.sops.secrets."key.pem".path;
    caCertFile = config.sops.secrets."ca.pem".path;
  };

  boot.loader.systemd-boot.enable = inputs.nixpkgs.lib.mkIf (system == "x86_64-linux") true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = syspkgs.linuxPackages_latest;

  networking = {
    search = [ "local" ];
    networkmanager = {
      enable = true;
    };
  };
  custom.home-wifi.enable = lib.mkDefault true;

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
    settings = {
      PermitRootLogin = "no";
      AcceptEnv = [
        "TERM"
        "LANG"
        "LC_*"
        "LANGUAGE"
        "COLORTERM"
      ];
    };
    allowSFTP = true;
  };

  security = {
    sudo = {
      wheelNeedsPassword = false;
      enable = true;
    };
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
  environment.enableAllTerminfo = true;
  users.defaultUserShell = syspkgs.bash;

  fonts.enableDefaultPackages = true;
  fonts.packages = with syspkgs; [
    nerd-fonts.fira-code
    nerd-fonts.noto
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];
}
