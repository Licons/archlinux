#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

"$DIR/1-base.sh"
"$DIR/2-desktop.sh"
"$DIR/3-work-apps.sh"

echo
echo "All phases completed."
echo "Reboot when ready: sudo reboot"
