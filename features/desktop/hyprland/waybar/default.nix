{ config, lib, pkgs, ... }:
with lib; let
  cfg = config.custom.desktop.hyprland.waybar;
  waybar-battery-limit-pkg = pkgs.writeShellScriptBin "waybar-battery-limit"
    (builtins.readFile ./waybar-battery-limit.sh);

  palette = (lib.importJSON "${config.catppuccin.sources.palette}/palette.json").${config.catppuccin.flavor}.colors;

  mkWaybarColors = palette: lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: color: "@define-color ${name} ${color.hex};") palette
  );

in
{
  options.custom.desktop.hyprland.waybar.enable = mkEnableOption "waybar";

  config = mkIf cfg.enable {
    systemd.user.targets."graphical-session".unitConfig.wants = [ "waybar.service" ];
    home.file = {
      ".config/systemd/user/hyprland-session.target.wants/waybar.service" = {
        source = "${config.programs.waybar.package}/share/systemd/user/waybar.service";
      };
    };
    programs.waybar = {
      enable = true;
      systemd.enable = true;

      style = ''
        ${mkWaybarColors palette}

        * {
            border: none;
            border-radius: 0;
            font-family: "FiraMono";
            font-size: 13px;
            min-height: 0;
        }

        window#waybar {
            background: transparent;
            color: @text;
        }

        #window {
            font-weight: bold;
            font-family: "FiraMono";
        }

        #workspaces button {
            padding: 0 5px;
            background: transparent;
            color: @text;
            border-top: 2px solid transparent;
        }

        #workspaces button.focused {
            color: @red;
            border-top: 2px solid @red;
        }

        #mode {
            background: @surface0;
            border-bottom: 1px solid @crust;
        }

        #clock, #battery, #cpu, #memory, #network, #pulseaudio, #custom-spotify, #tray, #mode {
            padding: 0 10px;
            margin: 0 10px;
        }

        #clock {
            font-weight: bold;
        }

        #battery {
        }

        #battery icon {
            color: @red;
        }

        #battery.charging {
        }

        @keyframes blink {
            to {
                background-color: @base;
                color: black;
            }
        }

        #battery.warning:not(.charging) {
            color: @text;
            animation-name: blink;
            animation-duration: 0.5s;
            animation-timing-function: linear;
            animation-iteration-count: infinite;
            animation-direction: alternate;
        }

        #cpu {
        }

        #memory {
        }

        #network {
        }

        #network.disconnected {
            background: @red;
        }

        #pulseaudio {
        }

        #pulseaudio.muted {
        }

        #custom-spotify {
            color: @green;
        }

        #tray {
        }
      '';
      settings = {
        "main" = {
          layer = "top";
          position = "top";
          height = 40;
          modules-left = [ "hyprland/workspaces" "hyprland/submap" "keyboard-state" "pulseaudio" "custom/battery-limit" ];
          modules-center = [ "hyprland/window" ];
          modules-right = [ "cpu" "memory" "tray" "clock" ];
          "hyprland/workspaces" = {
            format = "{name}";
            "format-icons" = {
              "1:web" = "";
              "2:code" = "";
              "3:term" = "";
              "4:work" = "";
              "5:music" = "";
              "6:docs" = "";
              urgent = "";
              focused = "";
              default = "";
            };
          };
          "hyprland/window" = {
            "separate-outputs" = true;
            format = "{title}";
          };
          "keyboard-state" = {
            numlock = true;
            capslock = true;
            format = "{name} {icon} ";
            "format-icons" = {
              locked = "";
              unlocked = "";
            };
          };
          tray = {
            spacing = 10;
          };
          clock = {
            interval = 1;
            format = "{:%Y-%m-%d %I:%M:%S}";
            "tooltip-format" = "<tt><small>{calendar}</small></tt>";
            calendar = {
              mode = "year";
              "mode-mon-col" = 3;
              "weeks-pos" = "";
              "on-scroll" = 1;
              "on-click-right" = "mode";
              format = {
                months = "<span color='#ffead3'><b>{}</b></span>";
                days = "<span color='#ecc6d9'><b>{}</b></span>";
                weeks = "<span color='#99ffdd'><b>W{}</b></span>";
                weekdays = "<span color='#ffcc66'><b>{}</b></span>";
                today = "<span color='#ff6699'><b><u>{}</u></b></span>";
              };
            };
            actions = {
              "on-click-right" = "mode";
              "on-scroll-up" = "shift_up";
              "on-scroll-down" = "shift_down";
            };
          };
          cpu = {
            format = "{usage}% ";
          };
          memory = {
            format = "{}% ";
          };
          network = {
            "format-wifi" = "{essid} ({signalStrength}%) ";
            "format-ethernet" = "{ifname}: {ipaddr}/{cidr} ";
            "format-disconnected" = "Disconnected ⚠";
          };
          pulseaudio = {
            format = "{icon}  {volume}%";
            "format-bluetooth" = "{icon}  {volume}%";
            "format-muted" = "";
            "format-icons" = {
              headphones = "";
              handsfree = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = [ "" "" ];
            };
            "on-click" = "pavucontrol";
          };
          "custom/battery-limit" = {
            format = "{}";
            "return-type" = "json";
            interval = 300;
            exec = "waybar-battery-limit";
            "on-click" = "waybar-battery-limit toggle && pkill -SIGRTMIN+8 waybar";
            signal = 8;
          };
        };
      };
    };

    home.packages = [ waybar-battery-limit-pkg ];
  };
}
