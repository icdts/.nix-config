{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.steam;
in
{
  options.custom.steam.enable = lib.mkEnableOption "enable steam";
  config = lib.mkIf cfg.enable {
    programs = {
      steam = {
        enable = true;
        package = lib.mkIf config.custom.nvidia-prime.enable (
          pkgs.steam.override {
            extraEnv = {
              __NV_PRIME_RENDER_OFFLOAD = "1";
              __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
              __GLX_VENDOR_LIBRARY_NAME = "nvidia";
              __VK_LAYER_NV_optimus = "NVIDIA_only";
            };
          }
        );
        remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
        dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      };
    };
    hardware.steam-hardware.enable = true;

    # Enables the Wi-Fi regulatory database for the kernel
    hardware.wirelessRegulatoryDatabase = true;

    # Open firewall ports for Steam Frame and VR streaming
    networking.firewall.allowedTCPPorts = [ 27036 27037 ];
    networking.firewall.allowedUDPPorts = [ 27031 27036 10400 10401 ];
  };
}
