# Copyright (c) 2024 Cadence Design Systems, Inc.
# SPDX-License-Identifier: Apache-2.0

zephyr_include_directories(include)

zephyr_library_sources(config_check.c)

# ---------------------------------------------------------------------------
# Toolchain-driven setup: run at cmake configure time when xt-clang is present.
# Both steps below read from the same xt-clang config root so they run
# together; switching XTENSA_CORE triggers a new cmake configure run which
# re-executes both steps automatically.
# ---------------------------------------------------------------------------
find_program(XT_CLANG xt-clang)

if(XT_CLANG)
  # Derive the core-specific build root from $XTENSA_SYSTEM (already set by
  # the build environment: .../builds/<ver>/<core>/config).  Its parent is
  # the core build root where xtensa-elf/lib/sim-mc/ lives.
  set(XT_CORE_ROOT "$ENV{XTENSA_SYSTEM}/..")
  get_filename_component(XT_CORE_ROOT "${XT_CORE_ROOT}" ABSOLUTE)

  if(IS_DIRECTORY "${XT_CORE_ROOT}")
    # -------------------------------------------------------------------
    # Detect multi-core IPI support: XCHAL_SUBSYS_IPI_S0C0_INTNUM is
    # defined in src/config/core.h only for multi-core subsystem configs.
    # smp.c must NOT be compiled for single-core targets.
    # -------------------------------------------------------------------
    set(_xt_core_h "${XT_CORE_ROOT}/src/config/core.h")
    if(EXISTS "${_xt_core_h}")
      file(STRINGS "${_xt_core_h}" _ipi_def
           REGEX "XCHAL_SUBSYS_IPI_S0C0_INTNUM")
    endif()

    # -------------------------------------------------------------------
    # Detect MPU support: query config dir via xt-clang --show-config=config,
    # then read core.h and check for XCHAL_HAVE_MPU 1.
    # -------------------------------------------------------------------
    execute_process(
      COMMAND ${XT_CLANG} --show-config=config
      OUTPUT_VARIABLE _xt_cfg_dir
      OUTPUT_STRIP_TRAILING_WHITESPACE
      RESULT_VARIABLE _xt_cfg_rc
      ERROR_QUIET
    )
    if(_xt_cfg_rc EQUAL 0 AND _xt_cfg_dir)
      set(_xt_mpu_core_h "${_xt_cfg_dir}/src/config/core.h")
      if(EXISTS "${_xt_mpu_core_h}")
        file(STRINGS "${_xt_mpu_core_h}" _mpu_def
             REGEX "^#define[ \t]+XCHAL_HAVE_MPU[ \t]+1")
        if(_mpu_def)
          message(STATUS "xtensa_lx: XCHAL_HAVE_MPU=1 detected, adding mpu_table.c")
          zephyr_library_sources(mpu_table.c)
        else()
          message(STATUS "xtensa_lx: XCHAL_HAVE_MPU not set, skipping mpu_table.c")
        endif()
      else()
        message(WARNING "xtensa_lx: core.h not found: ${_xt_mpu_core_h}, skipping mpu_table.c")
      endif()
    else()
      message(WARNING "xtensa_lx: 'xt-clang --show-config=config' failed (rc=${_xt_cfg_rc}), skipping mpu_table.c")
    endif()

    if(CONFIG_SMP)
      if(_ipi_def)
        zephyr_library_sources(smp.c)
      else()
        message(FATAL_ERROR
          "xtensa_lx: CONFIG_SMP=y is not supported for single-core "
          "configurations. Core '$ENV{XTENSA_CORE}' does not define "
          "XCHAL_SUBSYS_IPI_S0C0_INTNUM. "
          "Disable CONFIG_SMP or use a multi-core XTENSA_CORE.")
      endif()
    endif()

    set(_xt_clang_rc 0)   # treat as success
    set(XT_SIM_DIR "${XT_CORE_ROOT}/xtensa-elf/lib/sim-mc")
    set(LD_SCRIPT_SRC "${XT_SIM_DIR}/ldscripts/elf32xtensa.x")
    set(LD_SCRIPT_DST "${CMAKE_CURRENT_SOURCE_DIR}/include/xtensa_lx.ld")

    if(EXISTS "${LD_SCRIPT_SRC}")
      # -----------------------------------------------------------------
      # Step 1: Generate linker script from toolchain's elf32xtensa.x
      # -----------------------------------------------------------------
      message(STATUS "xtensa_lx: Generating linker script from ${LD_SCRIPT_SRC}")
      execute_process(
        COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/ldscriptconv.py
                -i ${LD_SCRIPT_SRC}
                -o ${LD_SCRIPT_DST}
        RESULT_VARIABLE _ldconv_rc
        OUTPUT_VARIABLE _ldconv_out
        ERROR_VARIABLE  _ldconv_err
      )
      if(NOT _ldconv_rc EQUAL 0)
        message(WARNING "xtensa_lx: ldscriptconv.py failed: ${_ldconv_err}")
      else()
        message(STATUS "xtensa_lx: Linker script written to ${LD_SCRIPT_DST}")
      endif()

      # -----------------------------------------------------------------
      # Step 2: Update xtensa_lx.dtsi SRAM base and size.
      # Uses the same elf32xtensa.x so the dtsi always matches the core.
      # -----------------------------------------------------------------
      set(DTSI_FILE "${CMAKE_CURRENT_SOURCE_DIR}/../../../dts/xtensa/xtensa_lx.dtsi")
      if(EXISTS "${DTSI_FILE}")
        message(STATUS "xtensa_lx: Updating SRAM base/size in xtensa_lx.dtsi")
        execute_process(
          COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/update_dtsi.py
                  --ldscript ${LD_SCRIPT_SRC}
                  --dtsi     ${DTSI_FILE}
          RESULT_VARIABLE _dtsi_rc
          OUTPUT_VARIABLE _dtsi_out
          ERROR_VARIABLE  _dtsi_err
        )
        if(NOT _dtsi_rc EQUAL 0)
          message(WARNING "xtensa_lx: update_dtsi.py failed: ${_dtsi_err}")
        else()
          message(STATUS "${_dtsi_out}")
        endif()
      endif()

    else()
      message(WARNING "xtensa_lx: Source linker script not found: ${LD_SCRIPT_SRC}")
    endif()

  else()
    message(WARNING "xtensa_lx: XTENSA_SYSTEM is not set, skipping toolchain-driven setup")
  endif()

else()
  message(STATUS "xtensa_lx: xt-clang not found in PATH, skipping toolchain-driven setup")
endif()

# ---------------------------------------------------------------------------
set(SOC_LINKER_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/include/xtensa_lx.ld CACHE INTERNAL "")
