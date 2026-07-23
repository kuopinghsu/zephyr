/*
 * Copyright (c) 2024 Cadence Design Systems, Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

/*
 * Compile-time Xtensa LX configuration sanity checks.
 *
 * These checks enforce the hardware prerequisites documented in README.md.
 * All checks use macros from <xtensa/config/core-isa.h>, which is generated
 * by the Xtensa toolchain for the selected XTENSA_CORE.  A build failure here
 * means the chosen core configuration does not meet Zephyr's requirements;
 * see the error message and README.md for remediation steps.
 *
 * Checks performed (in order):
 *
 *  [1] XCHAL_NUM_INTLEVELS >= 2
 *      Zephyr requires at least two distinct interrupt levels.
 *      See https://github.com/zephyrproject-rtos/zephyr/issues/84453
 *
 *  [2] At least one TIMER interrupt at level <= XCHAL_EXCM_LEVEL
 *      Zephyr's system timer driver needs a timer interrupt that can fire
 *      while the kernel masks interrupts up to EXCM_LEVEL.
 *
 *  [3] At least one SOFTWARE interrupt at level <= XCHAL_EXCM_LEVEL
 *      Zephyr uses a SW interrupt for its internal yield/reschedule path;
 *      it must be reachable under normal critical-section masking.
 *
 *  [4] WARNING: SW interrupt(s) exist above XCHAL_EXCM_LEVEL   (non-fatal)
 *      If any SW interrupt is above EXCM_LEVEL, Zephyr may select it for
 *      internal use but then only masks up to EXCM_LEVEL, leaving it
 *      unguarded.  Modify the core config or apply the upstream patch.
 *      See https://github.com/zephyrproject-rtos/zephyr/pull/87483
 *
 *  [5] CONFIG_SMP requires XCHAL_SUBSYS_IPI_S0C0_INTNUM (multi-core IPI)
 *      Single-core configs do not have inter-processor interrupts and cannot
 *      support SMP.
 *
 *  [6] IPI set-0 interrupt must be at level <= XCHAL_EXCM_LEVEL  (SMP only)
 *      The scheduler IPI must be maskable under normal critical sections.
 *
 *  [7] IPI set-0 interrupt must be edge-triggered  (SMP only)
 *      Edge triggering ensures each IPI is a single self-clearing pulse.
 *      A level-triggered IPI would re-assert continuously until cleared.
 */

#include <xtensa/config/core-isa.h>

/* =========================================================================
 * Helper: resolve XCHAL_INTLEVELn_ANDBELOW_MASK for n = XCHAL_EXCM_LEVEL.
 *
 * XCHAL_INTLEVELn_ANDBELOW_MASK is a bitmask where bit k is set when
 * interrupt k has level <= n.  We need the variant for n = XCHAL_EXCM_LEVEL,
 * but the n must be the numeric value (e.g. 3) to form the macro name via
 * token-pasting.
 *
 * The double-indirection (_PASTE3 → _PASTE3_INNER) is the standard C
 * preprocessor idiom that forces expansion of macro arguments before pasting:
 *  - _PASTE3(a, b, c) passes b (= XCHAL_EXCM_LEVEL) to _PASTE3_INNER
 *    as an ordinary argument, so the preprocessor expands it to its value
 *    (e.g. 3) before _PASTE3_INNER's ## operator concatenates the tokens.
 *  - Result: XCHAL_INTLEVEL3_ANDBELOW_MASK  (for XCHAL_EXCM_LEVEL == 3)
 * ========================================================================= */
#define _XCHAL_PASTE3_INNER(a, b, c)  a##b##c
#define _XCHAL_PASTE3(a, b, c)        _XCHAL_PASTE3_INNER(a, b, c)

/*
 * Bitmask of all interrupts at level 1 .. XCHAL_EXCM_LEVEL (inclusive).
 * Expands to, e.g., XCHAL_INTLEVEL3_ANDBELOW_MASK when XCHAL_EXCM_LEVEL == 3.
 */
#define _XCHAL_EXCM_ANDBELOW_MASK \
	_XCHAL_PASTE3(XCHAL_INTLEVEL, XCHAL_EXCM_LEVEL, _ANDBELOW_MASK)

/* =========================================================================
 * Check [1]: At least 2 interrupt levels.
 *
 * XCHAL_NUM_INTLEVELS counts non-NMI interrupt levels in the core.
 * Zephyr's interrupt model separates "maskable" (level <= EXCM_LEVEL) from
 * "critical" (level > EXCM_LEVEL) interrupts; this distinction is only
 * meaningful when there are at least two levels.
 *
 * See https://github.com/zephyrproject-rtos/zephyr/issues/84453
 * ========================================================================= */
#if XCHAL_NUM_INTLEVELS < 2
#error "Xtensa core has fewer than 2 interrupt levels (XCHAL_NUM_INTLEVELS < 2)." \
       " Zephyr requires at least 2 interrupt levels." \
       " See https://github.com/zephyrproject-rtos/zephyr/issues/84453"
#endif

/* =========================================================================
 * Check [2]: At least one TIMER interrupt at level <= XCHAL_EXCM_LEVEL.
 *
 * XCHAL_INTTYPE_MASK_TIMER is the bitmask of all timer-type interrupts.
 * ANDing it with _XCHAL_EXCM_ANDBELOW_MASK selects only timers at or below
 * EXCM_LEVEL.  The result must be non-zero (at least one such timer exists).
 *
 * Example (hifi5s_ao_7, EXCM_LEVEL=3):
 *   XCHAL_INTTYPE_MASK_TIMER        = 0x00002440  (INT6, INT10, INT13)
 *   XCHAL_INTLEVEL3_ANDBELOW_MASK   = 0x003F8FFF
 *   intersection                    = 0x00002440  -> non-zero, check passes
 * ========================================================================= */
#if (XCHAL_INTTYPE_MASK_TIMER & _XCHAL_EXCM_ANDBELOW_MASK) == 0
#error "No timer interrupt is configured at level <= XCHAL_EXCM_LEVEL." \
       " Zephyr's system timer requires at least one timer interrupt" \
       " at or below EXCM_LEVEL."
#endif

/* =========================================================================
 * Check [3]: At least one SOFTWARE interrupt at level <= XCHAL_EXCM_LEVEL.
 *
 * XCHAL_INTTYPE_MASK_SOFTWARE is the bitmask of all software-triggered
 * interrupts.  Zephyr uses a SW interrupt for its internal scheduler IPI
 * (single-core) and yield path; it must be triggerable while normal
 * critical sections mask up to EXCM_LEVEL.
 *
 * Example (hifi5s_ao_7, EXCM_LEVEL=3):
 *   XCHAL_INTTYPE_MASK_SOFTWARE     = 0x00000880  (INT7 @ L1, INT11 @ L3)
 *   XCHAL_INTLEVEL3_ANDBELOW_MASK   = 0x003F8FFF
 *   intersection                    = 0x00000880  -> non-zero, check passes
 * ========================================================================= */
#if (XCHAL_INTTYPE_MASK_SOFTWARE & _XCHAL_EXCM_ANDBELOW_MASK) == 0
#error "No software interrupt is configured at level <= XCHAL_EXCM_LEVEL." \
       " Zephyr requires at least one SW interrupt at or below EXCM_LEVEL."
#endif

/* =========================================================================
 * Check [4]: WARNING — SW interrupt(s) above XCHAL_EXCM_LEVEL.
 *
 * If any SW interrupt has level > EXCM_LEVEL (i.e. its bit is NOT in
 * _XCHAL_EXCM_ANDBELOW_MASK), Zephyr may select that interrupt for internal
 * use but then only masks interrupts up to EXCM_LEVEL during critical
 * processing, leaving the high-level SW interrupt unguarded.  This produces
 * subtle incorrect behaviour.
 *
 * This is a #warning, not a #error, because an upstream patch may already
 * be applied locally.
 *
 * Resolution:
 *   - Reconfigure the core so that all SW interrupts are at level
 *     <= XCHAL_EXCM_LEVEL, OR
 *   - Apply the patch at https://github.com/zephyrproject-rtos/zephyr/pull/87483
 * ========================================================================= */
#if (XCHAL_INTTYPE_MASK_SOFTWARE & ~_XCHAL_EXCM_ANDBELOW_MASK) != 0
#warning "One or more SW interrupts are at level > XCHAL_EXCM_LEVEL." \
         " Zephyr may select such an interrupt for internal use but only" \
         " masks up to EXCM_LEVEL, leaving it unguarded." \
         " Modify the core config or apply:" \
         " https://github.com/zephyrproject-rtos/zephyr/pull/87483"
#endif

/* =========================================================================
 * Checks [5-7] apply only to SMP (multi-core) builds.
 * ========================================================================= */
#if defined(CONFIG_SMP)

/* -------------------------------------------------------------------------
 * Check [5]: Multi-core IPI support must be present.
 *
 * XCHAL_SUBSYS_IPI_S0C0_INTNUM is defined only for multi-core subsystem
 * configurations; single-core configs omit it entirely.  Without IPI,
 * one core cannot signal another and SMP cannot function.
 * ------------------------------------------------------------------------- */
#ifndef XCHAL_SUBSYS_IPI_S0C0_INTNUM
#error "CONFIG_SMP=y requires a multi-core config with IPI support" \
       " (XCHAL_SUBSYS_IPI_S0C0_INTNUM is not defined)." \
       " Use a multi-core XTENSA_CORE or disable CONFIG_SMP."
#endif

/* -------------------------------------------------------------------------
 * Check [6]: IPI set-0 interrupt must be at level <= XCHAL_EXCM_LEVEL.
 *
 * The first IPI set (set 0) is the one Zephyr's scheduler uses.  It must
 * be maskable under normal critical sections (i.e. at level <= EXCM_LEVEL)
 * so that scheduler IPIs are properly deferred when the kernel holds locks.
 *
 * The check shifts 1 into the bit position of the IPI interrupt and tests
 * whether that bit is included in the "at-or-below-EXCM_LEVEL" mask.
 *
 * Example (hifi5s_4c_l2, EXCM_LEVEL=1, IPI=24):
 *   (1u << 24)                       = 0x01000000
 *   XCHAL_INTLEVEL1_ANDBELOW_MASK    = 0xFFFFFFFD
 *   intersection                     = 0x01000000  -> non-zero, check passes
 * ------------------------------------------------------------------------- */
#if ((1u << XCHAL_SUBSYS_IPI_S0C0_INTNUM) & _XCHAL_EXCM_ANDBELOW_MASK) == 0
#error "IPI set-0 interrupt (XCHAL_SUBSYS_IPI_S0C0_INTNUM) is above" \
       " XCHAL_EXCM_LEVEL.  The first IPI set must be at level <=" \
       " EXCM_LEVEL for correct SMP scheduler operation."
#endif

/* -------------------------------------------------------------------------
 * Check [7]: IPI set-0 interrupt must be edge-triggered.
 *
 * XCHAL_INTTYPE_MASK_EXTERN_EDGE is the bitmask of all edge-triggered
 * external interrupts.  IPI interrupts must be edge-triggered: each
 * xthal_ipi_trigger() call generates a single pulse that self-clears.
 * A level-triggered IPI would continuously re-assert until explicitly
 * cleared, causing the handler to re-enter indefinitely.
 *
 * Example (hifi5s_4c_l2, IPI=24):
 *   (1u << 24)                       = 0x01000000
 *   XCHAL_INTTYPE_MASK_EXTERN_EDGE   = 0xFF0007C0
 *   intersection                     = 0x01000000  -> non-zero, check passes
 * ------------------------------------------------------------------------- */
#if ((1u << XCHAL_SUBSYS_IPI_S0C0_INTNUM) & XCHAL_INTTYPE_MASK_EXTERN_EDGE) == 0
#error "IPI set-0 interrupt (XCHAL_SUBSYS_IPI_S0C0_INTNUM) is not" \
       " edge-triggered (not in XCHAL_INTTYPE_MASK_EXTERN_EDGE)." \
       " IPI interrupts must be configured as edge-triggered" \
       " (XTHAL_INTTYPE_EXTERN_EDGE) in the Xtensa subsystem."
#endif

#endif /* CONFIG_SMP */
