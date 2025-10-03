{
  pkgs,
  lib,
  profile,
  inputs,
  ...
}:
{
  # imports = [
  # inputs.catppuccin.homeModules.catppuccin
  #   ./features
  # ];

  home.packages = with pkgs; [ git ];
  home.stateVersion = "24.05";

  catppuccin = {
    enable = true;
    flavor = "mocha";
  };

  custom.cli.enable = true;
  custom.desktop.enable = lib.mkIf profile.graphical true;

  targets.genericLinux.enable = true;

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
