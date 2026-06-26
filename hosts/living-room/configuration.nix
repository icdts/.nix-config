{ config, pkgs, lib, ... }:
{
  networking.hostName = "living-room";

  hardware.graphics = {
    enable = true;
  };

  boot = {
    kernelModules = [
      "amdgpu"
    ];
    kernelParams = [
      "amdgpu.sg_display=0"
    ];
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
  swapDevices = [ { device = "/dev/nvme0n1p3"; } ];

  environment.systemPackages = with pkgs; [
    networkmanagerapplet
    orca-slicer
    android-tools
  ];

  services.fstrim.enable = true; # ssd health

  hardware.bluetooth.enable = true; # enables support for Bluetooth

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };
  services.blueman.enable = true;

  powerManagement.enable = true;
  # powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  services.auto-cpufreq.enable = false;
  services.tlp.enable = false;

  nixpkgs.config.allowUnfree = true;

  custom.generate-cert.enable = true;
  custom.pipewire.enable = true;
  custom.steam.enable = true;



  jovian = {
    steam = {
      enable = true;
      autoStart = true;
      user = "rn";
      desktopSession = "plasma"; # This is where you pick your "Desktop Mode"
    };
    devices.steamdeck.enable = false; # Set to false since this is a desktop
  };

  fileSystems."/mnt/sharedrive" = {
    device = "/dev/disk/by-label/sharedrive";
    fsType = "ext4";
  };

  services.samba = {
    enable = true;
    openFirewall = true; # Automatically opens ports 137, 138, 139, 445
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "living-room Samba Server";
        "netbios name" = "living-room";
        "security" = "user";
      };
      # The name of the share as it will appear in Windows
      "living-room Drive" = {
        path = "/mnt/sharedrive";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "rn";
        "force group" = "users";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  # Enable Plasma for when you "Switch to Desktop"
  services.desktopManager.plasma6.enable = true;
  # services.displayManager.sddm.enable = false;

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  imports = [];
}
