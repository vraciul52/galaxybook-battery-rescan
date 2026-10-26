#!/bin/bash
# Install the boot-time battery re-scan. Run with: sudo ./install.sh
set -euo pipefail
cd "$(dirname "$0")"

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: sudo ./install.sh"
  exit 1
fi

if ! modinfo acpi_configfs >/dev/null 2>&1 && [[ ! -d /sys/kernel/config/acpi ]]; then
  echo "Your kernel has no acpi_configfs support (CONFIG_ACPI_CONFIGFS), so this can't work."
  exit 1
fi

lockdown=$(cat /sys/kernel/security/lockdown 2>/dev/null || echo "[none]")
if [[ $lockdown != *"[none]"* ]]; then
  echo "Warning: kernel lockdown is active ($lockdown), usually because Secure Boot is on."
  echo "Lockdown blocks loading ACPI tables, so the re-scan will probably fail."
fi

install -Dm755 galaxybook-battery-rescan /usr/local/bin/galaxybook-battery-rescan
install -Dm644 galaxybook-battery-rescan.service /etc/systemd/system/galaxybook-battery-rescan.service
systemctl daemon-reload
systemctl enable galaxybook-battery-rescan.service

echo "Installed. It runs at every boot and only acts when the battery is missing."
echo "Run it now with: sudo systemctl start galaxybook-battery-rescan"
