#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# Arch Linux Base -> Hyprland 0.56.x Anime Desktop
# Modular Hyprland Lua config + Quickshell KDE-like bar
# Themes: Catppuccin Pastel / Tokyo Night
# ============================================================

log()  { printf '\033[1;35m[hypr-anime]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warning]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -ne 0 ]] || die "Run this script as your normal user, NOT root."
command -v sudo >/dev/null || die "sudo is required."
command -v pacman >/dev/null || die "This installer is for Arch Linux."

USER_HOME="$HOME"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN="$HOME/.local/bin"
WALL="$HOME/Pictures/Wallpapers"
HYPR="$CFG/hypr"
QS="$CFG/quickshell"
ROFI="$CFG/rofi"
SWAYNC="$CFG/swaync"
KITTY="$CFG/kitty"
BACKUP="$HOME/.config-backup-hypr-full-$(date +%Y%m%d-%H%M%S)"

log "Cleaning up existing configs..."
rm -frv $CFG

log "Updating Arch..."
sudo pacman -Syu --noconfirm --needed

PACKAGES=(
  hyprland
  xdg-desktop-portal
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk
  xorg-xwayland
  wayland-utils

  sddm

  quickshell
  qt6-base
  qt6-declarative
  qt6-svg
  qt6-wayland

  rofi
  swaync
  nwg-displays

  networkmanager
  network-manager-applet
  bluez
  bluez-utils
  blueman

  pipewire
  pipewire-audio
  pipewire-pulse
  wireplumber
  pavucontrol

  power-profiles-daemon
  upower
  brightnessctl
  playerctl

  hyprlock
  hypridle

  awww

  wl-clipboard
  cliphist

  grim
  slurp
  swappy

  kitty
  thunar
  firefox
  gvfs
  gvfs-mtp
  tumbler
  zed

  polkit-gnome

  xdg-user-dirs
  xdg-utils

  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
  ttf-jetbrains-mono-nerd
  papirus-icon-theme
  adw-gtk-theme
  nwg-look
  qt6ct

  jq
  imagemagick
  libnotify
  wev
)

log "Installing packages..."
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

log "Enabling services..."
sudo systemctl enable sddm.service
sudo systemctl enable NetworkManager.service
sudo systemctl enable bluetooth.service
sudo systemctl enable power-profiles-daemon.service 2>/dev/null || true

mkdir -p \
  "$HYPR/config" \
  "$HYPR/themes" \
  "$QS" \
  "$ROFI" \
  "$SWAYNC" \
  "$KITTY/themes" \
  "$BIN" \
  "$WALL" \
  "$HOME/.cache"

xdg-user-dirs-update || true

# ============================================================
# Wallpapers
# ============================================================
log "Creating bundled wallpapers..."

cat > /tmp/catppuccin-pastel.svg <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="2560" height="1440">
<defs>
 <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
  <stop offset="0" stop-color="#1e1e2e"/>
  <stop offset=".5" stop-color="#45475a"/>
  <stop offset="1" stop-color="#f5c2e7"/>
 </linearGradient>
</defs>
<rect width="2560" height="1440" fill="url(#g)"/>
<circle cx="1950" cy="330" r="190" fill="#f9e2af"/>
<circle cx="1880" cy="280" r="190" fill="#313244" opacity=".35"/>
<path d="M0 1100 Q500 850 1000 1100 T2000 1050 T2560 1100 V1440 H0Z" fill="#181825"/>
<path d="M0 1200 Q600 980 1200 1210 T2400 1160 T2560 1200 V1440 H0Z" fill="#11111b"/>
<g fill="#f5c2e7">
 <circle cx="280" cy="280" r="12"/><circle cx="370" cy="340" r="8"/>
 <circle cx="470" cy="250" r="10"/><circle cx="2250" cy="760" r="12"/>
</g>
<text x="150" y="1290" fill="#cdd6f4" font-size="70" font-family="sans-serif">PASTEL DREAM</text>
<text x="155" y="1350" fill="#f5c2e7" font-size="28" font-family="sans-serif">catppuccin • anime moonlight</text>
</svg>
EOF

cat > /tmp/tokyo-night.svg <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="2560" height="1440">
<defs>
 <linearGradient id="g" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#16161e"/>
  <stop offset=".6" stop-color="#24283b"/>
  <stop offset="1" stop-color="#101014"/>
 </linearGradient>
</defs>
<rect width="2560" height="1440" fill="url(#g)"/>
<circle cx="1880" cy="330" r="175" fill="#e0af68"/>
<g fill="#1f2335">
 <rect x="80" y="610" width="270" height="480"/>
 <rect x="400" y="690" width="330" height="400"/>
 <rect x="790" y="520" width="300" height="570"/>
 <rect x="1150" y="640" width="270" height="450"/>
 <rect x="1480" y="540" width="340" height="550"/>
 <rect x="1880" y="670" width="260" height="420"/>
 <rect x="2190" y="550" width="300" height="540"/>
</g>
<path d="M0 1120 C500 1020 800 1280 1300 1150 S2100 1040 2560 1180" fill="none" stroke="#bb9af7" stroke-width="12"/>
<path d="M0 1160 C550 1050 900 1300 1400 1190 S2150 1080 2560 1220" fill="none" stroke="#7aa2f7" stroke-width="6"/>
<text x="150" y="1290" fill="#c0caf5" font-size="70" font-family="sans-serif">TOKYO NIGHT</text>
<text x="155" y="1350" fill="#7aa2f7" font-size="28" font-family="sans-serif">neon city • anime midnight</text>
</svg>
EOF

magick /tmp/catppuccin-pastel.svg "$WALL/catppuccin-pastel.png"
magick /tmp/tokyo-night.svg "$WALL/tokyo-night.png"
rm -f /tmp/catppuccin-pastel.svg /tmp/tokyo-night.svg

# ============================================================
# Themes
# ============================================================
cat > "$HYPR/themes/catppuccin-pastel.lua" <<'EOF'
return {
  name = "catppuccin-pastel",
  active = 0xffcba6f7,
  inactive = 0xff45475a,
  shadow = 0xaa11111b,
}
EOF

cat > "$HYPR/themes/tokyo-night.lua" <<'EOF'
return {
  name = "tokyo-night",
  active = 0xff7aa2f7,
  inactive = 0xff414868,
  shadow = 0xaa101014,
}
EOF

cp "$HYPR/themes/catppuccin-pastel.lua" "$HYPR/theme.lua"
printf 'catppuccin-pastel\n' > "$HYPR/.theme"
printf '%s\n' "$WALL/catppuccin-pastel.png" > "$HOME/.cache/hypr-current-wallpaper"
printf 'file://%s\n' "$WALL/catppuccin-pastel.png" > "$HOME/.cache/hypr-popup-wallpaper"

cat > "$BIN/ui-theme-sync" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
THEME="$(cat "$CFG/hypr/.theme" 2>/dev/null || echo catppuccin-pastel)"
WALL="$(cat "$HOME/.cache/hypr-current-wallpaper" 2>/dev/null || true)"

if [[ ! -f "$WALL" ]]; then
  case "$THEME" in
    tokyo-night) WALL="$HOME/Pictures/Wallpapers/tokyo-night.png" ;;
    *) WALL="$HOME/Pictures/Wallpapers/catppuccin-pastel.png" ;;
  esac
fi

printf 'file://%s\n' "$WALL" > "$HOME/.cache/hypr-popup-wallpaper"

case "$THEME" in
  tokyo-night)
    BG="#1A1B26E8"; BG2="#24283BEF"; FG="#C0CAF5FF"
    MUTED="#565F89FF"; ACCENT="#7AA2F7FF"; ACCENT2="#BB9AF7FF"
    SEL="#101014FF"; BORDER="#BB9AF7AA"
    cat > "$CFG/quickshell/theme.js" <<'JS'
.pragma library
var bg="#E61A1B26"
var surface="#F224283B"
var surface2="#F2414868"
var text="#C0CAF5"
var subtext="#A9B1D6"
var muted="#565F89"
var accent="#7AA2F7"
var accent2="#BB9AF7"
var danger="#F7768E"
var border="#80565F89"
JS
    cat > "$CFG/kitty/theme.conf" <<'KITTY'
foreground #c0caf5
background #1a1b26
selection_foreground #1a1b26
selection_background #7aa2f7
cursor #c0caf5
color0 #414868
color1 #f7768e
color2 #9ece6a
color3 #e0af68
color4 #7aa2f7
color5 #bb9af7
color6 #7dcfff
color7 #a9b1d6
KITTY
    ;;
  *)
    BG="#1E1E2EE8"; BG2="#313244EF"; FG="#CDD6F4FF"
    MUTED="#A6ADC8FF"; ACCENT="#CBA6F7FF"; ACCENT2="#F5C2E7FF"
    SEL="#11111BFF"; BORDER="#F5C2E7AA"
    cat > "$CFG/quickshell/theme.js" <<'JS'
.pragma library
var bg="#E61E1E2E"
var surface="#F2313244"
var surface2="#F245475A"
var text="#CDD6F4"
var subtext="#BAC2DE"
var muted="#7F849C"
var accent="#CBA6F7"
var accent2="#F5C2E7"
var danger="#F38BA8"
var border="#806C7086"
JS
    cat > "$CFG/kitty/theme.conf" <<'KITTY'
foreground #cdd6f4
background #1e1e2e
selection_foreground #1e1e2e
selection_background #f5c2e7
cursor #f5e0dc
color0 #45475a
color1 #f38ba8
color2 #a6e3a1
color3 #f9e2af
color4 #89b4fa
color5 #cba6f7
color6 #94e2d5
color7 #bac2de
KITTY
    ;;
esac

cat > "$CFG/rofi/current.rasi" <<RASI
* {
  bg: $BG;
  bg2: $BG2;
  fg: $FG;
  muted: $MUTED;
  accent: $ACCENT;
  accent2: $ACCENT2;
  selectfg: $SEL;
  borderc: $BORDER;
}
window {
  width: 680px;
  location: center;
  anchor: center;
  border: 2px;
  border-color: @borderc;
  border-radius: 22px;
  padding: 0px;
  background-color: transparent;
  background-image: url("$WALL", both);
}
mainbox {
  padding: 18px;
  spacing: 13px;
  background-color: @bg;
  border-radius: 20px;
}
inputbar {
  padding: 12px 15px;
  spacing: 10px;
  border-radius: 14px;
  background-color: @bg2;
  text-color: @fg;
}
prompt {
  text-color: @accent2;
  font: "JetBrainsMono Nerd Font Bold 13";
}
entry {
  text-color: @fg;
  placeholder-color: @muted;
}
listview {
  lines: 9;
  columns: 1;
  spacing: 6px;
  scrollbar: false;
  background-color: transparent;
}
element {
  padding: 10px 12px;
  spacing: 10px;
  border-radius: 13px;
  text-color: @fg;
}
element selected.normal,
element selected.active {
  background-color: @accent;
  text-color: @selectfg;
}
element-icon { size: 30px; }
element-text { text-color: inherit; }
RASI
EOF
chmod +x "$BIN/ui-theme-sync"

# ============================================================
# Utility scripts
# ============================================================
cat > "$BIN/hypr-theme" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
export LANG=C.UTF-8 LC_ALL=C.UTF-8
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"

choice="$(printf 'Catppuccin Pastel\nTokyo Night\n' | \
  "$HOME/.local/bin/rofi-safe" -dmenu -i -p ' Theme' \
  -theme "$CFG/rofi/current.rasi")"
[[ -n "$choice" ]] || exit 0

case "$choice" in
  "Tokyo Night")
    slug="tokyo-night"
    wall="$HOME/Pictures/Wallpapers/tokyo-night.png"
    ;;
  *)
    slug="catppuccin-pastel"
    wall="$HOME/Pictures/Wallpapers/catppuccin-pastel.png"
    ;;
esac

printf '%s\n' "$slug" > "$CFG/hypr/.theme"
cp "$CFG/hypr/themes/$slug.lua" "$CFG/hypr/theme.lua"
printf '%s\n' "$wall" > "$HOME/.cache/hypr-current-wallpaper"
printf 'file://%s\n' "$wall" > "$HOME/.cache/hypr-popup-wallpaper"

pgrep -x awww-daemon >/dev/null || { awww-daemon >/dev/null 2>&1 & sleep 0.3; }
awww img "$wall" \
  --transition-type wave \
  --transition-duration 1.1 \
  --transition-fps 60 \
  --transition-angle 25 || true

"$HOME/.local/bin/ui-theme-sync"
hyprctl reload >/dev/null 2>&1 || true
notify-send -a "Hypr Anime" "Theme" "$choice"
EOF

cat > "$BIN/hypr-wallpaper" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
export LANG=C.UTF-8 LC_ALL=C.UTF-8

DIR="$HOME/Pictures/Wallpapers"
mapfile -d '' files < <(
  find "$DIR" -maxdepth 1 -type f \
  \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
  -print0 | sort -z
)
((${#files[@]})) || exit 0

menu=""
for f in "${files[@]}"; do menu+="$(basename "$f")"$'\n'; done

choice="$(printf '%s' "$menu" | \
  "$HOME/.local/bin/rofi-safe" -dmenu -i -p '󰸉 Wallpaper' \
  -theme "$HOME/.config/rofi/current.rasi")"
[[ -n "$choice" ]] || exit 0

wall="$DIR/$choice"
printf '%s\n' "$wall" > "$HOME/.cache/hypr-current-wallpaper"
printf 'file://%s\n' "$wall" > "$HOME/.cache/hypr-popup-wallpaper"

pgrep -x awww-daemon >/dev/null || { awww-daemon >/dev/null 2>&1 & sleep 0.3; }
awww img "$wall" \
  --transition-type grow \
  --transition-pos center \
  --transition-duration 1.0 \
  --transition-fps 60 || true

"$HOME/.local/bin/ui-theme-sync"
EOF

cat > "$BIN/hypr-power" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
export LANG=C.UTF-8 LC_ALL=C.UTF-8

choice="$(printf '󰌾  Lock\n󰤄  Sleep\n󰜉  Reboot\n󰐥  Shutdown\n󰍃  Logout\n' | \
  "$HOME/.local/bin/rofi-safe" -dmenu -i -p '󰐥 Power' \
  -theme "$HOME/.config/rofi/current.rasi")"

case "$choice" in
  *Lock*) hyprlock ;;
  *Sleep*) systemctl suspend ;;
  *Reboot*) systemctl reboot ;;
  *Shutdown*) systemctl poweroff ;;
  *Logout*) command -v hyprshutdown >/dev/null && hyprshutdown || hyprctl dispatch exit ;;
esac
EOF

cat > "$BIN/hypr-power-manager" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
export LANG=C.UTF-8 LC_ALL=C.UTF-8

current="$(powerprofilesctl get 2>/dev/null || echo balanced)"
choice="$(printf '󰌪  Power Saver\n󰾅  Balanced\n󰓅  Performance\n󰤄  Sleep now\n󰌾  Lock now\n' | \
  "$HOME/.local/bin/rofi-safe" -dmenu -i -p "󰾅 $current" \
  -theme "$HOME/.config/rofi/current.rasi")"

case "$choice" in
  *Saver*) powerprofilesctl set power-saver ;;
  *Balanced*) powerprofilesctl set balanced ;;
  *Performance*) powerprofilesctl set performance ;;
  *Sleep*) systemctl suspend ;;
  *Lock*) hyprlock ;;
esac
EOF

cat > "$BIN/hypr-clipboard" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
export LANG=C.UTF-8 LC_ALL=C.UTF-8

selection="$(cliphist list | \
  "$HOME/.local/bin/rofi-safe" -dmenu -i -p '󰅇 Clipboard' \
  -theme "$HOME/.config/rofi/current.rasi")"
[[ -n "$selection" ]] || exit 0
printf '%s' "$selection" | cliphist decode | wl-copy
EOF

cat > "$BIN/hypr-keys" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
export LANG=C.UTF-8 LC_ALL=C.UTF-8

cat <<'KEYS' | "$HOME/.local/bin/rofi-safe" -dmenu -i -p '󰌌 Keybindings' -theme "$HOME/.config/rofi/current.rasi"
SUPER + ENTER          Terminal
SUPER + Q              Close window
SUPER + M              Exit Hyprland
SUPER + E              File manager
SUPER + D              Display settings
SUPER + SHIFT + B      Wallpaper picker
SUPER + T              Theme selector
SUPER + P              Power Manager
SUPER + F              Fullscreen
SUPER + SHIFT + F      Maximize
SUPER + CTRL + F       Toggle floating
SUPER + K              Keybinding help
SUPER + C              Copy
SUPER + V              Paste
SUPER + SHIFT + V      Clipboard history
SUPER + arrows         Focus
SUPER + CTRL + arrows  Swap
SUPER + SHIFT + arrows Resize
SUPER + wheel          Scroll columns
SUPER + mouse1         Move window
SUPER + mouse2         Resize window
SUPER + L              Lock screen
SUPER + X              Power popup
SUPER + B              Browser
SUPER + SPACE          Application launcher
SUPER + 1..5           Workspace
SUPER + SHIFT + 1..5   Move window to workspace
PRINT                  Region screenshot
SUPER + PRINT          Fullscreen screenshot
SUPER + SHIFT + PRINT  Active window screenshot
KEYS
EOF

cat > "$BIN/hypr-screenshot" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

mode="${1:-region}"
dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +'%Y-%m-%d_%H-%M-%S').png"

case "$mode" in
  region)
    geometry="$(slurp)" || exit 0
    grim -g "$geometry" "$file"
    ;;
  full)
    grim "$file"
    ;;
  window)
    geometry="$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')"
    [[ -n "$geometry" && "$geometry" != "null" ]] || exit 0
    grim -g "$geometry" "$file"
    ;;
esac

wl-copy < "$file"
notify-send -a Screenshot "Saved + copied" "$file"
EOF

cat > "$BIN/qs-control" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

case "${1:-}" in
  network) nm-connection-editor >/dev/null 2>&1 & ;;
  bluetooth) blueman-manager >/dev/null 2>&1 & ;;
  audio) pavucontrol >/dev/null 2>&1 & ;;
  display) nwg-displays >/dev/null 2>&1 & ;;
  notifications) swaync-client -t -sw ;;
  power) "$HOME/.local/bin/hypr-power-manager" ;;
  session) "$HOME/.local/bin/hypr-power" ;;
  launcher) "$HOME/.local/bin/rofi-safe" -show drun -theme "$HOME/.config/rofi/current.rasi" ;;
  volume-up) wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+ ;;
  volume-down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
  volume-mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
esac
EOF

cat > "$BIN/hypr-startup" <<'EOF'
#!/usr/bin/env bash
set -u

pgrep -x awww-daemon >/dev/null || awww-daemon >/dev/null 2>&1 &
pgrep -x swaync >/dev/null || swaync >/dev/null 2>&1 &
pgrep -x hypridle >/dev/null || hypridle >/dev/null 2>&1 &
pgrep -f polkit-gnome-authentication-agent-1 >/dev/null || \
  /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 >/dev/null 2>&1 &

pgrep -f "wl-paste.*cliphist store" >/dev/null || \
  wl-paste --type text --watch cliphist store >/dev/null 2>&1 &
pgrep -f "wl-paste.*image.*cliphist store" >/dev/null || \
  wl-paste --type image --watch cliphist store >/dev/null 2>&1 &

"$HOME/.local/bin/ui-theme-sync" >/dev/null 2>&1 || true

pkill quickshell 2>/dev/null || true
quickshell -c "$HOME/.config/quickshell" >/tmp/quickshell-hypr.log 2>&1 &

sleep 0.5
wall="$(cat "$HOME/.cache/hypr-current-wallpaper" 2>/dev/null || true)"
[[ -f "$wall" ]] && awww img "$wall" --transition-type fade --transition-duration 0.7 >/dev/null 2>&1 || true
EOF

chmod +x "$BIN"/hypr-* "$BIN"/qs-control "$BIN"/ui-theme-sync "$BIN"/rofi-safe

# ============================================================
# Modular Hyprland Lua config
# ============================================================
cat > "$HYPR/hyprland.lua" <<'EOF'
-- Main Hyprland config.
-- Hyprland >= 0.55 uses Lua.
-- Each module is isolated by Hyprland's require scope.

require("config.env")
require("config.monitors")
require("config.general")
require("config.input")
require("config.scrolling")
require("config.animations")
require("config.rules")
require("config.autostart")
require("config.keybinds")
EOF

cat > "$HYPR/config/env.lua" <<'EOF'
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("XCURSOR_SIZE", "24")
EOF

cat > "$HYPR/config/monitors.lua" <<'EOF'
-- Auto-detect all outputs.
-- For fixed monitors, replace this with explicit hl.monitor({...}) blocks.
hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = 1,
})
EOF

cat > "$HYPR/config/general.lua" <<'EOF'
local theme = require("theme")

hl.config({
  general = {
    layout = "scrolling",
    gaps_in = 7,
    gaps_out = 12,
    border_size = 2,
    resize_on_border = true,
    ["col.active_border"] = theme.active,
    ["col.inactive_border"] = theme.inactive,
  },

  decoration = {
    rounding = 16,
    active_opacity = 1.0,
    inactive_opacity = 0.95,

    shadow = {
      enabled = true,
      range = 18,
      render_power = 3,
      color = theme.shadow,
    },

    blur = {
      enabled = true,
      size = 7,
      passes = 3,
      new_optimizations = true,
    },
  },
})
EOF

cat > "$HYPR/config/input.lua" <<'EOF'
hl.config({
  input = {
    kb_layout = "us",
    follow_mouse = 1,
    sensitivity = 0,

    touchpad = {
      natural_scroll = true,
      tap_to_click = true,
      disable_while_typing = true,
    },
  },

  binds = {
    scroll_event_delay = 100,
    drag_threshold = 8,
  },
})
EOF

cat > "$HYPR/config/scrolling.lua" <<'EOF'
hl.config({
  scrolling = {
    column_width = 0.50,
    focus_fit_method = 1,
    follow_focus = true,
    follow_min_visible = 0.35,
    explicit_column_widths = "0.333, 0.5, 0.667, 1.0",
    wrap_focus = true,
    wrap_swapcol = true,
    direction = "right",
  },
})
EOF

cat > "$HYPR/config/animations.lua" <<'EOF'
hl.curve("animeEase", {
  type = "bezier",
  points = {
    { 0.16, 1.0 },
    { 0.30, 1.0 },
  },
})

hl.curve("animeSpring", {
  type = "spring",
  mass = 1,
  stiffness = 120,
  dampening = 14,
})

hl.animation({
  leaf = "windows",
  enabled = true,
  speed = 3.0,
  spring = "animeSpring",
  style = "popin 88%",
})

hl.animation({
  leaf = "windowsMove",
  enabled = true,
  speed = 2.8,
  bezier = "animeEase",
})

hl.animation({
  leaf = "layers",
  enabled = true,
  speed = 2.8,
  bezier = "animeEase",
  style = "popin 92%",
})

hl.animation({
  leaf = "fade",
  enabled = true,
  speed = 2.3,
  bezier = "animeEase",
})

hl.animation({
  leaf = "workspaces",
  enabled = true,
  speed = 3.5,
  bezier = "animeEase",
  style = "slidefade 18%",
})
EOF

cat > "$HYPR/config/rules.lua" <<'EOF'
hl.window_rule({
  name = "pavucontrol-float",
  match = { class = "pavucontrol" },
  float = true,
  size = { 900, 650 },
  center = true,
})

hl.window_rule({
  name = "nwg-displays-float",
  match = { class = "nwg-displays" },
  float = true,
  size = { 1000, 700 },
  center = true,
})

hl.window_rule({
  name = "blueman-float",
  match = { class = "blueman-manager" },
  float = true,
  size = { 780, 620 },
  center = true,
})
EOF

cat > "$HYPR/config/autostart.lua" <<'EOF'
local home = os.getenv("HOME")

hl.on("hyprland.start", function()
  hl.exec_cmd(home .. "/.local/bin/hypr-startup")
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
end)
EOF

cat > "$HYPR/config/keybinds.lua" <<'EOF'
local home = os.getenv("HOME")

hl.bind("SUPER + Return",
  hl.dsp.exec_cmd("kitty"),
  { description = "Terminal" })

hl.bind("SUPER + Q",
  hl.dsp.window.close({}),
  { description = "Close window" })

hl.bind("SUPER + M",
  hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"),
  { description = "Exit Hyprland" })

hl.bind("SUPER + E",
  hl.dsp.exec_cmd("thunar"),
  { description = "File manager" })

hl.bind("SUPER + D",
  hl.dsp.exec_cmd("nwg-displays"),
  { description = "Display settings" })

hl.bind("SUPER + SHIFT + B",
  hl.dsp.exec_cmd(home .. "/.local/bin/hypr-wallpaper"),
  { description = "Wallpaper picker" })

hl.bind("SUPER + T",
  hl.dsp.exec_cmd(home .. "/.local/bin/hypr-theme"),
  { description = "Theme selector" })

hl.bind("SUPER + P",
  hl.dsp.exec_cmd(home .. "/.local/bin/hypr-power-manager"),
  { description = "Power manager" })

hl.bind("SUPER + F",
  hl.dsp.window.fullscreen({
    action = "toggle",
    mode = "fullscreen",
    layout_aware = true,
  }),
  { description = "Fullscreen" })

hl.bind("SUPER + SHIFT + F",
  hl.dsp.window.fullscreen({
    action = "toggle",
    mode = "maximized",
    layout_aware = true,
  }),
  { description = "Maximize" })

hl.bind("SUPER + CTRL + F",
  hl.dsp.window.float({ action = "toggle" }),
  { description = "Toggle floating" })

hl.bind("SUPER + K",
  hl.dsp.exec_cmd(home .. "/.local/bin/hypr-keys"),
  { description = "Keybinding help" })

hl.bind("SUPER + C",
  hl.dsp.send_shortcut({ mods = "CTRL", key = "C" }),
  { description = "Copy" })

hl.bind("SUPER + V",
  hl.dsp.send_shortcut({ mods = "CTRL", key = "V" }),
  { description = "Paste" })

hl.bind("SUPER + SHIFT + V",
  hl.dsp.exec_cmd(home .. "/.local/bin/hypr-clipboard"),
  { description = "Clipboard history" })

hl.bind("SUPER + Left",
  hl.dsp.focus({ direction = "l" }),
  { repeating = true, description = "Focus left" })

hl.bind("SUPER + Down",
  hl.dsp.focus({ direction = "d" }),
  { repeating = true, description = "Focus down" })

hl.bind("SUPER + Up",
  hl.dsp.focus({ direction = "u" }),
  { repeating = true, description = "Focus up" })

hl.bind("SUPER + Right",
  hl.dsp.focus({ direction = "r" }),
  { repeating = true, description = "Focus right" })

hl.bind("SUPER + CTRL + Left",
  hl.dsp.window.swap({ direction = "l" }),
  { repeating = true, description = "Swap left" })

hl.bind("SUPER + CTRL + Down",
  hl.dsp.window.swap({ direction = "d" }),
  { repeating = true, description = "Swap down" })

hl.bind("SUPER + CTRL + Up",
  hl.dsp.window.swap({ direction = "u" }),
  { repeating = true, description = "Swap up" })

hl.bind("SUPER + CTRL + Right",
  hl.dsp.window.swap({ direction = "r" }),
  { repeating = true, description = "Swap right" })

hl.bind("SUPER + SHIFT + Left",
  hl.dsp.window.resize({ x = -60, y = 0, relative = true }),
  { repeating = true, description = "Resize left" })

hl.bind("SUPER + SHIFT + Down",
  hl.dsp.window.resize({ x = 0, y = 60, relative = true }),
  { repeating = true, description = "Resize down" })

hl.bind("SUPER + SHIFT + Up",
  hl.dsp.window.resize({ x = 0, y = -60, relative = true }),
  { repeating = true, description = "Resize up" })

hl.bind("SUPER + SHIFT + Right",
  hl.dsp.window.resize({ x = 60, y = 0, relative = true }),
  { repeating = true, description = "Resize right" })

hl.bind("SUPER + mouse_up",
  hl.dsp.layout("move -col"),
  { description = "Scroll columns left" })

hl.bind("SUPER + mouse_down",
  hl.dsp.layout("move +col"),
  { description = "Scroll columns right" })

hl.bind("SUPER + mouse:272",
  hl.dsp.window.drag(),
  { mouse = true, description = "Move floating window" })

hl.bind("SUPER + mouse:273",
  hl.dsp.window.resize(),
  { mouse = true, description = "Resize floating window" })

hl.bind("SUPER + L",
  hl.dsp.exec_cmd("hyprlock"),
  { description = "Lock screen" })

hl.bind("SUPER + X",
  hl.dsp.exec_cmd(home .. "/.local/bin/hypr-power"),
  { description = "Power popup" })

hl.bind("SUPER + B",
  hl.dsp.exec_cmd("firefox"),
  { description = "Browser" })

hl.bind("SUPER + SPACE",
  hl.dsp.exec_cmd(home .. "/.local/bin/rofi-safe -show drun -theme " .. home .. "/.config/rofi/current.rasi"),
  { description = "Application launcher" })

for i = 1, 5 do
  local ws = tostring(i)

  hl.bind("SUPER + " .. ws,
    hl.dsp.focus({ workspace = ws }),
    { description = "Workspace " .. ws })

  hl.bind("SUPER + SHIFT + " .. ws,
    hl.dsp.window.move({ workspace = ws, follow = false }),
    { description = "Move window to workspace " .. ws })
end

hl.bind("Print",
  hl.dsp.exec_cmd(home .. "/.local/bin/hypr-screenshot region"),
  { description = "Region screenshot" })

hl.bind("SUPER + Print",
  hl.dsp.exec_cmd(home .. "/.local/bin/hypr-screenshot full"),
  { description = "Fullscreen screenshot" })

hl.bind("SUPER + SHIFT + Print",
  hl.dsp.exec_cmd(home .. "/.local/bin/hypr-screenshot window"),
  { description = "Active window screenshot" })

hl.bind("XF86AudioRaiseVolume",
  hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"),
  { repeating = true, locked = true })

hl.bind("XF86AudioLowerVolume",
  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
  { repeating = true, locked = true })

hl.bind("XF86AudioMute",
  hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
  { locked = true })

hl.bind("XF86MonBrightnessUp",
  hl.dsp.exec_cmd("brightnessctl set +5%"),
  { repeating = true })

hl.bind("XF86MonBrightnessDown",
  hl.dsp.exec_cmd("brightnessctl set 5%-"),
  { repeating = true })

hl.bind("XF86AudioPlay",
  hl.dsp.exec_cmd("playerctl play-pause"),
  { locked = true })

hl.bind("XF86AudioNext",
  hl.dsp.exec_cmd("playerctl next"),
  { locked = true })

hl.bind("XF86AudioPrev",
  hl.dsp.exec_cmd("playerctl previous"),
  { locked = true })
EOF

# ============================================================
# Quickshell KDE-like bar + popup
# ============================================================
cat > "$QS/theme.js" <<'EOF'
.pragma library
var bg="#E61E1E2E"
var surface="#F2313244"
var surface2="#F245475A"
var text="#CDD6F4"
var subtext="#BAC2DE"
var muted="#7F849C"
var accent="#CBA6F7"
var accent2="#F5C2E7"
var danger="#F38BA8"
var border="#806C7086"
EOF

cat > "$QS/shell.qml" <<'EOF'
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import "theme.js" as Theme

ShellRoot {
    id: root

    property string page: "quick"
    readonly property string popupWallpaper: wallpaperFile.text().trim()

    FileView {
        id: wallpaperFile
        path: Quickshell.env("HOME") + "/.cache/hypr-popup-wallpaper"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }

    function run(args) {
        Quickshell.execDetached(args)
    }

    function showPage(name) {
        page = name
        popup.visible = true
    }

    PanelWindow {
        id: bar
        implicitHeight: 44
        color: "transparent"

        anchors {
            top: true
            left: true
            right: true
        }

        margins {
            top: 7
            left: 10
            right: 10
        }

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: Theme.bg
            border.width: 1
            border.color: Theme.border

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 9
                anchors.rightMargin: 9
                spacing: 6

                BarButton {
                    text: "󰣇"
                    accent: true
                    onClicked: root.run([
                        Quickshell.env("HOME") + "/.local/bin/qs-control",
                        "launcher"
                    ])
                }

                Row {
                    spacing: 3
                    Repeater {
                        model: 5
                        Rectangle {
                            required property int index
                            width: 30
                            height: 30
                            radius: 10
                            color: Hyprland.focusedWorkspace &&
                                   Hyprland.focusedWorkspace.id === index + 1
                                   ? Theme.accent : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: index + 1
                                color: Hyprland.focusedWorkspace &&
                                       Hyprland.focusedWorkspace.id === index + 1
                                       ? "#11111b" : Theme.subtext
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Hyprland.dispatch("workspace " + (parent.index + 1))
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    leftPadding: 8
                    text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : "Hyprland"
                    color: Theme.subtext
                    elide: Text.ElideRight
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                }

                ClockButton {
                    onClicked: root.showPage("calendar")
                }

                Row {
                    spacing: 4

                    Repeater {
                        model: SystemTray.items

                        Item {
                            required property var modelData
                            width: 28
                            height: 30

                            Image {
                                anchors.centerIn: parent
                                width: 19
                                height: 19
                                source: parent.modelData.icon
                                fillMode: Image.PreserveAspectFit
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                cursorShape: Qt.PointingHandCursor

                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton && parent.modelData.hasMenu)
                                        parent.modelData.display(bar, parent.x, 36)
                                    else if (mouse.button === Qt.MiddleButton)
                                        parent.modelData.secondaryActivate()
                                    else
                                        parent.modelData.activate()
                                }
                            }
                        }
                    }
                }

                BarButton { text: "󰂯"; onClicked: root.showPage("bluetooth") }
                BarButton { text: "󰤨"; onClicked: root.showPage("network") }
                BarButton { text: "󰕾"; onClicked: root.showPage("audio") }
                BarButton { text: "󰂚"; onClicked: root.run([Quickshell.env("HOME") + "/.local/bin/qs-control", "notifications"]) }
                BarButton { text: "󰍹"; onClicked: root.showPage("display") }
                BarButton { text: "󰾅"; onClicked: root.showPage("power") }
                BarButton { text: "󰐥"; accent: true; onClicked: root.showPage("session") }
            }
        }
    }

    PanelWindow {
        id: popup
        visible: false
        implicitWidth: 410
        implicitHeight: 470
        color: "transparent"

        anchors {
            top: true
            right: true
        }

        margins {
            top: 6
            right: 12
        }

        Rectangle {
            id: card
            anchors.fill: parent
            radius: 20
            color: "transparent"
            clip: true
            border.width: 1
            border.color: Theme.border

            Image {
                anchors.fill: parent
                source: root.popupWallpaper
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                opacity: 0.50
            }

            Rectangle {
                anchors.fill: parent
                radius: 20
                color: Theme.bg
                opacity: 0.76
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: {
                            if (root.page === "network") return "󰤨  Network"
                            if (root.page === "bluetooth") return "󰂯  Bluetooth"
                            if (root.page === "audio") return "󰕾  Audio"
                            if (root.page === "display") return "󰍹  Display"
                            if (root.page === "power") return "󰾅  Power"
                            if (root.page === "calendar") return "󰃭  Calendar"
                            if (root.page === "session") return "󰐥  Session"
                            return "Control Center"
                        }
                        color: Theme.text
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 19
                        font.bold: true
                    }

                    Text {
                        text: "󰅖"
                        color: Theme.muted
                        font.pixelSize: 17
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popup.visible = false
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.border
                }

                ColumnLayout {
                    visible: root.page === "network"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12
                    BigButton {
                        icon: "󰤨"
                        title: "Network connections"
                        subtitle: "Wi-Fi / Ethernet / VPN"
                        onClicked: root.run([Quickshell.env("HOME") + "/.local/bin/qs-control", "network"])
                    }
                    Item { Layout.fillHeight: true }
                }

                ColumnLayout {
                    visible: root.page === "bluetooth"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12
                    BigButton {
                        icon: "󰂯"
                        title: "Bluetooth devices"
                        subtitle: "Pair / connect / disconnect"
                        onClicked: root.run([Quickshell.env("HOME") + "/.local/bin/qs-control", "bluetooth"])
                    }
                    Item { Layout.fillHeight: true }
                }

                ColumnLayout {
                    visible: root.page === "audio"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    BigButton {
                        icon: "󰕾"
                        title: "Audio mixer"
                        subtitle: "Output / input / application volume"
                        onClicked: root.run([Quickshell.env("HOME") + "/.local/bin/qs-control", "audio"])
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        SmallButton {
                            Layout.fillWidth: true
                            text: "󰝟 Mute"
                            onClicked: root.run([Quickshell.env("HOME") + "/.local/bin/qs-control", "volume-mute"])
                        }
                        SmallButton {
                            Layout.fillWidth: true
                            text: "− Volume"
                            onClicked: root.run([Quickshell.env("HOME") + "/.local/bin/qs-control", "volume-down"])
                        }
                        SmallButton {
                            Layout.fillWidth: true
                            text: "+ Volume"
                            onClicked: root.run([Quickshell.env("HOME") + "/.local/bin/qs-control", "volume-up"])
                        }
                    }

                    Item { Layout.fillHeight: true }
                }

                ColumnLayout {
                    visible: root.page === "display"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12
                    BigButton {
                        icon: "󰍹"
                        title: "Display configuration"
                        subtitle: "Monitor layout / scale / mode"
                        onClicked: root.run([Quickshell.env("HOME") + "/.local/bin/qs-control", "display"])
                    }
                    Item { Layout.fillHeight: true }
                }

                ColumnLayout {
                    visible: root.page === "power"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12
                    BigButton {
                        icon: "󰾅"
                        title: "Power profiles"
                        subtitle: "Saver / Balanced / Performance"
                        onClicked: root.run([Quickshell.env("HOME") + "/.local/bin/qs-control", "power"])
                    }
                    Item { Layout.fillHeight: true }
                }

                ColumnLayout {
                    visible: root.page === "calendar"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(new Date(), "dddd")
                        color: Theme.accent2
                        font.pixelSize: 16
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(new Date(), "dd MMMM yyyy")
                        color: Theme.text
                        font.pixelSize: 24
                        font.bold: true
                    }
                    Text {
                        id: bigClock
                        Layout.alignment: Qt.AlignHCenter
                        color: Theme.accent
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 56
                        font.bold: true

                        Timer {
                            interval: 1000
                            running: true
                            repeat: true
                            triggeredOnStart: true
                            onTriggered: bigClock.text = Qt.formatDateTime(new Date(), "HH:mm")
                        }
                    }
                    Item { Layout.fillHeight: true }
                }

                ColumnLayout {
                    visible: root.page === "session"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12
                    BigButton {
                        icon: "󰐥"
                        title: "Session / power menu"
                        subtitle: "Lock / sleep / reboot / shutdown"
                        onClicked: root.run([Quickshell.env("HOME") + "/.local/bin/qs-control", "session"])
                    }
                    Item { Layout.fillHeight: true }
                }
            }

            onVisibleChanged: {}
        }

        onVisibleChanged: {
            if (visible) {
                card.scale = 0.94
                card.opacity = 0
                popupAnim.restart()
            }
        }

        ParallelAnimation {
            id: popupAnim
            NumberAnimation {
                target: card
                property: "scale"
                from: 0.94
                to: 1.0
                duration: 170
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: card
                property: "opacity"
                from: 0
                to: 1
                duration: 150
            }
        }
    }

    component BarButton: Rectangle {
        id: bb
        property string text: ""
        property bool accent: false
        signal clicked()

        implicitWidth: 34
        implicitHeight: 30
        radius: 10
        color: mouse.containsMouse ? Theme.surface2 : "transparent"

        Text {
            anchors.centerIn: parent
            text: bb.text
            color: bb.accent ? Theme.accent : Theme.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 17
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: bb.clicked()
        }
    }

    component ClockButton: Rectangle {
        signal clicked()
        implicitWidth: 72
        implicitHeight: 30
        radius: 10
        color: clockMouse.containsMouse ? Theme.surface2 : "transparent"

        Text {
            id: clockText
            anchors.centerIn: parent
            color: Theme.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            font.bold: true

            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: clockText.text = Qt.formatDateTime(new Date(), "HH:mm")
            }
        }

        MouseArea {
            id: clockMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component BigButton: Rectangle {
        id: big
        property string icon: ""
        property string title: ""
        property string subtitle: ""
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: 84
        radius: 15
        color: hover.containsMouse ? Theme.surface2 : Theme.surface

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 13

            Text {
                text: big.icon
                color: Theme.accent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 25
            }

            ColumnLayout {
                Layout.fillWidth: true
                Text {
                    text: big.title
                    color: Theme.text
                    font.pixelSize: 14
                    font.bold: true
                }
                Text {
                    text: big.subtitle
                    color: Theme.muted
                    font.pixelSize: 11
                }
            }

            Text {
                text: "󰅂"
                color: Theme.muted
                font.pixelSize: 15
            }
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: big.clicked()
        }
    }

    component SmallButton: Rectangle {
        id: small
        property string text: ""
        signal clicked()

        implicitHeight: 42
        radius: 12
        color: smallHover.containsMouse ? Theme.surface2 : Theme.surface

        Text {
            anchors.centerIn: parent
            text: small.text
            color: Theme.text
            font.pixelSize: 11
            font.family: "JetBrainsMono Nerd Font"
        }

        MouseArea {
            id: smallHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: small.clicked()
        }
    }
}
EOF

# ============================================================
# SwayNC
# ============================================================
cat > "$SWAYNC/config.json" <<'EOF'
{
  "positionX": "right",
  "positionY": "top",
  "layer": "overlay",
  "control-center-layer": "top",
  "notification-window-width": 390,
  "control-center-width": 420,
  "control-center-height": 680,
  "fit-to-screen": true,
  "keyboard-shortcuts": true,
  "image-visibility": "when-available",
  "transition-time": 180,
  "hide-on-clear": false,
  "hide-on-action": true,
  "widgets": ["title", "dnd", "notifications"]
}
EOF

cat > "$SWAYNC/style.css" <<'EOF'
* {
  font-family: "JetBrainsMono Nerd Font", sans-serif;
  color: #cdd6f4;
}
.control-center,
.notification-row .notification-background .notification {
  background: rgba(30,30,46,.94);
  border: 1px solid rgba(203,166,247,.50);
  border-radius: 18px;
}
.control-center { padding: 12px; }
.notification { padding: 8px; margin: 7px; }
.summary { color: #f5c2e7; font-weight: 700; }
.body { color: #bac2de; }
.widget-title { color: #cba6f7; margin: 8px; font-size: 18px; }
.widget-dnd { background: #313244; border-radius: 12px; margin: 8px; padding: 7px; }
EOF

# ============================================================
# Hyprlock / Hypridle
# ============================================================
cat > "$HYPR/hyprlock.conf" <<'EOF'
general {
  hide_cursor = true
  grace = 2
}

background {
  monitor =
  path = screenshot
  blur_passes = 4
  blur_size = 7
  brightness = 0.62
}

label {
  monitor =
  text = cmd[update:1000] echo "$(date +'%H:%M')"
  color = rgba(205,214,244,1.0)
  font_size = 86
  font_family = JetBrainsMono Nerd Font
  position = 0, 90
  halign = center
  valign = center
}

input-field {
  monitor =
  size = 330, 55
  outline_thickness = 2
  dots_size = 0.22
  dots_spacing = 0.22
  outer_color = rgba(203,166,247,0.85)
  inner_color = rgba(30,30,46,0.88)
  font_color = rgba(205,214,244,1.0)
  fade_on_empty = false
  placeholder_text = <i>password...</i>
  position = 0, -120
  halign = center
  valign = center
}
EOF

cat > "$HYPR/hypridle.conf" <<'EOF'
general {
  lock_cmd = pidof hyprlock || hyprlock
  before_sleep_cmd = loginctl lock-session
  after_sleep_cmd = hyprctl dispatch dpms on
  ignore_dbus_inhibit = false
}

listener {
  timeout = 300
  on-timeout = loginctl lock-session
}

listener {
  timeout = 360
  on-timeout = hyprctl dispatch dpms off
  on-resume = hyprctl dispatch dpms on
}

listener {
  timeout = 900
  on-timeout = systemctl suspend
}
EOF

# ============================================================
# Kitty
# ============================================================
cat > "$KITTY/kitty.conf" <<'EOF'
include theme.conf
font_family JetBrainsMono Nerd Font
font_size 11.5
window_padding_width 12
background_opacity 0.92
confirm_os_window_close 0
enable_audio_bell no
EOF

# Initial theme files.
"$BIN/ui-theme-sync"

# ============================================================
# SDDM
# ============================================================
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/10-hypr-anime.conf >/dev/null <<'EOF'
[General]
InputMethod=
EOF

# ============================================================
# Validation
# ============================================================
log "Validating shell scripts..."
for f in \
  "$BIN/rofi-safe" \
  "$BIN/ui-theme-sync" \
  "$BIN/hypr-theme" \
  "$BIN/hypr-wallpaper" \
  "$BIN/hypr-power" \
  "$BIN/hypr-power-manager" \
  "$BIN/hypr-clipboard" \
  "$BIN/hypr-keys" \
  "$BIN/hypr-screenshot" \
  "$BIN/qs-control" \
  "$BIN/hypr-startup"; do
  bash -n "$f"
done

log "Install complete."

cat <<EOF

============================================================
 Hyprland Anime Desktop - modular build installed
============================================================

Main config:
  $HYPR/hyprland.lua

Modules:
  $HYPR/config/env.lua
  $HYPR/config/monitors.lua
  $HYPR/config/general.lua
  $HYPR/config/input.lua
  $HYPR/config/scrolling.lua
  $HYPR/config/animations.lua
  $HYPR/config/rules.lua
  $HYPR/config/autostart.lua
  $HYPR/config/keybinds.lua

Theme:
  SUPER + T
Wallpaper:
  SUPER + SHIFT + B
Terminal:
  SUPER + Enter
Launcher:
  SUPER + Space
Power:
  SUPER + X

Quickshell:
  $QS/shell.qml

Backup:
  $BACKUP

Next:
  sudo reboot

After login, if anything fails:
  hyprctl configerrors
  tail -100 /tmp/quickshell-hypr.log
============================================================
EOF
