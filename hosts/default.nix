{
  rnl = {
    system = "x86_64-linux";
    profile = {
      type = "desktop";
      graphical = true;
      hostname = "rnl";
      useJovian = false;
    };

    hardware = ./rnl/hardware-configuration.nix;
    configuration = ./rnl/configuration.nix;
  };

  living-room = {
    system = "x86_64-linux";
    profile = {
      type = "desktop";
      graphical = true;
      hostname = "living-room";
      useJovian = true;
    };

    hardware = ./living-room/hardware-configuration.nix;
    configuration = ./living-room/configuration.nix;
  };

  voron24 = {
    system = "aarch64-linux";
    profile = {
      type = "server";
      graphical = false;
      hostname = "voron24";
      useJovian = false;
    };
    hardware = ./voron24/hardware-configuration.nix;
    configuration = ./voron24/configuration.nix;
  };

  home-assistant = {
    system = "aarch64-linux";
    profile = {
      type = "server";
      graphical = false;
      hostname = "home-assistant";
      useJovian = false;
    };
    hardware = ./home-assistant/hardware-configuration.nix;
    configuration = ./home-assistant/configuration.nix;
  };
}
