{
  pkgs,
  lib,
  profile,
  config,
  ...
}:
{
  imports = [
    ./cli
    ./desktop
  ];

  home.packages = with pkgs; [ git ];
  home.stateVersion = "24.05";

  systemd.user.services.load-google-api-key = {
    Unit = {
      Description = "Load Google API Key into systemd environment";
      Before = [ "graphical-session-pre.target" ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "/bin/sh -c 'systemctl --user set-environment GOOGLE_API_KEY=\"$(cat /run/secrets/google-api-key)\"'";
    };
  };

  catppuccin = {
    enable = true;
    flavor = "mocha";
  };

  custom.cli.enable = true;
  custom.desktop.enable = lib.mkIf profile.graphical true;

  # targets.genericLinux.enable = true;

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
}
