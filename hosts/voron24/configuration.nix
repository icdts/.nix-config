{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
let
  name = "voron24";
  mDnsName = "${name}.local";
in
{
  networking = {
    hostName = name;
    firewall.allowedTCPPorts = [
      22
      80
      443
    ];
    useNetworkd = true;
    networkmanager.enable = lib.mkForce false;
  };
  systemd.network.enable = true;

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

  users.groups.klipper = { };
  users.users.klipper = {
    isNormalUser = false;
    isSystemUser = true;
    createHome = true;
    home = "/var/lib/klipper";
    group = "klipper";
  };

  systemd.tmpfiles.rules = [
    "L /var/lib/klipper/KAMP - - - - ${inputs.klipper-adaptive-meshing}/Configuration"
  ];
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
        serial = "/dev/serial/by-id/usb-Klipper_stm32f446xx_30005E001551303432323631-if00";
      };
      # toolhead = {
      #   enable = false;
      #   enableKlipperFlash = true;
      #   configFile = ./ebb36.v1.2.cfg;
      #   serial = "/dev/ebb36";
      # };
    };
  };

  boot.kernelModules = [
    "can"
    "can-dev"
    "can-raw"
  ];
  systemd.network = {
    links = {
      "10-can0" = {
        matchConfig = {
          OriginalName = "can0";
        };
        linkConfig = {
          TransmitQueueLength = 1024;
          MTUBytes = "16";
        };
      };
    };

    networks = {
      "10-can0" = {
        matchConfig = {
          Name = "can0";
        };
        networkConfig = {
          LinkLocalAddressing = "no";
          ConfigureWithoutCarrier = true;
        };
        canConfig = {
          BitRate = 500000;
        };
      };
      "11-wired" = {
        matchConfig = {
          Name = "end0";
        };
        networkConfig = {
          DHCP = "yes";
          IPv6PrivacyExtensions = "kernel";
        };
      };
    };
  };
  networking.wireless.iwd.enable = true;

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
      file_manager = {
        enable_object_processing = true;
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
      extraConfig = ''
        client_max_body_size 250M;
      '';
    };
  };

  # services.samba = {
  #   enable = true;
  #   settings = {
  #     gcode_files = {
  #       path = "/var/lib/klipper/printer_data/gcodes";
  #       "guest ok" = "yes";
  #       "read only" = "no";
  #       "force user" = "klipper"; # Ensures files have correct permissions
  #       browseable = "yes";
  #     };
  #   };
  # };

  services.udev.extraRules = ''
    # This rule creates a symlink /dev/print-board for your Octopus Pro.
    # To find the correct idVendor and idProduct:
    # 1. SSH into the Pi.
    # 2. Run `lsusb`< to see connected devices. Find your board in the list.
    #    Example output: Bus 001 Device 005: ID 1d50:614e OpenMoko, Inc.
    # 3. Replace the values below with the ones you found.
    # The values "1d50" and "614e" are common for boards flashed with Klipper.
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="614e", SYMLINK+="octupus"
  '';

  environment.systemPackages = with pkgs; [
    gcc-arm-embedded
    kconfig-frontends
    dfu-util
    python3
    pkgsCross.avr.buildPackages.gcc
    pkgsCross.avr.buildPackages.gpp
    gcc
    gpp
    can-utils
    python3.pkgs.numpy
    python3.pkgs.matplotlib
  ];

  imports = [
    (inputs.nixpkgs + "/nixos/modules/installer/sd-card/sd-image-aarch64.nix")
  ];

  sdImage.compressImage = false;
}
