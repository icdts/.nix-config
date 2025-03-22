{ pkgs, config, lib, ... }: 
  {
		boot = {
			blacklistedKernelModules = [ "nouveau" ];
		};

		services.xserver.videoDrivers = lib.mkDefault [ "nvidia" ];
		hardware.nvidia.open = false;
    amdgpu.initrd.enable = true;

    hardware.nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
			prime = {
				offload = {
					enable = true;
					enableOffloadCmd = true;
				};
        amdgpuBusId = "PCI:197:0:0"; #c5:00.0
        nvidiaBusId = "PCI:198:0:0"; #c4:00.0
			};
			powerManagement = {
        enable = lib.mkDefault true;
        finegrained = lib.mkDefault true;
      };

      dynamicBoost.enable = lib.mkDefault true;  
		};
	}
