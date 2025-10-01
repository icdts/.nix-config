{ pkgs, lib, monitorDefinitions }:
let
  primaryMonitorDescNoPrefix =
    let
      primaryDesc = (lib.findFirst (m: m.primary == true) null (lib.attrValues monitorDefinitions)).description;
    in
      lib.removePrefix "desc:" primaryDesc;

  extendCaseStatementBody = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value:
      let
        desc_no_prefix = lib.removePrefix "desc:" value.description;
        workspaceCmd =
          if value.workspace != null
          then ''WORKSPACE_BATCH_CMD+="dispatch moveworkspacetomonitor ${toString value.workspace} $name;";''
          else "";
      in
      ''
        "${desc_no_prefix}")
          MONITOR_BATCH_CMD+="keyword monitor $name,${value.resolution},${value.position},${value.scale};"
          ${workspaceCmd}
          ;;
      ''
    ) monitorDefinitions
  );

  mirrorWorkspaceCmds = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value:
      if value.workspace != null
      then ''WORKSPACE_BATCH_CMD+="dispatch moveworkspacetomonitor ${toString value.workspace} $PRIMARY_MONITOR_NAME;";''
      else ""
    ) (lib.filterAttrs (n: v: v.workspace != null) monitorDefinitions)
  );

in
pkgs.writeShellApplication {
  name = "toggle-mirror";
  runtimeInputs = [ pkgs.jq pkgs.hyprland pkgs.libnotify ];
  text = ''
    #!/usr/bin/env bash

    PRIMARY_MONITOR_DESC_STR="${primaryMonitorDescNoPrefix}"
    
    reload_waybar() {
      pkill -SIGUSR2 waybar
    }

    MONITORS_JSON=$(hyprctl -j monitors all)
    IS_MIRRORING_BOOL=$(echo "$MONITORS_JSON" | jq 'any(.[] ; .mirrorOf != "none")')

    if [[ "$IS_MIRRORING_BOOL" == "true" ]]; then
      MIRROR_STATUS="Yes"
    else
      MIRROR_STATUS="No"
    fi
    echo "Are we mirroring? $MIRROR_STATUS"

    if [[ "$IS_MIRRORING_BOOL" == "true" ]]; then
      echo "Action: Restoring extend layout and moving workspaces."
      MONITOR_BATCH_CMD=""
      WORKSPACE_BATCH_CMD=""

      while IFS= read -r name && IFS= read -r desc; do
        case "$desc" in
          ${extendCaseStatementBody}
          *)
            MONITOR_BATCH_CMD+="keyword monitor $name,preferred,auto,1;"
            ;;
        esac
      done < <(echo "$MONITORS_JSON" | jq -r '.[] | .name, .description')

      echo "Executing monitor layout commands..."
      hyprctl --batch "$MONITOR_BATCH_CMD"

      echo "Waiting for monitors to initialize (0.5s)..."
      sleep 0.5

      echo "Executing workspace move commands..."
      hyprctl --batch "$WORKSPACE_BATCH_CMD"

      echo "Focusing workspaces 1, 2, and 3..."
      hyprctl --batch "dispatch workspace 1; dispatch workspace 2; dispatch workspace 3;"

      sleep 0.5
      echo "Reloading Waybar..."
      reload_waybar
      notify-send "Hyprland" "Extended layout restored"
    else
      echo "Action: Enabling mirror layout."
      PRIMARY_MONITOR_NAME=$(echo "$MONITORS_JSON" | jq -r --arg desc "$PRIMARY_MONITOR_DESC_STR" '.[] | select(.description == $desc) | .name')

      if [[ -z "$PRIMARY_MONITOR_NAME" ]]; then
        notify-send "Hyprland Error" "Could not find primary monitor. Is it connected?"
        exit 1
      fi
      
      mapfile -t OTHER_MONITOR_NAMES < <(echo "$MONITORS_JSON" | jq -r --arg primary "$PRIMARY_MONITOR_NAME" '.[] | select(.name != $primary) | .name')

      if [[ ''${#OTHER_MONITOR_NAMES[@]} -eq 0 ]]; then
        notify-send "Hyprland" "No other monitors to mirror."
        exit 0
      fi

      MONITOR_BATCH_CMD=""
      for MONITOR_NAME in "''${OTHER_MONITOR_NAMES[@]}"; do
        MONITOR_BATCH_CMD+="keyword monitor $MONITOR_NAME,preferred,auto,1,mirror,$PRIMARY_MONITOR_NAME;"
      done
      
      MONITOR_BATCH_CMD+="keyword monitor $PRIMARY_MONITOR_NAME,2880x1800@60,0x0,1;"
      
      WORKSPACE_BATCH_CMD=""
      ${mirrorWorkspaceCmds}

      echo "Executing monitor layout commands..."
      hyprctl --batch "$MONITOR_BATCH_CMD"

      echo "Waiting for monitors to initialize (0.5s)..."
      sleep 0.5
      
      echo "Moving workspaces to primary monitor..."
      hyprctl --batch "$WORKSPACE_BATCH_CMD"
      
      echo "Focusing workspace 1..."
      hyprctl dispatch workspace 1

      sleep 0.5
      echo "Reloading Waybar..."
      reload_waybar
      notify-send "Hyprland" "Display mirroring ON"
    fi
    echo "Script finished."
  '';
}
