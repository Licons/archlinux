#!/usr/bin/env bash
set -euo pipefail

# Arch Linux workstation - BASE
# Run as a normal user with sudo access.

[[ $EUID -eq 0 ]] && { echo "Run as normal user, not root."; exit 1; }

PACMAN=(sudo pacman -S --needed --noconfirm)

echo "==> [BASE] Updating system"
sudo pacman -Syu --noconfirm

echo "==> [BASE] Core services, CLI, shell, input method"
"${PACMAN[@]}" \
  networkmanager \
  bluez bluez-utils \
  pipewire pipewire-alsa pipewire-pulse pipewire-audio wireplumber \
  ufw ufw-extras gufw \
  git git-lfs curl wget unzip 7zip less man-db bash-completion \
  fastfetch fish \
  fcitx5-im fcitx5-configtool fcitx5-unikey \
  noto-fonts noto-fonts-emoji noto-fonts-cjk \
  ttf-dejavu ttf-liberation ttf-jetbrains-mono \
  power-profiles-daemon cups-pk-helper kimageformats

echo "==> [BASE] Enabling system services"
sudo systemctl enable NetworkManager.service
sudo systemctl enable bluetooth.service
sudo systemctl enable ufw.service

echo "==> [BASE] Firewall defaults"
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow http
sudo ufw allow https
sudo ufw --force enable

echo "==> [BASE] Fish configuration"
mkdir -p "$HOME/.config/fish/functions"
cat > "$HOME/.config/fish/config.fish" <<'EOF'
if status is-interactive
    fastfetch
end

set -g fish_greeting
set -gx PATH /usr/bin $HOME/.local/bin $HOME/.dotnet/tools $HOME/.opencode/bin
set -Ux SSL_CERT_DIR "$HOME/.aspnet/dev-certs/trust:/etc/ssl/certs"
set -x DOTNET_CLI_TELEMETRY_OPTOUT 1
set -x LC_ALL C.UTF-8
EOF

cat > "$HOME/.config/fish/functions/fish_prompt.fish" <<'EOF'
function fish_prompt
    set_color purple
    echo (pwd)
    set_color green
    echo -n '> '
    set_color normal
end
EOF

echo "==> [BASE] Fcitx5"
# Niri starts xdg-desktop-autostart.target, and the Arch fcitx5 package
# already ships /etc/xdg/autostart/org.fcitx.Fcitx5.desktop.
#
# Prefer Wayland text-input for native GTK/Qt applications.
# Keep XMODIFIERS only for legacy X11/XWayland applications.
mkdir -p "$HOME/.config/environment.d"
cat > "$HOME/.config/environment.d/50-fcitx5.conf" <<'EOF'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
INPUT_METHOD=fcitx
XMODIFIERS=@im=fcitx
EOF

git lfs install --skip-repo

echo "==> [BASE] Done"
