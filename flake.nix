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
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      home-manager,
      nixpkgs,
      catppuccin,
      sops-nix,
      ...
    }:
    let
      nixos-system = import ./system {
        inherit inputs;
      };
      nixosHosts = import ./hosts;
    in
    {
      nixosConfigurations = nixpkgs.lib.mapAttrs (
        name: host:
        nixos-system host.system {
          inherit (host) profile;
          hardware-configuration = host.hardware;
          host-configuration = host.configuration;
        }
      ) nixosHosts;
    };
}
