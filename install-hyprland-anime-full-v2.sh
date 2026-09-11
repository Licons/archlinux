#!/usr/bin/env bash
set -Eeuo pipefail

# ================================================================
# Arch Linux -> Hyprland 0.56.x Anime Desktop (FULL / CLEAN)
# - Modular Hyprland Lua config
# - Scrolling layout
# - Quickshell KDE-like bar + SNI tray + popup wallpaper
# - Catppuccin Pastel / Tokyo Night
# - Rofi theme sync WITHOUT CSS gradients/background-image
# - awww wallpaper animations
# ================================================================

log()  { printf '\033[1;35m[hypr-anime]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warning]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -ne 0 ]] || die "Run as normal user, not root."
command -v sudo >/dev/null || die "sudo is required."
command -v pacman >/dev/null || die "Arch Linux / pacman required."

CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
HYPR="$CFG/hypr"
QS="$CFG/quickshell"
ROFI="$CFG/rofi"
SWAYNC="$CFG/swaync"
KITTY="$CFG/kitty"
BIN="$HOME/.local/bin"
WALL="$HOME/Pictures/Wallpapers"
CACHE="$HOME/.cache"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.config-backup-hypr-anime-$STAMP"

# ----------------------------------------------------------------
# Backup
# ----------------------------------------------------------------
log "Backing up existing desktop configs..."
mkdir -p "$BACKUP"
for d in hypr quickshell rofi swaync kitty; do
  [[ -e "$CFG/$d" ]] && cp -a "$CFG/$d" "$BACKUP/$d" 2>/dev/null || true
done

# ----------------------------------------------------------------
# Packages
# ----------------------------------------------------------------
log "Updating Arch Linux..."
sudo pacman -Syu --noconfirm

PACKAGES=(
  hyprland
  xdg-desktop-portal
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk
  xorg-xwayland

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

# ----------------------------------------------------------------
# Locale safety
# ----------------------------------------------------------------
if ! locale -a 2>/dev/null | grep -qi '^en_US\.utf8$'; then
  log "Generating en_US.UTF-8..."
  sudo sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
  sudo locale-gen
fi

if [[ ! -s /etc/locale.conf ]]; then
  echo 'LANG=en_US.UTF-8' | sudo tee /etc/locale.conf >/dev/null
fi

# ----------------------------------------------------------------
# Directories
# ----------------------------------------------------------------
mkdir -p \
  "$HYPR/config" \
  "$QS" \
  "$ROFI" \
  "$SWAYNC" \
  "$KITTY" \
  "$BIN" \
  "$WALL" \
  "$CACHE"

xdg-user-dirs-update || true

# ================================================================
# Bundled wallpapers
# ================================================================
log "Creating bundled anime-style wallpapers..."

cat > /tmp/hypr-catppuccin.svg <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="2560" height="1440">
<defs>
 <linearGradient id="sky" x1="0" y1="0" x2="1" y2="1">
  <stop offset="0" stop-color="#1e1e2e"/>
  <stop offset=".52" stop-color="#45475a"/>
  <stop offset="1" stop-color="#f5c2e7"/>
 </linearGradient>
</defs>
<rect width="2560" height="1440" fill="url(#sky)"/>
<circle cx="1940" cy="320" r="190" fill="#f9e2af"/>
<circle cx="1870" cy="270" r="190" fill="#313244" opacity=".38"/>
<path d="M0 1070 Q430 850 820 1090 T1620 1060 T2560 1030 V1440 H0Z" fill="#181825"/>
<path d="M0 1200 Q520 1010 1040 1200 T2040 1160 T2560 1190 V1440 H0Z" fill="#11111b"/>
<g fill="#f5c2e7" opacity=".85">
 <circle cx="250" cy="300" r="13"/>
 <circle cx="350" cy="370" r="8"/>
 <circle cx="455" cy="265" r="10"/>
 <circle cx="2260" cy="740" r="12"/>
 <circle cx="2350" cy="690" r="8"/>
</g>
<text x="150" y="1290" fill="#cdd6f4" font-size="70" font-family="sans-serif">PASTEL DREAM</text>
<text x="155" y="1350" fill="#f5c2e7" font-size="27" font-family="sans-serif">catppuccin • moonlight • anime</text>
</svg>
SVG

cat > /tmp/hypr-tokyo.svg <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="2560" height="1440">
<defs>
 <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#16161e"/>
  <stop offset=".62" stop-color="#24283b"/>
  <stop offset="1" stop-color="#101014"/>
 </linearGradient>
</defs>
<rect width="2560" height="1440" fill="url(#sky)"/>
<circle cx="1890" cy="325" r="175" fill="#e0af68"/>
<g fill="#1f2335">
 <rect x="80" y="610" width="270" height="500"/>
 <rect x="400" y="700" width="330" height="410"/>
 <rect x="790" y="500" width="300" height="610"/>
 <rect x="1140" y="640" width="270" height="470"/>
 <rect x="1470" y="540" width="340" height="570"/>
 <rect x="1870" y="670" width="270" height="440"/>
 <rect x="2190" y="550" width="300" height="560"/>
</g>
<g fill="#7dcfff">
 <rect x="835" y="570" width="28" height="90"/>
 <rect x="910" y="570" width="28" height="90"/>
 <rect x="1510" y="610" width="30" height="105"/>
 <rect x="1590" y="610" width="30" height="105"/>
</g>
<path d="M0 1120 C500 1010 800 1280 1300 1150 S2100 1040 2560 1180" fill="none" stroke="#bb9af7" stroke-width="12"/>
<path d="M0 1160 C550 1050 900 1300 1400 1190 S2150 1080 2560 1220" fill="none" stroke="#7aa2f7" stroke-width="6"/>
<text x="150" y="1290" fill="#c0caf5" font-size="70" font-family="sans-serif">TOKYO NIGHT</text>
<text x="155" y="1350" fill="#7aa2f7" font-size="27" font-family="sans-serif">neon city • midnight • anime</text>
</svg>
SVG

magick /tmp/hypr-catppuccin.svg "$WALL/catppuccin-pastel.png"
magick /tmp/hypr-tokyo.svg "$WALL/tokyo-night.png"
rm -f /tmp/hypr-catppuccin.svg /tmp/hypr-tokyo.svg

# ================================================================
# Rofi locale-safe wrapper
# ================================================================
cat > "$BIN/rofi-safe" <<'EOF'
#!/usr/bin/env bash
unset LC_ALL LC_CTYPE LC_MESSAGES LC_NUMERIC LC_TIME LC_COLLATE \
      LC_MONETARY LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE \
      LC_MEASUREMENT LC_IDENTIFICATION
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
exec /usr/bin/rofi "$@"
EOF
chmod +x "$BIN/rofi-safe"

# ================================================================
# Theme state + synchronizer
# ================================================================
printf 'catppuccin-pastel\n' > "$HYPR/.theme"
printf '%s\n' "$WALL/catppuccin-pastel.png" > "$CACHE/hypr-current-wallpaper"
printf 'file://%s\n' "$WALL/catppuccin-pastel.png" > "$CACHE/hypr-popup-wallpaper"

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
  printf '%s\n' "$WALL" > "$HOME/.cache/hypr-current-wallpaper"
fi

printf 'file://%s\n' "$WALL" > "$HOME/.cache/hypr-popup-wallpaper"

case "$THEME" in
  tokyo-night)
    ACTIVE="0xff7aa2f7"
    INACTIVE="0xff414868"
    SHADOW="0xaa101014"
    BG="#1A1B26EE"
    BG2="#24283BF2"
    FG="#C0CAF5FF"
    MUTED="#565F89FF"
    ACCENT="#7AA2F7FF"
    ACCENT2="#BB9AF7FF"
    SELECTFG="#101014FF"
    BORDER="#BB9AF7AA"

    QBG="#E61A1B26"
    QSURFACE="#F224283B"
    QSURFACE2="#F2414868"
    QTEXT="#C0CAF5"
    QSUB="#A9B1D6"
    QMUTED="#565F89"
    QACCENT="#7AA2F7"
    QACCENT2="#BB9AF7"
    QDANGER="#F7768E"
    QBORDER="#80565F89"

    SWBG="26,27,38"
    SWTEXT="#c0caf5"
    SWACC="#7aa2f7"
    SWACC2="#bb9af7"
    ;;
  *)
    ACTIVE="0xffcba6f7"
    INACTIVE="0xff45475a"
    SHADOW="0xaa11111b"
    BG="#1E1E2EEE"
    BG2="#313244F2"
    FG="#CDD6F4FF"
    MUTED="#7F849CFF"
    ACCENT="#CBA6F7FF"
    ACCENT2="#F5C2E7FF"
    SELECTFG="#11111BFF"
    BORDER="#F5C2E7AA"

    QBG="#E61E1E2E"
    QSURFACE="#F2313244"
    QSURFACE2="#F245475A"
    QTEXT="#CDD6F4"
    QSUB="#BAC2DE"
    QMUTED="#7F849C"
    QACCENT="#CBA6F7"
    QACCENT2="#F5C2E7"
    QDANGER="#F38BA8"
    QBORDER="#806C7086"

    SWBG="30,30,46"
    SWTEXT="#cdd6f4"
    SWACC="#cba6f7"
    SWACC2="#f5c2e7"
    ;;
esac

# Hyprland theme is a config module, not a returned Lua table.
cat > "$CFG/hypr/config/theme.lua" <<LUA
hl.config({
  general = {
    ["col.active_border"] = $ACTIVE,
    ["col.inactive_border"] = $INACTIVE,
  },

  decoration = {
    shadow = {
      color = $SHADOW,
    },
  },
})
LUA

# Rofi intentionally uses only basic supported RASI properties.
# NO linear-gradient and NO background-image.
cat > "$CFG/rofi/current.rasi" <<RASI
* {
  bg: $BG;
  bg2: $BG2;
  fg: $FG;
  muted: $MUTED;
  accent: $ACCENT;
  accent2: $ACCENT2;
  selectfg: $SELECTFG;
  borderc: $BORDER;
}

window {
  width: 680px;
  location: center;
  anchor: center;
  border: 2px;
  border-color: @borderc;
  border-radius: 20px;
  background-color: @bg;
  padding: 16px;
}

mainbox {
  spacing: 12px;
  background-color: transparent;
}

inputbar {
  padding: 11px 14px;
  spacing: 9px;
  border-radius: 13px;
  background-color: @bg2;
  text-color: @fg;
}

prompt {
  text-color: @accent2;
}

entry {
  text-color: @fg;
  placeholder-color: @muted;
}

listview {
  lines: 9;
  columns: 1;
  spacing: 5px;
  scrollbar: false;
  background-color: transparent;
}

element {
  padding: 10px 12px;
  spacing: 9px;
  border-radius: 12px;
  background-color: transparent;
  text-color: @fg;
}

element selected.normal,
element selected.active,
element selected.urgent {
  background-color: @accent;
  text-color: @selectfg;
}

element-icon {
  size: 28px;
}

element-text {
  text-color: inherit;
}
RASI

cat > "$CFG/quickshell/theme.js" <<JS
.pragma library
var bg = "$QBG"
var surface = "$QSURFACE"
var surface2 = "$QSURFACE2"
var text = "$QTEXT"
var subtext = "$QSUB"
var muted = "$QMUTED"
var accent = "$QACCENT"
var accent2 = "$QACCENT2"
var danger = "$QDANGER"
var border = "$QBORDER"
JS

cat > "$CFG/swaync/style.css" <<CSS
* {
  font-family: "JetBrainsMono Nerd Font", sans-serif;
  color: $SWTEXT;
}

.control-center,
.notification-row .notification-background .notification {
  background: rgba($SWBG,.94);
  border: 1px solid $SWACC;
  border-radius: 18px;
}

.control-center {
  padding: 12px;
}

.notification {
  padding: 8px;
  margin: 7px;
}

.summary {
  color: $SWACC2;
  font-weight: 700;
}

.widget-title {
  color: $SWACC;
  margin: 8px;
  font-size: 18px;
}

.widget-dnd {
  background: rgba($SWBG,.85);
  border-radius: 12px;
  margin: 8px;
  padding: 7px;
}
CSS

case "$THEME" in
  tokyo-night)
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
EOF
chmod +x "$BIN/ui-theme-sync"

# ================================================================
# User helper scripts
# ================================================================
cat > "$BIN/hypr-theme" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

choice="$(printf 'Catppuccin Pastel\nTokyo Night\n' | \
  "$HOME/.local/bin/rofi-safe" \
  -dmenu -i -p 'Theme' \
  -theme "$HOME/.config/rofi/current.rasi")"

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

printf '%s\n' "$slug" > "$HOME/.config/hypr/.theme"
printf '%s\n' "$wall" > "$HOME/.cache/hypr-current-wallpaper"
printf 'file://%s\n' "$wall" > "$HOME/.cache/hypr-popup-wallpaper"

"$HOME/.local/bin/ui-theme-sync"

pgrep -x awww-daemon >/dev/null || {
  awww-daemon >/dev/null 2>&1 &
  sleep 0.25
}

awww img "$wall" \
  --transition-type wave \
  --transition-duration 1.0 \
  --transition-fps 60 \
  --transition-angle 25 || true

hyprctl reload >/dev/null 2>&1 || true
swaync-client -rs >/dev/null 2>&1 || true

# theme.js is imported at shell load time, restart Quickshell for palette change.
pkill quickshell 2>/dev/null || true
sleep 0.15
quickshell -c "$HOME/.config/quickshell" >/tmp/quickshell-hypr.log 2>&1 &

notify-send -a "Hypr Anime" "Theme changed" "$choice"
EOF

cat > "$BIN/hypr-wallpaper" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

DIR="$HOME/Pictures/Wallpapers"
mkdir -p "$DIR"

mapfile -d '' files < <(
  find "$DIR" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
    -print0 | sort -z
)

((${#files[@]})) || {
  notify-send "Wallpaper" "No wallpaper found in $DIR"
  exit 0
}

menu=""
for f in "${files[@]}"; do
  menu+="$(basename "$f")"$'\n'
done

choice="$(printf '%s' "$menu" | \
  "$HOME/.local/bin/rofi-safe" \
  -dmenu -i -p 'Wallpaper' \
  -theme "$HOME/.config/rofi/current.rasi")"

[[ -n "$choice" ]] || exit 0
wall="$DIR/$choice"

printf '%s\n' "$wall" > "$HOME/.cache/hypr-current-wallpaper"
printf 'file://%s\n' "$wall" > "$HOME/.cache/hypr-popup-wallpaper"

pgrep -x awww-daemon >/dev/null || {
  awww-daemon >/dev/null 2>&1 &
  sleep 0.25
}

awww img "$wall" \
  --transition-type grow \
  --transition-pos center \
  --transition-duration 0.9 \
  --transition-fps 60 || true
EOF

cat > "$BIN/hypr-power" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

choice="$(printf 'Lock\nSleep\nReboot\nShutdown\nLogout\n' | \
  "$HOME/.local/bin/rofi-safe" \
  -dmenu -i -p 'Power' \
  -theme "$HOME/.config/rofi/current.rasi")"

case "$choice" in
  Lock) hyprlock ;;
  Sleep) systemctl suspend ;;
  Reboot) systemctl reboot ;;
  Shutdown) systemctl poweroff ;;
  Logout) command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit ;;
esac
EOF

cat > "$BIN/hypr-power-manager" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

current="$(powerprofilesctl get 2>/dev/null || echo unavailable)"

choice="$(printf 'Power Saver\nBalanced\nPerformance\nSleep now\nLock now\n' | \
  "$HOME/.local/bin/rofi-safe" \
  -dmenu -i -p "Power: $current" \
  -theme "$HOME/.config/rofi/current.rasi")"

case "$choice" in
  "Power Saver") powerprofilesctl set power-saver ;;
  Balanced) powerprofilesctl set balanced ;;
  Performance) powerprofilesctl set performance ;;
  "Sleep now") systemctl suspend ;;
  "Lock now") hyprlock ;;
esac
EOF

cat > "$BIN/hypr-clipboard" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

selection="$(cliphist list | \
  "$HOME/.local/bin/rofi-safe" \
  -dmenu -i -p 'Clipboard' \
  -theme "$HOME/.config/rofi/current.rasi")"

[[ -n "$selection" ]] || exit 0
printf '%s' "$selection" | cliphist decode | wl-copy
EOF

cat > "$BIN/hypr-keys" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

cat <<'KEYS' | "$HOME/.local/bin/rofi-safe" -dmenu -i -p 'Keybindings' -theme "$HOME/.config/rofi/current.rasi"
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
SUPER + CTRL + arrows  Move/swap window
SUPER + SHIFT + arrows Resize
SUPER + wheel          Scroll columns
SUPER + mouse1         Move floating window
SUPER + mouse2         Resize floating window
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
  *)
    exit 2
    ;;
esac

wl-copy < "$file"
notify-send -a Screenshot "Saved and copied" "$file"
EOF

cat > "$BIN/qs-control" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

case "${1:-}" in
  launcher)
    "$HOME/.local/bin/rofi-safe" -show drun -theme "$HOME/.config/rofi/current.rasi"
    ;;
  network)
    nm-connection-editor >/dev/null 2>&1 &
    ;;
  bluetooth)
    blueman-manager >/dev/null 2>&1 &
    ;;
  audio)
    pavucontrol >/dev/null 2>&1 &
    ;;
  notifications)
    swaync-client -t -sw
    ;;
  display)
    nwg-displays >/dev/null 2>&1 &
    ;;
  power)
    "$HOME/.local/bin/hypr-power-manager"
    ;;
  session)
    "$HOME/.local/bin/hypr-power"
    ;;
  volume-up)
    wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+
    ;;
  volume-down)
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    ;;
  volume-mute)
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    ;;
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

sleep 0.4

wall="$(cat "$HOME/.cache/hypr-current-wallpaper" 2>/dev/null || true)"
if [[ -f "$wall" ]]; then
  awww img "$wall" \
    --transition-type fade \
    --transition-duration 0.6 \
    --transition-fps 60 >/dev/null 2>&1 || true
fi
EOF

chmod +x \
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
  "$BIN/hypr-startup"

# ================================================================
# Hyprland modular Lua config
# ================================================================
cat > "$HYPR/hyprland.lua" <<'EOF'
require("config.env")
require("config.monitors")
require("config.general")
require("config.theme")
require("config.input")
require("config.scrolling")
require("config.animations")
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
-- Default: every connected monitor at preferred mode.
hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = 1,
})
EOF

cat > "$HYPR/config/general.lua" <<'EOF'
hl.config({
  general = {
    layout = "scrolling",
    gaps_in = 7,
    gaps_out = 12,
    border_size = 2,
    resize_on_border = true,
  },

  decoration = {
    rounding = 16,
    rounding_power = 2.0,
    active_opacity = 1.0,
    inactive_opacity = 0.96,
    fullscreen_opacity = 1.0,

    shadow = {
      enabled = true,
      range = 18,
      render_power = 3,
    },

    blur = {
      enabled = true,
      size = 7,
      passes = 3,
    },
  },
})
EOF

# Placeholder; ui-theme-sync overwrites it immediately below.
cat > "$HYPR/config/theme.lua" <<'EOF'
hl.config({
  general = {
    ["col.active_border"] = 0xffcba6f7,
    ["col.inactive_border"] = 0xff45475a,
  },
  decoration = {
    shadow = {
      color = 0xaa11111b,
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
-- Bezier-only animation config for stable Hyprland 0.56.x compatibility.

hl.curve("animeEase", {
  type = "bezier",
  points = {
    { 0.16, 1.0 },
    { 0.30, 1.0 },
  },
})

hl.curve("animeMove", {
  type = "bezier",
  points = {
    { 0.22, 1.0 },
    { 0.36, 1.0 },
  },
})

hl.animation({
  leaf = "windows",
  enabled = true,
  speed = 3.0,
  bezier = "animeEase",
  style = "popin 88%",
})

hl.animation({
  leaf = "windowsMove",
  enabled = true,
  speed = 2.5,
  bezier = "animeMove",
})

hl.animation({
  leaf = "layers",
  enabled = true,
  speed = 2.7,
  bezier = "animeEase",
  style = "popin 92%",
})

hl.animation({
  leaf = "fade",
  enabled = true,
  speed = 2.2,
  bezier = "animeEase",
})

hl.animation({
  leaf = "workspaces",
  enabled = true,
  speed = 3.3,
  bezier = "animeMove",
  style = "slidefade 18%",
})
EOF

cat > "$HYPR/config/autostart.lua" <<'EOF'
local home = os.getenv("HOME")

hl.on("hyprland.start", function()
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
  hl.exec_cmd(home .. "/.local/bin/hypr-startup")
end)
EOF

cat > "$HYPR/config/keybinds.lua" <<'EOF'
local home = os.getenv("HOME")

-- Emergency terminal. Keep this even if launcher/UI breaks.
hl.bind("SUPER + Return",
  hl.dsp.exec_cmd("kitty"))

hl.bind("SUPER + Q",
  hl.dsp.window.close({}))

hl.bind("SUPER + M",
  hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"))

hl.bind("SUPER + E",
  hl.dsp.exec_cmd("thunar"))

hl.bind("SUPER + D",
  hl.dsp.exec_cmd("nwg-displays"))

hl.bind("SUPER + SHIFT + B",
  hl.dsp.exec_cmd(home .. "/.local/bin/hypr-wallpaper"))

hl.bind("SUPER + T",
  hl.dsp.exec_cmd(home .. "/.local/bin/hypr-theme"))

hl.bind("SUPER + P",
  hl.dsp.exec_cmd(home .. "/.local/bin/hypr-power-manager"))

hl.bind("SUPER + F",
  hl.dsp.window.fullscreen({
    action = "toggle",
    mode = "fullscreen",
    layout_aware = true,
  }))

hl.bind("SUPER + SHIFT + F",
  hl.dsp.window.fullscreen({
    action = "toggle",
    mode = "maximized",
    layout_aware = true,
  }))

hl.bind("SUPER + CTRL + F",
  hl.dsp.window.float({
    action = "toggle",
  }))

hl.bind("SUPER + K",
  hl.dsp.exec_cmd(home .. "/.local/bin/hypr-keys"))

hl.bind("SUPER + C",
  hl.dsp.send_shortcut({
    mods = "CTRL",
    key = "C",
  }))

hl.bind("SUPER + V",
  hl.dsp.send_shortcut({
    mods = "CTRL",
    key = "V",
  }))

hl.bind("SUPER + SHIFT + V",
  hl.dsp.exec_cmd(home .. "/.local/bin/hypr-clipboard"))

-- Directional focus. Current Hyprland docs use lower-case key names.
hl.bind("SUPER + left",
  hl.dsp.focus({ direction = "l" }),
  { repeating = true })

hl.bind("SUPER + down",
  hl.dsp.focus({ direction = "d" }),
  { repeating = true })

hl.bind("SUPER + up",
  hl.dsp.focus({ direction = "u" }),
  { repeating = true })

hl.bind("SUPER + right",
  hl.dsp.focus({ direction = "r" }),
  { repeating = true })

-- Move the active window in a direction.
-- This is the current Lua dispatcher equivalent of directional movewindow.
hl.bind("SUPER + CTRL + left",
  hl.dsp.window.move({ direction = "l" }),
  { repeating = true })

hl.bind("SUPER + CTRL + down",
  hl.dsp.window.move({ direction = "d" }),
  { repeating = true })

hl.bind("SUPER + CTRL + up",
  hl.dsp.window.move({ direction = "u" }),
  { repeating = true })

hl.bind("SUPER + CTRL + right",
  hl.dsp.window.move({ direction = "r" }),
  { repeating = true })

hl.bind("SUPER + SHIFT + left",
  hl.dsp.window.resize({
    x = -60,
    y = 0,
    relative = true,
  }),
  { repeating = true })

hl.bind("SUPER + SHIFT + down",
  hl.dsp.window.resize({
    x = 0,
    y = 60,
    relative = true,
  }),
  { repeating = true })

hl.bind("SUPER + SHIFT + up",
  hl.dsp.window.resize({
    x = 0,
    y = -60,
    relative = true,
  }),
  { repeating = true })

hl.bind("SUPER + SHIFT + right",
  hl.dsp.window.resize({
    x = 60,
    y = 0,
    relative = true,
  }),
  { repeating = true })

-- Scrolling layout viewport.
hl.bind("SUPER + mouse_up",
  hl.dsp.layout("move -col"))

hl.bind("SUPER + mouse_down",
  hl.dsp.layout("move +col"))

-- Mouse drag/resize.
hl.bind("SUPER + mouse:272",
  hl.dsp.window.drag(),
  { mouse = true })

hl.bind("SUPER + mouse:273",
  hl.dsp.window.resize(),
  { mouse = true })

hl.bind("SUPER + L",
  hl.dsp.exec_cmd("hyprlock"))

hl.bind("SUPER + X",
  hl.dsp.exec_cmd(home .. "/.local/bin/hypr-power"))

hl.bind("SUPER + B",
  hl.dsp.exec_cmd("firefox"))

hl.bind("SUPER + SPACE",
  hl.dsp.exec_cmd(
    home .. "/.local/bin/rofi-safe -show drun -theme " ..
    home .. "/.config/rofi/current.rasi"
  ))

for i = 1, 5 do
  local ws = tostring(i)

  hl.bind("SUPER + " .. ws,
    hl.dsp.focus({
      workspace = ws,
    }))

  hl.bind("SUPER + SHIFT + " .. ws,
    hl.dsp.window.move({
      workspace = ws,
      follow = false,
    }))
end

hl.bind("Print",
  hl.dsp.exec_cmd(home .. "/.local/bin/hypr-screenshot region"))

hl.bind("SUPER + Print",
  hl.dsp.exec_cmd(home .. "/.local/bin/hypr-screenshot full"))

hl.bind("SUPER + SHIFT + Print",
  hl.dsp.exec_cmd(home .. "/.local/bin/hypr-screenshot window"))

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

# ================================================================
# Quickshell KDE-like top bar + popup
# ================================================================
cat > "$QS/theme.js" <<'EOF'
.pragma library
var bg = "#E61E1E2E"
var surface = "#F2313244"
var surface2 = "#F245475A"
var text = "#CDD6F4"
var subtext = "#BAC2DE"
var muted = "#7F849C"
var accent = "#CBA6F7"
var accent2 = "#F5C2E7"
var danger = "#F38BA8"
var border = "#806C7086"
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

    property string page: "calendar"
    readonly property string wallpaperUrl: wallpaperFile.text().trim()

    FileView {
        id: wallpaperFile
        path: Quickshell.env("HOME") + "/.cache/hypr-popup-wallpaper"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }

    function run(command, argument) {
        var args = [Quickshell.env("HOME") + "/.local/bin/qs-control", command]
        if (argument !== undefined)
            args.push(argument)
        Quickshell.execDetached(args)
    }

    function openPage(name) {
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
                    label: "󰣇"
                    highlight: true
                    onTriggered: root.run("launcher")
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
                                   ? Theme.accent
                                   : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: index + 1
                                color: Hyprland.focusedWorkspace &&
                                       Hyprland.focusedWorkspace.id === index + 1
                                       ? "#11111b"
                                       : Theme.subtext
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Hyprland.dispatch(
                                    "workspace " + (parent.index + 1)
                                )
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    leftPadding: 8
                    text: Hyprland.activeToplevel
                          ? Hyprland.activeToplevel.title
                          : "Hyprland"
                    color: Theme.subtext
                    elide: Text.ElideRight
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                }

                ClockButton {
                    onTriggered: root.openPage("calendar")
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
                                acceptedButtons:
                                    Qt.LeftButton |
                                    Qt.RightButton |
                                    Qt.MiddleButton
                                cursorShape: Qt.PointingHandCursor

                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton &&
                                        parent.modelData.hasMenu) {
                                        parent.modelData.display(
                                            bar,
                                            parent.x,
                                            36
                                        )
                                    } else if (mouse.button === Qt.MiddleButton) {
                                        parent.modelData.secondaryActivate()
                                    } else {
                                        parent.modelData.activate()
                                    }
                                }
                            }
                        }
                    }
                }

                BarButton {
                    label: "󰂯"
                    onTriggered: root.openPage("bluetooth")
                }

                BarButton {
                    label: "󰤨"
                    onTriggered: root.openPage("network")
                }

                BarButton {
                    label: "󰕾"
                    onTriggered: root.openPage("audio")
                }

                BarButton {
                    label: "󰂚"
                    onTriggered: root.run("notifications")
                }

                BarButton {
                    label: "󰍹"
                    onTriggered: root.openPage("display")
                }

                BarButton {
                    label: "󰾅"
                    onTriggered: root.openPage("power")
                }

                BarButton {
                    label: "󰐥"
                    highlight: true
                    onTriggered: root.openPage("session")
                }
            }
        }
    }

    PanelWindow {
        id: popup
        visible: false
        implicitWidth: 410
        implicitHeight: 440
        color: "transparent"
        focusable: true

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
            clip: true
            color: "transparent"
            border.width: 1
            border.color: Theme.border

            Image {
                anchors.fill: parent
                source: root.wallpaperUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                opacity: 0.52
            }

            Rectangle {
                anchors.fill: parent
                radius: 20
                color: Theme.bg
                opacity: 0.74
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
                            if (root.page === "network")
                                return "󰤨  Network"
                            if (root.page === "bluetooth")
                                return "󰂯  Bluetooth"
                            if (root.page === "audio")
                                return "󰕾  Audio"
                            if (root.page === "display")
                                return "󰍹  Display"
                            if (root.page === "power")
                                return "󰾅  Power"
                            if (root.page === "session")
                                return "󰐥  Session"
                            return "󰃭  Calendar"
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
                        font.pixelSize: 54
                        font.bold: true

                        Timer {
                            interval: 1000
                            repeat: true
                            running: true
                            triggeredOnStart: true
                            onTriggered: {
                                bigClock.text =
                                    Qt.formatDateTime(new Date(), "HH:mm")
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                PageButton {
                    visible: root.page === "network"
                    iconText: "󰤨"
                    titleText: "Network settings"
                    subText: "Wi-Fi / Ethernet / VPN"
                    onTriggered: root.run("network")
                }

                PageButton {
                    visible: root.page === "bluetooth"
                    iconText: "󰂯"
                    titleText: "Bluetooth devices"
                    subText: "Pair / connect / disconnect"
                    onTriggered: root.run("bluetooth")
                }

                ColumnLayout {
                    visible: root.page === "audio"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    PageButton {
                        iconText: "󰕾"
                        titleText: "Audio mixer"
                        subText: "Outputs / inputs / per-app volume"
                        onTriggered: root.run("audio")
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 7

                        MiniButton {
                            Layout.fillWidth: true
                            label: "󰝟 Mute"
                            onTriggered: root.run("volume-mute")
                        }

                        MiniButton {
                            Layout.fillWidth: true
                            label: "− Volume"
                            onTriggered: root.run("volume-down")
                        }

                        MiniButton {
                            Layout.fillWidth: true
                            label: "+ Volume"
                            onTriggered: root.run("volume-up")
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                PageButton {
                    visible: root.page === "display"
                    iconText: "󰍹"
                    titleText: "Display configuration"
                    subText: "Monitor layout / scale / resolution"
                    onTriggered: root.run("display")
                }

                PageButton {
                    visible: root.page === "power"
                    iconText: "󰾅"
                    titleText: "Power profiles"
                    subText: "Saver / Balanced / Performance"
                    onTriggered: root.run("power")
                }

                PageButton {
                    visible: root.page === "session"
                    iconText: "󰐥"
                    titleText: "Session & power"
                    subText: "Lock / sleep / logout / reboot / shutdown"
                    onTriggered: root.run("session")
                }

                Item {
                    visible: root.page !== "calendar" &&
                             root.page !== "audio"
                    Layout.fillHeight: true
                }
            }
        }

        onVisibleChanged: {
            if (visible) {
                card.scale = 0.94
                card.opacity = 0
                popupAnimation.restart()
            }
        }

        ParallelAnimation {
            id: popupAnimation

            NumberAnimation {
                target: card
                property: "scale"
                from: 0.94
                to: 1
                duration: 170
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: card
                property: "opacity"
                from: 0
                to: 1
                duration: 145
            }
        }
    }

    component BarButton: Rectangle {
        id: button

        property string label: ""
        property bool highlight: false
        signal triggered()

        implicitWidth: 34
        implicitHeight: 30
        radius: 10

        color: buttonMouse.containsMouse
               ? Theme.surface2
               : "transparent"

        Text {
            anchors.centerIn: parent
            text: button.label
            color: button.highlight ? Theme.accent : Theme.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 17
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.triggered()
        }
    }

    component ClockButton: Rectangle {
        id: clockButton

        signal triggered()

        implicitWidth: 72
        implicitHeight: 30
        radius: 10

        color: clockMouse.containsMouse
               ? Theme.surface2
               : "transparent"

        Text {
            id: clockLabel
            anchors.centerIn: parent
            color: Theme.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            font.bold: true

            Timer {
                interval: 1000
                repeat: true
                running: true
                triggeredOnStart: true
                onTriggered: {
                    clockLabel.text =
                        Qt.formatDateTime(new Date(), "HH:mm")
                }
            }
        }

        MouseArea {
            id: clockMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: clockButton.triggered()
        }
    }

    component PageButton: Rectangle {
        id: pageButton

        property string iconText: ""
        property string titleText: ""
        property string subText: ""
        signal triggered()

        Layout.fillWidth: true
        implicitHeight: 84
        radius: 15

        color: pageHover.containsMouse
               ? Theme.surface2
               : Theme.surface

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 13

            Text {
                text: pageButton.iconText
                color: Theme.accent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 25
            }

            ColumnLayout {
                Layout.fillWidth: true

                Text {
                    text: pageButton.titleText
                    color: Theme.text
                    font.pixelSize: 14
                    font.bold: true
                }

                Text {
                    text: pageButton.subText
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
            id: pageHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pageButton.triggered()
        }
    }

    component MiniButton: Rectangle {
        id: mini

        property string label: ""
        signal triggered()

        implicitHeight: 42
        radius: 12

        color: miniMouse.containsMouse
               ? Theme.surface2
               : Theme.surface

        Text {
            anchors.centerIn: parent
            text: mini.label
            color: Theme.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
        }

        MouseArea {
            id: miniMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mini.triggered()
        }
    }
}
EOF

# ================================================================
# SwayNC
# ================================================================
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
  "widgets": [
    "title",
    "dnd",
    "notifications"
  ]
}
EOF

# ================================================================
# Hyprlock / Hypridle
# ================================================================
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

# ================================================================
# Kitty
# ================================================================
cat > "$KITTY/kitty.conf" <<'EOF'
include theme.conf
font_family JetBrainsMono Nerd Font
font_size 11.5
window_padding_width 12
background_opacity 0.92
confirm_os_window_close 0
enable_audio_bell no
EOF

# Initial synchronized theme.
"$BIN/ui-theme-sync"

# ================================================================
# Validation
# ================================================================
log "Validating generated shell scripts..."
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

log "Validating SwayNC JSON..."
python3 - "$SWAYNC/config.json" <<'PY'
import json
import sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    json.load(f)
print("SwayNC JSON: OK")
PY

cat <<EOF

================================================================
 Hyprland Anime Desktop installed
================================================================

Hyprland main:
  $HYPR/hyprland.lua

Modules:
  $HYPR/config/env.lua
  $HYPR/config/monitors.lua
  $HYPR/config/general.lua
  $HYPR/config/theme.lua
  $HYPR/config/input.lua
  $HYPR/config/scrolling.lua
  $HYPR/config/animations.lua
  $HYPR/config/autostart.lua
  $HYPR/config/keybinds.lua

Important:
  SUPER + Enter       Kitty terminal
  SUPER + Space       App launcher
  SUPER + T           Theme selector
  SUPER + SHIFT + B   Wallpaper picker
  SUPER + X           Power menu
  SUPER + K           Keybind help

Rofi:
  - no linear-gradient
  - no background-image
  - palette synchronized by ui-theme-sync

Quickshell popup:
  - wallpaper image is loaded from:
    $CACHE/hypr-popup-wallpaper
  - popup gap is 6px below the top work area

Backup:
  $BACKUP

Reboot:
  sudo reboot

After login:
  hyprctl configerrors

Quickshell log:
  tail -100 /tmp/quickshell-hypr.log
================================================================
EOF
