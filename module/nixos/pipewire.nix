{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.pipewire;
in
{
  options.custom.pipewire = {
      enable = lib.mkEnableOption "enable pipewire";
    };

  config = lib.mkIf cfg.enable {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    environment.systemPackages = with pkgs; [
      pavucontrol
    ];
  };
}
