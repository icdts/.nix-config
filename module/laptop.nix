{ lib, pkgs, ... }:
let
		trustedNetworks = [
			"[REDACTED]"
			"stuffisgool"
		];
		ssidCheck = lib.concatStringsSep " || " (map (ssid: ''[ "$SSID" == "${ssid}" ]'') trustedNetworks);
	in
	{
		services.logind = {
			settings.Login = {
				HandleLidSwitch="suspend-then-hibernate";
				HandleLidSwitchExternalPower = "suspend-then-hibernate";
				HandleLidSwitchDocked = "suspend-then-hibernate";
				HibernateDelaySec="20min";
				IdleAction = "suspend-then-hibernate";
				IdleActionSec = "30min";
			};
		};

		services.avahi.enable = lib.mkForce false;
		networking.networkmanager.dispatcherScripts = [{
			source = pkgs.writeShellScript "avahi-dispatcher.sh" ''
				IFACE="$1"
				ACTION="$2"
				SSID="$CONNECTION_ID"

				# Use a variable for the service name
				SERVICE="avahi-daemon.service"

				update_avahi_status() {
					local is_trusted=false
					if [[ "$IFACE" =~ ^(eth|en) ]] || ([[ "$IFACE" =~ ^wlan ]] && { ${ssidCheck}; }); then
						is_trusted=true
					fi

					if [ "$is_trusted" = true ]; then
						echo "Trusted network detected, starting $SERVICE"
						${pkgs.systemd}/bin/systemctl start "$SERVICE"
					else
						echo "Untrusted network, ensuring $SERVICE is stopped"
						if ${pkgs.systemd}/bin/systemctl is-active --quiet "$SERVICE"; then
							${pkgs.systemd}/bin/systemctl stop "$SERVICE"
						fi
					fi
				}

				case "$ACTION" in
					"up")
						update_avahi_status
						;;
					"down")
						echo "Interface down, ensuring $SERVICE is stopped"
						if ${pkgs.systemd}/bin/systemctl is-active --quiet "$SERVICE"; then
							${pkgs.systemd}/bin/systemctl stop "$SERVICE"
						fi
						;;
				esac
			'';
		}];
	}
