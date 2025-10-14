{
  config,
  pkgs,
  inputs,
  ...
}:
let
  name = "voron24";
  mDnsName = "${name}.local";
in
{
  networking = {
    hostName = name;
    firewall.allowedTCPPorts = [ 22 80 443 ];
  };

  sops = {
    secrets = {
      "${name}-key.pem" = { 
        owner = config.users.users.nginx.name; 
        mode = "0400";
      };
      "${name}-crt.pem" = { 
        owner = config.users.users.nginx.name; 
      };
    };
  };

  users.groups.klipper = {};
  users.users.klipper = {
    isNormalUser = false;
    isSystemUser = true;
    createHome = true;
    home = "/var/lib/klipper";
    group = "klipper";
  };

  services.klipper = {
    enable = true;
    user = "klipper";
    group = "klipper";
    configFile = ./klipper.cfg;
    logFile = "/var/lib/klipper/klipper.log";
    firmwares = {
      mcu = {
        enable = true;
        enableKlipperFlash = true;
        configFile = ./octopus_v1.0.1.cfg;
        serial = "/dev/serial/by-id/usb-STMicroelectronics_MARLIN_BIGTREE_OCTOPUS_V1_CDC_in_FS_Mode_319432623430-if00";
      };
      toolhead = {
        enable = true;
        enableKlipperFlash = true;
        configFile = ./ebb36.v1.2.cfg;
      };
      u2c = {
        enable = true;
      };
    };
  };

  services.moonraker = {
    enable = true;
    address = "127.0.0.1";
    settings = {
      authorization = {
        trusted_clients = [
            "127.0.0.1"
            "::1"
        ];
        cors_domains = [
          "http://*.local"
          "http://${name}"
          "http://${mDnsName}"
          "https://*.local"
          "https://${name}"
         "https://${mDnsName}"
        ];
      };
    };
  };
  users.users.moonraker.extraGroups = [ "klipper" ];

  services.fluidd = {
    enable = true;
    nginx = {
      serverName = mDnsName;
      serverAliases = [ name ];
      sslCertificate = config.sops.secrets."${name}-crt.pem".certPath;
      sslCertificateKey = config.sops.secrets."${name}-key.pem".keyPath;
    };
  };

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
    # 2. Run `lsusb`< to see connected devices. Find your board in the list.
    #    Example output: Bus 001 Device 005: ID 1d50:614e OpenMoko, Inc.
    # 3. Replace the values below with the ones you found.
    # The values "1d50" and "614e" are common for boards flashed with Klipper.
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="614e", SYMLINK+="print-board"
  '';

  environment.systemPackages = with pkgs; [
    gcc-arm-embedded
    kconfig-frontends
    dfu-util
    python3
    pkgsCross.avr.buildPackages.gcc
    pkgsCross.avr.buildPackages.gpp
  ];

  imports = [
    (inputs.nixpkgs + "/nixos/modules/installer/sd-card/sd-image-aarch64.nix")
  ];

  sdImage.compressImage = false;
}
