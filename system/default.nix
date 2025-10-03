{ inputs
,
}:
system:
{ profile
, host-configuration
, hardware-configuration
,
}:
inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs profile system; };

  modules = [
    inputs.sops-nix.nixosModules.sops

    ./base.nix
    hardware-configuration
    host-configuration

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "home-manager.bk";
      home-manager.extraSpecialArgs = { inherit inputs profile; };
    }
    inputs.catppuccin.nixosModules.catppuccin
  ];
}
