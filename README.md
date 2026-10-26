# galaxybook-battery-rescan

A workaround for Samsung Galaxy Book4 laptops where **Linux shows no battery if you boot without the charger plugged in**.

Without this fix, if the laptop starts unplugged:
- there's no battery icon or percentage, and no low-battery warning;
- `/sys/class/power_supply/` has no `BAT1` and no `ADP1`, only the USB-C (`ucsi-source-psy-*`) entries;
- the kernel log is missing `ACPI: battery: Slot [BAT1] (battery present)`.

Booting with the charger plugged in works fine. Updating the BIOS doesn't help: the bug is still present on P10ALX.

Tested on a **Galaxy Book4 Ultra 960XGL** (BIOS P09ALX), Arch Linux (Omarchy), kernel 7.2. Reported upstream at [pop-os/pop#3980](https://github.com/pop-os/pop/issues/3980).

## Why it happens

At power-on without the charger, the firmware's `_STA` method for `\_SB.PC00.LPCB.H_EC.BAT1` (and `\_SB.ADP1`) reports "not present". The values come from the embedded controller (EC), which isn't ready yet. Linux scans its ACPI devices once at boot, skips them, and never looks again.

A few seconds later, both devices report present (`/sys/bus/acpi/devices/PNP0C0A:00/status` = `31`), but the firmware never sends the `Notify` that would make Linux re-check them.

## How the fix works

Linux re-scans all ACPI devices whenever an ACPI table is loaded (`acpi_scan_table_notify()` → `acpi_bus_scan()` in `drivers/acpi/scan.c`). This time the battery and charger report present, so they get set up normally.

This tool loads a **43-byte SSDT that does nothing**. Its only content is one unused integer, `\BRSC = 1`. It's loaded at boot through `acpi_configfs`, and only if the battery is missing. No firmware or kernel is modified, and a reboot undoes it completely.

`make-ssdt.py` regenerates the table, so you can check that the bytes embedded in the script are what they claim to be.

## Install

```bash
git clone https://github.com/vraciul52/galaxybook-battery-rescan
cd galaxybook-battery-rescan
sudo ./install.sh
```

This installs `/usr/local/bin/galaxybook-battery-rescan` and a systemd service that runs it at every boot. To fix the current boot right away:

```bash
sudo systemctl start galaxybook-battery-rescan
```

### Requirements

- A kernel with `CONFIG_ACPI_CONFIGFS` (Arch, Fedora and Ubuntu kernels ship it as a module).
- **Kernel lockdown off.** Secure Boot usually turns lockdown on, and lockdown blocks loading ACPI tables. Check with `cat /sys/kernel/security/lockdown`: you want `[none]`.

## Try it once without installing

```bash
sudo modprobe acpi_configfs
sudo mkdir /sys/kernel/config/acpi/table/test
python3 make-ssdt.py rescan.aml
sudo cp rescan.aml /sys/kernel/config/acpi/table/test/aml
ls /sys/class/power_supply/    # BAT1 and ADP1 should now be listed
```

## Uninstall

```bash
sudo ./uninstall.sh
```

## Status

This is a stopgap. The proper fix is a kernel quirk that re-checks these devices once the EC is ready. If you have the same problem on a different Galaxy Book model, please open an issue with your model, BIOS version (`cat /sys/class/dmi/id/bios_version`) and whether this fix worked.

## License

MIT
