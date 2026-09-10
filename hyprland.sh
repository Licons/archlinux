#!/usr/bin/env bash

# Dừng script ngay nếu gặp lỗi
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== [1/7] Cập nhật toàn diện hệ thống & Cài đặt Packages từ Pacman Repo ==="
# sudo pacman -Syu --needed --noconfirm \
#     base-devel git fish 7-zip flatpak ufw \
#     hyprland waybar kitty swaybg swaync rofi \
#     grim slurp cliphist thunar qt5-wayland qt6-wayland polkit-gnome \
#     ttf-jetbrains-mono-nerd noto-fonts-cjk ttf-font-awesome papirus-icon-theme \
#     sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg libnotify \
#     fastfetch chafa hyprlock brightnessctl wireplumber networkmanager \
#     pavucontrol blueman btop python-requests mpd mpc ncmpcpp cava

echo "=== [2/7] Tạo cấu trúc thư mục cấu hình & Themes ==="
mkdir -p ~/.config/hypr/conf
mkdir -p ~/.config/hypr/scripts
mkdir -p ~/.config/hypr/themes
mkdir -p ~/.config/waybar/scripts
mkdir -p ~/.config/waybar/themes
mkdir -p ~/.config/kitty/themes
mkdir -p ~/.config/rofi/themes
mkdir -p ~/.config/{rofi,kitty,swaync,mpd,cava}
mkdir -p ~/Pictures/Screenshots ~/Music ~/.playlists

echo "=== [3/7] Tạo các bộ Preset Theme (Catppuccin Mocha & Tokyo Night) ==="

# 3.1. Hyprland Themes
cat << 'EOF' > ~/.config/hypr/themes/catppuccin.conf
general {
    col.active_border = rgba(f5c2e7ff) rgba(cba6f7ff) 45deg
    col.inactive_border = rgba(44475aaa)
}
EOF

cat << 'EOF' > ~/.config/hypr/themes/tokyonight.conf
general {
    col.active_border = rgba(7aa2f7ff) rgba(bb9af7ff) 45deg
    col.inactive_border = rgba(24283baa)
}
EOF

# 3.2. Waybar Themes
cat << 'EOF' > ~/.config/waybar/themes/catppuccin.css
@define-color bg rgba(30, 30, 46, 0.85);
@define-color card #313244;
@define-color text #cdd6f4;
@define-color accent #f5c2e7;
@define-color subaccent #cba6f7;
EOF

cat << 'EOF' > ~/.config/waybar/themes/tokyonight.css
@define-color bg rgba(26, 27, 38, 0.85);
@define-color card #24283b;
@define-color text #c0caf5;
@define-color accent #7aa2f7;
@define-color subaccent #bb9af7;
EOF

# 3.3. Kitty Themes
cat << 'EOF' > ~/.config/kitty/themes/catppuccin.conf
foreground #cdd6f4
background #1e1e2e
selection_foreground #1e1e2e
selection_background #f5e0dc
cursor #f5e0dc
color0 #45475a
color8 #585b70
color1 #f38ba8
color9 #f38ba8
color2 #a6e3a1
color10 #a6e3a1
color3 #f9e2af
color11 #f9e2af
color4 #89b4fa
color12 #89b4fa
color5 #f5c2e7
color13 #f5c2e7
color6 #94e2d5
color14 #94e2d5
color7 #bac2de
color15 #a6adc8
EOF

cat << 'EOF' > ~/.config/kitty/themes/tokyonight.conf
foreground #c0caf5
background #1a1b26
selection_foreground #1a1b26
selection_background #33467c
cursor #c0caf5
color0 #15161e
color8 #414868
color1 #f7768e
color9 #f7768e
color2 #9ece6a
color10 #9ece6a
color3 #e0af68
color11 #e0af68
color4 #7aa2f7
color12 #7aa2f7
color5 #bb9af7
color13 #bb9af7
color6 #7dcfff
color14 #7dcfff
color7 #a9b1d6
color15 #c0caf5
EOF

# 3.4. Rofi Themes
cat << 'EOF' > ~/.config/rofi/themes/catppuccin.rasi
* {
    bg: #1e1e2e;
    bg-alt: #313244;
    fg: #cdd6f4;
    accent: #f5c2e7;
}
EOF

cat << 'EOF' > ~/.config/rofi/themes/tokyonight.rasi
* {
    bg: #1a1b26;
    bg-alt: #24283b;
    fg: #c0caf5;
    accent: #7aa2f7;
}
EOF

# Kích hoạt mặc định Theme Catppuccin Mocha
cp ~/.config/hypr/themes/catppuccin.conf ~/.config/hypr/conf/colors.conf
cp ~/.config/waybar/themes/catppuccin.css ~/.config/waybar/themes/current.css
cp ~/.config/kitty/themes/catppuccin.conf ~/.config/kitty/themes/current.conf
cp ~/.config/rofi/themes/catppuccin.rasi ~/.config/rofi/themes/current.rasi

echo "=== [4/7] Tạo Cấu hình Hyprland Modular (.conf) & Hyprlock ==="

# 4.1. File chính Hyprland
cat << 'EOF' > ~/.config/hypr/hyprland.conf
source = ~/.config/hypr/conf/monitors.conf
source = ~/.config/hypr/conf/env.conf
source = ~/.config/hypr/conf/autostart.conf
source = ~/.config/hypr/conf/decorations.conf
source = ~/.config/hypr/conf/windowrules.conf
source = ~/.config/hypr/conf/keybindings.conf
source = ~/.config/hypr/conf/colors.conf
EOF

# 4.2. Màn hình
cat << 'EOF' > ~/.config/hypr/conf/monitors.conf
monitor=,preferred,auto,1

# Định dạng: monitor=name,resolution@refresh,position,scale
#monitor=DP-1, 1920x1080@144, 0x0, 1
#monitor=HDMI-A-1, 1920x1080@60, 1920x0, 1
EOF

# 4.3. Biến môi trường
cat << 'EOF' > ~/.config/hypr/conf/env.conf
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
env = QT_QPA_PLATFORM,wayland;xcb
env = GDK_BACKEND,wayland,x11,*

env = QT_IM_MODULE, fcitx
env = XMODIFIERS, @im=fcitx
env = INPUT_METHOD, fcitx
EOF

# 4.4. Autostart
cat << 'EOF' > ~/.config/hypr/conf/autostart.conf
exec-once = swaybg -i ~/Pictures/train.png -m fill
exec-once = waybar
exec-once = swaync
exec-once = mpd
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = fcitx5
exec-once = udiskie &
EOF

# 4.5. Decorations & Scrolling Layout
cat << 'EOF' > ~/.config/hypr/conf/decorations.conf
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    layout = scrolling
}

scrolling {
    column_width = 0.5
    fullscreen_on_one_column = true
    focus_fit_method = true
    wrap_swapcol = true
    direction = right
}

decoration {
    rounding = 14
    active_opacity = 0.95
    inactive_opacity = 0.85
    blur {
        enabled = true
        size = 6
        passes = 3
    }
    shadow {
        enabled = true
        range = 15
        color = rgba(1a1a1aee)
    }
}

animations {
    enabled = yes
    bezier = wind, 0.05, 0.9, 0.1, 1.05
    bezier = winIn, 0.1, 1.1, 0.1, 1.1
    bezier = winOut, 0.3, -0.3, 0, 1
    bezier = liner, 1, 1, 1, 1
    animation = windows, 1, 6, wind, slide
    animation = windowsIn, 1, 6, winIn, slide
    animation = windowsOut, 1, 5, winOut, slide
    animation = border, 1, 1, liner
    animation = borderangle, 1, 30, liner, loop
    animation = workspaces, 1, 5, wind, slidefade 20%
}
EOF

# 4.6. Window Rules (Cú pháp block chuẩn)
cat << 'EOF' > ~/.config/hypr/conf/windowrules.conf
# --- PAVUCONTROL (Volume) ---
windowrule {
    match = {
        class = ^(pavucontrol)$
    }
    float = true
    size = 650 450
    move = 100%-660 48
    pin = true
}

# --- BLUEMAN (Bluetooth) ---
windowrule {
    match = {
        class = ^(.blueman-manager-wrapped)$
    }
    float = true
    size = 500 400
    move = 100%-510 48
    pin = true
}

# --- FLOATING BTOP ---
windowrule {
    match = {
        class = ^(floating_btop)$
    }
    float = true
    size = 900 600
    center = true
}

# --- FLOATING NCMPCPP ---
windowrule {
    match = {
        class = ^(floating_ncmpcpp)$
    }
    float = true
    size = 850 520
    center = true
}

# --- FLOATING CAVA ---
windowrule {
    match = {
        class = ^(floating_cava)$
    }
    float = true
    size = 800 350
    center = true
}

# --- MS TEAMS (App & Popups/Meetings) ---
windowrule {
    match = {
        class = ^(com\.github\.IsmaelMartinez\.teams_for_linux)$
    }
    float = true
}

windowrule {
    match = {
        title = ^(Microsoft Teams.*)$
    }
    float = true
    center = true
}

windowrule {
    match = {
        class = ^(com\.github\.IsmaelMartinez\.teams_for_linux)$
        title = ^(Choose.*|Open.*|Save.*)$
    }
    float = true
    center = true
}
EOF

# 4.7. Keybindings
cat << 'EOF' > ~/.config/hypr/conf/keybindings.conf
$mainMod = SUPER

bind = $mainMod, RETURN, exec, kitty
bind = $mainMod, E, exec, thunar
bind = $mainMod, SPACE, exec, rofi -show drun
bind = $mainMod, N, exec, swaync-client -t -sw
bind = $mainMod, L, exec, hyprlock
bind = $mainMod, X, exec, ~/.config/rofi/powermenu.sh
bind = $mainMod, W, exec, ~/.config/hypr/scripts/change_theme.sh
bind = $mainMod SHIFT, T, exec, ~/.config/hypr/scripts/switch_theme.sh
bind = $mainMod SHIFT, M, exec, kitty --class floating_cava -e cava

bind = , PRINT, exec, mkdir -p ~/Pictures/Screenshots && grim -g "$(slurp)" - | wl-copy && wl-paste > ~/Pictures/Screenshots/Screenshot_$(date +'%Y%m%d_%H%M%S').png

bind = $mainMod, Q, closewindow
bind = $mainMod, V, togglefloating
bind = $mainMod, F, fullscreen

bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5

bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5

bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

bindel = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bindel = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindl  = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindel = , XF86MonBrightnessUp, exec, brightnessctl set +5%
bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
EOF

# 4.8. Hyprlock Config
cat << 'EOF' > ~/.config/hypr/hyprlock.conf
background {
    monitor =
    path = ~/Pictures/train.png
    blur_passes = 3
    blur_size = 7
}

input-field {
    monitor =
    size = 260, 50
    outline_thickness = 3
    outer_color = rgba(245, 194, 231, 1.0)
    inner_color = rgba(49, 50, 68, 0.8)
    font_color = rgb(205, 214, 244)
    fade_on_empty = false
    placeholder_text = <span foreground="##cdd6f4">󰌾 <i>Enter Password...</i></span>
    position = 0, -100
    halign = center
    valign = center
}

label {
    monitor =
    text = cmd[update:1000] echo "$TIME"
    color = rgba(245, 194, 231, 1.0)
    font_size = 64
    font_family = JetBrainsMono Nerd Font
    position = 0, 100
    halign = center
    valign = center
}

label {
    monitor =
    text = Okaeri, $USER 🌸
    color = rgba(203, 166, 247, 1.0)
    font_size = 20
    font_family = JetBrainsMono Nerd Font
    position = 0, 10
    halign = center
    valign = center
}
EOF

echo "=== [5/7] Thiết lập Giao diện hỗ trợ Import Theme Động ==="

# 5.1. Waybar Config
cat << 'EOF' > ~/.config/waybar/config.jsonc
{
    "layer": "top",
    "position": "top",
    "height": 36,
    "margin-top": 6,
    "margin-left": 10,
    "margin-right": 10,
    "modules-left": ["hyprland/workspaces", "mpd"],
    "modules-center": ["clock", "custom/weather"],
    "modules-right": ["custom/theme", "backlight", "pulseaudio", "bluetooth", "network", "custom/disk", "custom/power", "tray"],

    "hyprland/workspaces": {
        "format": "{icon}",
        "format-icons": { "active": "🌸", "default": "🪷" }
    },
    "mpd": {
        "format": "{stateIcon} {artist} - {title}",
        "state-icons": { "paused": "󰏤", "playing": "󰐊" },
        "on-click": "kitty --class floating_ncmpcpp -e ncmpcpp",
        "on-click-right": "mpc toggle"
    },
    "clock": {
        "format": "󰥔 {:%H:%M - %d/%m}",
        "tooltip-format": "<tt><small>{calendar}</small></tt>"
    },
    "custom/weather": {
        "format": "{}",
        "return-type": "json",
        "exec": "~/.config/waybar/scripts/weather.py",
        "interval": 1800
    },
    "custom/theme": {
        "format": "🎨",
        "on-click": "~/.config/hypr/scripts/switch_theme.sh",
        "tooltip-format": "Đổi Theme Giao Diện"
    },
    "backlight": {
        "format": "{icon} {percent}%",
        "format-icons": ["󰃞", "󰃟", "󰃠"],
        "on-scroll-up": "brightnessctl set +5%",
        "on-scroll-down": "brightnessctl set 5%-"
    },
    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-icons": { "default": ["󰕿", "󰖀", "󰕾"] },
        "on-click": "pavucontrol"
    },
    "bluetooth": {
        "format": "󰂯",
        "on-click": "blueman-manager"
    },
    "network": {
        "format-wifi": "󰤨",
        "format-disconnected": "󰤭",
        "on-click": "~/.config/rofi/wifi-menu.sh"
    },
    "custom/disk": {
        "format": "󰋊",
        "on-click": "kitty --class floating_btop -e btop"
    },
    "custom/power": {
        "format": "󰐥",
        "on-click": "~/.config/rofi/powermenu.sh"
    },
    "tray": {
        "icon-size": 16,
        "spacing": 10
    }
}
EOF

# 5.2. Waybar Style
cat << 'EOF' > ~/.config/waybar/style.css
@import "themes/current.css";

* {
    font-family: "JetBrainsMono Nerd Font", "Noto Sans CJK JP", sans-serif;
    font-size: 13px;
    font-weight: bold;
    border: none;
}

window#waybar {
    background-color: @bg;
    color: @text;
    border-radius: 16px;
}

#workspaces button {
    padding: 0 8px;
    color: @accent;
}

#workspaces button.active {
    background-color: @accent;
    color: #11111b;
    border-radius: 12px;
}

#mpd, #clock, #custom-weather, #custom-theme, #backlight, #pulseaudio, #bluetooth, #network, #custom-disk, #custom-power {
    background-color: @card;
    padding: 4px 12px;
    margin: 4px 3px;
    border-radius: 12px;
    color: @subaccent;
}
EOF

# 5.3. Kitty Config
cat << 'EOF' > ~/.config/kitty/kitty.conf
font_family      JetBrainsMono Nerd Font
font_size        11.0
window_padding_width 12
background_opacity   0.85
confirm_os_window_close 0

include themes/current.conf
EOF

# 5.4. Rofi Config
cat << 'EOF' > ~/.config/rofi/config.rasi
@import "themes/current.rasi"

configuration {
    modi: "drun,run";
    show-icons: true;
    icon-theme: "Papirus";
    font: "JetBrainsMono Nerd Font 11";
}
@theme "/dev/null"

window {
    location: center;
    width: 550px;
    border: 2px;
    border-color: @accent;
    border-radius: 16px;
    background-color: @bg;
    padding: 20px;
}
inputbar {
    background-color: @bg-alt;
    border-radius: 12px;
    padding: 10px 14px;
    children: [ entry ];
}
entry { text-color: @accent; placeholder: "Search..."; }
listview { lines: 7; columns: 1; margin: 15px 0 0 0; spacing: 6px; }
element { padding: 8px 12px; border-radius: 10px; }
element selected { background-color: @accent; text-color: #11111b; }
EOF

# 5.5. SwayNC Config & Style
cat << 'EOF' > ~/.config/swaync/config.json
{
  "positionX": "right",
  "positionY": "top",
  "control-center-width": 380,
  "widgets": ["title", "dnd", "notifications", "mpris", "volume", "backlight"]
}
EOF

cat << 'EOF' > ~/.config/swaync/style.css
.control-center {
  background: rgba(30, 30, 46, 0.85);
  border: 2px solid #f5c2e7;
  border-radius: 16px;
  padding: 14px;
  color: #cdd6f4;
}
.notification {
  background: #313244;
  border: 1px solid #cba6f7;
  border-radius: 12px;
}
EOF

# 5.6. MPD & Cava
cat << 'EOF' > ~/.config/mpd/mpd.conf
music_directory    "~/Music"
playlist_directory "~/.playlists"
db_file            "~/.config/mpd/database"
log_file           "~/.config/mpd/log"
pid_file           "~/.config/mpd/pid"
state_file         "~/.config/mpd/state"

audio_output {
    type            "pipewire"
    name            "PipeWire Sound Server"
}
EOF

cat << 'EOF' > ~/.config/cava/config
[general]
framerate = 60
bar_width = 2
bar_spacing = 1
[input]
method = pipewire
source = auto
[output]
method = ncurses
[color]
gradient = 1
gradient_count = 8
gradient_color_1 = '#89b4fa'
gradient_color_2 = '#74c7ec'
gradient_color_3 = '#89dceb'
gradient_color_4 = '#94e2d5'
gradient_color_5 = '#a6e3a1'
gradient_color_6 = '#f9e2af'
gradient_color_7 = '#fab387'
gradient_color_8 = '#f5c2e7'
EOF

echo "=== [6/7] Tạo các Helper Scripts (Theme Switcher, Power Menu, Wi-Fi, Weather, Wallpaper) ==="

# 6.1. Script Switch Theme (Catppuccin Mocha <-> Tokyo Night)
cat << 'EOF' > ~/.config/hypr/scripts/switch_theme.sh
#!/usr/bin/env bash

THEME=$(echo -e "🌸 Catppuccin Mocha\n🌃 Tokyo Night" | rofi -dmenu -i -p "🎨 Select Theme:" -theme-str 'window {width: 320px;} listview {lines: 2;}')

case "$THEME" in
    *"Catppuccin Mocha"*)
        CHOICE="catppuccin"
        ;;
    *"Tokyo Night"*)
        CHOICE="tokyonight"
        ;;
    *)
        exit 0
        ;;
esac

# Update Configs
cp ~/.config/hypr/themes/${CHOICE}.conf ~/.config/hypr/conf/colors.conf
cp ~/.config/waybar/themes/${CHOICE}.css ~/.config/waybar/themes/current.css
cp ~/.config/kitty/themes/${CHOICE}.conf ~/.config/kitty/themes/current.conf
cp ~/.config/rofi/themes/${CHOICE}.rasi ~/.config/rofi/themes/current.rasi

# Reload
hyprctl reload
pkill -SIGUSR2 waybar
killall -SIGUSR1 kitty 2>/dev/null || true

notify-send "Theme Switcher" "Đã chuyển sang theme: $CHOICE" -i preferences-desktop-theme
EOF

# 6.2. Rofi Power Menu
cat << 'EOF' > ~/.config/rofi/powermenu.sh
#!/usr/bin/env bash

lock="󰌾 Lock"
logout="󰍃 Logout"
suspend="󰤄 Suspend"
reboot="󰜉 Reboot"
shutdown="󰐥 Shutdown"

options="$lock\n$logout\n$suspend\n$reboot\n$shutdown"

chosen=$(echo -e "$options" | rofi -dmenu -i -p "Power" -theme-str 'window {width: 280px;} listview {lines: 5;}')

case "$chosen" in
    "$lock") hyprlock ;;
    "$logout") hyprctl dispatch exit ;;
    "$suspend") systemctl suspend ;;
    "$reboot") systemctl reboot ;;
    "$shutdown") systemctl poweroff ;;
esac
EOF

# 6.3. Wi-Fi Menu
cat << 'EOF' > ~/.config/rofi/wifi-menu.sh
#!/usr/bin/env bash
location=$(nmcli -t -f SSID dev wifi list | grep -v '^$' | uniq)
chosen_network=$(echo "$location" | rofi -dmenu -i -p "󰤨 Wi-Fi: " -theme-str 'window {width: 400px;}')
if [ -n "$chosen_network" ]; then
    saved_connections=$(nmcli -g NAME connection)
    if echo "$saved_connections" | grep -w "$chosen_network" > /dev/null; then
        nmcli connection up id "$chosen_network"
    else
        password=$(rofi -dmenu -p "󰌾 Password: " -theme-str 'window {width: 400px;}')
        nmcli dev wifi connect "$chosen_network" password "$password"
    fi
fi
EOF

# 6.4. Weather Script
cat << 'EOF' > ~/.config/waybar/scripts/weather.py
#!/usr/bin/env python3
import requests, json
try:
    res = requests.get("https://wttr.in/?format=j1", timeout=5).json()
    curr = res["current_condition"][0]
    output = {
        "text": f"󰖕 {curr['temp_C']}°C",
        "tooltip": f"🌤️ Status: {curr['weatherDesc'][0]['value']}\n🌡️ Feels like: {curr['FeelsLikeC']}°C"
    }
    print(json.dumps(output))
except Exception:
    print(json.dumps({"text": "󰖕 N/A", "tooltip": "Offline"}))
EOF

# 6.5. Change Wallpaper Script
cat << 'EOF' > ~/.config/hypr/scripts/change_theme.sh
#!/usr/bin/env bash
BG_DIR="$HOME/Pictures"
IMAGE=$(find "$BG_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) | rofi -dmenu -i -p "🖼️ Choose Wallpaper:")

if [ -n "$IMAGE" ]; then
    pkill swaybg
    swaybg -i "$IMAGE" -m fill &
fi
EOF

# Phân quyền thực thi
chmod +x ~/.config/hypr/scripts/switch_theme.sh
chmod +x ~/.config/hypr/scripts/change_theme.sh
chmod +x ~/.config/rofi/powermenu.sh
chmod +x ~/.config/rofi/wifi-menu.sh
chmod +x ~/.config/waybar/scripts/weather.py

echo "=== [7/7] Cấu hình SDDM, Phân quyền & Công cụ bổ trợ ==="
sudo usermod -aG video $USER
sudo chmod +s $(which brightnessctl) 2>/dev/null || true

chsh -s /usr/bin/fish $USER

echo
echo
read -p "Your GPU is Nvidia (y/n): " NVIDIA_FLAG
read -p "Your Nvidia GPU is 10xx series (y/n): " GPU_10XX

case $GPU_10XX in
    [Yy])
        echo "=== Cài đặt Yay & Driver Nvidia 580xx cho GTX 10xx ==="
        git clone https://aur.archlinux.org/yay.git /tmp/yay || true
        cd /tmp/yay
        makepkg -si --noconfirm

        cd $SCRIPT_DIR
        yay -S --noconfirm \
            nvidia-580xx-dkms nvidia-580xx-settings \
            nvidia-580xx-utils opencl-nvidia-580xx \
            lib32-nvidia-580xx-utils
        ;;
    *)
        echo "Bỏ qua cài đặt driver Nvidia tùy chỉnh qua AUR."
        ;;
esac

case $NVIDIA_FLAG in
    [Yy])
        cat << 'EOF' >> ~/.config/hypr/hyprland.conf

# --- NVIDIA CONFIG ---
env = LIBVA_DRIVER_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
EOF
        ;;
esac

mkdir -p ~/Pictures
if [ -f "pictures/train.png" ]; then
    cp -f pictures/train.png ~/Pictures/
fi

sudo git clone https://github.com/keyitdev/sddm-flower-theme.git /usr/share/sddm/themes/sddm-flower-theme
sudo cp /usr/share/sddm/themes/sddm-flower-theme/Fonts/* /usr/share/fonts/
echo "[Theme]
Current=sddm-flower-theme" | sudo tee /etc/sddm.conf

# echo "   Installing gittyup"
# git clone https://aur.archlinux.org/gittyup.git
# cd gittyup
# makepkg -si

echo "================================================="
echo "   Installing MS Teams via Flatpak"
echo "================================================="
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
flatpak install flathub com.github.IsmaelMartinez.teams_for_linux -y || true

echo "=========================================================="
echo " HOÀN TẤT CÀI ĐẶT HYPRLAND (.CONF + SCROLLING) THÀNH CÔNG!"
echo "=========================================================="
