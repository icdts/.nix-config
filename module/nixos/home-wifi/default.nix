{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.home-wifi;
  useSystemdNetworkd = config.systemd.network.enable;
in
{
  options.custom.home-wifi = {
    enable = lib.mkEnableOption "setup home wifi networks";
    networkmanager.enable = lib.mkOption {
      description = "use network manager for wifi";
      type = lib.types.bool;
      default = !useSystemdNetworkd;
    };
    networkd.enable = lib.mkOption {
      description = "use systemd networkd for wifi";
      type = lib.types.bool;
      default = useSystemdNetworkd;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      sops.secrets = {
        "home-wifi.ssid" = { };
        "home-wifi.psk" = { };
      };

      warnings = lib.optionals (cfg.networkmanager.enable && cfg.networkd.enable) [
        "custom.home-wifi: Both networkmanager and networkd backends are enabled. This may cause conflicts unless you have a specific reason for this configuration."
      ];
    })
  ];

  imports = [
    ./networkmanager.nix
    ./networkd.nix
  ];
}
