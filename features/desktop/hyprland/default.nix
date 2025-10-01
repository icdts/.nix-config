{config,lib,pkgs,inputs,...}:
  with lib; let
    cfg = config.custom.desktop.hyprland;
		palette = (lib.importJSON "${config.catppuccin.sources.palette}/palette.json").${config.catppuccin.flavor}.colors;
		stripHash = hex: lib.substring 1 6 hex;
		toggle-mirror = pkgs.writeShellScriptBin "toggle-mirror"
     (builtins.readFile ./toggle-mirror.sh);
  in {
    imports = [
			./waybar
		];
    options.custom.desktop.hyprland.enable = mkEnableOption "hyprland config";

    config = mkIf cfg.enable {
			custom.desktop.hyprland.waybar.enable	= true;
			services.mako.enable = true;
			systemd.user.targets."graphical-session".unitConfig.wants = [ "mako.service" "waybar.service" ];

			home.file = {
				".config/systemd/user/graphical-session.target.wants/mako.service" = {
					source = "${config.services.mako.package}/share/systemd/user/mako.service";
				};
			};

			
			home.packages = [ toggle-mirror ];
      wayland.windowManager.hyprland = {
      	enable = true;
				systemd.enable = true;
				systemd.variables = ["--all"];
				package = null;
				settings = {
					"$mod" = "SUPER";
					"$menu" = "wofi --show drun";
					"$fileManager" = "ghostty sh -c nvim";
					"$terminal" = "ghostty";

					env = [
						"XCURSOR_SIZE,24"
						"QT_QPA_PLATFORMTHEME,qt6ct"
						"AQ_DRM_DEVICES,/dev/dri/card1"
						"WGPU_DRM_DEVICES,/dev/dri/card1"
						"NIXOS_OZONE_WL,1"
						"GDK_BACKEND,wayland"
						"QT_QPA_PLATFORM,wayland;xcb"
					];

					exec-once = [
						# "systemctl --user start waybar.service"
						# "mako"
						"/usr/lib/polkit-kde-authentication-agent-1"
						"nm-applet"
					];

					general = {
						gaps_in = 2;
						gaps_out = 1;
						border_size = 2;
						resize_on_border = true;
						layout = "master";
						# col.active_border = "rgb(89b4fa)";
						# col.inactive_border = "rgb(313244)";
						"col.active_border" = "rgb(${stripHash palette.blue.hex})";
						"col.inactive_border" = "rgb(${stripHash palette.surface0.hex})";
					};

					decoration = {
						rounding = 0;
						blur = {
							enabled = false;
						};
					};

					animations = {
						enabled = false;
					};

					input = {
						kb_options = "caps:escape";
						touchpad = {
							natural_scroll = false;
							disable_while_typing = true;
						};
					};
					
					master = {
						mfact = 0.80;
					};

					windowrulev2 = [ 
						"suppressevent maximize, class:.*" 
						"nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
					];

					# Laptop multimedia keys for volume and LCD brightness
					bindel = [
						",XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
						",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
						",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
						",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
						",XF86MonBrightnessUp, exec, brightnessctl s 5%+"
						"SHIFT, XF86MonBrightnessUp, exec, brightnessctl s 1%+"
						",XF86MonBrightnessDown, exec, brightnessctl s 5%-"
						"SHIFT, XF86MonBrightnessDown, exec, brightnessctl s 1%-"
						# ",XF86KbdLightOnOff, exec, "
					];

					bindl = [
						", XF86AudioNext, exec, playerctl next"
						", XF86AudioPause, exec, playerctl play-pause"
						", XF86AudioPlay, exec, playerctl play-pause"
						", XF86AudioPrev, exec, playerctl previous"
					];

					bind = [
						", Print, exec, grim -g \"$(slurp -d)\" - | wl-copy"
						"$mod, S, togglespecialworkspace, magic"
						"$mod SHIFT, S, movetoworkspace, special:magic"
						"$mod, mouse_down, workspace, e+1"
						"$mod, mouse_up, workspace, e-1"

						"$mod, Q, exec, $terminal"
						"$mod, C, killactive,"
						"$mod, M, exit,"
						"$mod, E, exec, $fileManager"
						"$mod, V, togglefloating,"
						"$mod, R, exec, $menu"
						"$mod, F, fullscreen"
						"$mod, P, exec, toggle-mirror"

						"$mod, h, movefocus, l"
						"$mod, j, movefocus, d"
						"$mod, k, movefocus, u"
						"$mod, l, movefocus, r"

						"$mod SHIFT, H, movewindow, l"
						"$mod SHIFT, L, movewindow, r"
						"$mod SHIFT, K, movewindow, u"
						"$mod SHIFT, J, movewindow, d"
						"$mod SHIFT, LEFT, movewindow, l"
						"$mod SHIFT, RIGHT, movewindow, r"
						"$mod SHIFT, UP, movewindow, u"
						"$mod SHIFT, DOWN, movewindow, d"

						"$mod CONTROL, h, movecurrentworkspacetomonitor, l"
						"$mod CONTROL, l, movecurrentworkspacetomonitor, r"
						"$mod CONTROL, k, movecurrentworkspacetomonitor, u"
						"$mod CONTROL, j, movecurrentworkspacetomonitor, d"
						"$mod CONTROL, LEFT, movecurrentworkspacetomonitor, l"
						"$mod CONTROL, RIGHT, movecurrentworkspacetomonitor, r"
						"$mod CONTROL, UP, movecurrentworkspacetomonitor, u"
						"$mod CONTROL, DOWN, movecurrentworkspacetomonitor, d"

						"$mod, Tab, layoutmsg, cyclenext,"
						"$mod SHIFT, Tab, layoutmsg, cycleprev,"
						"$mod CONTROL, l, layoutmsg, setmfact 0.05"
						"$mod CONTROL, h, layoutmsg, setmfact -0.05"
						"$mod CONTROL, RIGHT, layoutmsg, setmfact 0.05"
						"$mod CONTROL, LEFT, layoutmsg, setmfact -0.05"
						"$mod, Return, layoutmsg, swapwithmaster"
					] ++ (
						# workspaces
						# binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
						builtins.concatLists (builtins.genList (i:
							let ws = i + 1;
							in [
								"$mod, code:1${toString i}, workspace, ${toString ws}"
								"$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
							]
						) 9)
					);

					monitor = [
						"desc:AOC 2460G4 F61G4BA005375, 1920x1080@60, 960x0, 1"
						"desc:Samsung Display Corp. ATNA33AA08-0, 2880x1800@60, 0x1080, 1"
						"desc:GIGA-BYTE TECHNOLOGY CO. LTD. Gigabyte M32U 22181B001184, 3840x2160@144, 2880x0, 1"
					];
				};
			};
    };
  }
