{pkgs, ...}: {
  # add home-manager user settings here
  home.packages = with pkgs; [git neovim];
  home.stateVersion = "24.05";
  home.backupFileExtension = "home-manager.bk"
}
