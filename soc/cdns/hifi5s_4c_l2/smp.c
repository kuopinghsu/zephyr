/*
 * Copyright (c) 2024 Cadence Design Systems, Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr/device.h>
#include <zephyr/init.h>
#include <zephyr/kernel.h>
#include <zephyr/kernel_structs.h>
#include <zephyr/toolchain.h>
#include <zephyr/sys/__assert.h>
#include <zephyr/sys/sys_io.h>

#include <ksched.h>
#include <ipi.h>

#include <kernel_internal.h>

#include <xtensa/config/core-isa.h>
#include <xtensa/xtsubsystem.h>

#include <zephyr/zsr.h>
#include <zephyr/cache.h>

volatile struct cpustart_rec {
	uint32_t        cpu;
	arch_cpustart_t	fn;
	void            *arg;
} z_mp_start = {0, 0, 0};

/* Simple array of CPUs that are active and available for an IPI. */
bool soc_cpus_active[CONFIG_MP_MAX_NUM_CPUS];

__asm__(".section .text.z_mp_asm_entry, \"x\" \n\t"
	".align 4                   \n\t"
	".global z_mp_asm_entry     \n\t"
	"z_mp_asm_entry:            \n\t"
	"  movi  a0, 0x40023        \n\t" /* WOE | UM | INTLEVEL(XCHAL_EXCM_LEVEL) */
	"  wsr   a0, PS             \n\t"
	"  rsync                    \n\t"
	// Compute and set stack pointer register.
	"  rsr   a2, PRID \n\t"
	"  movi  a1, z_interrupt_stacks \n\t"
	"  movi  a3, CONFIG_ISR_STACK_SIZE \n\t"
	"  mull  a4, a3, a2 \n\t"
	"  add   a4, a4, a3 \n\t"
	"  add   a1, a1, a4 \n\t"
	// Call z_mp_entry().
	"  call4 z_mp_entry \n\t");

static void __used z_mp_entry(void)
{
	int prid = arch_proc_id();
	while (z_mp_start.cpu != prid) {
		// TODO: Wait for interrupt.
	}
	z_mp_start.cpu = 0;

	// Set up the CPU pointer.
	_cpu_t *cpu = &_kernel.cpus[prid];
	__asm__ volatile("wsr %0, " ZSR_CPU_STR :: "r"(cpu));

	#ifdef CONFIG_SCHED_IPI_SUPPORTED
	irq_enable(XCHAL_SUBSYS_IPI_S0C0_INTNUM);
	irq_enable(XCHAL_SUBSYS_IPI_S0C1_INTNUM);
	irq_enable(XCHAL_SUBSYS_IPI_S0C2_INTNUM);
	irq_enable(XCHAL_SUBSYS_IPI_S0C3_INTNUM);
	#endif

	soc_cpus_active[prid] = true;
	z_mp_start.fn(z_mp_start.arg);
	__ASSERT(false, "arch_cpu_start() handler should never return");
}

void __used z_mp_set_core0_active(void)
{
	soc_cpus_active[0] = true;
	xthal_run_cores(XTSUB_RUN_ALL_CORES);
}

bool arch_cpu_active(int cpu_num)
{
	return soc_cpus_active[cpu_num];
}

void arch_cpu_start(int cpu_num, k_thread_stack_t *stack, int sz,
		    arch_cpustart_t fn, void *arg)
{
	__ASSERT_NO_MSG(!soc_cpus_active[cpu_num]);

	// It must be the same stack that will be computed in z_mp_asm_entry().
	__ASSERT_NO_MSG(stack == z_interrupt_stacks[cpu_num]);

	z_mp_start.fn = fn;
	z_mp_start.arg = arg;
	// Must be done last.
	z_mp_start.cpu = cpu_num;
}

static void __attribute__ ((noinline)) ipi_trigger(int c)
{
	// Called from within this noinline function
	// to avoid invalid optimizations.
	xthal_ipi_trigger(c);
}

void arch_sched_directed_ipi(uint32_t cpu_bitmap)
{
	unsigned int num_cpus = arch_num_cpus();
	for (int c = 0; c < num_cpus; ++c) {
		if (soc_cpus_active[c] && (cpu_bitmap & BIT(c)))
			ipi_trigger(c);
	}
}

void arch_sched_broadcast_ipi(void)
{
	arch_sched_directed_ipi(IPI_ALL_CPUS_MASK);
}

static void ipi_isr(const void *param)
{
	ARG_UNUSED(param);
	z_sched_ipi();
}

static int soc_mp_init(void)
{
	#ifdef CONFIG_SCHED_IPI_SUPPORTED
	IRQ_CONNECT(XCHAL_SUBSYS_IPI_S0C0_INTNUM, 0, ipi_isr, NULL, 0);
	IRQ_CONNECT(XCHAL_SUBSYS_IPI_S0C1_INTNUM, 0, ipi_isr, NULL, 0);
	IRQ_CONNECT(XCHAL_SUBSYS_IPI_S0C2_INTNUM, 0, ipi_isr, NULL, 0);
	IRQ_CONNECT(XCHAL_SUBSYS_IPI_S0C3_INTNUM, 0, ipi_isr, NULL, 0);
	irq_enable(XCHAL_SUBSYS_IPI_S0C0_INTNUM);
	irq_enable(XCHAL_SUBSYS_IPI_S0C1_INTNUM);
	irq_enable(XCHAL_SUBSYS_IPI_S0C2_INTNUM);
	irq_enable(XCHAL_SUBSYS_IPI_S0C3_INTNUM);
	#endif
	return 0;
}
SYS_INIT(soc_mp_init, PRE_KERNEL_1, 99);
