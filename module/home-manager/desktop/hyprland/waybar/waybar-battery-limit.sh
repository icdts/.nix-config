#!/usr/bin/env bash

BAT_PATH="/sys/class/power_supply/BAT0"
ASUS_THRESHOLD_FILE="$BAT_PATH/charge_control_end_threshold"

toggle_limit() {
    if command -v asusctl &> /dev/null && [ -f "$ASUS_THRESHOLD_FILE" ]; then
        local current_limit
        current_limit=$(cat "$ASUS_THRESHOLD_FILE")
        if [[ "$current_limit" -eq "100" ]]; then
            asusctl -c 60
        else
            asusctl -c 100
        fi
        # Instead of returning 0, return the actual exit code of the asusctl command.
        return $?
    fi
}

print_json() {
    local status capacity
    status=$(cat "$BAT_PATH/status")
    capacity=$(cat "$BAT_PATH/capacity")

    local limit="100"
    if [ -f "$ASUS_THRESHOLD_FILE" ]; then
        limit=$(cat "$ASUS_THRESHOLD_FILE")
    fi

    local icon=""
    if [ "$status" = "Charging" ]; then
        icon=""
    elif [ "$status" = "Full" ] || [ "$status" = "Not charging" ]; then
        icon=""
    else # Discharging
        if [ "$capacity" -ge 95 ]; then icon="";
        elif [ "$capacity" -ge 70 ]; then icon="";
        elif [ "$capacity" -ge 50 ]; then icon="";
        elif [ "$capacity" -ge 25 ]; then icon="";
        else icon=""; fi
    fi

    local text tooltip
    text="$icon $capacity / $limit"
    tooltip="Status: $status\nCapacity: $capacity%\nCharge Limit: $limit%"
    printf '{"text": "%s", "tooltip": "%s", "class": "custom-battery"}\n' "$text" "$tooltip"
}

case "$1" in
    toggle)
        toggle_limit
        ;;
    *)
        print_json
        ;;
esac
