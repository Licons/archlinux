#!/usr/bin/env bash
set -euo pipefail

# Arch Linux workstation - DESKTOP
# Niri + DankMaterialShell + greetd + GTK/Qt tools

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ $EUID -eq 0 ]] && { echo "Run as normal user, not root."; exit 1; }

PACMAN=(sudo pacman -S --needed --noconfirm)

echo "==> [DESKTOP] Installing Niri + DMS"
# DMS upstream Arch docs: install dms-shell and pair it with niri.
"${PACMAN[@]}" \
  niri \
  dms-shell \
  xwayland-satellite \
  xdg-desktop-portal \
  xdg-desktop-portal-gnome \
  xdg-desktop-portal-gtk \
  xorg-xhost \
  wl-clipboard cliphist \
  grim slurp \
  matugen cava \
  qt6-multimedia-ffmpeg \
  vdirsyncer khal python-aiohttp-oauthlib \
  fprintd \
  flatpak

echo "==> [DESKTOP] Display manager and desktop integration"
"${PACMAN[@]}" \
  greetd \
  polkit \
  gnome-keyring libsecret \
  nwg-look adw-gtk-theme adwaita-icon-theme capitaine-cursors \
  qt5ct qt6ct kvantum \
  tela-circle-icon-theme-all

echo "==> [DESKTOP] Applications and filesystem integration"
"${PACMAN[@]}" \
  foot \
  nemo nemo-terminal nemo-share nemo-fileroller \
  file-roller viewnior \
  gnome-screenshot gnome-calculator gnome-characters \
  pavucontrol blueman \
  gvfs gvfs-mtp gvfs-gphoto2 tumbler udiskie udisks2

echo "==> [DESKTOP] Enabling greetd"
sudo systemctl enable greetd

echo "==> [DESKTOP] Environment"
mkdir -p "$HOME/.config/environment.d"
cat > "$HOME/.config/environment.d/90-desktop.conf" <<'EOF'
QT_QPA_PLATFORM=wayland
QT_QPA_PLATFORMTHEME=gtk3
ELECTRON_OZONE_PLATFORM_HINT=auto
TERMINAL=foot
EOF

echo "==> [DESKTOP] DMS compositor setup"
mkdir -p "$HOME/.config/niri"
# Headless setup documented by DMS. No --force: preserve existing configs.
dms setup headless --compositor niri --skip-existing

# Bind DMS specifically to Niri instead of enabling it for every graphical DE.
systemctl --user add-wants niri.service dms

echo "==> [DESKTOP] XDG autostart"
mkdir -p "$HOME/.config/autostart"

cat > "$HOME/.config/autostart/udiskie.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=udiskie
Exec=udiskie --tray
Terminal=false
OnlyShowIn=niri;
EOF
# Không thêm polkit-gnome: DMS đã có polkit agent riêng, agent thứ hai làm DMS đăng ký thất bại.

echo "==> [DESKTOP] GTK defaults"
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

cat > "$HOME/.config/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Adwaita
gtk-icon-theme-name=Adwaita
gtk-font-name=Adwaita Sans 10
gtk-cursor-theme-name=capitaine-cursors-light
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF

cat > "$HOME/.config/gtk-4.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Adwaita
gtk-icon-theme-name=Adwaita
gtk-font-name=Adwaita Sans 10
gtk-cursor-theme-name=capitaine-cursors-light
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF

# xdg-desktop-portal-gnome exposes GNOME UI settings to Flatpak.
if command -v dconf >/dev/null 2>&1; then
    dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'" || true
fi

gsettings set org.cinnamon.desktop.default-applications.terminal exec 'foot'

mkdir -p  $HOME/.config/foot
tee $HOME/.config/foot/foot.ini>/dev/null <<'EOF'
[main]
font=Adwaita Mono:size=10
# Gạch chân 2px sát đáy ô: vạch tím của tab tmux đang chọn không đè lên chữ
underline-offset=3px
underline-thickness=2px

shell=tmux new-session -A -s main
EOF

cp -fv "$SCRIPT_DIR/.tmux.conf" "$HOME"

echo "==> [DESKTOP] Done"
echo "Log out/reboot, then log in to Niri via greetd (DMS greeter)."
echo "DMS logs: journalctl --user -u dms -f"
