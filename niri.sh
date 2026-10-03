#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Arch Linux + Niri + DMS + LightDM + KDE/Qt apps
# Run as root
# ============================================================

USERNAME=$USER

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run as root."
    exit 1
fi

if ! id "$USERNAME" &>/dev/null; then
    echo "ERROR: User '$USERNAME' does not exist."
    echo "Edit USERNAME at the top of this script."
    exit 1
fi

USER_HOME=$HOME

echo "============================================"
echo " Installing Niri desktop for: $USERNAME"
echo " Home: $USER_HOME"
echo "============================================"


# ------------------------------------------------------------
# UPDATE
# ------------------------------------------------------------

pacman -Syu --noconfirm


# ------------------------------------------------------------
# LIGHTDM
# ------------------------------------------------------------

pacman -S --needed --noconfirm \
    lightdm \
    lightdm-gtk-greeter \
    lightdm-gtk-greeter-settings \
    accountsservice

mkdir -p /etc/lightdm/lightdm.conf.d

cat >/etc/lightdm/lightdm.conf.d/10-greeter.conf <<'EOF'
[Seat:*]
greeter-session=lightdm-gtk-greeter
user-session=niri
EOF


# ------------------------------------------------------------
# LIGHTDM GREETER THEME
# ------------------------------------------------------------

mkdir -p /etc/lightdm

cat >/etc/lightdm/lightdm-gtk-greeter.conf <<'EOF'
[greeter]
theme-name=Adwaita-dark
icon-theme-name=Papirus-Dark
font-name=Noto Sans 11
background=#111318
clock-format=%H:%M:%S
indicators=~host;~spacer;~clock;~spacer;~session;~language;~a11y;~power
EOF


# ------------------------------------------------------------
# NIRI + WAYLAND
# ------------------------------------------------------------

pacman -S --needed --noconfirm \
    niri \
    xwayland-satellite \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-gnome \
    wl-clipboard \
    cliphist \
    grim \
    slurp \
    wev


# ------------------------------------------------------------
# DMS
# ------------------------------------------------------------

pacman -S --needed --noconfirm \
    dms-shell-niri \
    matugen \
    cava \
    qt6-multimedia-ffmpeg


# ------------------------------------------------------------
# QT / KDE APPS
# ------------------------------------------------------------

pacman -S --needed --noconfirm \
    dolphin \
    dolphin-plugins \
    kate \
    konsole \
    ark \
    kio-extras \
    kio-admin \
    qt6ct \
    kvantum \
    breeze \
    breeze-icons \
    papirus-icon-theme


# ------------------------------------------------------------
# FILE / MOUNT / NETWORK INTEGRATION
# ------------------------------------------------------------

pacman -S --needed --noconfirm \
    udisks2 \
    udiskie \
    gvfs \
    gvfs-mtp \
    gvfs-smb \
    gvfs-nfs \
    ntfs-3g \
    exfatprogs


# ------------------------------------------------------------
# AUDIO
# ------------------------------------------------------------

pacman -S --needed --noconfirm \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    wireplumber \
    pavucontrol


# ------------------------------------------------------------
# NETWORK
# ------------------------------------------------------------

pacman -S --needed --noconfirm \
    networkmanager

systemctl enable NetworkManager.service


# ------------------------------------------------------------
# BLUETOOTH
# ------------------------------------------------------------

pacman -S --needed --noconfirm \
    bluez \
    bluez-utils

systemctl enable bluetooth.service


# ------------------------------------------------------------
# POLKIT / SECRET STORE
# ------------------------------------------------------------

pacman -S --needed --noconfirm \
    polkit \
    polkit-gnome \
    gnome-keyring \
    libsecret


# ------------------------------------------------------------
# BROWSER / MEDIA / OFFICE
# ------------------------------------------------------------

pacman -S --needed --noconfirm \
    firefox \
    vlc \
    okular \
    libreoffice-fresh


# ------------------------------------------------------------
# FONTS
# ------------------------------------------------------------

pacman -S --needed --noconfirm \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji \
    ttf-dejavu \
    ttf-liberation \
    ttf-jetbrains-mono-nerd


# ------------------------------------------------------------
# CLI / DEV TOOLS
# ------------------------------------------------------------

pacman -S --needed --noconfirm \
    git \
    curl \
    wget \
    unzip \
    zip \
    7zip \
    unrar \
    jq \
    tmux \
    btop \
    fastfetch


# ------------------------------------------------------------
# POWER / BRIGHTNESS
# ------------------------------------------------------------

pacman -S --needed --noconfirm \
    brightnessctl \
    power-profiles-daemon

systemctl enable power-profiles-daemon.service


# ------------------------------------------------------------
# USER DIRECTORIES
# ------------------------------------------------------------

pacman -S --needed --noconfirm xdg-user-dirs

runuser -u "$USERNAME" -- xdg-user-dirs-update

mkdir -p \
    "$USER_HOME/.config/niri" \
    "$USER_HOME/.config/qt6ct" \
    "$USER_HOME/Pictures/Screenshots" \
    "$USER_HOME/Pictures/Wallpapers"

chown -R "$USERNAME:$USERNAME" \
    "$USER_HOME/.config" \
    "$USER_HOME/Pictures"


# ------------------------------------------------------------
# QT ENVIRONMENT
# ------------------------------------------------------------

mkdir -p /etc/environment.d

cat >/etc/environment.d/90-qt.conf <<'EOF'
QT_QPA_PLATFORM=wayland;xcb
QT_QPA_PLATFORMTHEME=qt6ct
EOF


# ------------------------------------------------------------
# QT6CT
# ------------------------------------------------------------

cat >"$USER_HOME/.config/qt6ct/qt6ct.conf" <<'EOF'
[Appearance]
icon_theme=Papirus-Dark
style=kvantum-dark

[Fonts]
fixed=@Variant(\0\0\0@\0\0\0\x18\0J\0e\0t\0B\0r\0a\0i\0n\0s\0M\0o\0n\0o@(\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)
general=@Variant(\0\0\0@\0\0\0\x12\0N\0o\0t\0o\0 \0S\0a\0n\0s@(\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)

[Interface]
dialog_buttons_have_icons=1
menus_have_icons=true
EOF

chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config/qt6ct"


# ------------------------------------------------------------
# NIRI CONFIG
# ------------------------------------------------------------

cat >"$USER_HOME/.config/niri/config.kdl" <<'EOF'
input {
    keyboard {
        xkb {
            layout "us"
        }

        numlock
    }

    touchpad {
        tap
        natural-scroll
    }

    focus-follows-mouse max-scroll-amount="0%"
}


layout {
    gaps 14

    center-focused-column "never"

    preset-column-widths {
        proportion 0.33333
        proportion 0.5
        proportion 0.66667
    }

    default-column-width {
        proportion 0.5
    }

    focus-ring {
        width 3

        active-gradient from="#d9a7ff" to="#8fd9ff" angle=45
        inactive-color "#40364d"
    }

    border {
        off
    }

    shadow {
        on
        softness 24
        spread 3
        offset x=0 y=5
        color "#00000066"
    }
}


window-rule {
    geometry-corner-radius 14
    clip-to-geometry true
}


prefer-no-csd

screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"


spawn-at-startup "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
spawn-at-startup "udiskie"


binds {

    // --------------------------------------------------------
    // APPS
    // --------------------------------------------------------

    Mod+Return {
        spawn "konsole";
    }

    Alt+Return {
        spawn "konsole";
    }

    Mod+E {
        spawn "dolphin";
    }

    Mod+B {
        spawn "firefox";
    }

    Mod+Shift+K {
        spawn "kate";
    }


    // --------------------------------------------------------
    // DMS
    // --------------------------------------------------------

    Mod+Space {
        spawn "dms" "ipc" "call" "spotlight" "toggle";
    }


    // --------------------------------------------------------
    // WINDOW CONTROL
    // --------------------------------------------------------

    Mod+Q {
        close-window;
    }

    Mod+F {
        maximize-column;
    }

    Mod+Shift+F {
        fullscreen-window;
    }

    Mod+C {
        center-column;
    }


    // --------------------------------------------------------
    // FOCUS
    // --------------------------------------------------------

    Mod+H {
        focus-column-left;
    }

    Mod+L {
        focus-column-right;
    }

    Mod+J {
        focus-window-down;
    }

    Mod+K {
        focus-window-up;
    }

    Mod+Left {
        focus-column-left;
    }

    Mod+Right {
        focus-column-right;
    }

    Mod+Down {
        focus-window-down;
    }

    Mod+Up {
        focus-window-up;
    }


    // --------------------------------------------------------
    // MOVE
    // --------------------------------------------------------

    Mod+Ctrl+H {
        move-column-left;
    }

    Mod+Ctrl+L {
        move-column-right;
    }

    Mod+Ctrl+J {
        move-window-down;
    }

    Mod+Ctrl+K {
        move-window-up;
    }


    // --------------------------------------------------------
    // WORKSPACE
    // --------------------------------------------------------

    Mod+Page_Down {
        focus-workspace-down;
    }

    Mod+Page_Up {
        focus-workspace-up;
    }

    Mod+Ctrl+Page_Down {
        move-column-to-workspace-down;
    }

    Mod+Ctrl+Page_Up {
        move-column-to-workspace-up;
    }

    Mod+WheelScrollDown cooldown-ms=150 {
        focus-workspace-down;
    }

    Mod+WheelScrollUp cooldown-ms=150 {
        focus-workspace-up;
    }


    // --------------------------------------------------------
    // SIZE
    // --------------------------------------------------------

    Mod+R {
        switch-preset-column-width;
    }

    Mod+Minus {
        set-column-width "-10%";
    }

    Mod+Equal {
        set-column-width "+10%";
    }


    // --------------------------------------------------------
    // SCREENSHOTS
    // --------------------------------------------------------

    Print {
        screenshot;
    }

    Ctrl+Print {
        screenshot-screen;
    }

    Alt+Print {
        screenshot-window;
    }


    // --------------------------------------------------------
    // AUDIO
    // --------------------------------------------------------

    XF86AudioRaiseVolume allow-when-locked=true {
        spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05+";
    }

    XF86AudioLowerVolume allow-when-locked=true {
        spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05-";
    }

    XF86AudioMute allow-when-locked=true {
        spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle";
    }

    XF86AudioMicMute allow-when-locked=true {
        spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle";
    }


    // --------------------------------------------------------
    // BRIGHTNESS
    // --------------------------------------------------------

    XF86MonBrightnessUp allow-when-locked=true {
        spawn "brightnessctl" "set" "+10%";
    }

    XF86MonBrightnessDown allow-when-locked=true {
        spawn "brightnessctl" "set" "10%-";
    }


    // --------------------------------------------------------
    // EXIT
    // --------------------------------------------------------

    Mod+Shift+E {
        quit;
    }


    Mod+Shift+Slash {
        show-hotkey-overlay;
    }
}
EOF

chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config/niri"


# ------------------------------------------------------------
# ENABLE DMS FOR NIRI SESSION
# ------------------------------------------------------------

runuser -u "$USERNAME" -- \
    systemctl --user add-wants niri.service dms.service || true


# ------------------------------------------------------------
# IF USER BUS IS NOT AVAILABLE YET:
# create manual symlink fallback
# ------------------------------------------------------------

DMS_UNIT="$(find /usr/lib/systemd/user /usr/share/systemd/user \
    -maxdepth 1 -name dms.service 2>/dev/null | head -n1 || true)"

if [[ -n "$DMS_UNIT" ]]; then
    mkdir -p "$USER_HOME/.config/systemd/user/niri.service.wants"

    ln -sf "$DMS_UNIT" \
        "$USER_HOME/.config/systemd/user/niri.service.wants/dms.service"

    chown -R "$USERNAME:$USERNAME" \
        "$USER_HOME/.config/systemd"
fi


# ------------------------------------------------------------
# LIGHTDM: disable other display managers
# ------------------------------------------------------------

systemctl disable greetd.service 2>/dev/null || true
systemctl disable sddm.service 2>/dev/null || true
systemctl disable gdm.service 2>/dev/null || true

systemctl enable lightdm.service


# ------------------------------------------------------------
# VALIDATE NIRI
# ------------------------------------------------------------

echo
echo "Validating Niri config..."

if runuser -u "$USERNAME" -- \
    niri validate --config "$USER_HOME/.config/niri/config.kdl"; then
    echo "Niri config: OK"
else
    echo
    echo "ERROR: Niri config validation failed."
    exit 1
fi


# ------------------------------------------------------------
# VERIFY
# ------------------------------------------------------------

echo
echo "============================================"
echo " Verify"
echo "============================================"

command -v niri
command -v niri-session
command -v lightdm
command -v dolphin
command -v kate
command -v konsole
command -v dms

echo

test -f /usr/share/wayland-sessions/niri.desktop \
    && echo "Niri session: OK" \
    || echo "WARNING: niri.desktop not found"

echo

systemctl is-enabled lightdm.service
systemctl is-enabled NetworkManager.service


# ------------------------------------------------------------
# DONE
# ------------------------------------------------------------

echo
echo "============================================"
echo " DONE"
echo "============================================"
echo
echo "Desktop:"
echo "  LightDM"
echo "    -> Niri"
echo "       -> DMS"
echo "       -> Dolphin"
echo "       -> Kate"
echo "       -> Konsole"
echo
echo "Important keybinds:"
echo
echo "  Super + Enter    Konsole"
echo "  Alt   + Enter    Konsole fallback"
echo "  Super + E        Dolphin"
echo "  Super + B        Firefox"
echo "  Super + Shift+K  Kate"
echo "  Super + Space    DMS launcher"
echo "  Super + H/J/K/L  Focus"
echo "  Super + Q        Close window"
echo "  Super + F        Maximize column"
echo "  Print            Screenshot"
echo
echo "LightDM theme GUI:"
echo
echo "  lightdm-gtk-greeter-settings-pkexec"
echo
echo "Qt theme GUI:"
echo
echo "  qt6ct"
echo "  kvantummanager"
echo
echo "Reboot:"
echo
echo "  reboot"