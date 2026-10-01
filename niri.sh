#!/usr/bin/env bash

set -euo pipefail

USERNAME=$USER

[[ $EUID -eq 0 ]] || {
    echo "Run as root."
    exit 1
}

id "$USERNAME" &>/dev/null || {
    echo "User $USERNAME not found."
    exit 1
}

USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"

pacman -Syu --noconfirm

# ------------------------------------------------------------
# NIRI / WAYLAND / SHELL
# ------------------------------------------------------------

pacman -S --needed --noconfirm \
    niri \
    xwayland-satellite \
    xorg-xwayland \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-gnome \
    dms-shell-niri \
    matugen \
    cava \
    qt6-multimedia-ffmpeg \
    wl-clipboard \
    cliphist \
    grim \
    slurp


# ------------------------------------------------------------
# LOGIN
# ------------------------------------------------------------

pacman -S --needed --noconfirm \
    greetd \
    greetd-tuigreet

cat >/etc/greetd/config.toml <<'EOF'
[terminal]
vt = 2

[default_session]
command = "tuigreet --time --remember --remember-user-session --cmd niri-session"
user = "greeter"
EOF


# ------------------------------------------------------------
# AUDIO
# ------------------------------------------------------------

pacman -S --needed --noconfirm \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber \
    pavucontrol


# ------------------------------------------------------------
# NETWORK / BLUETOOTH
# ------------------------------------------------------------

pacman -S --needed --noconfirm \
    networkmanager \
    network-manager-applet \
    bluez \
    bluez-utils \
    blueman


# ------------------------------------------------------------
# DESKTOP INTEGRATION
# ------------------------------------------------------------

pacman -S --needed --noconfirm \
    polkit \
    polkit-gnome \
    gnome-keyring \
    libsecret \
    xdg-user-dirs


# ------------------------------------------------------------
# FILE MANAGER
# ------------------------------------------------------------

pacman -S --needed --noconfirm \
    nautilus \
    gvfs \
    gvfs-mtp \
    gvfs-smb \
    gvfs-nfs \
    udisks2 \
    udiskie \
    file-roller \
    gnome-disk-utility \
    ffmpegthumbnailer


# ------------------------------------------------------------
# APPLICATIONS
# ------------------------------------------------------------

pacman -S --needed --noconfirm \
    kitty \
    firefox \
    gnome-text-editor \
    loupe \
    evince \
    mpv \
    gnome-calculator \
    libreoffice-fresh


# ------------------------------------------------------------
# TOOLS
# ------------------------------------------------------------

pacman -S --needed --noconfirm \
    unzip \
    zip \
    p7zip \
    unrar \
    rsync \
    git \
    github-cli \
    curl \
    wget \
    jq \
    ripgrep \
    fd \
    fzf \
    tree \
    tmux \
    btop \
    htop \
    fastfetch


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
# POWER
# ------------------------------------------------------------

pacman -S --needed --noconfirm \
    brightnessctl \
    power-profiles-daemon


# ------------------------------------------------------------
# USER DIRECTORIES
# ------------------------------------------------------------

runuser -u "$USERNAME" -- xdg-user-dirs-update

mkdir -p "$USER_HOME/Pictures/Screenshots"

chown -R "$USERNAME:$USERNAME" \
    "$USER_HOME/Pictures"


# ------------------------------------------------------------
# NIRI CONFIG
# ------------------------------------------------------------

install -d \
    -o "$USERNAME" \
    -g "$USERNAME" \
    "$USER_HOME/.config/niri"


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
    gaps 12

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
        width 2
    }

    border {
        off
    }
}


spawn-at-startup "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
spawn-at-startup "udiskie"
spawn-at-startup "gnome-keyring-daemon" "--start" "--components=secrets"


prefer-no-csd

screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"


window-rule {
    geometry-corner-radius 8
    clip-to-geometry true
}


binds {

    Mod+Shift+Slash {
        show-hotkey-overlay;
    }

    Mod+Return {
        spawn "kitty";
    }

    Mod+T {
        spawn "kitty";
    }

    Mod+E {
        spawn "nautilus";
    }

    Mod+B {
        spawn "firefox";
    }

    Mod+Space {
        spawn "dms" "ipc" "call" "spotlight" "toggle";
    }


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


    Mod+R {
        switch-preset-column-width;
    }

    Mod+Minus {
        set-column-width "-10%";
    }

    Mod+Equal {
        set-column-width "+10%";
    }


    Print {
        screenshot;
    }

    Ctrl+Print {
        screenshot-screen;
    }

    Alt+Print {
        screenshot-window;
    }


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


    XF86MonBrightnessUp allow-when-locked=true {
        spawn "brightnessctl" "set" "+10%";
    }

    XF86MonBrightnessDown allow-when-locked=true {
        spawn "brightnessctl" "set" "10%-";
    }


    Mod+Shift+E {
        quit;
    }
}

EOF


chown -R \
    "$USERNAME:$USERNAME" \
    "$USER_HOME/.config/niri"


# ------------------------------------------------------------
# ENABLE DMS SCRIPT
# ------------------------------------------------------------

cat >"$USER_HOME/enable-dms.sh" <<'EOF'
#!/usr/bin/env bash

set -e

systemctl --user add-wants niri.service dms

echo
echo "DMS enabled."
echo "Logout/login lại để áp dụng."
EOF


chmod +x "$USER_HOME/enable-dms.sh"

chown \
    "$USERNAME:$USERNAME" \
    "$USER_HOME/enable-dms.sh"


# ------------------------------------------------------------
# SERVICES
# ------------------------------------------------------------

systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable greetd.service
systemctl enable power-profiles-daemon.service


# ------------------------------------------------------------
# VALIDATE
# ------------------------------------------------------------

runuser -u "$USERNAME" -- \
    niri validate \
    --config "$USER_HOME/.config/niri/config.kdl"


echo
echo "======================================"
echo " Arch + Niri desktop installed"
echo "======================================"
echo
echo "Reboot:"
echo
echo "    reboot"
echo
echo "Sau khi login Niri lần đầu:"
echo
echo "    ~/enable-dms.sh"
echo
echo "Sau đó logout/login lại."
echo