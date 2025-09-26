{
  rnl = {
    system = "x86_64-linux";
    profile = {
      type = "desktop";
      graphical = true;
      hostname = "rnl";
    };

    hardware = ./rnl/hardware-configuration.nix;
    configuration = ./rnl/configuration.nix;
  };

  voron24 = {
    system = "aarch64-linux";
    profile = {
      type = "server";
      graphical = false;
      hostname = "voron24";
    };
    hardware = ./voron24/hardware-configuration.nix;
    configuration = ./voron24/configuration.nix;
  };
}
