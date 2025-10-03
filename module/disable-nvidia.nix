{ pkgs, config, lib, ... }:
{
  config.boot.extraModprobeConfig = lib.mkDefault ''
    blacklist nouveau
    options nouveau modeset=0
  '';

  config.services.udev.extraRules = lib.mkDefault ''
    ACTION=="add", SUBSYSTEM="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{power/control}="auto", ATTR{remove}="1"
    ACTION=="add", SUBSYSTEM="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{power/control}="auto", ATTR{remove}="1"
    ACTION=="add", SUBSYSTEM="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto", ATTR{remove}="1"
    ACTION=="add", SUBSYSTEM="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{power/control}="auto", ATTR{remove}="1"
  '';
  config.boot.blacklistedKernelModules = lib.mkDefault [ "nouveau" "nvidia" ];
}
