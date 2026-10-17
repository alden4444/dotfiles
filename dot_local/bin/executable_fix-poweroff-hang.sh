#!/usr/bin/env bash
set -euo pipefail

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "This script modifies system boot files and must be run with sudo:"
    echo "  sudo ~/.local/bin/fix-poweroff-hang.sh"
    exit 1
fi

echo "==> 1. Blacklisting sp5100_tco watchdog driver..."
cat << 'EOF' > /etc/modprobe.d/sp5100_tco.conf
# Prevent AMD chipset watchdog from locking up poweroff/reboot
blacklist sp5100_tco
EOF

echo "==> 2. Disabling systemd hardware watchdog on shutdown/reboot..."
mkdir -p /etc/systemd/system.conf.d
cat << 'EOF' > /etc/systemd/system.conf.d/disable-watchdog.conf
[Manager]
RuntimeWatchdogSec=off
RebootWatchdogSec=off
ShutdownWatchdogSec=off
EOF

echo "==> 3. Updating /etc/default/grub kernel parameters..."
if grep -q "sp5100_tco" /etc/default/grub; then
    echo "    GRUB configuration already contains sp5100_tco parameter."
else
    # Append nowatchdog and modprobe.blacklist=sp5100_tco safely to GRUB_CMDLINE_LINUX_DEFAULT
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nowatchdog modprobe.blacklist=sp5100_tco"/' /etc/default/grub
    echo "    Added 'nowatchdog modprobe.blacklist=sp5100_tco' to GRUB_CMDLINE_LINUX_DEFAULT."
fi

echo "==> 4. Regenerating GRUB config (/boot/grub/grub.cfg)..."
grub-mkconfig -o /boot/grub/grub.cfg

echo "==> 5. Regenerating initramfs images (mkinitcpio)..."
mkinitcpio -P

echo ""
echo "==> Success! The AMD SP5100 watchdog freeze fix is fully installed."
echo "    Your computer will now power off cleanly without hanging on a blinking cursor."
