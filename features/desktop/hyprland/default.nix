{ config, lib, pkgs, inputs, ... }:
with lib;
let
  cfg = config.custom.desktop.hyprland;
  palette = (lib.importJSON "${config.catppuccin.sources.palette}/palette.json").${config.catppuccin.flavor}.colors;
  stripHash = hex: lib.substring 1 6 hex;

  toggleMirrorFactory = import ./toggle-mirror.nix;

  monitorDefinitions = {
    laptop = {
      description = "desc:Samsung Display Corp. ATNA33AA08-0";
      resolution = "2880x1800@60";
      position = "0x1080";
      scale = "1";
      workspace = 1;
      primary = true;
    };
    aoc = {
      description = "desc:AOC 2460G4 F61G4BA005375";
      resolution = "1920x1080@60";
      position = "960x0";
      scale = "1";
      workspace = 2;
      primary = false;
    };
    gigabyte = {
      description = "desc:GIGA-BYTE TECHNOLOGY CO. LTD. Gigabyte M32U 22181B001184";
      resolution = "3840x2160@144";
      position = "2880x0";
      scale = "1";
      workspace = 3;
      primary = false;
    };
  };

  toggle-mirror-pkg = toggleMirrorFactory {
    inherit pkgs lib;
    monitorDefinitions = monitorDefinitions;
  };

  hyprlandMonitorConfig =
    lib.mapAttrsToList (name: value:
      "${value.description}, ${value.resolution}, ${value.position}, ${value.scale}")
    monitorDefinitions;

  hyprlandWorkspaceConfig =
    lib.mapAttrsToList (name: value:
      if value.workspace != null
      then "${toString value.workspace}, monitor:${value.description}"
      else "") (lib.filterAttrs (n: v: v.workspace != null) monitorDefinitions);

in {
  imports = [ ./waybar ];
  options.custom.desktop.hyprland.enable = mkEnableOption "hyprland config";

  config = mkIf cfg.enable {
    custom.desktop.hyprland.waybar.enable = true;
    services.mako.enable = true;
    home.packages = [ toggle-mirror-pkg ];

    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        monitor = hyprlandMonitorConfig;
        workspace = hyprlandWorkspaceConfig;

        "$mod" = "SUPER";
        "$menu" = "wofi --show drun";
        "$fileManager" = "ghostty -e nvim ~/";
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
          "/usr/lib/polkit-kde-authentication-agent-1"
          "nm-applet"
          "google-chrome-stable --window-name=\"chrome-workspace2\" https://messages.google.com/ https://mail.google.com/ https://unifi.ui.com/consoles"
          "google-chrome-stable --window-name=\"chrome-dgg\" --app=https://www.destiny.gg/embed/chat"
          "google-chrome-stable --window-name=\"chrome-workspace3\" --new-window"
          "ghostty --title=ghostty-workspace3"
          "hyprctl --batch \"dispatch workspace 1; dispatch workspace 2; dispatch workspace 3;"
        ];
        general = {
          gaps_in = 2;
          gaps_out = 1;
          border_size = 2;
          resize_on_border = true;
          layout = "master";
          "col.active_border" = "rgb(${stripHash palette.blue.hex})";
          "col.inactive_border" = "rgb(${stripHash palette.surface0.hex})";
        };
        decoration = {
          rounding = 0;
          blur.enabled = false;
        };
        animations.enabled = false;
        input = {
          kb_options = "caps:escape";
          touchpad = {
            natural_scroll = false;
            disable_while_typing = true;
          };
        };
        master = { mfact = 0.80; };
				windowrulev2 = [
          "suppressevent maximize, class:.*"
          "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
          "workspace 3, class:com.mitchellh.ghostty, title:ghostty-workspace3"
          "workspace 2, class:google-chrome, initialTitle:chrome-workspace2"
          "workspace 2, class:chrome-www.destiny.gg__embed_chat-Default"
          "workspace 3, class:google-chrome, title:chrome-workspace3"
        ];
        bindel = [
          ",XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
          ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          ",XF86MonBrightnessUp, exec, brightnessctl s 5%+"
          "SHIFT, XF86MonBrightnessUp, exec, brightnessctl s 1%+"
          ",XF86MonBrightnessDown, exec, brightnessctl s 5%-"
          "SHIFT, XF86MonBrightnessDown, exec, brightnessctl s 1%-"
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
          builtins.concatLists (builtins.genList (i:
            let ws = i + 1;
            in [
              "$mod, code:1${toString i}, workspace, ${toString ws}"
              "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
            ])
          9));
      };
    };
  };
}
