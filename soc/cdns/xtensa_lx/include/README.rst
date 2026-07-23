.. SPDX-License-Identifier: Apache-2.0

soc/cdns/xtensa_lx/include
###########################

Overview
********

This directory is intentionally empty in the source tree.

At CMake **configure time**, the file ``xtensa_lx.ld`` is automatically
generated here by ``ldscriptconv.py`` and placed at:

.. code-block:: none

   soc/cdns/xtensa_lx/include/xtensa_lx.ld

This generated linker script is then used as ``SOC_LINKER_SCRIPT`` for all
Xtensa LX SoC builds.

How It Is Generated
*******************

``CMakeLists.txt`` (in the parent directory) runs the conversion when
``xt-clang`` is found in ``PATH`` and ``XTENSA_SYSTEM`` is set in the
environment:

1. The **source** linker script is read from the active Xtensa core
   configuration directory:

   .. code-block:: none

      $XTENSA_SYSTEM/../xtensa-elf/lib/sim-mc/ldscripts/elf32xtensa.x

2. The Python script ``ldscriptconv.py`` converts it to a Zephyr-compatible
   format and writes the result to:

   .. code-block:: none

      soc/cdns/xtensa_lx/include/xtensa_lx.ld

   The conversions applied by ``ldscriptconv.py`` include:

   - Replacing the original Xtensa file header with the Zephyr copyright
     header and the standard Zephyr linker includes
     (``sections.h``, ``linker-defs.h``, ``linker-tool.h``, …).
   - Adding ``#define RAMABLE_REGION`` / ``ROMABLE_REGION`` macros that
     point to the highest-numbered ``sramN_seg`` segment renamed to ``RAM``.
   - Injecting ``CONFIG_GEN_ISR_TABLES`` / ``IDT_LIST`` guards in the
     ``MEMORY`` block.
   - Changing the ``ENTRY`` point from ``_ResetVector`` to
     ``CONFIG_KERNEL_ENTRY``.
   - Inserting Zephyr section snippets (``common-rom.ld``,
     ``common-ram.ld``, ``rel-sections.ld``, ``intlist.ld``,
     ``snippets-*.ld``, ``linker_relocate.ld``, …) at the correct
     positions inside the ``SECTIONS`` block.

Triggering a Regeneration
*************************

The file is regenerated automatically whenever CMake re-configures the
build.  A new configuration is triggered when:

* ``XTENSA_CORE`` or ``XTENSA_SYSTEM`` changes (different core).
* The CMake build directory is deleted and rebuilt from scratch.
* ``cmake --fresh`` (or equivalent) is invoked.

To regenerate manually without a full rebuild, delete the build directory
and run ``cmake`` again:

.. code-block:: shell

   rm -rf <build_dir>
   west build -b <board> <app>

Note
****

``xtensa_lx.ld`` is a **generated file**.  It reflects the memory map of
the currently selected Xtensa core configuration and must **not** be
committed to version control when it has been produced from a local
toolchain installation.  The copy that may already be present in the
repository serves only as a baseline placeholder; it is overwritten on
every configure run when ``xt-clang`` is available.
