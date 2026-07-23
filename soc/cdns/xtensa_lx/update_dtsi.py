#!/usr/bin/env python3
"""
update_dtsi.py – Update xtensa_lx.dtsi SRAM base and size from toolchain config.

The script locates the Xtensa toolchain linker script (elf32xtensa.x) using
`xt-clang --show-config`, parses the MEMORY section to determine the full SRAM
address range, then rewrites the sram0 `reg` property in xtensa_lx.dtsi.

SRAM range calculation
----------------------
The linker script MEMORY section contains a series of sramN_seg entries followed
by a final "RAM" entry (which ldscriptconv.py creates from the last sramN_seg).
The contiguous SRAM block spans:

  base  = org of sram0_seg
  end   = org(RAM) + len(RAM)
  size  = end - base

Usage
-----
  # Automatic (uses xt-clang in PATH):
  python3 update_dtsi.py

  # Manual (explicit paths):
  python3 update_dtsi.py \\
      --ldscript /path/to/elf32xtensa.x \\
      --dtsi     /path/to/xtensa_lx.dtsi

Copyright (c) 2024 Cadence Design Systems, Inc.
SPDX-License-Identifier: Apache-2.0
"""

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _core_build_dir() -> Path:
    """
    Return the core build root directory.

    Strategy (first match wins):
    1. $XTENSA_SYSTEM env var — already set by the build environment;
       its parent is the core build root  (…/<core>/config -> …/<core>/).
    2. `xt-clang --show-config=config` — same directory as XTENSA_SYSTEM.
    """
    xtensa_system = os.environ.get("XTENSA_SYSTEM", "")
    if xtensa_system:
        core_root = Path(xtensa_system).parent
        if core_root.is_dir():
            return core_root

    # Fallback: ask xt-clang
    try:
        result = subprocess.run(
            ["xt-clang", "--show-config=config"],
            capture_output=True, text=True, check=True
        )
        config_dir = result.stdout.strip()
        core_root = Path(config_dir).parent
        if core_root.is_dir():
            return core_root
        sys.exit(f"ERROR: Core build root not found: {core_root}")
    except FileNotFoundError:
        sys.exit("ERROR: XTENSA_SYSTEM is not set and xt-clang is not in PATH.")
    except subprocess.CalledProcessError as exc:
        sys.exit(f"ERROR: xt-clang --show-config=config failed: {exc.stderr.strip()}")


def _default_ldscript() -> Path:
    """Return the core-specific elf32xtensa.x path."""
    path = _core_build_dir() / "xtensa-elf" / "lib" / "sim" / "ldscripts" / "elf32xtensa.x"
    if not path.exists():
        sys.exit(f"ERROR: Linker script not found: {path}")
    return path


def _default_dtsi() -> Path:
    """Return the dtsi path relative to this script's location."""
    here = Path(__file__).resolve().parent
    # script lives in soc/cdns/xtensa_lx/; dtsi is in dts/xtensa/
    # parents[0]=cdns  parents[1]=soc  parents[2]=zephyr
    dtsi = here.parents[2] / "dts" / "xtensa" / "xtensa_lx.dtsi"
    if not dtsi.exists():
        sys.exit(f"ERROR: dtsi not found at expected path: {dtsi}")
    return dtsi


# ---------------------------------------------------------------------------
# Parser
# ---------------------------------------------------------------------------

def parse_memory_section(ldscript_path: Path):
    """
    Parse the MEMORY { ... } block and return a list of dicts:
      [{'name': str, 'org': int, 'len': int}, ...]
    """
    text = ldscript_path.read_text(errors="replace")

    # Extract the MEMORY { ... } block (first occurrence, no nesting)
    mem_match = re.search(r'\bMEMORY\s*\{([^}]*)\}', text, re.DOTALL)
    if not mem_match:
        sys.exit(f"ERROR: No MEMORY section found in {ldscript_path}")

    block = mem_match.group(1)

    # Each entry looks like:
    #   name_seg (flags) : org = 0xADDR, len = 0xSIZE
    # or after ldscriptconv conversion:
    #   RAM : org = 0xADDR, len = 0xSIZE
    entry_re = re.compile(
        r'(\w+)\s*(?:\([^)]*\))?\s*:\s*'
        r'org\s*=\s*(0x[0-9A-Fa-f]+|\d+)\s*,\s*'
        r'len\s*=\s*(0x[0-9A-Fa-f]+|\d+)',
        re.IGNORECASE
    )

    segments = []
    for m in entry_re.finditer(block):
        name = m.group(1)
        # Skip preprocessor-guarded entries (IDT_LIST etc.)
        if name.startswith('#') or name.upper() == 'IDT_LIST':
            continue
        segments.append({
            'name': name,
            'org':  int(m.group(2), 0),
            'len':  int(m.group(3), 0),
        })

    if not segments:
        sys.exit(f"ERROR: No memory segments parsed from {ldscript_path}")

    return segments


def compute_sram_range(segments):
    """
    Determine the contiguous SRAM base address and total size.

    Strategy:
    - Collect all sramN_seg entries (and the final 'RAM' entry that
      ldscriptconv.py renames from the last sram segment).
    - The base is the org of the first sramN_seg (lowest address).
    - The end  is max(org + len) across all sram* and RAM entries.
    """
    sram_entries = [
        s for s in segments
        if re.match(r'^sram\d+_seg$', s['name'], re.IGNORECASE)
        or s['name'].upper() == 'RAM'
    ]

    if not sram_entries:
        # Fallback: use the original linker script where the last sram segment
        # has not been renamed to RAM yet.
        sram_entries = [
            s for s in segments
            if re.match(r'^sram', s['name'], re.IGNORECASE)
        ]

    if not sram_entries:
        sys.exit("ERROR: No sram* segments found in MEMORY section.")

    base = min(s['org'] for s in sram_entries)
    end  = max(s['org'] + s['len'] for s in sram_entries)
    size = end - base

    return base, size


# ---------------------------------------------------------------------------
# DTSI updater
# ---------------------------------------------------------------------------

def update_dtsi(dtsi_path: Path, base: int, size: int, dry_run: bool = False):
    """
    Rewrite the sram0 node in the dtsi:
      - node label:  memory@<hex_base>
      - reg property: <0xBASE 0xSIZE>
    """
    text = dtsi_path.read_text()

    hex_base = f"0x{base:08X}"
    hex_size = f"0x{size:X}"

    # Pattern matches:
    #   sram0: memory@<anything> {
    #       ...
    #       reg = <0x... 0x...>;
    #       ...
    #   };
    # We update the node address in the label and the reg value.

    # 1. Update the node address in the label line
    text_new = re.sub(
        r'(sram0\s*:\s*memory@)[0-9A-Fa-f]+',
        rf'\g<1>{base:08x}',
        text
    )

    # 2. Update the reg property inside the sram0 node
    #    Find sram0 node block and replace its reg value.
    def replace_reg(m):
        node_content = m.group(0)
        node_content = re.sub(
            r'(reg\s*=\s*<\s*)0x[0-9A-Fa-f]+(\s+)0x[0-9A-Fa-f]+(\s*>)',
            rf'\g<1>{hex_base}\g<2>{hex_size}\g<3>',
            node_content
        )
        return node_content

    # Match the sram0 node block (from 'sram0:' through the closing '};')
    text_new = re.sub(
        r'sram0\s*:.*?};',
        replace_reg,
        text_new,
        flags=re.DOTALL
    )

    if text_new == text:
        print("INFO: dtsi already up-to-date, no changes written.")
        return

    if dry_run:
        print(f"[dry-run] Would update {dtsi_path}:")
        print(f"  sram0: memory@{base:08x} {{ reg = <{hex_base} {hex_size}>; }}")
        return

    dtsi_path.write_text(text_new)
    print(f"Updated {dtsi_path}")
    print(f"  sram0 base = {hex_base}  size = {hex_size} ({size // 1024} KiB)")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Update xtensa_lx.dtsi SRAM base and size from toolchain config.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--ldscript", metavar="FILE",
        help="Path to elf32xtensa.x (default: auto-detected via xt-clang --show-config)"
    )
    parser.add_argument(
        "--dtsi", metavar="FILE",
        help="Path to xtensa_lx.dtsi (default: auto-detected relative to this script)"
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Print what would change without writing the file"
    )
    parser.add_argument(
        "--show-only", action="store_true",
        help="Only print the parsed SRAM base and size, do not modify dtsi"
    )
    args = parser.parse_args()

    ldscript_path = Path(args.ldscript) if args.ldscript else _default_ldscript()
    dtsi_path     = Path(args.dtsi)     if args.dtsi     else _default_dtsi()

    print(f"Linker script : {ldscript_path}")
    print(f"Target dtsi   : {dtsi_path}")

    segments = parse_memory_section(ldscript_path)

    print("\nParsed MEMORY segments:")
    for seg in segments:
        print(f"  {seg['name']:20s} org=0x{seg['org']:08X}  len=0x{seg['len']:X}")

    base, size = compute_sram_range(segments)
    print(f"\nSRAM range: base=0x{base:08X}  size=0x{size:X} ({size // 1024} KiB)")

    if args.show_only:
        return

    update_dtsi(dtsi_path, base, size, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
