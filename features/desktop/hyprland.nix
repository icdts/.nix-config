{config,lib,...}:
  with lib; let
    cfg = config.custom.desktop.hyprland;
  in {
    options.custom.desktop.hyprland.enable = mkEnableOption "hyprland config";

    config = mkIf cfg.enable {
			services.mako.enable = true;

      wayland.windowManager.hyprland = {
      	enable = true;
				systemd.enable = false;
				settings = {
					"$mod" = "SUPER";
					"$menu" = "wofi --show drun";
					"$fileManager" = "ghostty sh -c nvim";
					"$terminal" = "ghostty";

					env = [
						"XCURSOR_SIZE,24"
						"QT_QPA_PLATFORMTHEME,qt6ct"
						"AQ_DRM_DEVICES,/dev/dri/card1"
						"NIXOS_OZONE_WL,1"
					];

					exec-once = [
						"waybar"
						"mako"
						"/usr/lib/polkit-kde-authentication-agent-1"
						"nm-applet"
					];

					general = {
						gaps_in = 2;
						gaps_out = 1;
						border_size = 0;
						resize_on_border = true;
						layout = "master";
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
					};

					# dwindle = {
					# 	# See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
					# 	pseudotile = true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
					# 	preserve_split = true; # you probably want this
					# 	force_split = 2;
					# };
					
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
						"$mod, P, pseudo, # dwindle"
						"$mod, J, togglesplit, # dwindle"

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
						"DP-3, 1920x1080@60, 960x0, 1"
						"eDP-1, 2880x1800@60, 0x1080, 1"
						"DP-2, 3840x2160@144, 2880x0, 1"
					];
				};
			};
    };
  }
