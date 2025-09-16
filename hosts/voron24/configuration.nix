# /etc/nixos/configuration.nix
# NixOS configuration for a Klipper-powered Voron 2.4 on a Raspberry Pi 4 B

{ config, pkgs, ... }:

let
  # -- Easy to change user variables --
  # Change these to your actual values
  wifi-ssid = "wifinetworkname";
  wifi-psk = "passwordforwifi";
  
  local-username = "localuser";
  local-password = "passforlocal";

in
{
  # Import basic Raspberry Pi 4 hardware configuration
  imports = [ 
    <nixpkgs/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix> 
  ];

  # ============================================================================
  ## 1. NETWORKING
  # ============================================================================

  # Set a unique hostname for your printer
  networking.hostName = "voron24"; 

  # Wireless network connection
  networking.wireless.enable = true;
  networking.wireless.interfaces = [ "wlan0" ];
  networking.wireless.networks.${wifi-ssid} = {
    psk = wifi-psk;
  };

  # Enable Avahi daemon for .local hostname resolution (mDNS)
  services.avahi = {
    enable = true;
    nssmdns = true; # Allows your Pi to find other .local devices
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  # ============================================================================
  ## 2. USER MANAGEMENT
  # ============================================================================
  
  users.users.${local-username} = {
    isNormalUser = true;
    # IMPORTANT: Set a strong password. This is insecure for demonstration.
    # After your first login, it is HIGHLY recommended to switch to SSH keys.
    password = local-password;
    extraGroups = [ "wheel" ]; # Gives this user sudo privileges
  };

  # -- Instructions for switching to SSH key authentication --
  # 1. After logging in as 'localuser', generate an SSH key on your main computer.
  # 2. Copy the PUBLIC key (e.g., ~/.ssh/id_ed25519.pub) into the section below.
  # 3. Uncomment the following lines.
  # 4. Comment out or delete the `password = local-password;` line above.
  # 5. Run `sudo nixos-rebuild switch`.
  /*
  users.users.${local-username}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAA... your-public-key-here"
  ];
  services.openssh.passwordAuthentication = false;
  */

  # ============================================================================
  ## 3. PRINTER SERVICES (KLIPPER, FLUIDD, ETC.)
  # ============================================================================

  services.klipper = {
    enable = true;
    # The user 'klipper' will be created automatically.
    # No extra config is needed here unless you have multiple MCUs to list.
  };

  # Moonraker is the API that connects Klipper to frontends like Fluidd
  services.moonraker = {
    enable = true;
    # By default, it trusts localhost and allows connections from anywhere.
    # This is fine for a private home network.
  };

  # Fluidd is the web interface
  services.fluidd.enable = true;

  # ============================================================================
  ## 4. SYSTEM & HARDWARE CONFIGURATION
  # ============================================================================

  # Set the timezone for St. Paul, MN
  time.timeZone = "America/Chicago";

  # Enable the Samba service for network file sharing
  services.samba = {
    enable = true;
    shares = {
      gcode_files = {
        path = "${config.services.klipper.dataDir}/gcodes";
        "guest ok" = "yes";
        "read only" = "no";
        "force user" = "klipper"; # Ensures files have correct permissions
        browseable = "yes";
      };
    };
  };

  # Persistent USB device path for your printer board
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


  # ============================================================================
  ## 5. SYSTEM PACKAGES
  # ============================================================================
  
  # Packages available globally on the system
  environment.systemPackages = with pkgs; [
    # Git is required for version control
    git
    
    # Tools for building Klipper MCU firmware
    # This is the compiler toolchain for ARM MCUs like the one on the Octopus Pro
    gcc-arm-embedded 
    # Required for `make menuconfig`
    kconfig 
    # Sometimes needed for flashing
    dfu-util 
  ];
  

  # ============================================================================
  ## 6. SYSTEM BOOT AND SERVICES
  # ============================================================================
  
  # Basic system settings
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "23.11"; # Set to the version of NixOS you installed
}
