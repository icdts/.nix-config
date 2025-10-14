{ config, pkgs, inputs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  networking.hostName = "vault";

  services.vault = {
    enable = true;
    address = "0.0.0.0:8200";
    storageBackend = "file";
  };

  networking.firewall.allowedTCPPorts = [ 8200 ];

  environment.systemPackages = with pkgs; [ vault ];
  environment.sessionVariables = {
    VAULT_ADDR = "http://vault.local:8200";
  };

  imports = [
    (inputs.nixpkgs + "/nixos/modules/installer/sd-card/sd-image-aarch64.nix")
  ];
  sdImage.compressImage = false;
}
