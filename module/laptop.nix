{ lib, pkgs, ... }:
let
		trustedNetworks = [
			"[REDACTED]"
			"stuffisgool"
		];
		ssidCheck = lib.concatStringsSep " || " (map (ssid: ''[ "$SSID" == "${ssid}" ]'') trustedNetworks);
	in
	{
		powerManagement.enable = true;
		services.power-profiles-daemon.enable = true;

		services.tlp = {
			enable = false;

			settings = {
				CPU_SCALING_GOVERNOR_ON_AC = "performance";
				CPU_BOOST_ON_AC = "on";

				CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
				CPU_BOOST_ON_BAT = "off";

				WIFI_PWR_ON_AC = "off";
				WIFI_PWR_ON_BAT = "off";

				STOP_CHARGE_THRESH_BAT0 = 80;
				RUNTIME_PM_DRIVER_BLACKLIST = "nouveau";

				PCIE_ASPM_ON_AC = "performance";
				PCIE_ASPM_ON_BAT = "powersave";
			};
		};

		services.auto-cpufreq.enable = false;

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
