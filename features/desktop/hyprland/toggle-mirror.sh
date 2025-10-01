#!/usr/bin/env bash

# Define the primary display (your laptop screen)
PRIMARY_DISPLAY="eDP-1"

# Check if the primary display is connected
PRIMARY_EXISTS=$(hyprctl -j monitors | jq --arg primary "$PRIMARY_DISPLAY" 'any(.[] ; .name == $primary)')

if [[ "$PRIMARY_EXISTS" != "true" ]]; then
    notify-send "Hyprland" "Primary display $PRIMARY_DISPLAY is not connected."
    exit 1
fi

# Check if any monitor is currently mirroring (THE CORRECTED LINE)
IS_MIRRORING=$(hyprctl -j monitors | jq 'any(.[] ; .mirrorOf != "none")')

if [[ "$IS_MIRRORING" == "true" ]]; then
    # --- TURN MIRRORING OFF ---
    # Revert to your standard extended layout.
    hyprctl --batch "\
        keyword monitor desc:AOC 2460G4 F61G4BA005375, 1920x1080@60, 960x0, 1;\
        keyword monitor desc:Samsung Display Corp. ATNA33AA08-0, 2880x1800@60, 0x1080, 1;\
        keyword monitor desc:GIGA-BYTE TECHNOLOGY CO. LTD. Gigabyte M32U 22181B001184, 3840x2160@144, 2880x0, 1"
    notify-send "Hyprland" "Display mirroring OFF"
else
    # --- TURN MIRRORING ON ---
    # Get a list of all monitors EXCEPT the primary one
    OTHER_MONITORS=$(hyprctl -j monitors | jq -r --arg primary "$PRIMARY_DISPLAY" '.[] | select(.name != $primary) | .name')

    # Start a batch command
    BATCH_CMD=""

    # Set the primary monitor to a known state
    BATCH_CMD+="keyword monitor $PRIMARY_DISPLAY, 2880x1800@60, 0x0, 1;"

    # For each other monitor, tell it to mirror the primary display
    for monitor in $OTHER_MONITORS; do
        BATCH_CMD+="keyword monitor $monitor, preferred, auto, 1, mirror, $PRIMARY_DISPLAY;"
    done

    # Execute all commands at once
    hyprctl --batch "$BATCH_CMD"
    notify-send "Hyprland" "Display mirroring ON"
fi
