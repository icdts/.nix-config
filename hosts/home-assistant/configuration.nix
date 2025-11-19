{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
let
  name = "home-assistant";
in
{
  networking = {
    hostName = name;
    firewall.allowedTCPPorts = [
      22
      6052 # ESPHome Dashboard
      8123 # Home Assistant web interface
      21063 # HomeKit Bridge (optional, but good for Apple Home integration)
    ];
    firewall.allowedUDPPorts = [
      5353 # mDNS/Avahi (Device Discovery)
      6053 # ESPHome API (AirGradient)
    ];
    useNetworkd = true;
    networkmanager.enable = lib.mkForce false;
  };

  systemd.network.enable = true;

  systemd.network.networks."10-wired" = {
    matchConfig.Name = "end0";
    networkConfig = {
      DHCP = "yes";
      IPv6PrivacyExtensions = "kernel";
    };
  };

  services.home-assistant = {
    enable = true;
    extraComponents = [
      "cast"
      "google_translate"
      "thread"

      "zha" # Zigbee Home Automation (for SONOFF Dongle + Hue Bulbs)
      "esphome" # For AirGradient ONE
      "mobile_app" # Phone integration
      "wake_on_lan"
      "webostv"

      "homekit_controller"
      "androidtv_remote"
      "ecobee"
      "airgradient"
    ];
    config = {
      default_config = { };
      http = {
        server_port = 8123;
      };
      wake_on_lan = { };
    };
  };
  services.esphome.enable = true;

  services.udev.extraRules = ''
    # SONOFF Zigbee 3.0 USB Dongle Plus-E
    # Adjust idVendor/idProduct if yours differs (usually 1a86:55d4 or 10c4:ea60 depending on "E" or "P" variant)
    # The "E" variant (EFR32MG21) often shows as 1a86:55d4
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="55d4", SYMLINK+="zigbee-dongle"
  '';

  environment.systemPackages = with pkgs; [
    wakeonlan # Required to turn on LG TV over network
  ];

  
  boot.supportedFilesystems = lib.mkForce [ "ext4" "vfat" ];

  imports = [
    (inputs.nixpkgs + "/nixos/modules/installer/sd-card/sd-image-aarch64.nix")
  ];

  sdImage.compressImage = false;
}
