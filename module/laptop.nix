{ lib, pkgs, ... }:
let
		trustedNetworks = [
			"[REDACTED]"
			"stuffisgool"
		];
		ssidCheck = lib.concatStringsSep " || " (map (ssid: ''[ "$SSID" == "${ssid}" ]'') trustedNetworks);
	in
	{
		services.power-profiles-daemon.enable = false;
		powerManagement.enable = true;
		services.tlp = {
			enable = true;
		};

		services.auto-cpufreq.enable = true;
		services.auto-cpufreq.settings = {
			battery = {
				 governor = "powersave";
				 turbo = "never";
			};
			charger = {
				 governor = "performance";
				 turbo = "auto";
			};
		};

		services.logind = {
			settings.Login = {
				HandleLidSwitch="suspend-then-hibernate";
				HandleLidSwitchExternalPower = "suspend-then-hibernate";
				HibernateDelaySec="20min";
			};
		};

		services.avahi.enable = lib.mkForce false;
		networking.networkmanager.dispatcherScripts = [{
			source = pkgs.writeShellScript "avahi-dispatcher.sh" ''
				IFACE="$1"
				ACTION="$2"
				SSID="$CONNECTION_ID"

				update_avahi_status() {
					local is_trusted=false
					if [[ "$IFACE" =~ ^eth ]] || [[ "$IFACE" =~ ^en ]]; then
						is_trusted=true
					elif [[ "$IFACE" =~ ^wlan ]] && { ${ssidCheck}; }; then
						is_trusted=true
					fi

					if [ "$is_trusted" = true ]; then
						${pkgs.systemd}/bin/systemctl start avahi-daemon.service
					else
						${pkgs.systemd}/bin/systemctl stop avahi-daemon.service
					fi
				}

				case "$ACTION" in
					"up")
						update_avahi_status
						;;
					"down")
						${pkgs.systemd}/bin/systemctl stop avahi-daemon.service
						;;
				esac
			'';
		}];
	}
