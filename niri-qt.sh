#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# Arch Linux base -> Niri + SDDM + Qt6/Qt5 + Qt applications
# Target: current Arch Linux (2026), x86_64
#
# Run either:
#   bash install-niri-qt.sh
# or:
#   sudo bash install-niri-qt.sh
#
# If running as root directly and auto-detection picks the wrong user:
#   TARGET_USER=your_username bash install-niri-qt.sh
# ============================================================

trap 'echo; echo "[ERROR] Failed at line ${LINENO}: ${BASH_COMMAND}" >&2' ERR

log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\n\033[1;33m[WARN] %s\033[0m\n' "$*"; }
die()  { printf '\n\033[1;31m[ERROR] %s\033[0m\n' "$*" >&2; exit 1; }

# ----------------------------
# Detect privilege / target user
# ----------------------------
if [[ ${EUID} -eq 0 ]]; then
    ROOT=()

    if [[ -z "${TARGET_USER:-}" ]]; then
        TARGET_USER="${SUDO_USER:-}"
    fi

    if [[ -z "${TARGET_USER:-}" || "${TARGET_USER}" == "root" ]]; then
        TARGET_USER="$(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 && $7 !~ /(nologin|false)$/ {print $1; exit}')"
    fi
else
    command -v sudo >/dev/null 2>&1 || die "sudo is not installed. Run this script as root, or install sudo first."
    ROOT=(sudo)
    TARGET_USER="${TARGET_USER:-$USER}"
fi

[[ -n "${TARGET_USER:-}" ]] || die "No normal user found. Create a user first, then rerun the script."
id "${TARGET_USER}" >/dev/null 2>&1 || die "User '${TARGET_USER}' does not exist."

TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
TARGET_GROUP="$(id -gn "${TARGET_USER}")"

[[ -d "${TARGET_HOME}" ]] || die "Home directory '${TARGET_HOME}' does not exist."

run_as_user() {
    if [[ ${EUID} -eq 0 ]]; then
        runuser -u "${TARGET_USER}" -- "$@"
    else
        "$@"
    fi
}

write_user_file() {
    local path="$1"
    local mode="${2:-0644}"
    local tmp
    tmp="$(mktemp)"
    cat > "${tmp}"
    "${ROOT[@]}" install -Dm"${mode}" -o "${TARGET_USER}" -g "${TARGET_GROUP}" "${tmp}" "${path}"
    rm -f "${tmp}"
}

backup_file() {
    local file="$1"
    if [[ -e "${file}" ]]; then
        local stamp
        stamp="$(date +%Y%m%d-%H%M%S)"
        "${ROOT[@]}" cp -a "${file}" "${file}.bak.${stamp}"
        echo "Backup: ${file}.bak.${stamp}"
    fi
}

log "Target user: ${TARGET_USER} (${TARGET_HOME})"

# ----------------------------
# Full system update
# ----------------------------
log "Updating Arch Linux"
"${ROOT[@]}" pacman -Syu --noconfirm

# ----------------------------
# Packages
# ----------------------------
PACKAGES=(
    # Base desktop / utilities
    sudo
    git
    curl
    wget
    rsync
    unzip
    7zip
    pciutils
    xdg-user-dirs
    xdg-utils

    # Networking
    networkmanager

    # Bluetooth
    bluez
    bluez-utils

    # Audio
    pipewire
    pipewire-alsa
    pipewire-pulse
    wireplumber

    # Graphics - safe/common userspace stack
    mesa
    vulkan-icd-loader
    vulkan-intel
    vulkan-radeon

    # Niri / Wayland
    niri
    xwayland-satellite
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    xdg-desktop-portal-gnome
    waybar
    fuzzel
    mako
    swaybg
    swayidle
    swaylock
    wl-clipboard
    grim
    slurp
    brightnessctl
    playerctl

    # Authentication / secrets
    polkit
    lxqt-policykit
    oo7

    # Display manager
    sddm

    # Qt 6 - primary stack
    qt6-base
    qt6-wayland
    qt6-declarative
    qt6-svg
    qt6-imageformats
    qt6-multimedia
    qt6-translations
    qt6-5compat
    qt6ct

    # Qt 5 - compatibility stack / old SDDM themes
    qt5-base
    qt5-wayland
    qt5-declarative
    qt5-svg
    qt5-imageformats
    qt5-multimedia
    qt5-translations
    qt5ct

    # Qt applications
    qterminal
    pcmanfm-qt
    featherpad
    lximage-qt
    lxqt-archiver
    pavucontrol-qt
    qps

    # Removable media / phone mounting
    gvfs
    gvfs-mtp
    udisks2

    # Fonts / icons
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    ttf-dejavu
    breeze-icons
    papirus-icon-theme
)

log "Installing Niri + SDDM + Qt5/Qt6 + Qt applications"
"${ROOT[@]}" pacman -S --needed --noconfirm "${PACKAGES[@]}"

# ----------------------------
# GPU note
# ----------------------------
if command -v lspci >/dev/null 2>&1 && lspci | grep -Eqi 'VGA|3D|Display'; then
    if lspci | grep -Ei 'VGA|3D|Display' | grep -qi NVIDIA; then
        warn "NVIDIA GPU detected. This script intentionally does NOT auto-install a kernel-specific NVIDIA driver. Install the appropriate current Arch NVIDIA driver for your GPU/kernel if it is not already installed."
    fi
fi

# ----------------------------
# Services
# ----------------------------
log "Enabling services"
"${ROOT[@]}" systemctl enable NetworkManager.service
"${ROOT[@]}" systemctl enable bluetooth.service
"${ROOT[@]}" systemctl enable sddm.service

# Start NetworkManager immediately if systemd is running.
if systemctl is-system-running >/dev/null 2>&1 || [[ "$(systemctl is-system-running 2>/dev/null || true)" == "degraded" ]]; then
    "${ROOT[@]}" systemctl start NetworkManager.service || true
fi

# ----------------------------
# XDG user directories
# ----------------------------
log "Creating XDG user directories"
run_as_user xdg-user-dirs-update || true
"${ROOT[@]}" install -d -o "${TARGET_USER}" -g "${TARGET_GROUP}" \
    "${TARGET_HOME}/Pictures/Screenshots" \
    "${TARGET_HOME}/.config/niri" \
    "${TARGET_HOME}/.config/waybar" \
    "${TARGET_HOME}/.config/mako" \
    "${TARGET_HOME}/.config/swaylock"

# ----------------------------
# Niri config
# Use the package's version-matched default config as the base.
# ----------------------------
NIRI_CONFIG="${TARGET_HOME}/.config/niri/config.kdl"
DEFAULT_NIRI_CONFIG="/usr/share/doc/niri/default-config.kdl"

[[ -f "${DEFAULT_NIRI_CONFIG}" ]] || die "Cannot find ${DEFAULT_NIRI_CONFIG}. Is the niri package installed correctly?"

log "Creating Niri configuration"
backup_file "${NIRI_CONFIG}"
"${ROOT[@]}" cp "${DEFAULT_NIRI_CONFIG}" "${NIRI_CONFIG}"
"${ROOT[@]}" chown "${TARGET_USER}:${TARGET_GROUP}" "${NIRI_CONFIG}"

# Change default terminal from Alacritty to QTerminal.
"${ROOT[@]}" sed -i 's/alacritty/qterminal/g' "${NIRI_CONFIG}"

# Add desktop components after Waybar startup.
TMP_NIRI="$(mktemp)"
awk '
{
    print
    if ($0 == "spawn-at-startup \"waybar\"") {
        print "spawn-at-startup \"mako\""
        print "spawn-at-startup \"lxqt-policykit-agent\""
        print "spawn-at-startup \"swaybg\" \"-c\" \"#1e1e2e\""
        print "spawn-sh-at-startup \"swayidle -w timeout 600 '\''swaylock -f -c 111111'\'' before-sleep '\''swaylock -f -c 111111'\''\""
    }
}
' "${NIRI_CONFIG}" > "${TMP_NIRI}"
"${ROOT[@]}" install -m0644 -o "${TARGET_USER}" -g "${TARGET_GROUP}" "${TMP_NIRI}" "${NIRI_CONFIG}"
rm -f "${TMP_NIRI}"

# Enable Niri-managed xwayland-satellite integration and prefer native Qt Wayland.
cat >> "${NIRI_CONFIG}" <<'EOF_NIRI'

// Added by install-niri-qt.sh
// Niri >= 25.08 manages xwayland-satellite on demand and sets DISPLAY itself.
xwayland-satellite {
    path "xwayland-satellite"
}

environment {
    // Native Wayland first, XCB fallback for older Qt applications.
    QT_QPA_PLATFORM "wayland;xcb"
}
EOF_NIRI
"${ROOT[@]}" chown "${TARGET_USER}:${TARGET_GROUP}" "${NIRI_CONFIG}"

# ----------------------------
# Waybar config for Niri
# ----------------------------
log "Creating Waybar configuration"
WAYBAR_CONFIG="${TARGET_HOME}/.config/waybar/config.jsonc"
WAYBAR_STYLE="${TARGET_HOME}/.config/waybar/style.css"
backup_file "${WAYBAR_CONFIG}"
backup_file "${WAYBAR_STYLE}"

write_user_file "${WAYBAR_CONFIG}" 0644 <<'EOF_WAYBAR'
{
    "layer": "top",
    "position": "top",
    "height": 32,
    "spacing": 8,

    "modules-left": [
        "niri/workspaces"
    ],

    "modules-center": [
        "clock"
    ],

    "modules-right": [
        "tray",
        "pulseaudio",
        "network",
        "battery"
    ],

    "niri/workspaces": {
        "all-outputs": false
    },

    "clock": {
        "format": "{:%a %d/%m  %H:%M}",
        "tooltip-format": "{:%Y-%m-%d %H:%M:%S}"
    },

    "pulseaudio": {
        "format": "VOL {volume}%",
        "format-muted": "MUTE",
        "on-click": "pavucontrol-qt"
    },

    "network": {
        "format-wifi": "WiFi {signalStrength}%",
        "format-ethernet": "ETH",
        "format-disconnected": "Offline",
        "tooltip-format": "{ifname}  {ipaddr}/{cidr}"
    },

    "battery": {
        "format": "BAT {capacity}%",
        "format-charging": "CHG {capacity}%"
    },

    "tray": {
        "spacing": 10
    }
}
EOF_WAYBAR

write_user_file "${WAYBAR_STYLE}" 0644 <<'EOF_CSS'
* {
    border: none;
    border-radius: 0;
    font-family: "Noto Sans", sans-serif;
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background: rgba(24, 24, 27, 0.95);
    color: #f4f4f5;
}

#workspaces button {
    padding: 0 9px;
    color: #a1a1aa;
    background: transparent;
}

#workspaces button.active,
#workspaces button.focused {
    color: #ffffff;
    background: #3f3f46;
}

#clock,
#pulseaudio,
#network,
#battery,
#tray {
    padding: 0 10px;
}
EOF_CSS

# ----------------------------
# Mako
# ----------------------------
log "Creating Mako configuration"
MAKO_CONFIG="${TARGET_HOME}/.config/mako/config"
backup_file "${MAKO_CONFIG}"
write_user_file "${MAKO_CONFIG}" 0644 <<'EOF_MAKO'
font=Noto Sans 11
default-timeout=5000
ignore-timeout=1
anchor=top-right
margin=10
padding=10
border-size=2
EOF_MAKO

# ----------------------------
# Swaylock
# ----------------------------
log "Creating Swaylock configuration"
SWAYLOCK_CONFIG="${TARGET_HOME}/.config/swaylock/config"
backup_file "${SWAYLOCK_CONFIG}"
write_user_file "${SWAYLOCK_CONFIG}" 0600 <<'EOF_SWAYLOCK'
color=111111
indicator-radius=90
indicator-thickness=8
show-failed-attempts
EOF_SWAYLOCK

# ----------------------------
# Fuzzel
# ----------------------------
log "Creating Fuzzel configuration"
FUZZEL_CONFIG="${TARGET_HOME}/.config/fuzzel/fuzzel.ini"
backup_file "${FUZZEL_CONFIG}"
write_user_file "${FUZZEL_CONFIG}" 0644 <<'EOF_FUZZEL'
[main]
font=Noto Sans:size=12
terminal=qterminal
width=45
lines=12
horizontal-pad=20
vertical-pad=12

[border]
width=2
radius=8
EOF_FUZZEL

# ----------------------------
# Default directory handler
# ----------------------------
log "Setting PCManFM-Qt as default file manager"
run_as_user xdg-mime default pcmanfm-qt.desktop inode/directory || true

# ----------------------------
# Final package/service checks
# ----------------------------
log "Installed versions"
pacman -Q niri sddm qt6-base qt5-base qterminal pcmanfm-qt 2>/dev/null || true

echo
printf '\033[1;32m============================================================\033[0m\n'
printf '\033[1;32m Installation complete.\033[0m\n'
printf '\033[1;32m============================================================\033[0m\n'
echo
cat <<EOF_DONE
User:          ${TARGET_USER}
Niri config:   ${NIRI_CONFIG}
Waybar config: ${WAYBAR_CONFIG}

Important shortcuts from Niri default config:
  Super+T          QTerminal
  Super+D          Fuzzel
  Super+Alt+L      Lock screen
  Super+Q          Close window
  Super+O          Overview
  Print            Screenshot region
  Ctrl+Print       Screenshot screen
  Alt+Print        Screenshot window
  Super+Shift+E    Exit Niri

Next:
  1. Reboot:
       sudo reboot

  2. In SDDM, choose the Niri session.

  3. Qt configuration tools:
       qt6ct
       qt5ct

Notes:
  - SDDM on current Arch uses Qt6 by default.
  - Qt5 packages are installed for compatibility and old Qt5 SDDM themes/apps.
  - Niri manages xwayland-satellite automatically when an X11 client appears.
EOF_DONE
