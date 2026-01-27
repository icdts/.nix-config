{ ... }:
{
  imports = [
    ./generate-cert
    ./home-wifi
    ./enable-nvidia-prime.nix
    ./pipewire.nix
    ./steam.nix
    ./siyuan.nix
  ];
}
