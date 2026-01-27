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
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
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

  # Enable Plasma for when you "Switch to Desktop"
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = false;

  custom.siyuan.enable = true;

  imports = [];
}
