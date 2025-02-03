{pkgs,...} : {
  initialHashedPassword = "$y$j9T$GI3U03VC.icM2wa75ejk1/$bEfz3KYNQ7l9e./ha38TmgBVbZoFSae9Zn8ELA4e9v6";
  isNormalUser = true;
  description = "robb";
  extraGroups = [ "wheel" "networkmanager" "audio" "video" "input" ];
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfUC4pqST2CQ/oEEW4hNsA4fdTrHysipHuU01hvBehN rn@arch-rn"
  ];
}
