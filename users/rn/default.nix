{
  config,
  pkgs,
  inputs,
  ...
}:
{
  sops.secrets.user-rn-password.neededForUsers = true;

  users.users.rn = {
    hashedPasswordFile = config.sops.secrets.user-rn-password.path;
    isNormalUser = true;
    description = "robb";
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "input"
      "adbusers"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfUC4pqST2CQ/oEEW4hNsA4fdTrHysipHuU01hvBehN rn@arch-rn"
    ];
  };

  home-manager.users.rn = {
    imports = [
      inputs.catppuccin.homeModules.catppuccin
      ../../module/home-manager
    ];
  };
}
