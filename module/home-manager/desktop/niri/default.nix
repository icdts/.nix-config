{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.custom.desktop.niri;
  palette =
    (lib.importJSON "${config.catppuccin.sources.palette}/palette.json")
    .${config.catppuccin.flavor}.colors;

  defaultNoctaliaWallpaper = "${pkgs.noctalia}/share/noctalia/assets/noctalia-wallpaper.png";

  starterAnimeWallpapers = [
    {
      name = "02-girl-stars.png";
      src = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/orangci/walls-catppuccin-mocha/master/girl-stars.png";
        sha256 = "6f2b876e4ef4e360d9c9642321d03faf12d14287f21bfc70c36f836e90397752";
      };
    }
    {
      name = "03-coffee-girl.jpg";
      src = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/FrenzyExists/wallpapers/main/Anime/anime-coffee-girl.jpg";
        sha256 = "83deac0d074e096bd0e2eac4c4fea9b0f9c2e0019fb3fe8728352656e0db726c";
      };
    }
    {
      name = "04-cat-head-girl.jpg";
      src = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/dharmx/walls/main/anime/a_cartoon_of_a_girl_with_a_cat_on_her_head.jpg";
        sha256 = "7de1f9ebeab3981f29b72831b72b926a3cf1111fa9a9b9bffdeded2c17df3228";
      };
    }
    {
      name = "05-coder-girl.jpg";
      src = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/FrenzyExists/wallpapers/main/Anime/coder-girl.jpg";
        sha256 = "a8fa3794acc2dd6c6e890378b8d7d7afb6c02870b5786910a0b42e6b339ebdbf";
      };
    }
    {
      name = "06-guitar-room.png";
      src = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/dharmx/walls/main/anime/a_cartoon_of_a_girl_playing_a_guitar_in_a_room_with_many_objects.png";
        sha256 = "aa7a01096a963573aa3c2af8e15a854f8dd6b8e1f8552efd01aeeb805a39d9d8";
      };
    }
  ];

  noctaliaWallpaperPkg = pkgs.writeShellScriptBin "noctalia-wallpaper" ''
    set -euo pipefail

    DEFAULT_WALL="${defaultNoctaliaWallpaper}"
    ANIME_DIR="''${HOME}/Pictures/Wallpapers/anime"
    STATE_DIR="''${XDG_STATE_HOME:-''${HOME}/.local/state}/noctalia"
    STATE_FILE="''${STATE_DIR}/anime-wallpaper-index"
    BANNED_FILE="''${STATE_DIR}/banned-wallpapers.txt"
    ANILIST_SECRET="/run/secrets/anilist-username"
    PATH="${
      pkgs.lib.makeBinPath [
        pkgs.coreutils
        pkgs.curl
        pkgs.jq
        pkgs.gnugrep
        pkgs.gnused
        pkgs.noctalia
      ]
    }:''${PATH}"

    mkdir -p "''${ANIME_DIR}" "''${STATE_DIR}"
    touch "''${BANNED_FILE}"

    is_banned() {
      grep -Fxq "''$1" "''${BANNED_FILE}" 2>/dev/null
    }

    sync_anilist() {
      if [ ! -r "''${ANILIST_SECRET}" ]; then
        echo "noctalia-wallpaper: ''${ANILIST_SECRET} not found or not readable" >&2
        exit 1
      fi

      local username
      username="$(tr -d '[:space:]' < "''${ANILIST_SECRET}")"
      if [ -z "''${username}" ]; then
        echo "noctalia-wallpaper: empty AniList username in ''${ANILIST_SECRET}" >&2
        exit 1
      fi

      echo "Syncing manga list for AniList user ''${username}..."

      local query='
        query ($userName: String) {
          User(name: $userName) {
            favourites {
              manga(perPage: 25) {
                nodes {
                  title { romaji english }
                  characters(role: MAIN, sort: [FAVOURITES_DESC], perPage: 3) {
                    nodes { name { full } gender }
                  }
                }
              }
            }
          }
          MediaListCollection(userName: $userName, type: MANGA, status_in: [CURRENT, COMPLETED, REPEATING]) {
            lists {
              entries {
                score
                media {
                  title { romaji english }
                  characters(role: MAIN, sort: [FAVOURITES_DESC], perPage: 3) {
                    nodes { name { full } gender }
                  }
                }
              }
            }
          }
        }
      '

      local payload response
      payload="$(jq -n --arg q "''${query}" --arg u "''${username}" '{query: $q, variables: {userName: $u}}')"
      response="$(curl -fsSL -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d "''${payload}" https://graphql.anilist.co)"

      # Extract search terms: multi-word female main character names + series titles (preserving order, no A-Z truncation)
      mapfile -t terms < <(
        printf '%s' "''${response}" | jq -r '
          def clean: gsub("[×:]"; " ") | gsub("\\s+"; " ") | sub("^\\s+"; "") | sub("\\s+$"; "");
          [
            (.data.User.favourites.manga.nodes // [])[],
            ((.data.MediaListCollection.lists // [])[].entries // [] | sort_by(-.score)[].media)
          ]
          | map(
              (
                (.characters.nodes // [])
                | map(select(.gender == "Female") | .name.full | select(. != null and (test(" "))))
              ) + [ .title.romaji, .title.english ]
            )
          | flatten
          | map(select(. != null and . != "") | clean)
          | reduce .[] as $item ([]; if index($item) then . else . + [$item] end)
          | .[]
        '
      )

      if [ "''${#terms[@]}" -eq 0 ]; then
        echo "No manga entries found on AniList for ''${username}."
        return 0
      fi

      for term in "''${terms[@]}"; do
        local slug encoded wh_json
        slug="$(printf '%s' "''${term}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
        encoded="$(jq -rn --arg t "''${term}" '$t | @uri')"
        wh_json="$(curl -fsSL "https://wallhaven.cc/api/v1/search?q=''${encoded}&categories=010&purity=100&ratios=landscape&atleast=1920x1080&sorting=favorites&order=desc" 2>/dev/null || true)"
        if [ -z "''${wh_json}" ]; then
          continue
        fi

        mapfile -t urls < <(printf '%s' "''${wh_json}" | jq -r '.data[]? | "\(.id)|\(.path)"')
        local saved=0
        for item in "''${urls[@]}"; do
          local id="''${item%%|*}"
          local url="''${item#*|}"
          local ext="''${url##*.}"
          local dest="''${ANIME_DIR}/anilist-''${slug}-''${id}.''${ext}"
          if is_banned "''${id}" || is_banned "''${dest##*/}"; then
            continue
          fi
          if ! compgen -G "''${ANIME_DIR}/*-''${id}.*" > /dev/null; then
            echo "Downloading ''${term} -> ''${dest##*/}"
            curl -fsSL -o "''${dest}" "''${url}" || rm -f "''${dest}"
            sleep 1
          fi
          saved=$(( saved + 1 ))
          if [ "''${saved}" -ge 3 ]; then
            break
          fi
        done
        sleep 1
      done
    }

    action="''${1:-toggle}"
    if [ "''${action}" = "sync" ]; then
      sync_anilist
      exit 0
    fi

    current="$(noctalia msg wallpaper-get 2>/dev/null || true)"

    if [ "''${action}" = "ban" ]; then
      if [ -z "''${current}" ] || [[ "''${current}" == */noctalia-wallpaper.png ]]; then
        exit 0
      fi
      base="''${current##*/}"
      if ! is_banned "''${base}"; then
        echo "''${base}" >> "''${BANNED_FILE}"
      fi
      if [[ "''${base}" =~ ^anilist-.*-([a-z0-9]+)\.[a-zA-Z0-9]+$ ]]; then
        wh_id="''${BASH_REMATCH[1]}"
        if ! is_banned "''${wh_id}"; then
          echo "''${wh_id}" >> "''${BANNED_FILE}"
        fi
        rm -f "''${ANIME_DIR}"/*-"''${wh_id}".*
      fi
      rm -f "''${current}"
    fi

    shopt -s nullglob nocaseglob
    walls=(
      "''${ANIME_DIR}"/*.png
      "''${ANIME_DIR}"/*.jpg
      "''${ANIME_DIR}"/*.jpeg
      "''${ANIME_DIR}"/*.webp
    )
    shopt -u nullglob nocaseglob

    if [ "''${#walls[@]}" -eq 0 ]; then
      exec noctalia msg wallpaper-set "''${DEFAULT_WALL}"
    fi

    IFS=$'\n' walls=($(printf '%s\n' "''${walls[@]}" | sort))
    unset IFS

    count="''${#walls[@]}"
    idx=0
    if [ -f "''${STATE_FILE}" ]; then
      raw_idx="$(cat "''${STATE_FILE}" 2>/dev/null || echo 0)"
      if [[ "''${raw_idx}" =~ ^[0-9]+$ ]]; then
        idx=$(( raw_idx % count ))
      fi
    fi

    case "''${action}" in
      toggle)
        if [ -z "''${current}" ] || [[ "''${current}" == */noctalia-wallpaper.png ]]; then
          echo "''${idx}" > "''${STATE_FILE}"
          exec noctalia msg wallpaper-set "''${walls[$idx]}"
        else
          exec noctalia msg wallpaper-set "''${DEFAULT_WALL}"
        fi
        ;;
      next)
        if [ -n "''${current}" ] && [[ "''${current}" != */noctalia-wallpaper.png ]]; then
          idx=$(( (idx + 1) % count ))
        fi
        echo "''${idx}" > "''${STATE_FILE}"
        exec noctalia msg wallpaper-set "''${walls[$idx]}"
        ;;
      ban)
        echo "''${idx}" > "''${STATE_FILE}"
        exec noctalia msg wallpaper-set "''${walls[$idx]}"
        ;;
      prev)
        if [ -n "''${current}" ] && [[ "''${current}" != */noctalia-wallpaper.png ]]; then
          idx=$(( (idx - 1 + count) % count ))
        fi
        echo "''${idx}" > "''${STATE_FILE}"
        exec noctalia msg wallpaper-set "''${walls[$idx]}"
        ;;
      *)
        echo "Usage: noctalia-wallpaper {toggle|next|prev|ban|sync}" >&2
        exit 1
        ;;
    esac
  '';
in
{
  options.custom.desktop.niri.enable = mkEnableOption "niri desktop with noctalia shell";

  config = mkIf cfg.enable {
    services.polkit-gnome.enable = true;
    home.packages = [ noctaliaWallpaperPkg ];

    systemd.user.services.noctalia-wallpaper-sync = {
      Unit = {
        Description = "Sync anime wallpapers from AniList manga list via Wallhaven";
        After = [ "network-online.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${noctaliaWallpaperPkg}/bin/noctalia-wallpaper sync";
      };
    };

    systemd.user.timers.noctalia-wallpaper-sync = {
      Unit = {
        Description = "Daily AniList manga wallpaper sync timer";
      };
      Timer = {
        OnStartupSec = "2m";
        OnCalendar = "daily";
        Persistent = true;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };

    home.activation.seedAnimeWallpapers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/Pictures/Wallpapers/anime" "''${XDG_STATE_HOME:-$HOME/.local/state}/noctalia"
      BANNED_FILE="''${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/banned-wallpapers.txt"
      touch "$BANNED_FILE"
      rm -f "$HOME/Pictures/Wallpapers/anime/01-computer-girl.jpg"
      ${concatMapStringsSep "\n" (w: ''
        if [ ! -e "$HOME/Pictures/Wallpapers/anime/${w.name}" ] && ! grep -Fxq "${w.name}" "$BANNED_FILE" 2>/dev/null; then
          install -m 0644 "${w.src}" "$HOME/Pictures/Wallpapers/anime/${w.name}"
        fi
      '') starterAnimeWallpapers}
    '';

    programs.noctalia = {
      enable = true;
      systemd.enable = true;
      settings = {
        theme = {
          mode = "dark";
          source = "builtin";
          builtin = "Catppuccin";
        };
        shell = {
          font = "FiraCode Nerd Font";
        };
      };
    };

    wayland.windowManager.niri = {
      enable = true;
      package = pkgs.niri;
      systemd.enable = true;
      xwaylandSatellitePackage = pkgs.xwayland-satellite;
      portalPackage = null;

      settings = {
        prefer-no-csd = { };
        screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
        hotkey-overlay.skip-at-startup = { };

        cursor = {
          xcursor-theme = "catppuccin-latte-light-cursors";
          xcursor-size = 24;
        };

        environment = {
          NIXOS_OZONE_WL = "1";
          GDK_BACKEND = "wayland";
          QT_QPA_PLATFORM = "wayland;xcb";
          QT_QPA_PLATFORMTHEME = "qt6ct";
        };

        input = {
          keyboard.xkb.options = "caps:escape";
          touchpad = {
            tap = { };
            dwt = { };
          };
          focus-follows-mouse._props.max-scroll-amount = "0%";
        };

        layout = {
          gaps = 8;
          center-focused-column = "never";

          preset-column-widths._children = [
            { proportion = 0.33333; }
            { proportion = 0.5; }
            { proportion = 0.66667; }
            { proportion = 0.8; }
          ];

          default-column-width = {
            proportion = 0.5;
          };

          focus-ring = {
            width = 2;
            active-color = palette.blue.hex;
            inactive-color = palette.surface0.hex;
          };

          border.off = { };
        };

        _children = [
          # AOC 24" 1080p (Top-Left)
          {
            output = {
              _args = [ "DP-3" ];
              mode = "1920x1080@60.000";
              scale = 1.0;
              position._props = {
                x = 0;
                y = 0;
              };
            };
          }
          # Gigabyte M32U 32" 4K (Top-Right)
          {
            output = {
              _args = [ "DP-2" ];
              mode = "3840x2160@144.000";
              scale = 1.5;
              position._props = {
                x = 1920;
                y = 0;
              };
            };
          }
          # Laptop Internal Panel (Below AOC)
          {
            output = {
              _args = [ "eDP-1" ];
              mode = "2880x1800@60.000";
              scale = 1.75;
              position._props = {
                x = 140;
                y = 1080;
              };
            };
          }
          {
            window-rule = {
              geometry-corner-radius = 6;
              clip-to-geometry = true;
            };
          }
          {
            window-rule = {
              match._props.app-id = "^com\\.mitchellh\\.ghostty$";
              draw-border-with-background = false;
            };
          }
        ];

        binds = {
          # Hotkey overlay
          "Mod+Shift+Slash".show-hotkey-overlay = { };

          # Terminal & Apps
          "Mod+Q" = {
            _props.hotkey-overlay-title = "Open Terminal (Ghostty)";
            spawn = [ "ghostty" ];
          };
          "Mod+Return" = {
            _props.hotkey-overlay-title = "Open Terminal (Ghostty)";
            spawn = [ "ghostty" ];
          };
          "Mod+T" = {
            _props.hotkey-overlay-title = "Open Terminal (Ghostty)";
            spawn = [ "ghostty" ];
          };
          "Mod+E" = {
            _props.hotkey-overlay-title = "Open Neovim File Manager";
            spawn = [
              "ghostty"
              "-e"
              "nvim"
              "~/"
            ];
          };

          # Noctalia Shell Panels & Actions
          "Mod+Space" = {
            _props.hotkey-overlay-title = "Toggle App Launcher";
            spawn = [
              "noctalia"
              "msg"
              "panel-toggle"
              "launcher"
            ];
          };
          "Mod+D" = {
            _props.hotkey-overlay-title = "Toggle App Launcher";
            spawn = [
              "noctalia"
              "msg"
              "panel-toggle"
              "launcher"
            ];
          };
          "Mod+S" = {
            _props.hotkey-overlay-title = "Toggle Control Center";
            spawn = [
              "noctalia"
              "msg"
              "panel-toggle"
              "control-center"
            ];
          };
          "Mod+Comma" = {
            _props.hotkey-overlay-title = "Toggle Noctalia Settings";
            spawn = [
              "noctalia"
              "msg"
              "settings-toggle"
            ];
          };
          "Mod+V" = {
            _props.hotkey-overlay-title = "Clipboard History";
            spawn = [
              "noctalia"
              "msg"
              "clipboard"
            ];
          };
          "Mod+Alt+L" = {
            _props.hotkey-overlay-title = "Lock Screen";
            spawn = [
              "noctalia"
              "msg"
              "session"
              "lock"
            ];
          };
          "Mod+Shift+Q" = {
            _props.hotkey-overlay-title = "Session Power Menu";
            spawn = [
              "noctalia"
              "msg"
              "panel-toggle"
              "session"
            ];
          };
          "Alt+Tab" = {
            _props.hotkey-overlay-title = "Window Switcher";
            spawn = [
              "noctalia"
              "msg"
              "window-switcher"
            ];
          };
          "Mod+B" = {
            _props.hotkey-overlay-title = "Toggle Default / Anime Wallpaper";
            spawn = [
              "noctalia-wallpaper"
              "toggle"
            ];
          };
          "Mod+Shift+B" = {
            _props.hotkey-overlay-title = "Next Anime Wallpaper";
            spawn = [
              "noctalia-wallpaper"
              "next"
            ];
          };
          "Mod+Ctrl+B" = {
            _props.hotkey-overlay-title = "Ban Current Anime Wallpaper";
            spawn = [
              "noctalia-wallpaper"
              "ban"
            ];
          };

          # Audio & Brightness via Noctalia OSD
          "XF86AudioRaiseVolume" = {
            _props.allow-when-locked = true;
            spawn = [
              "noctalia"
              "msg"
              "volume-up"
            ];
          };
          "XF86AudioLowerVolume" = {
            _props.allow-when-locked = true;
            spawn = [
              "noctalia"
              "msg"
              "volume-down"
            ];
          };
          "XF86AudioMute" = {
            _props.allow-when-locked = true;
            spawn = [
              "noctalia"
              "msg"
              "volume-mute"
            ];
          };
          "XF86AudioMicMute" = {
            _props.allow-when-locked = true;
            spawn = [
              "noctalia"
              "msg"
              "mic-mute"
            ];
          };
          "XF86MonBrightnessUp" = {
            _props.allow-when-locked = true;
            spawn = [
              "noctalia"
              "msg"
              "brightness-up"
            ];
          };
          "XF86MonBrightnessDown" = {
            _props.allow-when-locked = true;
            spawn = [
              "noctalia"
              "msg"
              "brightness-down"
            ];
          };

          # Media playback
          "XF86AudioPlay" = {
            _props.allow-when-locked = true;
            spawn = [
              "playerctl"
              "play-pause"
            ];
          };
          "XF86AudioPause" = {
            _props.allow-when-locked = true;
            spawn = [
              "playerctl"
              "play-pause"
            ];
          };
          "XF86AudioNext" = {
            _props.allow-when-locked = true;
            spawn = [
              "playerctl"
              "next"
            ];
          };
          "XF86AudioPrev" = {
            _props.allow-when-locked = true;
            spawn = [
              "playerctl"
              "previous"
            ];
          };

          # Window & Overview management
          "Mod+O" = {
            _props.repeat = false;
            toggle-overview = { };
          };
          "Mod+C" = {
            _props.repeat = false;
            close-window = { };
          };
          "Mod+F".maximize-column = { };
          "Mod+Shift+F".fullscreen-window = { };
          "Mod+R".switch-preset-column-width = { };
          "Mod+Shift+R".switch-preset-window-height = { };
          "Mod+Ctrl+R".reset-window-height = { };
          "Mod+Ctrl+F".expand-column-to-available-width = { };
          "Mod+Ctrl+C".center-column = { };
          "Mod+Shift+V".toggle-window-floating = { };
          "Mod+Shift+W".switch-focus-between-floating-and-tiling = { };
          "Mod+W".toggle-column-tabbed-display = { };

          # Column width & window height adjustments
          "Mod+Minus".set-column-width = "-10%";
          "Mod+Equal".set-column-width = "+10%";
          "Mod+Shift+Minus".set-window-height = "-10%";
          "Mod+Shift+Equal".set-window-height = "+10%";

          # Consume / expel windows into/from columns
          "Mod+BracketLeft".consume-or-expel-window-left = { };
          "Mod+BracketRight".consume-or-expel-window-right = { };
          "Mod+Period".expel-window-from-column = { };

          # Focus column / window
          "Mod+Left".focus-column-left = { };
          "Mod+Right".focus-column-right = { };
          "Mod+Down".focus-window-or-workspace-down = { };
          "Mod+Up".focus-window-or-workspace-up = { };
          "Mod+H".focus-column-left = { };
          "Mod+L".focus-column-right = { };
          "Mod+J".focus-window-or-workspace-down = { };
          "Mod+K".focus-window-or-workspace-up = { };

          # Move column / window
          "Mod+Shift+Left".move-column-left = { };
          "Mod+Shift+Right".move-column-right = { };
          "Mod+Shift+Down".move-window-down-or-to-workspace-down = { };
          "Mod+Shift+Up".move-window-up-or-to-workspace-up = { };
          "Mod+Shift+H".move-column-left = { };
          "Mod+Shift+L".move-column-right = { };
          "Mod+Shift+J".move-window-down-or-to-workspace-down = { };
          "Mod+Shift+K".move-window-up-or-to-workspace-up = { };

          "Mod+Home".focus-column-first = { };
          "Mod+End".focus-column-last = { };
          "Mod+Ctrl+Home".move-column-to-first = { };
          "Mod+Ctrl+End".move-column-to-last = { };

          # Focus monitor
          "Mod+Ctrl+Left".focus-monitor-left = { };
          "Mod+Ctrl+Right".focus-monitor-right = { };
          "Mod+Ctrl+Down".focus-monitor-down = { };
          "Mod+Ctrl+Up".focus-monitor-up = { };
          "Mod+Ctrl+H".focus-monitor-left = { };
          "Mod+Ctrl+L".focus-monitor-right = { };
          "Mod+Ctrl+J".focus-monitor-down = { };
          "Mod+Ctrl+K".focus-monitor-up = { };

          # Move column to monitor
          "Mod+Shift+Ctrl+Left".move-column-to-monitor-left = { };
          "Mod+Shift+Ctrl+Right".move-column-to-monitor-right = { };
          "Mod+Shift+Ctrl+Down".move-column-to-monitor-down = { };
          "Mod+Shift+Ctrl+Up".move-column-to-monitor-up = { };
          "Mod+Shift+Ctrl+H".move-column-to-monitor-left = { };
          "Mod+Shift+Ctrl+L".move-column-to-monitor-right = { };
          "Mod+Shift+Ctrl+J".move-column-to-monitor-down = { };
          "Mod+Shift+Ctrl+K".move-column-to-monitor-up = { };

          # Workspaces
          "Mod+Page_Down".focus-workspace-down = { };
          "Mod+Page_Up".focus-workspace-up = { };
          "Mod+U".focus-workspace-down = { };
          "Mod+I".focus-workspace-up = { };
          "Mod+Ctrl+Page_Down".move-column-to-workspace-down = { };
          "Mod+Ctrl+Page_Up".move-column-to-workspace-up = { };
          "Mod+Ctrl+U".move-column-to-workspace-down = { };
          "Mod+Ctrl+I".move-column-to-workspace-up = { };

          "Mod+WheelScrollDown" = {
            _props.cooldown-ms = 150;
            focus-workspace-down = { };
          };
          "Mod+WheelScrollUp" = {
            _props.cooldown-ms = 150;
            focus-workspace-up = { };
          };
          "Mod+Ctrl+WheelScrollDown" = {
            _props.cooldown-ms = 150;
            move-column-to-workspace-down = { };
          };
          "Mod+Ctrl+WheelScrollUp" = {
            _props.cooldown-ms = 150;
            move-column-to-workspace-up = { };
          };
          "Mod+WheelScrollRight".focus-column-right = { };
          "Mod+WheelScrollLeft".focus-column-left = { };

          "Mod+1".focus-workspace = 1;
          "Mod+2".focus-workspace = 2;
          "Mod+3".focus-workspace = 3;
          "Mod+4".focus-workspace = 4;
          "Mod+5".focus-workspace = 5;
          "Mod+6".focus-workspace = 6;
          "Mod+7".focus-workspace = 7;
          "Mod+8".focus-workspace = 8;
          "Mod+9".focus-workspace = 9;

          "Mod+Shift+1".move-column-to-workspace = 1;
          "Mod+Shift+2".move-column-to-workspace = 2;
          "Mod+Shift+3".move-column-to-workspace = 3;
          "Mod+Shift+4".move-column-to-workspace = 4;
          "Mod+Shift+5".move-column-to-workspace = 5;
          "Mod+Shift+6".move-column-to-workspace = 6;
          "Mod+Shift+7".move-column-to-workspace = 7;
          "Mod+Shift+8".move-column-to-workspace = 8;
          "Mod+Shift+9".move-column-to-workspace = 9;

          # Screenshots (Niri built-in screenshot UI)
          "Print".screenshot = { };
          "Ctrl+Print".screenshot-screen = { };
          "Alt+Print".screenshot-window = { };

          # Session & Monitors
          "Mod+Escape" = {
            _props.allow-inhibiting = false;
            toggle-keyboard-shortcuts-inhibit = { };
          };
          "Mod+Shift+E".quit = { };
          "Mod+Shift+P".power-off-monitors = { };
        };
      };
    };
  };
}
