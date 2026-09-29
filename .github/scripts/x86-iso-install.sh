#!/bin/sh
# Install the ext4 disk image carried by the LEDE installer ISO.
set -eu

if ! grep -qE '/dev/root.*iso9660' /proc/mounts; then
	echo 'This installer must be run from the LEDE ISO.' >&2
	exit 1
fi

if [ -d /sys/firmware/efi ]; then
	image=/installer/efi.img.gz
	bytes_file=/installer/efi.bytes
	boot_mode=UEFI
else
	image=/installer/bios.img.gz
	bytes_file=/installer/bios.bytes
	boot_mode=BIOS
fi

for file in "$image" "$bytes_file" /installer/SHA256SUMS; do
	[ -r "$file" ] || { echo "Missing installer file: $file" >&2; exit 1; }
done

for tool in lsblk gzip sha256sum dd parted partprobe e2fsck resize2fs sgdisk; do
	command -v "$tool" >/dev/null 2>&1 || {
		echo "Missing installer tool: $tool" >&2
		exit 1
	}
done

echo "LEDE disk installer ($boot_mode)"
echo 'The selected disk and all its existing partitions will be erased.'
echo 'Available disks:'
lsblk -dn -o PATH,SIZE,MODEL,TYPE
printf 'Enter the full target disk path (for example /dev/sda): '
IFS= read -r disk || exit 1
case "$disk" in
	/dev/*) ;;
	*) echo 'Enter a full /dev/ disk path.' >&2; exit 1 ;;
esac
[ -b "$disk" ] || { echo "Not a block device: $disk" >&2; exit 1; }
disk=$(readlink -f "$disk")
[ "$(lsblk -dn -o TYPE "$disk")" = disk ] || {
	echo "Select a whole disk, not a partition: $disk" >&2
	exit 1
}

disk_name=${disk##*/}
[ "$(cat "/sys/class/block/$disk_name/queue/logical_block_size")" = 512 ] || {
	echo 'The disk must use 512-byte logical sectors for this image.' >&2
	exit 1
}
if lsblk -nr -o MOUNTPOINT "$disk" | grep -q '[^[:space:]]'; then
	echo "A filesystem on $disk is mounted. Refusing to overwrite it." >&2
	exit 1
fi

disk_sectors=$(cat "/sys/class/block/$disk_name/size")
disk_bytes=$((disk_sectors * 512))
image_bytes=$(cat "$bytes_file")
case "$image_bytes" in
	''|*[!0-9]*) echo 'Invalid image size metadata.' >&2; exit 1 ;;
esac
[ "$image_bytes" -gt 0 ] || { echo 'The installer image is empty.' >&2; exit 1; }
[ "$disk_bytes" -ge "$image_bytes" ] || {
	echo "The selected disk is smaller than the $image_bytes-byte system image." >&2
	exit 1
}
if [ "$boot_mode" = BIOS ] && [ "$disk_sectors" -ge 4294967296 ]; then
	echo 'BIOS/MBR cannot use this entire disk. Boot the ISO in UEFI mode.' >&2
	exit 1
fi

echo "Target: $disk ($disk_bytes bytes); image: $image ($image_bytes bytes)"
printf 'Type ERASE %s to confirm: ' "$disk"
IFS= read -r confirmation || exit 1
[ "$confirmation" = "ERASE $disk" ] || { echo 'Cancelled.'; exit 1; }

echo 'Verifying installer image...'
(cd /installer && sha256sum -c SHA256SUMS) || exit 1

echo "Writing $boot_mode image to $disk..."
gzip -dc "$image" | dd of="$disk" bs=4M
sync

if [ "$boot_mode" = UEFI ]; then
	# The backup GPT header in the image must move to the end of the real disk.
	sgdisk -e "$disk"
fi

# Partition 1 is the boot partition; partition 2 is the ext4 root filesystem.
parted -s "$disk" resizepart 2 100%
partprobe "$disk"
case "$disk" in
	*[0-9]) root_partition="${disk}p2" ;;
	*) root_partition="${disk}2" ;;
esac
[ -b "$root_partition" ] || {
	echo "Cannot find the new root partition: $root_partition" >&2
	exit 1
}

echo "Checking and expanding $root_partition..."
fsck_result=0
e2fsck -f -y "$root_partition" || fsck_result=$?
[ "$fsck_result" -le 1 ] || {
	echo "Filesystem check failed (status $fsck_result)." >&2
	exit 1
}
resize2fs "$root_partition"
sync

echo 'Installation complete. Shut down, remove the ISO, and boot from the disk.'
