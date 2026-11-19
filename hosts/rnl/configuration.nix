{ config, pkgs, ... }:
{
  networking.hostName = "rnl";

  hardware.graphics = {
    enable = true;
  };

  boot = {
    kernelParams = [
      "initcall_blacklist=acpi_cpufreq_init"
      "amd_pstate=passive"
      "resume_offset=157665280"
    ];
    kernelModules = [
      "amdgpu"
      "zenpower"
      "asus_wmi"
    ];
    extraModulePackages = [ config.boot.kernelPackages.zenpower ];
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
  swapDevices = [ { device = "/swapfile"; } ];

  environment.systemPackages = with pkgs; [
    orca-slicer
    android-tools
    obsidian
  ];

  services.fstrim.enable = true; # ssd health

  hardware.bluetooth.enable = true; # enables support for Bluetooth

  programs.niri.enable = true;
  home-manager.users.rn = {
    custom.desktop.niri.enable = true;
    wayland.windowManager.niri.settings.debug.render-drm-device = "/dev/dri/by-path/pci-0000:c5:00.0-render";
  };
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
        user = "greeter";
      };
    };
  };
  services.upower.enable = true;

  services.asusd.enable = true;
  powerManagement.enable = true;
  services.power-profiles-daemon.enable = true;
  services.auto-cpufreq.enable = false;
  services.tlp.enable = false;
  services.logind = {
    settings.Login = {
      HandleLidSwitch = "suspend-then-hibernate";
      HandleLidSwitchExternalPower = "suspend-then-hibernate";
      HandleLidSwitchDocked = "suspend-then-hibernate";
      HibernateDelaySec = "20min";
      IdleAction = "suspend-then-hibernate";
      IdleActionSec = "30min";
    };
  };

  nixpkgs.config.allowUnfree = true;

  custom.generate-cert.enable = true;
  custom.nvidia-prime.enable = true;
  custom.pipewire.enable = true;
  custom.steam.enable = true;

  imports = [];
}
