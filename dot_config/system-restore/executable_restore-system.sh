#!/usr/bin/env bash
set -euo pipefail

RESTORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== 1. Restoring /etc/pacman.conf (multilib & parallel downloads) ==="
if [[ -f "$RESTORE_DIR/etc/pacman.conf" ]]; then
  sudo cp -f "$RESTORE_DIR/etc/pacman.conf" /etc/pacman.conf
  sudo pacman -Sy
fi

echo "=== 2. Installing official Arch packages ==="
if [[ -f "$RESTORE_DIR/pkglist-native.txt" ]]; then
  sudo pacman -S --needed - < "$RESTORE_DIR/pkglist-native.txt"
fi

echo "=== 3. Installing yay & AUR packages ==="
if ! command -v yay >/dev/null 2>&1; then
  tmp_yay="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$tmp_yay/yay"
  (cd "$tmp_yay/yay" && makepkg -si --noconfirm)
  rm -rf "$tmp_yay"
fi
if [[ -f "$RESTORE_DIR/pkglist-aur.txt" ]]; then
  yay -S --needed - < "$RESTORE_DIR/pkglist-aur.txt"
fi

echo "=== 4. Restoring /etc hardware, kernel, Bluetooth, and CoolerControl configs ==="
sudo cp -f "$RESTORE_DIR/etc/modprobe.d/"*.conf /etc/modprobe.d/
sudo cp -f "$RESTORE_DIR/etc/modules-load.d/"*.conf /etc/modules-load.d/
sudo cp -f "$RESTORE_DIR/etc/sysctl.d/"*.conf /etc/sysctl.d/
sudo mkdir -p /etc/bluetooth /etc/coolercontrol
sudo cp -f "$RESTORE_DIR/etc/bluetooth/main.conf" /etc/bluetooth/main.conf
sudo cp -f "$RESTORE_DIR/etc/coolercontrol/"* /etc/coolercontrol/
sudo cp -f "$RESTORE_DIR/etc/systemd/system/wire-pod.service" /etc/systemd/system/wire-pod.service
sudo cp -f "$RESTORE_DIR/etc/default/grub" /etc/default/grub
sudo cp -f "$RESTORE_DIR/etc/mkinitcpio.conf" /etc/mkinitcpio.conf

echo "=== 5. Rebuilding initramfs & GRUB config ==="
sudo mkinitcpio -P || true
if [[ -f /boot/grub/grub.cfg ]]; then
  sudo grub-mkconfig -o /boot/grub/grub.cfg || true
fi

echo "=== 6. Restoring Flatpaks ==="
if command -v flatpak >/dev/null 2>&1 && [[ -s "$RESTORE_DIR/flatpak-list.txt" ]]; then
  while read -r app; do
    [[ -z "$app" ]] && continue
    flatpak install -y flathub "$app" || true
  done < "$RESTORE_DIR/flatpak-list.txt"
fi

echo "=== 7. Cloning git repositories ==="
if [[ -f "$RESTORE_DIR/git-repos.txt" ]]; then
  while read -r url target; do
    [[ -z "$url" || "$url" == \#* ]] && continue
    expanded_target="${target/#\~/$HOME}"
    if [[ ! -d "$expanded_target/.git" ]]; then
      mkdir -p "$(dirname "$expanded_target")"
      git clone "$url" "$expanded_target" || true
    fi
  done < "$RESTORE_DIR/git-repos.txt"
fi

echo "=== 8. Enabling systemd services ==="
sudo systemctl daemon-reload
for svc in NetworkManager bluetooth coolercontrold docker ollama wire-pod; do
  sudo systemctl enable "$svc" || true
done
systemctl --user daemon-reload || true
systemctl --user enable hypridle.service openrgb.service rclone-gdrive.service notes-sync.timer || true

echo "=== System restoration complete! ==="
