{config,lib,...}:
  with lib; let
    cfg = config.custom.desktop.hyprland;
  in {
    options.custom.desktop.hyprland.enable = mkEnableOption "hyprland config";

    config = mkIf cfg.enable {

      programs.zsh = {
        initExtra = ''
        case $(tty) in
          (/dev/tty1) if uwsm check may-start; then
            exec systemd-cat -t uwsm_start uwsm start default
          fi
        esac
        '';
      };

      wayland.windowManager.hyprland = {
      	enable = true;
	systemd.enable = false;
	settings = {
		"$mod" = "MOD3";
		"$menu" = "wofi --show drun";
		"$fileManager" = "ghostty sh -c nvim";
		"$terminal" = "ghostty";

		input = {
			kb_options = "caps:hyper";
		};

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
		  gaps_in = 0;
		  gaps_out = 0;
		  border_size = 0;
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

		dwindle = {
		  # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
		  pseudotile = true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
		  preserve_split = true; # you probably want this
		  force_split = 2;
		};

		master = {
		  smart_resizing = false;
		};

		gestures = {
		  workspace_swipe = false;
		};

		workspace = [
		  "1, monitor:DP-1, on-created-empty:ghostty, persistant:true, default:true"
		  "2, monitor:DP-2, on-created-empty:firefox, persistant:true"
		];

		windowrulev2 = [ 
		  "suppressevent maximize, class:.*" 
		  "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
			"float, title:Volume Control"
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
		  ", Print, exec, grimblast copy area"
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
	};
      };
    };
  }
