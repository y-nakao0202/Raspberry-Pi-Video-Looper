#!/bin/sh

CUSTOM_BOARD_DIR="$(dirname $0)"
GENIMAGE_CFG=""
START_FILE=""
FIXUP_FILE=""
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

# Pass an empty rootpath. genimage makes a full copy of the given rootpath to
# ${GENIMAGE_TMP}/root so passing TARGET_DIR would be a waste of time and disk
# space. We don't rely on genimage to build the rootfs image, just to insert a
# pre-built one in the disk image.

trap 'rm -rf "${ROOTPATH_TMP}"' EXIT
ROOTPATH_TMP="$(mktemp -d)"

echo "Post-image: processing $@"

# Process custom args
for arg in "$@"
do
	case "${arg}" in
		--genimage0)
			echo "Genimage set to genimage0.cfg"
			GENIMAGE_CFG="${CUSTOM_BOARD_DIR}/genimage0.cfg"
			START_FILE="start.elf"
			FIXUP_FILE="fixup.dat"
		;;
		--genimage4)
			echo "Genimage set to genimage4.cfg"
			GENIMAGE_CFG="${CUSTOM_BOARD_DIR}/genimage4.cfg"
			START_FILE="start4.elf"
			FIXUP_FILE="fixup4.dat"
		;;
	esac
done


# Override cmdline.txt
cat << __EOF__ > "${BINARIES_DIR}/rpi-firmware/cmdline.txt"
console=ttyAMA0,115200 ipv6.disable=1 consoleblank=0 vt.global_cursor_default=0 logo.nologo ignore_loglevel root=/dev/mmcblk0p2 rootwait
__EOF__

# Override config.txt
cat << __EOF__ > "${BINARIES_DIR}/rpi-firmware/config.txt"
start_file=${START_FILE}
fixup_file=${FIXUP_FILE}
kernel=zImage
gpu_mem_256=128
gpu_mem_512=196
gpu_mem_1024=384
boot_delay=0
disable_splash=1
enable_uart=1
dtoverlay=miniuart-bt
dtoverlay=dwc2,dr_mode=peripheral
device_tree=bcm2708-rpi-zero-w.dtb

hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_timings=440 1 30 20 30 1920 1 10 5 10 0 0 0 60 0 60680000 1
disable_overscan=1
__EOF__

# Create video.txt with default playback settings
printf '%s\n' '--win 0,0,440,1920 /boot/video.mp4' > "${BINARIES_DIR}/video.txt"

echo "Generating SD image"
rm -rf "${GENIMAGE_TMP}"

genimage                           \
	--rootpath "${ROOTPATH_TMP}"     \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
  --config "${GENIMAGE_CFG}"

exit $?

