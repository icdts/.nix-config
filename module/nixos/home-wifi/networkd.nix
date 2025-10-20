{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf (config.custom.home-wifi.networkd.enable && config.networking.wireless.iwd.enable) {
      sops.templates."home-wifi.ini" = {
        content = ''
          #${config.sops.placeholder."home-wifi.ssid"}
          [Security]
          Passphrase="${config.sops.placeholder."home-wifi.psk"}"

          [Settings]
          AutoConnect=true
        '';
        mode = "0600";
      };

      system.activationScripts."customHomeWifiCreateIwdLink" = {
        text = ''
          #!${pkgs.runtimeShell}
          set -e


          SOURCE_FILE="${config.sops.templates."home-wifi.ini".path}"
          NAME_FILE="${config.sops.secrets."home-wifi.ssid".path}"
          DESTINATION_DIR="/var/lib/iwd"

          if [ ! -f "$SOURCE_FILE" ] || [ ! -f "$NAME_FILE" ]; then
            echo "Error: custom.home-wifi: sops-nix failed to create secret source files." >&2
            exit 1
          fi

          DYNAMIC_NAME="$(cat "$NAME_FILE")"
          if [ -z "$DYNAMIC_NAME" ]; then
            echo "Error: custom.home-wifi: Secret '${config.sops.secrets."home-wifi.ssid".path}' is empty." >&2
            exit 1
          fi

          DESTINATION_FILE="$DESTINATION_DIR/$DYNAMIC_NAME"

          mkdir -p "$DESTINATION_DIR"
          ln -sf "$SOURCE_FILE" "$DESTINATION_FILE"

          echo "custom.home-wifi: Successfully linked my-app secret to $DESTINATION_FILE"
        '';

        deps = [ "setupSecrets" ];
      };
    })
    {
      warnings =
        lib.optionals (config.custom.home-wifi.networkd.enable && !config.networking.wireless.iwd.enable)
          [
            "custom.home-wifi: networkd backend selected, but iwd is not enabled."
          ];
    }
  ];
}
