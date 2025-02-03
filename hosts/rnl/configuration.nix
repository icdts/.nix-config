{ config, pkgs, ... }:{
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
      trusted-users = ["@wheel"];
      warn-dirty = false;
    };
  };

  networking.hostName = "rnl";

  hardware.graphics.enable = true;
  hardware.amdgpu.initrd.enable = true;

  boot = {
    kernelParams = [ "initcall_blacklist=acpi_cpufreq_init" "amd_pstate=passive"];
    kernelModules = [ "zenpower" "asus_wmi" ];
    blacklistedKernelModules = [ "k10temp" ];
    extraModulePackages = [ config.boot.kernelPackages.zenpower ];
  };

  environment.systemPackages = with pkgs; [
    networkmanagerapplet
  ];
  programs.nm-applet.enable = true;

  # services.asusd.enable = true;
  services.fstrim.enable = true; #ssd health

  hardware.bluetooth.enable = true; # enables support for Bluetooth

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  imports = [
   ../../module/laptop.nix
   ../../module/pipewire.nix
   ../../module/disable-nvidia.nix
  ];
}
