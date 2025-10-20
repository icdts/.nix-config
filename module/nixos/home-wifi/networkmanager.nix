{ config, lib, ... }:
{
  config =
    lib.mkIf (config.custom.home-wifi.networkmanager.enable && config.networking.wireless.iwd.enable)
      {
        sops.templates."home-wifi.env" = {
          content = ''
            HOME_SSID="${config.sops.placeholder."home-wifi.ssid"}"
            HOME_PSK="${config.sops.placeholder."home-wifi.psk"}"
          '';
          mode = "0600";
        };

        networking = {
          networkmanager = {
            ensureProfiles = {
              environmentFiles = [
                config.sops.templates."home-wifi.env".path
              ];
              profiles = {
                "home-wifi" = {
                  connection = {
                    id = "home-wifi";
                    type = "wifi";
                    interface-name = "wlp195s0";
                    autoconnect = true;
                    autoconnect-proirity = 50;
                  };
                  wifi.ssid = "$HOME_SSID";
                  wifi-security = {
                    auth-alg = "open";
                    key-mgmt = "wpa-psk";
                    psk = "$HOME_PSK";
                  };
                };
              };
            };
          };
        };
      };
}
