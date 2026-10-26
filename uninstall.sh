#!/bin/bash
# Remove the boot-time battery re-scan. Run with: sudo ./uninstall.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: sudo ./uninstall.sh"
  exit 1
fi

systemctl disable --now galaxybook-battery-rescan.service 2>/dev/null || true
rm -f /etc/systemd/system/galaxybook-battery-rescan.service /usr/local/bin/galaxybook-battery-rescan
systemctl daemon-reload
echo "Removed. (A table loaded during this boot stays until you reboot; it's harmless.)"
