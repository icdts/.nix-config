{ config, pkgs, lib, ... }:
{
  networking.hostName = "rnl";

  hardware.graphics = {
    enable = true;
  };

  boot = {
    kernelModules = [
      "amdgpu"
    ];
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
  swapDevices = [ { device = "/swapfile"; } ];

  environment.systemPackages = with pkgs; [
    networkmanagerapplet
    orca-slicer
  ];
  programs.adb.enable = true;

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

  imports = [];
}
