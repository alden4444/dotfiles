#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (e.g. sudo bash fix_bluetooth.sh)" >&2
   exit 1
fi

echo "=== 1. Updating /etc/bluetooth/main.conf ==="
# Backup original config
cp -a /etc/bluetooth/main.conf /etc/bluetooth/main.conf.bak.$(date +%s)

# Set ControllerMode = dual and remove/comment DisableLE
sed -i -E 's/^[#[:space:]]*ControllerMode[[:space:]]*=.*/ControllerMode = dual/' /etc/bluetooth/main.conf
sed -i -E 's/^[[:space:]]*DisableLE[[:space:]]*=.*/#DisableLE = yes/' /etc/bluetooth/main.conf

# Enable Experimental = true under [General]
sed -i -E 's/^[#[:space:]]*Experimental[[:space:]]*=.*/Experimental = true/' /etc/bluetooth/main.conf

# Enable AutoEnable = true under [Policy]
sed -i -E 's/^[#[:space:]]*AutoEnable[[:space:]]*=.*/AutoEnable = true/' /etc/bluetooth/main.conf

echo "Verifying /etc/bluetooth/main.conf changes:"
grep -n -E "^(ControllerMode|Experimental|AutoEnable|#DisableLE)" /etc/bluetooth/main.conf

echo -e "\n=== 2. Performing hardware-level driver rebind / module reload ==="
# Stop bluetooth service first to release device cleanly
systemctl stop bluetooth || true

# Rebind via sysfs or modprobe
if [[ -d /sys/bus/usb/drivers/btusb ]]; then
    for dev in 1-7:1.0 1-7:1.1; do
        if [[ -e /sys/bus/usb/drivers/btusb/$dev ]]; then
            echo "$dev" > /sys/bus/usb/drivers/btusb/unbind 2>/dev/null || true
        fi
    done
    sleep 1
    modprobe -r btusb 2>/dev/null || true
    sleep 1
    modprobe btusb
fi

# Ensure controller is powered up and LE is enabled via btmgmt
echo -e "\n=== 3. Restarting bluetooth.service ==="
systemctl restart bluetooth
sleep 2

echo -e "\n=== 4. Configuring and verifying controller state via btmgmt ==="
# Bring controller up with LE
btmgmt --index 0 power off || true
btmgmt --index 0 le on
btmgmt --index 0 power on

echo -e "\n=== Final btmgmt info ==="
btmgmt info
