#!/usr/bin/env bash
set -Eeuo pipefail

# ================================================================
# Arch Linux -> Hyprland 0.56.x Anime Desktop (FULL / CLEAN)
# - Modular Hyprland Lua config
# - Scrolling layout
# - Quickshell KDE-like bar + SNI tray + popup wallpaper
# - Catppuccin Pastel / Tokyo Night
# - Full Sweet stack: GTK + Kvantum + Sweet-Rainbow + Sweet-cursors
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
# Optional hardware / input-method setup
# ----------------------------------------------------------------
ENABLE_NVIDIA_ENV="n"
ENABLE_FCITX5="n"
CURSOR_THEME="Sweet-cursors"
CURSOR_SIZE="24"

read -r -p "Cursor theme [Sweet-cursors]: " CURSOR_INPUT
CURSOR_THEME="${CURSOR_INPUT:-Sweet-cursors}"

read -r -p "Cursor size [24]: " CURSOR_SIZE_INPUT
CURSOR_SIZE="${CURSOR_SIZE_INPUT:-24}"
[[ "$CURSOR_SIZE" =~ ^[0-9]+$ ]] || CURSOR_SIZE="24"

read -r -p "Thêm biến môi trường NVIDIA cho Hyprland? [y/N]: " ENABLE_NVIDIA_ENV
case "$ENABLE_NVIDIA_ENV" in
  y|Y|yes|YES) ENABLE_NVIDIA_ENV="y" ;;
  *) ENABLE_NVIDIA_ENV="n" ;;
esac

read -r -p "Cài Fcitx5 + Unikey và thêm biến môi trường Fcitx5? [y/N]: " ENABLE_FCITX5
case "$ENABLE_FCITX5" in
  y|Y|yes|YES) ENABLE_FCITX5="y" ;;
  *) ENABLE_FCITX5="n" ;;
esac

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
  flameshot

  kitty
  dolphin
  konsole
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
  breeze-icons
  adw-gtk-theme
  nwg-look
  qt6ct
  qt5ct
  kvantum
  kvantum-qt5

  jq
  git
  curl
  imagemagick
  libnotify
  wev
)

log "Installing packages..."
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

if [[ "$ENABLE_NVIDIA_ENV" == "y" ]]; then
  log "Installing NVIDIA VA-API userspace support..."
  sudo pacman -S --needed --noconfirm libva-nvidia-driver
fi

if [[ "$ENABLE_FCITX5" == "y" ]]; then
  log "Installing Fcitx5 + GTK/Qt integration + Unikey..."
  sudo pacman -S --needed --noconfirm     fcitx5     fcitx5-gtk     fcitx5-qt     fcitx5-configtool     fcitx5-unikey
fi

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
  "$CFG/gtk-3.0" \
  "$CFG/gtk-4.0" \
  "$CFG/qt5ct" \
  "$CFG/qt6ct" \
  "$CFG/Kvantum" \
  "$HOME/.local/share/icons" \
  "$BIN" \
  "$WALL" \
  "$CACHE"

xdg-user-dirs-update || true

# ================================================================
# Sweet GTK / Kvantum theme
# ================================================================
log "Installing Sweet GTK/Kvantum theme from upstream..."

mkdir -p "$HOME/.themes" "$CFG/Kvantum"

SWEET_TMP="$(mktemp -d)"
trap 'rm -rf "$SWEET_TMP"' EXIT

SWEET_GTK_NAME="Sweet"
SWEET_GTK_DIR="$HOME/.themes/Sweet"

# Prefer the latest official release asset for GTK.
# Fall back to a shallow source clone if GitHub API / release download fails.
sweet_asset_url="$(
  curl -fsSL --retry 3 \
    https://api.github.com/repos/EliverLara/Sweet/releases/latest 2>/dev/null |
  jq -r '
    [.assets[]
     | select(.name == "Sweet-Dark.tar.xz")
     | .browser_download_url][0] // empty
  ' 2>/dev/null || true
)"

if [[ -n "$sweet_asset_url" ]] &&
   curl -fL --retry 3 "$sweet_asset_url" -o "$SWEET_TMP/Sweet-Dark.tar.xz"; then
  mkdir -p "$SWEET_TMP/gtk-release"
  tar -xf "$SWEET_TMP/Sweet-Dark.tar.xz" -C "$SWEET_TMP/gtk-release"

  sweet_found="$(
    find "$SWEET_TMP/gtk-release" -mindepth 1 -maxdepth 2 -type d \
      \( -name 'Sweet-Dark' -o -name 'Sweet*' \) |
    head -1
  )"

  if [[ -n "$sweet_found" ]]; then
    SWEET_GTK_NAME="$(basename "$sweet_found")"
    rm -rf "$HOME/.themes/$SWEET_GTK_NAME"
    cp -a "$sweet_found" "$HOME/.themes/$SWEET_GTK_NAME"
    SWEET_GTK_DIR="$HOME/.themes/$SWEET_GTK_NAME"
ICON_THEME="$(cat "$CFG/hypr/.sweet-icon-theme" 2>/dev/null || echo Sweet-Rainbow)"
  fi
fi

# Source tree is also used to locate the official Sweet Kvantum files.
if git clone --depth 1 https://github.com/EliverLara/Sweet.git \
     "$SWEET_TMP/Sweet-src" >/dev/null 2>&1; then

  if [[ ! -d "$SWEET_GTK_DIR" ]] &&
     [[ -d "$SWEET_TMP/Sweet-src/gtk-3.0" ]]; then
    rm -rf "$HOME/.themes/Sweet"
    cp -a "$SWEET_TMP/Sweet-src" "$HOME/.themes/Sweet"
    SWEET_GTK_NAME="Sweet"
    SWEET_GTK_DIR="$HOME/.themes/Sweet"
  fi

  sweet_kvconfig="$(
    find "$SWEET_TMP/Sweet-src" -type f -name 'Sweet.kvconfig' |
    head -1
  )"

  if [[ -n "$sweet_kvconfig" ]]; then
    sweet_kv_dir="$(dirname "$sweet_kvconfig")"
    sweet_svg="$sweet_kv_dir/Sweet.svg"

    if [[ -f "$sweet_svg" ]]; then
      rm -rf "$CFG/Kvantum/Sweet"
      mkdir -p "$CFG/Kvantum/Sweet"
      cp -a "$sweet_kvconfig" "$CFG/Kvantum/Sweet/Sweet.kvconfig"
      cp -a "$sweet_svg" "$CFG/Kvantum/Sweet/Sweet.svg"

      # Copy optional companion assets from the same theme directory.
      find "$sweet_kv_dir" -maxdepth 1 -type f \
        ! -name 'Sweet.kvconfig' \
        ! -name 'Sweet.svg' \
        -exec cp -a {} "$CFG/Kvantum/Sweet/" \; 2>/dev/null || true
    else
      warn "Sweet.kvconfig found, but Sweet.svg was not found beside it."
    fi
  else
    warn "Could not locate Sweet Kvantum files in upstream source."
  fi
else
  warn "Could not clone Sweet source; GTK release theme may still be available."
fi

[[ -d "$SWEET_GTK_DIR" ]] ||
  warn "Sweet GTK theme was not installed successfully; GTK will fall back safely."

printf '%s\n' "$SWEET_GTK_NAME" > "$HYPR/.sweet-gtk-theme"

# ----------------------------------------------------------------
# Sweet icon + cursor stack
# ----------------------------------------------------------------
log "Installing Sweet-Rainbow icons + candy-icons + Sweet-cursors..."

ICONS_ROOT="$HOME/.local/share/icons"
SWEET_ICON_THEME="Sweet-Rainbow"
SWEET_CURSOR_THEME="Sweet-cursors"
mkdir -p "$ICONS_ROOT"

# Sweet-Rainbow contains the colorful folder layer and inherits candy-icons.
if git clone --depth 1 https://github.com/EliverLara/Sweet-folders.git \
     "$SWEET_TMP/Sweet-folders" >/dev/null 2>&1; then
  if [[ -d "$SWEET_TMP/Sweet-folders/Sweet-Rainbow" ]]; then
    rm -rf "$ICONS_ROOT/Sweet-Rainbow"
    cp -a "$SWEET_TMP/Sweet-folders/Sweet-Rainbow" \
      "$ICONS_ROOT/Sweet-Rainbow"
  else
    warn "Sweet-folders cloned, but Sweet-Rainbow was not found."
  fi
else
  warn "Could not clone Sweet-folders."
fi

# Sweet-Rainbow intentionally inherits candy-icons for application/file icons.
if git clone --depth 1 https://github.com/EliverLara/candy-icons.git \
     "$SWEET_TMP/candy-icons" >/dev/null 2>&1; then
  if [[ -f "$SWEET_TMP/candy-icons/index.theme" ]]; then
    rm -rf "$ICONS_ROOT/candy-icons"
    cp -a "$SWEET_TMP/candy-icons" "$ICONS_ROOT/candy-icons"
  else
    warn "candy-icons cloned, but index.theme was not found."
  fi
else
  warn "Could not clone candy-icons."
fi

# Official Sweet XCursor theme lives in the Sweet KDE tree.
# Prefer the upstream 'nova' branch because it contains the current cursor assets.
if git clone --depth 1 --branch nova https://github.com/EliverLara/Sweet.git \
     "$SWEET_TMP/Sweet-nova" >/dev/null 2>&1; then
  sweet_cursor_dir="$(
    find "$SWEET_TMP/Sweet-nova" -type d -name 'Sweet-cursors' -print -quit
  )"
else
  sweet_cursor_dir=""
fi

# Fall back to the already-cloned Sweet source if needed.
if [[ -z "${sweet_cursor_dir:-}" && -d "$SWEET_TMP/Sweet-src" ]]; then
  sweet_cursor_dir="$(
    find "$SWEET_TMP/Sweet-src" -type d -name 'Sweet-cursors' -print -quit
  )"
fi

if [[ -n "${sweet_cursor_dir:-}" && -f "$sweet_cursor_dir/index.theme" ]]; then
  rm -rf "$ICONS_ROOT/Sweet-cursors"
  cp -a "$sweet_cursor_dir" "$ICONS_ROOT/Sweet-cursors"
else
  warn "Sweet-cursors could not be located in upstream Sweet."
fi

# Refresh GTK icon caches when the helper exists. Failures are harmless because
# Qt/KDE/GTK can still load icon themes without a prebuilt user cache.
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  [[ -f "$ICONS_ROOT/candy-icons/index.theme" ]] &&
    gtk-update-icon-cache -f -t "$ICONS_ROOT/candy-icons" >/dev/null 2>&1 || true
  [[ -f "$ICONS_ROOT/Sweet-Rainbow/index.theme" ]] &&
    gtk-update-icon-cache -f -t "$ICONS_ROOT/Sweet-Rainbow" >/dev/null 2>&1 || true
fi

[[ -d "$ICONS_ROOT/Sweet-Rainbow" ]] ||
  warn "Sweet-Rainbow is unavailable; applications may fall back to Papirus/Breeze."
[[ -d "$ICONS_ROOT/candy-icons" ]] ||
  warn "candy-icons is unavailable; some Sweet-Rainbow application icons may fall back."
[[ -d "$ICONS_ROOT/Sweet-cursors/cursors" ]] ||
  warn "Sweet-cursors is unavailable; cursor fallback may be used."

printf '%s\n' "$SWEET_ICON_THEME" > "$HYPR/.sweet-icon-theme"
printf '%s\n' "$SWEET_CURSOR_THEME" > "$HYPR/.sweet-cursor-theme"

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


cat > "$BIN/rofi-wallpaper-mode" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

DIR="$HOME/Pictures/Wallpapers"
mkdir -p "$DIR"

# Rofi script mode:
# - first call prints entries
# - selected entry returns in $1 with ROFI_RETV=1
if [[ "${ROFI_RETV:-0}" == "0" ]]; then
  while IFS= read -r -d '' file; do
    name="$(basename "$file")"
    # Script-mode metadata: icon=<image path>
    printf '%s\0icon\x1f%s\n' "$name" "$file"
  done < <(
    find "$DIR" -maxdepth 1 -type f \
      \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
      -print0 | sort -z
  )
  exit 0
fi

selected="${1:-}"
[[ -n "$selected" ]] || exit 0

wall="$DIR/$selected"
[[ -f "$wall" ]] || exit 0

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

notify-send -a "Hypr Anime" "Wallpaper changed" "$selected"
EOF
chmod +x "$BIN/rofi-wallpaper-mode"

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

  background-color: transparent;
  text-color: @fg;
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
  background-color: @bg;
}

inputbar {
  padding: 11px 14px;
  spacing: 9px;
  border-radius: 13px;
  background-color: @bg2;
  text-color: @fg;
}

prompt {
  background-color: transparent;
  text-color: @accent2;
}

entry {
  background-color: transparent;
  text-color: @fg;
  placeholder-color: @muted;
}

case-indicator {
  background-color: transparent;
  text-color: @accent2;
}

listview {
  lines: 9;
  columns: 1;
  spacing: 5px;
  scrollbar: false;
  background-color: @bg;
}

element {
  padding: 10px 12px;
  spacing: 9px;
  border-radius: 12px;
  background-color: transparent;
  text-color: @fg;
}

element normal.normal,
element normal.active,
element normal.urgent {
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
  background-color: transparent;
  size: 28px;
}

element-text {
  background-color: transparent;
  text-color: inherit;
}

message {
  padding: 10px;
  border-radius: 12px;
  background-color: @bg2;
}

textbox {
  background-color: transparent;
  text-color: @fg;
}

scrollbar {
  handle-color: @accent;
  background-color: @bg2;
}
RASI

cat > "$CFG/rofi/wallpaper-grid.rasi" <<RASI
* {
  bg: $BG;
  bg2: $BG2;
  fg: $FG;
  muted: $MUTED;
  accent: $ACCENT;
  accent2: $ACCENT2;
  selectfg: $SELECTFG;
  borderc: $BORDER;

  background-color: transparent;
  text-color: @fg;
}

window {
  width: 860px;
  location: center;
  anchor: center;
  border: 2px;
  border-color: @borderc;
  border-radius: 22px;
  background-color: @bg;
  padding: 18px;
}

mainbox {
  spacing: 14px;
  background-color: @bg;
}

inputbar {
  padding: 11px 14px;
  border-radius: 13px;
  background-color: @bg2;
}

prompt {
  text-color: @accent2;
}

entry {
  text-color: @fg;
}

listview {
  columns: 4;
  lines: 3;
  flow: horizontal;
  spacing: 10px;
  fixed-height: true;
  fixed-columns: true;
  scrollbar: false;
  background-color: transparent;
}

element {
  orientation: vertical;
  children: [ element-icon, element-text ];
  width: 180px;
  height: 190px;
  spacing: 8px;
  padding: 9px;
  border-radius: 14px;
  background-color: @bg2;
}

element selected.normal,
element selected.active {
  background-color: @accent;
  text-color: @selectfg;
}

element-icon {
  size: 150px;
  horizontal-align: 0.5;
  background-color: transparent;
}

element-text {
  horizontal-align: 0.5;
  text-color: inherit;
}
RASI

cat > "$CFG/rofi/power.rasi" <<RASI
* {
  bg: $BG;
  bg2: $BG2;
  fg: $FG;
  muted: $MUTED;
  accent: $ACCENT;
  accent2: $ACCENT2;
  selectfg: $SELECTFG;
  borderc: $BORDER;
  background-color: transparent;
  text-color: @fg;
}

window {
  width: 780px;
  location: center;
  anchor: center;
  border: 2px;
  border-color: @borderc;
  border-radius: 22px;
  background-color: @bg;
  padding: 18px;
}

mainbox {
  spacing: 0px;
  background-color: @bg;
}

inputbar {
  enabled: false;
}

listview {
  lines: 1;
  columns: 5;
  fixed-columns: true;
  fixed-height: true;
  spacing: 10px;
  scrollbar: false;
  cycle: true;
  dynamic: false;
  background-color: transparent;
}

element {
  orientation: vertical;
  padding: 16px 12px;
  border-radius: 14px;
  background-color: @bg2;
}

element selected.normal,
element selected.active {
  background-color: @accent;
  text-color: @selectfg;
}

element-text {
  horizontal-align: 0.5;
  vertical-align: 0.5;
  text-color: inherit;
  font: "JetBrainsMono Nerd Font Bold 12";
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

# Toolkit theme sync: GTK + Qt5/Qt6 + Kvantum + cursor.
CURSOR_THEME="$(grep -m1 'HYPRCURSOR_THEME' "$CFG/hypr/config/env.lua" 2>/dev/null | sed -n 's/.*"\([^"]*\)").*/\1/p')"
CURSOR_SIZE="$(grep -m1 'HYPRCURSOR_SIZE' "$CFG/hypr/config/env.lua" 2>/dev/null | sed -n 's/.*"\([0-9][0-9]*\)").*/\1/p')"
CURSOR_THEME="${CURSOR_THEME:-Sweet-cursors}"
CURSOR_SIZE="${CURSOR_SIZE:-24}"

case "$THEME" in
  tokyo-night)
    GTK_ACCENT="#7aa2f7"
    GTK_ACCENT2="#bb9af7"
    GTK_BG="#1a1b26"
    GTK_FG="#c0caf5"
    KV_THEME="Sweet"
    ;;
  *)
    GTK_ACCENT="#cba6f7"
    GTK_ACCENT2="#f5c2e7"
    GTK_BG="#1e1e2e"
    GTK_FG="#cdd6f4"
    KV_THEME="Sweet"
    ;;
esac

SWEET_GTK_NAME="$(cat "$CFG/hypr/.sweet-gtk-theme" 2>/dev/null || echo Sweet)"
SWEET_GTK_DIR="$HOME/.themes/$SWEET_GTK_NAME"

for version in 3.0 4.0; do
  mkdir -p "$CFG/gtk-$version"
  cat > "$CFG/gtk-$version/settings.ini" <<GTK
[Settings]
gtk-theme-name=$SWEET_GTK_NAME
gtk-icon-theme-name=$ICON_THEME
gtk-font-name=Noto Sans 10
gtk-cursor-theme-name=$CURSOR_THEME
gtk-cursor-theme-size=$CURSOR_SIZE
gtk-application-prefer-dark-theme=1
GTK

done

# GTK4/libadwaita does not consistently honor gtk-theme-name.
# If the Sweet theme ships GTK4 assets, expose them in ~/.config/gtk-4.0.
if [[ -d "$SWEET_GTK_DIR/gtk-4.0" ]]; then
  rm -f "$CFG/gtk-4.0/gtk.css" "$CFG/gtk-4.0/gtk-dark.css"
  rm -rf "$CFG/gtk-4.0/assets"

  [[ -f "$SWEET_GTK_DIR/gtk-4.0/gtk.css" ]] &&
    ln -sfn "$SWEET_GTK_DIR/gtk-4.0/gtk.css" "$CFG/gtk-4.0/gtk.css"

  [[ -f "$SWEET_GTK_DIR/gtk-4.0/gtk-dark.css" ]] &&
    ln -sfn "$SWEET_GTK_DIR/gtk-4.0/gtk-dark.css" "$CFG/gtk-4.0/gtk-dark.css"

  [[ -d "$SWEET_GTK_DIR/gtk-4.0/assets" ]] &&
    ln -sfn "$SWEET_GTK_DIR/gtk-4.0/assets" "$CFG/gtk-4.0/assets"
fi

if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
  gsettings set org.gnome.desktop.interface gtk-theme "$SWEET_GTK_NAME" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE" 2>/dev/null || true
fi

mkdir -p "$CFG/Kvantum" "$CFG/qt5ct/colors" "$CFG/qt6ct/colors"

cat > "$CFG/Kvantum/kvantum.kvconfig" <<KV
[General]
theme=$KV_THEME
KV

FG="${GTK_FG#\#}"
BG="${GTK_BG#\#}"
ACC="${GTK_ACCENT#\#}"
ACC2="${GTK_ACCENT2#\#}"

for qt in qt5ct qt6ct; do
  cat > "$CFG/$qt/colors/hypr-anime.conf" <<QTCOLOR
[ColorScheme]
active_colors=#ff$FG, #ff$BG, #ff$BG, #ff$BG, #ff$BG, #ff$FG, #ff$FG, #ff$FG, #ff$FG, #ff$BG, #ff$BG, #ff$FG, #ff$ACC, #ff$BG, #ff$ACC2, #ff$FG, #ff$BG, #ff$FG, #ff$BG, #ff$FG, #ff$FG
disabled_colors=#ff7f849c, #ff$BG, #ff$BG, #ff$BG, #ff$BG, #ff7f849c, #ff7f849c, #ff7f849c, #ff7f849c, #ff$BG, #ff$BG, #ff7f849c, #ff$ACC, #ff$BG, #ff$ACC2, #ff7f849c, #ff$BG, #ff7f849c, #ff$BG, #ff7f849c, #ff7f849c
inactive_colors=#ff$FG, #ff$BG, #ff$BG, #ff$BG, #ff$BG, #ff$FG, #ff$FG, #ff$FG, #ff$FG, #ff$BG, #ff$BG, #ff$FG, #ff$ACC, #ff$BG, #ff$ACC2, #ff$FG, #ff$BG, #ff$FG, #ff$BG, #ff$FG, #ff$FG
QTCOLOR

  cat > "$CFG/$qt/${qt}.conf" <<QTCONF
[Appearance]
color_scheme_path=$CFG/$qt/colors/hypr-anime.conf
custom_palette=true
icon_theme=$ICON_THEME
standard_dialogs=default
style=kvantum

[Fonts]
fixed="JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"
general="Noto Sans,10,-1,5,50,0,0,0,0,0"
QTCONF
done

# KDE Frameworks applications such as Dolphin consult kdeglobals as well.
if command -v kwriteconfig6 >/dev/null 2>&1; then
  kwriteconfig6 --file kdeglobals --group Icons --key Theme "$ICON_THEME" || true
elif command -v kwriteconfig5 >/dev/null 2>&1; then
  kwriteconfig5 --file kdeglobals --group Icons --key Theme "$ICON_THEME" || true
fi

command -v kbuildsycoca6 >/dev/null 2>&1 && kbuildsycoca6 >/dev/null 2>&1 || true

# Sweet-cursors is an XCursor theme. Hyprland >= 0.37 only accepts real
# hyprcursor themes in `hyprctl setcursor`, so do not call it for Sweet-cursors.
# XCURSOR_THEME/XCURSOR_SIZE + GTK gsettings are the correct path here.
if command -v hyprctl >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  # XCursor environment changes apply reliably on the next Hyprland session.
  hyprctl reload >/dev/null 2>&1 || true
fi
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
quickshell -p "$HOME/.config/quickshell/shell.qml" >/tmp/quickshell-hypr.log 2>&1 &

notify-send -a "Hypr Anime" "Theme changed" "$choice"
EOF

cat > "$BIN/hypr-wallpaper" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

exec "$HOME/.local/bin/rofi-safe" \
  -show wallpaper \
  -modi "wallpaper:$HOME/.local/bin/rofi-wallpaper-mode" \
  -show-icons \
  -theme "$HOME/.config/rofi/wallpaper-grid.rasi"
EOF

cat > "$BIN/hypr-power" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

choice="$(printf '󰌾  Lock\n󰤄  Sleep\n󰜉  Reboot\n󰐥  Shutdown\n󰍃  Logout\n' | \
  "$HOME/.local/bin/rofi-safe" \
  -dmenu -i -p '' \
  -theme "$HOME/.config/rofi/power.rasi")"

case "$choice" in
  *Lock) hyprlock ;;
  *Sleep) systemctl suspend ;;
  *Reboot) systemctl reboot ;;
  *Shutdown) systemctl poweroff ;;
  *Logout)
    # Hyprland >= 0.55 uses Lua dispatchers. `hyprctl dispatch` expects
    # a Lua dispatcher expression, not the old hyprlang dispatcher name.
    exec hyprctl dispatch 'hl.dsp.exit()'
    ;;
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
PRINT                  Flameshot region / annotate
SUPER + PRINT          Flameshot fullscreen
SUPER + SHIFT + PRINT  Flameshot active window
KEYS
EOF

cat > "$BIN/hypr-screenshot" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

mode="${1:-region}"
dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +'%Y-%m-%d_%H-%M-%S').png"

# Force native Wayland rendering for Flameshot under Hyprland.
flame=(env QT_QPA_PLATFORM=wayland flameshot)

case "$mode" in
  region)
    # Interactive selection + annotation. Save and copy only when accepted.
    "${flame[@]}" gui \
      --clipboard \
      --path "$file"
    ;;

  full)
    # All monitors, no grim capture path.
    "${flame[@]}" full \
      --clipboard \
      --path "$file"
    ;;

  window)
    # Capture the active Hyprland window exactly using Flameshot's region option.
    geometry="$(
      hyprctl activewindow -j |
        jq -r '
          if (.at and .size and (.at|length) >= 2 and (.size|length) >= 2)
          then "\(.size[0])x\(.size[1])+\(.at[0])+\(.at[1])"
          else empty
          end
        '
    )"

    [[ -n "$geometry" ]] || exit 0

    "${flame[@]}" full \
      --region "$geometry" \
      --clipboard \
      --path "$file"
    ;;

  *)
    printf 'Usage: %s {region|full|window}
' "$0" >&2
    exit 2
    ;;
esac

# GUI cancellation produces no screenshot; don't show a false success notification.
if [[ -s "$file" ]]; then
  notify-send -a Screenshot \
    "Screenshot saved" \
    "$file"
fi
EOF

cat > "$BIN/qs-control" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

cmd="${1:-}"

case "$cmd" in
  launcher)
    "$HOME/.local/bin/rofi-safe" \
      -show drun -show-icons \
      -theme "$HOME/.config/rofi/current.rasi"
    ;;

  network-kind)
    # Prefer the currently connected interface. If disconnected, report
    # the available hardware type so the bar remains useful.
    wifi_connected="$(nmcli -t -f TYPE,STATE device status 2>/dev/null | grep '^wifi:connected$' | head -1 || true)"
    eth_connected="$(nmcli -t -f TYPE,STATE device status 2>/dev/null | grep '^ethernet:connected$' | head -1 || true)"
    wifi_any="$(nmcli -t -f TYPE device status 2>/dev/null | grep '^wifi$' | head -1 || true)"
    eth_any="$(nmcli -t -f TYPE device status 2>/dev/null | grep '^ethernet$' | head -1 || true)"

    if [[ -n "$wifi_connected" ]]; then
      echo wifi
    elif [[ -n "$eth_connected" ]]; then
      echo ethernet
    elif [[ -n "$wifi_any" ]]; then
      echo wifi-disconnected
    elif [[ -n "$eth_any" ]]; then
      echo ethernet-disconnected
    else
      echo none
    fi
    ;;

  network-label)
    kind="$("$0" network-kind)"
    case "$kind" in
      wifi)
        nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null |
          awk -F: '$1=="yes"{sub(/^yes:/,"");print;exit}'
        ;;
      ethernet)
        nmcli -t -f NAME,TYPE connection show --active 2>/dev/null |
          awk -F: '$2=="802-3-ethernet"{print $1;exit}'
        ;;
      wifi-disconnected) echo "Wi-Fi disconnected" ;;
      ethernet-disconnected) echo "Ethernet disconnected" ;;
      *) echo "No network" ;;
    esac
    ;;

  network)
    nm-connection-editor >/dev/null 2>&1 &
    ;;

  bluetooth-exists)
    if bluetoothctl list 2>/dev/null | grep -q '^Controller '; then
      echo yes
    else
      echo no
    fi
    ;;

  bluetooth)
    blueman-manager >/dev/null 2>&1 &
    ;;

  battery-exists)
    if upower -e 2>/dev/null | grep -q '/battery_'; then
      echo yes
    else
      echo no
    fi
    ;;

  battery-status)
    dev="$(upower -e 2>/dev/null | grep '/battery_' | head -1 || true)"
    if [[ -z "$dev" ]]; then
      echo "none"
      exit 0
    fi
    info="$(upower -i "$dev" 2>/dev/null || true)"
    pct="$(awk '/percentage:/ {gsub("%","",$2); print $2; exit}' <<<"$info")"
    state="$(awk '/state:/ {print $2; exit}' <<<"$info")"
    printf '%s|%s\n' "${pct:-0}" "${state:-unknown}"
    ;;

  audio-output)
    wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null |
      awk '{
        v=int($2*100+0.5);
        m=($0 ~ /\[MUTED\]/ ? "muted" : "on");
        printf "%d|%s\n",v,m
      }'
    ;;

  audio-input-exists)
    # A default source may exist as a monitor even without a physical mic.
    # Filter monitor sources and require a real source node.
    if wpctl status 2>/dev/null |
       sed -n '/Sources:/,/Filters:/p' |
       grep -v -i 'monitor' |
       grep -Eq '[0-9]+\.'; then
      echo yes
    else
      echo no
    fi
    ;;

  audio-input)
    if [[ "$("$0" audio-input-exists)" != "yes" ]]; then
      echo "none"
      exit 0
    fi
    wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null |
      awk '{
        v=int($2*100+0.5);
        m=($0 ~ /\[MUTED\]/ ? "muted" : "on");
        printf "%d|%s\n",v,m
      }'
    ;;

  audio)
    pavucontrol >/dev/null 2>&1 &
    ;;

  output-set)
    value="${2:-50}"
    wpctl set-volume @DEFAULT_AUDIO_SINK@ "${value}%"
    ;;

  input-set)
    value="${2:-50}"
    wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "${value}%"
    ;;

  output-mute)
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    ;;

  input-mute)
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    ;;

  system-stats)
    # Output:
    # ram_used|ram_total|swap_used_or_none|swap_total_or_none|disk_used|disk_total|cpu_pct|cpu_cores|cpu_threads|gpu_pct_or_none|gpu_vram_total_gb_or_none
    read -r mem_total mem_avail swap_total swap_free < <(
      awk '
        /MemTotal:/     { mt=$2 }
        /MemAvailable:/ { ma=$2 }
        /SwapTotal:/    { st=$2 }
        /SwapFree:/     { sf=$2 }
        END { print mt, ma, st, sf }
      ' /proc/meminfo
    )

    ram_used_gb="$(awk -v t="$mem_total" -v a="$mem_avail" 'BEGIN { printf "%.1f", (t-a)/1048576 }')"
    ram_total_gb="$(awk -v t="$mem_total" 'BEGIN { printf "%.0f", t/1048576 }')"

    if [[ "${swap_total:-0}" -gt 0 ]]; then
      swap_used_gb="$(awk -v t="$swap_total" -v f="$swap_free" 'BEGIN { printf "%.1f", (t-f)/1048576 }')"
      swap_total_gb="$(awk -v t="$swap_total" 'BEGIN { printf "%.0f", t/1048576 }')"
    else
      swap_used_gb="none"
      swap_total_gb="none"
    fi

    read -r disk_used disk_total < <(df -B1 --output=used,size / 2>/dev/null | awk 'NR==2 {print $1, $2}')
    disk_used_gb="$(awk -v b="${disk_used:-0}" 'BEGIN { printf "%.0f", b/1073741824 }')"
    disk_total_gb="$(awk -v b="${disk_total:-0}" 'BEGIN { printf "%.0f", b/1073741824 }')"

    # Physical core count (e.g. 6C/12T -> CPU (6)); fall back to online logical CPUs.
    cpu_cores="$(
      lscpu -p=CORE,SOCKET 2>/dev/null \
        | awk -F, '!/^#/ { key=$1 ":" $2; seen[key]=1 } END { print length(seen) }'
    )"
    if [[ -z "${cpu_cores:-}" || "$cpu_cores" -lt 1 ]]; then
      cpu_cores="$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
    fi
    cpu_threads="$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo "$cpu_cores")"

    read_cpu() {
      awk '/^cpu / {
        idle=$5+$6; total=0;
        for (i=2; i<=NF; i++) total += $i;
        print total, idle; exit
      }' /proc/stat
    }

    read -r cpu_total_1 cpu_idle_1 < <(read_cpu)
    sleep 0.15
    read -r cpu_total_2 cpu_idle_2 < <(read_cpu)
    cpu_pct="$(awk -v t1="$cpu_total_1" -v i1="$cpu_idle_1" -v t2="$cpu_total_2" -v i2="$cpu_idle_2" '
      BEGIN {
        dt=t2-t1; di=i2-i1;
        if (dt <= 0) print 0;
        else { v=(100*(dt-di)/dt); if (v<0) v=0; if (v>100) v=100; printf "%.0f", v }
      }
    ')"

    gpu_pct="none"
    gpu_vram_total_gb="none"
    if command -v nvidia-smi >/dev/null 2>&1; then
      value="$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -dc '0-9' || true)"
      [[ -n "$value" ]] && gpu_pct="$value"
      vram_mib="$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -dc '0-9.' || true)"
      if [[ -n "$vram_mib" ]]; then
        gpu_vram_total_gb="$(awk -v m="$vram_mib" 'BEGIN { v=m/1024; if (v == int(v)) printf "%.0f", v; else printf "%.1f", v }')"
      fi
    fi

    if [[ "$gpu_pct" == "none" ]]; then
      for busy in /sys/class/drm/card*/device/gpu_busy_percent; do
        [[ -r "$busy" ]] || continue
        value="$(tr -dc '0-9' < "$busy" 2>/dev/null || true)"
        if [[ -n "$value" ]]; then
          gpu_pct="$value"
          vram_file="${busy%/gpu_busy_percent}/mem_info_vram_total"
          if [[ -r "$vram_file" ]]; then
            vram_bytes="$(tr -dc '0-9' < "$vram_file" 2>/dev/null || true)"
            if [[ -n "$vram_bytes" && "$vram_bytes" -gt 0 ]]; then
              gpu_vram_total_gb="$(awk -v b="$vram_bytes" 'BEGIN { v=b/1073741824; if (v == int(v)) printf "%.0f", v; else printf "%.1f", v }')"
            fi
          fi
          break
        fi
      done
    fi

    printf '%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n' \
      "$ram_used_gb" "$ram_total_gb" "$swap_used_gb" "$swap_total_gb" \
      "$disk_used_gb" "$disk_total_gb" "$cpu_pct" "$cpu_cores" "$cpu_threads" "$gpu_pct" "$gpu_vram_total_gb"
    ;;

  cpu-detail)
    # Safe text-only CPU popup backend. Avoids dynamic QML models/delegates.
    physical="$(( $(lscpu -p=CORE,SOCKET 2>/dev/null | awk -F, '!/^#/ { k=$1 ":" $2; seen[k]=1 } END { print length(seen) }') + 0 ))"
    logical="$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
    (( physical > 0 )) || physical="$logical"

    tmp1="$(mktemp)"
    tmp2="$(mktemp)"
    trap 'rm -f "$tmp1" "$tmp2"' EXIT
    awk '/^cpu[0-9]+ / { idle=$5+$6; total=0; for(i=2;i<=NF;i++) total+=$i; print $1,total,idle }' /proc/stat > "$tmp1"
    sleep 0.15
    awk '/^cpu[0-9]+ / { idle=$5+$6; total=0; for(i=2;i<=NF;i++) total+=$i; print $1,total,idle }' /proc/stat > "$tmp2"

    printf '%s cores / %s threads\n\n' "$physical" "$logical"
    awk '
      NR==FNR { t[$1]=$2; i[$1]=$3; next }
      {
        dt=$2-t[$1]; di=$3-i[$1]; p=(dt>0 ? 100*(dt-di)/dt : 0);
        if (p<0) p=0; if (p>100) p=100;
        n=int((p+5)/10); bar="";
        for (j=0;j<10;j++) bar=bar (j<n ? "━" : "─");
        idx=$1; sub(/^cpu/, "", idx);
        printf "CPU %-2s  %3.0f%%  %s\n", idx, p, bar;
      }
    ' "$tmp1" "$tmp2"
    ;;

  disk-list)
    # mount|used_gib|total_gib|percent
    # Show real/local filesystems and hide pseudo filesystems.
    df -B1 -P \
      -x tmpfs -x devtmpfs -x squashfs -x overlay -x efivarfs \
      2>/dev/null | awk '
        NR > 1 {
          mount=$6
          # Ignore runtime/system pseudo mount trees even if backed by a block-like source.
          if (mount ~ /^\/(proc|sys|dev|run)(\/|$)/) next
          used=$3/1073741824
          total=$2/1073741824
          pct=$5; gsub(/%/, "", pct)
          printf "%s|%.1f|%.1f|%d\n", mount, used, total, pct
        }
      ' | sort -t'|' -k1,1
    ;;

  open-path)
    path="${2:-$HOME}"
    dolphin "$path" >/dev/null 2>&1 &
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

  *)
    exit 2
    ;;
esac
EOF

cat > "$BIN/hypr-startup" <<'EOF'
#!/usr/bin/env bash
set -u

pgrep -x awww-daemon >/dev/null || awww-daemon >/dev/null 2>&1 &
pgrep -x swaync >/dev/null || swaync >/dev/null 2>&1 &
pgrep -x hypridle >/dev/null || hypridle >/dev/null 2>&1 &

if command -v fcitx5 >/dev/null 2>&1; then
  pgrep -x fcitx5 >/dev/null || fcitx5 -d >/dev/null 2>&1
fi

pgrep -f polkit-gnome-authentication-agent-1 >/dev/null || \
  /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 >/dev/null 2>&1 &

pgrep -f "wl-paste.*cliphist store" >/dev/null || \
  wl-paste --type text --watch cliphist store >/dev/null 2>&1 &

pgrep -f "wl-paste.*image.*cliphist store" >/dev/null || \
  wl-paste --type image --watch cliphist store >/dev/null 2>&1 &

"$HOME/.local/bin/ui-theme-sync" >/dev/null 2>&1 || true

pkill quickshell 2>/dev/null || true
quickshell -p "$HOME/.config/quickshell/shell.qml" >/tmp/quickshell-hypr.log 2>&1 &

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
  "$BIN/rofi-wallpaper-mode" \
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
# Optional Hyprland environment modules
# ================================================================
rm -f "$HYPR/config/env-nvidia.lua" "$HYPR/config/env-fcitx5.lua"

if [[ "$ENABLE_NVIDIA_ENV" == "y" ]]; then
  cat > "$HYPR/config/env-nvidia.lua" <<'EOF'
-- NVIDIA-specific environment.
-- Current Hyprland wiki recommends these for NVIDIA sessions.
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
EOF
fi

if [[ "$ENABLE_FCITX5" == "y" ]]; then
  cat > "$HYPR/config/env-fcitx5.lua" <<'EOF'
-- Fcitx5 integration.
-- Values use "fcitx", not "fcitx5".
hl.env("GTK_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("SDL_IM_MODULE", "fcitx")
EOF
fi

# ================================================================
# Hyprland modular Lua config
# ================================================================
cat > "$HYPR/hyprland.lua" <<EOF
require("config.env")
$([[ "$ENABLE_NVIDIA_ENV" == "y" ]] && echo 'require("config.env-nvidia")')
$([[ "$ENABLE_FCITX5" == "y" ]] && echo 'require("config.env-fcitx5")')
require("config.monitors")
require("config.general")
require("config.theme")
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
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
-- Sweet-cursors is an XCursor theme. With no HYPRCURSOR_THEME set,
-- Hyprland falls back to XCursor as documented by the Hyprland wiki.
hl.env("XCURSOR_THEME", "__CURSOR_THEME__")
hl.env("XCURSOR_SIZE", "__CURSOR_SIZE__")
EOF

sed -i \
  -e "s|__CURSOR_THEME__|$CURSOR_THEME|g" \
  -e "s|__CURSOR_SIZE__|$CURSOR_SIZE|g" \
  "$HYPR/config/env.lua"

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
cat > "$HYPR/config/rules.lua" <<'EOF'
-- Dolphin as a centered popup-style file manager.
-- The main window gets a roomy size; modal child dialogs stay smaller.
hl.window_rule({
  name = "dolphin-popup-main",
  match = {
    class = "^(org[.]kde[.]dolphin)$",
    modal = false,
  },
  float = true,
  center = true,
  size = { "monitor_w*0.78", "monitor_h*0.80" },
  persistent_size = true,
})

hl.window_rule({
  name = "dolphin-popup-modal",
  match = {
    class = "^(org[.]kde[.]dolphin)$",
    modal = true,
  },
  float = true,
  center = true,
  size = { "monitor_w*0.50", "monitor_h*0.38" },
})
EOF

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
  hl.dsp.exit())

hl.bind("SUPER + E",
  hl.dsp.exec_cmd("dolphin"))

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
    home .. "/.local/bin/rofi-safe -show drun -show-icons -theme " ..
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
//@ pragma UseQApplication

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

    property string networkKind: "none"
    property string networkLabel: ""
    property bool bluetoothAvailable: false
    property bool batteryAvailable: false
    property string batteryData: "none"

    property int outputVolume: 0
    property bool outputMuted: false
    property bool microphoneAvailable: false
    property int microphoneVolume: 0
    property bool microphoneMuted: false

    property string ramUsedGb: "0.0"
    property string ramTotalGb: "0"
    property string swapUsedGb: "none"
    property string swapTotalGb: "none"
    property string diskUsedGb: "0"
    property string diskTotalGb: "0"
    property int cpuUsage: 0
    property int cpuCores: 1
    property int cpuThreads: 1
    property string cpuDetailText: "Loading CPU details..."
    property int gpuUsage: -1
    property string gpuVramTotalGb: "none"
    property var diskMounts: []

    property int calendarMonthOffset: 0
    property bool systemClusterExpanded: false
    property bool trayClusterExpanded: false

    readonly property string wallpaperUrl: wallpaperFile.text().trim()

    FileView {
        id: wallpaperFile
        path: Quickshell.env("HOME") + "/.cache/hypr-popup-wallpaper"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }

    function execControl(command, argument) {
        var p = processFactory.createObject(root)
        p.command = [
            Quickshell.env("HOME") + "/.local/bin/qs-control",
            command
        ]

        if (argument !== undefined)
            p.command.push(String(argument))

        p.running = true
    }

    function openPage(name) {
        page = name

        if (name === "calendar") {
            systemPopup.visible = false
            calendarPopup.visible = true
        } else {
            calendarPopup.visible = false
            systemPopup.visible = true
        }

        refresh()
    }

    function refresh() {
        networkKindProc.running = true
        networkLabelProc.running = true
        bluetoothProc.running = true
        batteryExistsProc.running = true
        batteryProc.running = true
        outputProc.running = true
        microphoneExistsProc.running = true
        microphoneProc.running = true
    }

    function networkIcon() {
        if (networkKind === "wifi")
            return "󰤨"
        if (networkKind === "wifi-disconnected")
            return "󰤭"
        if (networkKind === "ethernet")
            return "󰈀"
        if (networkKind === "ethernet-disconnected")
            return "󰈂"
        return ""
    }

    function batteryIcon() {
        var pct = Number((batteryData.split("|")[0] || "0"))
        var state = batteryData.split("|")[1] || ""

        if (state === "charging")
            return "󰂄"

        if (pct <= 15) return "󰁺"
        if (pct <= 30) return "󰁼"
        if (pct <= 50) return "󰁾"
        if (pct <= 70) return "󰂀"
        if (pct <= 90) return "󰂂"
        return "󰁹"
    }

    function clockDateString() {
        return Qt.formatDateTime(
            new Date(),
            "HH:mm  •  ddd, dd MMM"
        )
    }

    function monthDate() {
        var now = new Date()

        return new Date(
            now.getFullYear(),
            now.getMonth() + calendarMonthOffset,
            1
        )
    }

    function monthTitle() {
        return Qt.formatDate(monthDate(), "MMMM yyyy")
    }

    function monthStartOffset() {
        var day = monthDate().getDay()
        return (day + 6) % 7
    }

    function daysInMonth() {
        var d = monthDate()

        return new Date(
            d.getFullYear(),
            d.getMonth() + 1,
            0
        ).getDate()
    }

    function cellDay(index) {
        var day = index - monthStartOffset() + 1

        return day >= 1 && day <= daysInMonth()
               ? day
               : 0
    }

    function isToday(day) {
        if (day === 0)
            return false

        var now = new Date()
        var shown = monthDate()

        return day === now.getDate() &&
               shown.getMonth() === now.getMonth() &&
               shown.getFullYear() === now.getFullYear()
    }

    Component {
        id: processFactory
        Process {}
    }

    Process {
        id: networkKindProc
        command: [
            Quickshell.env("HOME") + "/.local/bin/qs-control",
            "network-kind"
        ]

        stdout: StdioCollector {
            onStreamFinished: root.networkKind = text.trim()
        }
    }

    Process {
        id: networkLabelProc
        command: [
            Quickshell.env("HOME") + "/.local/bin/qs-control",
            "network-label"
        ]

        stdout: StdioCollector {
            onStreamFinished: root.networkLabel = text.trim()
        }
    }

    Process {
        id: bluetoothProc
        command: [
            Quickshell.env("HOME") + "/.local/bin/qs-control",
            "bluetooth-exists"
        ]

        stdout: StdioCollector {
            onStreamFinished:
                root.bluetoothAvailable = text.trim() === "yes"
        }
    }

    Process {
        id: batteryExistsProc
        command: [
            Quickshell.env("HOME") + "/.local/bin/qs-control",
            "battery-exists"
        ]

        stdout: StdioCollector {
            onStreamFinished:
                root.batteryAvailable = text.trim() === "yes"
        }
    }

    Process {
        id: batteryProc
        command: [
            Quickshell.env("HOME") + "/.local/bin/qs-control",
            "battery-status"
        ]

        stdout: StdioCollector {
            onStreamFinished:
                root.batteryData = text.trim()
        }
    }

    Process {
        id: outputProc
        command: [
            Quickshell.env("HOME") + "/.local/bin/qs-control",
            "audio-output"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("|")
                root.outputVolume = Number(parts[0] || 0)
                root.outputMuted = (parts[1] || "") === "muted"
            }
        }
    }

    Process {
        id: microphoneExistsProc
        command: [
            Quickshell.env("HOME") + "/.local/bin/qs-control",
            "audio-input-exists"
        ]

        stdout: StdioCollector {
            onStreamFinished:
                root.microphoneAvailable = text.trim() === "yes"
        }
    }

    Process {
        id: microphoneProc
        command: [
            Quickshell.env("HOME") + "/.local/bin/qs-control",
            "audio-input"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                var value = text.trim()

                if (value === "none")
                    return

                var parts = value.split("|")
                root.microphoneVolume = Number(parts[0] || 0)
                root.microphoneMuted = (parts[1] || "") === "muted"
            }
        }
    }

    Process {
        id: systemStatsProc
        command: [
            Quickshell.env("HOME") + "/.local/bin/qs-control",
            "system-stats"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("|")
                if (parts.length < 11)
                    return

                root.ramUsedGb = parts[0] || "0.0"
                root.ramTotalGb = parts[1] || "0"
                root.swapUsedGb = parts[2] || "none"
                root.swapTotalGb = parts[3] || "none"
                root.diskUsedGb = parts[4] || "0"
                root.diskTotalGb = parts[5] || "0"
                root.cpuUsage = Math.max(0, Math.min(100, Number(parts[6] || 0)))
                root.cpuCores = Math.max(1, Number(parts[7] || 1))
                root.cpuThreads = Math.max(1, Number(parts[8] || root.cpuCores))
                root.gpuUsage = parts[9] === "none"
                    ? -1
                    : Math.max(0, Math.min(100, Number(parts[9] || 0)))
                root.gpuVramTotalGb = parts[10] || "none"
            }
        }
    }

    Process {
        id: cpuDetailProc
        command: [
            Quickshell.env("HOME") + "/.local/bin/qs-control",
            "cpu-detail"
        ]

        stdout: StdioCollector {
            onStreamFinished: root.cpuDetailText = text.trim()
        }
    }

    Process {
        id: diskListProc
        command: [
            Quickshell.env("HOME") + "/.local/bin/qs-control",
            "disk-list"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                var rows = []
                var lines = text.trim().split("\n")

                for (var i = 0; i < lines.length; ++i) {
                    if (!lines[i])
                        continue

                    var p = lines[i].split("|")
                    if (p.length < 4)
                        continue

                    rows.push({
                        mount: p[0],
                        used: p[1],
                        total: p[2],
                        percent: Math.max(0, Math.min(100, Number(p[3] || 0)))
                    })
                }

                root.diskMounts = rows
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (!systemStatsProc.running)
                systemStatsProc.running = true
        }
    }

    Timer {
        interval: 3500
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: systemClusterHideTimer
        interval: 220
        repeat: false

        onTriggered:
            root.systemClusterExpanded = false
    }

    Timer {
        id: trayClusterHideTimer
        interval: 220
        repeat: false

        onTriggered:
            root.trayClusterExpanded = false
    }

    // ============================================================
    // TOP BAR
    // ============================================================
    PanelWindow {
        id: bar

        implicitHeight: 56
        exclusiveZone: 56
        aboveWindows: true
        color: "transparent"

        anchors {
            top: true
            left: true
            right: true
        }

        margins {
            top: 0
            bottom: 0
            left: 0
            right: 0
        }

        Rectangle {
            id: barSurface
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                leftMargin: 10
                rightMargin: 10
                topMargin: 7
                bottomMargin: 5
            }
            radius: 16
            color: "#1E1E2E"
            border.width: 1
            border.color: Theme.border
            antialiasing: true

            // Left: launcher + workspaces only.
            Row {
                height: 30
                anchors.left: parent.left
                anchors.leftMargin: 11
                anchors.verticalCenter: parent.verticalCenter
                spacing: 7

                BarButton {
                    label: "󰣇"
                    highlight: true
                    onTriggered: root.execControl("launcher")
                }

                Row {
                    height: 30
                    spacing: 3

                    Repeater {
                        model: 5

                        Rectangle {
                            required property int index

                            width: 30
                            height: 30
                            radius: 10

                            color:
                                Hyprland.focusedWorkspace &&
                                Hyprland.focusedWorkspace.id === index + 1
                                ? Theme.accent
                                : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: index + 1

                                color:
                                    Hyprland.focusedWorkspace &&
                                    Hyprland.focusedWorkspace.id === index + 1
                                    ? "#11111b"
                                    : Theme.subtext

                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor

                                onClicked:
                                    Hyprland.dispatch(
                                        "workspace " + (parent.index + 1)
                                    )
                            }
                        }
                    }
                }

                // Compact system telemetry directly to the right of workspaces.
                Item {
                    width: 9
                    height: 30

                    Rectangle {
                        anchors.centerIn: parent
                        width: 1
                        height: 20
                        color: Theme.border
                    }
                }

                Row {
                    id: systemTelemetry
                    height: 30
                    spacing: 7

                    // Every telemetry item uses the same 28px container so icons,
                    // labels and bars share one visual baseline with the workspaces.
                    Rectangle {
                        id: diskTelemetry
                        implicitWidth: diskTelemetryRow.implicitWidth + 12
                        width: implicitWidth
                        height: 30
                        radius: 9
                        color: diskTelemetryMouse.containsMouse ? Theme.surface2 : "transparent"

                        Row {
                            id: diskTelemetryRow
                            anchors.centerIn: parent
                            height: 30
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰋊"
                                color: Theme.accent
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.diskUsedGb + "GB/" + root.diskTotalGb + "GB"
                                color: Theme.text
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: diskTelemetryMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!diskListProc.running)
                                    diskListProc.running = true
                                diskPopup.visible = !diskPopup.visible
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: ramTelemetryRow.implicitWidth + 4
                        width: implicitWidth
                        height: 30
                        color: "transparent"

                        Row {
                            id: ramTelemetryRow
                            anchors.centerIn: parent
                            height: 30
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰍛"
                                color: Theme.accent
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.ramUsedGb + "GB/" + root.ramTotalGb + "GB"
                                color: Theme.text
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }
                    }

                    Rectangle {
                        visible: root.swapUsedGb !== "none"
                        implicitWidth: swapTelemetryRow.implicitWidth + 4
                        width: visible ? implicitWidth : 0
                        height: 30
                        color: "transparent"

                        Row {
                            id: swapTelemetryRow
                            anchors.centerIn: parent
                            height: 30
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰾴"
                                color: Theme.accent2
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.swapUsedGb + "GB/" + root.swapTotalGb + "GB"
                                color: Theme.text
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }
                    }

                    Item {
                        width: 9
                        height: 30

                        Rectangle {
                            anchors.centerIn: parent
                            width: 1
                            height: 20
                            color: Theme.border
                        }
                    }

                    Rectangle {
                        id: cpuTelemetry
                        implicitWidth: cpuTelemetryRow.implicitWidth + 8
                        width: implicitWidth
                        height: 30
                        radius: 8
                        color: cpuTelemetryMouse.containsMouse ? Theme.surface2 : "transparent"

                        Row {
                            id: cpuTelemetryRow
                            anchors.centerIn: parent
                            height: 30
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "CPU (" + root.cpuCores + ")"
                                color: Theme.subtext
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                font.bold: true
                            }

                            Rectangle {
                                width: 48
                                height: 6
                                radius: 3
                                color: Theme.surface2
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    width: parent.width * root.cpuUsage / 100
                                    height: parent.height
                                    radius: parent.radius
                                    color: Theme.accent

                                    Behavior on width {
                                        NumberAnimation { duration: 180 }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: cpuTelemetryMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!cpuDetailProc.running)
                                    cpuDetailProc.running = true
                                cpuPopup.visible = !cpuPopup.visible
                            }
                        }
                    }

                    Rectangle {
                        visible: root.gpuUsage >= 0
                        implicitWidth: gpuTelemetryRow.implicitWidth
                        width: visible ? implicitWidth : 0
                        height: 30
                        color: "transparent"

                        Row {
                            id: gpuTelemetryRow
                            anchors.centerIn: parent
                            height: 30
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.gpuVramTotalGb === "none" ? "GPU" : "GPU (" + root.gpuVramTotalGb + "GB)"
                                color: Theme.subtext
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                font.bold: true
                            }

                            Rectangle {
                                width: 48
                                height: 6
                                radius: 3
                                color: Theme.surface2
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    width: parent.width * root.gpuUsage / 100
                                    height: parent.height
                                    radius: parent.radius
                                    color: Theme.accent2

                                    Behavior on width {
                                        NumberAnimation { duration: 180 }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Center: one synchronized clock/date string.
            Rectangle {
                id: centerClock

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                implicitWidth: 205
                implicitHeight: 32
                radius: 11

                color:
                    centerClockMouse.containsMouse
                    ? Theme.surface2
                    : "transparent"

                Text {
                    id: clockDateLabel

                    anchors.centerIn: parent
                    color: Theme.text
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    id: centerClockMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked:
                        root.openPage("calendar")
                }

                Timer {
                    interval: 1000
                    repeat: true
                    running: true
                    triggeredOnStart: true

                    onTriggered:
                        clockDateLabel.text =
                            root.clockDateString()
                }
            }

            // Right: tray + hover-reveal system cluster + persistent power.
            Row {
                id: rightCluster

                anchors.right: parent.right
                anchors.rightMargin: 11
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5

                // Application system tray collapsed into one hover-reveal button.
                Row {
                    id: trayCluster
                    spacing: 5

                    visible: root.trayClusterExpanded

                    opacity:
                        root.trayClusterExpanded
                        ? 1
                        : 0

                    scale:
                        root.trayClusterExpanded
                        ? 1
                        : 0.96

                    transformOrigin: Item.Right

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 120
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 140
                            easing.type: Easing.OutCubic
                        }
                    }

                    Repeater {
                        model: SystemTray.items

                        Item {
                            id: trayItem

                            required property var modelData

                            width:
                                trayIcon.status === Image.Ready
                                ? 28
                                : 0

                            height: 30

                            visible:
                                trayIcon.status === Image.Ready

                            Image {
                                id: trayIcon

                                anchors.centerIn: parent
                                width: 19
                                height: 19
                                source: trayItem.modelData.icon
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }

                            QsMenuAnchor {
                                id: trayMenuAnchor
                                menu: trayItem.modelData.menu

                                anchor {
                                    item: trayItem
                                    edges: Edges.Bottom | Edges.Right
                                    gravity: Edges.Bottom | Edges.Left
                                    margins.top: 6
                                }
                            }

                            MouseArea {
                                anchors.fill: parent

                                acceptedButtons:
                                    Qt.LeftButton |
                                    Qt.RightButton |
                                    Qt.MiddleButton

                                cursorShape:
                                    Qt.PointingHandCursor

                                onClicked: mouse => {
                                    if (
                                        mouse.button === Qt.RightButton &&
                                        trayItem.modelData.hasMenu
                                    ) {
                                        trayMenuAnchor.open()
                                    } else if (
                                        mouse.button === Qt.MiddleButton
                                    ) {
                                        trayItem.modelData.secondaryActivate()
                                    } else {
                                        trayItem.modelData.activate()
                                    }
                                }
                            }
                        }
                    }

                    HoverHandler {
                        onHoveredChanged: {
                            if (hovered) {
                                trayClusterHideTimer.stop()
                                root.trayClusterExpanded = true
                            } else {
                                trayClusterHideTimer.restart()
                            }
                        }
                    }
                }

                // Single always-visible tray handle.
                Rectangle {
                    id: trayClusterHandle

                    width: 28
                    height: 30
                    radius: 10

                    color:
                        trayHandleHover.hovered ||
                        root.trayClusterExpanded
                        ? Theme.surface2
                        : "transparent"

                    Text {
                        anchors.centerIn: parent

                        text: "󰀻"
                        color:
                            root.trayClusterExpanded
                            ? Theme.accent
                            : Theme.subtext

                        font.family:
                            "JetBrainsMono Nerd Font"

                        font.pixelSize: 16
                    }

                    HoverHandler {
                        id: trayHandleHover

                        onHoveredChanged: {
                            if (hovered) {
                                trayClusterHideTimer.stop()
                                root.trayClusterExpanded = true
                            } else {
                                trayClusterHideTimer.restart()
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            root.trayClusterExpanded =
                                !root.trayClusterExpanded

                            if (root.trayClusterExpanded)
                                trayClusterHideTimer.stop()
                        }
                    }
                }

                Rectangle {
                    width: 1
                    height: 18
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.border
                    opacity: 0.85
                }

                // Revealed system controls.
                Row {
                    id: systemCluster
                    spacing: 5

                    visible: root.systemClusterExpanded

                    opacity:
                        root.systemClusterExpanded
                        ? 1
                        : 0

                    scale:
                        root.systemClusterExpanded
                        ? 1
                        : 0.96

                    transformOrigin: Item.Right

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 120
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 140
                            easing.type: Easing.OutCubic
                        }
                    }

                    BarButton {
                        visible: root.bluetoothAvailable
                        label: "󰂯"
                        onTriggered: root.openPage("bluetooth")
                    }

                    BarButton {
                        visible: root.networkKind !== "none"
                        label: root.networkIcon()
                        onTriggered: root.openPage("network")
                    }

                    BarButton {
                        label:
                            root.outputMuted
                            ? "󰝟"
                            : "󰕾"

                        onTriggered:
                            root.openPage("audio")
                    }

                    BarButton {
                        visible: root.batteryAvailable
                        label: root.batteryIcon()
                        onTriggered: root.openPage("battery")
                    }

                    BarButton {
                        label: "󰂚"
                        onTriggered:
                            root.execControl("notifications")
                    }

                    BarButton {
                        label: "󰍹"
                        onTriggered:
                            root.execControl("display")
                    }

                    BarButton {
                        label: "󰾅"
                        onTriggered:
                            root.execControl("power")
                    }

                    HoverHandler {
                        onHoveredChanged: {
                            if (hovered) {
                                systemClusterHideTimer.stop()
                                root.systemClusterExpanded = true
                            } else {
                                systemClusterHideTimer.restart()
                            }
                        }
                    }
                }

                // Handle: always visible, directly left of Power.
                Rectangle {
                    id: systemClusterHandle

                    width: 28
                    height: 30
                    radius: 10

                    color:
                        handleHover.hovered ||
                        root.systemClusterExpanded
                        ? Theme.surface2
                        : "transparent"

                    Text {
                        anchors.centerIn: parent

                        text:
                            root.systemClusterExpanded
                            ? "›"
                            : "‹"

                        color:
                            root.systemClusterExpanded
                            ? Theme.accent
                            : Theme.subtext

                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 17
                        font.bold: true
                    }

                    HoverHandler {
                        id: handleHover

                        onHoveredChanged: {
                            if (hovered) {
                                systemClusterHideTimer.stop()
                                root.systemClusterExpanded = true
                            } else {
                                systemClusterHideTimer.restart()
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            root.systemClusterExpanded =
                                !root.systemClusterExpanded

                            if (root.systemClusterExpanded)
                                systemClusterHideTimer.stop()
                        }
                    }
                }

                // Persistent main power button.
                BarButton {
                    label: "󰐥"
                    highlight: true
                    onTriggered:
                        root.execControl("session")
                }

                HoverHandler {
                    onHoveredChanged: {
                        if (hovered) {
                            systemClusterHideTimer.stop()
                        } else if (root.systemClusterExpanded) {
                            systemClusterHideTimer.restart()
                        }
                    }
                }
            }
        }
    }

    // ============================================================
    // DISK POPUP - click the disk telemetry on the bar
    // ============================================================
    PopupWindow {
        id: diskPopup

        visible: false
        implicitWidth: 430
        implicitHeight: 360
        color: "transparent"
        grabFocus: true

        anchor.window: bar
        anchor.rect.x: Math.max(8, Math.min(bar.width - width - 8, diskTelemetry.mapToItem(barSurface, 0, 0).x))
        anchor.rect.y: bar.height + 6

        PopupCard {
            id: diskCard
            anchors.fill: parent
            anchors.margins: 2

            transform: Translate {
                id: diskSlide
                y: 0
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: "󰋊  Disk Usage"
                        color: Theme.text
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Text {
                        text: "󰑐"
                        color: diskRefreshMouse.containsMouse ? Theme.accent : Theme.muted
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16

                        MouseArea {
                            id: diskRefreshMouse
                            anchors.fill: parent
                            anchors.margins: -8
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (!diskListProc.running) diskListProc.running = true
                        }
                    }

                    Text {
                        text: "󰅖"
                        color: Theme.muted
                        font.pixelSize: 17

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            cursorShape: Qt.PointingHandCursor
                            onClicked: diskPopup.visible = false
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.border
                }

                ListView {
                    id: diskList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: root.diskMounts

                    delegate: Rectangle {
                        required property var modelData

                        width: diskList.width
                        height: 58
                        radius: 12
                        color: diskRowMouse.containsMouse ? Theme.surface2 : Theme.surface

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                text: modelData.mount === "/" ? "󰋊" : "󰋌"
                                color: Theme.accent
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 17
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.mount
                                        color: Theme.text
                                        elide: Text.ElideMiddle
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    Text {
                                        text: modelData.used + "GB/" + modelData.total + "GB  " + modelData.percent + "%"
                                        color: Theme.subtext
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 6
                                    radius: 3
                                    color: Theme.surface2

                                    Rectangle {
                                        width: parent.width * modelData.percent / 100
                                        height: parent.height
                                        radius: parent.radius
                                        color: Theme.accent
                                    }
                                }
                            }

                            Text {
                                text: "󰁔"
                                color: Theme.muted
                                font.pixelSize: 14
                            }
                        }

                        MouseArea {
                            id: diskRowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.execControl("open-path", modelData.mount)
                                diskPopup.visible = false
                            }
                        }
                    }
                }

                Text {
                    visible: root.diskMounts.length === 0
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    text: "No local filesystems found"
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.muted
                    font.pixelSize: 11
                }
            }
        }

        onVisibleChanged: {
            if (visible) {
                if (!diskListProc.running)
                    diskListProc.running = true
                diskSlide.y = -20
                diskCard.opacity = 0
                diskOpenAnim.restart()
            }
        }

        ParallelAnimation {
            id: diskOpenAnim

            NumberAnimation {
                target: diskSlide
                property: "y"
                from: -20
                to: 0
                duration: 190
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: diskCard
                property: "opacity"
                from: 0
                to: 1
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
    }

    // ============================================================
    // CPU POPUP - safe text-only per-thread view
    // ============================================================
    PopupWindow {
        id: cpuPopup

        visible: false
        implicitWidth: 390
        implicitHeight: Math.min(520, 120 + root.cpuThreads * 22)
        color: "transparent"
        grabFocus: true

        anchor.window: bar
        anchor.rect.x: Math.max(8, Math.min(bar.width - width - 8, cpuTelemetry.mapToItem(barSurface, 0, 0).x - width / 2 + cpuTelemetry.width / 2))
        anchor.rect.y: bar.height + 6

        PopupCard {
            id: cpuCard
            anchors.fill: parent
            anchors.margins: 2

            transform: Translate {
                id: cpuSlide
                y: 0
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: "󰘚  CPU • " + root.cpuCores + " cores / " + root.cpuThreads + " threads"
                        color: Theme.text
                        font.pixelSize: 16
                        font.bold: true
                    }

                    Text {
                        text: root.cpuUsage + "%"
                        color: Theme.accent
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
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
                            onClicked: cpuPopup.visible = false
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.border
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Text {
                        width: parent.width
                        text: root.cpuDetailText
                        color: Theme.text
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        lineHeight: 1.35
                    }
                }
            }
        }

        onVisibleChanged: {
            if (visible) {
                if (!cpuDetailProc.running)
                    cpuDetailProc.running = true
                cpuSlide.y = -20
                cpuCard.opacity = 0
                cpuOpenAnim.restart()
            }
        }

        ParallelAnimation {
            id: cpuOpenAnim

            NumberAnimation {
                target: cpuSlide
                property: "y"
                from: -20
                to: 0
                duration: 190
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: cpuCard
                property: "opacity"
                from: 0
                to: 1
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Timer {
            interval: 1500
            repeat: true
            running: cpuPopup.visible
            onTriggered: if (!cpuDetailProc.running) cpuDetailProc.running = true
        }
    }

    // ============================================================
    // CENTERED CALENDAR POPUP
    // PopupWindow dismisses itself when clicking outside.
    // ============================================================
    PopupWindow {
        id: calendarPopup

        visible: false
        implicitWidth: 434
        implicitHeight: 509
        color: "transparent"
        grabFocus: true

        anchor.window: bar
        anchor.rect.x: Math.max(0, (bar.width - width) / 2)
        anchor.rect.y: bar.height + 6

        PopupCard {
            id: calendarCard

            anchors.fill: parent
            anchors.margins: 2

            transform: Translate {
                id: calendarSlide
                y: 0
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: "󰃭  Calendar"
                        color: Theme.text
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
                            onClicked: calendarPopup.visible = false
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.border
                }

                RowLayout {
                    Layout.fillWidth: true

                    MiniButton {
                        label: "󰅁"
                        implicitWidth: 46
                        onTriggered:
                            root.calendarMonthOffset--
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: root.monthTitle()
                        color: Theme.text
                        font.pixelSize: 18
                        font.bold: true
                    }

                    MiniButton {
                        label: "󰅂"
                        implicitWidth: 46
                        onTriggered:
                            root.calendarMonthOffset++
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    rowSpacing: 4
                    columnSpacing: 4

                    Repeater {
                        model: [
                            "Mon",
                            "Tue",
                            "Wed",
                            "Thu",
                            "Fri",
                            "Sat",
                            "Sun"
                        ]

                        Text {
                            required property var modelData

                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter

                            text: modelData
                            color: Theme.accent2
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 7
                    rowSpacing: 5
                    columnSpacing: 5

                    Repeater {
                        model: 42

                        Rectangle {
                            required property int index

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 10

                            property int dayNumber:
                                root.cellDay(index)

                            color:
                                root.isToday(dayNumber)
                                ? Theme.accent
                                : dayNumber > 0
                                  ? Theme.surface
                                  : "transparent"

                            Text {
                                anchors.centerIn: parent

                                text:
                                    parent.dayNumber > 0
                                    ? parent.dayNumber
                                    : ""

                                color:
                                    root.isToday(parent.dayNumber)
                                    ? "#11111b"
                                    : Theme.text

                                font.pixelSize: 12
                                font.bold:
                                    root.isToday(parent.dayNumber)
                            }
                        }
                    }
                }

                MiniButton {
                    Layout.alignment: Qt.AlignHCenter
                    label: "Today"
                    implicitWidth: 90
                    onTriggered:
                        root.calendarMonthOffset = 0
                }
            }

        }

        onVisibleChanged: {
            if (visible) {
                calendarSlide.y = -18
                calendarCard.opacity = 0
                calendarAnim.restart()
            }
        }

        ParallelAnimation {
            id: calendarAnim

            NumberAnimation {
                target: calendarSlide
                property: "y"
                from: -18
                to: 0
                duration: 185
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: calendarCard
                property: "opacity"
                from: 0
                to: 1
                duration: 145
                easing.type: Easing.OutCubic
            }
        }
    }

    // ============================================================
    // RIGHT-SIDE SYSTEM POPUP
    // ============================================================
    PopupWindow {
        id: systemPopup

        visible: false
        implicitWidth: 414
        implicitHeight: 474
        color: "transparent"
        grabFocus: true

        anchor.window: bar
        anchor.rect.x: Math.max(0, bar.width - width - 12)
        anchor.rect.y: bar.height + 6

        PopupCard {
            id: systemCard

            anchors.fill: parent
            anchors.margins: 2

            transform: Translate {
                id: systemSlide
                y: 0
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

                            if (root.page === "battery")
                                return "󰁹  Battery"

                            return "System"
                        }

                        color: Theme.text
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
                            onClicked: systemPopup.visible = false
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.border
                }

                // Network: status + direct Settings button.
                ColumnLayout {
                    visible: root.page === "network"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    InfoCard {
                        iconText: root.networkIcon()

                        titleText:
                            root.networkLabel !== ""
                            ? root.networkLabel
                            : "Network"

                        subText:
                            root.networkKind.indexOf("wifi") === 0
                            ? "Wi-Fi"
                            : "Ethernet"
                    }

                    ActionButton {
                        label: "󰒓  Network Settings"
                        onTriggered:
                            root.execControl("network")
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                // Bluetooth: one action directly in popup.
                ColumnLayout {
                    visible: root.page === "bluetooth"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    InfoCard {
                        iconText: "󰂯"
                        titleText: "Bluetooth"
                        subText: "Controller available"
                    }

                    ActionButton {
                        label: "󰂯  Bluetooth Devices"
                        onTriggered:
                            root.execControl("bluetooth")
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                // Audio remains fully interactive; no extra utility required.
                ColumnLayout {
                    visible: root.page === "audio"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            text: "󰕾  Speakers"
                            color: Theme.text
                            font.bold: true
                        }

                        Text {
                            text:
                                root.outputMuted
                                ? "Muted"
                                : root.outputVolume + "%"

                            color:
                                root.outputMuted
                                ? Theme.danger
                                : Theme.subtext
                        }
                    }

                    Slider {
                        Layout.fillWidth: true
                        from: 0
                        to: 150
                        value: root.outputVolume
                        enabled: !root.outputMuted

                        onMoved: {
                            root.outputVolume =
                                Math.round(value)

                            root.execControl(
                                "output-set",
                                root.outputVolume
                            )
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        MiniButton {
                            Layout.fillWidth: true

                            label:
                                root.outputMuted
                                ? "󰖁 Unmute"
                                : "󰝟 Mute"

                            onTriggered: {
                                root.execControl("output-mute")
                                refreshDelay.restart()
                            }
                        }

                        MiniButton {
                            Layout.fillWidth: true
                            label: "󰓃 Mixer"
                            onTriggered:
                                root.execControl("audio")
                        }
                    }

                    Rectangle {
                        visible: root.microphoneAvailable
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.border
                    }

                    RowLayout {
                        visible: root.microphoneAvailable
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            text: "󰍬  Microphone"
                            color: Theme.text
                            font.bold: true
                        }

                        Text {
                            text:
                                root.microphoneMuted
                                ? "Muted"
                                : root.microphoneVolume + "%"

                            color:
                                root.microphoneMuted
                                ? Theme.danger
                                : Theme.subtext
                        }
                    }

                    Slider {
                        visible: root.microphoneAvailable
                        Layout.fillWidth: true
                        from: 0
                        to: 150
                        value: root.microphoneVolume
                        enabled: !root.microphoneMuted

                        onMoved: {
                            root.microphoneVolume =
                                Math.round(value)

                            root.execControl(
                                "input-set",
                                root.microphoneVolume
                            )
                        }
                    }

                    MiniButton {
                        visible: root.microphoneAvailable
                        Layout.fillWidth: true

                        label:
                            root.microphoneMuted
                            ? "󰍬 Unmute microphone"
                            : "󰍭 Mute microphone"

                        onTriggered: {
                            root.execControl("input-mute")
                            refreshDelay.restart()
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                // Battery status + direct Power Profiles button.
                ColumnLayout {
                    visible: root.page === "battery"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    InfoCard {
                        iconText: root.batteryIcon()

                        titleText: {
                            var parts =
                                root.batteryData.split("|")

                            return "Battery " +
                                   (parts[0] || "0") +
                                   "%"
                        }

                        subText: {
                            var parts =
                                root.batteryData.split("|")

                            return parts[1] || "unknown"
                        }
                    }

                    ActionButton {
                        label: "󰾅  Power Profiles"
                        onTriggered:
                            root.execControl("power")
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }

        }

        onVisibleChanged: {
            if (visible) {
                systemSlide.y = -18
                systemCard.opacity = 0
                systemAnim.restart()
            }
        }

        ParallelAnimation {
            id: systemAnim

            NumberAnimation {
                target: systemSlide
                property: "y"
                from: -18
                to: 0
                duration: 185
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: systemCard
                property: "opacity"
                from: 0
                to: 1
                duration: 145
                easing.type: Easing.OutCubic
            }
        }
    }

    Timer {
        id: refreshDelay
        interval: 400
        repeat: false
        onTriggered: root.refresh()
    }

    // ============================================================
    // COMPONENTS
    // ============================================================
    component PopupCard: Rectangle {
        // Keep the outer corners opaque and genuinely rounded. QQuickItem clipping
        // is rectangular, so a full-size wallpaper image can otherwise leak into
        // the four corner pixels of a rounded popup.
        radius: 22
        color: Theme.bg
        border.width: 1
        border.color: Theme.border

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: 19
            color: Theme.bg
            clip: true

            Image {
                // Inset the wallpaper from the outer border; even rectangular
                // clipping can no longer touch the popup's four outer corners.
                anchors.fill: parent
                anchors.margins: 2
                source: root.wallpaperUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                opacity: 0.34
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Theme.bg
                opacity: 0.82
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

        color:
            buttonMouse.containsMouse
            ? Theme.surface2
            : "transparent"

        Text {
            anchors.centerIn: parent
            text: button.label
            color:
                button.highlight
                ? Theme.accent
                : Theme.text

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

    component InfoCard: Rectangle {
        id: info

        property string iconText: ""
        property string titleText: ""
        property string subText: ""

        Layout.fillWidth: true
        implicitHeight: 78
        radius: 15
        color: Theme.surface

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 13

            Text {
                text: info.iconText
                color: Theme.accent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 24
            }

            ColumnLayout {
                Layout.fillWidth: true

                Text {
                    text: info.titleText
                    color: Theme.text
                    font.pixelSize: 14
                    font.bold: true
                }

                Text {
                    text: info.subText
                    color: Theme.muted
                    font.pixelSize: 11
                }
            }
        }
    }

    component ActionButton: Rectangle {
        id: action

        property string label: ""
        signal triggered()

        Layout.fillWidth: true
        implicitHeight: 44
        radius: 12

        color:
            actionMouse.containsMouse
            ? Theme.surface2
            : Theme.surface

        Text {
            anchors.centerIn: parent
            text: action.label
            color: Theme.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.bold: true
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.triggered()
        }
    }

    component MiniButton: Rectangle {
        id: mini

        property string label: ""
        signal triggered()

        implicitHeight: 40
        implicitWidth: 100
        radius: 11

        color:
            miniMouse.containsMouse
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

# ================================================================
# Initial theme/toolkit synchronization
# ================================================================
"$BIN/ui-theme-sync"

# ================================================================
# Validation
# ================================================================
log "Validating generated shell scripts..."
for f in \
  "$BIN/rofi-safe" \
  "$BIN/rofi-wallpaper-mode" \
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
  - app launcher loads .desktop application icons
  - wallpaper picker uses a true horizontal 4 x 3 thumbnail grid
  - power menu has centered/aligned text
  - no linear-gradient / no background-image
  - all default widgets explicitly dark/transparent
  - palette synchronized by ui-theme-sync

Optional environment:
  NVIDIA env: $ENABLE_NVIDIA_ENV
  Fcitx5 env: $ENABLE_FCITX5

Desktop theming:
  GTK: Sweet (upstream)
  Icons: Sweet-Rainbow + candy-icons fallback
  Cursor: Sweet-cursors / XCursor ($CURSOR_SIZE px)
  Qt5/Qt6: qt5ct/qt6ct -> Kvantum
  KDE/Dolphin icons: Sweet-Rainbow via kdeglobals
  Kvantum: Sweet
  SUPER + T keeps Sweet app styling while syncing shell palette/icons/cursor

Quickshell:
  - one synchronized clock/date string at true bar center
  - calendar popup centered directly below clock/date
  - month calendar popup (7 x 6)
  - disk/RAM/swap/CPU/GPU telemetry beside workspaces
  - clickable multi-mount disk popup; click a mount to open it in Dolphin
  - simple right-side layout: tray | system ‹ power
  - application tray collapsed into one hover-reveal tray button
  - broken tray icons auto-hide instead of showing checkerboard
  - hover-reveal system icon cluster behind a ‹ handle
  - cluster auto-collapses after pointer leaves
  - main Power button always visible
  - Display / Power / Session remain one-click direct actions
  - battery icon only when a battery exists
  - Wi-Fi/Ethernet icon selected from actual network hardware/state
  - Bluetooth icon only when a controller exists
  - microphone controls only when a real input source exists
  - rounded PopupWindow cards with 2px transparent inset
  - slide-down + fade animation
  - click outside dismisses calendar/system popups
  - wallpaper popup background loaded from:
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
