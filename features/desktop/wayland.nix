{ config, lib, pkgs, ... }:
with lib; let
  cfg = config.custom.desktop.wayland;
in
{
  options.custom.desktop.wayland.enable = mkEnableOption "wayland extra tools and config";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      grim
      hyprlock
      qt6.qtwayland
      slurp
      waypipe
      wl-mirror
      wl-clipboard
      wlogout
      wtype
      ydotool
      wofi
      nnn
      playerctl
      brightnessctl
    ];
  };
}
