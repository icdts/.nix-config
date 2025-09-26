{pkgs, lib, profile, inputs, ...}: {
  home.packages = with pkgs; [git];
  home.stateVersion = "24.05";
  programs = {
    home-manager.enable = true;
  };
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
      experimental-features = ["nix-command flakes"];
    };
  };

  imports = [
		inputs.catppuccin.homeModules.catppuccin
    ./features
    {
      custom.cli.enable = true;
      custom.desktop.enable = lib.mkIf profile.graphical true;
    }
  ];
}
