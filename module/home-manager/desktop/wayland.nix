{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.custom.desktop.wayland;
in
{
  options.custom.desktop.wayland.enable = mkEnableOption "wayland extra tools and config";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      qt6.qtwayland
      waypipe
      wl-mirror
      wl-clipboard
      wtype
      ydotool
      nnn
      playerctl
      brightnessctl
    ];
  };
}
