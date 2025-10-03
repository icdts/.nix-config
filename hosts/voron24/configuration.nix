{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  # wifi-ssid = config.sops.secrets.wifi-ssid;
  # wifi-psk = config.sops.secrets.wifi-psk;
in
{
  networking = {
    # networkmanager.enable = lib.mkForce false;
    hostName = "voron24";
    # wireless.enable = true;
    # wireless.interfaces = [ "wlan0" ];
    # wireless.networks.${wifi-ssid} = {
    # 	psk = wifi-psk;
    # };
  };

  services.klipper = {
    enable = true;
    # Add this settings block to satisfy the module's assertion.
    # This is just a placeholder and will be overridden by your
    # full printer.cfg file once you create it.
    settings = {
      printer = {
        kinematics = "none";
        max_velocity = 1;
        max_accel = 1;
      };
    };
  };
  services.moonraker = {
    enable = true;
  };
  services.fluidd.enable = true;

  services.samba = {
    enable = true;
    settings = {
      gcode_files = {
        path = "/var/lib/klipper/printer_data/gcodes";
        "guest ok" = "yes";
        "read only" = "no";
        "force user" = "klipper"; # Ensures files have correct permissions
        browseable = "yes";
      };
    };
  };

  services.udev.extraRules = ''
    # This rule creates a symlink /dev/print-board for your Octopus Pro.
    # To find the correct idVendor and idProduct:
    # 1. SSH into the Pi.
    # 2. Run `lsusb` to see connected devices. Find your board in the list.
    #    Example output: Bus 001 Device 005: ID 1d50:614e OpenMoko, Inc.
    # 3. Replace the values below with the ones you found.
    # The values "1d50" and "614e" are common for boards flashed with Klipper.
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="614e", SYMLINK+="print-board"
  '';

  environment.systemPackages = with pkgs; [
    # Tools for building Klipper MCU firmware
    # This is the compiler toolchain for ARM MCUs like the one on the Octopus Pro
    gcc-arm-embedded
    # Required for `make menuconfig`
    kconfig-frontends
    # Sometimes needed for flashing
    dfu-util
  ];

  imports = [
    (inputs.nixpkgs + "/nixos/modules/installer/sd-card/sd-image-aarch64.nix")
  ];

  sdImage.compressImage = false;
}
