/*
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

#define RAMABLE_REGION RAM :sram19_phdr
#define ROMABLE_REGION RAMABLE_REGION

MEMORY
{
  srom0_seg :                         	org = 0x50000000, len = 0x2E0
  srom1_seg :                         	org = 0x500002E0, len = 0xFFFD20
  l2ram0_seg :                        	org = 0x55600000, len = 0x80000
  dram0_0_seg :                       	org = 0x5FFA0000, len = 0x20000
  dram1_0_seg :                       	org = 0x5FFC0000, len = 0x20000
  iram0_0_seg :                       	org = 0x5FFE0000, len = 0x20000
  sram0_seg :                         	org = 0x60000000, len = 0x178
  sram1_seg :                         	org = 0x60000178, len = 0x4
  sram2_seg :                         	org = 0x6000017C, len = 0x1C
  sram3_seg :                         	org = 0x60000198, len = 0x4
  sram4_seg :                         	org = 0x6000019C, len = 0x1C
  sram5_seg :                         	org = 0x600001B8, len = 0x4
  sram6_seg :                         	org = 0x600001BC, len = 0x1C
  sram7_seg :                         	org = 0x600001D8, len = 0x4
  sram8_seg :                         	org = 0x600001DC, len = 0x1C
  sram9_seg :                         	org = 0x600001F8, len = 0x4
  sram10_seg :                        	org = 0x600001FC, len = 0x1C
  sram11_seg :                        	org = 0x60000218, len = 0x4
  sram12_seg :                        	org = 0x6000021C, len = 0x1C
  sram13_seg :                        	org = 0x60000238, len = 0x4
  sram14_seg :                        	org = 0x6000023C, len = 0x1C
  sram15_seg :                        	org = 0x60000258, len = 0x4
  sram16_seg :                        	org = 0x6000025C, len = 0x1C
  sram17_seg :                        	org = 0x60000278, len = 0x4
  sram18_seg :                        	org = 0x6000027C, len = 0x1C
  RAM :                         	org = 0x60000298, len = 0x3FFFD68
#ifdef CONFIG_GEN_ISR_TABLES
  IDT_LIST : org = 0x00000000, len = 0x2000
#endif
}

PHDRS
{
  srom0_phdr PT_LOAD;
  srom1_phdr PT_LOAD;
  l2ram0_phdr PT_LOAD;
  l2ram0_bss_phdr PT_LOAD;
  dram0_0_phdr PT_LOAD;
  dram0_0_bss_phdr PT_LOAD;
  dram1_0_phdr PT_LOAD;
  dram1_0_bss_phdr PT_LOAD;
  iram0_0_phdr PT_LOAD;
  sram0_phdr PT_LOAD;
  sram1_phdr PT_LOAD;
  sram2_phdr PT_LOAD;
  sram3_phdr PT_LOAD;
  sram4_phdr PT_LOAD;
  sram5_phdr PT_LOAD;
  sram6_phdr PT_LOAD;
  sram7_phdr PT_LOAD;
  sram8_phdr PT_LOAD;
  sram9_phdr PT_LOAD;
  sram10_phdr PT_LOAD;
  sram11_phdr PT_LOAD;
  sram12_phdr PT_LOAD;
  sram13_phdr PT_LOAD;
  sram14_phdr PT_LOAD;
  sram15_phdr PT_LOAD;
  sram16_phdr PT_LOAD;
  sram17_phdr PT_LOAD;
  sram18_phdr PT_LOAD;
  sram19_phdr PT_LOAD;
  sram19_bss_phdr PT_LOAD;
}


/*  Default entry point:  */
ENTRY(CONFIG_KERNEL_ENTRY)

/*  Memory boundary addresses:  */
_memmap_mem_srom_start = 0x50000000;
_memmap_mem_srom_end   = 0x51000000;
_memmap_mem_l2regs_start = 0x55500000;
_memmap_mem_l2regs_end   = 0x55501000;
_memmap_mem_l2ram_start = 0x55600000;
_memmap_mem_l2ram_end   = 0x55680000;
_memmap_mem_dram0_start = 0x5ffa0000;
_memmap_mem_dram0_end   = 0x5ffc0000;
_memmap_mem_dram1_start = 0x5ffc0000;
_memmap_mem_dram1_end   = 0x5ffe0000;
_memmap_mem_iram0_start = 0x5ffe0000;
_memmap_mem_iram0_end   = 0x60000000;
_memmap_mem_sram_start = 0x60000000;
_memmap_mem_sram_end   = 0x64000000;
l2regs = 0x55500000;

/*  Memory segment boundary addresses:  */
_memmap_seg_srom0_start = 0x50000000;
_memmap_seg_srom0_max   = 0x500002e0;
_memmap_seg_srom1_start = 0x500002e0;
_memmap_seg_srom1_max   = 0x51000000;
_memmap_seg_l2ram0_start = 0x55600000;
_memmap_seg_l2ram0_max   = 0x55680000;
_memmap_seg_dram0_0_start = 0x5ffa0000;
_memmap_seg_dram0_0_max   = 0x5ffc0000;
_memmap_seg_dram1_0_start = 0x5ffc0000;
_memmap_seg_dram1_0_max   = 0x5ffe0000;
_memmap_seg_iram0_0_start = 0x5ffe0000;
_memmap_seg_iram0_0_max   = 0x60000000;
_memmap_seg_sram0_start = 0x60000000;
_memmap_seg_sram0_max   = 0x60000178;
_memmap_seg_sram1_start = 0x60000178;
_memmap_seg_sram1_max   = 0x6000017c;
_memmap_seg_sram2_start = 0x6000017c;
_memmap_seg_sram2_max   = 0x60000198;
_memmap_seg_sram3_start = 0x60000198;
_memmap_seg_sram3_max   = 0x6000019c;
_memmap_seg_sram4_start = 0x6000019c;
_memmap_seg_sram4_max   = 0x600001b8;
_memmap_seg_sram5_start = 0x600001b8;
_memmap_seg_sram5_max   = 0x600001bc;
_memmap_seg_sram6_start = 0x600001bc;
_memmap_seg_sram6_max   = 0x600001d8;
_memmap_seg_sram7_start = 0x600001d8;
_memmap_seg_sram7_max   = 0x600001dc;
_memmap_seg_sram8_start = 0x600001dc;
_memmap_seg_sram8_max   = 0x600001f8;
_memmap_seg_sram9_start = 0x600001f8;
_memmap_seg_sram9_max   = 0x600001fc;
_memmap_seg_sram10_start = 0x600001fc;
_memmap_seg_sram10_max   = 0x60000218;
_memmap_seg_sram11_start = 0x60000218;
_memmap_seg_sram11_max   = 0x6000021c;
_memmap_seg_sram12_start = 0x6000021c;
_memmap_seg_sram12_max   = 0x60000238;
_memmap_seg_sram13_start = 0x60000238;
_memmap_seg_sram13_max   = 0x6000023c;
_memmap_seg_sram14_start = 0x6000023c;
_memmap_seg_sram14_max   = 0x60000258;
_memmap_seg_sram15_start = 0x60000258;
_memmap_seg_sram15_max   = 0x6000025c;
_memmap_seg_sram16_start = 0x6000025c;
_memmap_seg_sram16_max   = 0x60000278;
_memmap_seg_sram17_start = 0x60000278;
_memmap_seg_sram17_max   = 0x6000027c;
_memmap_seg_sram18_start = 0x6000027c;
_memmap_seg_sram18_max   = 0x60000298;
_memmap_seg_sram19_start = 0x60000298;
_memmap_seg_sram19_max   = 0x64000000;

_rom_store_table = 0;
PROVIDE(_memmap_reset_vector = 0x50000000);
PROVIDE(_memmap_vecbase_reset = 0x60000000);
/* Various memory-map dependent cache attribute settings: */
_memmap_cacheattr_wb_base = 0x00001400;
_memmap_cacheattr_wt_base = 0x00003400;
_memmap_cacheattr_bp_base = 0x00004400;
_memmap_cacheattr_unused_mask = 0xFFFF00FF;
_memmap_cacheattr_wb_trapnull = 0x44441440;
_memmap_cacheattr_wba_trapnull = 0x44441440;
_memmap_cacheattr_wbna_trapnull = 0x44442440;
_memmap_cacheattr_wt_trapnull = 0x44443440;
_memmap_cacheattr_bp_trapnull = 0x44444440;
_memmap_cacheattr_wb_strict = 0x00001400;
_memmap_cacheattr_wt_strict = 0x00003400;
_memmap_cacheattr_bp_strict = 0x00004400;
_memmap_cacheattr_wb_allvalid = 0x44441444;
_memmap_cacheattr_wt_allvalid = 0x44443444;
_memmap_cacheattr_bp_allvalid = 0x44444444;
_memmap_region_map = 0x0000000C;
PROVIDE(_memmap_cacheattr_reset = _memmap_cacheattr_wb_trapnull);

SECTIONS
{

#include <zephyr/linker/rel-sections.ld>

#ifdef CONFIG_LLEXT
#include <zephyr/linker/llext-sections.ld>
#endif

#ifdef CONFIG_GEN_ISR_TABLES
#include <zephyr/linker/intlist.ld>
#endif

  .ResetVector.text : ALIGN(4)
  {
    _ResetVector_text_start = ABSOLUTE(.);
    KEEP (*(.ResetVector.text))
    . = ALIGN (4);
    _ResetVector_text_end = ABSOLUTE(.);
  } >srom0_seg :srom0_phdr

  .ResetHandler.text : ALIGN(4)
  {
    _ResetHandler_text_start = ABSOLUTE(.);
    *(.ResetHandler.literal .ResetHandler.text)
    . = ALIGN (4);
    _ResetHandler_text_end = ABSOLUTE(.);
    _memmap_seg_srom0_end = ALIGN(0x8);
  } >srom0_seg :srom0_phdr


  .srom.rodata : ALIGN(4)
  {
    _srom_rodata_start = ABSOLUTE(.);
    *(.srom.rodata)
    . = ALIGN (4);
    _srom_rodata_end = ABSOLUTE(.);
  } >srom1_seg :srom1_phdr

  .srom.text : ALIGN(4)
  {
    _srom_text_start = ABSOLUTE(.);
    *(.srom.literal .srom.text)
    . = ALIGN (4);
    _srom_text_end = ABSOLUTE(.);
    _memmap_seg_srom1_end = ALIGN(0x8);
  } >srom1_seg :srom1_phdr

  _memmap_mem_srom_max = ABSOLUTE(.);

  .l2ram.rodata : ALIGN(4)
  {
    _l2ram_rodata_start = ABSOLUTE(.);
    *(.l2ram.rodata)
    . = ALIGN (4);
    _l2ram_rodata_end = ABSOLUTE(.);
  } >l2ram0_seg :l2ram0_phdr

  .l2ram.text : ALIGN(4)
  {
    _l2ram_text_start = ABSOLUTE(.);
    *(.l2ram.literal .l2ram.text)
    . = ALIGN (4);
    _l2ram_text_end = ABSOLUTE(.);
  } >l2ram0_seg :l2ram0_phdr

  .l2ram.data : ALIGN(4)
  {
    _l2ram_data_start = ABSOLUTE(.);
    *(.l2ram.data)
    . = ALIGN (4);
    _l2ram_data_end = ABSOLUTE(.);
  } >l2ram0_seg :l2ram0_phdr

  .l2ram.bss (NOLOAD) : ALIGN(8)
  {
    . = ALIGN (8);
    _l2ram_bss_start = ABSOLUTE(.);
    *(.l2ram.bss)
    . = ALIGN (8);
    _l2ram_bss_end = ABSOLUTE(.);
    _memmap_seg_l2ram0_end = ALIGN(0x8);
  } >l2ram0_seg :l2ram0_bss_phdr

  _memmap_mem_l2ram_max = ABSOLUTE(.);

  .dram0.rodata : ALIGN(4)
  {
    _dram0_rodata_start = ABSOLUTE(.);
    *(.dram0.rodata)
    . = ALIGN (4);
    _dram0_rodata_end = ABSOLUTE(.);
  } >dram0_0_seg :dram0_0_phdr

  .dram0.data : ALIGN(4)
  {
    _dram0_data_start = ABSOLUTE(.);
    *(.dram0.data)
    . = ALIGN (4);
    _dram0_data_end = ABSOLUTE(.);
  } >dram0_0_seg :dram0_0_phdr

  .clib.percpu.data : ALIGN(4)
  {
    _clib_percpu_data_start = ABSOLUTE(.);
    *(.clib.percpu.data)
    . = ALIGN (4);
    _clib_percpu_data_end = ABSOLUTE(.);
  } >dram0_0_seg :dram0_0_phdr

  .rtos.percpu.data : ALIGN(4)
  {
    _rtos_percpu_data_start = ABSOLUTE(.);
    *(.rtos.percpu.data)
    . = ALIGN (4);
    _rtos_percpu_data_end = ABSOLUTE(.);
  } >dram0_0_seg :dram0_0_phdr

  .dram0.bss (NOLOAD) : ALIGN(8)
  {
    . = ALIGN (8);
    _dram0_bss_start = ABSOLUTE(.);
    *(.dram0.bss)
    . = ALIGN (8);
    _dram0_bss_end = ABSOLUTE(.);
  } >dram0_0_seg :dram0_0_bss_phdr

  .clib.percpu.bss (NOLOAD) : ALIGN(8)
  {
    . = ALIGN (8);
    _clib_percpu_bss_start = ABSOLUTE(.);
    *(.clib.percpu.bss)
    . = ALIGN (8);
    _clib_percpu_bss_end = ABSOLUTE(.);
  } >dram0_0_seg :dram0_0_bss_phdr

  .rtos.percpu.bss (NOLOAD) : ALIGN(8)
  {
    . = ALIGN (8);
    _rtos_percpu_bss_start = ABSOLUTE(.);
    *(.rtos.percpu.bss)
    . = ALIGN (8);
    _rtos_percpu_bss_end = ABSOLUTE(.);
    _memmap_seg_dram0_0_end = ALIGN(0x8);
  } >dram0_0_seg :dram0_0_bss_phdr

  _memmap_mem_dram0_max = ABSOLUTE(.);

  .dram1.rodata : ALIGN(4)
  {
    _dram1_rodata_start = ABSOLUTE(.);
    *(.dram1.rodata)
    . = ALIGN (4);
    _dram1_rodata_end = ABSOLUTE(.);
  } >dram1_0_seg :dram1_0_phdr

  .iram0.literal : ALIGN(4)
  {
    _iram0_literal_start = ABSOLUTE(.);
    *(.iram0.literal)
    *(.iram.literal)
    *(.iram.text.literal)
    . = ALIGN (4);
    _iram0_literal_end = ABSOLUTE(.);
  } >dram1_0_seg :dram1_0_phdr

  .dram1.data : ALIGN(4)
  {
    _dram1_data_start = ABSOLUTE(.);
    *(.dram1.data)
    . = ALIGN (4);
    _dram1_data_end = ABSOLUTE(.);
  } >dram1_0_seg :dram1_0_phdr

  .dram1.bss (NOLOAD) : ALIGN(8)
  {
    . = ALIGN (8);
    _dram1_bss_start = ABSOLUTE(.);
    *(.dram1.bss)
    . = ALIGN (8);
    _dram1_bss_end = ABSOLUTE(.);
    _memmap_seg_dram1_0_end = ALIGN(0x8);
  } >dram1_0_seg :dram1_0_bss_phdr

  _memmap_mem_dram1_max = ABSOLUTE(.);

  .iram0.text : ALIGN(4)
  {
    _iram0_text_start = ABSOLUTE(.);
    *(.iram0.text)
    *(.iram.text)
    . = ALIGN (4);
    _iram0_text_end = ABSOLUTE(.);
    _memmap_seg_iram0_0_end = ALIGN(0x8);
  } >iram0_0_seg :iram0_0_phdr

  _memmap_mem_iram0_max = ABSOLUTE(.);

  .WindowVectors.text : ALIGN(4)
  {
    _WindowVectors_text_start = ABSOLUTE(.);
    KEEP (*(.WindowVectors.text))
    . = ALIGN (4);
    _WindowVectors_text_end = ABSOLUTE(.);
    _memmap_seg_sram0_end = ALIGN(0x8);
  } >sram0_seg :sram0_phdr


  .Level2InterruptVector.literal : ALIGN(4)
  {
    _Level2InterruptVector_literal_start = ABSOLUTE(.);
    *(.Level2InterruptVector.literal)
    . = ALIGN (4);
    _Level2InterruptVector_literal_end = ABSOLUTE(.);
    _memmap_seg_sram1_end = ALIGN(0x8);
  } >sram1_seg :sram1_phdr


  .Level2InterruptVector.text : ALIGN(4)
  {
    _Level2InterruptVector_text_start = ABSOLUTE(.);
    KEEP (*(.Level2InterruptVector.text))
    . = ALIGN (4);
    _Level2InterruptVector_text_end = ABSOLUTE(.);
    _memmap_seg_sram2_end = ALIGN(0x8);
  } >sram2_seg :sram2_phdr


  .Level3InterruptVector.literal : ALIGN(4)
  {
    _Level3InterruptVector_literal_start = ABSOLUTE(.);
    *(.Level3InterruptVector.literal)
    . = ALIGN (4);
    _Level3InterruptVector_literal_end = ABSOLUTE(.);
    _memmap_seg_sram3_end = ALIGN(0x8);
  } >sram3_seg :sram3_phdr


  .Level3InterruptVector.text : ALIGN(4)
  {
    _Level3InterruptVector_text_start = ABSOLUTE(.);
    KEEP (*(.Level3InterruptVector.text))
    . = ALIGN (4);
    _Level3InterruptVector_text_end = ABSOLUTE(.);
    _memmap_seg_sram4_end = ALIGN(0x8);
  } >sram4_seg :sram4_phdr


  .Level4InterruptVector.literal : ALIGN(4)
  {
    _Level4InterruptVector_literal_start = ABSOLUTE(.);
    *(.Level4InterruptVector.literal)
    . = ALIGN (4);
    _Level4InterruptVector_literal_end = ABSOLUTE(.);
    _memmap_seg_sram5_end = ALIGN(0x8);
  } >sram5_seg :sram5_phdr


  .Level4InterruptVector.text : ALIGN(4)
  {
    _Level4InterruptVector_text_start = ABSOLUTE(.);
    KEEP (*(.Level4InterruptVector.text))
    . = ALIGN (4);
    _Level4InterruptVector_text_end = ABSOLUTE(.);
    _memmap_seg_sram6_end = ALIGN(0x8);
  } >sram6_seg :sram6_phdr


  .Level5InterruptVector.literal : ALIGN(4)
  {
    _Level5InterruptVector_literal_start = ABSOLUTE(.);
    *(.Level5InterruptVector.literal)
    . = ALIGN (4);
    _Level5InterruptVector_literal_end = ABSOLUTE(.);
    _memmap_seg_sram7_end = ALIGN(0x8);
  } >sram7_seg :sram7_phdr


  .Level5InterruptVector.text : ALIGN(4)
  {
    _Level5InterruptVector_text_start = ABSOLUTE(.);
    KEEP (*(.Level5InterruptVector.text))
    . = ALIGN (4);
    _Level5InterruptVector_text_end = ABSOLUTE(.);
    _memmap_seg_sram8_end = ALIGN(0x8);
  } >sram8_seg :sram8_phdr


  .DebugExceptionVector.literal : ALIGN(4)
  {
    _DebugExceptionVector_literal_start = ABSOLUTE(.);
    *(.DebugExceptionVector.literal)
    . = ALIGN (4);
    _DebugExceptionVector_literal_end = ABSOLUTE(.);
    _memmap_seg_sram9_end = ALIGN(0x8);
  } >sram9_seg :sram9_phdr


  .DebugExceptionVector.text : ALIGN(4)
  {
    _DebugExceptionVector_text_start = ABSOLUTE(.);
    KEEP (*(.DebugExceptionVector.text))
    . = ALIGN (4);
    _DebugExceptionVector_text_end = ABSOLUTE(.);
    _memmap_seg_sram10_end = ALIGN(0x8);
  } >sram10_seg :sram10_phdr


  .NMIExceptionVector.literal : ALIGN(4)
  {
    _NMIExceptionVector_literal_start = ABSOLUTE(.);
    *(.NMIExceptionVector.literal)
    . = ALIGN (4);
    _NMIExceptionVector_literal_end = ABSOLUTE(.);
    _memmap_seg_sram11_end = ALIGN(0x8);
  } >sram11_seg :sram11_phdr


  .NMIExceptionVector.text : ALIGN(4)
  {
    _NMIExceptionVector_text_start = ABSOLUTE(.);
    KEEP (*(.NMIExceptionVector.text))
    . = ALIGN (4);
    _NMIExceptionVector_text_end = ABSOLUTE(.);
    _memmap_seg_sram12_end = ALIGN(0x8);
  } >sram12_seg :sram12_phdr


  .KernelExceptionVector.literal : ALIGN(4)
  {
    _KernelExceptionVector_literal_start = ABSOLUTE(.);
    *(.KernelExceptionVector.literal)
    . = ALIGN (4);
    _KernelExceptionVector_literal_end = ABSOLUTE(.);
    _memmap_seg_sram13_end = ALIGN(0x8);
  } >sram13_seg :sram13_phdr


  .KernelExceptionVector.text : ALIGN(4)
  {
    _KernelExceptionVector_text_start = ABSOLUTE(.);
    KEEP (*(.KernelExceptionVector.text))
    . = ALIGN (4);
    _KernelExceptionVector_text_end = ABSOLUTE(.);
    _memmap_seg_sram14_end = ALIGN(0x8);
  } >sram14_seg :sram14_phdr


  .UserExceptionVector.literal : ALIGN(4)
  {
    _UserExceptionVector_literal_start = ABSOLUTE(.);
    *(.UserExceptionVector.literal)
    . = ALIGN (4);
    _UserExceptionVector_literal_end = ABSOLUTE(.);
    _memmap_seg_sram15_end = ALIGN(0x8);
  } >sram15_seg :sram15_phdr


  .UserExceptionVector.text : ALIGN(4)
  {
    _UserExceptionVector_text_start = ABSOLUTE(.);
    KEEP (*(.UserExceptionVector.text))
    . = ALIGN (4);
    _UserExceptionVector_text_end = ABSOLUTE(.);
    _memmap_seg_sram16_end = ALIGN(0x8);
  } >sram16_seg :sram16_phdr


  .DoubleExceptionVector.literal : ALIGN(4)
  {
    _DoubleExceptionVector_literal_start = ABSOLUTE(.);
    *(.DoubleExceptionVector.literal)
    . = ALIGN (4);
    _DoubleExceptionVector_literal_end = ABSOLUTE(.);
    _memmap_seg_sram17_end = ALIGN(0x8);
  } >sram17_seg :sram17_phdr


  .DoubleExceptionVector.text : ALIGN(4)
  {
    _DoubleExceptionVector_text_start = ABSOLUTE(.);
    KEEP (*(.DoubleExceptionVector.text))
    . = ALIGN (4);
    _DoubleExceptionVector_text_end = ABSOLUTE(.);
    _memmap_seg_sram18_end = ALIGN(0x8);
  } >sram18_seg :sram18_phdr

#ifdef CONFIG_CODE_DATA_RELOCATION
#include <linker_relocate.ld>
#endif

  .sram.rodata : ALIGN(4)
  {
    _image_ram_start = ABSOLUTE(.);
    _sram_rodata_start = ABSOLUTE(.);
    *(.sram.rodata)
    . = ALIGN (4);
    _sram_rodata_end = ABSOLUTE(.);
  } >RAM :sram19_phdr

#include <zephyr/linker/common-rom.ld>
/* Located in generated directory. This file is populated by calling
 * zephyr_linker_sources(ROM_SECTIONS ...). Useful for grouping iterable RO structs.
 */
#include <snippets-rom-sections.ld>

  .clib.rodata : ALIGN(4)
  {
    _clib_rodata_start = ABSOLUTE(.);
    *(.clib.rodata)
    . = ALIGN (4);
    _clib_rodata_end = ABSOLUTE(.);
  } >RAM :sram19_phdr

  .rtos.rodata : ALIGN(4)
  {
    _rtos_rodata_start = ABSOLUTE(.);
    *(.rtos.rodata)
    . = ALIGN (4);
    _rtos_rodata_end = ABSOLUTE(.);
  } >RAM :sram19_phdr

  .rodata : ALIGN(4)
  {
    __rodata_region_start = ABSOLUTE(.);
    _rodata_start = ABSOLUTE(.);
    *(.rodata)
    *(SORT(.rodata.sort.*))
    KEEP (*(SORT(.rodata.keepsort.*) .rodata.keep.*))
    *(.rodata.*)
    *(.gnu.linkonce.r.*)
    *(.rodata1)

    . = ALIGN(4);
    #include <snippets-rodata.ld>
    . = ALIGN(4);

    __XT_EXCEPTION_TABLE__ = ABSOLUTE(.);
    KEEP (*(.xt_except_table))
    KEEP (*(.gcc_except_table))
    *(.gnu.linkonce.e.*)
    *(.gnu.version_r)
    PROVIDE (__eh_frame_start = .);
    KEEP (*(.eh_frame))
    PROVIDE (__eh_frame_end = .);
    /*  C++ constructor and destructor tables, properly ordered:  */
    KEEP (*crtbegin.o(.ctors))
    KEEP (*(EXCLUDE_FILE (*crtend.o) .ctors))
    KEEP (*(SORT(.ctors.*)))
    KEEP (*(.ctors))
    KEEP (*crtbegin.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend.o) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*(.dtors))
    /*  C++ exception handlers table:  */
    __XT_EXCEPTION_DESCS__ = ABSOLUTE(.);
    *(.xt_except_desc)
    *(.gnu.linkonce.h.*)
    __XT_EXCEPTION_DESCS_END__ = ABSOLUTE(.);
    *(.xt_except_desc_end)
    *(.dynamic)
    *(.gnu.version_d)
    . = ALIGN(4);		/* this table MUST be 4-byte aligned */
    _bss_table_start = ABSOLUTE(.);
    LONG(_l2ram_bss_start)
    LONG(_l2ram_bss_end)
    LONG(_dram0_bss_start)
    LONG(_dram0_bss_end)
    LONG(_clib_percpu_bss_start)
    LONG(_clib_percpu_bss_end)
    LONG(_rtos_percpu_bss_start)
    LONG(_rtos_percpu_bss_end)
    LONG(_dram1_bss_start)
    LONG(_dram1_bss_end)
    LONG(_sram_bss_start)
    LONG(_sram_bss_end)
    LONG(_clib_bss_start)
    LONG(_clib_bss_end)
    LONG(_rtos_bss_start)
    LONG(_rtos_bss_end)
    LONG(_bss_start)
    LONG(_bss_end)
    _bss_table_end = ABSOLUTE(.);
    . = ALIGN (4);
    _rodata_end = ABSOLUTE(.);
    __rodata_region_end = ABSOLUTE(.);
  } >RAM :sram19_phdr

  .sram.text : ALIGN(4)
  {
    _sram_text_start = ABSOLUTE(.);
    *(.sram.literal .sram.text)
    . = ALIGN (4);
    _sram_text_end = ABSOLUTE(.);
  } >RAM :sram19_phdr

  .clib.text : ALIGN(4)
  {
    _clib_text_start = ABSOLUTE(.);
    *(.clib.literal .clib.text)
    . = ALIGN (4);
    _clib_text_end = ABSOLUTE(.);
  } >RAM :sram19_phdr

  .rtos.text : ALIGN(4)
  {
    _rtos_text_start = ABSOLUTE(.);
    *(.rtos.literal .rtos.text)
    . = ALIGN (4);
    _rtos_text_end = ABSOLUTE(.);
  } >RAM :sram19_phdr

  __text_region_start =  ALIGN(4);
  .text : ALIGN(4)
  {
    _stext = .;
    _text_start = ABSOLUTE(.);
    *(.entry.text)
    *(.init.literal)
    KEEP(*(.init))
    *(.literal.sort.* SORT(.text.sort.*))
    KEEP (*(.literal.keepsort.* SORT(.text.keepsort.*) .literal.keep.* .text.keep.* .literal.*personality* .text.*personality*))
    *(.literal .text .literal.* .text.* .stub .gnu.warning .gnu.linkonce.literal.* .gnu.linkonce.t.*.literal .gnu.linkonce.t.*)
    *(.fini.literal)
    KEEP(*(.fini))
    *(.gnu.version)
    . = ALIGN (4);
    _text_end = ABSOLUTE(.);
    _etext = .;
  } >RAM :sram19_phdr

  .sram.data : ALIGN(4)
  {
    _sram_data_start = ABSOLUTE(.);
    *(.sram.data)
    . = ALIGN (4);
    _sram_data_end = ABSOLUTE(.);
  } >RAM :sram19_phdr

  .clib.data : ALIGN(4)
  {
    _clib_data_start = ABSOLUTE(.);
    *(.clib.data)
    . = ALIGN (4);
    _clib_data_end = ABSOLUTE(.);
  } >RAM :sram19_phdr

  .rtos.data : ALIGN(4)
  {
    _rtos_data_start = ABSOLUTE(.);
    *(.rtos.data)
    . = ALIGN (4);
    _rtos_data_end = ABSOLUTE(.);
  } >RAM :sram19_phdr

  .noinit : ALIGN(4)
  {
    *(.noinit)
    *(.noinit.*)
  } >RAM :sram19_phdr

#include <snippets-sections.ld>

  .data : ALIGN(4)
  {
    __data_start = ABSOLUTE(.);
    _data_start = ABSOLUTE(.);
    *(.data)
    *(SORT(.data.sort.*))
    KEEP (*(SORT(.data.keepsort.*) .data.keep.*))
    *(.data.*)
    *(.gnu.linkonce.d.*)
    KEEP(*(.gnu.linkonce.d.*personality*))
    *(.data1)
    *(.sdata)
    *(.sdata.*)
    *(.gnu.linkonce.s.*)
    *(.sdata2)
    *(.sdata2.*)
    *(.gnu.linkonce.s2.*)
    KEEP(*(.jcr))
    . = ALIGN (4);
    #include <snippets-rwdata.ld>
    . = ALIGN (4);
#ifdef CONFIG_CODE_DATA_RELOCATION
#include <linker_sram_data_relocate.ld>
#endif
    . = ALIGN (4);
    _data_end = ABSOLUTE(.);
    __data_end = ABSOLUTE(.);
  } >RAM :sram19_phdr

#include <snippets-data-sections.ld>

#include <zephyr/linker/common-ram.ld>

#include <snippets-ram-sections.ld>

  __llvm_prf_data : ALIGN(4)
  {
    __llvm_prf_data_start = ABSOLUTE(.);
    *(__llvm_prf_data)
    . = ALIGN (4);
    __llvm_prf_data_end = ABSOLUTE(.);
  } >RAM :sram19_phdr

  __llvm_prf_cnts : ALIGN(4)
  {
    __llvm_prf_cnts_start = ABSOLUTE(.);
    *(__llvm_prf_cnts)
    . = ALIGN (4);
    __llvm_prf_cnts_end = ABSOLUTE(.);
  } >RAM :sram19_phdr

  __llvm_prf_names : ALIGN(4)
  {
    __llvm_prf_names_start = ABSOLUTE(.);
    *(__llvm_prf_names)
    . = ALIGN (4);
    __llvm_prf_names_end = ABSOLUTE(.);
  } >RAM :sram19_phdr

  __llvm_prf_vnds : ALIGN(4)
  {
    __llvm_prf_vnds_start = ABSOLUTE(.);
    *(__llvm_prf_vnds)
    . = ALIGN (4);
    __llvm_prf_vnds_end = ABSOLUTE(.);
  } >RAM :sram19_phdr

  __llvm_covmap : ALIGN(4)
  {
    __llvm_covmap_start = ABSOLUTE(.);
    *(__llvm_covmap)
    . = ALIGN (4);
    __llvm_covmap_end = ABSOLUTE(.);
  } >RAM :sram19_phdr

  __llvm_covfun : ALIGN(4)
  {
    __llvm_covfun_start = ABSOLUTE(.);
    *(__llvm_covfun)
    . = ALIGN (4);
    __llvm_covfun_end = ABSOLUTE(.);
  } >RAM :sram19_phdr

  .xtos.lock : ALIGN(4)
  {
    _xtos_lock_start = ABSOLUTE(.);
    *(.xtos.lock)
    . = ALIGN (4);
    _xtos_lock_end = ABSOLUTE(.);
  } >RAM :sram19_phdr

  .note.gnu.build-id : ALIGN(4)
  {
    _note_gnu_build-id_start = ABSOLUTE(.);
    *(.note.gnu.build-id)
    . = ALIGN (4);
    _note_gnu_build-id_end = ABSOLUTE(.);
  } >RAM :sram19_phdr

  .sram.bss (NOLOAD) : ALIGN(8)
  {
    . = ALIGN (8);
    _sram_bss_start = ABSOLUTE(.);
    *(.sram.bss)
    . = ALIGN (8);
    _sram_bss_end = ABSOLUTE(.);
  } >RAM :sram19_bss_phdr

  .clib.bss (NOLOAD) : ALIGN(8)
  {
    . = ALIGN (8);
    _clib_bss_start = ABSOLUTE(.);
    *(.clib.bss)
    . = ALIGN (8);
    _clib_bss_end = ABSOLUTE(.);
  } >RAM :sram19_bss_phdr

  .rtos.bss (NOLOAD) : ALIGN(8)
  {
    . = ALIGN (8);
    _rtos_bss_start = ABSOLUTE(.);
    *(.rtos.bss)
    . = ALIGN (8);
    _rtos_bss_end = ABSOLUTE(.);
  } >RAM :sram19_bss_phdr

  .bss (NOLOAD) : ALIGN(8)
  {
    . = ALIGN (8);
    _bss_start = ABSOLUTE(.);
    *(.dynsbss)
    *(.sbss)
    *(.sbss.*)
    *(.gnu.linkonce.sb.*)
    *(.scommon)
    *(.sbss2)
    *(.sbss2.*)
    *(.gnu.linkonce.sb2.*)
    *(.dynbss)
    *(.bss)
    *(SORT(.bss.sort.*))
    KEEP (*(SORT(.bss.keepsort.*) .bss.keep.*))
    *(.bss.*)
    *(.gnu.linkonce.b.*)
    *(COMMON)
#ifdef CONFIG_CODE_DATA_RELOCATION
#include <linker_sram_bss_relocate.ld>
#endif
    . = ALIGN (8);
    _bss_end = ABSOLUTE(.);
    _end = ALIGN(0x8);
    PROVIDE(end = ALIGN(0x8));
    _stack_sentry = ALIGN(0x8);
    _memmap_seg_sram19_end = ALIGN(0x8);
  } >RAM :sram19_bss_phdr

  PROVIDE(__stack = 0x64000000);
  _heap_sentry = 0x64000000;

  _memmap_mem_sram_max = ABSOLUTE(.);

  .debug  0 :  { *(.debug) }
  .line  0 :  { *(.line) }
  .debug_srcinfo  0 :  { *(.debug_srcinfo) }
  .debug_sfnames  0 :  { *(.debug_sfnames) }
  .debug_aranges  0 :  { *(.debug_aranges) }
  .debug_ranges   0 :  { *(.debug_ranges) }
  .debug_pubnames  0 :  { *(.debug_pubnames) }
  .debug_info  0 :  { *(.debug_info) }
  .debug_abbrev  0 :  { *(.debug_abbrev) }
  .debug_line  0 :  { *(.debug_line) }
  .debug_frame  0 :  { *(.debug_frame) }
  .debug_str  0 :  { *(.debug_str) }
  .debug_loc  0 :  { *(.debug_loc) }
  .debug_macinfo  0 :  { *(.debug_macinfo) }
  .debug_weaknames  0 :  { *(.debug_weaknames) }
  .debug_funcnames  0 :  { *(.debug_funcnames) }
  .debug_typenames  0 :  { *(.debug_typenames) }
  .debug_varnames  0 :  { *(.debug_varnames) }
  .debug.xt.map 0 :  { *(.debug.xt.map) }
  .xt.insn 0 :
  {
    KEEP (*(.xt.insn))
    KEEP (*(.gnu.linkonce.x.*))
  }
  .xt.prop 0 :
  {
    *(.xt.prop)
    *(.xt.prop.*)
    *(.gnu.linkonce.prop.*)
  }
  .xt.lit 0 :
  {
    *(.xt.lit)
    *(.xt.lit.*)
    *(.gnu.linkonce.p.*)
  }
  .xtensa.info 0 :
  {
    *(.xtensa.info)
  }
  .debug.xt.callgraph 0 :
  {
    KEEP (*(.debug.xt.callgraph .debug.xt.callgraph.* .gnu.linkonce.xt.callgraph.*))
  }
  .comment 0 :
  {
    KEEP(*(.comment))
  }
  .note.GNU-stack 0 :
  {
    *(.note.GNU-stack)
  }
}

