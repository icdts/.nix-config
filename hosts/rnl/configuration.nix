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

  hardware.amdgpu.initrd.enable = true;
	hardware.graphics = {
		enable = true;
		extraPackages = with pkgs; [
			amdvlk
		];
		extraPackages32 = with pkgs; [
			driversi686Linux.amdvlk
		];
	};

  boot = {
    kernelParams = [ "initcall_blacklist=acpi_cpufreq_init" "amd_pstate=passive"];
    kernelModules = [ "amdgpu" "zenpower" "asus_wmi" ];
    blacklistedKernelModules = [ "k10temp" ];
    extraModulePackages = [ config.boot.kernelPackages.zenpower ];
  };

  environment.systemPackages = with pkgs; [
    networkmanagerapplet
  ];
  programs.nm-applet.enable = true;
	programs.adb.enable = true;

  services.asusd.enable = true;
  services.fstrim.enable = true; #ssd health

  hardware.bluetooth.enable = true; # enables support for Bluetooth

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };
	services.blueman.enable = true;


  imports = [
   ../../module/laptop.nix
   ../../module/pipewire.nix
   ../../module/enable-nvidia-prime.nix
   #../../module/disable-nvidia.nix
  ];
}
