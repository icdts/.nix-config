{
  description = "my nixos config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
  };

  outputs = inputs @ {
    self,
    home-manager,
    nixpkgs,
    catppuccin,
    ...
  }: let
    nixos-system = import ./system/nixos.nix {
      inherit inputs;
      username = "rn"; 
      userconfig = import ./users/rn.nix;
    };
  in {
    nixosConfigurations = {
      rnl = nixos-system "x86_64-linux" {
        host-configuration = import ./hosts/rnl/configuration.nix;
        hardware-configuration = import ./hosts/rnl/hardware-configuration.nix;
      };
    };
  };
}
