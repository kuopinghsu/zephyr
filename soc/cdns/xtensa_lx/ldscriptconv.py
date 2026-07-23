#!/usr/bin/env python3
"""
Linker Script Converter for Zephyr
Converts Xtensa linker scripts (elf32xtensa.x) to Zephyr-compatible format.

Copyright (c) 2024 Cadence Design Systems, Inc.
SPDX-License-Identifier: Apache-2.0
"""

import argparse
import os
import re
import sys
from pathlib import Path


class LinkerScriptConverter:
    """Converts Xtensa linker scripts to Zephyr format."""
    
    def __init__(self):
        self.rules_applied = {
            'header_added': False,
            'includes_added': False,
            'ramable_region_defined': False,
            'memory_renamed': False,
            'isr_tables_added': False,
            'entry_point_changed': False,
            'sections_includes_added': False,
            'zephyr_sections_added': False,
            'extra_blank_lines_removed': False,
        }
        self.errors = []
        
    def convert(self, input_file, output_file):
        """Convert linker script from input to output format."""
        
        # Read input file
        try:
            with open(input_file, 'r') as f:
                content = f.read()
        except FileNotFoundError:
            raise FileNotFoundError(f"Input file not found: {input_file}")
        except Exception as e:
            raise IOError(f"Error reading input file: {e}")
        
        # Apply conversion rules in correct order
        # Step 1: Remove original header
        converted = self._remove_original_header(content)
        
        # Step 2: Add new header with includes
        converted = self._add_header_and_includes(converted)
        
        # Step 3: Add RAMABLE_REGION before MEMORY
        converted = self._add_ramable_region(converted)
        
        # Step 4: Convert MEMORY section
        converted = self._convert_memory_section(converted)
        
        # Step 5: Change entry point
        converted = self._change_entry_point(converted)
        
        # Step 6: Add sections includes
        converted = self._add_sections_includes(converted)
        
        # Step 7: Add Zephyr-specific sections and includes
        converted = self._add_zephyr_sections(converted)
        
        # Step 8: Clean up extra blank lines
        converted = self._remove_extra_blank_lines(converted)
        
        # Verify all rules were applied
        self._verify_rules()
        
        # Write output file
        try:
            output_path = Path(output_file)
            output_path.parent.mkdir(parents=True, exist_ok=True)
            with open(output_file, 'w') as f:
                f.write(converted)
        except Exception as e:
            raise IOError(f"Error writing output file: {e}")
        
        return True
    
    def _remove_original_header(self, content):
        """Remove original comments at the top."""
        content = re.sub(r'^/\*.*?Linker Script for default link.*?\*/', '', content, flags=re.DOTALL)
        content = content.lstrip()
        return content
    
    def _find_last_sram_segment(self, content):
        """Find the last (highest numbered) SRAM segment in the MEMORY section."""
        # Find all sramN_seg entries
        sram_matches = re.findall(r'(sram(\d+)_seg)\s*:', content)
        if not sram_matches:
            return None
        
        # Find the one with the highest number
        max_num = -1
        last_sram = None
        for full_name, num_str in sram_matches:
            num = int(num_str)
            if num > max_num:
                max_num = num
                last_sram = full_name
        
        return last_sram
    
    def _add_header_and_includes(self, content):
        """Add Zephyr copyright header, documentation, and includes."""
        
        header = """/*
 * Copyright (c) 2024 Cadence Design Systems, Inc.
 * SPDX-License-Identifier: Apache-2.0
 */

/**
 * @file
 * @brief Linker command/script file
 *
 * Linker script for the Xtensa platform.
 */

#include <zephyr/linker/sections.h>

#include <zephyr/devicetree.h>
#include <zephyr/linker/linker-defs.h>
#include <zephyr/linker/linker-tool.h>

"""
        self.rules_applied['header_added'] = True
        self.rules_applied['includes_added'] = True
        return header + content
    
    def _add_ramable_region(self, content):
        """Add RAMABLE_REGION and ROMABLE_REGION definitions."""
        
        # Find MEMORY section and add definitions before it
        memory_match = re.search(r'^MEMORY\s*{', content, re.MULTILINE)
        if not memory_match:
            self.errors.append("MEMORY section not found")
            return content
        
        # Find the last SRAM segment to use in RAMABLE_REGION
        last_sram = self._find_last_sram_segment(content)
        if not last_sram:
            self.errors.append("Could not find any SRAM segment")
            return content
        
        # Extract the number from sramN_seg to create sramN_phdr
        sram_num = re.search(r'sram(\d+)_seg', last_sram)
        if sram_num:
            phdr_name = f"sram{sram_num.group(1)}_phdr"
        else:
            self.errors.append(f"Could not extract number from {last_sram}")
            return content
        
        definitions = f"""#define RAMABLE_REGION RAM :{phdr_name}
#define ROMABLE_REGION RAMABLE_REGION

"""
        pos = memory_match.start()
        self.rules_applied['ramable_region_defined'] = True
        return content[:pos] + definitions + content[pos:]
    
    def _convert_memory_section(self, content):
        """Convert MEMORY section: rename last SRAM segment to RAM and add ISR tables."""
        
        # Find the last SRAM segment dynamically
        last_sram = self._find_last_sram_segment(content)
        if not last_sram:
            self.errors.append("Could not find any SRAM segment to rename")
            return content
        
        # Rename the last SRAM segment to RAM
        pattern = rf'{last_sram}\s*:'
        content = re.sub(pattern, 'RAM :', content)
        
        if 'RAM :' in content:
            self.rules_applied['memory_renamed'] = True
        else:
            self.errors.append(f"Failed to rename {last_sram} to RAM")
        
        # Add ISR tables configuration before closing brace of MEMORY section
        memory_end = re.search(r'^}', content, re.MULTILINE)
        if memory_end:
            isr_config = """#ifdef CONFIG_GEN_ISR_TABLES
  IDT_LIST : org = 0x00000000, len = 0x2000
#endif
"""
            # Insert before the closing brace
            pos = memory_end.start()
            content = content[:pos] + isr_config + content[pos:]
            self.rules_applied['isr_tables_added'] = True
        else:
            self.errors.append("Could not find end of MEMORY section")
        
        return content
    
    def _change_entry_point(self, content):
        """Change ENTRY point from _ResetVector to CONFIG_KERNEL_ENTRY."""
        
        content = re.sub(
            r'ENTRY\(_ResetVector\)',
            'ENTRY(CONFIG_KERNEL_ENTRY)',
            content
        )
        
        if 'ENTRY(CONFIG_KERNEL_ENTRY)' in content:
            self.rules_applied['entry_point_changed'] = True
        else:
            self.errors.append("Failed to change entry point")
        
        return content
    
    def _add_sections_includes(self, content):
        """Add Zephyr section includes at the beginning of SECTIONS block."""
        
        # Find SECTIONS block
        sections_match = re.search(r'^SECTIONS\s*{', content, re.MULTILINE)
        if not sections_match:
            self.errors.append("SECTIONS block not found")
            return content
        
        includes = """
#include <zephyr/linker/rel-sections.ld>

#ifdef CONFIG_LLEXT
#include <zephyr/linker/llext-sections.ld>
#endif

#ifdef CONFIG_GEN_ISR_TABLES
#include <zephyr/linker/intlist.ld>
#endif

"""
        pos = sections_match.end()
        self.rules_applied['sections_includes_added'] = True
        return content[:pos] + includes + content[pos:]
    
    def _add_zephyr_sections(self, content):
        """Add Zephyr-specific sections and includes throughout the linker script."""

        errors_before = len(self.errors)

        # Find the last SRAM phdr from the PHDRS section (after memory conversion)
        # Look for sramN_phdr in the PHDRS section and find the highest N
        phdr_matches = re.findall(r'sram(\d+)_phdr', content)
        if not phdr_matches:
            self.errors.append("Could not find any SRAM phdr in _add_zephyr_sections")
            return content

        # Find the highest number
        max_num = max(int(num) for num in phdr_matches)
        phdr_name = f"sram{max_num}_phdr"

        # 1. Add code data relocation before .sram.rodata
        new_content = re.sub(
            r'(\n)(  \.sram\.rodata : ALIGN\(4\))',
            r'\1#ifdef CONFIG_CODE_DATA_RELOCATION\n#include <linker_relocate.ld>\n#endif\n\n\2',
            content
        )
        if new_content == content:
            self.errors.append("Failed to add #include <linker_relocate.ld> before .sram.rodata")
        content = new_content

        # 2. Add _image_ram_start inside .sram.rodata section
        new_content = re.sub(
            r'(  \.sram\.rodata : ALIGN\(4\)\n  \{\n)(    _sram_rodata_start)',
            r'\1    _image_ram_start = ABSOLUTE(.);\n\2',
            content
        )
        if new_content == content:
            self.errors.append("Failed to add _image_ram_start in .sram.rodata")
        content = new_content

        # 3. Add common-rom and snippets-rom-sections before .clib.rodata section
        new_content = re.sub(
            r'(  \.clib\.rodata : ALIGN\(4\))',
            r'#include <zephyr/linker/common-rom.ld>\n/* Located in generated directory. This file is populated by calling\n * zephyr_linker_sources(ROM_SECTIONS ...). Useful for grouping iterable RO structs.\n */\n#include <snippets-rom-sections.ld>\n\n\1',
            content
        )
        if new_content == content:
            self.errors.append("Failed to add common-rom.ld and snippets-rom-sections.ld before .clib.rodata")
        content = new_content

        # 4. Add __rodata_region_start in .rodata section
        new_content = re.sub(
            r'(  \.rodata : ALIGN\(4\)\n  \{\n)(    _rodata_start)',
            r'\1    __rodata_region_start = ABSOLUTE(.);\n\2',
            content
        )
        if new_content == content:
            self.errors.append("Failed to add __rodata_region_start in .rodata")
        content = new_content

        # 4b. Add snippets-rodata in .rodata section
        new_content = re.sub(
            r'(    \*\(\.rodata1\)\n)(    __XT_EXCEPTION_TABLE__)',
            r'\1\n    . = ALIGN(4);\n    #include <snippets-rodata.ld>\n    . = ALIGN(4);\n\n\2',
            content
        )
        if new_content == content:
            self.errors.append("Failed to add #include <snippets-rodata.ld> in .rodata")
        content = new_content

        # 5. Add __rodata_region_end after _rodata_end (the one near _bss_table_end)
        new_content = re.sub(
            r'(_bss_table_end = ABSOLUTE\(\.\);\n    \. = ALIGN \(4\);\n    _rodata_end = ABSOLUTE\(\.\);)',
            r'\1\n    __rodata_region_end = ABSOLUTE(.);',
            content
        )
        if new_content == content:
            self.errors.append("Failed to add __rodata_region_end after _rodata_end")
        content = new_content

        # 6. Add __text_region_start before .text section
        new_content = re.sub(
            r'(\n)(  \.text : ALIGN\(4\))',
            r'\1  __text_region_start =  ALIGN(4);\n\2',
            content
        )
        if new_content == content:
            self.errors.append("Failed to add __text_region_start before .text section")
        content = new_content

        # 7. Add .noinit section before main .data section and __data_start inside it
        noinit_section = f'''
  .noinit : ALIGN(4)
  {{
    *(.noinit)
    *(.noinit.*)
  }} >RAM :{phdr_name}

#include <snippets-sections.ld>
'''
        # Match ".data : ALIGN(4)" followed by "_data_start" to ensure we get the main .data section
        # This pattern will match the main .data section and add both .noinit before it and __data_start inside
        new_content = re.sub(
            r'(\n)(  \.data : ALIGN\(4\)\n  \{\n)(    _data_start)',
            r'\1' + noinit_section + r'\2    __data_start = ABSOLUTE(.);\n\3',
            content
        )
        if new_content == content:
            self.errors.append("Failed to add .noinit section and __data_start before/in .data section")
        content = new_content

        # 9. Add snippets and relocation includes in .data section
        new_content = re.sub(
            r'(    \. = ALIGN \(4\);\n)(    _data_end)',
            r'\1    #include <snippets-rwdata.ld>\n    . = ALIGN (4);\n#ifdef CONFIG_CODE_DATA_RELOCATION\n#include <linker_sram_data_relocate.ld>\n#endif\n    . = ALIGN (4);\n\2',
            content
        )
        if new_content == content:
            self.errors.append("Failed to add snippets-rwdata.ld and linker_sram_data_relocate.ld in .data section")
        content = new_content

        # 10. Add __data_end after _data_end in the main .data section
        new_content = re.sub(
            r'(#include <linker_sram_data_relocate\.ld>\n#endif\n    \. = ALIGN \(4\);\n    _data_end = ABSOLUTE\(\.\);)',
            r'\1\n    __data_end = ABSOLUTE(.);',
            content
        )
        if new_content == content:
            self.errors.append("Failed to add __data_end after _data_end in .data section")
        content = new_content

        # 11. Add common-ram and other snippets before __llvm_prf_data section
        new_content = re.sub(
            r'(  __llvm_prf_data : ALIGN\(4\))',
            r'#include <snippets-data-sections.ld>\n\n#include <zephyr/linker/common-ram.ld>\n\n#include <snippets-ram-sections.ld>\n\n\1',
            content
        )
        if new_content == content:
            self.errors.append("Failed to add snippets-data-sections.ld and common-ram.ld before __llvm_prf_data")
        content = new_content

        # 12. Add CODE_DATA_RELOCATION in .bss section
        # Use ((?:.*\n)*?) to bridge any intermediate lines between *(COMMON) and . = ALIGN (8);
        new_content = re.sub(
            r'(    \*\(COMMON\)\n)((?:.*\n)*?)(    \. = ALIGN \(8\);)',
            r'\1\2#ifdef CONFIG_CODE_DATA_RELOCATION\n#include <linker_sram_bss_relocate.ld>\n#endif\n\3',
            content
        )
        if new_content == content:
            self.errors.append("Failed to add #include <linker_sram_bss_relocate.ld> in .bss section")
        content = new_content

        self.rules_applied['zephyr_sections_added'] = len(self.errors) == errors_before
        return content
    
    def _remove_extra_blank_lines(self, content):
        """Remove extra blank lines to match reference format."""
        
        # Remove multiple consecutive blank lines, keep max 2
        content = re.sub(r'\n\n\n+', '\n\n', content)
        
        self.rules_applied['extra_blank_lines_removed'] = True
        return content
    
    def _verify_rules(self):
        """Verify that all conversion rules were applied."""
        
        failed_rules = [rule for rule, applied in self.rules_applied.items() if not applied]
        
        if failed_rules:
            error_msg = "The following conversion rules were not applied:\n"
            error_msg += "\n".join(f"  - {rule}" for rule in failed_rules)
            self.errors.append(error_msg)
        
        if self.errors:
            raise RuntimeError("\n".join(self.errors))
    
    def get_summary(self):
        """Get a summary of applied conversions."""
        
        summary = "\nConversion Summary:\n"
        summary += "=" * 60 + "\n"
        
        for rule, applied in self.rules_applied.items():
            status = "[OK]" if applied else "[FAILED]"
            rule_name = rule.replace('_', ' ').title()
            summary += f"{status} {rule_name}\n"
        
        summary += "=" * 60 + "\n"
        
        if all(self.rules_applied.values()):
            summary += "All conversion rules successfully applied!\n"
        else:
            summary += "Some conversion rules failed to apply.\n"
        
        return summary


def main():
    """Main entry point for the linker script converter."""
    
    parser = argparse.ArgumentParser(
        description='Convert Xtensa linker scripts to Zephyr format',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Example usage:
  %(prog)s -i elf32xtensa.x -o soc/cdns/hifi5s_l2/include/hifi5s_l2.ld
  
  %(prog)s \\
    -i /home/kuoping/works/Zephyr.common/elf32xtensa.x \\
    -o /home/kuoping/works/Zephyr.common/soc/cdns/hifi5s_l2/include/hifi5s_l2.ld
"""
    )
    
    parser.add_argument(
        '-i', '--input',
        required=True,
        help='Input linker script file (e.g., elf32xtensa.x)'
    )
    
    parser.add_argument(
        '-o', '--output',
        required=True,
        help='Output linker script file (e.g., hifi5s_l2.ld)'
    )
    
    args = parser.parse_args()
    
    # Verify input file exists
    if not os.path.exists(args.input):
        print(f"Error: Input file does not exist: {args.input}", file=sys.stderr)
        sys.exit(1)
    
    # Perform conversion
    try:
        converter = LinkerScriptConverter()
        converter.convert(args.input, args.output)
        
        print(converter.get_summary())
        print(f"\nOutput written to: {args.output}")
        
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except IOError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except RuntimeError as e:
        print(f"Conversion failed:\n{e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
