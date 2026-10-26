"""Build a minimal, do-nothing SSDT.

Its only content is one unused integer, \\BRSC = 1. Loading any table makes
Linux re-scan the ACPI namespace, which is the point.

Usage: python3 -I make_ssdt.py <out.aml>
"""
import struct
import sys

aml = bytes([0x08]) + b"\\BRSC" + bytes([0x01])  # Name (\BRSC, One)

header = struct.pack(
    "<4sIBB6s8sI4sI",
    b"SSDT",
    36 + len(aml),   # length
    2,               # revision
    0,               # checksum (filled below)
    b"RESCAN",       # OEM ID
    b"BATRSCAN",     # OEM table ID
    1,               # OEM revision
    b"INTL",         # creator ID
    0x20251212,      # creator revision
)
table = bytearray(header + aml)
table[9] = (-sum(table)) & 0xFF
assert sum(table) & 0xFF == 0
open(sys.argv[1], "wb").write(table)
print(f"wrote {len(table)} bytes")
