#!/bin/sh
# Start the interactive installer at the first console login from the ISO.
if [ -t 0 ] && grep -qE '/dev/root.*iso9660' /proc/mounts; then
	if [ ! -e /tmp/.lede-installer-started ]; then
		: > /tmp/.lede-installer-started
		/usr/sbin/lede-install
	else
		echo 'Run lede-install to install this ISO to a disk.'
	fi
fi
