{ pkgs, config, lib, ... }:
{
  boot = {
    blacklistedKernelModules = [ "nouveau" ];
  };

  hardware.graphics.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = false;
    modesetting.enable = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      amdgpuBusId = "PCI:197:0:0"; #c5:00.0
      nvidiaBusId = "PCI:198:0:0"; #c4:00.0
    };
    powerManagement = {
      enable = false;
      finegrained = true;
    };

    dynamicBoost.enable = lib.mkDefault true;
  };
}
