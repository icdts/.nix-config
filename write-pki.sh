#!/usr/bin/env bash

set -e

COLOR_BLUE='\033[1;34m'
COLOR_GREEN='\033[1;32m'
COLOR_RED='\033[1;31m'
COLOR_NC='\033[0m' # no color

if [ ! -L "sdcard-vault" ]; then
	echo -e "${COLOR_RED}Error: 'sdcard-vault' symlink not found.${COLOR_NC}" >&2
	exit 1
fi

IMG_PATH=$(find "$(readlink -f ./sdcard-vault)" -type f -name '*.img' -print -quit)
if [ -z "$IMG_PATH" ]; then
	OUT_DIR=$(readlink -f ./sdcard-vault)
	echo -e "${COLOR_RED}Error: No .img file found in the build output directory: ${OUT_DIR}${COLOR_NC}" >&2
	exit 1
fi
echo "Image found: $IMG_PATH"


REMOVABLE_DISKS=($(lsblk -d -n -o NAME,RM,TYPE,SIZE | awk '$2=="1" && $3=="disk" && $4 != "0B" {print "/dev/"$1}'))
if [ ${#REMOVABLE_DISKS[@]} -eq 0 ]; then
	echo -e "${COLOR_RED}Error: No suitable removable disks found. Aborting.${COLOR_NC}" >&2
	exit 1
fi

echo "Available removable disks:"
lsblk -d -o NAME,SIZE,MODEL "${REMOVABLE_DISKS[@]}"

DEFAULT_DEVICE="${REMOVABLE_DISKS[0]}"
read -p "Please select device to write to [${DEFAULT_DEVICE}]: " -e TARGET_DEVICE
TARGET_DEVICE=${TARGET_DEVICE:-$DEFAULT_DEVICE}

if ! [ -b "$TARGET_DEVICE" ]; then
	echo -e "${COLOR_RED}Error: '$TARGET_DEVICE' is not a valid block device.${COLOR_NC}" >&2
	exit 1
fi


echo -e "\n${COLOR_BLUE}--- (2/4) Confirmation ---${COLOR_NC}"
echo -e "${COLOR_RED}WARNING: This will completely erase all data on $TARGET_DEVICE.${COLOR_NC}"
read -p "Are you absolutely sure you want to proceed? (type 'yes'): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
	echo "Aborting." >&2
	exit 1
fi

sudo dd if="$IMG_PATH" of="$TARGET_DEVICE" bs=4M status=progress conv=fsync

# Add a short delay to allow the kernel to re-read the partition table
sleep 3
sudo mkdir -p /mnt/sdcard
sudo mount "${TARGET_DEVICE}2" /mnt/sdcard
sudo mkdir -p /mnt/sdcard/var/lib/sops
sudo cp /var/lib/sops/key.txt /mnt/sdcard/var/lib/sops/key.txt
sudo umount /mnt/sdcard
sudo eject "$TARGET_DEVICE"
