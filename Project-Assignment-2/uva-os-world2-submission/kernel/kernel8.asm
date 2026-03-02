
build-rpi3qemu/kernel8.elf:     file format elf64-littleaarch64


Disassembly of section .text.boot:

0000000000080000 <_start>:
.section ".text.boot"

.globl _start
_start:		
	// MMU off, until we set pgtables. cf: sysregs.h
	ldr	x0, =SCTLR_VALUE_MMU_DISABLED  
   80000:	58000440 	ldr	x0, 80088 <setup_sp+0x1c>
	msr	sctlr_el1, x0
   80004:	d5181000 	msr	sctlr_el1, x0
	
	/* -------- Exception level switch -------------- */
	// Check the current exception level: EL3 or EL2?	
	mrs x0, CurrentEL
   80008:	d5384240 	mrs	x0, currentel
  	lsr x0, x0, #2
   8000c:	d342fc00 	lsr	x0, x0, #2
	cmp x0, #3
   80010:	f1000c1f 	cmp	x0, #0x3
	beq el3
   80014:	54000120 	b.eq	80038 <el3>  // b.none

	# Current EL: EL2 
	# set EL1 to be running in AArch64
	mrs	x0, hcr_el2
   80018:	d53c1100 	mrs	x0, hcr_el2
	orr	x0, x0, #HCR_RW  
   8001c:	b2610000 	orr	x0, x0, #0x80000000
	msr	hcr_el2, x0
   80020:	d51c1100 	msr	hcr_el2, x0

	# prepare to switch to EL1
	mov x0, #SPSR_VALUE
   80024:	d28038a0 	mov	x0, #0x1c5                 	// #453
	msr	spsr_el2, x0
   80028:	d51c4000 	msr	spsr_el2, x0

	adr	x0, el1_entry
   8002c:	10000180 	adr	x0, 8005c <el1_entry>
	msr	elr_el2, x0
   80030:	d51c4020 	msr	elr_el2, x0
	eret	// switch to EL1
   80034:	d69f03e0 	eret

0000000000080038 <el3>:

el3: 		// Current EL: EL3
	// 	With the rpi3 firmware (armstub) or qemu, kernel always starts in EL2; 
	//  We leave EL3 code here for completeness
  	ldr x0, =HCR_VALUE
   80038:	580002c0 	ldr	x0, 80090 <setup_sp+0x24>
  	msr hcr_el2, x0
   8003c:	d51c1100 	msr	hcr_el2, x0

	ldr	x0, =SCR_VALUE
   80040:	580002c0 	ldr	x0, 80098 <setup_sp+0x2c>
	msr	scr_el3, x0
   80044:	d51e1100 	msr	scr_el3, x0

	# prepare to switch to EL1
	ldr	x0, =SPSR_VALUE
   80048:	580002c0 	ldr	x0, 800a0 <setup_sp+0x34>
	msr	spsr_el3, x0
   8004c:	d51e4000 	msr	spsr_el3, x0

	adr	x0, el1_entry		
   80050:	10000060 	adr	x0, 8005c <el1_entry>
	msr	elr_el3, x0	
   80054:	d51e4020 	msr	elr_el3, x0
	eret	// switch to EL1				
   80058:	d69f03e0 	eret

000000000008005c <el1_entry>:
	/* ------- Start of EL1 execution ------- */
el1_entry:	
	// Clean up bss region. 
	// bss_begin/end are linking addr (kernel virt). convert them to phys.
	// they are (at least) 8 bytes aligned in link script
	ldr	x0, =bss_begin
   8005c:	58000260 	ldr	x0, 800a8 <setup_sp+0x3c>
	ldr	x1, =bss_end
   80060:	58000281 	ldr	x1, 800b0 <setup_sp+0x44>
	sub	x1, x1, x0
   80064:	cb000021 	sub	x1, x1, x0
	bl 	memzero_aligned
   80068:	940017bb 	bl	85f54 <memzero_aligned>

000000000008006c <setup_sp>:
	
setup_sp: 	
	ldr x1, =boot_stacks	// sched.c		
   8006c:	58000261 	ldr	x1, 800b8 <setup_sp+0x4c>
	ldr x0, =0x1000
   80070:	58000280 	ldr	x0, 800c0 <setup_sp+0x54>
	add x1, x1, x0		// point to the end of cpu0's bootstack
   80074:	8b000021 	add	x1, x1, x0
	mov sp, x1			// set sp to the end of cpu0's bootstack
   80078:	9100003f 	mov	sp, x1
	// NB: we aren't use sp yet -- until we call a C function for the 1st time

	// install irq vectors
	ldr x0, =vectors	// load VBAR_EL1 vector table addr
   8007c:	58000260 	ldr	x0, 800c8 <setup_sp+0x5c>
	msr	vbar_el1, x0	
   80080:	d518c000 	msr	vbar_el1, x0

	// load the addr of kernel_main
   80084:	9400024f 	bl	809c0 <kernel_main>
   80088:	30d00800 	.word	0x30d00800
   8008c:	00000000 	.word	0x00000000
   80090:	80000000 	.word	0x80000000
   80094:	00000000 	.word	0x00000000
   80098:	00000431 	.word	0x00000431
   8009c:	00000000 	.word	0x00000000
   800a0:	000001c5 	.word	0x000001c5
   800a4:	00000000 	.word	0x00000000
   800a8:	00095f68 	.word	0x00095f68
   800ac:	00000000 	.word	0x00000000
   800b0:	0010e110 	.word	0x0010e110
   800b4:	00000000 	.word	0x00000000
   800b8:	0010d000 	.word	0x0010d000
   800bc:	00000000 	.word	0x00000000
   800c0:	00001000 	.word	0x00001000
   800c4:	00000000 	.word	0x00000000
   800c8:	00085000 	.word	0x00085000
   800cc:	00000000 	.word	0x00000000

Disassembly of section .text:

0000000000080800 <enable_interrupt_controller>:
#if defined(PLAT_RPI3) || defined(PLAT_RPI3QEMU)
    // On RPi3, Arm Generic timer IRQs are wired to a per-core interrupt controller/register. 
    // For core 0, this is `TIMER_INT_CTRL_0` at 0x40000040; bit 1 is for physical timer at EL1 (CNTP). This register is documented 
    // in the [manual](https://www.raspberrypi.org/documentation/hardware/raspberrypi/bcm2836/QA7_rev3.4.pdf) of BCM2836 
    // (search for "Core timers interrupts"). Note the manual is NOT for the BCM2837 SoC used by Rpi3    
    put32(TIMER_INT_CTRL_0 + 4*coreid, TIMER_INT_CTRL_0_VALUE);
   80800:	531e7402 	lsl	w2, w0, #2
   80804:	d2800801 	mov	x1, #0x40                  	// #64
   80808:	f2a80001 	movk	x1, #0x4000, lsl #16
   8080c:	52800043 	mov	w3, #0x2                   	// #2
   80810:	b822c823 	str	w3, [x1, w2, sxtw]

    if (coreid==0)
   80814:	350000c0 	cbnz	w0, 8082c <enable_interrupt_controller+0x2c>
        put32(ENABLE_IRQS_1, 
   80818:	d2964200 	mov	x0, #0xb210                	// #45584
   8081c:	52804041 	mov	w1, #0x202                 	// #514
   80820:	f2a7e000 	movk	x0, #0x3f00, lsl #16
   80824:	72a60001 	movk	w1, #0x3000, lsl #16
   80828:	b9000001 	str	w1, [x0]
    //     arm_gic_umask(0, i);
    // gic_dump(); // debugging 
#else   
    #error "unimplemented"    
#endif
}
   8082c:	d65f03c0 	ret

0000000000080830 <handle_irq>:

    The old PSTATE, which includes DAIF, is saved to SPSR, and will be 
    restored by eret (kernel_exit)
*/
#if defined(PLAT_RPI3) || defined(PLAT_RPI3QEMU)
void handle_irq(void) {
   80830:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   80834:	910003fd 	mov	x29, sp
   80838:	a90153f3 	stp	x19, x20, [sp, #16]
    `INT_SOURCE_0` register that holds interrupt status for interrupts 
    `0 - 31`. Using this register we can check whether the current 
    interrupt was generated by the timer or by some other device and 
    call device specific interrupt handler.
    NB: Each Core has its own pending local interrupt register. */
    int coreid = cpuid();
   8083c:	940015b3 	bl	85f08 <cpuid>
    unsigned int irq = get32(INT_SOURCE_0 + 4*coreid), irq0 = irq; 
   80840:	d2800c01 	mov	x1, #0x60                  	// #96
   80844:	531e7400 	lsl	w0, w0, #2
   80848:	f2a80001 	movk	x1, #0x4000, lsl #16
   8084c:	b860c834 	ldr	w20, [x1, w0, sxtw]

    if (irq & GENERIC_TIMER_INTERRUPT) {
   80850:	2a1403f3 	mov	w19, w20
   80854:	37080474 	tbnz	w20, #1, 808e0 <handle_irq+0xb0>
        handle_generic_timer_irq();
        irq &= (~GENERIC_TIMER_INTERRUPT);
    } 
    
    if (irq & GPU_SIDE_INTERRUPT) {
   80858:	36400133 	tbz	w19, #8, 8087c <handle_irq+0x4c>
        unsigned int p1 = get32(IRQ_PENDING_1);
   8085c:	d2964080 	mov	x0, #0xb204                	// #45572
   80860:	f90013f5 	str	x21, [sp, #32]
   80864:	f2a7e000 	movk	x0, #0x3f00, lsl #16
   80868:	b9400015 	ldr	w21, [x0]
        if (p1 & SYSTEM_TIMER_IRQ_1) {
   8086c:	37080475 	tbnz	w21, #1, 808f8 <handle_irq+0xc8>
        }
        if (p1) {
            E("unknown pending irq in IRQ_PENDING_1 p1 %08x", p1); 
            goto unknown; 
        }          
        irq &= (~GPU_SIDE_INTERRUPT);  // clear all "GPU side" irqs
   80870:	12177a73 	and	w19, w19, #0xfffffeff
        if (p1) {
   80874:	350004b5 	cbnz	w21, 80908 <handle_irq+0xd8>
   80878:	f94013f5 	ldr	x21, [sp, #32]
    } 

    if (!irq) 
   8087c:	34000393 	cbz	w19, 808ec <handle_irq+0xbc>
   80880:	d0000033 	adrp	x19, 86000 <__asm_dcache_level+0xc>
        return;  // all irq bits cleared

unknown:
    E("Unknown pending irq: INT_SOURCE_0 %08x IRQ_BASIC_PENDING %08x " 
   80884:	d2964002 	mov	x2, #0xb200                	// #45568
   80888:	d2964081 	mov	x1, #0xb204                	// #45572
   8088c:	d2964100 	mov	x0, #0xb208                	// #45576
   80890:	f2a7e002 	movk	x2, #0x3f00, lsl #16
   80894:	f2a7e001 	movk	x1, #0x3f00, lsl #16
   80898:	f2a7e000 	movk	x0, #0x3f00, lsl #16
   8089c:	b9400044 	ldr	w4, [x2]
   808a0:	910a8273 	add	x19, x19, #0x2a0
   808a4:	b9400025 	ldr	w5, [x1]
   808a8:	2a1403e3 	mov	w3, w20
   808ac:	b9400006 	ldr	w6, [x0]
   808b0:	aa1303e1 	mov	x1, x19
   808b4:	52800d02 	mov	w2, #0x68                  	// #104
   808b8:	d0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   808bc:	910ba000 	add	x0, x0, #0x2e8
   808c0:	9400033e 	bl	815b8 <tfp_printf>
        irq0, 
        get32(IRQ_BASIC_PENDING), 
        get32(IRQ_PENDING_1),
        get32(IRQ_PENDING_2)
        );
    BUG(); 
   808c4:	aa1303e1 	mov	x1, x19
   808c8:	d0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
}
   808cc:	a94153f3 	ldp	x19, x20, [sp, #16]
    BUG(); 
   808d0:	910d8000 	add	x0, x0, #0x360
}
   808d4:	a8c37bfd 	ldp	x29, x30, [sp], #48
    BUG(); 
   808d8:	52800de2 	mov	w2, #0x6f                  	// #111
   808dc:	14000407 	b	818f8 <assertion_failed>
        irq &= (~GENERIC_TIMER_INTERRUPT);
   808e0:	121e7a93 	and	w19, w20, #0xfffffffd
        handle_generic_timer_irq();
   808e4:	94000571 	bl	81ea8 <handle_generic_timer_irq>
        irq &= (~GENERIC_TIMER_INTERRUPT);
   808e8:	17ffffdc 	b	80858 <handle_irq+0x28>
}
   808ec:	a94153f3 	ldp	x19, x20, [sp, #16]
   808f0:	a8c37bfd 	ldp	x29, x30, [sp], #48
   808f4:	d65f03c0 	ret
            p1 &= (~SYSTEM_TIMER_IRQ_1);
   808f8:	121e7ab5 	and	w21, w21, #0xfffffffd
        irq &= (~GPU_SIDE_INTERRUPT);  // clear all "GPU side" irqs
   808fc:	12177a73 	and	w19, w19, #0xfffffeff
            sys_timer_irq(); 
   80900:	94000614 	bl	82150 <sys_timer_irq>
        if (p1) {
   80904:	34fffbb5 	cbz	w21, 80878 <handle_irq+0x48>
            E("unknown pending irq in IRQ_PENDING_1 p1 %08x", p1); 
   80908:	2a1503e3 	mov	w3, w21
   8090c:	d0000033 	adrp	x19, 86000 <__asm_dcache_level+0xc>
   80910:	d0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   80914:	910a8261 	add	x1, x19, #0x2a0
   80918:	910aa000 	add	x0, x0, #0x2a8
   8091c:	52800bc2 	mov	w2, #0x5e                  	// #94
   80920:	94000326 	bl	815b8 <tfp_printf>
            goto unknown; 
   80924:	f94013f5 	ldr	x21, [sp, #32]
   80928:	17ffffd7 	b	80884 <handle_irq+0x54>
   8092c:	d503201f 	nop

0000000000080930 <show_invalid_entry_message>:
#endif

// esr: syndrome, elr: ~faulty pc, far: faulty access addr
void show_invalid_entry_message(int type, unsigned long esr, 
    unsigned long elr, unsigned long far)
{    
   80930:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
    E("%s, cpu%d, esr: 0x%016lx, elr: 0x%016lx, far: 0x%016lx",  
   80934:	b00000a4 	adrp	x4, 95000 <wordsworth.1725+0xee10>
   80938:	91372084 	add	x4, x4, #0xdc8
{    
   8093c:	910003fd 	mov	x29, sp
   80940:	f9001bf7 	str	x23, [sp, #48]
    E("%s, cpu%d, esr: 0x%016lx, elr: 0x%016lx, far: 0x%016lx",  
   80944:	f860d897 	ldr	x23, [x4, w0, sxtw #3]
{    
   80948:	a90153f3 	stp	x19, x20, [sp, #16]
   8094c:	aa0103f4 	mov	x20, x1
    E("%s, cpu%d, esr: 0x%016lx, elr: 0x%016lx, far: 0x%016lx",  
   80950:	d0000033 	adrp	x19, 86000 <__asm_dcache_level+0xc>
   80954:	910a8273 	add	x19, x19, #0x2a0
{    
   80958:	a9025bf5 	stp	x21, x22, [sp, #32]
   8095c:	aa0203f5 	mov	x21, x2
   80960:	aa0303f6 	mov	x22, x3
    E("%s, cpu%d, esr: 0x%016lx, elr: 0x%016lx, far: 0x%016lx",  
   80964:	94001569 	bl	85f08 <cpuid>
   80968:	2a0003e4 	mov	w4, w0
   8096c:	aa1703e3 	mov	x3, x23
   80970:	aa1603e7 	mov	x7, x22
   80974:	aa1503e6 	mov	x6, x21
   80978:	aa1403e5 	mov	x5, x20
   8097c:	aa1303e1 	mov	x1, x19
   80980:	52800ee2 	mov	w2, #0x77                  	// #119
   80984:	d0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   80988:	910da000 	add	x0, x0, #0x368
   8098c:	9400030b 	bl	815b8 <tfp_printf>
        entry_error_messages[type], cpuid(), esr, elr, far);
    E("online esr decoder: %s0x%016lx", "https://esr.arm64.dev/#", esr);
   80990:	aa1403e4 	mov	x4, x20
   80994:	aa1303e1 	mov	x1, x19
}
   80998:	a94153f3 	ldp	x19, x20, [sp, #16]
    E("online esr decoder: %s0x%016lx", "https://esr.arm64.dev/#", esr);
   8099c:	d0000023 	adrp	x3, 86000 <__asm_dcache_level+0xc>
}
   809a0:	a9425bf5 	ldp	x21, x22, [sp, #32]
    E("online esr decoder: %s0x%016lx", "https://esr.arm64.dev/#", esr);
   809a4:	910ee063 	add	x3, x3, #0x3b8
}
   809a8:	f9401bf7 	ldr	x23, [sp, #48]
    E("online esr decoder: %s0x%016lx", "https://esr.arm64.dev/#", esr);
   809ac:	d0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
}
   809b0:	a8c47bfd 	ldp	x29, x30, [sp], #64
    E("online esr decoder: %s0x%016lx", "https://esr.arm64.dev/#", esr);
   809b4:	910f4000 	add	x0, x0, #0x3d0
   809b8:	52800f22 	mov	w2, #0x79                  	// #121
   809bc:	140002ff 	b	815b8 <tfp_printf>

00000000000809c0 <kernel_main>:
extern void donut(int x, int y); 	//donut.c

struct cpu cpus[NCPU]; 

// Q3: quest "two preemptive printers"
void kernel_main() {
   809c0:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   809c4:	910003fd 	mov	x29, sp
	uart_init();
   809c8:	94001134 	bl	84e98 <uart_init>
	init_printf(NULL, putc);	
   809cc:	b00000a1 	adrp	x1, 95000 <wordsworth.1725+0xee10>
   809d0:	d2800000 	mov	x0, #0x0                   	// #0
   809d4:	f9478821 	ldr	x1, [x1, #3856]
   809d8:	940002f2 	bl	815a0 <init_printf>
	printf("------ kernel boot ------  core %d\n\r", cpuid());
   809dc:	9400154b 	bl	85f08 <cpuid>
   809e0:	2a0003e1 	mov	w1, w0
   809e4:	d0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   809e8:	91150000 	add	x0, x0, #0x540
   809ec:	940002f3 	bl	815b8 <tfp_printf>
	printf("build time (kernel.c) %s %s\n", __DATE__, __TIME__); // simplicity 
   809f0:	d0000022 	adrp	x2, 86000 <__asm_dcache_level+0xc>
   809f4:	d0000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   809f8:	9115a042 	add	x2, x2, #0x568
   809fc:	9115e021 	add	x1, x1, #0x578
   80a00:	d0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   80a04:	91162000 	add	x0, x0, #0x588
   80a08:	940002ec 	bl	815b8 <tfp_printf>
			
	paging_init(); 
   80a0c:	94000af1 	bl	835d0 <paging_init>
	sched_init(); 	// must be before schedule() or timertick() 
   80a10:	94000b78 	bl	837f0 <sched_init>
	fb_init(); 		// reserve fb memory other page allocations
   80a14:	940007e1 	bl	82998 <fb_init>
	sys_timer_init(); 		// kernel timer: delay, timekeeping...
   80a18:	9400054c 	bl	81f48 <sys_timer_init>
	enable_interrupt_controller(0/*coreid*/);
   80a1c:	52800000 	mov	w0, #0x0                   	// #0
   80a20:	97ffff78 	bl	80800 <enable_interrupt_controller>
	/* turn on cpu irq  */
	/* STUDENT: TODO: your code here */
	// asm volatile("msr daifclr, #2");
	enable_irq();
   80a24:	94001531 	bl	85ee8 <enable_irq>
	/* sched ticks alive. preemptive scheduler is on */
	/* STUDENT: TODO: your code here */
	generic_timer_init();
   80a28:	9400051a 	bl	81e90 <generic_timer_init>
	
	
	/* now cpu is on its boot stack (boot.S) belonging to the idle task. 
	schedule() will jump off to kernel stacks belonging to normal tasks
	(i.e. init_task as set up in sched_init(), sched.c) */
	schedule(); 
   80a2c:	94000bed 	bl	839e0 <schedule>
	the cpu switches back to the boot stack and returns here */
    while (1) {
        /* don't call schedule(), otherwise each irq calls schedule(): too much
        instead, let timer_tick() throttle & decide when to call schedule() */
        V("idle task");
        asm volatile("wfi");
   80a30:	d503207f 	wfi
   80a34:	d503207f 	wfi
    while (1) {
   80a38:	17fffffe 	b	80a30 <kernel_main+0x70>
   80a3c:	d503201f 	nop

0000000000080a40 <init>:
    }
}

/* the 1st task (other than "idle"), created by sched_init()
as the launchpad of various kernel tests, etc.  */
void init(int arg/*ignored*/) {
   80a40:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
	int wpid; 
    W("entering init");
   80a44:	528007a2 	mov	w2, #0x3d                  	// #61
   80a48:	d0000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
void init(int arg/*ignored*/) {
   80a4c:	910003fd 	mov	x29, sp
    W("entering init");
   80a50:	9116a021 	add	x1, x1, #0x5a8
   80a54:	d0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   80a58:	9116e000 	add	x0, x0, #0x5b8
   80a5c:	940002d7 	bl	815b8 <tfp_printf>

	printf("Init is running\n");
   80a60:	d0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   80a64:	91178000 	add	x0, x0, #0x5e0
   80a68:	940002d4 	bl	815b8 <tfp_printf>
	/* STUDENT: TODO: your code here */
	//test_kern_tasks_donut();
	// Q4: quest: "two donuts"
	/* STUDENT: TODO: your code here */
	// test_kern_task_mgmt();
	test_kern_reader_writer(); 
   80a6c:	9400108f 	bl	84ca8 <test_kern_reader_writer>
	while (1) {
    yield();
   80a70:	94000c50 	bl	83bb0 <yield>
   80a74:	94000c4f 	bl	83bb0 <yield>
	while (1) {
   80a78:	17fffffe 	b	80a70 <init+0x30>
   80a7c:	00000000 	udf	#0

0000000000080a80 <ulli2a>:
    unsigned long long int num, struct param *p)
{
    int n = 0;
    unsigned long long int d = 1;
    char *bf = p->bf;
    while (num / d >= p->base)
   80a80:	b9400c26 	ldr	w6, [x1, #12]
    char *bf = p->bf;
   80a84:	f9400829 	ldr	x9, [x1, #16]
    while (num / d >= p->base)
   80a88:	2a0603e4 	mov	w4, w6
   80a8c:	eb26401f 	cmp	x0, w6, uxtw
   80a90:	54000583 	b.cc	80b40 <ulli2a+0xc0>  // b.lo, b.ul, b.last
    unsigned long long int d = 1;
   80a94:	d2800022 	mov	x2, #0x1                   	// #1
        d *= p->base;
   80a98:	9b047c42 	mul	x2, x2, x4
    while (num / d >= p->base)
   80a9c:	9ac20803 	udiv	x3, x0, x2
   80aa0:	eb04007f 	cmp	x3, x4
   80aa4:	54ffffa2 	b.cs	80a98 <ulli2a+0x18>  // b.hs, b.nlast
    while (d != 0) {
   80aa8:	b4000462 	cbz	x2, 80b34 <ulli2a+0xb4>
    int n = 0;
   80aac:	52800007 	mov	w7, #0x0                   	// #0
        int dgt = num / d;
        num %= d;
        d /= p->base;
        if (n || dgt > 0 || d == 0) {
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80ab0:	528006eb 	mov	w11, #0x37                  	// #55
   80ab4:	52800aea 	mov	w10, #0x57                  	// #87
        if (n || dgt > 0 || d == 0) {
   80ab8:	710000ff 	cmp	w7, #0x0
        num %= d;
   80abc:	9b028060 	msub	x0, x3, x2, x0
        d /= p->base;
   80ac0:	9ac40848 	udiv	x8, x2, x4
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80ac4:	aa0903e5 	mov	x5, x9
        if (n || dgt > 0 || d == 0) {
   80ac8:	7a400860 	ccmp	w3, #0x0, #0x0, eq	// eq = none
   80acc:	540000ec 	b.gt	80ae8 <ulli2a+0x68>
   80ad0:	eb02009f 	cmp	x4, x2
   80ad4:	540002c9 	b.ls	80b2c <ulli2a+0xac>  // b.plast
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80ad8:	1100c063 	add	w3, w3, #0x30
   80adc:	380014a3 	strb	w3, [x5], #1
            ++n;
        }
    }
    *bf = 0;
   80ae0:	390000bf 	strb	wzr, [x5]
}
   80ae4:	d65f03c0 	ret
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80ae8:	7100247f 	cmp	w3, #0x9
   80aec:	52800606 	mov	w6, #0x30                  	// #48
   80af0:	5400008d 	b.le	80b00 <ulli2a+0x80>
   80af4:	39400026 	ldrb	w6, [x1]
   80af8:	f27e00df 	tst	x6, #0x4
   80afc:	1a8a1166 	csel	w6, w11, w10, ne	// ne = any
   80b00:	0b0300c3 	add	w3, w6, w3
   80b04:	380014a3 	strb	w3, [x5], #1
            ++n;
   80b08:	110004e7 	add	w7, w7, #0x1
    while (d != 0) {
   80b0c:	eb02009f 	cmp	x4, x2
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80b10:	aa0503e9 	mov	x9, x5
    while (d != 0) {
   80b14:	54fffe68 	b.hi	80ae0 <ulli2a+0x60>  // b.pmore
   80b18:	b9400c26 	ldr	w6, [x1, #12]
   80b1c:	9ac80803 	udiv	x3, x0, x8
   80b20:	2a0603e4 	mov	w4, w6
    int n = 0;
   80b24:	aa0803e2 	mov	x2, x8
   80b28:	17ffffe4 	b	80ab8 <ulli2a+0x38>
   80b2c:	52800007 	mov	w7, #0x0                   	// #0
   80b30:	17fffffb 	b	80b1c <ulli2a+0x9c>
    char *bf = p->bf;
   80b34:	aa0903e5 	mov	x5, x9
    *bf = 0;
   80b38:	390000bf 	strb	wzr, [x5]
}
   80b3c:	d65f03c0 	ret
   80b40:	aa0003e3 	mov	x3, x0
    unsigned long long int d = 1;
   80b44:	d2800022 	mov	x2, #0x1                   	// #1
   80b48:	17ffffd9 	b	80aac <ulli2a+0x2c>
   80b4c:	d503201f 	nop

0000000000080b50 <uli2a>:
static void uli2a(unsigned long int num, struct param *p)
{
    int n = 0;
    unsigned long int d = 1;
    char *bf = p->bf;
    while (num / d >= p->base)
   80b50:	b9400c26 	ldr	w6, [x1, #12]
    char *bf = p->bf;
   80b54:	f9400829 	ldr	x9, [x1, #16]
    while (num / d >= p->base)
   80b58:	2a0603e4 	mov	w4, w6
   80b5c:	eb26401f 	cmp	x0, w6, uxtw
   80b60:	54000583 	b.cc	80c10 <uli2a+0xc0>  // b.lo, b.ul, b.last
    unsigned long int d = 1;
   80b64:	d2800022 	mov	x2, #0x1                   	// #1
        d *= p->base;
   80b68:	9b047c42 	mul	x2, x2, x4
    while (num / d >= p->base)
   80b6c:	9ac20803 	udiv	x3, x0, x2
   80b70:	eb04007f 	cmp	x3, x4
   80b74:	54ffffa2 	b.cs	80b68 <uli2a+0x18>  // b.hs, b.nlast
    while (d != 0) {
   80b78:	b4000462 	cbz	x2, 80c04 <uli2a+0xb4>
    int n = 0;
   80b7c:	52800007 	mov	w7, #0x0                   	// #0
        int dgt = num / d;
        num %= d;
        d /= p->base;
        if (n || dgt > 0 || d == 0) {
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80b80:	528006eb 	mov	w11, #0x37                  	// #55
   80b84:	52800aea 	mov	w10, #0x57                  	// #87
        if (n || dgt > 0 || d == 0) {
   80b88:	710000ff 	cmp	w7, #0x0
        num %= d;
   80b8c:	9b028060 	msub	x0, x3, x2, x0
        d /= p->base;
   80b90:	9ac40848 	udiv	x8, x2, x4
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80b94:	aa0903e5 	mov	x5, x9
        if (n || dgt > 0 || d == 0) {
   80b98:	7a400860 	ccmp	w3, #0x0, #0x0, eq	// eq = none
   80b9c:	540000ec 	b.gt	80bb8 <uli2a+0x68>
   80ba0:	eb02009f 	cmp	x4, x2
   80ba4:	540002c9 	b.ls	80bfc <uli2a+0xac>  // b.plast
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80ba8:	1100c063 	add	w3, w3, #0x30
   80bac:	380014a3 	strb	w3, [x5], #1
            ++n;
        }
    }
    *bf = 0;
   80bb0:	390000bf 	strb	wzr, [x5]
}
   80bb4:	d65f03c0 	ret
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80bb8:	7100247f 	cmp	w3, #0x9
   80bbc:	52800606 	mov	w6, #0x30                  	// #48
   80bc0:	5400008d 	b.le	80bd0 <uli2a+0x80>
   80bc4:	39400026 	ldrb	w6, [x1]
   80bc8:	f27e00df 	tst	x6, #0x4
   80bcc:	1a8a1166 	csel	w6, w11, w10, ne	// ne = any
   80bd0:	0b0300c3 	add	w3, w6, w3
   80bd4:	380014a3 	strb	w3, [x5], #1
            ++n;
   80bd8:	110004e7 	add	w7, w7, #0x1
    while (d != 0) {
   80bdc:	eb02009f 	cmp	x4, x2
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80be0:	aa0503e9 	mov	x9, x5
    while (d != 0) {
   80be4:	54fffe68 	b.hi	80bb0 <uli2a+0x60>  // b.pmore
   80be8:	b9400c26 	ldr	w6, [x1, #12]
   80bec:	9ac80803 	udiv	x3, x0, x8
   80bf0:	2a0603e4 	mov	w4, w6
    int n = 0;
   80bf4:	aa0803e2 	mov	x2, x8
   80bf8:	17ffffe4 	b	80b88 <uli2a+0x38>
   80bfc:	52800007 	mov	w7, #0x0                   	// #0
   80c00:	17fffffb 	b	80bec <uli2a+0x9c>
    char *bf = p->bf;
   80c04:	aa0903e5 	mov	x5, x9
    *bf = 0;
   80c08:	390000bf 	strb	wzr, [x5]
}
   80c0c:	d65f03c0 	ret
   80c10:	aa0003e3 	mov	x3, x0
    unsigned long int d = 1;
   80c14:	d2800022 	mov	x2, #0x1                   	// #1
   80c18:	17ffffd9 	b	80b7c <uli2a+0x2c>
   80c1c:	d503201f 	nop

0000000000080c20 <ui2a>:
static void ui2a(unsigned int num, struct param *p)
{
    int n = 0;
    unsigned int d = 1;
    char *bf = p->bf;
    while (num / d >= p->base)
   80c20:	b9400c24 	ldr	w4, [x1, #12]
    char *bf = p->bf;
   80c24:	f9400826 	ldr	x6, [x1, #16]
    while (num / d >= p->base)
   80c28:	6b04001f 	cmp	w0, w4
   80c2c:	54000583 	b.cc	80cdc <ui2a+0xbc>  // b.lo, b.ul, b.last
    unsigned int d = 1;
   80c30:	52800022 	mov	w2, #0x1                   	// #1
   80c34:	d503201f 	nop
        d *= p->base;
   80c38:	1b047c42 	mul	w2, w2, w4
    while (num / d >= p->base)
   80c3c:	1ac20803 	udiv	w3, w0, w2
   80c40:	6b04007f 	cmp	w3, w4
   80c44:	54ffffa2 	b.cs	80c38 <ui2a+0x18>  // b.hs, b.nlast
    while (d != 0) {
   80c48:	34000442 	cbz	w2, 80cd0 <ui2a+0xb0>
    int n = 0;
   80c4c:	52800007 	mov	w7, #0x0                   	// #0
        int dgt = num / d;
        num %= d;
        d /= p->base;
        if (n || dgt > 0 || d == 0) {
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80c50:	528006ea 	mov	w10, #0x37                  	// #55
   80c54:	52800ae9 	mov	w9, #0x57                  	// #87
        if (n || dgt > 0 || d == 0) {
   80c58:	710000ff 	cmp	w7, #0x0
        num %= d;
   80c5c:	1b028060 	msub	w0, w3, w2, w0
        d /= p->base;
   80c60:	1ac40848 	udiv	w8, w2, w4
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80c64:	aa0603e5 	mov	x5, x6
        if (n || dgt > 0 || d == 0) {
   80c68:	7a400860 	ccmp	w3, #0x0, #0x0, eq	// eq = none
   80c6c:	540000ec 	b.gt	80c88 <ui2a+0x68>
   80c70:	6b04005f 	cmp	w2, w4
   80c74:	540002a2 	b.cs	80cc8 <ui2a+0xa8>  // b.hs, b.nlast
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80c78:	1100c063 	add	w3, w3, #0x30
   80c7c:	380014a3 	strb	w3, [x5], #1
            ++n;
        }
    }
    *bf = 0;
   80c80:	390000bf 	strb	wzr, [x5]
}
   80c84:	d65f03c0 	ret
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80c88:	7100247f 	cmp	w3, #0x9
   80c8c:	52800606 	mov	w6, #0x30                  	// #48
   80c90:	5400008d 	b.le	80ca0 <ui2a+0x80>
   80c94:	39400026 	ldrb	w6, [x1]
   80c98:	f27e00df 	tst	x6, #0x4
   80c9c:	1a891146 	csel	w6, w10, w9, ne	// ne = any
   80ca0:	0b0300c3 	add	w3, w6, w3
   80ca4:	380014a3 	strb	w3, [x5], #1
            ++n;
   80ca8:	110004e7 	add	w7, w7, #0x1
    while (d != 0) {
   80cac:	6b04005f 	cmp	w2, w4
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80cb0:	aa0503e6 	mov	x6, x5
    while (d != 0) {
   80cb4:	54fffe63 	b.cc	80c80 <ui2a+0x60>  // b.lo, b.ul, b.last
   80cb8:	b9400c24 	ldr	w4, [x1, #12]
   80cbc:	1ac80803 	udiv	w3, w0, w8
    int n = 0;
   80cc0:	2a0803e2 	mov	w2, w8
   80cc4:	17ffffe5 	b	80c58 <ui2a+0x38>
   80cc8:	52800007 	mov	w7, #0x0                   	// #0
   80ccc:	17fffffc 	b	80cbc <ui2a+0x9c>
    char *bf = p->bf;
   80cd0:	aa0603e5 	mov	x5, x6
    *bf = 0;
   80cd4:	390000bf 	strb	wzr, [x5]
}
   80cd8:	d65f03c0 	ret
   80cdc:	2a0003e3 	mov	w3, w0
    unsigned int d = 1;
   80ce0:	52800022 	mov	w2, #0x1                   	// #1
   80ce4:	17ffffda 	b	80c4c <ui2a+0x2c>

0000000000080ce8 <putchw>:
    *nump = num;
    return ch;
}

static void putchw(void *putp, putcf putf, struct param *p)
{
   80ce8:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
   80cec:	910003fd 	mov	x29, sp
   80cf0:	a90153f3 	stp	x19, x20, [sp, #16]
   80cf4:	aa0003f4 	mov	x20, x0
    char ch;
    int n = p->width;
   80cf8:	b9400453 	ldr	w19, [x2, #4]
    char *bf = p->bf;

    /* Number of filling characters */
    while (*bf++ && n > 0)
   80cfc:	f9400840 	ldr	x0, [x2, #16]
{
   80d00:	a9025bf5 	stp	x21, x22, [sp, #32]
   80d04:	aa0103f5 	mov	x21, x1
   80d08:	f9001bf7 	str	x23, [sp, #48]
   80d0c:	aa0203f7 	mov	x23, x2
    while (*bf++ && n > 0)
   80d10:	38401401 	ldrb	w1, [x0], #1
   80d14:	7100003f 	cmp	w1, #0x0
   80d18:	7a401a64 	ccmp	w19, #0x0, #0x4, ne	// ne = any
   80d1c:	540000cd 	b.le	80d34 <putchw+0x4c>
   80d20:	38401401 	ldrb	w1, [x0], #1
        n--;
   80d24:	51000673 	sub	w19, w19, #0x1
    while (*bf++ && n > 0)
   80d28:	7100003f 	cmp	w1, #0x0
   80d2c:	7a401a64 	ccmp	w19, #0x0, #0x4, ne	// ne = any
   80d30:	54ffff8c 	b.gt	80d20 <putchw+0x38>
    if (p->sign)
   80d34:	394022e1 	ldrb	w1, [x23, #8]
        n--;
    if (p->alt && p->base == 16)
   80d38:	394002e0 	ldrb	w0, [x23]
        n--;
   80d3c:	7100003f 	cmp	w1, #0x0
   80d40:	1a9f07e2 	cset	w2, ne	// ne = any
   80d44:	4b020273 	sub	w19, w19, w2
    if (p->alt && p->base == 16)
   80d48:	360800e0 	tbz	w0, #1, 80d64 <putchw+0x7c>
   80d4c:	b9400ee2 	ldr	w2, [x23, #12]
   80d50:	7100405f 	cmp	w2, #0x10
   80d54:	54000a80 	b.eq	80ea4 <putchw+0x1bc>  // b.none
        n -= 2;
    else if (p->alt && p->base == 8)
        n--;
   80d58:	7100205f 	cmp	w2, #0x8
   80d5c:	1a9f17e2 	cset	w2, eq	// eq = none
   80d60:	4b020273 	sub	w19, w19, w2

    /* Fill with space to align to the right, before alternate or sign */
    if (!p->lz && !p->align_left) {
   80d64:	52800122 	mov	w2, #0x9                   	// #9
   80d68:	6a02001f 	tst	w0, w2
   80d6c:	54000181 	b.ne	80d9c <putchw+0xb4>  // b.any
        while (n-- > 0)
   80d70:	7100027f 	cmp	w19, #0x0
   80d74:	51000673 	sub	w19, w19, #0x1
   80d78:	5400012d 	b.le	80d9c <putchw+0xb4>
   80d7c:	d503201f 	nop
   80d80:	51000673 	sub	w19, w19, #0x1
            putf(putp, ' ');
   80d84:	aa1403e0 	mov	x0, x20
   80d88:	52800401 	mov	w1, #0x20                  	// #32
   80d8c:	d63f02a0 	blr	x21
        while (n-- > 0)
   80d90:	3100067f 	cmn	w19, #0x1
   80d94:	54ffff61 	b.ne	80d80 <putchw+0x98>  // b.any
   80d98:	394022e1 	ldrb	w1, [x23, #8]
    }

    /* print sign */
    if (p->sign)
   80d9c:	34000061 	cbz	w1, 80da8 <putchw+0xc0>
        putf(putp, p->sign);
   80da0:	aa1403e0 	mov	x0, x20
   80da4:	d63f02a0 	blr	x21

    /* Alternate */
    if (p->alt && p->base == 16) {
   80da8:	394002e0 	ldrb	w0, [x23]
   80dac:	360800c0 	tbz	w0, #1, 80dc4 <putchw+0xdc>
   80db0:	b9400ee1 	ldr	w1, [x23, #12]
   80db4:	7100403f 	cmp	w1, #0x10
   80db8:	540005e0 	b.eq	80e74 <putchw+0x18c>  // b.none
        putf(putp, '0');
        putf(putp, (p->uc ? 'X' : 'x'));
    } else if (p->alt && p->base == 8) {
   80dbc:	7100203f 	cmp	w1, #0x8
   80dc0:	54000760 	b.eq	80eac <putchw+0x1c4>  // b.none
        putf(putp, '0');
    }

    /* Fill with zeros, after alternate or sign */
    if (p->lz) {
   80dc4:	36000160 	tbz	w0, #0, 80df0 <putchw+0x108>
        while (n-- > 0)
   80dc8:	7100027f 	cmp	w19, #0x0
   80dcc:	51000673 	sub	w19, w19, #0x1
   80dd0:	5400010d 	b.le	80df0 <putchw+0x108>
   80dd4:	d503201f 	nop
   80dd8:	51000673 	sub	w19, w19, #0x1
            putf(putp, '0');
   80ddc:	aa1403e0 	mov	x0, x20
   80de0:	52800601 	mov	w1, #0x30                  	// #48
   80de4:	d63f02a0 	blr	x21
        while (n-- > 0)
   80de8:	3100067f 	cmn	w19, #0x1
   80dec:	54ffff61 	b.ne	80dd8 <putchw+0xf0>  // b.any
    }

    /* Put actual buffer */
    bf = p->bf;
    while ((ch = *bf++))
   80df0:	f9400af6 	ldr	x22, [x23, #16]
   80df4:	384016c1 	ldrb	w1, [x22], #1
   80df8:	340000c1 	cbz	w1, 80e10 <putchw+0x128>
   80dfc:	d503201f 	nop
        putf(putp, ch);
   80e00:	aa1403e0 	mov	x0, x20
   80e04:	d63f02a0 	blr	x21
    while ((ch = *bf++))
   80e08:	384016c1 	ldrb	w1, [x22], #1
   80e0c:	35ffffa1 	cbnz	w1, 80e00 <putchw+0x118>

    /* Fill with space to align to the left, after string */
    if (!p->lz && p->align_left) {
   80e10:	394002e1 	ldrb	w1, [x23]
   80e14:	52800120 	mov	w0, #0x9                   	// #9
   80e18:	0a010000 	and	w0, w0, w1
   80e1c:	7100201f 	cmp	w0, #0x8
   80e20:	540000c0 	b.eq	80e38 <putchw+0x150>  // b.none
        while (n-- > 0)
            putf(putp, ' ');
    }
}
   80e24:	a94153f3 	ldp	x19, x20, [sp, #16]
   80e28:	a9425bf5 	ldp	x21, x22, [sp, #32]
   80e2c:	f9401bf7 	ldr	x23, [sp, #48]
   80e30:	a8c47bfd 	ldp	x29, x30, [sp], #64
   80e34:	d65f03c0 	ret
        while (n-- > 0)
   80e38:	7100027f 	cmp	w19, #0x0
   80e3c:	51000673 	sub	w19, w19, #0x1
   80e40:	54ffff2d 	b.le	80e24 <putchw+0x13c>
   80e44:	d503201f 	nop
   80e48:	51000673 	sub	w19, w19, #0x1
            putf(putp, ' ');
   80e4c:	aa1403e0 	mov	x0, x20
   80e50:	52800401 	mov	w1, #0x20                  	// #32
   80e54:	d63f02a0 	blr	x21
        while (n-- > 0)
   80e58:	3100067f 	cmn	w19, #0x1
   80e5c:	54ffff61 	b.ne	80e48 <putchw+0x160>  // b.any
}
   80e60:	a94153f3 	ldp	x19, x20, [sp, #16]
   80e64:	a9425bf5 	ldp	x21, x22, [sp, #32]
   80e68:	f9401bf7 	ldr	x23, [sp, #48]
   80e6c:	a8c47bfd 	ldp	x29, x30, [sp], #64
   80e70:	d65f03c0 	ret
        putf(putp, '0');
   80e74:	aa1403e0 	mov	x0, x20
   80e78:	52800601 	mov	w1, #0x30                  	// #48
   80e7c:	d63f02a0 	blr	x21
        putf(putp, (p->uc ? 'X' : 'x'));
   80e80:	394002e3 	ldrb	w3, [x23]
   80e84:	52800b02 	mov	w2, #0x58                  	// #88
   80e88:	aa1403e0 	mov	x0, x20
   80e8c:	52800f01 	mov	w1, #0x78                  	// #120
   80e90:	f27e007f 	tst	x3, #0x4
   80e94:	1a811041 	csel	w1, w2, w1, ne	// ne = any
   80e98:	d63f02a0 	blr	x21
   80e9c:	394002e0 	ldrb	w0, [x23]
   80ea0:	17ffffc9 	b	80dc4 <putchw+0xdc>
        n -= 2;
   80ea4:	51000a73 	sub	w19, w19, #0x2
   80ea8:	17ffffaf 	b	80d64 <putchw+0x7c>
        putf(putp, '0');
   80eac:	aa1403e0 	mov	x0, x20
   80eb0:	52800601 	mov	w1, #0x30                  	// #48
   80eb4:	d63f02a0 	blr	x21
   80eb8:	394002e0 	ldrb	w0, [x23]
   80ebc:	17ffffc2 	b	80dc4 <putchw+0xdc>

0000000000080ec0 <_vsnprintf_putcf>:
};

static void _vsnprintf_putcf(void *p, char c)
{
  struct _vsnprintf_putcf_data *data = (struct _vsnprintf_putcf_data*)p;
  if (data->num_chars < data->dest_capacity)
   80ec0:	f9400003 	ldr	x3, [x0]
{
   80ec4:	12001c21 	and	w1, w1, #0xff
  if (data->num_chars < data->dest_capacity)
   80ec8:	f9400802 	ldr	x2, [x0, #16]
   80ecc:	eb03005f 	cmp	x2, x3
   80ed0:	54000082 	b.cs	80ee0 <_vsnprintf_putcf+0x20>  // b.hs, b.nlast
    data->dest[data->num_chars] = c;
   80ed4:	f9400403 	ldr	x3, [x0, #8]
   80ed8:	38226861 	strb	w1, [x3, x2]
   80edc:	f9400802 	ldr	x2, [x0, #16]
  data->num_chars ++;
   80ee0:	91000442 	add	x2, x2, #0x1
   80ee4:	f9000802 	str	x2, [x0, #16]
}
   80ee8:	d65f03c0 	ret
   80eec:	d503201f 	nop

0000000000080ef0 <_vsprintf_putcf>:
};

static void _vsprintf_putcf(void *p, char c)
{
  struct _vsprintf_putcf_data *data = (struct _vsprintf_putcf_data*)p;
  data->dest[data->num_chars++] = c;
   80ef0:	a9400803 	ldp	x3, x2, [x0]
   80ef4:	91000444 	add	x4, x2, #0x1
   80ef8:	f9000404 	str	x4, [x0, #8]
   80efc:	38226861 	strb	w1, [x3, x2]
}
   80f00:	d65f03c0 	ret
   80f04:	d503201f 	nop

0000000000080f08 <tfp_format>:
{
   80f08:	a9b67bfd 	stp	x29, x30, [sp, #-160]!
   80f0c:	910003fd 	mov	x29, sp
   80f10:	a90573fb 	stp	x27, x28, [sp, #80]
    while ((ch = *(fmt++))) {
   80f14:	aa0203fb 	mov	x27, x2
{
   80f18:	a90153f3 	stp	x19, x20, [sp, #16]
   80f1c:	aa0103f4 	mov	x20, x1
   80f20:	aa0003f3 	mov	x19, x0
   80f24:	a9025bf5 	stp	x21, x22, [sp, #32]
   80f28:	b9401876 	ldr	w22, [x3, #24]
   80f2c:	a9046bf9 	stp	x25, x26, [sp, #64]
    p.bf = bf;
   80f30:	9101c3f9 	add	x25, sp, #0x70
    while ((ch = *(fmt++))) {
   80f34:	38401761 	ldrb	w1, [x27], #1
   80f38:	a9400075 	ldp	x21, x0, [x3]
   80f3c:	f90037e0 	str	x0, [sp, #104]
    p.bf = bf;
   80f40:	f9004ff9 	str	x25, [sp, #152]
    while ((ch = *(fmt++))) {
   80f44:	34000a81 	cbz	w1, 81094 <tfp_format+0x18c>
                p.base = 10;
   80f48:	5280015a 	mov	w26, #0xa                   	// #10
   80f4c:	a90363f7 	stp	x23, x24, [sp, #48]
    ui2a(num, p);
   80f50:	910223f7 	add	x23, sp, #0x88
            p.lz = 0;
   80f54:	12800178 	mov	w24, #0xfffffff4            	// #-12
   80f58:	14000008 	b	80f78 <tfp_format+0x70>
            putf(putp, ch);
   80f5c:	aa1303e0 	mov	x0, x19
   80f60:	d63f0280 	blr	x20
   80f64:	aa1c03e0 	mov	x0, x28
   80f68:	aa1b03fc 	mov	x28, x27
   80f6c:	aa0003fb 	mov	x27, x0
    while ((ch = *(fmt++))) {
   80f70:	39400381 	ldrb	w1, [x28]
   80f74:	340008e1 	cbz	w1, 81090 <tfp_format+0x188>
        if (ch != '%') {
   80f78:	7100943f 	cmp	w1, #0x25
   80f7c:	9100077c 	add	x28, x27, #0x1
   80f80:	54fffee1 	b.ne	80f5c <tfp_format+0x54>  // b.any
            p.lz = 0;
   80f84:	394223e0 	ldrb	w0, [sp, #136]
            while ((ch = *(fmt++))) {
   80f88:	39400363 	ldrb	w3, [x27]
            p.lz = 0;
   80f8c:	0a180000 	and	w0, w0, w24
   80f90:	390223e0 	strb	w0, [sp, #136]
            p.width = 0;
   80f94:	b9008fff 	str	wzr, [sp, #140]
            p.sign = 0;
   80f98:	390243ff 	strb	wzr, [sp, #144]
            while ((ch = *(fmt++))) {
   80f9c:	340007a3 	cbz	w3, 81090 <tfp_format+0x188>
   80fa0:	52800002 	mov	w2, #0x0                   	// #0
   80fa4:	52800001 	mov	w1, #0x0                   	// #0
   80fa8:	52800000 	mov	w0, #0x0                   	// #0
                switch (ch) {
   80fac:	7100b47f 	cmp	w3, #0x2d
   80fb0:	54000f00 	b.eq	81190 <tfp_format+0x288>  // b.none
   80fb4:	7100c07f 	cmp	w3, #0x30
   80fb8:	540009e0 	b.eq	810f4 <tfp_format+0x1ec>  // b.none
   80fbc:	71008c7f 	cmp	w3, #0x23
   80fc0:	54000760 	b.eq	810ac <tfp_format+0x1a4>  // b.none
   80fc4:	34000080 	cbz	w0, 80fd4 <tfp_format+0xcc>
   80fc8:	394223e0 	ldrb	w0, [sp, #136]
   80fcc:	321d0000 	orr	w0, w0, #0x8
   80fd0:	390223e0 	strb	w0, [sp, #136]
   80fd4:	34000081 	cbz	w1, 80fe4 <tfp_format+0xdc>
   80fd8:	394223e0 	ldrb	w0, [sp, #136]
   80fdc:	32000000 	orr	w0, w0, #0x1
   80fe0:	390223e0 	strb	w0, [sp, #136]
   80fe4:	34000082 	cbz	w2, 80ff4 <tfp_format+0xec>
   80fe8:	394223e0 	ldrb	w0, [sp, #136]
   80fec:	321f0000 	orr	w0, w0, #0x2
   80ff0:	390223e0 	strb	w0, [sp, #136]
            if (ch >= '0' && ch <= '9') {
   80ff4:	5100c066 	sub	w6, w3, #0x30
   80ff8:	12001cc0 	and	w0, w6, #0xff
   80ffc:	7100241f 	cmp	w0, #0x9
   81000:	54001209 	b.ls	81240 <tfp_format+0x338>  // b.plast
            if (ch == '.') {
   81004:	7100b87f 	cmp	w3, #0x2e
   81008:	54001540 	b.eq	812b0 <tfp_format+0x3a8>  // b.none
            if (ch == 'z') {
   8100c:	7101e87f 	cmp	w3, #0x7a
   81010:	540010e0 	b.eq	8122c <tfp_format+0x324>  // b.none
            if (ch == 'l') {
   81014:	7101b07f 	cmp	w3, #0x6c
   81018:	54001600 	b.eq	812d8 <tfp_format+0x3d0>  // b.none
            switch (ch) {
   8101c:	7101a47f 	cmp	w3, #0x69
   81020:	54002640 	b.eq	814e8 <tfp_format+0x5e0>  // b.none
            char lng = 0;  /* 1 for long, 2 for long long */
   81024:	52800000 	mov	w0, #0x0                   	// #0
            switch (ch) {
   81028:	7101a47f 	cmp	w3, #0x69
   8102c:	54000b69 	b.ls	81198 <tfp_format+0x290>  // b.plast
   81030:	7101cc7f 	cmp	w3, #0x73
   81034:	540017e0 	b.eq	81330 <tfp_format+0x428>  // b.none
   81038:	54000889 	b.ls	81148 <tfp_format+0x240>  // b.plast
   8103c:	7101d47f 	cmp	w3, #0x75
   81040:	540005e1 	b.ne	810fc <tfp_format+0x1f4>  // b.any
                p.base = 10;
   81044:	b90097fa 	str	w26, [sp, #148]
                if (2 == lng)
   81048:	7100081f 	cmp	w0, #0x2
   8104c:	540006e0 	b.eq	81128 <tfp_format+0x220>  // b.none
                  if (1 == lng)
   81050:	7100041f 	cmp	w0, #0x1
   81054:	540008e0 	b.eq	81170 <tfp_format+0x268>  // b.none
                    ui2a(va_arg(va, unsigned int), &p);
   81058:	37f81c36 	tbnz	w22, #31, 813dc <tfp_format+0x4d4>
   8105c:	91002ea1 	add	x1, x21, #0xb
   81060:	aa1503e0 	mov	x0, x21
   81064:	927df035 	and	x21, x1, #0xfffffffffffffff8
   81068:	b9400000 	ldr	w0, [x0]
   8106c:	aa1703e1 	mov	x1, x23
   81070:	97fffeec 	bl	80c20 <ui2a>
                putchw(putp, putf, &p);
   81074:	aa1403e1 	mov	x1, x20
   81078:	aa1703e2 	mov	x2, x23
   8107c:	aa1303e0 	mov	x0, x19
   81080:	97ffff1a 	bl	80ce8 <putchw>
    while ((ch = *(fmt++))) {
   81084:	39400381 	ldrb	w1, [x28]
   81088:	9100079b 	add	x27, x28, #0x1
   8108c:	35fff761 	cbnz	w1, 80f78 <tfp_format+0x70>
   81090:	a94363f7 	ldp	x23, x24, [sp, #48]
}
   81094:	a94153f3 	ldp	x19, x20, [sp, #16]
   81098:	a9425bf5 	ldp	x21, x22, [sp, #32]
   8109c:	a9446bf9 	ldp	x25, x26, [sp, #64]
   810a0:	a94573fb 	ldp	x27, x28, [sp, #80]
   810a4:	a8ca7bfd 	ldp	x29, x30, [sp], #160
   810a8:	d65f03c0 	ret
                    p.alt = 1;
   810ac:	52800022 	mov	w2, #0x1                   	// #1
            while ((ch = *(fmt++))) {
   810b0:	38401783 	ldrb	w3, [x28], #1
   810b4:	35fff7c3 	cbnz	w3, 80fac <tfp_format+0xa4>
   810b8:	34000080 	cbz	w0, 810c8 <tfp_format+0x1c0>
   810bc:	394223e0 	ldrb	w0, [sp, #136]
   810c0:	321d0000 	orr	w0, w0, #0x8
   810c4:	390223e0 	strb	w0, [sp, #136]
   810c8:	34fffe41 	cbz	w1, 81090 <tfp_format+0x188>
   810cc:	394223e0 	ldrb	w0, [sp, #136]
}
   810d0:	a94153f3 	ldp	x19, x20, [sp, #16]
   810d4:	32000000 	orr	w0, w0, #0x1
   810d8:	390223e0 	strb	w0, [sp, #136]
   810dc:	a9425bf5 	ldp	x21, x22, [sp, #32]
   810e0:	a94363f7 	ldp	x23, x24, [sp, #48]
   810e4:	a9446bf9 	ldp	x25, x26, [sp, #64]
   810e8:	a94573fb 	ldp	x27, x28, [sp, #80]
   810ec:	a8ca7bfd 	ldp	x29, x30, [sp], #160
   810f0:	d65f03c0 	ret
                    p.lz = 1;
   810f4:	52800021 	mov	w1, #0x1                   	// #1
   810f8:	17ffffee 	b	810b0 <tfp_format+0x1a8>
            switch (ch) {
   810fc:	7101e07f 	cmp	w3, #0x78
   81100:	54000f61 	b.ne	812ec <tfp_format+0x3e4>  // b.any
                p.uc = (ch == 'X')?1:0;
   81104:	7101607f 	cmp	w3, #0x58
   81108:	394223e1 	ldrb	w1, [sp, #136]
   8110c:	1a9f17e2 	cset	w2, eq	// eq = none
                p.base = 16;
   81110:	52800203 	mov	w3, #0x10                  	// #16
   81114:	b90097e3 	str	w3, [sp, #148]
                if (2 == lng)
   81118:	7100081f 	cmp	w0, #0x2
                p.uc = (ch == 'X')?1:0;
   8111c:	331e0041 	bfi	w1, w2, #2, #1
   81120:	390223e1 	strb	w1, [sp, #136]
                if (2 == lng)
   81124:	54fff961 	b.ne	81050 <tfp_format+0x148>  // b.any
                    ulli2a(va_arg(va, unsigned long long int), &p);
   81128:	37f81836 	tbnz	w22, #31, 8142c <tfp_format+0x524>
   8112c:	91003ea1 	add	x1, x21, #0xf
   81130:	aa1503e0 	mov	x0, x21
   81134:	927df035 	and	x21, x1, #0xfffffffffffffff8
   81138:	f9400000 	ldr	x0, [x0]
   8113c:	aa1703e1 	mov	x1, x23
   81140:	97fffe50 	bl	80a80 <ulli2a>
   81144:	17ffffcc 	b	81074 <tfp_format+0x16c>
            switch (ch) {
   81148:	7101bc7f 	cmp	w3, #0x6f
   8114c:	54000d40 	b.eq	812f4 <tfp_format+0x3ec>  // b.none
   81150:	7101c07f 	cmp	w3, #0x70
   81154:	54000cc1 	b.ne	812ec <tfp_format+0x3e4>  // b.any
                p.alt = 1;
   81158:	394223e0 	ldrb	w0, [sp, #136]
                p.base = 16;
   8115c:	52800201 	mov	w1, #0x10                  	// #16
   81160:	b90097e1 	str	w1, [sp, #148]
                p.alt = 1;
   81164:	121d7400 	and	w0, w0, #0xfffffff9
   81168:	321f0000 	orr	w0, w0, #0x2
   8116c:	390223e0 	strb	w0, [sp, #136]
                    uli2a(va_arg(va, unsigned long int), &p);
   81170:	37f81476 	tbnz	w22, #31, 813fc <tfp_format+0x4f4>
   81174:	91003ea1 	add	x1, x21, #0xf
   81178:	aa1503e0 	mov	x0, x21
   8117c:	927df035 	and	x21, x1, #0xfffffffffffffff8
   81180:	f9400000 	ldr	x0, [x0]
   81184:	aa1703e1 	mov	x1, x23
   81188:	97fffe72 	bl	80b50 <uli2a>
   8118c:	17ffffba 	b	81074 <tfp_format+0x16c>
                switch (ch) {
   81190:	52800020 	mov	w0, #0x1                   	// #1
   81194:	17ffffc7 	b	810b0 <tfp_format+0x1a8>
            switch (ch) {
   81198:	7101607f 	cmp	w3, #0x58
   8119c:	54fffb40 	b.eq	81104 <tfp_format+0x1fc>  // b.none
   811a0:	54000128 	b.hi	811c4 <tfp_format+0x2bc>  // b.pmore
   811a4:	34fff763 	cbz	w3, 81090 <tfp_format+0x188>
   811a8:	7100947f 	cmp	w3, #0x25
   811ac:	54000a01 	b.ne	812ec <tfp_format+0x3e4>  // b.any
                putf(putp, ch);
   811b0:	9100079b 	add	x27, x28, #0x1
   811b4:	2a0303e1 	mov	w1, w3
   811b8:	aa1303e0 	mov	x0, x19
   811bc:	d63f0280 	blr	x20
   811c0:	17ffff6c 	b	80f70 <tfp_format+0x68>
            switch (ch) {
   811c4:	71018c7f 	cmp	w3, #0x63
   811c8:	54000141 	b.ne	811f0 <tfp_format+0x2e8>  // b.any
                putf(putp, (char)(va_arg(va, int)));
   811cc:	37f80cd6 	tbnz	w22, #31, 81364 <tfp_format+0x45c>
   811d0:	91002ea1 	add	x1, x21, #0xb
   811d4:	aa1503e0 	mov	x0, x21
   811d8:	927df035 	and	x21, x1, #0xfffffffffffffff8
   811dc:	39400001 	ldrb	w1, [x0]
   811e0:	9100079b 	add	x27, x28, #0x1
   811e4:	aa1303e0 	mov	x0, x19
   811e8:	d63f0280 	blr	x20
                break;
   811ec:	17ffff61 	b	80f70 <tfp_format+0x68>
            switch (ch) {
   811f0:	7101907f 	cmp	w3, #0x64
   811f4:	540007c1 	b.ne	812ec <tfp_format+0x3e4>  // b.any
                p.base = 10;
   811f8:	b90097fa 	str	w26, [sp, #148]
                if (2 == lng)
   811fc:	7100081f 	cmp	w0, #0x2
   81200:	54001261 	b.ne	8144c <tfp_format+0x544>  // b.any
                    lli2a(va_arg(va, long long int), &p);
   81204:	37f81456 	tbnz	w22, #31, 8148c <tfp_format+0x584>
   81208:	91003ea1 	add	x1, x21, #0xf
   8120c:	aa1503e0 	mov	x0, x21
   81210:	927df035 	and	x21, x1, #0xfffffffffffffff8
   81214:	f9400000 	ldr	x0, [x0]
    if (num < 0) {
   81218:	b6fff920 	tbz	x0, #63, 8113c <tfp_format+0x234>
        p->sign = '-';
   8121c:	528005a1 	mov	w1, #0x2d                  	// #45
        num = -num;
   81220:	cb0003e0 	neg	x0, x0
        p->sign = '-';
   81224:	390243e1 	strb	w1, [sp, #144]
    ulli2a(num, p);
   81228:	17ffffc5 	b	8113c <tfp_format+0x234>
                ch = *(fmt++);
   8122c:	38401783 	ldrb	w3, [x28], #1
            switch (ch) {
   81230:	7101a47f 	cmp	w3, #0x69
   81234:	54001440 	b.eq	814bc <tfp_format+0x5b4>  // b.none
   81238:	52800020 	mov	w0, #0x1                   	// #1
   8123c:	17ffff7b 	b	81028 <tfp_format+0x120>
    unsigned int num = 0;
   81240:	52800002 	mov	w2, #0x0                   	// #0
   81244:	1400000b 	b	81270 <tfp_format+0x368>
    else if (ch >= 'a' && ch <= 'f')
   81248:	7100141f 	cmp	w0, #0x5
   8124c:	54000269 	b.ls	81298 <tfp_format+0x390>  // b.plast
    else if (ch >= 'A' && ch <= 'F')
   81250:	7100143f 	cmp	w1, #0x5
   81254:	54000288 	b.hi	812a4 <tfp_format+0x39c>  // b.pmore
        if (digit > base)
   81258:	710028bf 	cmp	w5, #0xa
   8125c:	54000241 	b.ne	812a4 <tfp_format+0x39c>  // b.any
        ch = *p++;
   81260:	38401783 	ldrb	w3, [x28], #1
        num = num * base + digit;
   81264:	0b020842 	add	w2, w2, w2, lsl #2
   81268:	5100c066 	sub	w6, w3, #0x30
   8126c:	0b0204a2 	add	w2, w5, w2, lsl #1
    else if (ch >= 'a' && ch <= 'f')
   81270:	51018460 	sub	w0, w3, #0x61
    else if (ch >= 'A' && ch <= 'F')
   81274:	51010461 	sub	w1, w3, #0x41
    if (ch >= '0' && ch <= '9')
   81278:	12001cc4 	and	w4, w6, #0xff
        return ch - 'A' + 10;
   8127c:	5100dc65 	sub	w5, w3, #0x37
    else if (ch >= 'a' && ch <= 'f')
   81280:	12001c00 	and	w0, w0, #0xff
    else if (ch >= 'A' && ch <= 'F')
   81284:	12001c21 	and	w1, w1, #0xff
    if (ch >= '0' && ch <= '9')
   81288:	7100249f 	cmp	w4, #0x9
   8128c:	54fffde8 	b.hi	81248 <tfp_format+0x340>  // b.pmore
        return ch - '0';
   81290:	2a0603e5 	mov	w5, w6
        if (digit > base)
   81294:	17fffff3 	b	81260 <tfp_format+0x358>
        return ch - 'a' + 10;
   81298:	51015c65 	sub	w5, w3, #0x57
        if (digit > base)
   8129c:	710028bf 	cmp	w5, #0xa
   812a0:	54fffe00 	b.eq	81260 <tfp_format+0x358>  // b.none
    *nump = num;
   812a4:	b9008fe2 	str	w2, [sp, #140]
            if (ch == '.') {
   812a8:	7100b87f 	cmp	w3, #0x2e
   812ac:	54ffeb01 	b.ne	8100c <tfp_format+0x104>  // b.any
              p.lz = 1;  /* zero-padding */
   812b0:	394223e0 	ldrb	w0, [sp, #136]
   812b4:	32000000 	orr	w0, w0, #0x1
   812b8:	390223e0 	strb	w0, [sp, #136]
   812bc:	d503201f 	nop
                ch = *(fmt++);
   812c0:	38401783 	ldrb	w3, [x28], #1
              } while ((ch >= '0') && (ch <= '9'));
   812c4:	5100c060 	sub	w0, w3, #0x30
   812c8:	12001c00 	and	w0, w0, #0xff
   812cc:	7100241f 	cmp	w0, #0x9
   812d0:	54ffff89 	b.ls	812c0 <tfp_format+0x3b8>  // b.plast
   812d4:	17ffff4e 	b	8100c <tfp_format+0x104>
                ch = *(fmt++);
   812d8:	39400383 	ldrb	w3, [x28]
                if (ch == 'l') {
   812dc:	7101b07f 	cmp	w3, #0x6c
   812e0:	54000720 	b.eq	813c4 <tfp_format+0x4bc>  // b.none
                ch = *(fmt++);
   812e4:	9100079c 	add	x28, x28, #0x1
   812e8:	17ffffd2 	b	81230 <tfp_format+0x328>
   812ec:	9100079b 	add	x27, x28, #0x1
   812f0:	17ffff20 	b	80f70 <tfp_format+0x68>
                p.base = 8;
   812f4:	52800100 	mov	w0, #0x8                   	// #8
   812f8:	b90097e0 	str	w0, [sp, #148]
                ui2a(va_arg(va, unsigned int), &p);
   812fc:	37f80456 	tbnz	w22, #31, 81384 <tfp_format+0x47c>
   81300:	91002ea1 	add	x1, x21, #0xb
   81304:	aa1503e0 	mov	x0, x21
   81308:	927df035 	and	x21, x1, #0xfffffffffffffff8
   8130c:	b9400000 	ldr	w0, [x0]
   81310:	aa1703e1 	mov	x1, x23
   81314:	9100079b 	add	x27, x28, #0x1
   81318:	97fffe42 	bl	80c20 <ui2a>
                putchw(putp, putf, &p);
   8131c:	aa1703e2 	mov	x2, x23
   81320:	aa1403e1 	mov	x1, x20
   81324:	aa1303e0 	mov	x0, x19
   81328:	97fffe70 	bl	80ce8 <putchw>
                break;
   8132c:	17ffff11 	b	80f70 <tfp_format+0x68>
                p.bf = va_arg(va, char *);
   81330:	37f803b6 	tbnz	w22, #31, 813a4 <tfp_format+0x49c>
   81334:	91003ea1 	add	x1, x21, #0xf
   81338:	aa1503e0 	mov	x0, x21
   8133c:	927df035 	and	x21, x1, #0xfffffffffffffff8
   81340:	f9400003 	ldr	x3, [x0]
                putchw(putp, putf, &p);
   81344:	aa1703e2 	mov	x2, x23
   81348:	aa1403e1 	mov	x1, x20
   8134c:	aa1303e0 	mov	x0, x19
   81350:	9100079b 	add	x27, x28, #0x1
                p.bf = va_arg(va, char *);
   81354:	f9004fe3 	str	x3, [sp, #152]
                putchw(putp, putf, &p);
   81358:	97fffe64 	bl	80ce8 <putchw>
                p.bf = bf;
   8135c:	f9004ff9 	str	x25, [sp, #152]
                break;
   81360:	17ffff04 	b	80f70 <tfp_format+0x68>
                putf(putp, (char)(va_arg(va, int)));
   81364:	110022c1 	add	w1, w22, #0x8
   81368:	7100003f 	cmp	w1, #0x0
   8136c:	54000d2d 	b.le	81510 <tfp_format+0x608>
   81370:	91002ea2 	add	x2, x21, #0xb
   81374:	aa1503e0 	mov	x0, x21
   81378:	2a0103f6 	mov	w22, w1
   8137c:	927df055 	and	x21, x2, #0xfffffffffffffff8
   81380:	17ffff97 	b	811dc <tfp_format+0x2d4>
                ui2a(va_arg(va, unsigned int), &p);
   81384:	110022c1 	add	w1, w22, #0x8
   81388:	7100003f 	cmp	w1, #0x0
   8138c:	54000d2d 	b.le	81530 <tfp_format+0x628>
   81390:	91002ea2 	add	x2, x21, #0xb
   81394:	aa1503e0 	mov	x0, x21
   81398:	2a0103f6 	mov	w22, w1
   8139c:	927df055 	and	x21, x2, #0xfffffffffffffff8
   813a0:	17ffffdb 	b	8130c <tfp_format+0x404>
                p.bf = va_arg(va, char *);
   813a4:	110022c1 	add	w1, w22, #0x8
   813a8:	7100003f 	cmp	w1, #0x0
   813ac:	54000bad 	b.le	81520 <tfp_format+0x618>
   813b0:	91003ea2 	add	x2, x21, #0xf
   813b4:	aa1503e0 	mov	x0, x21
   813b8:	2a0103f6 	mov	w22, w1
   813bc:	927df055 	and	x21, x2, #0xfffffffffffffff8
   813c0:	17ffffe0 	b	81340 <tfp_format+0x438>
                  ch = *(fmt++);
   813c4:	39400783 	ldrb	w3, [x28, #1]
   813c8:	91000b9c 	add	x28, x28, #0x2
            switch (ch) {
   813cc:	7101a47f 	cmp	w3, #0x69
   813d0:	54000d80 	b.eq	81580 <tfp_format+0x678>  // b.none
                  lng = 2;
   813d4:	52800040 	mov	w0, #0x2                   	// #2
   813d8:	17ffff14 	b	81028 <tfp_format+0x120>
                    ui2a(va_arg(va, unsigned int), &p);
   813dc:	110022c1 	add	w1, w22, #0x8
   813e0:	7100003f 	cmp	w1, #0x0
   813e4:	540001cd 	b.le	8141c <tfp_format+0x514>
   813e8:	91002ea2 	add	x2, x21, #0xb
   813ec:	aa1503e0 	mov	x0, x21
   813f0:	2a0103f6 	mov	w22, w1
   813f4:	927df055 	and	x21, x2, #0xfffffffffffffff8
   813f8:	17ffff1c 	b	81068 <tfp_format+0x160>
                    uli2a(va_arg(va, unsigned long int), &p);
   813fc:	110022c1 	add	w1, w22, #0x8
   81400:	7100003f 	cmp	w1, #0x0
   81404:	540003cd 	b.le	8147c <tfp_format+0x574>
   81408:	91003ea2 	add	x2, x21, #0xf
   8140c:	aa1503e0 	mov	x0, x21
   81410:	2a0103f6 	mov	w22, w1
   81414:	927df055 	and	x21, x2, #0xfffffffffffffff8
   81418:	17ffff5a 	b	81180 <tfp_format+0x278>
                    ui2a(va_arg(va, unsigned int), &p);
   8141c:	f94037e0 	ldr	x0, [sp, #104]
   81420:	8b36c000 	add	x0, x0, w22, sxtw
   81424:	2a0103f6 	mov	w22, w1
   81428:	17ffff10 	b	81068 <tfp_format+0x160>
                    ulli2a(va_arg(va, unsigned long long int), &p);
   8142c:	110022c1 	add	w1, w22, #0x8
   81430:	7100003f 	cmp	w1, #0x0
   81434:	540003cd 	b.le	814ac <tfp_format+0x5a4>
   81438:	91003ea2 	add	x2, x21, #0xf
   8143c:	aa1503e0 	mov	x0, x21
   81440:	2a0103f6 	mov	w22, w1
   81444:	927df055 	and	x21, x2, #0xfffffffffffffff8
   81448:	17ffff3c 	b	81138 <tfp_format+0x230>
                  if (1 == lng)
   8144c:	7100041f 	cmp	w0, #0x1
   81450:	54000380 	b.eq	814c0 <tfp_format+0x5b8>  // b.none
                    i2a(va_arg(va, int), &p);
   81454:	37f804f6 	tbnz	w22, #31, 814f0 <tfp_format+0x5e8>
   81458:	91002ea1 	add	x1, x21, #0xb
   8145c:	aa1503e0 	mov	x0, x21
   81460:	927df035 	and	x21, x1, #0xfffffffffffffff8
   81464:	b9400000 	ldr	w0, [x0]
    if (num < 0) {
   81468:	36ffe020 	tbz	w0, #31, 8106c <tfp_format+0x164>
        p->sign = '-';
   8146c:	528005a1 	mov	w1, #0x2d                  	// #45
        num = -num;
   81470:	4b0003e0 	neg	w0, w0
        p->sign = '-';
   81474:	390243e1 	strb	w1, [sp, #144]
    ui2a(num, p);
   81478:	17fffefd 	b	8106c <tfp_format+0x164>
                    uli2a(va_arg(va, unsigned long int), &p);
   8147c:	f94037e0 	ldr	x0, [sp, #104]
   81480:	8b36c000 	add	x0, x0, w22, sxtw
   81484:	2a0103f6 	mov	w22, w1
   81488:	17ffff3e 	b	81180 <tfp_format+0x278>
                    lli2a(va_arg(va, long long int), &p);
   8148c:	110022c1 	add	w1, w22, #0x8
   81490:	7100003f 	cmp	w1, #0x0
   81494:	540006ed 	b.le	81570 <tfp_format+0x668>
   81498:	91003ea2 	add	x2, x21, #0xf
   8149c:	aa1503e0 	mov	x0, x21
   814a0:	2a0103f6 	mov	w22, w1
   814a4:	927df055 	and	x21, x2, #0xfffffffffffffff8
   814a8:	17ffff5b 	b	81214 <tfp_format+0x30c>
                    ulli2a(va_arg(va, unsigned long long int), &p);
   814ac:	f94037e0 	ldr	x0, [sp, #104]
   814b0:	8b36c000 	add	x0, x0, w22, sxtw
   814b4:	2a0103f6 	mov	w22, w1
   814b8:	17ffff20 	b	81138 <tfp_format+0x230>
                p.base = 10;
   814bc:	b90097fa 	str	w26, [sp, #148]
                    li2a(va_arg(va, long int), &p);
   814c0:	37f80416 	tbnz	w22, #31, 81540 <tfp_format+0x638>
   814c4:	91003ea1 	add	x1, x21, #0xf
   814c8:	aa1503e0 	mov	x0, x21
   814cc:	927df035 	and	x21, x1, #0xfffffffffffffff8
   814d0:	f9400000 	ldr	x0, [x0]
    if (num < 0) {
   814d4:	b6ffe580 	tbz	x0, #63, 81184 <tfp_format+0x27c>
        p->sign = '-';
   814d8:	528005a1 	mov	w1, #0x2d                  	// #45
        num = -num;
   814dc:	cb0003e0 	neg	x0, x0
        p->sign = '-';
   814e0:	390243e1 	strb	w1, [sp, #144]
    uli2a(num, p);
   814e4:	17ffff28 	b	81184 <tfp_format+0x27c>
                p.base = 10;
   814e8:	b90097fa 	str	w26, [sp, #148]
                if (2 == lng)
   814ec:	17ffffda 	b	81454 <tfp_format+0x54c>
                    i2a(va_arg(va, int), &p);
   814f0:	110022c1 	add	w1, w22, #0x8
   814f4:	7100003f 	cmp	w1, #0x0
   814f8:	5400034d 	b.le	81560 <tfp_format+0x658>
   814fc:	91002ea2 	add	x2, x21, #0xb
   81500:	aa1503e0 	mov	x0, x21
   81504:	2a0103f6 	mov	w22, w1
   81508:	927df055 	and	x21, x2, #0xfffffffffffffff8
   8150c:	17ffffd6 	b	81464 <tfp_format+0x55c>
                putf(putp, (char)(va_arg(va, int)));
   81510:	f94037e0 	ldr	x0, [sp, #104]
   81514:	8b36c000 	add	x0, x0, w22, sxtw
   81518:	2a0103f6 	mov	w22, w1
   8151c:	17ffff30 	b	811dc <tfp_format+0x2d4>
                p.bf = va_arg(va, char *);
   81520:	f94037e0 	ldr	x0, [sp, #104]
   81524:	8b36c000 	add	x0, x0, w22, sxtw
   81528:	2a0103f6 	mov	w22, w1
   8152c:	17ffff85 	b	81340 <tfp_format+0x438>
                ui2a(va_arg(va, unsigned int), &p);
   81530:	f94037e0 	ldr	x0, [sp, #104]
   81534:	8b36c000 	add	x0, x0, w22, sxtw
   81538:	2a0103f6 	mov	w22, w1
   8153c:	17ffff74 	b	8130c <tfp_format+0x404>
                    li2a(va_arg(va, long int), &p);
   81540:	110022c1 	add	w1, w22, #0x8
   81544:	7100003f 	cmp	w1, #0x0
   81548:	5400022d 	b.le	8158c <tfp_format+0x684>
   8154c:	91003ea2 	add	x2, x21, #0xf
   81550:	aa1503e0 	mov	x0, x21
   81554:	2a0103f6 	mov	w22, w1
   81558:	927df055 	and	x21, x2, #0xfffffffffffffff8
   8155c:	17ffffdd 	b	814d0 <tfp_format+0x5c8>
                    i2a(va_arg(va, int), &p);
   81560:	f94037e0 	ldr	x0, [sp, #104]
   81564:	8b36c000 	add	x0, x0, w22, sxtw
   81568:	2a0103f6 	mov	w22, w1
   8156c:	17ffffbe 	b	81464 <tfp_format+0x55c>
                    lli2a(va_arg(va, long long int), &p);
   81570:	f94037e0 	ldr	x0, [sp, #104]
   81574:	8b36c000 	add	x0, x0, w22, sxtw
   81578:	2a0103f6 	mov	w22, w1
   8157c:	17ffff26 	b	81214 <tfp_format+0x30c>
                p.base = 10;
   81580:	b90097fa 	str	w26, [sp, #148]
                    lli2a(va_arg(va, long long int), &p);
   81584:	36ffe436 	tbz	w22, #31, 81208 <tfp_format+0x300>
   81588:	17ffffc1 	b	8148c <tfp_format+0x584>
                    li2a(va_arg(va, long int), &p);
   8158c:	f94037e0 	ldr	x0, [sp, #104]
   81590:	8b36c000 	add	x0, x0, w22, sxtw
   81594:	2a0103f6 	mov	w22, w1
   81598:	17ffffce 	b	814d0 <tfp_format+0x5c8>
   8159c:	d503201f 	nop

00000000000815a0 <init_printf>:
    stdout_putf = putf;
   815a0:	b00000a2 	adrp	x2, 96000 <stdout_putf>
   815a4:	91000043 	add	x3, x2, #0x0
   815a8:	f9000041 	str	x1, [x2]
    stdout_putp = putp;
   815ac:	f9000460 	str	x0, [x3, #8]
}
   815b0:	d65f03c0 	ret
   815b4:	d503201f 	nop

00000000000815b8 <tfp_printf>:
{
   815b8:	a9b77bfd 	stp	x29, x30, [sp, #-144]!
    tfp_format(stdout_putp, stdout_putf, fmt, va);
   815bc:	b00000a8 	adrp	x8, 96000 <stdout_putf>
   815c0:	9100010b 	add	x11, x8, #0x0
{
   815c4:	910003fd 	mov	x29, sp
   815c8:	f9002fe1 	str	x1, [sp, #88]
   815cc:	aa0003ea 	mov	x10, x0
    tfp_format(stdout_putp, stdout_putf, fmt, va);
   815d0:	f9400101 	ldr	x1, [x8]
    va_start(va, fmt);
   815d4:	910143e9 	add	x9, sp, #0x50
    tfp_format(stdout_putp, stdout_putf, fmt, va);
   815d8:	f9400560 	ldr	x0, [x11, #8]
    va_start(va, fmt);
   815dc:	910243eb 	add	x11, sp, #0x90
   815e0:	a9032feb 	stp	x11, x11, [sp, #48]
   815e4:	128006e8 	mov	w8, #0xffffffc8            	// #-56
   815e8:	f90023e9 	str	x9, [sp, #64]
   815ec:	b9004be8 	str	w8, [sp, #72]
   815f0:	b9004fff 	str	wzr, [sp, #76]
    tfp_format(stdout_putp, stdout_putf, fmt, va);
   815f4:	a94327e8 	ldp	x8, x9, [sp, #48]
   815f8:	a90127e8 	stp	x8, x9, [sp, #16]
   815fc:	a94427e8 	ldp	x8, x9, [sp, #64]
   81600:	a90227e8 	stp	x8, x9, [sp, #32]
{
   81604:	a9060fe2 	stp	x2, x3, [sp, #96]
    tfp_format(stdout_putp, stdout_putf, fmt, va);
   81608:	910043e3 	add	x3, sp, #0x10
   8160c:	aa0a03e2 	mov	x2, x10
{
   81610:	a90717e4 	stp	x4, x5, [sp, #112]
   81614:	a9081fe6 	stp	x6, x7, [sp, #128]
    tfp_format(stdout_putp, stdout_putf, fmt, va);
   81618:	97fffe3c 	bl	80f08 <tfp_format>
}
   8161c:	a8c97bfd 	ldp	x29, x30, [sp], #144
   81620:	d65f03c0 	ret
   81624:	d503201f 	nop

0000000000081628 <tfp_vsnprintf>:
  if (size < 1)
   81628:	b5000061 	cbnz	x1, 81634 <tfp_vsnprintf+0xc>
    return 0;
   8162c:	52800000 	mov	w0, #0x0                   	// #0
}
   81630:	d65f03c0 	ret
{
   81634:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
   81638:	aa0003e5 	mov	x5, x0
  data.dest_capacity = size-1;
   8163c:	d1000424 	sub	x4, x1, #0x1
{
   81640:	910003fd 	mov	x29, sp
  tfp_format(&data, _vsnprintf_putcf, format, ap);
   81644:	a9402069 	ldp	x9, x8, [x3]
   81648:	9100e3e0 	add	x0, sp, #0x38
   8164c:	a9411867 	ldp	x7, x6, [x3, #16]
   81650:	f0ffffe1 	adrp	x1, 80000 <_start>
   81654:	910043e3 	add	x3, sp, #0x10
   81658:	913b0021 	add	x1, x1, #0xec0
   8165c:	a90123e9 	stp	x9, x8, [sp, #16]
   81660:	a9021be7 	stp	x7, x6, [sp, #32]
  data.dest = str;
   81664:	a90397e4 	stp	x4, x5, [sp, #56]
  data.num_chars = 0;
   81668:	f90027ff 	str	xzr, [sp, #72]
  tfp_format(&data, _vsnprintf_putcf, format, ap);
   8166c:	97fffe27 	bl	80f08 <tfp_format>
  if (data.num_chars < data.dest_capacity)
   81670:	f9401fe0 	ldr	x0, [sp, #56]
   81674:	f94027e1 	ldr	x1, [sp, #72]
   81678:	eb00003f 	cmp	x1, x0
   8167c:	540000c2 	b.cs	81694 <tfp_vsnprintf+0x6c>  // b.hs, b.nlast
    data.dest[data.num_chars] = '\0';
   81680:	f94023e0 	ldr	x0, [sp, #64]
   81684:	3821681f 	strb	wzr, [x0, x1]
  return data.num_chars;
   81688:	b9404be0 	ldr	w0, [sp, #72]
}
   8168c:	a8c57bfd 	ldp	x29, x30, [sp], #80
   81690:	d65f03c0 	ret
    data.dest[data.dest_capacity] = '\0';
   81694:	f94023e1 	ldr	x1, [sp, #64]
   81698:	3820683f 	strb	wzr, [x1, x0]
  return data.num_chars;
   8169c:	b9404be0 	ldr	w0, [sp, #72]
}
   816a0:	a8c57bfd 	ldp	x29, x30, [sp], #80
   816a4:	d65f03c0 	ret

00000000000816a8 <tfp_snprintf>:
{
   816a8:	a9b87bfd 	stp	x29, x30, [sp, #-128]!
  va_start(ap, format);
   816ac:	128004e8 	mov	w8, #0xffffffd8            	// #-40
{
   816b0:	910003fd 	mov	x29, sp
  va_start(ap, format);
   816b4:	910203ea 	add	x10, sp, #0x80
   816b8:	a9032bea 	stp	x10, x10, [sp, #48]
   816bc:	910143e9 	add	x9, sp, #0x50
   816c0:	f90023e9 	str	x9, [sp, #64]
   816c4:	29097fe8 	stp	w8, wzr, [sp, #72]
  retval = tfp_vsnprintf(str, size, format, ap);
   816c8:	a94327e8 	ldp	x8, x9, [sp, #48]
   816cc:	a90127e8 	stp	x8, x9, [sp, #16]
   816d0:	a94427e8 	ldp	x8, x9, [sp, #64]
   816d4:	a90227e8 	stp	x8, x9, [sp, #32]
{
   816d8:	a90593e3 	stp	x3, x4, [sp, #88]
  retval = tfp_vsnprintf(str, size, format, ap);
   816dc:	910043e3 	add	x3, sp, #0x10
{
   816e0:	a9069be5 	stp	x5, x6, [sp, #104]
   816e4:	f9003fe7 	str	x7, [sp, #120]
  retval = tfp_vsnprintf(str, size, format, ap);
   816e8:	97ffffd0 	bl	81628 <tfp_vsnprintf>
}
   816ec:	a8c87bfd 	ldp	x29, x30, [sp], #128
   816f0:	d65f03c0 	ret
   816f4:	d503201f 	nop

00000000000816f8 <tfp_vsprintf>:

int tfp_vsprintf(char *str, const char *format, va_list ap)
{
   816f8:	aa0203e4 	mov	x4, x2
   816fc:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
   81700:	aa0003e5 	mov	x5, x0
   81704:	910003fd 	mov	x29, sp
  struct _vsprintf_putcf_data data;
  data.dest = str;
  data.num_chars = 0;
  tfp_format(&data, _vsprintf_putcf, format, ap);
   81708:	a9401c86 	ldp	x6, x7, [x4]
   8170c:	f9000be6 	str	x6, [sp, #16]
   81710:	aa0103e2 	mov	x2, x1
   81714:	910043e3 	add	x3, sp, #0x10
   81718:	f9400886 	ldr	x6, [x4, #16]
   8171c:	f9000fe7 	str	x7, [sp, #24]
   81720:	9100c3e0 	add	x0, sp, #0x30
   81724:	f0ffffe1 	adrp	x1, 80000 <_start>
   81728:	f9400c84 	ldr	x4, [x4, #24]
   8172c:	913bc021 	add	x1, x1, #0xef0
   81730:	a90213e6 	stp	x6, x4, [sp, #32]
  data.num_chars = 0;
   81734:	a9037fe5 	stp	x5, xzr, [sp, #48]
  tfp_format(&data, _vsprintf_putcf, format, ap);
   81738:	97fffdf4 	bl	80f08 <tfp_format>
  data.dest[data.num_chars] = '\0';
   8173c:	a94303e1 	ldp	x1, x0, [sp, #48]
   81740:	3820683f 	strb	wzr, [x1, x0]
  return data.num_chars;
}
   81744:	b9403be0 	ldr	w0, [sp, #56]
   81748:	a8c47bfd 	ldp	x29, x30, [sp], #64
   8174c:	d65f03c0 	ret

0000000000081750 <tfp_sprintf>:

int tfp_sprintf(char *str, const char *format, ...)
{
   81750:	a9b57bfd 	stp	x29, x30, [sp, #-176]!
  va_list ap;
  int retval;

  va_start(ap, format);
   81754:	128005e8 	mov	w8, #0xffffffd0            	// #-48
{
   81758:	aa0103ec 	mov	x12, x1
   8175c:	910003fd 	mov	x29, sp
  va_start(ap, format);
   81760:	910203e9 	add	x9, sp, #0x80
   81764:	9102c3ea 	add	x10, sp, #0xb0
   81768:	a9042bea 	stp	x10, x10, [sp, #64]
{
   8176c:	aa0003ed 	mov	x13, x0
  tfp_format(&data, _vsprintf_putcf, format, ap);
   81770:	f0ffffe1 	adrp	x1, 80000 <_start>
  va_start(ap, format);
   81774:	f9002be9 	str	x9, [sp, #80]
  tfp_format(&data, _vsprintf_putcf, format, ap);
   81778:	9100c3e0 	add	x0, sp, #0x30
  va_start(ap, format);
   8177c:	290b7fe8 	stp	w8, wzr, [sp, #88]
  tfp_format(&data, _vsprintf_putcf, format, ap);
   81780:	913bc021 	add	x1, x1, #0xef0
   81784:	a9442fea 	ldp	x10, x11, [sp, #64]
   81788:	a9012fea 	stp	x10, x11, [sp, #16]
   8178c:	a94527e8 	ldp	x8, x9, [sp, #80]
   81790:	a90227e8 	stp	x8, x9, [sp, #32]
  data.num_chars = 0;
   81794:	a9037fed 	stp	x13, xzr, [sp, #48]
   81798:	a9062fea 	stp	x10, x11, [sp, #96]
   8179c:	a90727e8 	stp	x8, x9, [sp, #112]
{
   817a0:	a9080fe2 	stp	x2, x3, [sp, #128]
  tfp_format(&data, _vsprintf_putcf, format, ap);
   817a4:	910043e3 	add	x3, sp, #0x10
   817a8:	aa0c03e2 	mov	x2, x12
{
   817ac:	a90917e4 	stp	x4, x5, [sp, #144]
   817b0:	a90a1fe6 	stp	x6, x7, [sp, #160]
  tfp_format(&data, _vsprintf_putcf, format, ap);
   817b4:	97fffdd5 	bl	80f08 <tfp_format>
  data.dest[data.num_chars] = '\0';
   817b8:	a94303e1 	ldp	x1, x0, [sp, #48]
   817bc:	3820683f 	strb	wzr, [x1, x0]
  retval = tfp_vsprintf(str, format, ap);
  va_end(ap);
  return retval;
}
   817c0:	b9403be0 	ldr	w0, [sp, #56]
   817c4:	a8cb7bfd 	ldp	x29, x30, [sp], #176
   817c8:	d65f03c0 	ret
   817cc:	d503201f 	nop

00000000000817d0 <panic>:
#endif

// xv6
void panic(char *s)
{
   817d0:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
  printf("panic: ");
   817d4:	b0000022 	adrp	x2, 86000 <__asm_dcache_level+0xc>
{
   817d8:	910003fd 	mov	x29, sp
   817dc:	f9000bf3 	str	x19, [sp, #16]
   817e0:	aa0003f3 	mov	x19, x0
  printf("panic: ");
   817e4:	9117e040 	add	x0, x2, #0x5f8
   817e8:	97ffff74 	bl	815b8 <tfp_printf>
  printf("%s\n", s);
   817ec:	aa1303e1 	mov	x1, x19
   817f0:	b0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   817f4:	91180000 	add	x0, x0, #0x600
   817f8:	97ffff70 	bl	815b8 <tfp_printf>
//   panicked = 1; // freeze uart output from other CPUs
    asm volatile("msr	daifset, #0b0010 "); // disable irq
   817fc:	d50342df 	msr	daifset, #0x2
  for(;;)
   81800:	14000000 	b	81800 <panic+0x30>
   81804:	d503201f 	nop

0000000000081808 <debug_hexdump>:
}

// circle debug.cpp
// will dump at least 16 bytes....
void debug_hexdump (const void *pStart, unsigned nBytes)
{
   81808:	d10203ff 	sub	sp, sp, #0x80
	unsigned char *pOffset = (unsigned char *) pStart;
	
	printf("Dumping 0x%x bytes starting at 0x%lx\r\n", nBytes,
   8180c:	aa0003e2 	mov	x2, x0
{
   81810:	a9057bfd 	stp	x29, x30, [sp, #80]
   81814:	910143fd 	add	x29, sp, #0x50
   81818:	a90653f3 	stp	x19, x20, [sp, #96]
   8181c:	aa0003f4 	mov	x20, x0
	printf("Dumping 0x%x bytes starting at 0x%lx\r\n", nBytes,
   81820:	b0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   81824:	91182000 	add	x0, x0, #0x608
{
   81828:	a9075bf5 	stp	x21, x22, [sp, #112]
   8182c:	2a0103f5 	mov	w21, w1
	printf("Dumping 0x%x bytes starting at 0x%lx\r\n", nBytes,
   81830:	97ffff62 	bl	815b8 <tfp_printf>
				(unsigned long) pOffset);
	
	while (nBytes > 0)
   81834:	34000575 	cbz	w21, 818e0 <debug_hexdump+0xd8>
   81838:	927c6ea2 	and	x2, x21, #0xfffffff0
	unsigned char *pOffset = (unsigned char *) pStart;
   8183c:	aa1403f3 	mov	x19, x20
   81840:	91004042 	add	x2, x2, #0x10
	while (nBytes > 0)
   81844:	0b1402b5 	add	w21, w21, w20
   81848:	b0000036 	adrp	x22, 86000 <__asm_dcache_level+0xc>
   8184c:	8b020294 	add	x20, x20, x2
	{
		printf(
   81850:	9118c2d6 	add	x22, x22, #0x630
   81854:	14000003 	b	81860 <debug_hexdump+0x58>
	while (nBytes > 0)
   81858:	6b1302bf 	cmp	w21, w19
   8185c:	54000420 	b.eq	818e0 <debug_hexdump+0xd8>  // b.none
		printf(
   81860:	39402e68 	ldrb	w8, [x19, #11]
   81864:	92403e61 	and	x1, x19, #0xffff
   81868:	39402a69 	ldrb	w9, [x19, #10]
   8186c:	aa1603e0 	mov	x0, x22
   81870:	3940266a 	ldrb	w10, [x19, #9]
				(unsigned) pOffset[0],  (unsigned) pOffset[1],  (unsigned) pOffset[2],  (unsigned) pOffset[3],
				(unsigned) pOffset[4],  (unsigned) pOffset[5],  (unsigned) pOffset[6],  (unsigned) pOffset[7],
				(unsigned) pOffset[8],  (unsigned) pOffset[9],  (unsigned) pOffset[10], (unsigned) pOffset[11],
				(unsigned) pOffset[12], (unsigned) pOffset[13], (unsigned) pOffset[14], (unsigned) pOffset[15]);

		pOffset += 16;
   81874:	91004273 	add	x19, x19, #0x10
		printf(
   81878:	385f826b 	ldurb	w11, [x19, #-8]
   8187c:	385f726c 	ldurb	w12, [x19, #-9]
   81880:	385f626d 	ldurb	w13, [x19, #-10]
   81884:	385f5267 	ldurb	w7, [x19, #-11]
   81888:	385f4266 	ldurb	w6, [x19, #-12]
   8188c:	385f3265 	ldurb	w5, [x19, #-13]
   81890:	385f2264 	ldurb	w4, [x19, #-14]
   81894:	385f1263 	ldurb	w3, [x19, #-15]
   81898:	385f0262 	ldurb	w2, [x19, #-16]
   8189c:	b90003ed 	str	w13, [sp]
   818a0:	b9000bec 	str	w12, [sp, #8]
   818a4:	b90013eb 	str	w11, [sp, #16]
   818a8:	b9001bea 	str	w10, [sp, #24]
   818ac:	b90023e9 	str	w9, [sp, #32]
   818b0:	b9002be8 	str	w8, [sp, #40]
   818b4:	385ff268 	ldurb	w8, [x19, #-1]
   818b8:	385fe269 	ldurb	w9, [x19, #-2]
   818bc:	385fd26a 	ldurb	w10, [x19, #-3]
   818c0:	385fc26b 	ldurb	w11, [x19, #-4]
   818c4:	b90033eb 	str	w11, [sp, #48]
   818c8:	b9003bea 	str	w10, [sp, #56]
   818cc:	b90043e9 	str	w9, [sp, #64]
   818d0:	b9004be8 	str	w8, [sp, #72]
   818d4:	97ffff39 	bl	815b8 <tfp_printf>
		if (nBytes >= 16)
   818d8:	eb14027f 	cmp	x19, x20
   818dc:	54fffbe1 	b.ne	81858 <debug_hexdump+0x50>  // b.any
		else
		{
			nBytes = 0;
		}
	}
}
   818e0:	a9457bfd 	ldp	x29, x30, [sp, #80]
   818e4:	a94653f3 	ldp	x19, x20, [sp, #96]
   818e8:	a9475bf5 	ldp	x21, x22, [sp, #112]
   818ec:	910203ff 	add	sp, sp, #0x80
   818f0:	d65f03c0 	ret
   818f4:	d503201f 	nop

00000000000818f8 <assertion_failed>:

// circle assert.cpp        
void assertion_failed (const char *pExpr, const char *pFile, unsigned nLine) {
   818f8:	aa0103e4 	mov	x4, x1
   818fc:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
    printf("assertion failed: %s at %s:%u\n", pExpr, pFile, nLine); 
   81900:	aa0003e1 	mov	x1, x0
   81904:	2a0203e3 	mov	w3, w2
   81908:	aa0403e2 	mov	x2, x4
void assertion_failed (const char *pExpr, const char *pFile, unsigned nLine) {
   8190c:	910003fd 	mov	x29, sp
    printf("assertion failed: %s at %s:%u\n", pExpr, pFile, nLine); 
   81910:	b0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   81914:	911a4000 	add	x0, x0, #0x690
   81918:	97ffff28 	bl	815b8 <tfp_printf>
    panic("kernel hangs"); 
   8191c:	b0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   81920:	911ac000 	add	x0, x0, #0x6b0
   81924:	97ffffab 	bl	817d0 <panic>

0000000000081928 <memset>:

/* c: the fill value (byte); n: size, in bytes */
void *memset(void *dst, int c, uint n) {
    char *cdst = (char *)dst;
    int i;
    for (i = 0; i < n; i++) {
   81928:	34000122 	cbz	w2, 8194c <memset+0x24>
   8192c:	51000442 	sub	w2, w2, #0x1
   81930:	12001c23 	and	w3, w1, #0xff
   81934:	91000442 	add	x2, x2, #0x1
   81938:	aa0003e1 	mov	x1, x0
   8193c:	8b000042 	add	x2, x2, x0
        cdst[i] = c;
   81940:	38001423 	strb	w3, [x1], #1
    for (i = 0; i < n; i++) {
   81944:	eb02003f 	cmp	x1, x2
   81948:	54ffffc1 	b.ne	81940 <memset+0x18>  // b.any
    }
    return dst;
}
   8194c:	d65f03c0 	ret

0000000000081950 <memzero>:
    for (i = 0; i < n; i++) {
   81950:	34000101 	cbz	w1, 81970 <memzero+0x20>
   81954:	51000421 	sub	w1, w1, #0x1
   81958:	8b010002 	add	x2, x0, x1
   8195c:	d503201f 	nop
        cdst[i] = c;
   81960:	3900001f 	strb	wzr, [x0]
    for (i = 0; i < n; i++) {
   81964:	eb02001f 	cmp	x0, x2
   81968:	91000400 	add	x0, x0, #0x1
   8196c:	54ffffa1 	b.ne	81960 <memzero+0x10>  // b.any

void memzero(void *dst, uint n) {
    memset(dst, 0, n);
}
   81970:	d65f03c0 	ret
   81974:	d503201f 	nop

0000000000081978 <memcmp>:
int memcmp(const void *v1, const void *v2, uint n) {
    const uchar *s1, *s2;

    s1 = v1;
    s2 = v2;
    while (n-- > 0) {
   81978:	51000446 	sub	w6, w2, #0x1
   8197c:	340001a2 	cbz	w2, 819b0 <memcmp+0x38>
   81980:	d2800002 	mov	x2, #0x0                   	// #0
   81984:	14000004 	b	81994 <memcmp+0x1c>
   81988:	eb0200df 	cmp	x6, x2
   8198c:	aa0503e2 	mov	x2, x5
   81990:	54000100 	b.eq	819b0 <memcmp+0x38>  // b.none
        if (*s1 != *s2)
   81994:	38626803 	ldrb	w3, [x0, x2]
   81998:	91000445 	add	x5, x2, #0x1
   8199c:	38626824 	ldrb	w4, [x1, x2]
   819a0:	6b04007f 	cmp	w3, w4
   819a4:	54ffff20 	b.eq	81988 <memcmp+0x10>  // b.none
            return *s1 - *s2;
   819a8:	4b040060 	sub	w0, w3, w4
        s1++, s2++;
    }

    return 0;
}
   819ac:	d65f03c0 	ret
    return 0;
   819b0:	52800000 	mov	w0, #0x0                   	// #0
}
   819b4:	d65f03c0 	ret

00000000000819b8 <memmove>:
void *
memmove(void *dst, const void *src, uint n) {
    const char *s;
    char *d;

    if (n == 0)
   819b8:	34000162 	cbz	w2, 819e4 <memmove+0x2c>
        return dst;

    s = src;
    d = dst;
    if (s < d && s + n > d) {
   819bc:	eb00003f 	cmp	x1, x0
   819c0:	51000445 	sub	w5, w2, #0x1
   819c4:	54000123 	b.cc	819e8 <memmove+0x30>  // b.lo, b.ul, b.last
memmove(void *dst, const void *src, uint n) {
   819c8:	d2800002 	mov	x2, #0x0                   	// #0
   819cc:	d503201f 	nop
        d += n;
        while (n-- > 0)
            *--d = *--s;
    } else
        while (n-- > 0)
            *d++ = *s++;
   819d0:	38626824 	ldrb	w4, [x1, x2]
        while (n-- > 0)
   819d4:	eb0200bf 	cmp	x5, x2
            *d++ = *s++;
   819d8:	38226804 	strb	w4, [x0, x2]
        while (n-- > 0)
   819dc:	91000442 	add	x2, x2, #0x1
   819e0:	54ffff81 	b.ne	819d0 <memmove+0x18>  // b.any

    return dst;
}
   819e4:	d65f03c0 	ret
    if (s < d && s + n > d) {
   819e8:	2a0203e2 	mov	w2, w2
   819ec:	8b020024 	add	x4, x1, x2
   819f0:	eb00009f 	cmp	x4, x0
   819f4:	54fffea9 	b.ls	819c8 <memmove+0x10>  // b.plast
        d += n;
   819f8:	92800021 	mov	x1, #0xfffffffffffffffe    	// #-2
   819fc:	8b020002 	add	x2, x0, x2
        while (n-- > 0)
   81a00:	cb254025 	sub	x5, x1, w5, uxtw
        d += n;
   81a04:	92800001 	mov	x1, #0xffffffffffffffff    	// #-1
            *--d = *--s;
   81a08:	38616883 	ldrb	w3, [x4, x1]
   81a0c:	38216843 	strb	w3, [x2, x1]
        while (n-- > 0)
   81a10:	d1000421 	sub	x1, x1, #0x1
   81a14:	eb0100bf 	cmp	x5, x1
   81a18:	54ffff81 	b.ne	81a08 <memmove+0x50>  // b.any
}
   81a1c:	d65f03c0 	ret

0000000000081a20 <memcpy>:
// memcpy exists to placate GCC.  Use memmove.
// NB: gcc will gen code to invoke memcpy for struct assignment. so the
// func below must be right (e.g. cannot assume any alignment)
void *
memcpy(void *dst, const void *src, uint n) {
    return memmove(dst, src, n);
   81a20:	17ffffe6 	b	819b8 <memmove>
   81a24:	d503201f 	nop

0000000000081a28 <strncmp>:
}

int strncmp(const char *p, const char *q, uint n) {
    while (n > 0 && *p && *p == *q)
   81a28:	340001e2 	cbz	w2, 81a64 <strncmp+0x3c>
   81a2c:	51000446 	sub	w6, w2, #0x1
   81a30:	d2800002 	mov	x2, #0x0                   	// #0
   81a34:	14000005 	b	81a48 <strncmp+0x20>
   81a38:	54000121 	b.ne	81a5c <strncmp+0x34>  // b.any
   81a3c:	eb0200df 	cmp	x6, x2
   81a40:	aa0503e2 	mov	x2, x5
   81a44:	54000100 	b.eq	81a64 <strncmp+0x3c>  // b.none
   81a48:	38626803 	ldrb	w3, [x0, x2]
   81a4c:	91000445 	add	x5, x2, #0x1
   81a50:	38626824 	ldrb	w4, [x1, x2]
   81a54:	6b04007f 	cmp	w3, w4
   81a58:	35ffff03 	cbnz	w3, 81a38 <strncmp+0x10>
        n--, p++, q++;
    if (n == 0)
        return 0;
    return (uchar)*p - (uchar)*q;
   81a5c:	4b040060 	sub	w0, w3, w4
}
   81a60:	d65f03c0 	ret
        return 0;
   81a64:	52800000 	mov	w0, #0x0                   	// #0
}
   81a68:	d65f03c0 	ret
   81a6c:	d503201f 	nop

0000000000081a70 <strncpy>:
char *
strncpy(char *s, const char *t, int n) {
    char *os;

    os = s;
    while (n-- > 0 && (*s++ = *t++) != 0)
   81a70:	aa0103e5 	mov	x5, x1
   81a74:	aa0003e1 	mov	x1, x0
   81a78:	14000004 	b	81a88 <strncpy+0x18>
   81a7c:	384014a4 	ldrb	w4, [x5], #1
   81a80:	38001424 	strb	w4, [x1], #1
   81a84:	340000a4 	cbz	w4, 81a98 <strncpy+0x28>
   81a88:	2a0203e3 	mov	w3, w2
   81a8c:	51000442 	sub	w2, w2, #0x1
   81a90:	7100007f 	cmp	w3, #0x0
   81a94:	54ffff4c 	b.gt	81a7c <strncpy+0xc>
        ;
    while (n-- > 0)
   81a98:	7100005f 	cmp	w2, #0x0
   81a9c:	0b010063 	add	w3, w3, w1
   81aa0:	540000ed 	b.le	81abc <strncpy+0x4c>
   81aa4:	d503201f 	nop
        *s++ = 0;
   81aa8:	3800143f 	strb	wzr, [x1], #1
    while (n-- > 0)
   81aac:	2a2103e2 	mvn	w2, w1
   81ab0:	0b030042 	add	w2, w2, w3
   81ab4:	7100005f 	cmp	w2, #0x0
   81ab8:	54ffff8c 	b.gt	81aa8 <strncpy+0x38>
    return os;
}
   81abc:	d65f03c0 	ret

0000000000081ac0 <safestrcpy>:
char *
safestrcpy(char *s, const char *t, int n) {
    char *os;

    os = s;
    if (n <= 0)
   81ac0:	7100005f 	cmp	w2, #0x0
   81ac4:	5400016d 	b.le	81af0 <safestrcpy+0x30>
   81ac8:	51000442 	sub	w2, w2, #0x1
   81acc:	aa0003e3 	mov	x3, x0
   81ad0:	8b020024 	add	x4, x1, x2
   81ad4:	14000004 	b	81ae4 <safestrcpy+0x24>
        return os;
    while (--n > 0 && (*s++ = *t++) != 0)
   81ad8:	38401422 	ldrb	w2, [x1], #1
   81adc:	38001462 	strb	w2, [x3], #1
   81ae0:	34000062 	cbz	w2, 81aec <safestrcpy+0x2c>
   81ae4:	eb04003f 	cmp	x1, x4
   81ae8:	54ffff81 	b.ne	81ad8 <safestrcpy+0x18>  // b.any
        ;
    *s = 0;
   81aec:	3900007f 	strb	wzr, [x3]
    return os;
}
   81af0:	d65f03c0 	ret
   81af4:	d503201f 	nop

0000000000081af8 <strlen>:

int strlen(const char *s) {
    int n;

    for (n = 0; s[n]; n++)
   81af8:	39400001 	ldrb	w1, [x0]
   81afc:	34000101 	cbz	w1, 81b1c <strlen+0x24>
   81b00:	d1000403 	sub	x3, x0, #0x1
   81b04:	d2800021 	mov	x1, #0x1                   	// #1
   81b08:	2a0103e0 	mov	w0, w1
   81b0c:	91000421 	add	x1, x1, #0x1
   81b10:	38616862 	ldrb	w2, [x3, x1]
   81b14:	35ffffa2 	cbnz	w2, 81b08 <strlen+0x10>
        ;
    return n;
}
   81b18:	d65f03c0 	ret
    for (n = 0; s[n]; n++)
   81b1c:	52800000 	mov	w0, #0x0                   	// #0
}
   81b20:	d65f03c0 	ret
   81b24:	d503201f 	nop

0000000000081b28 <atoi>:

int atoi(const char *s) {
    int n;
    n = 0;
    while ('0' <= *s && *s <= '9')
   81b28:	39400002 	ldrb	w2, [x0]
int atoi(const char *s) {
   81b2c:	aa0003e3 	mov	x3, x0
    while ('0' <= *s && *s <= '9')
   81b30:	5100c040 	sub	w0, w2, #0x30
   81b34:	12001c00 	and	w0, w0, #0xff
   81b38:	7100241f 	cmp	w0, #0x9
    n = 0;
   81b3c:	52800000 	mov	w0, #0x0                   	// #0
    while ('0' <= *s && *s <= '9')
   81b40:	54000148 	b.hi	81b68 <atoi+0x40>  // b.pmore
   81b44:	d503201f 	nop
        n = n * 10 + *s++ - '0';
   81b48:	0b000800 	add	w0, w0, w0, lsl #2
   81b4c:	0b000440 	add	w0, w2, w0, lsl #1
    while ('0' <= *s && *s <= '9')
   81b50:	38401c62 	ldrb	w2, [x3, #1]!
        n = n * 10 + *s++ - '0';
   81b54:	5100c000 	sub	w0, w0, #0x30
    while ('0' <= *s && *s <= '9')
   81b58:	5100c041 	sub	w1, w2, #0x30
   81b5c:	12001c21 	and	w1, w1, #0xff
   81b60:	7100243f 	cmp	w1, #0x9
   81b64:	54ffff29 	b.ls	81b48 <atoi+0x20>  // b.plast
    return n;
}
   81b68:	d65f03c0 	ret
   81b6c:	00000000 	udf	#0

0000000000081b70 <initlock>:

// #define SPINLOCK_DEBUG 1

void initlock(struct spinlock *lk, char *name) {
    lk->name = name;
    lk->locked = 0;
   81b70:	b900001f 	str	wzr, [x0]
    lk->cpu = 0;
   81b74:	a900fc01 	stp	x1, xzr, [x0, #8]
}
   81b78:	d65f03c0 	ret
   81b7c:	d503201f 	nop

0000000000081b80 <holding>:
// Check whether this cpu is holding the lock.
// Interrupts must be off.
int holding(struct spinlock *lk) {
    int r;
    // W("%lx %s %d", (unsigned long)lk, lk->name, lk->locked);
    r = (lk->locked && lk->cpu == mycpu());
   81b80:	b9400001 	ldr	w1, [x0]
   81b84:	340000e1 	cbz	w1, 81ba0 <holding+0x20>
   81b88:	900000a1 	adrp	x1, 95000 <wordsworth.1725+0xee10>
   81b8c:	f9400802 	ldr	x2, [x0, #16]
   81b90:	f9478020 	ldr	x0, [x1, #3840]
   81b94:	eb00005f 	cmp	x2, x0
   81b98:	1a9f17e0 	cset	w0, eq	// eq = none
    return r;
}
   81b9c:	d65f03c0 	ret
    r = (lk->locked && lk->cpu == mycpu());
   81ba0:	52800000 	mov	w0, #0x0                   	// #0
}
   81ba4:	d65f03c0 	ret

0000000000081ba8 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.
//
// "intena" is the irq status (on/off) when noff (i.e. the "balance") is 0.
// hence, the irq status must be restored when noff reaches 0 again
void push_off(void) {
   81ba8:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   81bac:	910003fd 	mov	x29, sp
   81bb0:	f9000bf3 	str	x19, [sp, #16]
void irq_vector_init( void );    
void enable_irq( void ); 
void disable_irq( void );
int is_irq_masked(void); 
/*return 1 if irq enabled, 0 otherwise*/
static inline int intr_get(void) {return 1-is_irq_masked();}; 
   81bb4:	940010d1 	bl	85ef8 <is_irq_masked>
   81bb8:	2a0003f3 	mov	w19, w0
    int old = intr_get();

    disable_irq();
   81bbc:	940010cd 	bl	85ef0 <disable_irq>
    if (mycpu()->noff == 0)
   81bc0:	900000a1 	adrp	x1, 95000 <wordsworth.1725+0xee10>
   81bc4:	f9478023 	ldr	x3, [x1, #3840]
   81bc8:	b9400862 	ldr	w2, [x3, #8]
   81bcc:	35000082 	cbnz	w2, 81bdc <push_off+0x34>
   81bd0:	52800020 	mov	w0, #0x1                   	// #1
   81bd4:	4b130000 	sub	w0, w0, w19
        mycpu()->intena = old;
   81bd8:	b9000c60 	str	w0, [x3, #12]
    mycpu()->noff += 1;
   81bdc:	f9478021 	ldr	x1, [x1, #3840]
   81be0:	11000442 	add	w2, w2, #0x1
}
   81be4:	f9400bf3 	ldr	x19, [sp, #16]
    mycpu()->noff += 1;
   81be8:	b9000822 	str	w2, [x1, #8]
}
   81bec:	a8c27bfd 	ldp	x29, x30, [sp], #32
   81bf0:	d65f03c0 	ret
   81bf4:	d503201f 	nop

0000000000081bf8 <acquire>:
void acquire(struct spinlock *lk) {
   81bf8:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   81bfc:	910003fd 	mov	x29, sp
   81c00:	a90153f3 	stp	x19, x20, [sp, #16]
   81c04:	aa0003f3 	mov	x19, x0
   81c08:	900000b4 	adrp	x20, 95000 <wordsworth.1725+0xee10>
    push_off(); // disable interrupts to avoid deadlock.
   81c0c:	97ffffe7 	bl	81ba8 <push_off>
    if (!lk || holding(lk)) {
   81c10:	b4000273 	cbz	x19, 81c5c <acquire+0x64>
    r = (lk->locked && lk->cpu == mycpu());
   81c14:	b9400261 	ldr	w1, [x19]
   81c18:	900000b4 	adrp	x20, 95000 <wordsworth.1725+0xee10>
   81c1c:	34000101 	cbz	w1, 81c3c <acquire+0x44>
   81c20:	f9478280 	ldr	x0, [x20, #3840]
   81c24:	f9400a62 	ldr	x2, [x19, #16]
   81c28:	eb00005f 	cmp	x2, x0
   81c2c:	54000180 	b.eq	81c5c <acquire+0x64>  // b.none
    while (lk->locked == 1)
   81c30:	7100043f 	cmp	w1, #0x1
   81c34:	54000041 	b.ne	81c3c <acquire+0x44>  // b.any
   81c38:	14000000 	b	81c38 <acquire+0x40>
    lk->locked = 1;
   81c3c:	52800020 	mov	w0, #0x1                   	// #1
   81c40:	b9000260 	str	w0, [x19]
    __sync_synchronize();
   81c44:	d5033bbf 	dmb	ish
    lk->cpu = mycpu();
   81c48:	f9478294 	ldr	x20, [x20, #3840]
   81c4c:	f9000a74 	str	x20, [x19, #16]
}
   81c50:	a94153f3 	ldp	x19, x20, [sp, #16]
   81c54:	a8c27bfd 	ldp	x29, x30, [sp], #32
   81c58:	d65f03c0 	ret
        printf("%s ", lk->name);
   81c5c:	f9400661 	ldr	x1, [x19, #8]
   81c60:	b0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   81c64:	911b0000 	add	x0, x0, #0x6c0
   81c68:	97fffe54 	bl	815b8 <tfp_printf>
        panic("acquire");
   81c6c:	b0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   81c70:	911b2000 	add	x0, x0, #0x6c8
   81c74:	97fffed7 	bl	817d0 <panic>
   81c78:	b9400261 	ldr	w1, [x19]
   81c7c:	17ffffed 	b	81c30 <acquire+0x38>

0000000000081c80 <pop_off>:

// pop_off must be done with a positive counter (noff)
//  i.e. it's a bug if irq is already enabled and then pop_off
void pop_off(void) {
   81c80:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   81c84:	910003fd 	mov	x29, sp
   81c88:	a90153f3 	stp	x19, x20, [sp, #16]
   81c8c:	9400109b 	bl	85ef8 <is_irq_masked>
    struct cpu *c = mycpu();
    if (intr_get())
   81c90:	7100041f 	cmp	w0, #0x1
   81c94:	54000080 	b.eq	81ca4 <pop_off+0x24>  // b.none
        panic("pop_off - interruptible");
   81c98:	b0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   81c9c:	911b4000 	add	x0, x0, #0x6d0
   81ca0:	97fffecc 	bl	817d0 <panic>
    if (c->noff < 1)
   81ca4:	900000b3 	adrp	x19, 95000 <wordsworth.1725+0xee10>
   81ca8:	f9478274 	ldr	x20, [x19, #3840]
   81cac:	b9400a80 	ldr	w0, [x20, #8]
   81cb0:	7100001f 	cmp	w0, #0x0
   81cb4:	5400014d 	b.le	81cdc <pop_off+0x5c>
        panic("pop_off");
    c->noff -= 1;
   81cb8:	f9478273 	ldr	x19, [x19, #3840]
   81cbc:	51000400 	sub	w0, w0, #0x1
   81cc0:	b9000a60 	str	w0, [x19, #8]
    if (c->noff == 0 && c->intena)
   81cc4:	35000060 	cbnz	w0, 81cd0 <pop_off+0x50>
   81cc8:	b9400e60 	ldr	w0, [x19, #12]
   81ccc:	35000120 	cbnz	w0, 81cf0 <pop_off+0x70>
        enable_irq();
}
   81cd0:	a94153f3 	ldp	x19, x20, [sp, #16]
   81cd4:	a8c27bfd 	ldp	x29, x30, [sp], #32
   81cd8:	d65f03c0 	ret
        panic("pop_off");
   81cdc:	b0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   81ce0:	911ba000 	add	x0, x0, #0x6e8
   81ce4:	97fffebb 	bl	817d0 <panic>
   81ce8:	b9400a80 	ldr	w0, [x20, #8]
   81cec:	17fffff3 	b	81cb8 <pop_off+0x38>
}
   81cf0:	a94153f3 	ldp	x19, x20, [sp, #16]
   81cf4:	a8c27bfd 	ldp	x29, x30, [sp], #32
        enable_irq();
   81cf8:	1400107c 	b	85ee8 <enable_irq>
   81cfc:	d503201f 	nop

0000000000081d00 <release>:
void release(struct spinlock *lk) {
   81d00:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   81d04:	910003fd 	mov	x29, sp
   81d08:	f9000bf3 	str	x19, [sp, #16]
   81d0c:	aa0003f3 	mov	x19, x0
    if (!lk || !holding(lk)) {
   81d10:	b4000060 	cbz	x0, 81d1c <release+0x1c>
    r = (lk->locked && lk->cpu == mycpu());
   81d14:	b9400000 	ldr	w0, [x0]
   81d18:	350001c0 	cbnz	w0, 81d50 <release+0x50>
        printf("%s ", lk->name);
   81d1c:	f9400661 	ldr	x1, [x19, #8]
   81d20:	b0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   81d24:	911b0000 	add	x0, x0, #0x6c0
   81d28:	97fffe24 	bl	815b8 <tfp_printf>
        panic("release");
   81d2c:	b0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   81d30:	911bc000 	add	x0, x0, #0x6f0
   81d34:	97fffea7 	bl	817d0 <panic>
    lk->cpu = 0;
   81d38:	f9000a7f 	str	xzr, [x19, #16]
    __sync_synchronize();
   81d3c:	d5033bbf 	dmb	ish
    lk->locked = 0;
   81d40:	b900027f 	str	wzr, [x19]
}
   81d44:	f9400bf3 	ldr	x19, [sp, #16]
   81d48:	a8c27bfd 	ldp	x29, x30, [sp], #32
    pop_off();
   81d4c:	17ffffcd 	b	81c80 <pop_off>
    r = (lk->locked && lk->cpu == mycpu());
   81d50:	900000a0 	adrp	x0, 95000 <wordsworth.1725+0xee10>
   81d54:	f9400a61 	ldr	x1, [x19, #16]
   81d58:	f9478000 	ldr	x0, [x0, #3840]
   81d5c:	eb00003f 	cmp	x1, x0
   81d60:	54fffde1 	b.ne	81d1c <release+0x1c>  // b.any
    lk->cpu = 0;
   81d64:	f9000a7f 	str	xzr, [x19, #16]
    __sync_synchronize();
   81d68:	d5033bbf 	dmb	ish
    lk->locked = 0;
   81d6c:	b900027f 	str	wzr, [x19]
}
   81d70:	f9400bf3 	ldr	x19, [sp, #16]
   81d74:	a8c27bfd 	ldp	x29, x30, [sp], #32
    pop_off();
   81d78:	17ffffc2 	b	81c80 <pop_off>
   81d7c:	00000000 	udf	#0

0000000000081d80 <adjust_sys_timer>:

// we have added/removed a virt timer, now adjust the phys timer accordingly
// caller must hold timerlock
// return 0 on success
static int adjust_sys_timer(void)
{
   81d80:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
   81d84:	910003fd 	mov	x29, sp
   81d88:	a90363f7 	stp	x23, x24, [sp, #48]
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   81d8c:	d2860118 	mov	x24, #0x3008                	// #12296
   81d90:	d2860097 	mov	x23, #0x3004                	// #12292
   81d94:	f2a7e018 	movk	x24, #0x3f00, lsl #16
   81d98:	f2a7e017 	movk	x23, #0x3f00, lsl #16
{
   81d9c:	a90153f3 	stp	x19, x20, [sp, #16]
   81da0:	b00000b3 	adrp	x19, 96000 <stdout_putf>
   81da4:	d2800014 	mov	x20, #0x0                   	// #0
   81da8:	91004273 	add	x19, x19, #0x10
   81dac:	a9025bf5 	stp	x21, x22, [sp, #32]
	unsigned long next = (unsigned long)-1; // upcoming firing time, to be determined
   81db0:	92800015 	mov	x21, #0xffffffffffffffff    	// #-1
				(*timers[tt].handler)(tt, timers[tt].param, timers[tt].context);
				timers[tt].handler = 0; 
			} else 
				/* give "next" a bit slack so current_counter() won't exceed
				"next" before we retuen from this function */
				next = timers[tt].elapseat + 10*1000 /*10ms*/;
   81db4:	d284e216 	mov	x22, #0x2710                	// #10000
   81db8:	14000008 	b	81dd8 <adjust_sys_timer+0x58>
				(*timers[tt].handler)(tt, timers[tt].param, timers[tt].context);
   81dbc:	a9410a61 	ldp	x1, x2, [x19, #16]
   81dc0:	d63f0060 	blr	x3
				timers[tt].handler = 0; 
   81dc4:	f900027f 	str	xzr, [x19]
	for (int tt = 0; tt < N_TIMERS; tt++) {
   81dc8:	91000694 	add	x20, x20, #0x1
   81dcc:	91008273 	add	x19, x19, #0x20
   81dd0:	f100529f 	cmp	x20, #0x14
   81dd4:	54000240 	b.eq	81e1c <adjust_sys_timer+0x9c>  // b.none
		if (!timers[tt].handler)
   81dd8:	f9400263 	ldr	x3, [x19]
   81ddc:	b4ffff63 	cbz	x3, 81dc8 <adjust_sys_timer+0x48>
		if (timers[tt].elapseat < next) {
   81de0:	f9400661 	ldr	x1, [x19, #8]
   81de4:	eb15003f 	cmp	x1, x21
   81de8:	54ffff02 	b.cs	81dc8 <adjust_sys_timer+0x48>  // b.hs, b.nlast
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   81dec:	b9400302 	ldr	w2, [x24]
				(*timers[tt].handler)(tt, timers[tt].param, timers[tt].context);
   81df0:	aa1403e0 	mov	x0, x20
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   81df4:	b94002e4 	ldr	w4, [x23]
   81df8:	2a0403e4 	mov	w4, w4
   81dfc:	aa028082 	orr	x2, x4, x2, lsl #32
			if (timers[tt].elapseat < current_counter()) {
   81e00:	eb02003f 	cmp	x1, x2
   81e04:	54fffdc3 	b.cc	81dbc <adjust_sys_timer+0x3c>  // b.lo, b.ul, b.last
   81e08:	91000694 	add	x20, x20, #0x1
				next = timers[tt].elapseat + 10*1000 /*10ms*/;
   81e0c:	8b160035 	add	x21, x1, x22
	for (int tt = 0; tt < N_TIMERS; tt++) {
   81e10:	91008273 	add	x19, x19, #0x20
   81e14:	f100529f 	cmp	x20, #0x14
   81e18:	54fffe01 	b.ne	81dd8 <adjust_sys_timer+0x58>  // b.any
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   81e1c:	d2860100 	mov	x0, #0x3008                	// #12296
   81e20:	d2860081 	mov	x1, #0x3004                	// #12292
   81e24:	f2a7e000 	movk	x0, #0x3f00, lsl #16
   81e28:	f2a7e001 	movk	x1, #0x3f00, lsl #16
   81e2c:	b9400000 	ldr	w0, [x0]
   81e30:	b9400021 	ldr	w1, [x1]
   81e34:	2a0103e1 	mov	w1, w1
   81e38:	aa008020 	orr	x0, x1, x0, lsl #32
		}
	}

	// a known bug (TBD. may occur: when qemu is very slow, or on actual hw
	// timer expired, but handler not called?? should we handle it?
	BUG_ON(current_counter() > next); 
   81e3c:	eb0002bf 	cmp	x21, x0
   81e40:	54000183 	b.cc	81e70 <adjust_sys_timer+0xf0>  // b.lo, b.ul, b.last

	// if no valid handlers, we leave TIMER_C1 as is. it will trigger a timer
	// irq when wrapping around (~4000 sec later). this is fine as our isr
	// compares 64bit counters. 
	if (next == 0xFFFFFFFFFFFFFFFF) 
   81e44:	b10006bf 	cmn	x21, #0x1
   81e48:	54000080 	b.eq	81e58 <adjust_sys_timer+0xd8>  // b.none
		return 0; 

	// the compare reg is only 32 bits so we have to ignore the high 32 bits of
	// the counter. this is ok even if the low 32 bits have to wrap around 
	// in order to match TIMER_C1 (cf the isr)	
	put32(TIMER_C1, (unsigned)next);  
   81e4c:	d2860200 	mov	x0, #0x3010                	// #12304
   81e50:	f2a7e000 	movk	x0, #0x3f00, lsl #16
   81e54:	b9000015 	str	w21, [x0]

	return 0; 
}
   81e58:	52800000 	mov	w0, #0x0                   	// #0
   81e5c:	a94153f3 	ldp	x19, x20, [sp, #16]
   81e60:	a9425bf5 	ldp	x21, x22, [sp, #32]
   81e64:	a94363f7 	ldp	x23, x24, [sp, #48]
   81e68:	a8c47bfd 	ldp	x29, x30, [sp], #64
   81e6c:	d65f03c0 	ret
	BUG_ON(current_counter() > next); 
   81e70:	b0000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   81e74:	b0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   81e78:	911be021 	add	x1, x1, #0x6f8
   81e7c:	911c0000 	add	x0, x0, #0x700
   81e80:	52801ae2 	mov	w2, #0xd7                  	// #215
   81e84:	97fffe9d 	bl	818f8 <assertion_failed>
	if (next == 0xFFFFFFFFFFFFFFFF) 
   81e88:	17fffff1 	b	81e4c <adjust_sys_timer+0xcc>
   81e8c:	d503201f 	nop

0000000000081e90 <generic_timer_init>:
	asm volatile("msr CNTP_CTL_EL0, %0" : : "r"(1));
   81e90:	52800020 	mov	w0, #0x1                   	// #1
   81e94:	d51be220 	msr	cntp_ctl_el0, x0
	generic_timer_reset(interval);	// kickoff 1st time firing
   81e98:	900000a0 	adrp	x0, 95000 <wordsworth.1725+0xee10>
	asm volatile("msr CNTP_TVAL_EL0, %0" : : "r"(intv));  // TVAL is 32bit, signed
   81e9c:	b9456000 	ldr	w0, [x0, #1376]
   81ea0:	d51be200 	msr	cntp_tval_el0, x0
}
   81ea4:	d65f03c0 	ret

0000000000081ea8 <handle_generic_timer_irq>:
	generic_timer_reset(interval);
   81ea8:	900000a0 	adrp	x0, 95000 <wordsworth.1725+0xee10>
	asm volatile("msr CNTP_TVAL_EL0, %0" : : "r"(intv));  // TVAL is 32bit, signed
   81eac:	b9456000 	ldr	w0, [x0, #1376]
   81eb0:	d51be200 	msr	cntp_tval_el0, x0
	timer_tick();
   81eb4:	14000751 	b	83bf8 <timer_tick>

0000000000081eb8 <ms_delay>:
	delay(cycles_per_ms * ms); 
   81eb8:	52944bc1 	mov	w1, #0xa25e                	// #41566
   81ebc:	72a000c1 	movk	w1, #0x6, lsl #16
   81ec0:	1b017c00 	mul	w0, w0, w1
   81ec4:	1400102f 	b	85f80 <delay>

0000000000081ec8 <us_delay>:
	delay(cycles_per_us * us); 
   81ec8:	52803641 	mov	w1, #0x1b2                 	// #434
   81ecc:	1b017c00 	mul	w0, w0, w1
   81ed0:	1400102c 	b	85f80 <delay>
   81ed4:	d503201f 	nop

0000000000081ed8 <current_time>:
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   81ed8:	d2860102 	mov	x2, #0x3008                	// #12296
   81edc:	d2860085 	mov	x5, #0x3004                	// #12292
   81ee0:	f2a7e002 	movk	x2, #0x3f00, lsl #16
   81ee4:	f2a7e005 	movk	x5, #0x3f00, lsl #16
	*sec =  (unsigned) (cur / TICKPERSEC); 
   81ee8:	d2869b63 	mov	x3, #0x34db                	// #13531
	cur -= (*sec) * TICKPERSEC; 
   81eec:	52884804 	mov	w4, #0x4240                	// #16960
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   81ef0:	b9400042 	ldr	w2, [x2]
	*sec =  (unsigned) (cur / TICKPERSEC); 
   81ef4:	f2baf6c3 	movk	x3, #0xd7b6, lsl #16
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   81ef8:	b94000a5 	ldr	w5, [x5]
	*sec =  (unsigned) (cur / TICKPERSEC); 
   81efc:	f2dbd043 	movk	x3, #0xde82, lsl #32
   81f00:	f2e86363 	movk	x3, #0x431b, lsl #48
	cur -= (*sec) * TICKPERSEC; 
   81f04:	72a001e4 	movk	w4, #0xf, lsl #16
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   81f08:	2a0503e5 	mov	w5, w5
	*msec = (unsigned) (cur / TICKPERMS);	
   81f0c:	d29ef9e6 	mov	x6, #0xf7cf                	// #63439
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   81f10:	aa0280a2 	orr	x2, x5, x2, lsl #32
	*msec = (unsigned) (cur / TICKPERMS);	
   81f14:	f2bc6a66 	movk	x6, #0xe353, lsl #16
   81f18:	f2d374a6 	movk	x6, #0x9ba5, lsl #32
   81f1c:	f2e41886 	movk	x6, #0x20c4, lsl #48
	*sec =  (unsigned) (cur / TICKPERSEC); 
   81f20:	9bc37c43 	umulh	x3, x2, x3
   81f24:	d352fc63 	lsr	x3, x3, #18
   81f28:	b9000003 	str	w3, [x0]
	cur -= (*sec) * TICKPERSEC; 
   81f2c:	1b037c83 	mul	w3, w4, w3
   81f30:	cb234042 	sub	x2, x2, w3, uxtw
	*msec = (unsigned) (cur / TICKPERMS);	
   81f34:	d343fc42 	lsr	x2, x2, #3
   81f38:	9bc67c42 	umulh	x2, x2, x6
   81f3c:	d344fc42 	lsr	x2, x2, #4
   81f40:	b9000022 	str	w2, [x1]
}
   81f44:	d65f03c0 	ret

0000000000081f48 <sys_timer_init>:
{
   81f48:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
	initlock(&timerlock, "timer"); 
   81f4c:	900000a0 	adrp	x0, 95000 <wordsworth.1725+0xee10>
   81f50:	b0000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
{
   81f54:	910003fd 	mov	x29, sp
	initlock(&timerlock, "timer"); 
   81f58:	f9476400 	ldr	x0, [x0, #3784]
   81f5c:	911c8021 	add	x1, x1, #0x720
   81f60:	97ffff04 	bl	81b70 <initlock>
}
   81f64:	a8c17bfd 	ldp	x29, x30, [sp], #16
	memzero(timers, sizeof(timers)); 	// all field zeros	
   81f68:	b00000a0 	adrp	x0, 96000 <stdout_putf>
   81f6c:	52805001 	mov	w1, #0x280                 	// #640
   81f70:	91004000 	add	x0, x0, #0x10
   81f74:	17fffe77 	b	81950 <memzero>

0000000000081f78 <ktimer_start>:
	adjust_sys_timer(); 
	return t; 
}

int ktimer_start(unsigned delayms, TKernelTimerHandler *handler, 
		void *para, void *context) {
   81f78:	a9ba7bfd 	stp	x29, x30, [sp, #-96]!
   81f7c:	910003fd 	mov	x29, sp
   81f80:	a90363f7 	stp	x23, x24, [sp, #48]
	int ret;
	acquire(&timerlock); 
   81f84:	900000b7 	adrp	x23, 95000 <wordsworth.1725+0xee10>
		void *para, void *context) {
   81f88:	2a0003f8 	mov	w24, w0
	acquire(&timerlock); 
   81f8c:	f94766e0 	ldr	x0, [x23, #3784]
		void *para, void *context) {
   81f90:	a90153f3 	stp	x19, x20, [sp, #16]
   81f94:	aa0103f4 	mov	x20, x1
   81f98:	a9025bf5 	stp	x21, x22, [sp, #32]
   81f9c:	aa0203f5 	mov	x21, x2
   81fa0:	aa0303f6 	mov	x22, x3
   81fa4:	f90023f9 	str	x25, [sp, #64]
	acquire(&timerlock); 
   81fa8:	97ffff14 	bl	81bf8 <acquire>
	for (t = 0; t < N_TIMERS; t++) {
   81fac:	b00000b9 	adrp	x25, 96000 <stdout_putf>
   81fb0:	52800013 	mov	w19, #0x0                   	// #0
   81fb4:	91004320 	add	x0, x25, #0x10
   81fb8:	14000004 	b	81fc8 <ktimer_start+0x50>
   81fbc:	11000673 	add	w19, w19, #0x1
   81fc0:	7100527f 	cmp	w19, #0x14
   81fc4:	54000400 	b.eq	82044 <ktimer_start+0xcc>  // b.none
		if (timers[t].handler == 0) 
   81fc8:	f9400001 	ldr	x1, [x0]
   81fcc:	91008000 	add	x0, x0, #0x20
   81fd0:	b5ffff61 	cbnz	x1, 81fbc <ktimer_start+0x44>
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   81fd4:	d2860101 	mov	x1, #0x3008                	// #12296
   81fd8:	d2860080 	mov	x0, #0x3004                	// #12292
   81fdc:	f2a7e001 	movk	x1, #0x3f00, lsl #16
   81fe0:	f2a7e000 	movk	x0, #0x3f00, lsl #16
	BUG_ON(cur + TICKPERMS * delayms < cur); // 64bit counter wraps around??
   81fe4:	52807d04 	mov	w4, #0x3e8                 	// #1000
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   81fe8:	b9400025 	ldr	w5, [x1]
   81fec:	b9400001 	ldr	w1, [x0]
	BUG_ON(cur + TICKPERMS * delayms < cur); // 64bit counter wraps around??
   81ff0:	1b047f00 	mul	w0, w24, w4
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   81ff4:	2a0103e1 	mov	w1, w1
   81ff8:	aa058024 	orr	x4, x1, x5, lsl #32
   81ffc:	ab000084 	adds	x4, x4, x0
   82000:	54000322 	b.cs	82064 <ktimer_start+0xec>  // b.hs, b.nlast
	timers[t].handler = handler; 
   82004:	91004339 	add	x25, x25, #0x10
   82008:	d37b7e61 	ubfiz	x1, x19, #5, #32
   8200c:	8b010320 	add	x0, x25, x1
   82010:	f8216b34 	str	x20, [x25, x1]
	timers[t].param = para; 
   82014:	a900d404 	stp	x4, x21, [x0, #8]
	timers[t].context = context; 
   82018:	f9000c16 	str	x22, [x0, #24]
	adjust_sys_timer(); 
   8201c:	97ffff59 	bl	81d80 <adjust_sys_timer>
	ret = ktimer_start_nolock(delayms, handler, para, context); 
	release(&timerlock); 
   82020:	f94766e0 	ldr	x0, [x23, #3784]
   82024:	97ffff37 	bl	81d00 <release>
	return ret;
}
   82028:	2a1303e0 	mov	w0, w19
   8202c:	a94153f3 	ldp	x19, x20, [sp, #16]
   82030:	a9425bf5 	ldp	x21, x22, [sp, #32]
   82034:	a94363f7 	ldp	x23, x24, [sp, #48]
   82038:	f94023f9 	ldr	x25, [sp, #64]
   8203c:	a8c67bfd 	ldp	x29, x30, [sp], #96
   82040:	d65f03c0 	ret
		E("ktimer_start failed. # max timer reached"); 
   82044:	90000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   82048:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   8204c:	911be021 	add	x1, x1, #0x6f8
   82050:	911d6000 	add	x0, x0, #0x758
   82054:	52801ec2 	mov	w2, #0xf6                  	// #246
		return -1; 
   82058:	12800013 	mov	w19, #0xffffffff            	// #-1
		E("ktimer_start failed. # max timer reached"); 
   8205c:	97fffd57 	bl	815b8 <tfp_printf>
		return -1; 
   82060:	17fffff0 	b	82020 <ktimer_start+0xa8>
	BUG_ON(cur + TICKPERMS * delayms < cur); // 64bit counter wraps around??
   82064:	90000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   82068:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   8206c:	911be021 	add	x1, x1, #0x6f8
   82070:	911ca000 	add	x0, x0, #0x728
   82074:	52801f62 	mov	w2, #0xfb                  	// #251
   82078:	f9002fe4 	str	x4, [sp, #88]
   8207c:	97fffe1f 	bl	818f8 <assertion_failed>
   82080:	f9402fe4 	ldr	x4, [sp, #88]
   82084:	17ffffe0 	b	82004 <ktimer_start+0x8c>

0000000000082088 <ktimer_cancel>:
// return 0 on okay, -1 if no such timer/handler, 
//	-2 if already fired (will clean anyway)
int ktimer_cancel(int t) {
	unsigned long cur; 

	if (t < 0 || t >= N_TIMERS)
   82088:	71004c1f 	cmp	w0, #0x13
   8208c:	54000488 	b.hi	8211c <ktimer_cancel+0x94>  // b.pmore
int ktimer_cancel(int t) {
   82090:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   82094:	d2860101 	mov	x1, #0x3008                	// #12296
   82098:	f2a7e001 	movk	x1, #0x3f00, lsl #16
int ktimer_cancel(int t) {
   8209c:	910003fd 	mov	x29, sp
   820a0:	a90153f3 	stp	x19, x20, [sp, #16]
   820a4:	2a0003f3 	mov	w19, w0
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   820a8:	d2860080 	mov	x0, #0x3004                	// #12292
   820ac:	f2a7e000 	movk	x0, #0x3f00, lsl #16
   820b0:	b9400022 	ldr	w2, [x1]
		return -1; 

	cur = current_counter();
	acquire(&timerlock); 
   820b4:	f0000094 	adrp	x20, 95000 <wordsworth.1725+0xee10>
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   820b8:	b9400001 	ldr	w1, [x0]
	acquire(&timerlock); 
   820bc:	f9476694 	ldr	x20, [x20, #3784]
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   820c0:	2a0103e1 	mov	w1, w1
int ktimer_cancel(int t) {
   820c4:	f90013f5 	str	x21, [sp, #32]
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   820c8:	aa028035 	orr	x21, x1, x2, lsl #32
	acquire(&timerlock); 
   820cc:	aa1403e0 	mov	x0, x20
   820d0:	97fffeca 	bl	81bf8 <acquire>

	if (!timers[t].handler) {	// invalid handler
   820d4:	937b7e61 	sbfiz	x1, x19, #5, #32
   820d8:	900000a2 	adrp	x2, 96000 <stdout_putf>
   820dc:	91004042 	add	x2, x2, #0x10
   820e0:	8b010043 	add	x3, x2, x1
   820e4:	f8616840 	ldr	x0, [x2, x1]
   820e8:	b40002a0 	cbz	x0, 8213c <ktimer_cancel+0xb4>
		release(&timerlock); 
		return -1; 
	}

	if (timers[t].elapseat < cur) { // already fired? 
   820ec:	f9400460 	ldr	x0, [x3, #8]
   820f0:	eb15001f 	cmp	x0, x21
   820f4:	54000183 	b.cc	82124 <ktimer_cancel+0x9c>  // b.lo, b.ul, b.last
		timers[t].param = 0; 
		release(&timerlock); 
		return -2; 
	}

	timers[t].handler = 0; 
   820f8:	f821685f 	str	xzr, [x2, x1]

	adjust_sys_timer(); 	
   820fc:	97ffff21 	bl	81d80 <adjust_sys_timer>
	release(&timerlock);
   82100:	aa1403e0 	mov	x0, x20
   82104:	97fffeff 	bl	81d00 <release>

	return 0;  
   82108:	52800000 	mov	w0, #0x0                   	// #0
}
   8210c:	a94153f3 	ldp	x19, x20, [sp, #16]
   82110:	f94013f5 	ldr	x21, [sp, #32]
   82114:	a8c37bfd 	ldp	x29, x30, [sp], #48
   82118:	d65f03c0 	ret
		return -1; 
   8211c:	12800000 	mov	w0, #0xffffffff            	// #-1
}
   82120:	d65f03c0 	ret
		timers[t].handler = 0; 
   82124:	f821685f 	str	xzr, [x2, x1]
		release(&timerlock); 
   82128:	aa1403e0 	mov	x0, x20
		timers[t].context = 0; 
   8212c:	a9017c7f 	stp	xzr, xzr, [x3, #16]
		release(&timerlock); 
   82130:	97fffef4 	bl	81d00 <release>
		return -2; 
   82134:	12800020 	mov	w0, #0xfffffffe            	// #-2
   82138:	17fffff5 	b	8210c <ktimer_cancel+0x84>
		release(&timerlock); 
   8213c:	aa1403e0 	mov	x0, x20
   82140:	97fffef0 	bl	81d00 <release>
		return -1; 
   82144:	12800000 	mov	w0, #0xffffffff            	// #-1
   82148:	17fffff1 	b	8210c <ktimer_cancel+0x84>
   8214c:	d503201f 	nop

0000000000082150 <sys_timer_irq>:
void sys_timer_irq(void) 
{
	V("called");	

	// timer1 must have pending match. below could happen under high load. why?
	BUG_ON(!(get32(TIMER_CS) & TIMER_CS_M1));  
   82150:	d2860000 	mov	x0, #0x3000                	// #12288
{
   82154:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
	BUG_ON(!(get32(TIMER_CS) & TIMER_CS_M1));  
   82158:	f2a7e000 	movk	x0, #0x3f00, lsl #16
{
   8215c:	910003fd 	mov	x29, sp
	BUG_ON(!(get32(TIMER_CS) & TIMER_CS_M1));  
   82160:	b9400000 	ldr	w0, [x0]
{
   82164:	a90153f3 	stp	x19, x20, [sp, #16]
   82168:	a9025bf5 	stp	x21, x22, [sp, #32]
	BUG_ON(!(get32(TIMER_CS) & TIMER_CS_M1));  
   8216c:	360804c0 	tbz	w0, #1, 82204 <sys_timer_irq+0xb4>
	put32(TIMER_CS, TIMER_CS_M1);	// clear timer1 match
   82170:	d2860000 	mov	x0, #0x3000                	// #12288
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   82174:	d2860102 	mov	x2, #0x3008                	// #12296
	put32(TIMER_CS, TIMER_CS_M1);	// clear timer1 match
   82178:	f2a7e000 	movk	x0, #0x3f00, lsl #16
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   8217c:	d2860081 	mov	x1, #0x3004                	// #12292
	put32(TIMER_CS, TIMER_CS_M1);	// clear timer1 match
   82180:	52800043 	mov	w3, #0x2                   	// #2
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   82184:	f2a7e002 	movk	x2, #0x3f00, lsl #16
   82188:	f2a7e001 	movk	x1, #0x3f00, lsl #16
	put32(TIMER_CS, TIMER_CS_M1);	// clear timer1 match
   8218c:	b9000003 	str	w3, [x0]

	unsigned long cur = current_counter(); 

	acquire(&timerlock); 
   82190:	f0000096 	adrp	x22, 95000 <wordsworth.1725+0xee10>
   82194:	900000b3 	adrp	x19, 96000 <stdout_putf>
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   82198:	b9400055 	ldr	w21, [x2]
   8219c:	91004273 	add	x19, x19, #0x10
   821a0:	b9400021 	ldr	w1, [x1]
	acquire(&timerlock); 
   821a4:	d2800014 	mov	x20, #0x0                   	// #0
   821a8:	f94766c0 	ldr	x0, [x22, #3784]
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   821ac:	2a0103e1 	mov	w1, w1
   821b0:	aa158035 	orr	x21, x1, x21, lsl #32
	acquire(&timerlock); 
   821b4:	97fffe91 	bl	81bf8 <acquire>
	for (int t = 0; t < N_TIMERS; t++) {
		TKernelTimerHandler *h = timers[t].handler; 
   821b8:	f9400263 	ldr	x3, [x19]
		if (h == 0) 
			continue; 
		if (timers[t].elapseat <= cur) { // should fire  
			V("called, id %d h %lx", t, (unsigned long)timers[t].handler);	
			timers[t].handler = 0; 
			(*h)(t, timers[t].param, timers[t].context); 			
   821bc:	aa1403e0 	mov	x0, x20
   821c0:	91000694 	add	x20, x20, #0x1
		if (h == 0) 
   821c4:	b40000e3 	cbz	x3, 821e0 <sys_timer_irq+0x90>
		if (timers[t].elapseat <= cur) { // should fire  
   821c8:	f9400661 	ldr	x1, [x19, #8]
   821cc:	eb15003f 	cmp	x1, x21
   821d0:	54000088 	b.hi	821e0 <sys_timer_irq+0x90>  // b.pmore
			(*h)(t, timers[t].param, timers[t].context); 			
   821d4:	a9410a61 	ldp	x1, x2, [x19, #16]
			timers[t].handler = 0; 
   821d8:	f900027f 	str	xzr, [x19]
			(*h)(t, timers[t].param, timers[t].context); 			
   821dc:	d63f0060 	blr	x3
	for (int t = 0; t < N_TIMERS; t++) {
   821e0:	91008273 	add	x19, x19, #0x20
   821e4:	f100529f 	cmp	x20, #0x14
   821e8:	54fffe81 	b.ne	821b8 <sys_timer_irq+0x68>  // b.any
		}		
	}
	adjust_sys_timer(); 
   821ec:	97fffee5 	bl	81d80 <adjust_sys_timer>
	release(&timerlock);
   821f0:	f94766c0 	ldr	x0, [x22, #3784]
}
   821f4:	a94153f3 	ldp	x19, x20, [sp, #16]
   821f8:	a9425bf5 	ldp	x21, x22, [sp, #32]
   821fc:	a8c37bfd 	ldp	x29, x30, [sp], #48
	release(&timerlock);
   82200:	17fffec0 	b	81d00 <release>
	BUG_ON(!(get32(TIMER_CS) & TIMER_CS_M1));  
   82204:	90000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   82208:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   8220c:	911be021 	add	x1, x1, #0x6f8
   82210:	911e6000 	add	x0, x0, #0x798
   82214:	528026c2 	mov	w2, #0x136                 	// #310
   82218:	97fffdb8 	bl	818f8 <assertion_failed>
   8221c:	17ffffd5 	b	82170 <sys_timer_irq+0x20>

0000000000082220 <mbox_call>:
 * Returns 0 on failure, non-zero on success
 * 
 * caller must hold mboxlock
 */
int mbox_call(unsigned char ch)
{
   82220:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
    // the buf addr (pa) w/ ch (chan id) in LSB 
    unsigned int r = (((unsigned int)((unsigned long)&mbox)&~0xF) | (ch&0xF));
    r = BUS_ADDRESS(r); 
    /* wait until we can write to the mailbox */
    do{asm volatile("nop");}while(*MBOX_STATUS & MBOX_FULL);
   82224:	d2971301 	mov	x1, #0xb898                	// #47256
   82228:	f2a7e001 	movk	x1, #0x3f00, lsl #16
{
   8222c:	910003fd 	mov	x29, sp
   82230:	a90363f7 	stp	x23, x24, [sp, #48]
    unsigned int r = (((unsigned int)((unsigned long)&mbox)&~0xF) | (ch&0xF));
   82234:	f0000098 	adrp	x24, 95000 <wordsworth.1725+0xee10>
{
   82238:	a90153f3 	stp	x19, x20, [sp, #16]
    unsigned int r = (((unsigned int)((unsigned long)&mbox)&~0xF) | (ch&0xF));
   8223c:	12000c14 	and	w20, w0, #0xf
   82240:	f9476300 	ldr	x0, [x24, #3776]
{
   82244:	a9025bf5 	stp	x21, x22, [sp, #32]
    unsigned int r = (((unsigned int)((unsigned long)&mbox)&~0xF) | (ch&0xF));
   82248:	2a000294 	orr	w20, w20, w0
    r = BUS_ADDRESS(r); 
   8224c:	32020694 	orr	w20, w20, #0xc0000000
    do{asm volatile("nop");}while(*MBOX_STATUS & MBOX_FULL);
   82250:	d503201f 	nop
   82254:	b9400020 	ldr	w0, [x1]
   82258:	37ffffc0 	tbnz	w0, #31, 82250 <mbox_call+0x30>
    __asm__ volatile ("dmb sy" ::: "memory");    // mem barrier, ensuring msg in mem
   8225c:	d5033fbf 	dmb	sy
    __asm_flush_dcache_range((void *)mbox, (char *)mbox + sizeof(mbox)); 
   82260:	f9476300 	ldr	x0, [x24, #3776]
    /* write the address of our message to the mailbox with channel identifier */
    *MBOX_WRITE = r; 
    /* now wait for the response */
    while(1) {
        /* is there a response? */
        do{asm volatile("nop");}while(*MBOX_STATUS & MBOX_EMPTY);
   82264:	d2971313 	mov	x19, #0xb898                	// #47256
        /* is it a response to our message? */
        if(r == *MBOX_READ) {
   82268:	d2971017 	mov	x23, #0xb880                	// #47232
            __asm_invalidate_dcache_range((void *)mbox, (char *)mbox + sizeof(mbox)); 
            /* is it a valid successful response? (strange it's benign) */
            if (mbox[1]!=MBOX_RESPONSE) I("mbox[1] is %08x", mbox[1]);            
            return mbox[1]==MBOX_RESPONSE;
        } else {
            W("got an irrelvant msg. bug?"); 
   8226c:	90000035 	adrp	x21, 86000 <__asm_dcache_level+0xc>
    __asm_flush_dcache_range((void *)mbox, (char *)mbox + sizeof(mbox)); 
   82270:	91024001 	add	x1, x0, #0x90
            W("got an irrelvant msg. bug?"); 
   82274:	911fa2b5 	add	x21, x21, #0x7e8
    __asm_flush_dcache_range((void *)mbox, (char *)mbox + sizeof(mbox)); 
   82278:	94000f45 	bl	85f8c <__asm_flush_dcache_range>
        do{asm volatile("nop");}while(*MBOX_STATUS & MBOX_EMPTY);
   8227c:	f2a7e013 	movk	x19, #0x3f00, lsl #16
    *MBOX_WRITE = r; 
   82280:	d2971400 	mov	x0, #0xb8a0                	// #47264
        if(r == *MBOX_READ) {
   82284:	f2a7e017 	movk	x23, #0x3f00, lsl #16
    *MBOX_WRITE = r; 
   82288:	f2a7e000 	movk	x0, #0x3f00, lsl #16
            W("got an irrelvant msg. bug?"); 
   8228c:	90000036 	adrp	x22, 86000 <__asm_dcache_level+0xc>
    *MBOX_WRITE = r; 
   82290:	b9000014 	str	w20, [x0]
   82294:	d503201f 	nop
        do{asm volatile("nop");}while(*MBOX_STATUS & MBOX_EMPTY);
   82298:	d503201f 	nop
   8229c:	b9400260 	ldr	w0, [x19]
   822a0:	37f7ffc0 	tbnz	w0, #30, 82298 <mbox_call+0x78>
        if(r == *MBOX_READ) {
   822a4:	b94002e3 	ldr	w3, [x23]
            W("got an irrelvant msg. bug?"); 
   822a8:	aa1503e1 	mov	x1, x21
   822ac:	912062c0 	add	x0, x22, #0x818
   822b0:	52800822 	mov	w2, #0x41                  	// #65
        if(r == *MBOX_READ) {
   822b4:	6b14007f 	cmp	w3, w20
   822b8:	54000060 	b.eq	822c4 <mbox_call+0xa4>  // b.none
            W("got an irrelvant msg. bug?"); 
   822bc:	97fffcbf 	bl	815b8 <tfp_printf>
    while(1) {
   822c0:	17fffff6 	b	82298 <mbox_call+0x78>
            __asm_invalidate_dcache_range((void *)mbox, (char *)mbox + sizeof(mbox)); 
   822c4:	f9476313 	ldr	x19, [x24, #3776]
   822c8:	91024261 	add	x1, x19, #0x90
   822cc:	aa1303e0 	mov	x0, x19
   822d0:	94000f3c 	bl	85fc0 <__asm_invalidate_dcache_range>
            if (mbox[1]!=MBOX_RESPONSE) I("mbox[1] is %08x", mbox[1]);            
   822d4:	b9400661 	ldr	w1, [x19, #4]
   822d8:	52b00000 	mov	w0, #0x80000000            	// #-2147483648
   822dc:	6b00003f 	cmp	w1, w0
   822e0:	54000100 	b.eq	82300 <mbox_call+0xe0>  // b.none
   822e4:	b9400663 	ldr	w3, [x19, #4]
   822e8:	90000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   822ec:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   822f0:	911fa021 	add	x1, x1, #0x7e8
   822f4:	911fc000 	add	x0, x0, #0x7f0
   822f8:	528007c2 	mov	w2, #0x3e                  	// #62
   822fc:	97fffcaf 	bl	815b8 <tfp_printf>
            return mbox[1]==MBOX_RESPONSE;
   82300:	f9476318 	ldr	x24, [x24, #3776]
   82304:	52b00000 	mov	w0, #0x80000000            	// #-2147483648
        }
    }
    return 0;
}
   82308:	a94153f3 	ldp	x19, x20, [sp, #16]
            return mbox[1]==MBOX_RESPONSE;
   8230c:	b9400701 	ldr	w1, [x24, #4]
}
   82310:	a9425bf5 	ldp	x21, x22, [sp, #32]
            return mbox[1]==MBOX_RESPONSE;
   82314:	6b00003f 	cmp	w1, w0
   82318:	1a9f17e0 	cset	w0, eq	// eq = none
}
   8231c:	a94363f7 	ldp	x23, x24, [sp, #48]
   82320:	a8c47bfd 	ldp	x29, x30, [sp], #64
   82324:	d65f03c0 	ret

0000000000082328 <fb_detect_scr_dim>:
    return: 0 on success 

    FL's 720p monitor: 1360 768
    qemu 640 480 (initial? subject to reconfig for larger fb)
*/
int fb_detect_scr_dim(uint *w, uint *h) {
   82328:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
    mbox[0] = 8*4;     // size of the whole buf that follows
   8232c:	52800404 	mov	w4, #0x20                  	// #32
    mbox[1] = MBOX_REQUEST; // cpu->gpu request
        mbox[2] = 0x40003;     // rls framebuffer
   82330:	52800063 	mov	w3, #0x3                   	// #3
int fb_detect_scr_dim(uint *w, uint *h) {
   82334:	910003fd 	mov	x29, sp
   82338:	a90153f3 	stp	x19, x20, [sp, #16]
    mbox[0] = 8*4;     // size of the whole buf that follows
   8233c:	f0000093 	adrp	x19, 95000 <wordsworth.1725+0xee10>
        mbox[2] = 0x40003;     // rls framebuffer
   82340:	72a00083 	movk	w3, #0x4, lsl #16
    mbox[0] = 8*4;     // size of the whole buf that follows
   82344:	f9476273 	ldr	x19, [x19, #3776]
int fb_detect_scr_dim(uint *w, uint *h) {
   82348:	a9025bf5 	stp	x21, x22, [sp, #32]
        mbox[3] = 8;           // total buf size
   8234c:	52800102 	mov	w2, #0x8                   	// #8
int fb_detect_scr_dim(uint *w, uint *h) {
   82350:	aa0003f4 	mov	x20, x0
   82354:	aa0103f5 	mov	x21, x1
    mbox[0] = 8*4;     // size of the whole buf that follows
   82358:	b9000264 	str	w4, [x19]
        mbox[4] = 0;           // req para size
        mbox[5] = 0;           // resp: width
        mbox[6] = 0;           // resp: height
    mbox[7] = MBOX_TAG_LAST;

    if(!mbox_call(MBOX_CH_PROP)) {
   8235c:	2a0203e0 	mov	w0, w2
    mbox[1] = MBOX_REQUEST; // cpu->gpu request
   82360:	b900067f 	str	wzr, [x19, #4]
        mbox[2] = 0x40003;     // rls framebuffer
   82364:	b9000a63 	str	w3, [x19, #8]
        mbox[3] = 8;           // total buf size
   82368:	b9000e62 	str	w2, [x19, #12]
        mbox[4] = 0;           // req para size
   8236c:	b900127f 	str	wzr, [x19, #16]
        mbox[5] = 0;           // resp: width
   82370:	b900167f 	str	wzr, [x19, #20]
        mbox[6] = 0;           // resp: height
   82374:	b9001a7f 	str	wzr, [x19, #24]
    mbox[7] = MBOX_TAG_LAST;
   82378:	b9001e7f 	str	wzr, [x19, #28]
    if(!mbox_call(MBOX_CH_PROP)) {
   8237c:	97ffffa9 	bl	82220 <mbox_call>
   82380:	340004a0 	cbz	w0, 82414 <fb_detect_scr_dim+0xec>
        E("failed to get screen dim");
        return -1;
    } 

    *w=mbox[5];*h=mbox[6]; I("detected screen dim %d %d", *w, *h);
   82384:	b9401660 	ldr	w0, [x19, #20]
   82388:	90000036 	adrp	x22, 86000 <__asm_dcache_level+0xc>
   8238c:	b9000280 	str	w0, [x20]
   82390:	911fa2c1 	add	x1, x22, #0x7e8
   82394:	52801a02 	mov	w2, #0xd0                  	// #208
   82398:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   8239c:	b9401a64 	ldr	w4, [x19, #24]
   823a0:	9121e000 	add	x0, x0, #0x878
   823a4:	b90002a4 	str	w4, [x21]
   823a8:	b9400283 	ldr	w3, [x20]
   823ac:	97fffc83 	bl	815b8 <tfp_printf>

    if (*w == 1184 || *h == 624) {
   823b0:	b9400280 	ldr	w0, [x20]
   823b4:	7112801f 	cmp	w0, #0x4a0
   823b8:	54000120 	b.eq	823dc <fb_detect_scr_dim+0xb4>  // b.none
   823bc:	b94002a1 	ldr	w1, [x21]
        W("detected screen 1184x624. assume a Waveshare HAT. force 480 320");
        *w = 480; *h = 320;
    }    
    return 0; 
   823c0:	52800000 	mov	w0, #0x0                   	// #0
    if (*w == 1184 || *h == 624) {
   823c4:	7109c03f 	cmp	w1, #0x270
   823c8:	540000a0 	b.eq	823dc <fb_detect_scr_dim+0xb4>  // b.none
}
   823cc:	a94153f3 	ldp	x19, x20, [sp, #16]
   823d0:	a9425bf5 	ldp	x21, x22, [sp, #32]
   823d4:	a8c37bfd 	ldp	x29, x30, [sp], #48
   823d8:	d65f03c0 	ret
        W("detected screen 1184x624. assume a Waveshare HAT. force 480 320");
   823dc:	911fa2c1 	add	x1, x22, #0x7e8
   823e0:	52801a62 	mov	w2, #0xd3                  	// #211
   823e4:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   823e8:	9122a000 	add	x0, x0, #0x8a8
   823ec:	97fffc73 	bl	815b8 <tfp_printf>
        *w = 480; *h = 320;
   823f0:	52803c00 	mov	w0, #0x1e0                 	// #480
   823f4:	b9000280 	str	w0, [x20]
   823f8:	52802801 	mov	w1, #0x140                 	// #320
   823fc:	b90002a1 	str	w1, [x21]
    return 0; 
   82400:	52800000 	mov	w0, #0x0                   	// #0
}
   82404:	a94153f3 	ldp	x19, x20, [sp, #16]
   82408:	a9425bf5 	ldp	x21, x22, [sp, #32]
   8240c:	a8c37bfd 	ldp	x29, x30, [sp], #48
   82410:	d65f03c0 	ret
        E("failed to get screen dim");
   82414:	90000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   82418:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   8241c:	911fa021 	add	x1, x1, #0x7e8
   82420:	91212000 	add	x0, x0, #0x848
   82424:	52801982 	mov	w2, #0xcc                  	// #204
   82428:	97fffc64 	bl	815b8 <tfp_printf>
        return -1;
   8242c:	12800000 	mov	w0, #0xffffffff            	// #-1
   82430:	17ffffe7 	b	823cc <fb_detect_scr_dim+0xa4>
   82434:	d503201f 	nop

0000000000082438 <fb_set_voffsets>:

// set virt offset
// caller must hold mboxlock
// 0 on success
int fb_set_voffsets(int offsetx, int offsety) {
   82438:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!

    mbox[0] = 8*4;
   8243c:	52800404 	mov	w4, #0x20                  	// #32
    mbox[1] = MBOX_REQUEST;
    
    mbox[2] = 0x48009; 
   82440:	52900123 	mov	w3, #0x8009                	// #32777
int fb_set_voffsets(int offsetx, int offsety) {
   82444:	910003fd 	mov	x29, sp
   82448:	a9025bf5 	stp	x21, x22, [sp, #32]
    mbox[0] = 8*4;
   8244c:	f0000096 	adrp	x22, 95000 <wordsworth.1725+0xee10>
    mbox[2] = 0x48009; 
   82450:	72a00083 	movk	w3, #0x4, lsl #16
int fb_set_voffsets(int offsetx, int offsety) {
   82454:	a90153f3 	stp	x19, x20, [sp, #16]
    mbox[3] = 8;
   82458:	52800102 	mov	w2, #0x8                   	// #8
int fb_set_voffsets(int offsetx, int offsety) {
   8245c:	2a0003f4 	mov	w20, w0
    mbox[0] = 8*4;
   82460:	f94762d3 	ldr	x19, [x22, #3776]
int fb_set_voffsets(int offsetx, int offsety) {
   82464:	2a0103f5 	mov	w21, w1
    mbox[5] =  offsetx;           //FrameBufferInfo.x_offset
    mbox[6] =  offsety;           //FrameBufferInfo.y.offset    

    mbox[7] = MBOX_TAG_LAST;

    if(!mbox_call(MBOX_CH_PROP)) {
   82468:	2a0203e0 	mov	w0, w2
    mbox[0] = 8*4;
   8246c:	b9000264 	str	w4, [x19]
    mbox[1] = MBOX_REQUEST;
   82470:	b900067f 	str	wzr, [x19, #4]
    mbox[2] = 0x48009; 
   82474:	b9000a63 	str	w3, [x19, #8]
    mbox[3] = 8;
   82478:	b9000e62 	str	w2, [x19, #12]
    mbox[4] = 8;
   8247c:	b9001262 	str	w2, [x19, #16]
    mbox[5] =  offsetx;           //FrameBufferInfo.x_offset
   82480:	b9001674 	str	w20, [x19, #20]
    mbox[6] =  offsety;           //FrameBufferInfo.y.offset    
   82484:	b9001a61 	str	w1, [x19, #24]
    mbox[7] = MBOX_TAG_LAST;
   82488:	b9001e7f 	str	wzr, [x19, #28]
    if(!mbox_call(MBOX_CH_PROP)) {
   8248c:	97ffff65 	bl	82220 <mbox_call>
   82490:	34000320 	cbz	w0, 824f4 <fb_set_voffsets+0xbc>
        E("failed to set virt offsets, requested x=%d y=%d", offsetx, offsety);
        return -1;
    }     
     if (mbox[5] != offsetx || mbox[6] != offsety) {
   82494:	b9401660 	ldr	w0, [x19, #20]
   82498:	6b00029f 	cmp	w20, w0
   8249c:	54000121 	b.ne	824c0 <fb_set_voffsets+0x88>  // b.any
   824a0:	b9401a61 	ldr	w1, [x19, #24]
            offsetx, offsety, mbox[5], mbox[6]);
        return -1;     
     }
     V("set OK: offsetx %u offsety %u res: offsetx %u offsety %u", 
            offsetx, offsety, mbox[5], mbox[6]);
     return 0; 
   824a4:	52800000 	mov	w0, #0x0                   	// #0
     if (mbox[5] != offsetx || mbox[6] != offsety) {
   824a8:	6b0102bf 	cmp	w21, w1
   824ac:	540000a1 	b.ne	824c0 <fb_set_voffsets+0x88>  // b.any
}
   824b0:	a94153f3 	ldp	x19, x20, [sp, #16]
   824b4:	a9425bf5 	ldp	x21, x22, [sp, #32]
   824b8:	a8c37bfd 	ldp	x29, x30, [sp], #48
   824bc:	d65f03c0 	ret
        E("failed set: offsetx %u offsety %u res: offsetx %u offsety %u", 
   824c0:	f94762d6 	ldr	x22, [x22, #3776]
   824c4:	2a1503e4 	mov	w4, w21
   824c8:	2a1403e3 	mov	w3, w20
   824cc:	90000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   824d0:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   824d4:	911fa021 	add	x1, x1, #0x7e8
   824d8:	b94016c5 	ldr	w5, [x22, #20]
   824dc:	91252000 	add	x0, x0, #0x948
   824e0:	b9401ac6 	ldr	w6, [x22, #24]
   824e4:	52801dc2 	mov	w2, #0xee                  	// #238
   824e8:	97fffc34 	bl	815b8 <tfp_printf>
        return -1;     
   824ec:	12800000 	mov	w0, #0xffffffff            	// #-1
   824f0:	17fffff0 	b	824b0 <fb_set_voffsets+0x78>
        E("failed to set virt offsets, requested x=%d y=%d", offsetx, offsety);
   824f4:	2a1503e4 	mov	w4, w21
   824f8:	2a1403e3 	mov	w3, w20
   824fc:	90000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   82500:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   82504:	911fa021 	add	x1, x1, #0x7e8
   82508:	91240000 	add	x0, x0, #0x900
   8250c:	52801d42 	mov	w2, #0xea                  	// #234
   82510:	97fffc2a 	bl	815b8 <tfp_printf>
        return -1;
   82514:	12800000 	mov	w0, #0xffffffff            	// #-1
   82518:	17ffffe6 	b	824b0 <fb_set_voffsets+0x78>
   8251c:	d503201f 	nop

0000000000082520 <fb_fini>:
}

/* finalize the fb, clean up. 
    return 0 on success (display will go blank)
*/
int fb_fini(void) {
   82520:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   82524:	910003fd 	mov	x29, sp
   82528:	a90153f3 	stp	x19, x20, [sp, #16]
    int ret = 0; 

    acquire(&mboxlock); 
    if (!the_fb.fb || !the_fb.size) {
   8252c:	f0000093 	adrp	x19, 95000 <wordsworth.1725+0xee10>
int fb_fini(void) {
   82530:	f90013f5 	str	x21, [sp, #32]
    acquire(&mboxlock); 
   82534:	f0000095 	adrp	x21, 95000 <wordsworth.1725+0xee10>
   82538:	913922a0 	add	x0, x21, #0xe48
   8253c:	97fffdaf 	bl	81bf8 <acquire>
    if (!the_fb.fb || !the_fb.size) {
   82540:	f942b660 	ldr	x0, [x19, #1384]
   82544:	b4000620 	cbz	x0, 82608 <fb_fini+0xe8>
   82548:	9115a261 	add	x1, x19, #0x568
   8254c:	b9403422 	ldr	w2, [x1, #52]
   82550:	340005c2 	cbz	w2, 82608 <fb_fini+0xe8>
        ret = -1; 
        goto out; 
    }

#ifdef PLAT_RPI3QEMU    // avoid artifacts: qemu does not clear old fb
    memset(the_fb.fb, 0, the_fb.size);     
   82554:	52800001 	mov	w1, #0x0                   	// #0
   82558:	97fffcf4 	bl	81928 <memset>
#endif

    mbox[0] = 6*4;     // size of the whole buf that follows
   8255c:	f0000081 	adrp	x1, 95000 <wordsworth.1725+0xee10>
   82560:	52800303 	mov	w3, #0x18                  	// #24
    mbox[1] = MBOX_REQUEST; // cpu->gpu request

    mbox[2] = 0x48001;     // rls framebuffer
   82564:	52900022 	mov	w2, #0x8001                	// #32769
    mbox[3] = 0;           // total buf size
    mbox[4] = 0;           // req para size
        
    mbox[5] = MBOX_TAG_LAST;

    if(!mbox_call(MBOX_CH_PROP))
   82568:	52800100 	mov	w0, #0x8                   	// #8
    mbox[0] = 6*4;     // size of the whole buf that follows
   8256c:	f9476021 	ldr	x1, [x1, #3776]
    mbox[2] = 0x48001;     // rls framebuffer
   82570:	72a00082 	movk	w2, #0x4, lsl #16
    mbox[0] = 6*4;     // size of the whole buf that follows
   82574:	b9000023 	str	w3, [x1]
    mbox[1] = MBOX_REQUEST; // cpu->gpu request
   82578:	b900043f 	str	wzr, [x1, #4]
    mbox[2] = 0x48001;     // rls framebuffer
   8257c:	b9000822 	str	w2, [x1, #8]
    mbox[3] = 0;           // total buf size
   82580:	b9000c3f 	str	wzr, [x1, #12]
    mbox[4] = 0;           // req para size
   82584:	b900103f 	str	wzr, [x1, #16]
    mbox[5] = MBOX_TAG_LAST;
   82588:	b900143f 	str	wzr, [x1, #20]
    if(!mbox_call(MBOX_CH_PROP))
   8258c:	97ffff25 	bl	82220 <mbox_call>
   82590:	340002e0 	cbz	w0, 825ec <fb_fini+0xcc>
        I("failed to rls fb with GPU (could be benign)"); 
        // response code always 0x80000001 (failure). couldn't figure out why

    if (free_phys_region((unsigned long)the_fb.fb, the_fb.size)) {
   82594:	9115a261 	add	x1, x19, #0x568
   82598:	f942b660 	ldr	x0, [x19, #1384]
   8259c:	b9403421 	ldr	w1, [x1, #52]
   825a0:	940003f4 	bl	83570 <free_phys_region>
   825a4:	2a0003f4 	mov	w20, w0
   825a8:	35000120 	cbnz	w0, 825cc <fb_fini+0xac>
        E("failed to free fb memory. bug?"); 
        ret = -2; 
    }
    the_fb.fb = 0; 
   825ac:	f902b67f 	str	xzr, [x19, #1384]
out:
    release(&mboxlock);          
   825b0:	913922a0 	add	x0, x21, #0xe48
   825b4:	97fffdd3 	bl	81d00 <release>
    return ret; 
}
   825b8:	2a1403e0 	mov	w0, w20
   825bc:	a94153f3 	ldp	x19, x20, [sp, #16]
   825c0:	f94013f5 	ldr	x21, [sp, #32]
   825c4:	a8c37bfd 	ldp	x29, x30, [sp], #48
   825c8:	d65f03c0 	ret
        ret = -2; 
   825cc:	12800034 	mov	w20, #0xfffffffe            	// #-2
        E("failed to free fb memory. bug?"); 
   825d0:	90000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   825d4:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   825d8:	911fa021 	add	x1, x1, #0x7e8
   825dc:	91276000 	add	x0, x0, #0x9d8
   825e0:	528030a2 	mov	w2, #0x185                 	// #389
   825e4:	97fffbf5 	bl	815b8 <tfp_printf>
        ret = -2; 
   825e8:	17fffff1 	b	825ac <fb_fini+0x8c>
        I("failed to rls fb with GPU (could be benign)"); 
   825ec:	90000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   825f0:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   825f4:	911fa021 	add	x1, x1, #0x7e8
   825f8:	91266000 	add	x0, x0, #0x998
   825fc:	52803022 	mov	w2, #0x181                 	// #385
   82600:	97fffbee 	bl	815b8 <tfp_printf>
   82604:	17ffffe4 	b	82594 <fb_fini+0x74>
        ret = -1; 
   82608:	12800014 	mov	w20, #0xffffffff            	// #-1
   8260c:	17ffffe9 	b	825b0 <fb_fini+0x90>

0000000000082610 <fb_print>:
    unsigned char *fb = the_fb.fb; 

    // get our font
    psf_t *font = (psf_t*)&_binary_font_psf_start;
    // draw next character if it's not zero
    while(*s) {
   82610:	39400043 	ldrb	w3, [x2]
    unsigned pitch = the_fb.pitch; 
   82614:	f0000084 	adrp	x4, 95000 <wordsworth.1725+0xee10>
   82618:	9115a085 	add	x5, x4, #0x568
    unsigned char *fb = the_fb.fb; 
   8261c:	f942b48f 	ldr	x15, [x4, #1384]
    unsigned pitch = the_fb.pitch; 
   82620:	b94018aa 	ldr	w10, [x5, #24]
    while(*s) {
   82624:	34000f23 	cbz	w3, 82808 <fb_print+0x1f8>
{
   82628:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
        /* get offset of the glyph. Need to adjust this to support unicode table */
        unsigned char *glyph = (unsigned char*)&_binary_font_psf_start +
         font->headersize + (*((unsigned char*)s)<font->numglyph?*s:0)*font->bytesperglyph;
   8262c:	f0000084 	adrp	x4, 95000 <wordsworth.1725+0xee10>
        } else {
            // display a character
            for(j=0;j<font->height;j++){
                // display one row
                line=offs;
                mask=1<<(font->width-1);
   82630:	5280002e 	mov	w14, #0x1                   	// #1
{
   82634:	910003fd 	mov	x29, sp
         font->headersize + (*((unsigned char*)s)<font->numglyph?*s:0)*font->bytesperglyph;
   82638:	f9479084 	ldr	x4, [x4, #3872]
{
   8263c:	a90153f3 	stp	x19, x20, [sp, #16]
   82640:	910011f1 	add	x17, x15, #0x4
   82644:	a9025bf5 	stp	x21, x22, [sp, #32]
        unsigned char *glyph = (unsigned char*)&_binary_font_psf_start +
   82648:	aa0403f4 	mov	x20, x4
                for(i=0;i<font->width;i++){
                    // if bit set, we use white color, otherwise black
                    *((unsigned int*)(fb + line))=((int)*glyph) & mask?0xFFFFFF:0;
   8264c:	12bfe008 	mov	w8, #0xffffff              	// #16777215
         font->headersize + (*((unsigned char*)s)<font->numglyph?*s:0)*font->bytesperglyph;
   82650:	39402085 	ldrb	w5, [x4, #8]
   82654:	39402489 	ldrb	w9, [x4, #9]
   82658:	92401ca5 	and	x5, x5, #0xff
   8265c:	3940288c 	ldrb	w12, [x4, #10]
   82660:	39402c96 	ldrb	w22, [x4, #11]
   82664:	d3781d29 	ubfiz	x9, x9, #8, #8
   82668:	39404086 	ldrb	w6, [x4, #16]
   8266c:	39404487 	ldrb	w7, [x4, #17]
   82670:	aa050129 	orr	x9, x9, x5
   82674:	3940489e 	ldrb	w30, [x4, #18]
   82678:	92401cc6 	and	x6, x6, #0xff
   8267c:	39404c8d 	ldrb	w13, [x4, #19]
   82680:	d3701d8c 	ubfiz	x12, x12, #16, #8
   82684:	39405085 	ldrb	w5, [x4, #20]
   82688:	d3781ce7 	ubfiz	x7, x7, #8, #8
   8268c:	3940548b 	ldrb	w11, [x4, #21]
   82690:	aa0600e7 	orr	x7, x7, x6
   82694:	92401ca5 	and	x5, x5, #0xff
   82698:	39405886 	ldrb	w6, [x4, #22]
   8269c:	39405c92 	ldrb	w18, [x4, #23]
   826a0:	aa09018c 	orr	x12, x12, x9
        int i,j, line,mask, bytesperline=(font->width+7)/8;
   826a4:	39407090 	ldrb	w16, [x4, #28]
         font->headersize + (*((unsigned char*)s)<font->numglyph?*s:0)*font->bytesperglyph;
   826a8:	d3781d6b 	ubfiz	x11, x11, #8, #8
        int i,j, line,mask, bytesperline=(font->width+7)/8;
   826ac:	39407493 	ldrb	w19, [x4, #29]
         font->headersize + (*((unsigned char*)s)<font->numglyph?*s:0)*font->bytesperglyph;
   826b0:	aa05016b 	orr	x11, x11, x5
        int i,j, line,mask, bytesperline=(font->width+7)/8;
   826b4:	39407885 	ldrb	w5, [x4, #30]
   826b8:	92401e10 	and	x16, x16, #0xff
   826bc:	39407c95 	ldrb	w21, [x4, #31]
         font->headersize + (*((unsigned char*)s)<font->numglyph?*s:0)*font->bytesperglyph;
   826c0:	d3701cc6 	ubfiz	x6, x6, #16, #8
        int i,j, line,mask, bytesperline=(font->width+7)/8;
   826c4:	d3781e73 	ubfiz	x19, x19, #8, #8
         font->headersize + (*((unsigned char*)s)<font->numglyph?*s:0)*font->bytesperglyph;
   826c8:	d3701fde 	ubfiz	x30, x30, #16, #8
        int i,j, line,mask, bytesperline=(font->width+7)/8;
   826cc:	aa100273 	orr	x19, x19, x16
   826d0:	d3701ca5 	ubfiz	x5, x5, #16, #8
            for(j=0;j<font->height;j++){
   826d4:	39406090 	ldrb	w16, [x4, #24]
        int i,j, line,mask, bytesperline=(font->width+7)/8;
   826d8:	aa1300a5 	orr	x5, x5, x19
            for(j=0;j<font->height;j++){
   826dc:	39406489 	ldrb	w9, [x4, #25]
        int i,j, line,mask, bytesperline=(font->width+7)/8;
   826e0:	53081eb3 	lsl	w19, w21, #24
   826e4:	aa050273 	orr	x19, x19, x5
            for(j=0;j<font->height;j++){
   826e8:	39406885 	ldrb	w5, [x4, #26]
   826ec:	92401e10 	and	x16, x16, #0xff
   826f0:	39406c95 	ldrb	w21, [x4, #27]
   826f4:	d3781d24 	ubfiz	x4, x9, #8, #8
         font->headersize + (*((unsigned char*)s)<font->numglyph?*s:0)*font->bytesperglyph;
   826f8:	aa0b00c6 	orr	x6, x6, x11
            for(j=0;j<font->height;j++){
   826fc:	aa100089 	orr	x9, x4, x16
        int i,j, line,mask, bytesperline=(font->width+7)/8;
   82700:	11001e6b 	add	w11, w19, #0x7
                mask=1<<(font->width-1);
   82704:	51000670 	sub	w16, w19, #0x1
            for(j=0;j<font->height;j++){
   82708:	d3701ca4 	ubfiz	x4, x5, #16, #8
         font->headersize + (*((unsigned char*)s)<font->numglyph?*s:0)*font->bytesperglyph;
   8270c:	53081ed6 	lsl	w22, w22, #24
   82710:	aa0703c7 	orr	x7, x30, x7
            for(j=0;j<font->height;j++){
   82714:	aa090084 	orr	x4, x4, x9
         font->headersize + (*((unsigned char*)s)<font->numglyph?*s:0)*font->bytesperglyph;
   82718:	2a0d60fe 	orr	w30, w7, w13, lsl #24
   8271c:	aa0c02cc 	orr	x12, x22, x12
        int i,j, line,mask, bytesperline=(font->width+7)/8;
   82720:	2a1303ed 	mov	w13, w19
         font->headersize + (*((unsigned char*)s)<font->numglyph?*s:0)*font->bytesperglyph;
   82724:	2a1260d2 	orr	w18, w6, w18, lsl #24
   82728:	0b0e0273 	add	w19, w19, w14
   8272c:	53037d6b 	lsr	w11, w11, #3
            for(j=0;j<font->height;j++){
   82730:	2a156089 	orr	w9, w4, w21, lsl #24
                mask=1<<(font->width-1);
   82734:	1ad021ce 	lsl	w14, w14, w16
   82738:	14000009 	b	8275c <fb_print+0x14c>
        if(*s == '\n') {
   8273c:	7100287f 	cmp	w3, #0xa
   82740:	54000281 	b.ne	82790 <fb_print+0x180>  // b.any
            *x = 0; *y += font->height;
   82744:	b900001f 	str	wzr, [x0]
   82748:	b9400023 	ldr	w3, [x1]
   8274c:	0b090063 	add	w3, w3, w9
   82750:	b9000023 	str	w3, [x1]
    while(*s) {
   82754:	38401c43 	ldrb	w3, [x2, #1]!
   82758:	34000143 	cbz	w3, 82780 <fb_print+0x170>
        unsigned char *glyph = (unsigned char*)&_binary_font_psf_start +
   8275c:	1b127c66 	mul	w6, w3, w18
   82760:	6b1e007f 	cmp	w3, w30
   82764:	8b0c00c6 	add	x6, x6, x12
   82768:	9a8c30c6 	csel	x6, x6, x12, cc	// cc = lo, ul, last
        if(*s == '\r') {
   8276c:	7100347f 	cmp	w3, #0xd
   82770:	54fffe61 	b.ne	8273c <fb_print+0x12c>  // b.any
            *x = 0;
   82774:	b900001f 	str	wzr, [x0]
    while(*s) {
   82778:	38401c43 	ldrb	w3, [x2, #1]!
   8277c:	35ffff03 	cbnz	w3, 8275c <fb_print+0x14c>
            *x += (font->width+1);
        }
        // next character
        s++;
    }
}
   82780:	a94153f3 	ldp	x19, x20, [sp, #16]
   82784:	a9425bf5 	ldp	x21, x22, [sp, #32]
   82788:	a8c37bfd 	ldp	x29, x30, [sp], #48
   8278c:	d65f03c0 	ret
        int offs = (*y * pitch) + (*x * 4);
   82790:	b9400003 	ldr	w3, [x0]
            for(j=0;j<font->height;j++){
   82794:	34000349 	cbz	w9, 827fc <fb_print+0x1ec>
        int offs = (*y * pitch) + (*x * 4);
   82798:	b9400035 	ldr	w21, [x1]
   8279c:	531e7463 	lsl	w3, w3, #2
        unsigned char *glyph = (unsigned char*)&_binary_font_psf_start +
   827a0:	8b1400c6 	add	x6, x6, x20
            for(j=0;j<font->height;j++){
   827a4:	52800016 	mov	w22, #0x0                   	// #0
        int offs = (*y * pitch) + (*x * 4);
   827a8:	1b150d55 	madd	w21, w10, w21, w3
   827ac:	d503201f 	nop
                for(i=0;i<font->width;i++){
   827b0:	340001ad 	cbz	w13, 827e4 <fb_print+0x1d4>
   827b4:	93407ea3 	sxtw	x3, w21
                mask=1<<(font->width-1);
   827b8:	2a0e03e4 	mov	w4, w14
   827bc:	8b304867 	add	x7, x3, w16, uxtw #2
   827c0:	8b0301e3 	add	x3, x15, x3
   827c4:	8b1100e7 	add	x7, x7, x17
                    *((unsigned int*)(fb + line))=((int)*glyph) & mask?0xFFFFFF:0;
   827c8:	394000c5 	ldrb	w5, [x6]
   827cc:	6a0400bf 	tst	w5, w4
                    mask>>=1;
   827d0:	13017c84 	asr	w4, w4, #1
                    *((unsigned int*)(fb + line))=((int)*glyph) & mask?0xFFFFFF:0;
   827d4:	1a9f1105 	csel	w5, w8, wzr, ne	// ne = any
   827d8:	b8004465 	str	w5, [x3], #4
                for(i=0;i<font->width;i++){
   827dc:	eb07007f 	cmp	x3, x7
   827e0:	54ffff41 	b.ne	827c8 <fb_print+0x1b8>  // b.any
            for(j=0;j<font->height;j++){
   827e4:	110006d6 	add	w22, w22, #0x1
                glyph+=bytesperline;
   827e8:	8b0b00c6 	add	x6, x6, x11
            for(j=0;j<font->height;j++){
   827ec:	6b0902df 	cmp	w22, w9
   827f0:	0b0a02b5 	add	w21, w21, w10
   827f4:	54fffde1 	b.ne	827b0 <fb_print+0x1a0>  // b.any
   827f8:	b9400003 	ldr	w3, [x0]
            *x += (font->width+1);
   827fc:	0b130063 	add	w3, w3, w19
   82800:	b9000003 	str	w3, [x0]
   82804:	17ffffd4 	b	82754 <fb_print+0x144>
   82808:	d65f03c0 	ret
   8280c:	d503201f 	nop

0000000000082810 <fb_showpicture>:
#define IMG_DATA header_data      
#define IMG_HEIGHT height
#define IMG_WIDTH width

void fb_showpicture()
{
   82810:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
    int x,y;
    unsigned char *ptr=the_fb.fb;
    char *data=IMG_DATA, pixel[4];
    // fill framebuf. crop img data per the framebuf size
    unsigned int img_fb_height = the_fb.vheight < IMG_HEIGHT ? the_fb.vheight : IMG_HEIGHT; 
   82814:	52800ecb 	mov	w11, #0x76                  	// #118
    unsigned int img_fb_width = the_fb.vwidth < IMG_WIDTH ? the_fb.vwidth : IMG_WIDTH; 
   82818:	52800e8a 	mov	w10, #0x74                  	// #116
{
   8281c:	910003fd 	mov	x29, sp
   82820:	a90153f3 	stp	x19, x20, [sp, #16]
    unsigned char *ptr=the_fb.fb;
   82824:	f0000093 	adrp	x19, 95000 <wordsworth.1725+0xee10>
   82828:	9115a269 	add	x9, x19, #0x568
   8282c:	f942b665 	ldr	x5, [x19, #1384]
{
   82830:	a9025bf5 	stp	x21, x22, [sp, #32]

    // copy the image pixels to the start (top) of framebuf    
    //ptr += (vheight-img_fb_height)/2*pitch + (vwidth-img_fb_width)*2;  
    ptr += (the_fb.vwidth-img_fb_width)/2*PIXELSIZE;  // top center
    ptr += (the_fb.vheight-img_fb_height)/2*the_fb.pitch; 
   82834:	b9401921 	ldr	w1, [x9, #24]
    unsigned int img_fb_height = the_fb.vheight < IMG_HEIGHT ? the_fb.vheight : IMG_HEIGHT; 
   82838:	2942092c 	ldp	w12, w2, [x9, #16]
    
    for(y=0;y<img_fb_height;y++) {
   8283c:	b9003fff 	str	wzr, [sp, #60]
    unsigned int img_fb_height = the_fb.vheight < IMG_HEIGHT ? the_fb.vheight : IMG_HEIGHT; 
   82840:	6b0b005f 	cmp	w2, w11
   82844:	1a8b904b 	csel	w11, w2, w11, ls	// ls = plast
    unsigned int img_fb_width = the_fb.vwidth < IMG_WIDTH ? the_fb.vwidth : IMG_WIDTH; 
   82848:	6b0a019f 	cmp	w12, w10
    ptr += (the_fb.vheight-img_fb_height)/2*the_fb.pitch; 
   8284c:	4b0b0040 	sub	w0, w2, w11
    unsigned int img_fb_width = the_fb.vwidth < IMG_WIDTH ? the_fb.vwidth : IMG_WIDTH; 
   82850:	1a8a918a 	csel	w10, w12, w10, ls	// ls = plast
    ptr += (the_fb.vwidth-img_fb_width)/2*PIXELSIZE;  // top center
   82854:	4b0a0183 	sub	w3, w12, w10
    ptr += (the_fb.vheight-img_fb_height)/2*the_fb.pitch; 
   82858:	53017c00 	lsr	w0, w0, #1
    ptr += (the_fb.vwidth-img_fb_width)/2*PIXELSIZE;  // top center
   8285c:	53017c63 	lsr	w3, w3, #1
    ptr += (the_fb.vheight-img_fb_height)/2*the_fb.pitch; 
   82860:	1b017c00 	mul	w0, w0, w1
    ptr += (the_fb.vwidth-img_fb_width)/2*PIXELSIZE;  // top center
   82864:	531e7461 	lsl	w1, w3, #2
    ptr += (the_fb.vheight-img_fb_height)/2*the_fb.pitch; 
   82868:	8b010000 	add	x0, x0, x1
   8286c:	8b0000a5 	add	x5, x5, x0
    for(y=0;y<img_fb_height;y++) {
   82870:	34000622 	cbz	w2, 82934 <fb_showpicture+0x124>
    char *data=IMG_DATA, pixel[4];
   82874:	90000023 	adrp	x3, 86000 <__asm_dcache_level+0xc>
            *((unsigned int*)ptr)=the_fb.isrgb ? *((unsigned int *)&pixel) 
                : (unsigned int)(pixel[0]<<16 | pixel[1]<<8 | pixel[2]);
            // *((unsigned int*)ptr)=(!the_fb.isrgb) ? *((unsigned int *)&pixel) : (unsigned int)(pixel[0]<<16 | pixel[1]<<8 | pixel[2]);
            ptr+=4;
        }
        ptr+=the_fb.pitch-img_fb_width*4;
   82878:	531e754d 	lsl	w13, w10, #2
    char *data=IMG_DATA, pixel[4];
   8287c:	91284063 	add	x3, x3, #0xa10
        for(x=0;x<img_fb_width;x++) {
   82880:	b9003bff 	str	wzr, [sp, #56]
   82884:	3400042c 	cbz	w12, 82908 <fb_showpicture+0xf8>
            HEADER_PIXEL(data, pixel);
   82888:	39400861 	ldrb	w1, [x3, #2]
   8288c:	91001063 	add	x3, x3, #0x4
   82890:	385fd062 	ldurb	w2, [x3, #-3]
   82894:	51008421 	sub	w1, w1, #0x21
   82898:	385fc060 	ldurb	w0, [x3, #-4]
   8289c:	51008442 	sub	w2, w2, #0x21
   828a0:	385ff064 	ldurb	w4, [x3, #-1]
   828a4:	13027c27 	asr	w7, w1, #2
   828a8:	51008400 	sub	w0, w0, #0x21
   828ac:	13047c48 	asr	w8, w2, #4
   828b0:	2a0210e2 	orr	w2, w7, w2, lsl #4
   828b4:	51008484 	sub	w4, w4, #0x21
   828b8:	12001c42 	and	w2, w2, #0xff
   828bc:	2a000900 	orr	w0, w8, w0, lsl #2
                : (unsigned int)(pixel[0]<<16 | pixel[1]<<8 | pixel[2]);
   828c0:	b9402926 	ldr	w6, [x9, #40]
            HEADER_PIXEL(data, pixel);
   828c4:	2a011881 	orr	w1, w4, w1, lsl #6
   828c8:	12001c00 	and	w0, w0, #0xff
   828cc:	12001c21 	and	w1, w1, #0xff
                : (unsigned int)(pixel[0]<<16 | pixel[1]<<8 | pixel[2]);
   828d0:	53185c44 	lsl	w4, w2, #8
            HEADER_PIXEL(data, pixel);
   828d4:	3900c3e0 	strb	w0, [sp, #48]
                : (unsigned int)(pixel[0]<<16 | pixel[1]<<8 | pixel[2]);
   828d8:	2a004080 	orr	w0, w4, w0, lsl #16
            HEADER_PIXEL(data, pixel);
   828dc:	3900c7e2 	strb	w2, [sp, #49]
                : (unsigned int)(pixel[0]<<16 | pixel[1]<<8 | pixel[2]);
   828e0:	2a010000 	orr	w0, w0, w1
            HEADER_PIXEL(data, pixel);
   828e4:	3900cbe1 	strb	w1, [sp, #50]
                : (unsigned int)(pixel[0]<<16 | pixel[1]<<8 | pixel[2]);
   828e8:	34000046 	cbz	w6, 828f0 <fb_showpicture+0xe0>
   828ec:	b94033e0 	ldr	w0, [sp, #48]
            *((unsigned int*)ptr)=the_fb.isrgb ? *((unsigned int *)&pixel) 
   828f0:	b80044a0 	str	w0, [x5], #4
        for(x=0;x<img_fb_width;x++) {
   828f4:	b9403be0 	ldr	w0, [sp, #56]
   828f8:	11000400 	add	w0, w0, #0x1
   828fc:	b9003be0 	str	w0, [sp, #56]
   82900:	6b0a001f 	cmp	w0, w10
   82904:	54fffc23 	b.cc	82888 <fb_showpicture+0x78>  // b.lo, b.ul, b.last
    for(y=0;y<img_fb_height;y++) {
   82908:	b9403fe0 	ldr	w0, [sp, #60]
        ptr+=the_fb.pitch-img_fb_width*4;
   8290c:	b9401921 	ldr	w1, [x9, #24]
    for(y=0;y<img_fb_height;y++) {
   82910:	11000400 	add	w0, w0, #0x1
   82914:	b9003fe0 	str	w0, [sp, #60]
        ptr+=the_fb.pitch-img_fb_width*4;
   82918:	4b0d0021 	sub	w1, w1, w13
    for(y=0;y<img_fb_height;y++) {
   8291c:	6b0b001f 	cmp	w0, w11
        ptr+=the_fb.pitch-img_fb_width*4;
   82920:	8b0100a5 	add	x5, x5, x1
    for(y=0;y<img_fb_height;y++) {
   82924:	54fffae3 	b.cc	82880 <fb_showpicture+0x70>  // b.lo, b.ul, b.last
   82928:	29420923 	ldp	w3, w2, [x9, #16]
   8292c:	4b0a0063 	sub	w3, w3, w10
   82930:	53017c63 	lsr	w3, w3, #1
    }

    // show text strings
    x = (the_fb.vwidth-img_fb_width)/2;
    y = the_fb.vheight/2 + img_fb_height/2;
   82934:	53017d6b 	lsr	w11, w11, #1
    fb_print(&x, &y, "UVA OS");
    char res[16]; 
    sprintf(res, " %dx%d", the_fb.width, the_fb.height); // debug info 
   82938:	9115a273 	add	x19, x19, #0x568
    y = the_fb.vheight/2 + img_fb_height/2;
   8293c:	0b42056b 	add	w11, w11, w2, lsr #1
    fb_print(&x, &y, "UVA OS");
   82940:	9100f3f5 	add	x21, sp, #0x3c
   82944:	9100e3f4 	add	x20, sp, #0x38
   82948:	aa1503e1 	mov	x1, x21
   8294c:	aa1403e0 	mov	x0, x20
   82950:	b0000082 	adrp	x2, 93000 <wordsworth.1725+0xce10>
   82954:	913fe042 	add	x2, x2, #0xff8
    y = the_fb.vheight/2 + img_fb_height/2;
   82958:	29072fe3 	stp	w3, w11, [sp, #56]
    fb_print(&x, &y, "UVA OS");
   8295c:	97ffff2d 	bl	82610 <fb_print>
    sprintf(res, " %dx%d", the_fb.width, the_fb.height); // debug info 
   82960:	910103f6 	add	x22, sp, #0x40
   82964:	29410e62 	ldp	w2, w3, [x19, #8]
   82968:	aa1603e0 	mov	x0, x22
   8296c:	d0000081 	adrp	x1, 94000 <wordsworth.1725+0xde10>
   82970:	91000021 	add	x1, x1, #0x0
   82974:	97fffb77 	bl	81750 <tfp_sprintf>
    fb_print(&x, &y, res);
   82978:	aa1603e2 	mov	x2, x22
   8297c:	aa1503e1 	mov	x1, x21
   82980:	aa1403e0 	mov	x0, x20
   82984:	97ffff23 	bl	82610 <fb_print>
    // __asm_flush_dcache_range(the_fb.fb, the_fb.fb + the_fb.size); 
}
   82988:	a94153f3 	ldp	x19, x20, [sp, #16]
   8298c:	a9425bf5 	ldp	x21, x22, [sp, #32]
   82990:	a8c57bfd 	ldp	x29, x30, [sp], #80
   82994:	d65f03c0 	ret

0000000000082998 <fb_init>:
int fb_init(void) {
   82998:	d10143ff 	sub	sp, sp, #0x50
   8299c:	a9017bfd 	stp	x29, x30, [sp, #16]
   829a0:	910043fd 	add	x29, sp, #0x10
   829a4:	a9035bf5 	stp	x21, x22, [sp, #48]
    mbox[0] = 35*4;     // size of the whole buf that follows
   829a8:	f0000095 	adrp	x21, 95000 <wordsworth.1725+0xee10>
    acquire(&mboxlock); 
   829ac:	f0000096 	adrp	x22, 95000 <wordsworth.1725+0xee10>
   829b0:	913922c0 	add	x0, x22, #0xe48
int fb_init(void) {
   829b4:	a90253f3 	stp	x19, x20, [sp, #32]
   829b8:	a90463f7 	stp	x23, x24, [sp, #64]
    acquire(&mboxlock); 
   829bc:	97fffc8f 	bl	81bf8 <acquire>
    mbox[0] = 35*4;     // size of the whole buf that follows
   829c0:	52801182 	mov	w2, #0x8c                  	// #140
   829c4:	f94762b3 	ldr	x19, [x21, #3776]
    mbox[5] = fbs->width;           //(val) FrameBufferInfo.width
   829c8:	f0000098 	adrp	x24, 95000 <wordsworth.1725+0xee10>
    mbox[2] = 0x48003;  //set phy width & height
   829cc:	52900060 	mov	w0, #0x8003                	// #32771
    mbox[5] = fbs->width;           //(val) FrameBufferInfo.width
   829d0:	9115a314 	add	x20, x24, #0x568
    mbox[2] = 0x48003;  //set phy width & height
   829d4:	72a00080 	movk	w0, #0x4, lsl #16
    mbox[3] = 8;        // total buf size of this tag
   829d8:	52800101 	mov	w1, #0x8                   	// #8
    mbox[0] = 35*4;     // size of the whole buf that follows
   829dc:	b9000262 	str	w2, [x19]
    mbox[7] = 0x48004;  //set virt width & height
   829e0:	52900089 	mov	w9, #0x8004                	// #32772
    mbox[1] = MBOX_REQUEST; // cpu->gpu request
   829e4:	b900067f 	str	wzr, [x19, #4]
    mbox[7] = 0x48004;  //set virt width & height
   829e8:	72a00089 	movk	w9, #0x4, lsl #16
    mbox[2] = 0x48003;  //set phy width & height
   829ec:	b9000a60 	str	w0, [x19, #8]
    mbox[12] = 0x48009; //set virt offset
   829f0:	52900128 	mov	w8, #0x8009                	// #32777
    mbox[3] = 8;        // total buf size of this tag
   829f4:	b9000e61 	str	w1, [x19, #12]
    mbox[12] = 0x48009; //set virt offset
   829f8:	72a00088 	movk	w8, #0x4, lsl #16
    mbox[5] = fbs->width;           //(val) FrameBufferInfo.width
   829fc:	b9400a80 	ldr	w0, [x20, #8]
    mbox[17] = 0x48005; //set depth
   82a00:	529000a7 	mov	w7, #0x8005                	// #32773
    mbox[4] = 8;        // req val size (needed?), to be overwritten as resp val size
   82a04:	b9001261 	str	w1, [x19, #16]
    mbox[17] = 0x48005; //set depth
   82a08:	72a00087 	movk	w7, #0x4, lsl #16
    mbox[5] = fbs->width;           //(val) FrameBufferInfo.width
   82a0c:	b9001660 	str	w0, [x19, #20]
    mbox[18] = 4;
   82a10:	52800082 	mov	w2, #0x4                   	// #4
    mbox[6] = fbs->height;          //(val) FrameBufferInfo.height
   82a14:	b9400e80 	ldr	w0, [x20, #12]
    mbox[21] = 0x48006;     //set pixel order
   82a18:	529000c6 	mov	w6, #0x8006                	// #32774
    mbox[6] = fbs->height;          //(val) FrameBufferInfo.height
   82a1c:	b9001a60 	str	w0, [x19, #24]
    mbox[21] = 0x48006;     //set pixel order
   82a20:	72a00086 	movk	w6, #0x4, lsl #16
    mbox[7] = 0x48004;  //set virt width & height
   82a24:	b9001e69 	str	w9, [x19, #28]
    mbox[25] = 0x40001;     //get framebuffer, gets alignment on request
   82a28:	52800025 	mov	w5, #0x1                   	// #1
    mbox[8] = 8;
   82a2c:	b9002261 	str	w1, [x19, #32]
    mbox[25] = 0x40001;     //get framebuffer, gets alignment on request
   82a30:	72a00085 	movk	w5, #0x4, lsl #16
    mbox[10] = fbs->vwidth;        //FrameBufferInfo.virtual_width
   82a34:	b9401289 	ldr	w9, [x20, #16]
    mbox[28] = 4096;        //req: alignment; resp: FrameBufferInfo.pointer
   82a38:	52820004 	mov	w4, #0x1000                	// #4096
    mbox[9] = 8;
   82a3c:	b9002661 	str	w1, [x19, #36]
    mbox[30] = 0x40008;     //get pitch
   82a40:	52800103 	mov	w3, #0x8                   	// #8
    mbox[10] = fbs->vwidth;        //FrameBufferInfo.virtual_width
   82a44:	b9002a69 	str	w9, [x19, #40]
    mbox[30] = 0x40008;     //get pitch
   82a48:	72a00083 	movk	w3, #0x4, lsl #16
    mbox[11] = fbs->vheight;         //FrameBufferInfo.virtual_height
   82a4c:	b9401689 	ldr	w9, [x20, #20]
    if(mbox_call(MBOX_CH_PROP) 
   82a50:	2a0103e0 	mov	w0, w1
    mbox[11] = fbs->vheight;         //FrameBufferInfo.virtual_height
   82a54:	b9002e69 	str	w9, [x19, #44]
    mbox[12] = 0x48009; //set virt offset
   82a58:	b9003268 	str	w8, [x19, #48]
    mbox[13] = 8;
   82a5c:	b9003661 	str	w1, [x19, #52]
    mbox[15] = fbs->offsetx;           
   82a60:	b9402e88 	ldr	w8, [x20, #44]
    mbox[14] = 8;
   82a64:	b9003a61 	str	w1, [x19, #56]
    mbox[15] = fbs->offsetx;           
   82a68:	b9003e68 	str	w8, [x19, #60]
    mbox[16] = fbs->offsety;           
   82a6c:	b9403288 	ldr	w8, [x20, #48]
   82a70:	b9004268 	str	w8, [x19, #64]
    mbox[17] = 0x48005; //set depth
   82a74:	b9004667 	str	w7, [x19, #68]
    mbox[18] = 4;
   82a78:	b9004a62 	str	w2, [x19, #72]
    mbox[20] = fbs->depth;       
   82a7c:	b9402687 	ldr	w7, [x20, #36]
    mbox[19] = 4;
   82a80:	b9004e62 	str	w2, [x19, #76]
    mbox[20] = fbs->depth;       
   82a84:	b9005267 	str	w7, [x19, #80]
    mbox[21] = 0x48006;     //set pixel order
   82a88:	b9005666 	str	w6, [x19, #84]
    mbox[22] = 4;
   82a8c:	b9005a62 	str	w2, [x19, #88]
    mbox[23] = 4;
   82a90:	b9005e62 	str	w2, [x19, #92]
    mbox[24] = fbs->isrgb;           //RGB, not BGR preferably
   82a94:	b9402a86 	ldr	w6, [x20, #40]
   82a98:	b9006266 	str	w6, [x19, #96]
    mbox[25] = 0x40001;     //get framebuffer, gets alignment on request
   82a9c:	b9006665 	str	w5, [x19, #100]
    mbox[26] = 8;
   82aa0:	b9006a61 	str	w1, [x19, #104]
    mbox[27] = 8;           // fxl: should be 4?? (req para size)
   82aa4:	b9006e61 	str	w1, [x19, #108]
    mbox[28] = 4096;        //req: alignment; resp: FrameBufferInfo.pointer
   82aa8:	b9007264 	str	w4, [x19, #112]
    mbox[29] = 0;           //resp: FrameBufferInfo.size
   82aac:	b900767f 	str	wzr, [x19, #116]
    mbox[30] = 0x40008;     //get pitch
   82ab0:	b9007a63 	str	w3, [x19, #120]
    mbox[31] = 4;
   82ab4:	b9007e62 	str	w2, [x19, #124]
    mbox[32] = 4;
   82ab8:	b9008262 	str	w2, [x19, #128]
    mbox[33] = 0;           //FrameBufferInfo.pitch
   82abc:	b900867f 	str	wzr, [x19, #132]
    mbox[34] = MBOX_TAG_LAST;   // the end of tag seq
   82ac0:	b9008a7f 	str	wzr, [x19, #136]
    if(mbox_call(MBOX_CH_PROP) 
   82ac4:	97fffdd7 	bl	82220 <mbox_call>
   82ac8:	34000ae0 	cbz	w0, 82c24 <fb_init+0x28c>
        && mbox[20]==fbs->depth /*depth*/ 
   82acc:	b9405261 	ldr	w1, [x19, #80]
   82ad0:	b9402680 	ldr	w0, [x20, #36]
   82ad4:	6b00003f 	cmp	w1, w0
   82ad8:	54000a61 	b.ne	82c24 <fb_init+0x28c>  // b.any
        && mbox[28]!=0 /*framebuf*/) {
   82adc:	b9407260 	ldr	w0, [x19, #112]
   82ae0:	34000a20 	cbz	w0, 82c24 <fb_init+0x28c>
        mbox[28]&=0x3FFFFFFF;  
   82ae4:	b9407260 	ldr	w0, [x19, #112]
   82ae8:	90000037 	adrp	x23, 86000 <__asm_dcache_level+0xc>
   82aec:	12007400 	and	w0, w0, #0x3fffffff
   82af0:	b9007260 	str	w0, [x19, #112]
        fbs->fb = (unsigned char *)((unsigned long)mbox[28]);   // save framebuf ptr
   82af4:	b9407260 	ldr	w0, [x19, #112]
        fbs->width=mbox[5];
   82af8:	b9401664 	ldr	w4, [x19, #20]
        fbs->height=mbox[6];
   82afc:	b9401a65 	ldr	w5, [x19, #24]
        fbs->fb = (unsigned char *)((unsigned long)mbox[28]);   // save framebuf ptr
   82b00:	2a0003e0 	mov	w0, w0
        fbs->vwidth=mbox[10];
   82b04:	b9402a66 	ldr	w6, [x19, #40]
        fbs->vheight=mbox[11];        
   82b08:	b9402e67 	ldr	w7, [x19, #44]
        fbs->depth=mbox[20]; 
   82b0c:	b9405261 	ldr	w1, [x19, #80]
        fbs->isrgb=mbox[24];         // channel order        
   82b10:	b9406268 	ldr	w8, [x19, #96]
        fbs->pitch=mbox[33];
   82b14:	b9408662 	ldr	w2, [x19, #132]
        if(fbs->pitch * fbs->vheight > mbox[29])  // possible that pitch*vheight < actual allocation
   82b18:	b9407663 	ldr	w3, [x19, #116]
        fbs->fb = (unsigned char *)((unsigned long)mbox[28]);   // save framebuf ptr
   82b1c:	f902b700 	str	x0, [x24, #1384]
        fbs->height=mbox[6];
   82b20:	29011684 	stp	w4, w5, [x20, #8]
        if(fbs->pitch * fbs->vheight > mbox[29])  // possible that pitch*vheight < actual allocation
   82b24:	1b027ce0 	mul	w0, w7, w2
        fbs->vheight=mbox[11];        
   82b28:	29021e86 	stp	w6, w7, [x20, #16]
        fbs->pitch=mbox[33];
   82b2c:	b9001a82 	str	w2, [x20, #24]
        fbs->isrgb=mbox[24];         // channel order        
   82b30:	2904a281 	stp	w1, w8, [x20, #36]
        if(fbs->pitch * fbs->vheight > mbox[29])  // possible that pitch*vheight < actual allocation
   82b34:	6b03001f 	cmp	w0, w3
   82b38:	540003c8 	b.hi	82bb0 <fb_init+0x218>  // b.pmore
        I("From GPU: fb pa: 0x%08x w %u h %u vw %u vh %u pitch %u isrgb %u", 
   82b3c:	f94762b5 	ldr	x21, [x21, #3776]
        fbs->size = PGROUNDUP(fbs->pitch * fbs->vheight);  // roundup b/c we'll reserve pages for it
   82b40:	113ffc00 	add	w0, w0, #0xfff
   82b44:	9115a318 	add	x24, x24, #0x568
        I("From GPU: fb pa: 0x%08x w %u h %u vw %u vh %u pitch %u isrgb %u", 
   82b48:	911fa2f7 	add	x23, x23, #0x7e8
   82b4c:	aa1703e1 	mov	x1, x23
   82b50:	b94072a3 	ldr	w3, [x21, #112]
   82b54:	b9000be8 	str	w8, [sp, #8]
        fbs->size = PGROUNDUP(fbs->pitch * fbs->vheight);  // roundup b/c we'll reserve pages for it
   82b58:	12144c08 	and	w8, w0, #0xfffff000
        I("From GPU: fb pa: 0x%08x w %u h %u vw %u vh %u pitch %u isrgb %u", 
   82b5c:	b90003e2 	str	w2, [sp]
   82b60:	52802922 	mov	w2, #0x149                 	// #329
   82b64:	d0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   82b68:	91010000 	add	x0, x0, #0x40
        fbs->size = PGROUNDUP(fbs->pitch * fbs->vheight);  // roundup b/c we'll reserve pages for it
   82b6c:	b9003708 	str	w8, [x24, #52]
        I("From GPU: fb pa: 0x%08x w %u h %u vw %u vh %u pitch %u isrgb %u", 
   82b70:	97fffa92 	bl	815b8 <tfp_printf>
    release(&mboxlock); 
   82b74:	913922c0 	add	x0, x22, #0xe48
   82b78:	97fffc62 	bl	81d00 <release>
    if (reserve_phys_region(mbox[28], fbs->size)) {
   82b7c:	b9403701 	ldr	w1, [x24, #52]
   82b80:	b94072a0 	ldr	w0, [x21, #112]
   82b84:	2a0003e0 	mov	w0, w0
   82b88:	94000262 	bl	83510 <reserve_phys_region>
   82b8c:	35000600 	cbnz	w0, 82c4c <fb_init+0x2b4>
    if (ret==0 && once)
   82b90:	b9403b00 	ldr	w0, [x24, #56]
   82b94:	35000360 	cbnz	w0, 82c00 <fb_init+0x268>
}
   82b98:	a9417bfd 	ldp	x29, x30, [sp, #16]
   82b9c:	a94253f3 	ldp	x19, x20, [sp, #32]
   82ba0:	a9435bf5 	ldp	x21, x22, [sp, #48]
   82ba4:	a94463f7 	ldp	x23, x24, [sp, #64]
   82ba8:	910143ff 	add	sp, sp, #0x50
   82bac:	d65f03c0 	ret
            {W("pitch %d x vheight %d!= mbox[29] %u", fbs->pitch, fbs->vheight, mbox[29]);BUG();}
   82bb0:	b9407665 	ldr	w5, [x19, #116]
   82bb4:	2a0703e4 	mov	w4, w7
   82bb8:	2a0203e3 	mov	w3, w2
   82bbc:	911fa2f3 	add	x19, x23, #0x7e8
   82bc0:	aa1303e1 	mov	x1, x19
   82bc4:	528028e2 	mov	w2, #0x147                 	// #327
   82bc8:	d0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   82bcc:	91002000 	add	x0, x0, #0x8
   82bd0:	97fffa7a 	bl	815b8 <tfp_printf>
   82bd4:	528028e2 	mov	w2, #0x147                 	// #327
   82bd8:	aa1303e1 	mov	x1, x19
   82bdc:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   82be0:	910d8000 	add	x0, x0, #0x360
   82be4:	97fffb45 	bl	818f8 <assertion_failed>
   82be8:	29421e86 	ldp	w6, w7, [x20, #16]
   82bec:	b9401a82 	ldr	w2, [x20, #24]
   82bf0:	29411684 	ldp	w4, w5, [x20, #8]
   82bf4:	b9402a88 	ldr	w8, [x20, #40]
   82bf8:	1b077c40 	mul	w0, w2, w7
   82bfc:	17ffffd0 	b	82b3c <fb_init+0x1a4>
        {fb_showpicture(); once=0;}
   82c00:	97ffff04 	bl	82810 <fb_showpicture>
   82c04:	b9003b1f 	str	wzr, [x24, #56]
        return 0; 
   82c08:	52800000 	mov	w0, #0x0                   	// #0
}
   82c0c:	a9417bfd 	ldp	x29, x30, [sp, #16]
   82c10:	a94253f3 	ldp	x19, x20, [sp, #32]
   82c14:	a9435bf5 	ldp	x21, x22, [sp, #48]
   82c18:	a94463f7 	ldp	x23, x24, [sp, #64]
   82c1c:	910143ff 	add	sp, sp, #0x50
   82c20:	d65f03c0 	ret
        E("Unable to set scr res to %d x %d\n", fbs->width, fbs->height);
   82c24:	9115a313 	add	x19, x24, #0x568
   82c28:	90000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   82c2c:	d0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   82c30:	911fa021 	add	x1, x1, #0x7e8
   82c34:	91026000 	add	x0, x0, #0x98
   82c38:	528029a2 	mov	w2, #0x14d                 	// #333
   82c3c:	29411263 	ldp	w3, w4, [x19, #8]
   82c40:	97fffa5e 	bl	815b8 <tfp_printf>
        return -2; 
   82c44:	12800020 	mov	w0, #0xfffffffe            	// #-2
   82c48:	17ffffd4 	b	82b98 <fb_init+0x200>
        E("failed to reserve fb mem. pa 0x%x size 0x%x already in use.",
   82c4c:	b94072a3 	ldr	w3, [x21, #112]
   82c50:	aa1703e1 	mov	x1, x23
   82c54:	b9403704 	ldr	w4, [x24, #52]
   82c58:	52802a62 	mov	w2, #0x153                 	// #339
   82c5c:	d0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   82c60:	91034000 	add	x0, x0, #0xd0
   82c64:	97fffa55 	bl	815b8 <tfp_printf>
            mbox[28], fbs->size); BUG(); 
   82c68:	aa1703e1 	mov	x1, x23
   82c6c:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   82c70:	52802a82 	mov	w2, #0x154                 	// #340
   82c74:	910d8000 	add	x0, x0, #0x360
   82c78:	97fffb20 	bl	818f8 <assertion_failed>
        return -1; 
   82c7c:	12800000 	mov	w0, #0xffffffff            	// #-1
   82c80:	17ffffc6 	b	82b98 <fb_init+0x200>
   82c84:	00000000 	udf	#0

0000000000082c88 <donut_canvas_init>:
_Static_assert(22*K*2  <= NN/2); // rows

static char b[N_DONUTS][1760];        // text buffer (W 80 H 22?
static signed char z[N_DONUTS][1760]; // z buffer

void donut_canvas_init(void) {
   82c88:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   82c8c:	910003fd 	mov	x29, sp
    fb_fini();
   82c90:	97fffe24 	bl	82520 <fb_fini>
    // acquire(&mboxlock);      //it's a test. so no lock

    the_fb.width = NN;
   82c94:	f0000080 	adrp	x0, 95000 <wordsworth.1725+0xee10>
   82c98:	d2805001 	mov	x1, #0x280                 	// #640
   82c9c:	f2c05001 	movk	x1, #0x280, lsl #32
   82ca0:	f9478400 	ldr	x0, [x0, #3848]
    the_fb.height = NN;

    the_fb.vwidth = NN;
   82ca4:	a9008401 	stp	x1, x1, [x0, #8]
    the_fb.vheight = NN;

    if (fb_init() != 0)
   82ca8:	97ffff3c 	bl	82998 <fb_init>
   82cac:	35000060 	cbnz	w0, 82cb8 <donut_canvas_init+0x30>
        BUG();
}
   82cb0:	a8c17bfd 	ldp	x29, x30, [sp], #16
   82cb4:	d65f03c0 	ret
   82cb8:	a8c17bfd 	ldp	x29, x30, [sp], #16
        BUG();
   82cbc:	d0000081 	adrp	x1, 94000 <wordsworth.1725+0xde10>
   82cc0:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   82cc4:	9104c021 	add	x1, x1, #0x130
   82cc8:	910d8000 	add	x0, x0, #0x360
   82ccc:	528007e2 	mov	w2, #0x3f                  	// #63
   82cd0:	17fffb0a 	b	818f8 <assertion_failed>
   82cd4:	d503201f 	nop

0000000000082cd8 <donut_pixel>:
// draw dots on canvas, closer to the original js version (see comment at the end)
// Q4: quest: "two donuts". understand code below
// Q7: quest: "donuts in sync"
static int frame_count[N_DONUTS] = {0};
void donut_pixel(int idx) {
    int sA = 1024, cA = 0, sB = 1024, cB = 0, _;
   82cd8:	93407c05 	sxtw	x5, w0
                    lumince = lumince<0? 0 : lumince/5; 
                    lumince = lumince<255? lumince : 255; 

                int o = x + 80 * y; // fxl: 80 chars per row
                signed char zz = (x6 - K2) >> 15;
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82cdc:	937d7c01 	sbfiz	x1, x0, #3, #32
   82ce0:	cb050021 	sub	x1, x1, x5
            R(9, 7, cj, sj) // rotate j
        }
        //R(5, 7, cA, sA);
        //R(5, 8, cB, sB);

        for (int t = 0; t <=idx%4; t++) {
   82ce4:	6b0003e3 	negs	w3, w0
   82ce8:	5280dc02 	mov	w2, #0x6e0                 	// #1760
void donut_pixel(int idx) {
   82cec:	a9b27bfd 	stp	x29, x30, [sp, #-224]!
        for (int t = 0; t <=idx%4; t++) {
   82cf0:	12000404 	and	w4, w0, #0x3
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82cf4:	d37df021 	lsl	x1, x1, #3
        for (int t = 0; t <=idx%4; t++) {
   82cf8:	12000463 	and	w3, w3, #0x3
   82cfc:	5a834483 	csneg	w3, w4, w3, mi	// mi = first
   82d00:	9b227c02 	smull	x2, w0, w2
   82d04:	7100081f 	cmp	w0, #0x2
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82d08:	cb050020 	sub	x0, x1, x5
void donut_pixel(int idx) {
   82d0c:	910003fd 	mov	x29, sp
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82d10:	d37be800 	lsl	x0, x0, #5
        memset(b[idx], 0, 1760);  // text buffer 0: black bkgnd
   82d14:	d00000e1 	adrp	x1, a0000 <z+0x9d08>
        for (int t = 0; t <=idx%4; t++) {
   82d18:	b9007fe3 	str	w3, [sp, #124]
        memset(b[idx], 0, 1760);  // text buffer 0: black bkgnd
   82d1c:	913b6023 	add	x3, x1, #0xed8
        memset(z[idx], 127, 1760); // z buffer
   82d20:	900000a1 	adrp	x1, 96000 <stdout_putf>
   82d24:	910be021 	add	x1, x1, #0x2f8
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82d28:	f90067e0 	str	x0, [sp, #200]
        memset(b[idx], 0, 1760);  // text buffer 0: black bkgnd
   82d2c:	8b030040 	add	x0, x2, x3
void donut_pixel(int idx) {
   82d30:	a90573fb 	stp	x27, x28, [sp, #80]
                    lumince = lumince<0? 0 : lumince/5; 
   82d34:	528cccfc 	mov	w28, #0x6667                	// #26215
    int sA = 1024, cA = 0, sB = 1024, cB = 0, _;
   82d38:	52808003 	mov	w3, #0x400                 	// #1024
        memset(b[idx], 0, 1760);  // text buffer 0: black bkgnd
   82d3c:	f9003be0 	str	x0, [sp, #112]
        memset(z[idx], 127, 1760); // z buffer
   82d40:	8b010040 	add	x0, x2, x1
    int sA = 1024, cA = 0, sB = 1024, cB = 0, _;
   82d44:	52800004 	mov	w4, #0x0                   	// #0
   82d48:	52800007 	mov	w7, #0x0                   	// #0
   82d4c:	12807fe6 	mov	w6, #0xfffffc00            	// #-1024
                    lumince = lumince<0? 0 : lumince/5; 
   82d50:	72acccdc 	movk	w28, #0x6666, lsl #16
void donut_pixel(int idx) {
   82d54:	a90153f3 	stp	x19, x20, [sp, #16]
    int sA = 1024, cA = 0, sB = 1024, cB = 0, _;
   82d58:	52800013 	mov	w19, #0x0                   	// #0
void donut_pixel(int idx) {
   82d5c:	a9025bf5 	stp	x21, x22, [sp, #32]
   82d60:	a90363f7 	stp	x23, x24, [sp, #48]
   82d64:	a9046bf9 	stp	x25, x26, [sp, #64]
                    lumince = lumince<0? 0 : lumince/5; 
   82d68:	b9006be4 	str	w4, [sp, #104]
   82d6c:	b9006fe3 	str	w3, [sp, #108]
   82d70:	b9007be3 	str	w3, [sp, #120]
   82d74:	f90043e5 	str	x5, [sp, #128]
   82d78:	29141be7 	stp	w7, w6, [sp, #160]
        memset(z[idx], 127, 1760); // z buffer
   82d7c:	f90057e0 	str	x0, [sp, #168]
   82d80:	1a9f17e0 	cset	w0, eq	// eq = none
   82d84:	b900c7e0 	str	w0, [sp, #196]
        memset(b[idx], 0, 1760);  // text buffer 0: black bkgnd
   82d88:	f9403be0 	ldr	x0, [sp, #112]
   82d8c:	5280dc02 	mov	w2, #0x6e0                 	// #1760
   82d90:	52800001 	mov	w1, #0x0                   	// #0
        int sj = 0, cj = 1024;
   82d94:	5280801a 	mov	w26, #0x400                 	// #1024
   82d98:	52800019 	mov	w25, #0x0                   	// #0
   82d9c:	52801ff7 	mov	w23, #0xff                  	// #255
        memset(b[idx], 0, 1760);  // text buffer 0: black bkgnd
   82da0:	97fffae2 	bl	81928 <memset>
                R(5, 8, ci, si) // rotate i
   82da4:	52a00616 	mov	w22, #0x300000              	// #3145728
        memset(z[idx], 127, 1760); // z buffer
   82da8:	f94057e0 	ldr	x0, [sp, #168]
   82dac:	5280dc02 	mov	w2, #0x6e0                 	// #1760
   82db0:	52800fe1 	mov	w1, #0x7f                  	// #127
   82db4:	97fffadd 	bl	81928 <memset>
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82db8:	900000a0 	adrp	x0, 96000 <stdout_putf>
   82dbc:	910be018 	add	x24, x0, #0x2f8
                    b[idx][o] = lumince;
   82dc0:	d00000e0 	adrp	x0, a0000 <z+0x9d08>
   82dc4:	913b601b 	add	x27, x0, #0xed8
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82dc8:	f94067e0 	ldr	x0, [sp, #200]
        memset(z[idx], 127, 1760); // z buffer
   82dcc:	52800b5e 	mov	w30, #0x5a                  	// #90
   82dd0:	294d17e4 	ldp	w4, w5, [sp, #104]
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82dd4:	8b000318 	add	x24, x24, x0
   82dd8:	b9407be3 	ldr	w3, [sp, #120]
                    b[idx][o] = lumince;
   82ddc:	8b00037b 	add	x27, x27, x0
   82de0:	29541be7 	ldp	w7, w6, [sp, #160]
                    x5 = sA * sj >> 10,
   82de4:	1b197cac 	mul	w12, w5, w25
                    x2 = cA * sj >> 10,
   82de8:	1b197c8d 	mul	w13, w4, w25
            int si = 0, ci = 1024; // sine and cosine of angle i
   82dec:	52808000 	mov	w0, #0x400                 	// #1024
                    lumince = (((-cA * x7 - cB * ((-sA * x7 >> 10) + x2) - ci * (cj * sB >> 10)) >> 10) - x5); 
   82df0:	1b1a7c6f 	mul	w15, w3, w26
                    x6 = K2 + R1 * 1024 * x5 + cA * x3,
   82df4:	12165590 	and	w16, w12, #0xfffffc00
   82df8:	1120034e 	add	w14, w26, #0x800
   82dfc:	11540210 	add	w16, w16, #0x500, lsl #12
                    x5 = sA * sj >> 10,
   82e00:	130a7d8c 	asr	w12, w12, #10
                    x2 = cA * sj >> 10,
   82e04:	130a7dad 	asr	w13, w13, #10
                    lumince = (((-cA * x7 - cB * ((-sA * x7 >> 10) + x2) - ci * (cj * sB >> 10)) >> 10) - x5); 
   82e08:	130a7def 	asr	w15, w15, #10
   82e0c:	2a0003f1 	mov	w17, w0
   82e10:	5280288b 	mov	w11, #0x144                 	// #324
            int si = 0, ci = 1024; // sine and cosine of angle i
   82e14:	52800001 	mov	w1, #0x0                   	// #0
                    x3 = si * x0 >> 10,
   82e18:	1b0e7c28 	mul	w8, w1, w14
                R(5, 8, ci, si) // rotate i
   82e1c:	0b010834 	add	w20, w1, w1, lsl #2
                    x1 = ci * x0 >> 10,
   82e20:	1b0e7e35 	mul	w21, w17, w14
                R(5, 8, ci, si) // rotate i
   82e24:	0b110a22 	add	w2, w17, w17, lsl #2
   82e28:	4b942234 	sub	w20, w17, w20, asr #8
                    x7 = cj * si >> 10,
   82e2c:	4b012d09 	sub	w9, w8, w1, lsl #11
                    x3 = si * x0 >> 10,
   82e30:	130a7d08 	asr	w8, w8, #10
                R(5, 8, ci, si) // rotate i
   82e34:	0b822021 	add	w1, w1, w2, asr #8
                    x1 = ci * x0 >> 10,
   82e38:	130a7eb5 	asr	w21, w21, #10
                    x7 = cj * si >> 10,
   82e3c:	130a7d29 	asr	w9, w9, #10
                R(5, 8, ci, si) // rotate i
   82e40:	1b14da82 	msub	w2, w20, w20, w22
                    x4 = R1 * x2 - (sA * x3 >> 10),
   82e44:	1b087caa 	mul	w10, w5, w8
                    x = 25 + 30 * (cB * x1 - sB * x4) / x6,
   82e48:	1b157e72 	mul	w18, w19, w21
                    lumince = (((-cA * x7 - cB * ((-sA * x7 >> 10) + x2) - ci * (cj * sB >> 10)) >> 10) - x5); 
   82e4c:	1b067d20 	mul	w0, w9, w6
                    x4 = R1 * x2 - (sA * x3 >> 10),
   82e50:	4b8a29aa 	sub	w10, w13, w10, asr #10
                R(5, 8, ci, si) // rotate i
   82e54:	1b018822 	msub	w2, w1, w1, w2
                    y = 12 + 15 * (cB * x4 + sB * x1) / x6,
   82e58:	1b157c75 	mul	w21, w3, w21
                    lumince = (((-cA * x7 - cB * ((-sA * x7 >> 10) + x2) - ci * (cj * sB >> 10)) >> 10) - x5); 
   82e5c:	0b8029a0 	add	w0, w13, w0, asr #10
   82e60:	1b077d29 	mul	w9, w9, w7
                    x = 25 + 30 * (cB * x1 - sB * x4) / x6,
   82e64:	1b0ac872 	msub	w18, w3, w10, w18
                R(5, 8, ci, si) // rotate i
   82e68:	130b7c42 	asr	w2, w2, #11
                    y = 12 + 15 * (cB * x4 + sB * x1) / x6,
   82e6c:	1b0a566a 	madd	w10, w19, w10, w21
                    lumince = (((-cA * x7 - cB * ((-sA * x7 >> 10) + x2) - ci * (cj * sB >> 10)) >> 10) - x5); 
   82e70:	1b13a400 	msub	w0, w0, w19, w9
   82e74:	52800009 	mov	w9, #0x0                   	// #0
                    x = 25 + 30 * (cB * x1 - sB * x4) / x6,
   82e78:	531c6e55 	lsl	w21, w18, #4
                    lumince = (((-cA * x7 - cB * ((-sA * x7 >> 10) + x2) - ci * (cj * sB >> 10)) >> 10) - x5); 
   82e7c:	1b1181e0 	msub	w0, w15, w17, w0
                    x = 25 + 30 * (cB * x1 - sB * x4) / x6,
   82e80:	4b1202b2 	sub	w18, w21, w18
                    x6 = K2 + R1 * 1024 * x5 + cA * x3,
   82e84:	1b084088 	madd	w8, w4, w8, w16
                    y = 12 + 15 * (cB * x4 + sB * x1) / x6,
   82e88:	531c6d55 	lsl	w21, w10, #4
                R(5, 8, ci, si) // rotate i
   82e8c:	1b027e91 	mul	w17, w20, w2
                    y = 12 + 15 * (cB * x4 + sB * x1) / x6,
   82e90:	4b0a02aa 	sub	w10, w21, w10
                    lumince = (((-cA * x7 - cB * ((-sA * x7 >> 10) + x2) - ci * (cj * sB >> 10)) >> 10) - x5); 
   82e94:	130a7c00 	asr	w0, w0, #10
                R(5, 8, ci, si) // rotate i
   82e98:	1b027c21 	mul	w1, w1, w2
                    x = 25 + 30 * (cB * x1 - sB * x4) / x6,
   82e9c:	531f7a52 	lsl	w18, w18, #1
                    lumince = lumince<0? 0 : lumince/5; 
   82ea0:	6b0c0000 	subs	w0, w0, w12
                R(5, 8, ci, si) // rotate i
   82ea4:	130a7e31 	asr	w17, w17, #10
                    y = 12 + 15 * (cB * x4 + sB * x1) / x6,
   82ea8:	1ac80d4a 	sdiv	w10, w10, w8
                    lumince = lumince<0? 0 : lumince/5; 
   82eac:	540000c4 	b.mi	82ec4 <donut_pixel+0x1ec>  // b.first
   82eb0:	9b3c7c09 	smull	x9, w0, w28
   82eb4:	9361fd29 	asr	x9, x9, #33
   82eb8:	4b807d29 	sub	w9, w9, w0, asr #31
   82ebc:	7103fd3f 	cmp	w9, #0xff
   82ec0:	1a97d129 	csel	w9, w9, w23, le
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82ec4:	11002d40 	add	w0, w10, #0xb
                R(5, 8, ci, si) // rotate i
   82ec8:	130a7c21 	asr	w1, w1, #10
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82ecc:	7100501f 	cmp	w0, #0x14
   82ed0:	54000208 	b.hi	82f10 <donut_pixel+0x238>  // b.pmore
                    x = 25 + 30 * (cB * x1 - sB * x4) / x6,
   82ed4:	1ac80e52 	sdiv	w18, w18, w8
                    y = 12 + 15 * (cB * x4 + sB * x1) / x6,
   82ed8:	11003142 	add	w2, w10, #0xc
                signed char zz = (x6 - K2) >> 15;
   82edc:	51540108 	sub	w8, w8, #0x500, lsl #12
                int o = x + 80 * y; // fxl: 80 chars per row
   82ee0:	0b020842 	add	w2, w2, w2, lsl #2
                signed char zz = (x6 - K2) >> 15;
   82ee4:	934f5908 	sbfx	x8, x8, #15, #8
                    x = 25 + 30 * (cB * x1 - sB * x4) / x6,
   82ee8:	11006640 	add	w0, w18, #0x19
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82eec:	11006252 	add	w18, w18, #0x18
   82ef0:	71013a5f 	cmp	w18, #0x4e
   82ef4:	540000e8 	b.hi	82f10 <donut_pixel+0x238>  // b.pmore
                int o = x + 80 * y; // fxl: 80 chars per row
   82ef8:	0b021002 	add	w2, w0, w2, lsl #4
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82efc:	38e2cb00 	ldrsb	w0, [x24, w2, sxtw]
   82f00:	6b08001f 	cmp	w0, w8
   82f04:	5400006d 	b.le	82f10 <donut_pixel+0x238>
                    z[idx][o] = zz;
   82f08:	3822cb08 	strb	w8, [x24, w2, sxtw]
                    b[idx][o] = lumince;
   82f0c:	3822cb69 	strb	w9, [x27, w2, sxtw]
            for (int i = 0; i < 324; i++) {
   82f10:	7100056b 	subs	w11, w11, #0x1
   82f14:	54fff821 	b.ne	82e18 <donut_pixel+0x140>  // b.any
            R(9, 7, cj, sj) // rotate j
   82f18:	0b190f21 	add	w1, w25, w25, lsl #3
   82f1c:	0b1a0f40 	add	w0, w26, w26, lsl #3
        for (int j = 0; j < 90; j++) {
   82f20:	710007de 	subs	w30, w30, #0x1
            R(9, 7, cj, sj) // rotate j
   82f24:	4b811f5a 	sub	w26, w26, w1, asr #7
   82f28:	0b801f39 	add	w25, w25, w0, asr #7
   82f2c:	1b1adb40 	msub	w0, w26, w26, w22
   82f30:	1b198320 	msub	w0, w25, w25, w0
   82f34:	130b7c00 	asr	w0, w0, #11
   82f38:	1b007f5a 	mul	w26, w26, w0
   82f3c:	1b007f39 	mul	w25, w25, w0
   82f40:	130a7f5a 	asr	w26, w26, #10
   82f44:	130a7f39 	asr	w25, w25, #10
        for (int j = 0; j < 90; j++) {
   82f48:	54fff4e1 	b.ne	82de4 <donut_pixel+0x10c>  // b.any
        for (int t = 0; t <=idx%4; t++) {
   82f4c:	b9407fe0 	ldr	w0, [sp, #124]
   82f50:	52800008 	mov	w8, #0x0                   	// #0
            R(5, 7, cA, sA);
   82f54:	52a00609 	mov	w9, #0x300000              	// #3145728
        for (int t = 0; t <=idx%4; t++) {
   82f58:	37f80460 	tbnz	w0, #31, 82fe4 <donut_pixel+0x30c>
   82f5c:	294d17e4 	ldp	w4, w5, [sp, #104]
   82f60:	b9407be3 	ldr	w3, [sp, #120]
            R(5, 7, cA, sA);
   82f64:	0b0508a6 	add	w6, w5, w5, lsl #2
            R(5, 8, cB, sB);
   82f68:	0b030861 	add	w1, w3, w3, lsl #2
            R(5, 7, cA, sA);
   82f6c:	0b040882 	add	w2, w4, w4, lsl #2
            R(5, 8, cB, sB);
   82f70:	0b130a60 	add	w0, w19, w19, lsl #2
   82f74:	4b812261 	sub	w1, w19, w1, asr #8
            R(5, 7, cA, sA);
   82f78:	4b861c84 	sub	w4, w4, w6, asr #7
   82f7c:	0b821ca2 	add	w2, w5, w2, asr #7
            R(5, 8, cB, sB);
   82f80:	0b802060 	add	w0, w3, w0, asr #8
        for (int t = 0; t <=idx%4; t++) {
   82f84:	b9407fe3 	ldr	w3, [sp, #124]
   82f88:	11000508 	add	w8, w8, #0x1
            R(5, 7, cA, sA);
   82f8c:	1b04a485 	msub	w5, w4, w4, w9
        for (int t = 0; t <=idx%4; t++) {
   82f90:	6b03011f 	cmp	w8, w3
            R(5, 8, cB, sB);
   82f94:	1b01a423 	msub	w3, w1, w1, w9
            R(5, 7, cA, sA);
   82f98:	1b029445 	msub	w5, w2, w2, w5
            R(5, 8, cB, sB);
   82f9c:	1b008c03 	msub	w3, w0, w0, w3
            R(5, 7, cA, sA);
   82fa0:	130b7ca5 	asr	w5, w5, #11
            R(5, 8, cB, sB);
   82fa4:	130b7c63 	asr	w3, w3, #11
            R(5, 7, cA, sA);
   82fa8:	1b057c84 	mul	w4, w4, w5
            R(5, 8, cB, sB);
   82fac:	1b037c21 	mul	w1, w1, w3
            R(5, 7, cA, sA);
   82fb0:	1b057c42 	mul	w2, w2, w5
            R(5, 8, cB, sB);
   82fb4:	1b037c00 	mul	w0, w0, w3
            R(5, 7, cA, sA);
   82fb8:	130a7c84 	asr	w4, w4, #10
            R(5, 8, cB, sB);
   82fbc:	130a7c33 	asr	w19, w1, #10
            R(5, 7, cA, sA);
   82fc0:	130a7c45 	asr	w5, w2, #10
            R(5, 8, cB, sB);
   82fc4:	130a7c03 	asr	w3, w0, #10
        for (int t = 0; t <=idx%4; t++) {
   82fc8:	54fffced 	b.le	82f64 <donut_pixel+0x28c>
   82fcc:	4b0403e0 	neg	w0, w4
   82fd0:	290d17e4 	stp	w4, w5, [sp, #104]
   82fd4:	b9007be3 	str	w3, [sp, #120]
   82fd8:	b900a3e0 	str	w0, [sp, #160]
   82fdc:	4b0503e0 	neg	w0, w5
   82fe0:	b900a7e0 	str	w0, [sp, #164]
        }

        // screen_clear(idx);   // not needed
        int offsetx = xoff[idx], offsety = yoff[idx]; 
   82fe4:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   82fe8:	91048000 	add	x0, x0, #0x120
   82fec:	f94043e3 	ldr	x3, [sp, #128]
   82ff0:	9101a001 	add	x1, x0, #0x68
                    // PIXEL clr = b[k]; // blue only
                    PIXEL clr = int2rgb(b[idx][k]); // to a color spectrum
                    // W("fb %lx idx %d xx %d yy %d pitch %d",
                    //     (unsigned long)the_fb.fb, idx, xx, yy, the_fb.pitch);
                    // expand to a neighborhood of 4 pixels
                    setpixel(the_fb.fb, xx, yy, the_fb.pitch, clr);
   82ff4:	f0000082 	adrp	x2, 95000 <wordsworth.1725+0xee10>
        int offsetx = xoff[idx], offsety = yoff[idx]; 
   82ff8:	d280001b 	mov	x27, #0x0                   	// #0
        int y = 0, x = 0;
   82ffc:	5280001a 	mov	w26, #0x0                   	// #0
   83000:	52800017 	mov	w23, #0x0                   	// #0
                    setpixel(the_fb.fb, xx, yy, the_fb.pitch, clr);
   83004:	f9478442 	ldr	x2, [x2, #3848]
        int offsetx = xoff[idx], offsety = yoff[idx]; 
   83008:	529999b9 	mov	w25, #0xcccd                	// #52429
   8300c:	b8637821 	ldr	w1, [x1, x3, lsl #2]
            if (k % 80) {
   83010:	52866678 	mov	w24, #0x3333                	// #13107
        int offsetx = xoff[idx], offsety = yoff[idx]; 
   83014:	b8637800 	ldr	w0, [x0, x3, lsl #2]
            if (k % 80) {
   83018:	2a1a03f5 	mov	w21, w26
   8301c:	aa1b03f6 	mov	x22, x27
   83020:	b900d3f3 	str	w19, [sp, #208]
   83024:	2a1703f3 	mov	w19, w23
        int offsetx = xoff[idx], offsety = yoff[idx]; 
   83028:	72b99999 	movk	w25, #0xcccc, lsl #16
            if (k % 80) {
   8302c:	72a06678 	movk	w24, #0x333, lsl #16
                    setpixel(the_fb.fb, xx+1, yy, the_fb.pitch, clr);
   83030:	a9088be2 	stp	x2, x2, [sp, #136]
                    setpixel(the_fb.fb, xx, yy+1, the_fb.pitch, clr);
   83034:	f9004fe2 	str	x2, [sp, #152]
        int offsetx = xoff[idx], offsety = yoff[idx]; 
   83038:	291607e0 	stp	w0, w1, [sp, #176]
   8303c:	d503201f 	nop
   83040:	1b197ec0 	mul	w0, w22, w25
   83044:	13801000 	ror	w0, w0, #4
            if (k % 80) {
   83048:	6b18001f 	cmp	w0, w24
   8304c:	54000ae9 	b.ls	831a8 <donut_pixel+0x4d0>  // b.plast
                if (x < 50) {
   83050:	7100c6bf 	cmp	w21, #0x31
   83054:	5400028d 	b.le	830a4 <donut_pixel+0x3cc>
                    setpixel(the_fb.fb, xx+1, yy+1, the_fb.pitch, clr);
                }
                x++;
   83058:	110006b5 	add	w21, w21, #0x1
        for (int k = 0; 1761 > k; k++) {
   8305c:	910006d6 	add	x22, x22, #0x1
   83060:	f11b86df 	cmp	x22, #0x6e1
   83064:	54fffee1 	b.ne	83040 <donut_pixel+0x368>  // b.any
                y++;
                x = 1;
            }
        }
        /* STUDENT: TODO: your code here */
        yield();
   83068:	b940d3f3 	ldr	w19, [sp, #208]
   8306c:	940002d1 	bl	83bb0 <yield>

        frame_count[idx]++;
   83070:	f94043e2 	ldr	x2, [sp, #128]
   83074:	f0000080 	adrp	x0, 96000 <stdout_putf>
   83078:	910a4001 	add	x1, x0, #0x290
   8307c:	b8627820 	ldr	w0, [x1, x2, lsl #2]
   83080:	11000400 	add	w0, w0, #0x1
   83084:	b8227820 	str	w0, [x1, x2, lsl #2]
        if (frame_count[idx] == 100 && idx==2) {
   83088:	7101901f 	cmp	w0, #0x64
   8308c:	b940c7e0 	ldr	w0, [sp, #196]
   83090:	7a400804 	ccmp	w0, #0x0, #0x4, eq	// eq = none
   83094:	54ffe7a0 	b.eq	82d88 <donut_pixel+0xb0>  // b.none
            exit_process(0);
   83098:	52800000 	mov	w0, #0x0                   	// #0
   8309c:	940003c3 	bl	83fa8 <exit_process>
   830a0:	17ffff3a 	b	82d88 <donut_pixel+0xb0>
                    int xx=x*K+offsetx, yy=y*K*2+offsety;
   830a4:	b940b3e1 	ldr	w1, [sp, #176]
                    PIXEL clr = int2rgb(b[idx][k]); // to a color spectrum
   830a8:	f9403be0 	ldr	x0, [sp, #112]
                    int xx=x*K+offsetx, yy=y*K*2+offsety;
   830ac:	0b15043b 	add	w27, w1, w21, lsl #1
   830b0:	b940b7e1 	ldr	w1, [sp, #180]
                    PIXEL clr = int2rgb(b[idx][k]); // to a color spectrum
   830b4:	38766800 	ldrb	w0, [x0, x22]
                    int xx=x*K+offsetx, yy=y*K*2+offsety;
   830b8:	0b13083a 	add	w26, w1, w19, lsl #2

// map luminance [0..255] to rgb color
// value: 0..255, PIXEL: argb
static PIXEL int2rgb (int value) {
    int r,g,b;     
    if (value >= 0 && value <= 85) {
   830bc:	7101541f 	cmp	w0, #0x55
   830c0:	540007a8 	b.hi	831b4 <donut_pixel+0x4dc>  // b.pmore
        // Black to Yellow (R stays 0, G increases, B stays 0)
        r = 0;
        g = (value * 3);
   830c4:	0b000400 	add	w0, w0, w0, lsl #1
   830c8:	53185c14 	lsl	w20, w0, #8
                    setpixel(the_fb.fb, xx, yy, the_fb.pitch, clr);
   830cc:	f94047e1 	ldr	x1, [sp, #136]
    assert(x >= 0 && y >= 0); // important guard
   830d0:	2a3b03e0 	mvn	w0, w27
   830d4:	2a3a03e7 	mvn	w7, w26
   830d8:	531f7c00 	lsr	w0, w0, #31
   830dc:	b900c3e0 	str	w0, [sp, #192]
                    setpixel(the_fb.fb, xx, yy, the_fb.pitch, clr);
   830e0:	f940002b 	ldr	x11, [x1]
    assert(x >= 0 && y >= 0); // important guard
   830e4:	7100001f 	cmp	w0, #0x0
   830e8:	531f7cf7 	lsr	w23, w7, #31
                    setpixel(the_fb.fb, xx, yy, the_fb.pitch, clr);
   830ec:	b940182c 	ldr	w12, [x1, #24]
    assert(x >= 0 && y >= 0); // important guard
   830f0:	7a401ae4 	ccmp	w23, #0x0, #0x4, ne	// ne = any
   830f4:	aa0b03e9 	mov	x9, x11
   830f8:	540007e0 	b.eq	831f4 <donut_pixel+0x51c>  // b.none
    *(PIXEL *)(buf + y * pit + x * PIXELSIZE) = p;
   830fc:	531e776a 	lsl	w10, w27, #2
   83100:	1b1a7d8c 	mul	w12, w12, w26
    assert(x >= 0 && y >= 0); // important guard
   83104:	3100077f 	cmn	w27, #0x1
   83108:	aa0903e7 	mov	x7, x9
    *(PIXEL *)(buf + y * pit + x * PIXELSIZE) = p;
   8310c:	93407d40 	sxtw	x0, w10
   83110:	f9005fe0 	str	x0, [sp, #184]
   83114:	8b00016b 	add	x11, x11, x0
    assert(x >= 0 && y >= 0); // important guard
   83118:	1a9fb7fb 	cset	w27, ge	// ge = tcont
                    setpixel(the_fb.fb, xx+1, yy, the_fb.pitch, clr);
   8311c:	f9404be0 	ldr	x0, [sp, #144]
    assert(x >= 0 && y >= 0); // important guard
   83120:	7100037f 	cmp	w27, #0x0
    *(PIXEL *)(buf + y * pit + x * PIXELSIZE) = p;
   83124:	b82cc974 	str	w20, [x11, w12, sxtw]
    assert(x >= 0 && y >= 0); // important guard
   83128:	7a401ae4 	ccmp	w23, #0x0, #0x4, ne	// ne = any
                    setpixel(the_fb.fb, xx+1, yy, the_fb.pitch, clr);
   8312c:	b9401817 	ldr	w23, [x0, #24]
    assert(x >= 0 && y >= 0); // important guard
   83130:	54000b00 	b.eq	83290 <donut_pixel+0x5b8>  // b.none
    *(PIXEL *)(buf + y * pit + x * PIXELSIZE) = p;
   83134:	1100114a 	add	w10, w10, #0x4
   83138:	1b1a7ee8 	mul	w8, w23, w26
                    setpixel(the_fb.fb, xx, yy+1, the_fb.pitch, clr);
   8313c:	1100075a 	add	w26, w26, #0x1
    assert(x >= 0 && y >= 0); // important guard
   83140:	b940c3e0 	ldr	w0, [sp, #192]
    *(PIXEL *)(buf + y * pit + x * PIXELSIZE) = p;
   83144:	93407d57 	sxtw	x23, w10
    assert(x >= 0 && y >= 0); // important guard
   83148:	2a3a03ea 	mvn	w10, w26
    *(PIXEL *)(buf + y * pit + x * PIXELSIZE) = p;
   8314c:	8b170129 	add	x9, x9, x23
    assert(x >= 0 && y >= 0); // important guard
   83150:	531f7d4a 	lsr	w10, w10, #31
   83154:	7100015f 	cmp	w10, #0x0
   83158:	7a401804 	ccmp	w0, #0x0, #0x4, ne	// ne = any
    *(PIXEL *)(buf + y * pit + x * PIXELSIZE) = p;
   8315c:	b828c934 	str	w20, [x9, w8, sxtw]
                    setpixel(the_fb.fb, xx, yy+1, the_fb.pitch, clr);
   83160:	f9404fe0 	ldr	x0, [sp, #152]
   83164:	aa0703e8 	mov	x8, x7
   83168:	b9401809 	ldr	w9, [x0, #24]
    assert(x >= 0 && y >= 0); // important guard
   8316c:	54000740 	b.eq	83254 <donut_pixel+0x57c>  // b.none
    *(PIXEL *)(buf + y * pit + x * PIXELSIZE) = p;
   83170:	f9405fe0 	ldr	x0, [sp, #184]
   83174:	1b097f49 	mul	w9, w26, w9
    assert(x >= 0 && y >= 0); // important guard
   83178:	7100015f 	cmp	w10, #0x0
    *(PIXEL *)(buf + y * pit + x * PIXELSIZE) = p;
   8317c:	8b0000e7 	add	x7, x7, x0
                    setpixel(the_fb.fb, xx+1, yy+1, the_fb.pitch, clr);
   83180:	d0000080 	adrp	x0, 95000 <wordsworth.1725+0xee10>
    assert(x >= 0 && y >= 0); // important guard
   83184:	7a401b64 	ccmp	w27, #0x0, #0x4, ne	// ne = any
                    setpixel(the_fb.fb, xx+1, yy+1, the_fb.pitch, clr);
   83188:	f9478400 	ldr	x0, [x0, #3848]
    *(PIXEL *)(buf + y * pit + x * PIXELSIZE) = p;
   8318c:	b829c8f4 	str	w20, [x7, w9, sxtw]
                    setpixel(the_fb.fb, xx+1, yy+1, the_fb.pitch, clr);
   83190:	b9401807 	ldr	w7, [x0, #24]
    assert(x >= 0 && y >= 0); // important guard
   83194:	540004a0 	b.eq	83228 <donut_pixel+0x550>  // b.none
    *(PIXEL *)(buf + y * pit + x * PIXELSIZE) = p;
   83198:	1b077f46 	mul	w6, w26, w7
   8319c:	8b170108 	add	x8, x8, x23
   831a0:	b826c914 	str	w20, [x8, w6, sxtw]
}
   831a4:	17ffffad 	b	83058 <donut_pixel+0x380>
                y++;
   831a8:	11000673 	add	w19, w19, #0x1
                x = 1;
   831ac:	52800035 	mov	w21, #0x1                   	// #1
   831b0:	17ffffab 	b	8305c <donut_pixel+0x384>
        b = 0;
    } else if (value > 85 && value <= 170) {
   831b4:	51015801 	sub	w1, w0, #0x56
   831b8:	7101503f 	cmp	w1, #0x54
   831bc:	54000108 	b.hi	831dc <donut_pixel+0x504>  // b.pmore
        // Yellow to Cyan (G stays 255, R decreases, B increases)
        r = 255 - ((value - 85) * 3);
   831c0:	51015400 	sub	w0, w0, #0x55
   831c4:	4b000814 	sub	w20, w0, w0, lsl #2
        g = 255;
        b = (value - 85) * 3;
   831c8:	0b000400 	add	w0, w0, w0, lsl #1
        r = 255 - ((value - 85) * 3);
   831cc:	1103fe94 	add	w20, w20, #0xff
   831d0:	2a144000 	orr	w0, w0, w20, lsl #16
   831d4:	32181c14 	orr	w20, w0, #0xff00
   831d8:	17ffffbd 	b	830cc <donut_pixel+0x3f4>
    } else if (value > 170 && value <= 255) {
        // Cyan to Blue (G decreases, B stays 255, R stays 0)
        r = 0;
        g = 255 - ((value - 170) * 3);
   831dc:	5102a800 	sub	w0, w0, #0xaa
   831e0:	4b000800 	sub	w0, w0, w0, lsl #2
   831e4:	1103fc14 	add	w20, w0, #0xff
   831e8:	53185e94 	lsl	w20, w20, #8
   831ec:	32001e94 	orr	w20, w20, #0xff
   831f0:	17ffffb7 	b	830cc <donut_pixel+0x3f4>
    assert(x >= 0 && y >= 0); // important guard
   831f4:	b0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   831f8:	52800302 	mov	w2, #0x18                  	// #24
   831fc:	9104c001 	add	x1, x0, #0x130
   83200:	b0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   83204:	9104e000 	add	x0, x0, #0x138
   83208:	f9005feb 	str	x11, [sp, #184]
   8320c:	b900d7ec 	str	w12, [sp, #212]
   83210:	97fff9ba 	bl	818f8 <assertion_failed>
   83214:	f94047e0 	ldr	x0, [sp, #136]
   83218:	b940d7ec 	ldr	w12, [sp, #212]
   8321c:	f9405feb 	ldr	x11, [sp, #184]
   83220:	f9400009 	ldr	x9, [x0]
   83224:	17ffffb6 	b	830fc <donut_pixel+0x424>
   83228:	b0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   8322c:	52800302 	mov	w2, #0x18                  	// #24
   83230:	9104c001 	add	x1, x0, #0x130
   83234:	b0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   83238:	9104e000 	add	x0, x0, #0x138
   8323c:	f9005fe8 	str	x8, [sp, #184]
   83240:	b900c3e7 	str	w7, [sp, #192]
   83244:	97fff9ad 	bl	818f8 <assertion_failed>
   83248:	b940c3e7 	ldr	w7, [sp, #192]
   8324c:	f9405fe8 	ldr	x8, [sp, #184]
   83250:	17ffffd2 	b	83198 <donut_pixel+0x4c0>
   83254:	b0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   83258:	52800302 	mov	w2, #0x18                  	// #24
   8325c:	9104c001 	add	x1, x0, #0x130
   83260:	b0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   83264:	9104e000 	add	x0, x0, #0x138
   83268:	b900c3e9 	str	w9, [sp, #192]
   8326c:	b900d7ea 	str	w10, [sp, #212]
   83270:	f9006fe7 	str	x7, [sp, #216]
   83274:	97fff9a1 	bl	818f8 <assertion_failed>
   83278:	f9404fe0 	ldr	x0, [sp, #152]
   8327c:	b940c3e9 	ldr	w9, [sp, #192]
   83280:	b940d7ea 	ldr	w10, [sp, #212]
   83284:	f9400008 	ldr	x8, [x0]
   83288:	f9406fe7 	ldr	x7, [sp, #216]
   8328c:	17ffffb9 	b	83170 <donut_pixel+0x498>
   83290:	b0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   83294:	52800302 	mov	w2, #0x18                  	// #24
   83298:	9104c001 	add	x1, x0, #0x130
   8329c:	b0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   832a0:	9104e000 	add	x0, x0, #0x138
   832a4:	b900d7ea 	str	w10, [sp, #212]
   832a8:	f9006fe9 	str	x9, [sp, #216]
   832ac:	97fff993 	bl	818f8 <assertion_failed>
   832b0:	f9404be0 	ldr	x0, [sp, #144]
   832b4:	b940d7ea 	ldr	w10, [sp, #212]
   832b8:	f9406fe9 	ldr	x9, [sp, #216]
   832bc:	f9400007 	ldr	x7, [x0]
   832c0:	17ffff9d 	b	83134 <donut_pixel+0x45c>
   832c4:	d503201f 	nop

00000000000832c8 <donut>:
    return (r<<16)|(g<<8)|b; 
}

// idx: region in the canvas
// 
void donut(int idx) {
   832c8:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   832cc:	910003fd 	mov	x29, sp
    donut_pixel(idx);
   832d0:	97fffe82 	bl	82cd8 <donut_pixel>
   832d4:	00000000 	udf	#0

00000000000832d8 <_reserve_phys_region>:
	caller MUST hold alloc_lock
	is_reserve: 1 for reserve, 0 for free
	return 0 if OK  */
static int _reserve_phys_region(unsigned long pa_start, 
	unsigned long size, int is_reserve) {
	if ((pa_start & ~PAGE_MASK) != 0 || (size & ~PAGE_MASK) != 0) // must align
   832d8:	aa010003 	orr	x3, x0, x1
   832dc:	f2402c7f 	tst	x3, #0xfff
   832e0:	540005a1 	b.ne	83394 <_reserve_phys_region+0xbc>  // b.any
		{W("pa_start %lx size %lx", pa_start, size);BUG(); return -1;}

	for (unsigned i = ((pa_start-LOW_MEMORY)>>PAGE_SHIFT); 
   832e4:	9000014a 	adrp	x10, ab000 <b+0xa128>
   832e8:	90000149 	adrp	x9, ab000 <b+0xa128>
			i<((pa_start-LOW_MEMORY+size)>>PAGE_SHIFT); i++){
		if (mem_map[i] == is_reserve)	
   832ec:	912b6128 	add	x8, x9, #0xad8
	for (unsigned i = ((pa_start-LOW_MEMORY)>>PAGE_SHIFT); 
   832f0:	f9455d43 	ldr	x3, [x10, #2744]
   832f4:	cb030000 	sub	x0, x0, x3
			i<((pa_start-LOW_MEMORY+size)>>PAGE_SHIFT); i++){
   832f8:	8b010007 	add	x7, x0, x1
	for (unsigned i = ((pa_start-LOW_MEMORY)>>PAGE_SHIFT); 
   832fc:	d34cfc00 	lsr	x0, x0, #12
   83300:	92407c04 	and	x4, x0, #0xffffffff
   83304:	2a0003e5 	mov	w5, w0
   83308:	eb47309f 	cmp	x4, x7, lsr #12
   8330c:	aa0503e3 	mov	x3, x5
			i<((pa_start-LOW_MEMORY+size)>>PAGE_SHIFT); i++){
   83310:	d34cfce7 	lsr	x7, x7, #12
	for (unsigned i = ((pa_start-LOW_MEMORY)>>PAGE_SHIFT); 
   83314:	54000083 	b.cc	83324 <_reserve_phys_region+0x4c>  // b.lo, b.ul, b.last
   83318:	14000013 	b	83364 <_reserve_phys_region+0x8c>
   8331c:	eb2540ff 	cmp	x7, w5, uxtw
   83320:	54000109 	b.ls	83340 <_reserve_phys_region+0x68>  // b.plast
		if (mem_map[i] == is_reserve)	
   83324:	38656906 	ldrb	w6, [x8, x5]
			i<((pa_start-LOW_MEMORY+size)>>PAGE_SHIFT); i++){
   83328:	11000405 	add	w5, w0, #0x1
   8332c:	aa0503e0 	mov	x0, x5
		if (mem_map[i] == is_reserve)	
   83330:	6b0200df 	cmp	w6, w2
   83334:	54ffff41 	b.ne	8331c <_reserve_phys_region+0x44>  // b.any
			{return -2;}      // page already reserved / freed? 
   83338:	12800020 	mov	w0, #0xfffffffe            	// #-2

	I("%s: %s. pa_start %lx -- %lx size %lx",
		 __func__, is_reserve?"reserved":"freed", 
		 pa_start, pa_start+size, size);
	return 0; 
}
   8333c:	d65f03c0 	ret
		mem_map[i] = is_reserve; 
   83340:	912b6125 	add	x5, x9, #0xad8
   83344:	12001c44 	and	w4, w2, #0xff
   83348:	2a0303e0 	mov	w0, w3
   8334c:	d503201f 	nop
		i<((pa_start-LOW_MEMORY+size)>>PAGE_SHIFT); i++){
   83350:	11000463 	add	w3, w3, #0x1
		mem_map[i] = is_reserve; 
   83354:	382068a4 	strb	w4, [x5, x0]
		i<((pa_start-LOW_MEMORY+size)>>PAGE_SHIFT); i++){
   83358:	2a0303e0 	mov	w0, w3
	for (unsigned i = ((pa_start-LOW_MEMORY)>>PAGE_SHIFT); 
   8335c:	eb2340ff 	cmp	x7, w3, uxtw
   83360:	54ffff88 	b.hi	83350 <_reserve_phys_region+0x78>  // b.pmore
	if (is_reserve) paging_pages_used += (size>>PAGE_SHIFT); 
   83364:	912ae14a 	add	x10, x10, #0xab8
   83368:	d34cfc21 	lsr	x1, x1, #12
   8336c:	b9400940 	ldr	w0, [x10, #8]
   83370:	340000a2 	cbz	w2, 83384 <_reserve_phys_region+0xac>
   83374:	0b010001 	add	w1, w0, w1
	return 0; 
   83378:	52800000 	mov	w0, #0x0                   	// #0
	if (is_reserve) paging_pages_used += (size>>PAGE_SHIFT); 
   8337c:	b9000941 	str	w1, [x10, #8]
   83380:	d65f03c0 	ret
		else paging_pages_used -= (size>>PAGE_SHIFT);
   83384:	4b010001 	sub	w1, w0, w1
	return 0; 
   83388:	52800000 	mov	w0, #0x0                   	// #0
		else paging_pages_used -= (size>>PAGE_SHIFT);
   8338c:	b9000941 	str	w1, [x10, #8]
   83390:	d65f03c0 	ret
	unsigned long size, int is_reserve) {
   83394:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
		{W("pa_start %lx size %lx", pa_start, size);BUG(); return -1;}
   83398:	aa0103e4 	mov	x4, x1
   8339c:	aa0003e3 	mov	x3, x0
	unsigned long size, int is_reserve) {
   833a0:	910003fd 	mov	x29, sp
		{W("pa_start %lx size %lx", pa_start, size);BUG(); return -1;}
   833a4:	b0000081 	adrp	x1, 94000 <wordsworth.1725+0xde10>
	unsigned long size, int is_reserve) {
   833a8:	f9000bf3 	str	x19, [sp, #16]
		{W("pa_start %lx size %lx", pa_start, size);BUG(); return -1;}
   833ac:	91054033 	add	x19, x1, #0x150
   833b0:	52800a02 	mov	w2, #0x50                  	// #80
   833b4:	aa1303e1 	mov	x1, x19
   833b8:	b0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   833bc:	91056000 	add	x0, x0, #0x158
   833c0:	97fff87e 	bl	815b8 <tfp_printf>
   833c4:	aa1303e1 	mov	x1, x19
   833c8:	52800a02 	mov	w2, #0x50                  	// #80
   833cc:	f0000000 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   833d0:	910d8000 	add	x0, x0, #0x360
   833d4:	97fff949 	bl	818f8 <assertion_failed>
   833d8:	12800000 	mov	w0, #0xffffffff            	// #-1
}
   833dc:	f9400bf3 	ldr	x19, [sp, #16]
   833e0:	a8c27bfd 	ldp	x29, x30, [sp], #32
   833e4:	d65f03c0 	ret

00000000000833e8 <get_free_page>:
unsigned long get_free_page() {
   833e8:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   833ec:	910003fd 	mov	x29, sp
   833f0:	a90153f3 	stp	x19, x20, [sp, #16]
	acquire(&alloc_lock);
   833f4:	d0000094 	adrp	x20, 95000 <wordsworth.1725+0xee10>
   833f8:	91398280 	add	x0, x20, #0xe60
unsigned long get_free_page() {
   833fc:	f90013f5 	str	x21, [sp, #32]
	acquire(&alloc_lock);
   83400:	97fff9fe 	bl	81bf8 <acquire>
	for (int i = 0; i < PAGING_PAGES-MALLOC_PAGES; i++){
   83404:	90000155 	adrp	x21, ab000 <b+0xa128>
   83408:	912ae2a0 	add	x0, x21, #0xab8
   8340c:	f9400802 	ldr	x2, [x0, #16]
   83410:	f1200042 	subs	x2, x2, #0x800
   83414:	540003c0 	b.eq	8348c <get_free_page+0xa4>  // b.none
   83418:	90000143 	adrp	x3, ab000 <b+0xa128>
   8341c:	d2800000 	mov	x0, #0x0                   	// #0
		if (mem_map[i] == 0){
   83420:	912b6063 	add	x3, x3, #0xad8
   83424:	14000002 	b	8342c <get_free_page+0x44>
	for (int i = 0; i < PAGING_PAGES-MALLOC_PAGES; i++){
   83428:	54000320 	b.eq	8348c <get_free_page+0xa4>  // b.none
		if (mem_map[i] == 0){
   8342c:	38636801 	ldrb	w1, [x0, x3]
   83430:	2a0003f3 	mov	w19, w0
   83434:	91000400 	add	x0, x0, #0x1
	for (int i = 0; i < PAGING_PAGES-MALLOC_PAGES; i++){
   83438:	eb02001f 	cmp	x0, x2
		if (mem_map[i] == 0){
   8343c:	35ffff61 	cbnz	w1, 83428 <get_free_page+0x40>
			mem_map[i] = 1; paging_pages_used++;
   83440:	912ae2a2 	add	x2, x21, #0xab8
   83444:	52800021 	mov	w1, #0x1                   	// #1
   83448:	3833c861 	strb	w1, [x3, w19, sxtw]
			release(&alloc_lock);
   8344c:	91398280 	add	x0, x20, #0xe60
			unsigned long page = LOW_MEMORY + i*PAGE_SIZE;
   83450:	53144e73 	lsl	w19, w19, #12
			mem_map[i] = 1; paging_pages_used++;
   83454:	b9400841 	ldr	w1, [x2, #8]
   83458:	11000421 	add	w1, w1, #0x1
   8345c:	b9000841 	str	w1, [x2, #8]
			release(&alloc_lock);
   83460:	97fffa28 	bl	81d00 <release>
			unsigned long page = LOW_MEMORY + i*PAGE_SIZE;
   83464:	f9455ea0 	ldr	x0, [x21, #2744]
			memzero_aligned((void *)page, PAGE_SIZE);
   83468:	d2820001 	mov	x1, #0x1000                	// #4096
			unsigned long page = LOW_MEMORY + i*PAGE_SIZE;
   8346c:	8b33c013 	add	x19, x0, w19, sxtw
			memzero_aligned((void *)page, PAGE_SIZE);
   83470:	aa1303e0 	mov	x0, x19
   83474:	94000ab8 	bl	85f54 <memzero_aligned>
}
   83478:	aa1303e0 	mov	x0, x19
   8347c:	a94153f3 	ldp	x19, x20, [sp, #16]
   83480:	f94013f5 	ldr	x21, [sp, #32]
   83484:	a8c37bfd 	ldp	x29, x30, [sp], #48
   83488:	d65f03c0 	ret
	release(&alloc_lock);
   8348c:	91398280 	add	x0, x20, #0xe60
	return 0;
   83490:	d2800013 	mov	x19, #0x0                   	// #0
	release(&alloc_lock);
   83494:	97fffa1b 	bl	81d00 <release>
}
   83498:	aa1303e0 	mov	x0, x19
   8349c:	a94153f3 	ldp	x19, x20, [sp, #16]
   834a0:	f94013f5 	ldr	x21, [sp, #32]
   834a4:	a8c37bfd 	ldp	x29, x30, [sp], #48
   834a8:	d65f03c0 	ret
   834ac:	d503201f 	nop

00000000000834b0 <free_page>:
void free_page(unsigned long p){
   834b0:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   834b4:	910003fd 	mov	x29, sp
   834b8:	a90153f3 	stp	x19, x20, [sp, #16]
	acquire(&alloc_lock);
   834bc:	d0000094 	adrp	x20, 95000 <wordsworth.1725+0xee10>
   834c0:	91398294 	add	x20, x20, #0xe60
void free_page(unsigned long p){
   834c4:	aa0003f3 	mov	x19, x0
	acquire(&alloc_lock);
   834c8:	aa1403e0 	mov	x0, x20
   834cc:	97fff9cb 	bl	81bf8 <acquire>
	mem_map[(p - LOW_MEMORY)>>PAGE_SHIFT] = 0; paging_pages_used--;
   834d0:	90000140 	adrp	x0, ab000 <b+0xa128>
   834d4:	90000141 	adrp	x1, ab000 <b+0xa128>
   834d8:	912ae003 	add	x3, x0, #0xab8
   834dc:	912b6021 	add	x1, x1, #0xad8
   834e0:	f9455c04 	ldr	x4, [x0, #2744]
	release(&alloc_lock);
   834e4:	aa1403e0 	mov	x0, x20
	mem_map[(p - LOW_MEMORY)>>PAGE_SHIFT] = 0; paging_pages_used--;
   834e8:	b9400862 	ldr	w2, [x3, #8]
   834ec:	cb040273 	sub	x19, x19, x4
   834f0:	51000442 	sub	w2, w2, #0x1
   834f4:	d34cfe73 	lsr	x19, x19, #12
   834f8:	3833683f 	strb	wzr, [x1, x19]
}
   834fc:	a94153f3 	ldp	x19, x20, [sp, #16]
	mem_map[(p - LOW_MEMORY)>>PAGE_SHIFT] = 0; paging_pages_used--;
   83500:	b9000862 	str	w2, [x3, #8]
}
   83504:	a8c27bfd 	ldp	x29, x30, [sp], #32
	release(&alloc_lock);
   83508:	17fff9fe 	b	81d00 <release>
   8350c:	d503201f 	nop

0000000000083510 <reserve_phys_region>:

/* same as above. but caller MUST NOT hold alloc_lock */
int reserve_phys_region(unsigned long pa_start, unsigned long size) {
   83510:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   83514:	910003fd 	mov	x29, sp
   83518:	a90153f3 	stp	x19, x20, [sp, #16]
	int ret; 
	acquire(&alloc_lock); 
   8351c:	d0000093 	adrp	x19, 95000 <wordsworth.1725+0xee10>
   83520:	91398273 	add	x19, x19, #0xe60
int reserve_phys_region(unsigned long pa_start, unsigned long size) {
   83524:	aa0003f4 	mov	x20, x0
	acquire(&alloc_lock); 
   83528:	aa1303e0 	mov	x0, x19
int reserve_phys_region(unsigned long pa_start, unsigned long size) {
   8352c:	f90013f5 	str	x21, [sp, #32]
   83530:	aa0103f5 	mov	x21, x1
	acquire(&alloc_lock); 
   83534:	97fff9b1 	bl	81bf8 <acquire>
	ret = _reserve_phys_region(pa_start, size, 1/*reserve*/);
   83538:	aa1503e1 	mov	x1, x21
   8353c:	52800022 	mov	w2, #0x1                   	// #1
   83540:	aa1403e0 	mov	x0, x20
   83544:	97ffff65 	bl	832d8 <_reserve_phys_region>
   83548:	2a0003e1 	mov	w1, w0
	release(&alloc_lock); 
   8354c:	aa1303e0 	mov	x0, x19
	ret = _reserve_phys_region(pa_start, size, 1/*reserve*/);
   83550:	2a0103f3 	mov	w19, w1
	release(&alloc_lock); 
   83554:	97fff9eb 	bl	81d00 <release>
	return ret; 
}
   83558:	2a1303e0 	mov	w0, w19
   8355c:	a94153f3 	ldp	x19, x20, [sp, #16]
   83560:	f94013f5 	ldr	x21, [sp, #32]
   83564:	a8c37bfd 	ldp	x29, x30, [sp], #48
   83568:	d65f03c0 	ret
   8356c:	d503201f 	nop

0000000000083570 <free_phys_region>:

/* same as above. but caller MUST NOT hold alloc_lock */
int free_phys_region(unsigned long pa_start, unsigned long size) {
   83570:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   83574:	910003fd 	mov	x29, sp
   83578:	a90153f3 	stp	x19, x20, [sp, #16]
	int ret; 
	acquire(&alloc_lock); 
   8357c:	d0000093 	adrp	x19, 95000 <wordsworth.1725+0xee10>
   83580:	91398273 	add	x19, x19, #0xe60
int free_phys_region(unsigned long pa_start, unsigned long size) {
   83584:	aa0003f4 	mov	x20, x0
	acquire(&alloc_lock); 
   83588:	aa1303e0 	mov	x0, x19
int free_phys_region(unsigned long pa_start, unsigned long size) {
   8358c:	f90013f5 	str	x21, [sp, #32]
   83590:	aa0103f5 	mov	x21, x1
	acquire(&alloc_lock); 
   83594:	97fff999 	bl	81bf8 <acquire>
	ret = _reserve_phys_region(pa_start, size, 0/*free*/);
   83598:	aa1503e1 	mov	x1, x21
   8359c:	52800002 	mov	w2, #0x0                   	// #0
   835a0:	aa1403e0 	mov	x0, x20
   835a4:	97ffff4d 	bl	832d8 <_reserve_phys_region>
   835a8:	2a0003e1 	mov	w1, w0
	release(&alloc_lock); 
   835ac:	aa1303e0 	mov	x0, x19
	ret = _reserve_phys_region(pa_start, size, 0/*free*/);
   835b0:	2a0103f3 	mov	w19, w1
	release(&alloc_lock); 
   835b4:	97fff9d3 	bl	81d00 <release>
	return ret; 
}
   835b8:	2a1303e0 	mov	w0, w19
   835bc:	a94153f3 	ldp	x19, x20, [sp, #16]
   835c0:	f94013f5 	ldr	x21, [sp, #32]
   835c4:	a8c37bfd 	ldp	x29, x30, [sp], #48
   835c8:	d65f03c0 	ret
   835cc:	d503201f 	nop

00000000000835d0 <paging_init>:

/* init kernel's memory mgmt 
	return: # of paging pages */
unsigned int paging_init() {
   835d0:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
	LOW_MEMORY = PGROUNDUP((unsigned long)&kernel_end);
	PAGING_PAGES = (HIGH_MEMORY0 - LOW_MEMORY) / PAGE_SIZE; // comment above
   835d4:	d2a78200 	mov	x0, #0x3c100000            	// #1007681536
unsigned int paging_init() {
   835d8:	910003fd 	mov	x29, sp
   835dc:	a90153f3 	stp	x19, x20, [sp, #16]
	LOW_MEMORY = PGROUNDUP((unsigned long)&kernel_end);
   835e0:	d0000094 	adrp	x20, 95000 <wordsworth.1725+0xee10>
   835e4:	90000153 	adrp	x19, ab000 <b+0xa128>
   835e8:	f9477694 	ldr	x20, [x20, #3816]
   835ec:	912ae262 	add	x2, x19, #0xab8
unsigned int paging_init() {
   835f0:	f90013f5 	str	x21, [sp, #32]
	LOW_MEMORY = PGROUNDUP((unsigned long)&kernel_end);
   835f4:	913ffe81 	add	x1, x20, #0xfff
   835f8:	9274cc21 	and	x1, x1, #0xfffffffffffff000
   835fc:	f9055e61 	str	x1, [x19, #2744]
	PAGING_PAGES = (HIGH_MEMORY0 - LOW_MEMORY) / PAGE_SIZE; // comment above
   83600:	cb010000 	sub	x0, x0, x1
   83604:	d34cfc00 	lsr	x0, x0, #12
   83608:	f9000840 	str	x0, [x2, #16]
	
    BUG_ON(2 * MALLOC_PAGES >= PAGING_PAGES); // too many malloc pages 
   8360c:	f140041f 	cmp	x0, #0x1, lsl #12
   83610:	54000aa9 	b.ls	83764 <paging_init+0x194>  // b.plast

    /* reserve a virtually contig region for malloc()  */
    if (MALLOC_PAGES) {
        acquire(&alloc_lock); 
   83614:	d0000095 	adrp	x21, 95000 <wordsworth.1725+0xee10>
   83618:	913982a0 	add	x0, x21, #0xe60
   8361c:	97fff977 	bl	81bf8 <acquire>
		int ret = _reserve_phys_region(HIGH_MEMORY0-MALLOC_PAGES*PAGE_SIZE, 
   83620:	52800022 	mov	w2, #0x1                   	// #1
   83624:	d2a01001 	mov	x1, #0x800000              	// #8388608
   83628:	d2a77200 	mov	x0, #0x3b900000            	// #999292928
   8362c:	97ffff2b 	bl	832d8 <_reserve_phys_region>
			MALLOC_PAGES*PAGE_SIZE, 1); 
        BUG_ON(ret); 
   83630:	35000b80 	cbnz	w0, 837a0 <paging_init+0x1d0>
        release(&alloc_lock);
   83634:	913982a0 	add	x0, x21, #0xe60
   83638:	97fff9b2 	bl	81d00 <release>
    }

	printf("phys mem: %08x -- %08x\n", PHYS_BASE, PHYS_BASE + PHYS_SIZE);
   8363c:	52a7e002 	mov	w2, #0x3f000000            	// #1056964608
   83640:	52800001 	mov	w1, #0x0                   	// #0
   83644:	b0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   83648:	91078000 	add	x0, x0, #0x1e0
   8364c:	97fff7db 	bl	815b8 <tfp_printf>
	printf("\t kernel: %08x -- %08lx\n", KERNEL_START, (unsigned long)(&kernel_end));
   83650:	aa1403e2 	mov	x2, x20
   83654:	52a00101 	mov	w1, #0x80000               	// #524288
   83658:	b0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   8365c:	9107e000 	add	x0, x0, #0x1f8
   83660:	97fff7d6 	bl	815b8 <tfp_printf>
	printf("\t paging mem: %08lx -- %08x\n", LOW_MEMORY, HIGH_MEMORY0-(MALLOC_PAGES<<PAGE_SHIFT));
   83664:	f9455e61 	ldr	x1, [x19, #2744]
   83668:	b0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   8366c:	52a77202 	mov	w2, #0x3b900000            	// #999292928
   83670:	91086000 	add	x0, x0, #0x218
   83674:	97fff7d1 	bl	815b8 <tfp_printf>
	printf("\t\t %lu%s %ld pages\n", 
		int_val((HIGH_MEMORY0 - LOW_MEMORY)),
   83678:	f9455e60 	ldr	x0, [x19, #2744]
   8367c:	d2a78201 	mov	x1, #0x3c100000            	// #1007681536
   83680:	cb000021 	sub	x1, x1, x0
   83684:	f10ffc3f 	cmp	x1, #0x3ff
   83688:	54000129 	b.ls	836ac <paging_init+0xdc>  // b.plast
   8368c:	b2404fe0 	mov	x0, #0xfffff               	// #1048575
   83690:	eb00003f 	cmp	x1, x0
   83694:	54000508 	b.hi	83734 <paging_init+0x164>  // b.pmore
		int_postfix((HIGH_MEMORY0 - LOW_MEMORY)),
   83698:	b0000082 	adrp	x2, 94000 <wordsworth.1725+0xde10>
		int_val((HIGH_MEMORY0 - LOW_MEMORY)),
   8369c:	d34afc21 	lsr	x1, x1, #10
		int_postfix((HIGH_MEMORY0 - LOW_MEMORY)),
   836a0:	91064042 	add	x2, x2, #0x190
   836a4:	b0000095 	adrp	x21, 94000 <wordsworth.1725+0xde10>
   836a8:	14000004 	b	836b8 <paging_init+0xe8>
   836ac:	f0000002 	adrp	x2, 86000 <__asm_dcache_level+0xc>
   836b0:	911a2042 	add	x2, x2, #0x688
   836b4:	b0000095 	adrp	x21, 94000 <wordsworth.1725+0xde10>
	printf("\t\t %lu%s %ld pages\n", 
   836b8:	912ae274 	add	x20, x19, #0xab8
   836bc:	b0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   836c0:	9108e000 	add	x0, x0, #0x238
   836c4:	f9400a83 	ldr	x3, [x20, #16]
   836c8:	97fff7bc 	bl	815b8 <tfp_printf>
		PAGING_PAGES);
    printf("\t malloc mem: %08x -- %08x\n", HIGH_MEMORY0-(MALLOC_PAGES<<PAGE_SHIFT), HIGH_MEMORY0);
   836cc:	52a78202 	mov	w2, #0x3c100000            	// #1007681536
   836d0:	52a77201 	mov	w1, #0x3b900000            	// #999292928
   836d4:	b0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   836d8:	91094000 	add	x0, x0, #0x250
   836dc:	97fff7b7 	bl	815b8 <tfp_printf>
	printf("\t\t %lu%s\n", int_val(MALLOC_PAGES * PAGE_SIZE),
   836e0:	910662a2 	add	x2, x21, #0x198
   836e4:	d2800101 	mov	x1, #0x8                   	// #8
   836e8:	b0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   836ec:	9109c000 	add	x0, x0, #0x270
   836f0:	97fff7b2 	bl	815b8 <tfp_printf>
                                 int_postfix(MALLOC_PAGES * PAGE_SIZE)); 
	printf("\t reserved for framebuffer: %08x -- %08x\n", 
   836f4:	52a7e002 	mov	w2, #0x3f000000            	// #1056964608
   836f8:	52a78201 	mov	w1, #0x3c100000            	// #1007681536
   836fc:	b0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   83700:	910a0000 	add	x0, x0, #0x280
   83704:	97fff7ad 	bl	815b8 <tfp_printf>
		HIGH_MEMORY0, HIGH_MEMORY);

	paging_pages_total = ((HIGH_MEMORY0-LOW_MEMORY)>>PAGE_SHIFT) - MALLOC_PAGES; 
   83708:	f9455e62 	ldr	x2, [x19, #2744]
   8370c:	d2a78201 	mov	x1, #0x3c100000            	// #1007681536

	return PAGING_PAGES; 
}
   83710:	f94013f5 	ldr	x21, [sp, #32]
	paging_pages_total = ((HIGH_MEMORY0-LOW_MEMORY)>>PAGE_SHIFT) - MALLOC_PAGES; 
   83714:	cb020021 	sub	x1, x1, x2
}
   83718:	b9401280 	ldr	w0, [x20, #16]
	paging_pages_total = ((HIGH_MEMORY0-LOW_MEMORY)>>PAGE_SHIFT) - MALLOC_PAGES; 
   8371c:	d34cfc21 	lsr	x1, x1, #12
   83720:	51200021 	sub	w1, w1, #0x800
   83724:	b9001a81 	str	w1, [x20, #24]
}
   83728:	a94153f3 	ldp	x19, x20, [sp, #16]
   8372c:	a8c37bfd 	ldp	x29, x30, [sp], #48
   83730:	d65f03c0 	ret
		int_val((HIGH_MEMORY0 - LOW_MEMORY)),
   83734:	b24077e0 	mov	x0, #0x3fffffff            	// #1073741823
   83738:	eb00003f 	cmp	x1, x0
   8373c:	540000a8 	b.hi	83750 <paging_init+0x180>  // b.pmore
		int_postfix((HIGH_MEMORY0 - LOW_MEMORY)),
   83740:	b0000095 	adrp	x21, 94000 <wordsworth.1725+0xde10>
		int_val((HIGH_MEMORY0 - LOW_MEMORY)),
   83744:	d354fc21 	lsr	x1, x1, #20
		int_postfix((HIGH_MEMORY0 - LOW_MEMORY)),
   83748:	910662a2 	add	x2, x21, #0x198
   8374c:	17ffffdb 	b	836b8 <paging_init+0xe8>
   83750:	b0000082 	adrp	x2, 94000 <wordsworth.1725+0xde10>
		int_val((HIGH_MEMORY0 - LOW_MEMORY)),
   83754:	d35efc21 	lsr	x1, x1, #30
		int_postfix((HIGH_MEMORY0 - LOW_MEMORY)),
   83758:	91062042 	add	x2, x2, #0x188
   8375c:	b0000095 	adrp	x21, 94000 <wordsworth.1725+0xde10>
   83760:	17ffffd6 	b	836b8 <paging_init+0xe8>
    BUG_ON(2 * MALLOC_PAGES >= PAGING_PAGES); // too many malloc pages 
   83764:	b0000081 	adrp	x1, 94000 <wordsworth.1725+0xde10>
   83768:	91054021 	add	x1, x1, #0x150
   8376c:	52800f82 	mov	w2, #0x7c                  	// #124
   83770:	b0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   83774:	91068000 	add	x0, x0, #0x1a0
   83778:	97fff860 	bl	818f8 <assertion_failed>
        acquire(&alloc_lock); 
   8377c:	d0000095 	adrp	x21, 95000 <wordsworth.1725+0xee10>
   83780:	913982a0 	add	x0, x21, #0xe60
   83784:	97fff91d 	bl	81bf8 <acquire>
		int ret = _reserve_phys_region(HIGH_MEMORY0-MALLOC_PAGES*PAGE_SIZE, 
   83788:	52800022 	mov	w2, #0x1                   	// #1
   8378c:	d2a01001 	mov	x1, #0x800000              	// #8388608
   83790:	d2a77200 	mov	x0, #0x3b900000            	// #999292928
   83794:	97fffed1 	bl	832d8 <_reserve_phys_region>
        BUG_ON(ret); 
   83798:	34fff4e0 	cbz	w0, 83634 <paging_init+0x64>
   8379c:	d503201f 	nop
   837a0:	b0000081 	adrp	x1, 94000 <wordsworth.1725+0xde10>
   837a4:	b0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   837a8:	91054021 	add	x1, x1, #0x150
   837ac:	91076000 	add	x0, x0, #0x1d8
   837b0:	52801062 	mov	w2, #0x83                  	// #131
   837b4:	97fff851 	bl	818f8 <assertion_failed>
   837b8:	17ffff9f 	b	83634 <paging_init+0x64>
   837bc:	00000000 	udf	#0

00000000000837c0 <myproc>:
    [TASK_RUNNING]  "RUNNING ",
    [TASK_SLEEPING] "SLEEP   ",
    [TASK_RUNNABLE] "RUNNABLE",
    [TASK_ZOMBIE]   "ZOMBIE  "};
    
struct task_struct *myproc(void) {      
   837c0:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   837c4:	910003fd 	mov	x29, sp
   837c8:	f9000bf3 	str	x19, [sp, #16]
    struct task_struct *p;
    /* need disable irq b/c: if right after mycpu(), the cur task moves to 
    a diff cpu, then cpu still points to a previous cpu and ->proc 
    is not this task but a diff one */
	push_off(); 
   837cc:	97fff8f7 	bl	81ba8 <push_off>
    p=mycpu()->proc; 
   837d0:	d0000080 	adrp	x0, 95000 <wordsworth.1725+0xee10>
   837d4:	f9478000 	ldr	x0, [x0, #3840]
   837d8:	f9400013 	ldr	x19, [x0]
    pop_off(); 
   837dc:	97fff929 	bl	81c80 <pop_off>
	return p; 
};
   837e0:	aa1303e0 	mov	x0, x19
   837e4:	f9400bf3 	ldr	x19, [sp, #16]
   837e8:	a8c27bfd 	ldp	x29, x30, [sp], #32
   837ec:	d65f03c0 	ret

00000000000837f0 <sched_init>:

extern void init(int arg); // kernel.c

/* must be called BEFORE any schedule() or timertick() occurs */
void sched_init(void) {
   837f0:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
   837f4:	910003fd 	mov	x29, sp
   837f8:	f9001bf7 	str	x23, [sp, #48]
   837fc:	d0000097 	adrp	x23, 95000 <wordsworth.1725+0xee10>
   83800:	a90153f3 	stp	x19, x20, [sp, #16]
   83804:	b0000353 	adrp	x19, ec000 <kernel_stacks>
   83808:	91000273 	add	x19, x19, #0x0
   8380c:	f9477af4 	ldr	x20, [x23, #3824]
   83810:	a9025bf5 	stp	x21, x22, [sp, #32]
   83814:	b0000095 	adrp	x21, 94000 <wordsworth.1725+0xde10>
   83818:	91408276 	add	x22, x19, #0x20, lsl #12
    for (int i = 0; i < NR_TASKS; i++) {
        task[i] = (struct task_struct *)(&kernel_stacks[i][0]); 
        BUG_ON((unsigned long)task[i] & ~PAGE_MASK);  // must be page aligned. see above
        memset(task[i], 0, sizeof(struct task_struct)); // zero everything
        initlock(&(task[i]->lock), "task");
   8381c:	910b02b5 	add	x21, x21, #0x2c0
        task[i] = (struct task_struct *)(&kernel_stacks[i][0]); 
   83820:	f9000293 	str	x19, [x20]
        memset(task[i], 0, sizeof(struct task_struct)); // zero everything
   83824:	aa1303e0 	mov	x0, x19
   83828:	52802d02 	mov	w2, #0x168                 	// #360
   8382c:	52800001 	mov	w1, #0x0                   	// #0
   83830:	97fff83e 	bl	81928 <memset>
        initlock(&(task[i]->lock), "task");
   83834:	91400673 	add	x19, x19, #0x1, lsl #12
   83838:	f9400280 	ldr	x0, [x20]
   8383c:	aa1503e1 	mov	x1, x21
   83840:	91046000 	add	x0, x0, #0x118
   83844:	97fff8cb 	bl	81b70 <initlock>
        task[i]->state = TASK_UNUSED;
   83848:	f8408680 	ldr	x0, [x20], #8
    for (int i = 0; i < NR_TASKS; i++) {
   8384c:	eb16027f 	cmp	x19, x22
        task[i]->state = TASK_UNUSED;
   83850:	b901381f 	str	wzr, [x0, #312]
    for (int i = 0; i < NR_TASKS; i++) {
   83854:	54fffe61 	b.ne	83820 <sched_init+0x30>  // b.any
    }

    for (int i = 0; i < NCPU; i++) {
        idle_tasks[i] = (struct task_struct *)(&boot_stacks[i][0]); 
        cpus[i].proc = idle_tasks[i]; 
   83858:	d0000082 	adrp	x2, 95000 <wordsworth.1725+0xee10>
        idle_tasks[i] = (struct task_struct *)(&boot_stacks[i][0]); 
   8385c:	d0000093 	adrp	x19, 95000 <wordsworth.1725+0xee10>
   83860:	d0000080 	adrp	x0, 95000 <wordsworth.1725+0xee10>
        initlock(&(idle_tasks[i]->lock), "idle"); // some code will try to grab
   83864:	b0000081 	adrp	x1, 94000 <wordsworth.1725+0xde10>
        cpus[i].proc = idle_tasks[i]; 
   83868:	f9478042 	ldr	x2, [x2, #3840]
        initlock(&(idle_tasks[i]->lock), "idle"); // some code will try to grab
   8386c:	910b2021 	add	x1, x1, #0x2c8
        idle_tasks[i] = (struct task_struct *)(&boot_stacks[i][0]); 
   83870:	f9477273 	ldr	x19, [x19, #3808]
   83874:	f9475800 	ldr	x0, [x0, #3760]
        cpus[i].proc = idle_tasks[i]; 
   83878:	f9000040 	str	x0, [x2]
        idle_tasks[i] = (struct task_struct *)(&boot_stacks[i][0]); 
   8387c:	f9000260 	str	x0, [x19]
        initlock(&(idle_tasks[i]->lock), "idle"); // some code will try to grab
   83880:	91046000 	add	x0, x0, #0x118
   83884:	97fff8bb 	bl	81b70 <initlock>
        snprintf(idle_tasks[i]->name, 10, "idle-%d", i); 
   83888:	f9400260 	ldr	x0, [x19]
   8388c:	52800003 	mov	w3, #0x0                   	// #0
   83890:	d2800141 	mov	x1, #0xa                   	// #10
   83894:	b0000082 	adrp	x2, 94000 <wordsworth.1725+0xde10>
   83898:	9103c000 	add	x0, x0, #0xf0
   8389c:	910b4042 	add	x2, x2, #0x2d0
   838a0:	97fff782 	bl	816a8 <tfp_snprintf>
        jump off the idle task to "normal" ones, saving cpu_context 
        (inc sp/pc) to idle_tasks[i] */
    }
    
    /* init task, will be picked up once cpu0 calls schedule() for the 1st time */
    init_task = task[0]; 
   838a4:	f9477af7 	ldr	x23, [x23, #3824]
   838a8:	d0000081 	adrp	x1, 95000 <wordsworth.1725+0xee10>
        idle_tasks[i]->pid = -1; // not meaningful. a placeholder
   838ac:	f9400264 	ldr	x4, [x19]
    init_task->state = TASK_RUNNABLE;
    init_task->cpu_context.x19 = (unsigned long)init; 
   838b0:	d0000080 	adrp	x0, 95000 <wordsworth.1725+0xee10>
    init_task = task[0]; 
   838b4:	f9476c21 	ldr	x1, [x1, #3800]
    init_task->cpu_context.pc = (unsigned long)ret_from_fork; // entry.S
   838b8:	d0000082 	adrp	x2, 95000 <wordsworth.1725+0xee10>
    init_task = task[0]; 
   838bc:	f94002e3 	ldr	x3, [x23]
        idle_tasks[i]->pid = -1; // not meaningful. a placeholder
   838c0:	12800005 	mov	w5, #0xffffffff            	// #-1
    init_task->cpu_context.x19 = (unsigned long)init; 
   838c4:	f9477c00 	ldr	x0, [x0, #3832]
    init_task->cpu_context.pc = (unsigned long)ret_from_fork; // entry.S
   838c8:	f9478c42 	ldr	x2, [x2, #3864]
    init_task->flags = PF_KTHREAD;
    // init_task->mm = 0;  // nothing (kernel task) 
    init_task->chan = 0;
    init_task->pid = 0;
    safestrcpy(init_task->name, "init", 5);
}
   838cc:	a94153f3 	ldp	x19, x20, [sp, #16]
   838d0:	a9425bf5 	ldp	x21, x22, [sp, #32]
   838d4:	f9401bf7 	ldr	x23, [sp, #48]
    init_task = task[0]; 
   838d8:	f9000023 	str	x3, [x1]
        idle_tasks[i]->pid = -1; // not meaningful. a placeholder
   838dc:	b9013485 	str	w5, [x4, #308]
    init_task->cpu_context.sp = (unsigned long)init_task + THREAD_SIZE; 
   838e0:	91400461 	add	x1, x3, #0x1, lsl #12
    init_task->priority = 2;
   838e4:	d2800044 	mov	x4, #0x2                   	// #2
    init_task->state = TASK_RUNNABLE;
   838e8:	52800085 	mov	w5, #0x4                   	// #4
    init_task->cpu_context.x19 = (unsigned long)init; 
   838ec:	f9000060 	str	x0, [x3]
    safestrcpy(init_task->name, "init", 5);
   838f0:	9103c060 	add	x0, x3, #0xf0
    init_task->cpu_context.pc = (unsigned long)ret_from_fork; // entry.S
   838f4:	a9058861 	stp	x1, x2, [x3, #88]
    safestrcpy(init_task->name, "init", 5);
   838f8:	b0000081 	adrp	x1, 94000 <wordsworth.1725+0xde10>
   838fc:	528000a2 	mov	w2, #0x5                   	// #5
    init_task->flags = PF_KTHREAD;
   83900:	f9008464 	str	x4, [x3, #264]
    safestrcpy(init_task->name, "init", 5);
   83904:	910b6021 	add	x1, x1, #0x2d8
    init_task->pid = 0;
   83908:	b901347f 	str	wzr, [x3, #308]
    init_task->state = TASK_RUNNABLE;
   8390c:	b9013865 	str	w5, [x3, #312]
    init_task->priority = 2;
   83910:	a914107f 	stp	xzr, x4, [x3, #320]
    init_task->chan = 0;
   83914:	f900ac7f 	str	xzr, [x3, #344]
}
   83918:	a8c47bfd 	ldp	x29, x30, [sp], #64
    safestrcpy(init_task->name, "init", 5);
   8391c:	17fff869 	b	81ac0 <safestrcpy>

0000000000083920 <leave_scheduler>:
    This function is needed b/c when a task is "switched to" for the first time,
    the task starts to execute from ret_from_fork instead of the instruction
    right after the callsite to cpu_switch_to(), (see comments in switch_to()).
    To balance the irq_disable/enable, ret_from_fork must call leave_scheduler()
    below */
void leave_scheduler(void) {
   83920:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
    release(&sched_lock);
   83924:	d0000080 	adrp	x0, 95000 <wordsworth.1725+0xee10>
   83928:	9139e000 	add	x0, x0, #0xe78
void leave_scheduler(void) {
   8392c:	910003fd 	mov	x29, sp
    release(&sched_lock);
   83930:	97fff8f4 	bl	81d00 <release>
    enable_irq(); // new task must turn on irq. cf timer_tick() comments
}
   83934:	a8c17bfd 	ldp	x29, x30, [sp], #16
    enable_irq(); // new task must turn on irq. cf timer_tick() comments
   83938:	1400096c 	b	85ee8 <enable_irq>
   8393c:	d503201f 	nop

0000000000083940 <switch_to>:
}

/* caller must hold sched_lock, and not holding next->lock
called when preemption is disabled, so the cur task wont lose cpu */
// Q2: quest: "two cooperative printers"
void switch_to(struct task_struct * next) {
   83940:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   83944:	910003fd 	mov	x29, sp
   83948:	f90013f5 	str	x21, [sp, #32]
    p=mycpu()->proc; 
   8394c:	d0000095 	adrp	x21, 95000 <wordsworth.1725+0xee10>
void switch_to(struct task_struct * next) {
   83950:	a90153f3 	stp	x19, x20, [sp, #16]
   83954:	aa0003f3 	mov	x19, x0
	push_off(); 
   83958:	97fff894 	bl	81ba8 <push_off>
    p=mycpu()->proc; 
   8395c:	f94782a0 	ldr	x0, [x21, #3840]
   83960:	f9400014 	ldr	x20, [x0]
    pop_off(); 
   83964:	97fff8c7 	bl	81c80 <pop_off>
	struct task_struct * prev; 
    struct task_struct *cur; 

    cur = myproc(); BUG_ON(!cur); 
   83968:	b40002d4 	cbz	x20, 839c0 <switch_to+0x80>
	if (cur == next) 
   8396c:	eb14027f 	cmp	x19, x20
   83970:	54000200 	b.eq	839b0 <switch_to+0x70>  // b.none
		return; 

	prev = cur;
	mycpu()->proc = next;
   83974:	f94782b5 	ldr	x21, [x21, #3840]

	if (prev->state == TASK_RUNNING) // preempted 
   83978:	b9413a80 	ldr	w0, [x20, #312]
	mycpu()->proc = next;
   8397c:	f90002b3 	str	x19, [x21]
	if (prev->state == TASK_RUNNING) // preempted 
   83980:	7100041f 	cmp	w0, #0x1
   83984:	54000061 	b.ne	83990 <switch_to+0x50>  // b.any
		prev->state = TASK_RUNNABLE; 
   83988:	52800080 	mov	w0, #0x4                   	// #4
   8398c:	b9013a80 	str	w0, [x20, #312]
	next->state = TASK_RUNNING;
   83990:	52800020 	mov	w0, #0x1                   	// #1

        cpu_switch_to() does not need task::lock, cf "locking protocol" on the top
    */

    /* below: cpu_switch_to() in switch.S. it will branch to next->cpu_context.pc */
    cpu_switch_to(prev, next);   /* STUDENT: TODO: replace this */
   83994:	aa1303e1 	mov	x1, x19
}
   83998:	f94013f5 	ldr	x21, [sp, #32]
	next->state = TASK_RUNNING;
   8399c:	b9013a60 	str	w0, [x19, #312]
    cpu_switch_to(prev, next);   /* STUDENT: TODO: replace this */
   839a0:	aa1403e0 	mov	x0, x20
}
   839a4:	a94153f3 	ldp	x19, x20, [sp, #16]
   839a8:	a8c37bfd 	ldp	x29, x30, [sp], #48
    cpu_switch_to(prev, next);   /* STUDENT: TODO: replace this */
   839ac:	14000939 	b	85e90 <cpu_switch_to>
}
   839b0:	a94153f3 	ldp	x19, x20, [sp, #16]
   839b4:	f94013f5 	ldr	x21, [sp, #32]
   839b8:	a8c37bfd 	ldp	x29, x30, [sp], #48
   839bc:	d65f03c0 	ret
    cur = myproc(); BUG_ON(!cur); 
   839c0:	b0000081 	adrp	x1, 94000 <wordsworth.1725+0xde10>
   839c4:	b0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   839c8:	910b8021 	add	x1, x1, #0x2e0
   839cc:	910ba000 	add	x0, x0, #0x2e8
   839d0:	528018c2 	mov	w2, #0xc6                  	// #198
   839d4:	97fff7c9 	bl	818f8 <assertion_failed>
   839d8:	17ffffe5 	b	8396c <switch_to+0x2c>
   839dc:	d503201f 	nop

00000000000839e0 <schedule>:
void schedule() {
   839e0:	a9b97bfd 	stp	x29, x30, [sp, #-112]!
   839e4:	910003fd 	mov	x29, sp
   839e8:	a90573fb 	stp	x27, x28, [sp, #80]
    p=mycpu()->proc; 
   839ec:	d000009c 	adrp	x28, 95000 <wordsworth.1725+0xee10>
void schedule() {
   839f0:	a90153f3 	stp	x19, x20, [sp, #16]
   839f4:	a9025bf5 	stp	x21, x22, [sp, #32]
   839f8:	a90363f7 	stp	x23, x24, [sp, #48]
			p = task[i]; BUG_ON(!p);
   839fc:	b0000098 	adrp	x24, 94000 <wordsworth.1725+0xde10>
   83a00:	910b8318 	add	x24, x24, #0x2e0
void schedule() {
   83a04:	a9046bf9 	stp	x25, x26, [sp, #64]
	push_off(); 
   83a08:	97fff868 	bl	81ba8 <push_off>
    p=mycpu()->proc; 
   83a0c:	f9478380 	ldr	x0, [x28, #3840]
   83a10:	f9400015 	ldr	x21, [x0]
    pop_off(); 
   83a14:	97fff89b 	bl	81c80 <pop_off>
    acquire(&sched_lock); 
   83a18:	d0000080 	adrp	x0, 95000 <wordsworth.1725+0xee10>
   83a1c:	9139e000 	add	x0, x0, #0xe78
   83a20:	97fff876 	bl	81bf8 <acquire>
    cpu = cpuid();  // holding sched_lock, the cur process wont mirgrate across cpus
   83a24:	94000939 	bl	85f08 <cpuid>
   83a28:	2a0003f6 	mov	w22, w0
			p = task[i]; BUG_ON(!p);
   83a2c:	b0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   83a30:	910bc000 	add	x0, x0, #0x2f0
   83a34:	f90037e0 	str	x0, [sp, #104]
   83a38:	d0000080 	adrp	x0, 95000 <wordsworth.1725+0xee10>
void schedule() {
   83a3c:	d2800013 	mov	x19, #0x0                   	// #0
        has_runnable = 0; 
   83a40:	52800006 	mov	w6, #0x0                   	// #0
		max_cr = -1; 
   83a44:	12800019 	mov	w25, #0xffffffff            	// #-1
			p = task[i]; BUG_ON(!p);
   83a48:	f947781b 	ldr	x27, [x0, #3824]
		next = 0;
   83a4c:	52800017 	mov	w23, #0x0                   	// #0
   83a50:	14000004 	b	83a60 <schedule+0x80>
		for (int i = 0; i < NR_TASKS; i++){
   83a54:	91000673 	add	x19, x19, #0x1
   83a58:	f100827f 	cmp	x19, #0x20
   83a5c:	540002e0 	b.eq	83ab8 <schedule+0xd8>  // b.none
			p = task[i]; BUG_ON(!p);
   83a60:	f8737b74 	ldr	x20, [x27, x19, lsl #3]
        if (cpus[i].proc == p)
   83a64:	2a1303fa 	mov	w26, w19
			p = task[i]; BUG_ON(!p);
   83a68:	b40006b4 	cbz	x20, 83b3c <schedule+0x15c>
        if (cpus[i].proc == p)
   83a6c:	f9478380 	ldr	x0, [x28, #3840]
   83a70:	f9400000 	ldr	x0, [x0]
   83a74:	eb00029f 	cmp	x20, x0
   83a78:	54000041 	b.ne	83a80 <schedule+0xa0>  // b.any
            if (oncpu != -1 && oncpu != cpu) 
   83a7c:	35fffed6 	cbnz	w22, 83a54 <schedule+0x74>
				if (p->credits > max_cr) { max_cr = p->credits; next = i; }
   83a80:	b9413a80 	ldr	w0, [x20, #312]
   83a84:	93407f21 	sxtw	x1, w25
			if ((p == cur && p->state == TASK_RUNNING)
   83a88:	eb15029f 	cmp	x20, x21
   83a8c:	54000480 	b.eq	83b1c <schedule+0x13c>  // b.none
                || p->state == TASK_RUNNABLE) {
   83a90:	7100101f 	cmp	w0, #0x4
   83a94:	54fffe01 	b.ne	83a54 <schedule+0x74>  // b.any
				if (p->credits > max_cr) { max_cr = p->credits; next = i; }
   83a98:	f940a280 	ldr	x0, [x20, #320]
   83a9c:	52800026 	mov	w6, #0x1                   	// #1
   83aa0:	eb01001f 	cmp	x0, x1
   83aa4:	1a80d339 	csel	w25, w25, w0, le
   83aa8:	1a9ad2f7 	csel	w23, w23, w26, le
		for (int i = 0; i < NR_TASKS; i++){
   83aac:	91000673 	add	x19, x19, #0x1
   83ab0:	f100827f 	cmp	x19, #0x20
   83ab4:	54fffd61 	b.ne	83a60 <schedule+0x80>  // b.any
		if (max_cr >0) {
   83ab8:	7100033f 	cmp	w25, #0x0
            switch_to(task[next]);  /* STUDENT: TODO: replace this */
   83abc:	d0000080 	adrp	x0, 95000 <wordsworth.1725+0xee10>
		if (max_cr >0) {
   83ac0:	5400056c 	b.gt	83b6c <schedule+0x18c>
        if (has_runnable) { 
   83ac4:	340006c6 	cbz	w6, 83b9c <schedule+0x1bc>
                p = task[i]; BUG_ON(!p);
   83ac8:	f9477814 	ldr	x20, [x0, #3824]
   83acc:	91040299 	add	x25, x20, #0x100
   83ad0:	91002294 	add	x20, x20, #0x8
   83ad4:	f85f8293 	ldur	x19, [x20, #-8]
   83ad8:	b4000193 	cbz	x19, 83b08 <schedule+0x128>
   83adc:	d503201f 	nop
                if (p->state != TASK_UNUSED) {
   83ae0:	b9413a60 	ldr	w0, [x19, #312]
            for (int i = 0; i < NR_TASKS; i++) {
   83ae4:	eb14033f 	cmp	x25, x20
                if (p->state != TASK_UNUSED) {
   83ae8:	34000080 	cbz	w0, 83af8 <schedule+0x118>
                    p->credits = (p->credits >> 1) + p->priority;  // per priority
   83aec:	a9540660 	ldp	x0, x1, [x19, #320]
   83af0:	8b800420 	add	x0, x1, x0, asr #1
   83af4:	f900a260 	str	x0, [x19, #320]
            for (int i = 0; i < NR_TASKS; i++) {
   83af8:	54fffa00 	b.eq	83a38 <schedule+0x58>  // b.none
                p = task[i]; BUG_ON(!p);
   83afc:	f9400293 	ldr	x19, [x20]
   83b00:	91002294 	add	x20, x20, #0x8
   83b04:	b5fffef3 	cbnz	x19, 83ae0 <schedule+0x100>
   83b08:	f94037e0 	ldr	x0, [sp, #104]
   83b0c:	aa1803e1 	mov	x1, x24
   83b10:	528012a2 	mov	w2, #0x95                  	// #149
   83b14:	97fff779 	bl	818f8 <assertion_failed>
   83b18:	17fffff2 	b	83ae0 <schedule+0x100>
			if ((p == cur && p->state == TASK_RUNNING)
   83b1c:	7100041f 	cmp	w0, #0x1
   83b20:	54fffb81 	b.ne	83a90 <schedule+0xb0>  // b.any
				if (p->credits > max_cr) { max_cr = p->credits; next = i; }
   83b24:	f940a280 	ldr	x0, [x20, #320]
   83b28:	52800026 	mov	w6, #0x1                   	// #1
   83b2c:	eb01001f 	cmp	x0, x1
   83b30:	1a80d339 	csel	w25, w25, w0, le
   83b34:	1a9ad2f7 	csel	w23, w23, w26, le
   83b38:	17ffffdd 	b	83aac <schedule+0xcc>
			p = task[i]; BUG_ON(!p);
   83b3c:	f94037e0 	ldr	x0, [sp, #104]
   83b40:	aa1803e1 	mov	x1, x24
   83b44:	52800fa2 	mov	w2, #0x7d                  	// #125
   83b48:	b90067e6 	str	w6, [sp, #100]
   83b4c:	97fff76b 	bl	818f8 <assertion_failed>
    if (!p) {BUG(); return -1;}
   83b50:	aa1803e1 	mov	x1, x24
   83b54:	52800b62 	mov	w2, #0x5b                  	// #91
   83b58:	f0000000 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   83b5c:	910d8000 	add	x0, x0, #0x360
   83b60:	97fff766 	bl	818f8 <assertion_failed>
   83b64:	b94067e6 	ldr	w6, [sp, #100]
   83b68:	17ffffc6 	b	83a80 <schedule+0xa0>
            switch_to(task[next]);  /* STUDENT: TODO: replace this */
   83b6c:	f9477816 	ldr	x22, [x0, #3824]
   83b70:	f877dac0 	ldr	x0, [x22, w23, sxtw #3]
   83b74:	97ffff73 	bl	83940 <switch_to>
}
   83b78:	a94153f3 	ldp	x19, x20, [sp, #16]
    release(&sched_lock);
   83b7c:	d0000080 	adrp	x0, 95000 <wordsworth.1725+0xee10>
}
   83b80:	a9425bf5 	ldp	x21, x22, [sp, #32]
    release(&sched_lock);
   83b84:	9139e000 	add	x0, x0, #0xe78
}
   83b88:	a94363f7 	ldp	x23, x24, [sp, #48]
   83b8c:	a9446bf9 	ldp	x25, x26, [sp, #64]
   83b90:	a94573fb 	ldp	x27, x28, [sp, #80]
   83b94:	a8c77bfd 	ldp	x29, x30, [sp], #112
    release(&sched_lock);
   83b98:	17fff85a 	b	81d00 <release>
            switch_to(task[0]);   /* STUDENT: TODO: replace this */
   83b9c:	f9477816 	ldr	x22, [x0, #3824]
   83ba0:	f94002c0 	ldr	x0, [x22]
   83ba4:	97ffff67 	bl	83940 <switch_to>
            break;
   83ba8:	17fffff4 	b	83b78 <schedule+0x198>
   83bac:	d503201f 	nop

0000000000083bb0 <yield>:
void yield(void) {    
   83bb0:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   83bb4:	910003fd 	mov	x29, sp
   83bb8:	a90153f3 	stp	x19, x20, [sp, #16]
	push_off(); 
   83bbc:	97fff7fb 	bl	81ba8 <push_off>
    p=mycpu()->proc; 
   83bc0:	d0000080 	adrp	x0, 95000 <wordsworth.1725+0xee10>
    acquire(&sched_lock); p->credits = 0; release(&sched_lock);
   83bc4:	d0000093 	adrp	x19, 95000 <wordsworth.1725+0xee10>
   83bc8:	9139e273 	add	x19, x19, #0xe78
    p=mycpu()->proc; 
   83bcc:	f9478000 	ldr	x0, [x0, #3840]
   83bd0:	f9400014 	ldr	x20, [x0]
    pop_off(); 
   83bd4:	97fff82b 	bl	81c80 <pop_off>
    acquire(&sched_lock); p->credits = 0; release(&sched_lock);
   83bd8:	aa1303e0 	mov	x0, x19
   83bdc:	97fff807 	bl	81bf8 <acquire>
   83be0:	aa1303e0 	mov	x0, x19
   83be4:	f900a29f 	str	xzr, [x20, #320]
   83be8:	97fff846 	bl	81d00 <release>
}
   83bec:	a94153f3 	ldp	x19, x20, [sp, #16]
   83bf0:	a8c27bfd 	ldp	x29, x30, [sp], #32
    schedule();
   83bf4:	17ffff7b 	b	839e0 <schedule>

0000000000083bf8 <timer_tick>:
#define CPU_UTIL_INTERVAL 10  // cal cpu measurement every X ticks

/* Called by handle_generic_timer_irq(), i.e. timer irq handler, with irq 
    automatically turned off by hardware. irq status can be checked by 
    is_irq_masked() */
void timer_tick() {
   83bf8:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   83bfc:	910003fd 	mov	x29, sp
   83c00:	a90153f3 	stp	x19, x20, [sp, #16]
    p=mycpu()->proc; 
   83c04:	d0000093 	adrp	x19, 95000 <wordsworth.1725+0xee10>
void timer_tick() {
   83c08:	f90013f5 	str	x21, [sp, #32]
	push_off(); 
   83c0c:	97fff7e7 	bl	81ba8 <push_off>
    p=mycpu()->proc; 
   83c10:	f9478275 	ldr	x21, [x19, #3840]
   83c14:	f94002b4 	ldr	x20, [x21]
    pop_off(); 
   83c18:	97fff81a 	bl	81c80 <pop_off>
    struct task_struct *cur = myproc();
    struct cpu* cp = mycpu(); 
    printf("Inside timer_tick\n");
   83c1c:	b0000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   83c20:	910be000 	add	x0, x0, #0x2f8
   83c24:	97fff665 	bl	815b8 <tfp_printf>
    if (cur) { // update task::credits, decide if schedule() is needed
   83c28:	b4000494 	cbz	x20, 83cb8 <timer_tick+0xc0>
        V("enter timer_tick cpu%d task %s pid %d", cpuid(), cur->name, cur->pid);
        if (cur->pid>=0 && cur->state == TASK_RUNNING) // not "idle" (pid -1), and running
   83c2c:	b9413680 	ldr	w0, [x20, #308]
   83c30:	37f80080 	tbnz	w0, #31, 83c40 <timer_tick+0x48>
   83c34:	b9413a80 	ldr	w0, [x20, #312]
   83c38:	7100041f 	cmp	w0, #0x1
   83c3c:	54000460 	b.eq	83cc8 <timer_tick+0xd0>  // b.none
            cp->busy++; 

        // calculate cpu util %     Qx: quest: hide this until later lab
        if ((cp->total++ % CPU_UTIL_INTERVAL) == CPU_UTIL_INTERVAL - 1) {
   83c40:	f9478261 	ldr	x1, [x19, #3840]
   83c44:	b202e7e0 	mov	x0, #0xcccccccccccccccc    	// #-3689348814741910324
   83c48:	f29999a0 	movk	x0, #0xcccd
   83c4c:	f9400c22 	ldr	x2, [x1, #24]
   83c50:	91000443 	add	x3, x2, #0x1
   83c54:	f9000c23 	str	x3, [x1, #24]
   83c58:	9bc07c40 	umulh	x0, x2, x0
   83c5c:	d343fc00 	lsr	x0, x0, #3
   83c60:	8b000800 	add	x0, x0, x0, lsl #2
   83c64:	cb000440 	sub	x0, x2, x0, lsl #1
   83c68:	f100241f 	cmp	x0, #0x9
   83c6c:	540000a1 	b.ne	83c80 <timer_tick+0x88>  // b.any
            cp->last_util = cp->busy * 100 / CPU_UTIL_INTERVAL; 
   83c70:	b9401020 	ldr	w0, [x1, #16]
   83c74:	0b000800 	add	w0, w0, w0, lsl #2
   83c78:	531f7800 	lsl	w0, w0, #1
   83c7c:	2902003f 	stp	wzr, w0, [x1, #16]
            if (cpuid()==0)
                procdump();
            #endif
        }

        acquire(&sched_lock); 
   83c80:	d0000093 	adrp	x19, 95000 <wordsworth.1725+0xee10>
   83c84:	9139e275 	add	x21, x19, #0xe78
   83c88:	aa1503e0 	mov	x0, x21
   83c8c:	97fff7db 	bl	81bf8 <acquire>
        if (cur->pid>=0 && --cur->credits > 0) { 
   83c90:	b9413680 	ldr	w0, [x20, #308]
   83c94:	37f800c0 	tbnz	w0, #31, 83cac <timer_tick+0xb4>
   83c98:	f940a281 	ldr	x1, [x20, #320]
   83c9c:	d1000421 	sub	x1, x1, #0x1
   83ca0:	f900a281 	str	x1, [x20, #320]
   83ca4:	f100003f 	cmp	x1, #0x0
   83ca8:	5400018c 	b.gt	83cd8 <timer_tick+0xe0>
            // let "cur" task to continue execution 
            V("leave timer_tick. no resche");
            release(&sched_lock); return;
        }
        cur->credits=0;
   83cac:	f900a29f 	str	xzr, [x20, #320]
        release(&sched_lock);
   83cb0:	9139e260 	add	x0, x19, #0xe78
   83cb4:	97fff813 	bl	81d00 <release>

    V("leave timer_tick cpu%d task %s pid %d", cpuid(), cur->name, cur->pid);
	
    /* irq disabled until kernel_exit, in which eret will restore the 
       DAIF.I flag from spsr, which sets irq on. */
}
   83cb8:	a94153f3 	ldp	x19, x20, [sp, #16]
   83cbc:	f94013f5 	ldr	x21, [sp, #32]
   83cc0:	a8c37bfd 	ldp	x29, x30, [sp], #48
	schedule();
   83cc4:	17ffff47 	b	839e0 <schedule>
            cp->busy++; 
   83cc8:	b94012a0 	ldr	w0, [x21, #16]
   83ccc:	11000400 	add	w0, w0, #0x1
   83cd0:	b90012a0 	str	w0, [x21, #16]
   83cd4:	17ffffdb 	b	83c40 <timer_tick+0x48>
            release(&sched_lock); return;
   83cd8:	aa1503e0 	mov	x0, x21
}
   83cdc:	a94153f3 	ldp	x19, x20, [sp, #16]
   83ce0:	f94013f5 	ldr	x21, [sp, #32]
   83ce4:	a8c37bfd 	ldp	x29, x30, [sp], #48
            release(&sched_lock); return;
   83ce8:	17fff806 	b	81d00 <release>
   83cec:	d503201f 	nop

0000000000083cf0 <wakeup>:

/* Must be called WITHOUT sched_lock 
Called from irq (many drivers) or task
return # of tasks woken up */
// Q9: quest: "wordsmith"
int wakeup(void *chan) {
   83cf0:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   83cf4:	910003fd 	mov	x29, sp
   83cf8:	a90153f3 	stp	x19, x20, [sp, #16]
   83cfc:	aa0003f3 	mov	x19, x0
    int cnt = 0; 
   83d00:	52800014 	mov	w20, #0x0                   	// #0
int wakeup(void *chan) {
   83d04:	f90013f5 	str	x21, [sp, #32]
    int cnt; 
    acquire(&sched_lock);     
   83d08:	d0000095 	adrp	x21, 95000 <wordsworth.1725+0xee10>
   83d0c:	9139e2a0 	add	x0, x21, #0xe78
   83d10:	97fff7ba 	bl	81bf8 <acquire>
	for (int i = 0; i < NR_TASKS; i ++) {
   83d14:	d0000081 	adrp	x1, 95000 <wordsworth.1725+0xee10>
            p->state = TASK_RUNNABLE;
   83d18:	52800080 	mov	w0, #0x4                   	// #4
   83d1c:	f9477821 	ldr	x1, [x1, #3824]
   83d20:	91040024 	add	x4, x1, #0x100
   83d24:	14000003 	b	83d30 <wakeup+0x40>
	for (int i = 0; i < NR_TASKS; i ++) {
   83d28:	eb01009f 	cmp	x4, x1
   83d2c:	540001c0 	b.eq	83d64 <wakeup+0x74>  // b.none
		p = task[i]; 
   83d30:	f9400022 	ldr	x2, [x1]
        if (p->state == TASK_SLEEPING && p->chan == chan) {            
   83d34:	91002021 	add	x1, x1, #0x8
   83d38:	b9413843 	ldr	w3, [x2, #312]
   83d3c:	7100087f 	cmp	w3, #0x2
   83d40:	54ffff41 	b.ne	83d28 <wakeup+0x38>  // b.any
   83d44:	f940ac43 	ldr	x3, [x2, #344]
   83d48:	eb03027f 	cmp	x19, x3
   83d4c:	54fffee1 	b.ne	83d28 <wakeup+0x38>  // b.any
            p->state = TASK_RUNNABLE;
   83d50:	b9013840 	str	w0, [x2, #312]
            cnt++;
   83d54:	11000694 	add	w20, w20, #0x1
            p->chan  = 0;
   83d58:	f900ac5f 	str	xzr, [x2, #344]
	for (int i = 0; i < NR_TASKS; i ++) {
   83d5c:	eb01009f 	cmp	x4, x1
   83d60:	54fffe81 	b.ne	83d30 <wakeup+0x40>  // b.any
    cnt = wakeup_nolock(chan); 
    release(&sched_lock);
   83d64:	9139e2a0 	add	x0, x21, #0xe78
   83d68:	97fff7e6 	bl	81d00 <release>
    return cnt; 
}
   83d6c:	2a1403e0 	mov	w0, w20
   83d70:	a94153f3 	ldp	x19, x20, [sp, #16]
   83d74:	f94013f5 	ldr	x21, [sp, #32]
   83d78:	a8c37bfd 	ldp	x29, x30, [sp], #48
   83d7c:	d65f03c0 	ret

0000000000083d80 <sleep>:

/* Atomically release "lk" and sleep on chan.
Reacquires lk when awakened.
Called by tasks with @lk held */
// Q9: quest: "wordsmith"
void sleep(void *chan, struct spinlock *lk) {
   83d80:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
   83d84:	910003fd 	mov	x29, sp
   83d88:	a9025bf5 	stp	x21, x22, [sp, #32]
    p=mycpu()->proc; 
   83d8c:	d0000096 	adrp	x22, 95000 <wordsworth.1725+0xee10>
     * 
     * Corner case: lk==sched_lock, which is already held by cur task. the right
     * behavior of sleep(): keep sched_lock and switch to idle task, which later
     * will release the lock
     */
    if (lk != &sched_lock) {
   83d90:	d0000095 	adrp	x21, 95000 <wordsworth.1725+0xee10>
void sleep(void *chan, struct spinlock *lk) {
   83d94:	a90153f3 	stp	x19, x20, [sp, #16]
   83d98:	aa0103f4 	mov	x20, x1
    if (lk != &sched_lock) {
   83d9c:	9139e2b5 	add	x21, x21, #0xe78
void sleep(void *chan, struct spinlock *lk) {
   83da0:	f9001bf7 	str	x23, [sp, #48]
   83da4:	aa0003f7 	mov	x23, x0
	push_off(); 
   83da8:	97fff780 	bl	81ba8 <push_off>
    p=mycpu()->proc; 
   83dac:	f94782d6 	ldr	x22, [x22, #3840]
   83db0:	f94002d3 	ldr	x19, [x22]
    pop_off(); 
   83db4:	97fff7b3 	bl	81c80 <pop_off>
    if (lk != &sched_lock) {
   83db8:	eb15029f 	cmp	x20, x21
   83dbc:	54000380 	b.eq	83e2c <sleep+0xac>  // b.none
        acquire(&sched_lock);
   83dc0:	aa1503e0 	mov	x0, x21
   83dc4:	97fff78d 	bl	81bf8 <acquire>
        release(lk);
   83dc8:	aa1403e0 	mov	x0, x20
   83dcc:	97fff7cd 	bl	81d00 <release>
    p->chan  = chan;
    p->state = TASK_SLEEPING;

    /* although the task has not used up the current tick, bill it regardless.
    thus this task will be disadvantaged in future scheduling  */
    p->credits --; 
   83dd0:	f940a261 	ldr	x1, [x19, #320]
    p->state = TASK_SLEEPING;
   83dd4:	52800040 	mov	w0, #0x2                   	// #2
   83dd8:	b9013a60 	str	w0, [x19, #312]
    p->credits --; 
   83ddc:	d1000421 	sub	x1, x1, #0x1
   83de0:	f900a261 	str	x1, [x19, #320]
    p->chan  = chan;
   83de4:	f900ae77 	str	x23, [x19, #344]

    /* switch the cpu away from the current kern stack to the idle task, which we
    know exists for sure. the idle task will return from the schedule() and 
    rls sched_lock. the next timertick will call schedule() and switch 
    to a normal task (if any)  */
    struct task_struct *idle = idle_tasks[cpuid()];
   83de8:	94000848 	bl	85f08 <cpuid>
   83dec:	2a0003e2 	mov	w2, w0
   83df0:	d0000081 	adrp	x1, 95000 <wordsworth.1725+0xee10>
    mycpu()->proc = idle;
    cpu_switch_to(p, idle);  
   83df4:	aa1303e0 	mov	x0, x19
    struct task_struct *idle = idle_tasks[cpuid()];
   83df8:	f9477021 	ldr	x1, [x1, #3808]
   83dfc:	f862d821 	ldr	x1, [x1, w2, sxtw #3]
    mycpu()->proc = idle;
   83e00:	f90002c1 	str	x1, [x22]
    cpu_switch_to(p, idle);  
   83e04:	94000823 	bl	85e90 <cpu_switch_to>
    
    /* cpu_switch_to() back here when the cur task is woken up. 
    it now has sched_lock.  */

    /* Tidy up. */
    p->chan = 0;
   83e08:	f900ae7f 	str	xzr, [x19, #344]

    if (lk != &sched_lock) {
        release(&sched_lock); 
   83e0c:	aa1503e0 	mov	x0, x21
   83e10:	97fff7bc 	bl	81d00 <release>
        acquire(lk); 
   83e14:	aa1403e0 	mov	x0, x20
        - T1 tries to reacquire lk (before releasing sched_lock)
        - T2 has lk, but cannot run b/c T1 has sched_lock -- deadlock         
            cf unittests.c do_write()
        */
    } /* else keep holding sched_lock */
}
   83e18:	a94153f3 	ldp	x19, x20, [sp, #16]
   83e1c:	a9425bf5 	ldp	x21, x22, [sp, #32]
   83e20:	f9401bf7 	ldr	x23, [sp, #48]
   83e24:	a8c47bfd 	ldp	x29, x30, [sp], #64
        acquire(lk); 
   83e28:	17fff774 	b	81bf8 <acquire>
    p->credits --; 
   83e2c:	f940a260 	ldr	x0, [x19, #320]
    p->state = TASK_SLEEPING;
   83e30:	52800041 	mov	w1, #0x2                   	// #2
   83e34:	b9013a61 	str	w1, [x19, #312]
    p->credits --; 
   83e38:	d1000400 	sub	x0, x0, #0x1
   83e3c:	f900a260 	str	x0, [x19, #320]
    p->chan  = chan;
   83e40:	f900ae77 	str	x23, [x19, #344]
    struct task_struct *idle = idle_tasks[cpuid()];
   83e44:	94000831 	bl	85f08 <cpuid>
   83e48:	2a0003e2 	mov	w2, w0
   83e4c:	d0000081 	adrp	x1, 95000 <wordsworth.1725+0xee10>
    cpu_switch_to(p, idle);  
   83e50:	aa1303e0 	mov	x0, x19
    struct task_struct *idle = idle_tasks[cpuid()];
   83e54:	f9477021 	ldr	x1, [x1, #3808]
   83e58:	f862d821 	ldr	x1, [x1, w2, sxtw #3]
    mycpu()->proc = idle;
   83e5c:	f90002c1 	str	x1, [x22]
    cpu_switch_to(p, idle);  
   83e60:	9400080c 	bl	85e90 <cpu_switch_to>
}
   83e64:	a9425bf5 	ldp	x21, x22, [sp, #32]
   83e68:	f9401bf7 	ldr	x23, [sp, #48]
    p->chan = 0;
   83e6c:	f900ae7f 	str	xzr, [x19, #344]
}
   83e70:	a94153f3 	ldp	x19, x20, [sp, #16]
   83e74:	a8c47bfd 	ldp	x29, x30, [sp], #64
   83e78:	d65f03c0 	ret
   83e7c:	d503201f 	nop

0000000000083e80 <wait>:

/* Wait for a child process to exit and return its pid.
    Return -1 if this process has no children. 
    addr=0 a special case, dont care about status
    --- "addr" ignored for lab2 */
int wait(uint64 addr /*dst user va to copy status to */) {
   83e80:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
   83e84:	910003fd 	mov	x29, sp
   83e88:	a90153f3 	stp	x19, x20, [sp, #16]
   83e8c:	a9025bf5 	stp	x21, x22, [sp, #32]

    for (;;) {
        // Scan through table looking for exited children.  pp:child
        havekids = 0;
        for (pp = task; pp < &task[NR_TASKS]; pp++) {
            struct task_struct *p0 = *pp; BUG_ON(!p0); 
   83e90:	b0000096 	adrp	x22, 94000 <wordsworth.1725+0xde10>
   83e94:	d0000095 	adrp	x21, 95000 <wordsworth.1725+0xee10>
int wait(uint64 addr /*dst user va to copy status to */) {
   83e98:	a90363f7 	stp	x23, x24, [sp, #48]
            struct task_struct *p0 = *pp; BUG_ON(!p0); 
   83e9c:	910c42d6 	add	x22, x22, #0x310
    acquire(&sched_lock); 
   83ea0:	d0000098 	adrp	x24, 95000 <wordsworth.1725+0xee10>
int wait(uint64 addr /*dst user va to copy status to */) {
   83ea4:	a9046bf9 	stp	x25, x26, [sp, #64]
	push_off(); 
   83ea8:	97fff740 	bl	81ba8 <push_off>
    p=mycpu()->proc; 
   83eac:	d0000080 	adrp	x0, 95000 <wordsworth.1725+0xee10>
            struct task_struct *p0 = *pp; BUG_ON(!p0); 
   83eb0:	b0000097 	adrp	x23, 94000 <wordsworth.1725+0xde10>
   83eb4:	910b82f7 	add	x23, x23, #0x2e0
    p=mycpu()->proc; 
   83eb8:	f9478000 	ldr	x0, [x0, #3840]
   83ebc:	f9400019 	ldr	x25, [x0]
    pop_off(); 
   83ec0:	97fff770 	bl	81c80 <pop_off>
    acquire(&sched_lock); 
   83ec4:	9139e300 	add	x0, x24, #0xe78
   83ec8:	97fff74c 	bl	81bf8 <acquire>
        for (pp = task; pp < &task[NR_TASKS]; pp++) {
   83ecc:	f9477ab3 	ldr	x19, [x21, #3824]
        havekids = 0;
   83ed0:	5280001a 	mov	w26, #0x0                   	// #0
   83ed4:	14000005 	b	83ee8 <wait+0x68>
        for (pp = task; pp < &task[NR_TASKS]; pp++) {
   83ed8:	f9477aa0 	ldr	x0, [x21, #3824]
   83edc:	91040000 	add	x0, x0, #0x100
   83ee0:	eb00027f 	cmp	x19, x0
   83ee4:	54000420 	b.eq	83f68 <wait+0xe8>  // b.none
            struct task_struct *p0 = *pp; BUG_ON(!p0); 
   83ee8:	f9400274 	ldr	x20, [x19]
        for (pp = task; pp < &task[NR_TASKS]; pp++) {
   83eec:	91002273 	add	x19, x19, #0x8
            struct task_struct *p0 = *pp; BUG_ON(!p0); 
   83ef0:	b4000334 	cbz	x20, 83f54 <wait+0xd4>
            if (p0->state == TASK_UNUSED) continue; 
   83ef4:	b9413a80 	ldr	w0, [x20, #312]
   83ef8:	34ffff00 	cbz	w0, 83ed8 <wait+0x58>
            if (p0->parent == p) {
   83efc:	f940b281 	ldr	x1, [x20, #352]
   83f00:	eb19003f 	cmp	x1, x25
   83f04:	54fffea1 	b.ne	83ed8 <wait+0x58>  // b.any
                havekids = 1;
                if (p0->state == TASK_ZOMBIE) {
   83f08:	71000c1f 	cmp	w0, #0x3
                havekids = 1;
   83f0c:	5280003a 	mov	w26, #0x1                   	// #1
                if (p0->state == TASK_ZOMBIE) {
   83f10:	54fffe41 	b.ne	83ed8 <wait+0x58>  // b.any
                    // Found one.
                    pid = p0->pid;
   83f14:	b9413693 	ldr	w19, [x20, #308]
                    I("found zombie pid=%d", pid); 
                    freeproc(p0);       // will mark the task slot as unused                    
                    release(&sched_lock); 
   83f18:	9139e300 	add	x0, x24, #0xe78
    BUG_ON(!p); V("%s entered. pid %d", __func__, p->pid);

    p->state = TASK_UNUSED; // mark the slot as unused
    // o need to zero task_struct, which is among the task's kernel page
    // FIX: since we cannot recycle task slot now, so we dont dec nr_tasks ...
    p->flags = 0; 
   83f1c:	f900869f 	str	xzr, [x20, #264]
    p->killed = 0; 
   83f20:	f9009a9f 	str	xzr, [x20, #304]
    p->state = TASK_UNUSED; // mark the slot as unused
   83f24:	b9013a9f 	str	wzr, [x20, #312]
    p->credits = 0; 
   83f28:	f900a29f 	str	xzr, [x20, #320]
    p->chan = 0; 
    p->pid = 0; 
    p->xstate = 0; 
   83f2c:	b901529f 	str	wzr, [x20, #336]
    p->chan = 0; 
   83f30:	f900ae9f 	str	xzr, [x20, #344]
                    release(&sched_lock); 
   83f34:	97fff773 	bl	81d00 <release>
}
   83f38:	2a1303e0 	mov	w0, w19
   83f3c:	a94153f3 	ldp	x19, x20, [sp, #16]
   83f40:	a9425bf5 	ldp	x21, x22, [sp, #32]
   83f44:	a94363f7 	ldp	x23, x24, [sp, #48]
   83f48:	a9446bf9 	ldp	x25, x26, [sp, #64]
   83f4c:	a8c57bfd 	ldp	x29, x30, [sp], #80
   83f50:	d65f03c0 	ret
            struct task_struct *p0 = *pp; BUG_ON(!p0); 
   83f54:	aa1703e1 	mov	x1, x23
   83f58:	aa1603e0 	mov	x0, x22
   83f5c:	52803862 	mov	w2, #0x1c3                 	// #451
   83f60:	97fff666 	bl	818f8 <assertion_failed>
   83f64:	17ffffe4 	b	83ef4 <wait+0x74>
        if (!havekids) {
   83f68:	340000ba 	cbz	w26, 83f7c <wait+0xfc>
        sleep(p, &sched_lock); // sleep on own task_struct
   83f6c:	9139e301 	add	x1, x24, #0xe78
   83f70:	aa1903e0 	mov	x0, x25
   83f74:	97ffff83 	bl	83d80 <sleep>
        havekids = 0;
   83f78:	17ffffd5 	b	83ecc <wait+0x4c>
            release(&sched_lock);
   83f7c:	9139e300 	add	x0, x24, #0xe78
            return -1;
   83f80:	12800013 	mov	w19, #0xffffffff            	// #-1
            release(&sched_lock);
   83f84:	97fff75f 	bl	81d00 <release>
}
   83f88:	2a1303e0 	mov	w0, w19
   83f8c:	a94153f3 	ldp	x19, x20, [sp, #16]
   83f90:	a9425bf5 	ldp	x21, x22, [sp, #32]
   83f94:	a94363f7 	ldp	x23, x24, [sp, #48]
   83f98:	a9446bf9 	ldp	x25, x26, [sp, #64]
   83f9c:	a8c57bfd 	ldp	x29, x30, [sp], #80
   83fa0:	d65f03c0 	ret
   83fa4:	d503201f 	nop

0000000000083fa8 <exit_process>:
void exit_process(int status) {
   83fa8:	a9b97bfd 	stp	x29, x30, [sp, #-112]!
   83fac:	910003fd 	mov	x29, sp
   83fb0:	a9025bf5 	stp	x21, x22, [sp, #32]
    p=mycpu()->proc; 
   83fb4:	d0000096 	adrp	x22, 95000 <wordsworth.1725+0xee10>
void exit_process(int status) {
   83fb8:	a90153f3 	stp	x19, x20, [sp, #16]
   83fbc:	a90363f7 	stp	x23, x24, [sp, #48]
   83fc0:	2a0003f7 	mov	w23, w0
   83fc4:	a9046bf9 	stp	x25, x26, [sp, #64]
    if (p == init_task)
   83fc8:	d0000099 	adrp	x25, 95000 <wordsworth.1725+0xee10>
void exit_process(int status) {
   83fcc:	a90573fb 	stp	x27, x28, [sp, #80]
	push_off(); 
   83fd0:	97fff6f6 	bl	81ba8 <push_off>
    p=mycpu()->proc; 
   83fd4:	f94782c0 	ldr	x0, [x22, #3840]
   83fd8:	f940001a 	ldr	x26, [x0]
    pop_off(); 
   83fdc:	97fff729 	bl	81c80 <pop_off>
    if (p == init_task)
   83fe0:	f9476f20 	ldr	x0, [x25, #3800]
   83fe4:	f9400000 	ldr	x0, [x0]
   83fe8:	eb1a001f 	cmp	x0, x26
   83fec:	54000c20 	b.eq	84170 <exit_process+0x1c8>  // b.none
    for (child = task; child < &task[NR_TASKS]; child++) {
   83ff0:	d0000094 	adrp	x20, 95000 <wordsworth.1725+0xee10>
    acquire(&sched_lock); 
   83ff4:	d0000080 	adrp	x0, 95000 <wordsworth.1725+0xee10>
   83ff8:	9139e000 	add	x0, x0, #0xe78
   83ffc:	97fff6ff 	bl	81bf8 <acquire>
    for (child = task; child < &task[NR_TASKS]; child++) {
   84000:	f9477a93 	ldr	x19, [x20, #3824]
        BUG_ON(!(*child));
   84004:	90000081 	adrp	x1, 94000 <wordsworth.1725+0xde10>
   84008:	9000009c 	adrp	x28, 94000 <wordsworth.1725+0xde10>
   8400c:	910b8035 	add	x21, x1, #0x2e0
    for (child = task; child < &task[NR_TASKS]; child++) {
   84010:	91040278 	add	x24, x19, #0x100
        BUG_ON(!(*child));
   84014:	910ca39c 	add	x28, x28, #0x328
    int cnt = 0; 
   84018:	5280001b 	mov	w27, #0x0                   	// #0
    for (child = task; child < &task[NR_TASKS]; child++) {
   8401c:	f90037f3 	str	x19, [sp, #104]
   84020:	14000003 	b	8402c <exit_process+0x84>
   84024:	eb18027f 	cmp	x19, x24
   84028:	540001e0 	b.eq	84064 <exit_process+0xbc>  // b.none
        BUG_ON(!(*child));
   8402c:	f9400262 	ldr	x2, [x19]
   84030:	b4000942 	cbz	x2, 84158 <exit_process+0x1b0>
        if ((*child)->state == TASK_UNUSED) continue;
   84034:	b9413843 	ldr	w3, [x2, #312]
    for (child = task; child < &task[NR_TASKS]; child++) {
   84038:	91002273 	add	x19, x19, #0x8
        if ((*child)->state == TASK_UNUSED) continue;
   8403c:	34ffff43 	cbz	w3, 84024 <exit_process+0x7c>
        if ((*child)->parent == p) {
   84040:	f940b043 	ldr	x3, [x2, #352]
   84044:	eb03035f 	cmp	x26, x3
   84048:	54fffee1 	b.ne	84024 <exit_process+0x7c>  // b.any
            (*child)->parent = init_task;
   8404c:	f9476f23 	ldr	x3, [x25, #3800]
            cnt ++; 
   84050:	1100077b 	add	w27, w27, #0x1
    for (child = task; child < &task[NR_TASKS]; child++) {
   84054:	eb18027f 	cmp	x19, x24
            (*child)->parent = init_task;
   84058:	f9400063 	ldr	x3, [x3]
   8405c:	f900b043 	str	x3, [x2, #352]
    for (child = task; child < &task[NR_TASKS]; child++) {
   84060:	54fffe61 	b.ne	8402c <exit_process+0x84>  // b.any
    if (reparent(p)) 
   84064:	340002bb 	cbz	w27, 840b8 <exit_process+0x110>
        wakeup_nolock(init_task);
   84068:	f9476f39 	ldr	x25, [x25, #3800]
            p->state = TASK_RUNNABLE;
   8406c:	52800084 	mov	w4, #0x4                   	// #4
   84070:	f94037e1 	ldr	x1, [sp, #104]
        wakeup_nolock(init_task);
   84074:	f9400323 	ldr	x3, [x25]
	for (int i = 0; i < NR_TASKS; i ++) {
   84078:	14000003 	b	84084 <exit_process+0xdc>
   8407c:	eb01027f 	cmp	x19, x1
   84080:	540001c0 	b.eq	840b8 <exit_process+0x110>  // b.none
		p = task[i]; 
   84084:	f9400020 	ldr	x0, [x1]
        if (p->state == TASK_SLEEPING && p->chan == chan) {            
   84088:	91002021 	add	x1, x1, #0x8
   8408c:	b9413802 	ldr	w2, [x0, #312]
   84090:	7100085f 	cmp	w2, #0x2
   84094:	54ffff41 	b.ne	8407c <exit_process+0xd4>  // b.any
   84098:	f940ac02 	ldr	x2, [x0, #344]
   8409c:	eb02007f 	cmp	x3, x2
   840a0:	54fffee1 	b.ne	8407c <exit_process+0xd4>  // b.any
            p->state = TASK_RUNNABLE;
   840a4:	b9013804 	str	w4, [x0, #312]
	for (int i = 0; i < NR_TASKS; i ++) {
   840a8:	eb01027f 	cmp	x19, x1
            p->chan  = 0;
   840ac:	f900ac1f 	str	xzr, [x0, #344]
	for (int i = 0; i < NR_TASKS; i ++) {
   840b0:	54fffea1 	b.ne	84084 <exit_process+0xdc>  // b.any
   840b4:	d503201f 	nop
    wakeup_nolock(p->parent); 
   840b8:	f9477a81 	ldr	x1, [x20, #3824]
            p->state = TASK_RUNNABLE;
   840bc:	52800085 	mov	w5, #0x4                   	// #4
    wakeup_nolock(p->parent); 
   840c0:	f940b344 	ldr	x4, [x26, #352]
	for (int i = 0; i < NR_TASKS; i ++) {
   840c4:	91040020 	add	x0, x1, #0x100
   840c8:	14000003 	b	840d4 <exit_process+0x12c>
   840cc:	eb00003f 	cmp	x1, x0
   840d0:	540001a0 	b.eq	84104 <exit_process+0x15c>  // b.none
		p = task[i]; 
   840d4:	f9400022 	ldr	x2, [x1]
        if (p->state == TASK_SLEEPING && p->chan == chan) {            
   840d8:	91002021 	add	x1, x1, #0x8
   840dc:	b9413843 	ldr	w3, [x2, #312]
   840e0:	7100087f 	cmp	w3, #0x2
   840e4:	54ffff41 	b.ne	840cc <exit_process+0x124>  // b.any
   840e8:	f940ac43 	ldr	x3, [x2, #344]
   840ec:	eb03009f 	cmp	x4, x3
   840f0:	54fffee1 	b.ne	840cc <exit_process+0x124>  // b.any
            p->state = TASK_RUNNABLE;
   840f4:	b9013845 	str	w5, [x2, #312]
	for (int i = 0; i < NR_TASKS; i ++) {
   840f8:	eb00003f 	cmp	x1, x0
            p->chan  = 0;
   840fc:	f900ac5f 	str	xzr, [x2, #344]
	for (int i = 0; i < NR_TASKS; i ++) {
   84100:	54fffea1 	b.ne	840d4 <exit_process+0x12c>  // b.any
    p->state = TASK_ZOMBIE;
   84104:	52800060 	mov	w0, #0x3                   	// #3
   84108:	b9013b40 	str	w0, [x26, #312]
    p->xstate = status;
   8410c:	b9015357 	str	w23, [x26, #336]
    struct task_struct *idle = idle_tasks[cpuid()];
   84110:	9400077e 	bl	85f08 <cpuid>
   84114:	2a0003e2 	mov	w2, w0
   84118:	b0000081 	adrp	x1, 95000 <wordsworth.1725+0xee10>
    cpu_switch_to(p, idle);
   8411c:	aa1a03e0 	mov	x0, x26
    mycpu()->proc = idle;
   84120:	f94782d6 	ldr	x22, [x22, #3840]
    struct task_struct *idle = idle_tasks[cpuid()];
   84124:	f9477021 	ldr	x1, [x1, #3808]
   84128:	f862d821 	ldr	x1, [x1, w2, sxtw #3]
    mycpu()->proc = idle;
   8412c:	f90002c1 	str	x1, [x22]
    cpu_switch_to(p, idle);
   84130:	94000758 	bl	85e90 <cpu_switch_to>
}
   84134:	a94153f3 	ldp	x19, x20, [sp, #16]
    panic("zombie exit");
   84138:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
}
   8413c:	a9425bf5 	ldp	x21, x22, [sp, #32]
    panic("zombie exit");
   84140:	910ce000 	add	x0, x0, #0x338
}
   84144:	a94363f7 	ldp	x23, x24, [sp, #48]
   84148:	a9446bf9 	ldp	x25, x26, [sp, #64]
   8414c:	a94573fb 	ldp	x27, x28, [sp, #80]
   84150:	a8c77bfd 	ldp	x29, x30, [sp], #112
    panic("zombie exit");
   84154:	17fff59f 	b	817d0 <panic>
        BUG_ON(!(*child));
   84158:	52803462 	mov	w2, #0x1a3                 	// #419
   8415c:	aa1503e1 	mov	x1, x21
   84160:	aa1c03e0 	mov	x0, x28
   84164:	97fff5e5 	bl	818f8 <assertion_failed>
   84168:	f9400262 	ldr	x2, [x19]
   8416c:	17ffffb2 	b	84034 <exit_process+0x8c>
        panic("init exiting");
   84170:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   84174:	910c6000 	add	x0, x0, #0x318
   84178:	97fff596 	bl	817d0 <panic>
   8417c:	17ffff9d 	b	83ff0 <exit_process+0x48>

0000000000084180 <procdump>:
}

/* Print a process listing to console.  For debugging.
Runs when user types ^P on console.
No lock to avoid wedging a stuck machine further. */
void procdump(void) {
   84180:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
    struct task_struct *p;
    char *state;

    printf("\t %5s %10s %10s %20s\n", "pid", "state", "name", "sleep-on");
   84184:	90000084 	adrp	x4, 94000 <wordsworth.1725+0xde10>
   84188:	90000083 	adrp	x3, 94000 <wordsworth.1725+0xde10>
void procdump(void) {
   8418c:	910003fd 	mov	x29, sp
   84190:	a90153f3 	stp	x19, x20, [sp, #16]
   84194:	b0000093 	adrp	x19, 95000 <wordsworth.1725+0xee10>
    printf("\t %5s %10s %10s %20s\n", "pid", "state", "name", "sleep-on");
   84198:	910d4084 	add	x4, x4, #0x350
   8419c:	910d8063 	add	x3, x3, #0x360
   841a0:	90000082 	adrp	x2, 94000 <wordsworth.1725+0xde10>
   841a4:	90000081 	adrp	x1, 94000 <wordsworth.1725+0xde10>
   841a8:	910da042 	add	x2, x2, #0x368
   841ac:	910dc021 	add	x1, x1, #0x370
   841b0:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   841b4:	910de000 	add	x0, x0, #0x378
void procdump(void) {
   841b8:	a9025bf5 	stp	x21, x22, [sp, #32]
        if (p->state == TASK_UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
            state = states[p->state];
        else
            state = "???";
   841bc:	90000094 	adrp	x20, 94000 <wordsworth.1725+0xde10>
void procdump(void) {
   841c0:	f9001bf7 	str	x23, [sp, #48]
    printf("\t %5s %10s %10s %20s\n", "pid", "state", "name", "sleep-on");
   841c4:	97fff4fd 	bl	815b8 <tfp_printf>
    for (int i = 0; i < NR_TASKS; i++) {
   841c8:	f9477a73 	ldr	x19, [x19, #3824]
        printf("\t %5d %10s %10s %20lx\n", p->pid, state, p->name, 
   841cc:	90000095 	adrp	x21, 94000 <wordsworth.1725+0xde10>
            state = "???";
   841d0:	910d2294 	add	x20, x20, #0x348
        printf("\t %5d %10s %10s %20lx\n", p->pid, state, p->name, 
   841d4:	910e42b5 	add	x21, x21, #0x390
   841d8:	91040276 	add	x22, x19, #0x100
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
   841dc:	b0000097 	adrp	x23, 95000 <wordsworth.1725+0xee10>
        p = task[i];
   841e0:	f9400264 	ldr	x4, [x19]
            state = "???";
   841e4:	aa1403e2 	mov	x2, x20
        printf("\t %5d %10s %10s %20lx\n", p->pid, state, p->name, 
   841e8:	aa1503e0 	mov	x0, x21
   841ec:	91002273 	add	x19, x19, #0x8
   841f0:	9103c083 	add	x3, x4, #0xf0
        if (p->state == TASK_UNUSED)
   841f4:	b9413881 	ldr	w1, [x4, #312]
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
   841f8:	7100103f 	cmp	w1, #0x4
        if (p->state == TASK_UNUSED)
   841fc:	34000121 	cbz	w1, 84220 <procdump+0xa0>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
   84200:	913d02e5 	add	x5, x23, #0xf40
   84204:	54000088 	b.hi	84214 <procdump+0x94>  // b.pmore
   84208:	f861d8a2 	ldr	x2, [x5, w1, sxtw #3]
            state = "???";
   8420c:	f100005f 	cmp	x2, #0x0
   84210:	9a820282 	csel	x2, x20, x2, eq	// eq = none
        printf("\t %5d %10s %10s %20lx\n", p->pid, state, p->name, 
   84214:	b9413481 	ldr	w1, [x4, #308]
   84218:	f940ac84 	ldr	x4, [x4, #344]
   8421c:	97fff4e7 	bl	815b8 <tfp_printf>
    for (int i = 0; i < NR_TASKS; i++) {
   84220:	eb1302df 	cmp	x22, x19
   84224:	54fffde1 	b.ne	841e0 <procdump+0x60>  // b.any
               (unsigned long)p->chan);
    }
    
    extern unsigned paging_pages_used, paging_pages_total; // alloc.c
	printf("paging mem: used %u total %u (%u/100)\n", 
   84228:	b0000081 	adrp	x1, 95000 <wordsworth.1725+0xee10>
   8422c:	b0000082 	adrp	x2, 95000 <wordsworth.1725+0xee10>
		paging_pages_used, paging_pages_total, 
        paging_pages_used*100/(paging_pages_total));
   84230:	52800c83 	mov	w3, #0x64                  	// #100
	printf("paging mem: used %u total %u (%u/100)\n", 
   84234:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   84238:	f9476821 	ldr	x1, [x1, #3792]
   8423c:	910ea000 	add	x0, x0, #0x3a8
   84240:	f9475c42 	ldr	x2, [x2, #3768]
   84244:	b9400021 	ldr	w1, [x1]
}
   84248:	a94153f3 	ldp	x19, x20, [sp, #16]
	printf("paging mem: used %u total %u (%u/100)\n", 
   8424c:	b9400042 	ldr	w2, [x2]
        paging_pages_used*100/(paging_pages_total));
   84250:	1b037c23 	mul	w3, w1, w3
}
   84254:	a9425bf5 	ldp	x21, x22, [sp, #32]
   84258:	f9401bf7 	ldr	x23, [sp, #48]
   8425c:	a8c47bfd 	ldp	x29, x30, [sp], #64
	printf("paging mem: used %u total %u (%u/100)\n", 
   84260:	1ac20863 	udiv	w3, w3, w2
   84264:	17fff4d5 	b	815b8 <tfp_printf>

0000000000084268 <copy_process>:
    arg: arg to kernel thread; or stack (userva) for user thread
    name: to be copied to task->name[]. if null, copy parent's name
*/
// Q2: quest "two cooperative printers"
int copy_process(unsigned long clone_flags, unsigned long fn, unsigned long arg,
    const char *name) {
   84268:	a9b87bfd 	stp	x29, x30, [sp, #-128]!
   8426c:	910003fd 	mov	x29, sp
   84270:	a90153f3 	stp	x19, x20, [sp, #16]
   84274:	aa0303f3 	mov	x19, x3
   84278:	a9025bf5 	stp	x21, x22, [sp, #32]
   8427c:	a90363f7 	stp	x23, x24, [sp, #48]
	struct task_struct *p = 0, *cur=myproc(); 
    int i, pid; 

	acquire(&sched_lock);	
   84280:	b0000098 	adrp	x24, 95000 <wordsworth.1725+0xee10>
   84284:	b0000097 	adrp	x23, 95000 <wordsworth.1725+0xee10>
    const char *name) {
   84288:	a9046bf9 	stp	x25, x26, [sp, #64]
   8428c:	a90573fb 	stp	x27, x28, [sp, #80]
	// find an empty tcb slot
	for (i = 0; i < NR_TASKS; i++) {
   84290:	5280001c 	mov	w28, #0x0                   	// #0
    const char *name) {
   84294:	a90687e0 	stp	x0, x1, [sp, #104]
   84298:	f9003fe2 	str	x2, [sp, #120]
	push_off(); 
   8429c:	97fff643 	bl	81ba8 <push_off>
    p=mycpu()->proc; 
   842a0:	b0000080 	adrp	x0, 95000 <wordsworth.1725+0xee10>
        pid = (lastpid+1+i) % NR_TASKS; 
   842a4:	f0000321 	adrp	x1, eb000 <lastpid>
   842a8:	91000039 	add	x25, x1, #0x0
    p=mycpu()->proc; 
   842ac:	f9478000 	ldr	x0, [x0, #3840]
   842b0:	f9400014 	ldr	x20, [x0]
    pop_off(); 
   842b4:	97fff673 	bl	81c80 <pop_off>
	acquire(&sched_lock);	
   842b8:	9139e300 	add	x0, x24, #0xe78
   842bc:	97fff64f 	bl	81bf8 <acquire>
		p = task[pid]; BUG_ON(!p); 
   842c0:	90000081 	adrp	x1, 94000 <wordsworth.1725+0xde10>
   842c4:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   842c8:	910b8036 	add	x22, x1, #0x2e0
   842cc:	910bc015 	add	x21, x0, #0x2f0
   842d0:	14000005 	b	842e4 <copy_process+0x7c>
		if (p->state == TASK_UNUSED)
   842d4:	b9413b62 	ldr	w2, [x27, #312]
	for (i = 0; i < NR_TASKS; i++) {
   842d8:	7100839f 	cmp	w28, #0x20
		if (p->state == TASK_UNUSED)
   842dc:	340002a2 	cbz	w2, 84330 <copy_process+0xc8>
	for (i = 0; i < NR_TASKS; i++) {
   842e0:	54000920 	b.eq	84404 <copy_process+0x19c>  // b.none
        pid = (lastpid+1+i) % NR_TASKS; 
   842e4:	b9400324 	ldr	w4, [x25]
		p = task[pid]; BUG_ON(!p); 
   842e8:	f9477ae2 	ldr	x2, [x23, #3824]
        pid = (lastpid+1+i) % NR_TASKS; 
   842ec:	11000484 	add	w4, w4, #0x1
   842f0:	0b1c0084 	add	w4, w4, w28
   842f4:	1100079c 	add	w28, w28, #0x1
   842f8:	6b0403fa 	negs	w26, w4
   842fc:	12001084 	and	w4, w4, #0x1f
   84300:	1200135a 	and	w26, w26, #0x1f
   84304:	5a9a449a 	csneg	w26, w4, w26, mi	// mi = first
		p = task[pid]; BUG_ON(!p); 
   84308:	f87ad85b 	ldr	x27, [x2, w26, sxtw #3]
   8430c:	b5fffe5b 	cbnz	x27, 842d4 <copy_process+0x6c>
   84310:	52804a82 	mov	w2, #0x254                 	// #596
   84314:	aa1603e1 	mov	x1, x22
   84318:	aa1503e0 	mov	x0, x21
   8431c:	97fff577 	bl	818f8 <assertion_failed>
		if (p->state == TASK_UNUSED)
   84320:	b9413b62 	ldr	w2, [x27, #312]
	for (i = 0; i < NR_TASKS; i++) {
   84324:	7100839f 	cmp	w28, #0x20
		if (p->state == TASK_UNUSED)
   84328:	35fffdc2 	cbnz	w2, 842e0 <copy_process+0x78>
   8432c:	d503201f 	nop
			{V("alloc pid %d", pid); lastpid=pid; break;}
   84330:	f0000320 	adrp	x0, eb000 <lastpid>
	}
	if (i == NR_TASKS) 
		{release(&sched_lock); return -1;}

	memset(p, 0, sizeof(struct task_struct));
   84334:	52802d02 	mov	w2, #0x168                 	// #360
   84338:	52800001 	mov	w1, #0x0                   	// #0
	initlock(&p->lock, "proc");
   8433c:	91046379 	add	x25, x27, #0x118
			{V("alloc pid %d", pid); lastpid=pid; break;}
   84340:	b900001a 	str	w26, [x0]
	memset(p, 0, sizeof(struct task_struct));
   84344:	aa1b03e0 	mov	x0, x27
   84348:	97fff578 	bl	81928 <memset>

	acquire(&p->lock);	
    acquire(&cur->lock);	
   8434c:	9104629c 	add	x28, x20, #0x118
	initlock(&p->lock, "proc");
   84350:	90000081 	adrp	x1, 94000 <wordsworth.1725+0xde10>
   84354:	910f4021 	add	x1, x1, #0x3d0
   84358:	aa1903e0 	mov	x0, x25
   8435c:	97fff605 	bl	81b70 <initlock>
	acquire(&p->lock);	
   84360:	aa1903e0 	mov	x0, x25
   84364:	97fff625 	bl	81bf8 <acquire>
    acquire(&cur->lock);	
   84368:	aa1c03e0 	mov	x0, x28
   8436c:	97fff623 	bl	81bf8 <acquire>

    // load fn/arg to cpu context. cf ret_from_fork
    /* STUDENT: TODO: your code here */
    
    p->cpu_context.x19 = fn;
    p->cpu_context.x20 = arg;
   84370:	a94707e0 	ldp	x0, x1, [sp, #112]
   84374:	a9000760 	stp	x0, x1, [x27]


    // also inherit task name
    if (name)
   84378:	9103c360 	add	x0, x27, #0xf0
   8437c:	b40003d3 	cbz	x19, 843f4 <copy_process+0x18c>
        safestrcpy(p->name, name, sizeof(p->name));
   84380:	aa1303e1 	mov	x1, x19
   84384:	52800202 	mov	w2, #0x10                  	// #16
   84388:	97fff5ce 	bl	81ac0 <safestrcpy>
	/* STUDENT: TODO: your code here */

    unsigned long stack_top = (unsigned long)p + THREAD_SIZE;

    p->cpu_context.sp = stack_top;
    p->cpu_context.pc = (unsigned long)ret_from_fork;
   8438c:	b0000080 	adrp	x0, 95000 <wordsworth.1725+0xee10>
    unsigned long stack_top = (unsigned long)p + THREAD_SIZE;
   84390:	91400762 	add	x2, x27, #0x1, lsl #12
	p->credits = p->priority = cur->priority;
   84394:	f940a681 	ldr	x1, [x20, #328]
	p->pid = pid; 
   84398:	b901377a 	str	w26, [x27, #308]
    p->cpu_context.pc = (unsigned long)ret_from_fork;
   8439c:	f9478c00 	ldr	x0, [x0, #3864]
   843a0:	a9058362 	stp	x2, x0, [x27, #88]
	p->flags = clone_flags;
   843a4:	f94037e0 	ldr	x0, [sp, #104]
   843a8:	f9008760 	str	x0, [x27, #264]
	p->credits = p->priority = cur->priority;
   843ac:	a9140761 	stp	x1, x1, [x27, #320]
	
    release(&cur->lock);
   843b0:	aa1c03e0 	mov	x0, x28
   843b4:	97fff653 	bl	81d00 <release>
	release(&p->lock);
   843b8:	aa1903e0 	mov	x0, x25
   843bc:	97fff651 	bl	81d00 <release>
 	p->parent = cur;
	// the last thing: change the task's state so that the scheduler can pick up
    // the task to run in the future
	/* STUDENT: TODO: your code here */

    p->state = TASK_RUNNABLE;
   843c0:	52800080 	mov	w0, #0x4                   	// #4
   843c4:	b9013b60 	str	w0, [x27, #312]
 	p->parent = cur;
   843c8:	f900b374 	str	x20, [x27, #352]
	
	release(&sched_lock);
   843cc:	9139e300 	add	x0, x24, #0xe78
   843d0:	97fff64c 	bl	81d00 <release>

	return pid;
}
   843d4:	2a1a03e0 	mov	w0, w26
   843d8:	a94153f3 	ldp	x19, x20, [sp, #16]
   843dc:	a9425bf5 	ldp	x21, x22, [sp, #32]
   843e0:	a94363f7 	ldp	x23, x24, [sp, #48]
   843e4:	a9446bf9 	ldp	x25, x26, [sp, #64]
   843e8:	a94573fb 	ldp	x27, x28, [sp, #80]
   843ec:	a8c87bfd 	ldp	x29, x30, [sp], #128
   843f0:	d65f03c0 	ret
	    safestrcpy(p->name, cur->name, sizeof(cur->name));
   843f4:	9103c281 	add	x1, x20, #0xf0
   843f8:	52800202 	mov	w2, #0x10                  	// #16
   843fc:	97fff5b1 	bl	81ac0 <safestrcpy>
   84400:	17ffffe3 	b	8438c <copy_process+0x124>
		{release(&sched_lock); return -1;}
   84404:	9139e300 	add	x0, x24, #0xe78
   84408:	1280001a 	mov	w26, #0xffffffff            	// #-1
   8440c:	97fff63d 	bl	81d00 <release>
   84410:	17fffff1 	b	843d4 <copy_process+0x16c>
   84414:	00000000 	udf	#0

0000000000084418 <handler>:
#include "plat.h"
#include "utils.h"
#include "debug.h"
#include "sched.h"

static void handler(TKernelTimerHandle hTimer, void *param, void *context) {
   84418:	d10183ff 	sub	sp, sp, #0x60
   8441c:	a9017bfd 	stp	x29, x30, [sp, #16]
   84420:	910043fd 	add	x29, sp, #0x10
   84424:	a90253f3 	stp	x19, x20, [sp, #32]
   84428:	aa0003f3 	mov	x19, x0
   8442c:	aa0103f4 	mov	x20, x1
	unsigned sec, msec; 
	current_time(&sec, &msec);
   84430:	910163e0 	add	x0, sp, #0x58
   84434:	910173e1 	add	x1, sp, #0x5c
static void handler(TKernelTimerHandle hTimer, void *param, void *context) {
   84438:	a9035bf5 	stp	x21, x22, [sp, #48]
   8443c:	aa0203f5 	mov	x21, x2
   84440:	f90023f7 	str	x23, [sp, #64]
	current_time(&sec, &msec);
   84444:	97fff6a5 	bl	81ed8 <current_time>
	I("%u.%03u: fired. on cpu %d. htimer %ld, param %lx, contex %lx", sec, msec,
   84448:	294b5ff6 	ldp	w22, w23, [sp, #88]
   8444c:	940006af 	bl	85f08 <cpuid>
   84450:	f90003f5 	str	x21, [sp]
   84454:	aa1403e7 	mov	x7, x20
   84458:	aa1303e6 	mov	x6, x19
   8445c:	2a1703e4 	mov	w4, w23
   84460:	2a1603e3 	mov	w3, w22
   84464:	2a0003e5 	mov	w5, w0
   84468:	52800122 	mov	w2, #0x9                   	// #9
   8446c:	90000081 	adrp	x1, 94000 <wordsworth.1725+0xde10>
   84470:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   84474:	9110c021 	add	x1, x1, #0x430
   84478:	91110000 	add	x0, x0, #0x440
   8447c:	97fff44f 	bl	815b8 <tfp_printf>
		cpuid(), hTimer, (unsigned long)param, (unsigned long)context); 
}
   84480:	a9417bfd 	ldp	x29, x30, [sp, #16]
   84484:	a94253f3 	ldp	x19, x20, [sp, #32]
   84488:	a9435bf5 	ldp	x21, x22, [sp, #48]
   8448c:	f94023f7 	ldr	x23, [sp, #64]
   84490:	910183ff 	add	sp, sp, #0x60
   84494:	d65f03c0 	ret

0000000000084498 <kern_task_print>:
////////////////////////////////////////////////
//  two kernel tasks print msgs. 
//  simple test for scheduler and context switch 

// a simple kernel task: print a message, yield
static void kern_task_print(const char *str) {
   84498:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   8449c:	910003fd 	mov	x29, sp
   844a0:	a90153f3 	stp	x19, x20, [sp, #16]
   844a4:	aa0003f4 	mov	x20, x0
	printf("Kernel task started at EL %d, pid %d\r\n", get_el(), myproc()->pid);
   844a8:	940006af 	bl	85f64 <get_el>
   844ac:	2a0003f3 	mov	w19, w0
   844b0:	97fffcc4 	bl	837c0 <myproc>
   844b4:	aa0003e2 	mov	x2, x0
   844b8:	2a1303e1 	mov	w1, w19
   844bc:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   844c0:	90000093 	adrp	x19, 94000 <wordsworth.1725+0xde10>
   844c4:	91124000 	add	x0, x0, #0x490

	while (1) {
		printf("%s", str); 
   844c8:	9112e273 	add	x19, x19, #0x4b8
	printf("Kernel task started at EL %d, pid %d\r\n", get_el(), myproc()->pid);
   844cc:	b9413442 	ldr	w2, [x2, #308]
   844d0:	97fff43a 	bl	815b8 <tfp_printf>
   844d4:	d503201f 	nop
		printf("%s", str); 
   844d8:	aa1403e1 	mov	x1, x20
   844dc:	aa1303e0 	mov	x0, x19
   844e0:	97fff436 	bl	815b8 <tfp_printf>
		ms_delay(10); // NB: spin waiting (silly). for testing sched only
   844e4:	52800140 	mov	w0, #0xa                   	// #10
   844e8:	97fff674 	bl	81eb8 <ms_delay>
		yield();
   844ec:	97fffdb1 	bl	83bb0 <yield>
	while (1) {
   844f0:	17fffffa 	b	844d8 <kern_task_print+0x40>
   844f4:	d503201f 	nop

00000000000844f8 <kern_task_return>:

////////////////////////////////////////////////
// test kernel task return, exit() 

// a task returns from its func
static void kern_task_return(const char *str) {
   844f8:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   844fc:	910003fd 	mov	x29, sp
   84500:	a90153f3 	stp	x19, x20, [sp, #16]
   84504:	aa0003f3 	mov	x19, x0
	printf("Kernel task started at EL %d, pid %d\r\n", get_el(), myproc()->pid);
   84508:	94000697 	bl	85f64 <get_el>
   8450c:	2a0003f4 	mov	w20, w0
   84510:	97fffcac 	bl	837c0 <myproc>
   84514:	aa0003e2 	mov	x2, x0
   84518:	2a1403e1 	mov	w1, w20
   8451c:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   84520:	91124000 	add	x0, x0, #0x490
   84524:	b9413442 	ldr	w2, [x2, #308]
   84528:	97fff424 	bl	815b8 <tfp_printf>
    printf("%s", str); 
   8452c:	aa1303e1 	mov	x1, x19
   84530:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
    return;     
    // what will happen? 
    // this func is called from ret_from_fork (entry.S). after returning from 
	// this func, it goes back to ret_from_fork and continues there -- in an inf loop
    // (cf entry.S ret_from_fork)
}
   84534:	a94153f3 	ldp	x19, x20, [sp, #16]
    printf("%s", str); 
   84538:	9112e000 	add	x0, x0, #0x4b8
}
   8453c:	a8c27bfd 	ldp	x29, x30, [sp], #32
    printf("%s", str); 
   84540:	17fff41e 	b	815b8 <tfp_printf>
   84544:	d503201f 	nop

0000000000084548 <kern_task_exit>:

// a task calling "exit"
static void kern_task_exit(const char *str) {
   84548:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   8454c:	910003fd 	mov	x29, sp
   84550:	a90153f3 	stp	x19, x20, [sp, #16]
   84554:	aa0003f3 	mov	x19, x0
	printf("Kernel task started at EL %d, pid %d\r\n", get_el(), myproc()->pid);
   84558:	94000683 	bl	85f64 <get_el>
   8455c:	2a0003f4 	mov	w20, w0
   84560:	97fffc98 	bl	837c0 <myproc>
   84564:	aa0003e2 	mov	x2, x0
   84568:	2a1403e1 	mov	w1, w20
   8456c:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   84570:	91124000 	add	x0, x0, #0x490
   84574:	b9413442 	ldr	w2, [x2, #308]
   84578:	97fff410 	bl	815b8 <tfp_printf>
    printf("%s", str); 
   8457c:	aa1303e1 	mov	x1, x19
   84580:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   84584:	9112e000 	add	x0, x0, #0x4b8
   84588:	97fff40c 	bl	815b8 <tfp_printf>
    exit_process(0); 
}
   8458c:	a94153f3 	ldp	x19, x20, [sp, #16]
    exit_process(0); 
   84590:	52800000 	mov	w0, #0x0                   	// #0
}
   84594:	a8c27bfd 	ldp	x29, x30, [sp], #32
    exit_process(0); 
   84598:	17fffe84 	b	83fa8 <exit_process>
   8459c:	d503201f 	nop

00000000000845a0 <kern_task_donut>:
//  modeled after test_kern_tasks_print()

// Q4: quest: "two donuts"
extern void donut(int idx); 	//donut.c
extern void donut_canvas_init(void); //donut.c don't forget to init canvas -- once
void kern_task_donut(int idx) {
   845a0:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   845a4:	910003fd 	mov	x29, sp
   845a8:	a90153f3 	stp	x19, x20, [sp, #16]
   845ac:	2a0003f3 	mov	w19, w0
	printf("process started EL %d, pid %d idx %d\r\n", 
   845b0:	9400066d 	bl	85f64 <get_el>
   845b4:	2a0003f4 	mov	w20, w0
        get_el(), myproc()->pid, idx);
   845b8:	97fffc82 	bl	837c0 <myproc>
   845bc:	aa0003e2 	mov	x2, x0
	printf("process started EL %d, pid %d idx %d\r\n", 
   845c0:	2a1403e1 	mov	w1, w20
   845c4:	2a1303e3 	mov	w3, w19
   845c8:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   845cc:	91130000 	add	x0, x0, #0x4c0
   845d0:	b9413442 	ldr	w2, [x2, #308]
   845d4:	97fff3f9 	bl	815b8 <tfp_printf>
    // exp: diff proirities --> donuts will turn at diff rates
	/* STUDENT: TODO: your code here */
    donut(idx);
   845d8:	2a1303e0 	mov	w0, w19
}
   845dc:	a94153f3 	ldp	x19, x20, [sp, #16]
   845e0:	a8c27bfd 	ldp	x29, x30, [sp], #32
    donut(idx);
   845e4:	17fffb39 	b	832c8 <donut>

00000000000845e8 <task_reader>:
static void task_reader() {
   845e8:	a9b87bfd 	stp	x29, x30, [sp, #-128]!
    printf("in reader\n");
   845ec:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   845f0:	9113a000 	add	x0, x0, #0x4e8
static void task_reader() {
   845f4:	910003fd 	mov	x29, sp
   845f8:	a90153f3 	stp	x19, x20, [sp, #16]
   845fc:	90000453 	adrp	x19, 10c000 <nread>
    while (nread == nwrite) {   // pipe empty
   84600:	91000273 	add	x19, x19, #0x0
   84604:	9101a3f4 	add	x20, sp, #0x68
static void task_reader() {
   84608:	a9025bf5 	stp	x21, x22, [sp, #32]
            str[i] = pipebuf[nread % NSIZE];
   8460c:	5290a3f6 	mov	w22, #0x851f                	// #34079
static void task_reader() {
   84610:	a9046bf9 	stp	x25, x26, [sp, #64]
            str[i] = pipebuf[nread % NSIZE];
   84614:	91002279 	add	x25, x19, #0x8
   84618:	b0000095 	adrp	x21, 95000 <wordsworth.1725+0xee10>
   8461c:	9000009a 	adrp	x26, 94000 <wordsworth.1725+0xde10>
   84620:	72aa3d76 	movk	w22, #0x51eb, lsl #16
static void task_reader() {
   84624:	a90363f7 	stp	x23, x24, [sp, #48]
   84628:	90000098 	adrp	x24, 94000 <wordsworth.1725+0xde10>
   8462c:	90000097 	adrp	x23, 94000 <wordsworth.1725+0xde10>
   84630:	a90573fb 	stp	x27, x28, [sp, #80]
    printf("in reader\n");
   84634:	97fff3e1 	bl	815b8 <tfp_printf>
    acquire(&testlock); 
   84638:	913a42bb 	add	x27, x21, #0xe90
   8463c:	aa1b03e0 	mov	x0, x27
   84640:	97fff56e 	bl	81bf8 <acquire>
    while (nread == nwrite) {   // pipe empty
   84644:	29400e62 	ldp	w2, w3, [x19]
   84648:	6b02007f 	cmp	w3, w2
   8464c:	54000161 	b.ne	84678 <task_reader+0x90>  // b.any
        printf("Reader sleeping\n");
   84650:	9113e35c 	add	x28, x26, #0x4f8
   84654:	d503201f 	nop
   84658:	aa1c03e0 	mov	x0, x28
   8465c:	97fff3d7 	bl	815b8 <tfp_printf>
        sleep(&testlock, &testlock);
   84660:	aa1b03e1 	mov	x1, x27
   84664:	aa1b03e0 	mov	x0, x27
   84668:	97fffdc6 	bl	83d80 <sleep>
    while (nread == nwrite) {   // pipe empty
   8466c:	29400e62 	ldp	w2, w3, [x19]
   84670:	6b03005f 	cmp	w2, w3
   84674:	54ffff20 	b.eq	84658 <task_reader+0x70>  // b.none
   84678:	4b020063 	sub	w3, w3, w2
   8467c:	aa1403e1 	mov	x1, x20
static void task_reader() {
   84680:	52800004 	mov	w4, #0x0                   	// #0
    for (i=0; i<n; i++) {
   84684:	5280001b 	mov	w27, #0x0                   	// #0
            str[i] = pipebuf[nread % NSIZE];
   84688:	52801905 	mov	w5, #0xc8                  	// #200
   8468c:	d503201f 	nop
        if (nread == nwrite){
   84690:	6b03037f 	cmp	w27, w3
            str[i] = pipebuf[nread % NSIZE];
   84694:	9b367c40 	smull	x0, w2, w22
    for (i=0; i<n; i++) {
   84698:	1100077b 	add	w27, w27, #0x1
        if (nread == nwrite){
   8469c:	54000300 	b.eq	846fc <task_reader+0x114>  // b.none
            str[i] = pipebuf[nread % NSIZE];
   846a0:	9366fc00 	asr	x0, x0, #38
   846a4:	52800024 	mov	w4, #0x1                   	// #1
   846a8:	4b827c00 	sub	w0, w0, w2, asr #31
    for (i=0; i<n; i++) {
   846ac:	7100437f 	cmp	w27, #0x10
            str[i] = pipebuf[nread % NSIZE];
   846b0:	1b058800 	msub	w0, w0, w5, w2
   846b4:	0b040042 	add	w2, w2, w4
   846b8:	3860cb20 	ldrb	w0, [x25, w0, sxtw]
   846bc:	38001420 	strb	w0, [x1], #1
    for (i=0; i<n; i++) {
   846c0:	54fffe81 	b.ne	84690 <task_reader+0xa8>  // b.any
   846c4:	b9000262 	str	w2, [x19]
    wakeup(&testlock);
   846c8:	913a42bc 	add	x28, x21, #0xe90
   846cc:	aa1c03e0 	mov	x0, x28
   846d0:	97fffd88 	bl	83cf0 <wakeup>
    release(&testlock); 
   846d4:	aa1c03e0 	mov	x0, x28
   846d8:	97fff58a 	bl	81d00 <release>
        W("read: %d bytes. %s", n, mybuf);
   846dc:	2a1b03e3 	mov	w3, w27
   846e0:	aa1403e4 	mov	x4, x20
   846e4:	9110c301 	add	x1, x24, #0x430
   846e8:	911442e0 	add	x0, x23, #0x510
   846ec:	52802602 	mov	w2, #0x130                 	// #304
        mybuf[n] = '\0';
   846f0:	383bca9f 	strb	wzr, [x20, w27, sxtw]
        W("read: %d bytes. %s", n, mybuf);
   846f4:	97fff3b1 	bl	815b8 <tfp_printf>
    while (1) {
   846f8:	17ffffd0 	b	84638 <task_reader+0x50>
   846fc:	34000044 	cbz	w4, 84704 <task_reader+0x11c>
   84700:	b9000262 	str	w2, [x19]
    for (i=0; i<n; i++) {
   84704:	2a0303fb 	mov	w27, w3
   84708:	17fffff0 	b	846c8 <task_reader+0xe0>
   8470c:	d503201f 	nop

0000000000084710 <task_writer>:
static void task_writer() {
   84710:	a9ba7bfd 	stp	x29, x30, [sp, #-96]!
   84714:	910003fd 	mov	x29, sp
   84718:	a90573fb 	stp	x27, x28, [sp, #80]
   8471c:	9000045c 	adrp	x28, 10c000 <nread>
        while (nwrite == nread + NSIZE) { // pipe write full
   84720:	9100039c 	add	x28, x28, #0x0
        pipebuf[nwrite % NSIZE] = str[i];
   84724:	9100239b 	add	x27, x28, #0x8
static void task_writer() {
   84728:	a90363f7 	stp	x23, x24, [sp, #48]
   8472c:	90000098 	adrp	x24, 94000 <wordsworth.1725+0xde10>
            printf("writer sleeping\n");
   84730:	9114e318 	add	x24, x24, #0x538
static void task_writer() {
   84734:	a9046bf9 	stp	x25, x26, [sp, #64]
        pipebuf[nwrite % NSIZE] = str[i];
   84738:	5290a3f9 	mov	w25, #0x851f                	// #34079
   8473c:	b0000097 	adrp	x23, 95000 <wordsworth.1725+0xee10>
   84740:	9000009a 	adrp	x26, 94000 <wordsworth.1725+0xde10>
   84744:	72aa3d79 	movk	w25, #0x51eb, lsl #16
static void task_writer() {
   84748:	a90153f3 	stp	x19, x20, [sp, #16]
   8474c:	a9025bf5 	stp	x21, x22, [sp, #32]
   84750:	d0000016 	adrp	x22, 86000 <__asm_dcache_level+0xc>
   84754:	d503201f 	nop
        do_write(wordsworth, strlen(wordsworth)); // NB: strlen does NOT count '\0'
   84758:	9107c2c0 	add	x0, x22, #0x1f0
    acquire(&testlock); 
   8475c:	913a42f3 	add	x19, x23, #0xe90
        do_write(wordsworth, strlen(wordsworth)); // NB: strlen does NOT count '\0'
   84760:	97fff4e6 	bl	81af8 <strlen>
   84764:	2a0003f5 	mov	w21, w0
    acquire(&testlock); 
   84768:	aa1303e0 	mov	x0, x19
   8476c:	97fff523 	bl	81bf8 <acquire>
    while (i<n) {
   84770:	d2800014 	mov	x20, #0x0                   	// #0
   84774:	710002bf 	cmp	w21, #0x0
   84778:	540000ec 	b.gt	84794 <task_writer+0x84>
   8477c:	1400001c 	b	847ec <task_writer+0xdc>
            printf("writer sleeping\n");
   84780:	aa1803e0 	mov	x0, x24
   84784:	97fff38d 	bl	815b8 <tfp_printf>
            sleep(&testlock, &testlock);
   84788:	aa1303e1 	mov	x1, x19
   8478c:	aa1303e0 	mov	x0, x19
   84790:	97fffd7c 	bl	83d80 <sleep>
        while (nwrite == nread + NSIZE) { // pipe write full
   84794:	29400780 	ldp	w0, w1, [x28]
   84798:	11032000 	add	w0, w0, #0xc8
   8479c:	6b01001f 	cmp	w0, w1
   847a0:	54ffff00 	b.eq	84780 <task_writer+0x70>  // b.none
        printf("Writing\n");
   847a4:	91154340 	add	x0, x26, #0x550
   847a8:	97fff384 	bl	815b8 <tfp_printf>
        pipebuf[nwrite % NSIZE] = str[i];
   847ac:	b9400782 	ldr	w2, [x28, #4]
   847b0:	9107c2c3 	add	x3, x22, #0x1f0
   847b4:	52801904 	mov	w4, #0xc8                  	// #200
        wakeup(&testlock);
   847b8:	aa1303e0 	mov	x0, x19
        nwrite++;
   847bc:	11000441 	add	w1, w2, #0x1
   847c0:	b9000781 	str	w1, [x28, #4]
        pipebuf[nwrite % NSIZE] = str[i];
   847c4:	38636a83 	ldrb	w3, [x20, x3]
   847c8:	91000694 	add	x20, x20, #0x1
   847cc:	9b397c41 	smull	x1, w2, w25
   847d0:	9366fc21 	asr	x1, x1, #38
   847d4:	4b827c21 	sub	w1, w1, w2, asr #31
   847d8:	1b048821 	msub	w1, w1, w4, w2
   847dc:	3821cb63 	strb	w3, [x27, w1, sxtw]
        wakeup(&testlock);
   847e0:	97fffd44 	bl	83cf0 <wakeup>
    while (i<n) {
   847e4:	6b1402bf 	cmp	w21, w20
   847e8:	54fffd6c 	b.gt	84794 <task_writer+0x84>
    wakeup(&testlock);
   847ec:	913a42f3 	add	x19, x23, #0xe90
   847f0:	aa1303e0 	mov	x0, x19
   847f4:	97fffd3f 	bl	83cf0 <wakeup>
    release(&testlock); 
   847f8:	aa1303e0 	mov	x0, x19
   847fc:	97fff541 	bl	81d00 <release>
        ms_delay(100); // spin waiting (silly). for testing only
   84800:	52800c80 	mov	w0, #0x64                  	// #100
   84804:	97fff5ad 	bl	81eb8 <ms_delay>
    while (1) {
   84808:	17ffffd4 	b	84758 <task_writer+0x48>
   8480c:	d503201f 	nop

0000000000084810 <test_ktimer>:
void test_ktimer() {
   84810:	a9ba7bfd 	stp	x29, x30, [sp, #-96]!
   84814:	910003fd 	mov	x29, sp
   84818:	a90153f3 	stp	x19, x20, [sp, #16]
	current_time(&sec, &msec); 
   8481c:	910163f4 	add	x20, sp, #0x58
   84820:	aa1403e0 	mov	x0, x20
void test_ktimer() {
   84824:	a9025bf5 	stp	x21, x22, [sp, #32]
	current_time(&sec, &msec); 
   84828:	910173f5 	add	x21, sp, #0x5c
   8482c:	aa1503e1 	mov	x1, x21
void test_ktimer() {
   84830:	f9001bf7 	str	x23, [sp, #48]
	current_time(&sec, &msec); 
   84834:	97fff5a9 	bl	81ed8 <current_time>
	I("%u.%03u start delaying 500ms...", sec, msec); 
   84838:	294b13e3 	ldp	w3, w4, [sp, #88]
   8483c:	90000097 	adrp	x23, 94000 <wordsworth.1725+0xde10>
   84840:	9110c2f3 	add	x19, x23, #0x430
   84844:	52800242 	mov	w2, #0x12                  	// #18
   84848:	aa1303e1 	mov	x1, x19
   8484c:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   84850:	91158000 	add	x0, x0, #0x560
   84854:	97fff359 	bl	815b8 <tfp_printf>
	ms_delay(500); 
   84858:	52803e80 	mov	w0, #0x1f4                 	// #500
   8485c:	97fff597 	bl	81eb8 <ms_delay>
	current_time(&sec, &msec);
   84860:	aa1503e1 	mov	x1, x21
   84864:	aa1403e0 	mov	x0, x20
   84868:	97fff59c 	bl	81ed8 <current_time>
	int t = ktimer_start(500, handler, (void *)0xdeadbeef, (void*)0xdeaddeed);
   8486c:	90000015 	adrp	x21, 84000 <exit_process+0x58>
	I("%u.%03u ended delaying 500ms", sec, msec); 
   84870:	294b13e3 	ldp	w3, w4, [sp, #88]
   84874:	aa1303e1 	mov	x1, x19
   84878:	528002a2 	mov	w2, #0x15                  	// #21
   8487c:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   84880:	91166000 	add	x0, x0, #0x598
	int t = ktimer_start(500, handler, (void *)0xdeadbeef, (void*)0xdeaddeed);
   84884:	911062b5 	add	x21, x21, #0x418
	I("%u.%03u ended delaying 500ms", sec, msec); 
   84888:	97fff34c 	bl	815b8 <tfp_printf>
	I("timer start. timer id %u", t); 
   8488c:	90000094 	adrp	x20, 94000 <wordsworth.1725+0xde10>
	int t = ktimer_start(500, handler, (void *)0xdeadbeef, (void*)0xdeaddeed);
   84890:	d29bdda3 	mov	x3, #0xdeed                	// #57069
   84894:	d297dde2 	mov	x2, #0xbeef                	// #48879
   84898:	aa1503e1 	mov	x1, x21
   8489c:	f2bbd5a3 	movk	x3, #0xdead, lsl #16
   848a0:	f2bbd5a2 	movk	x2, #0xdead, lsl #16
   848a4:	52803e80 	mov	w0, #0x1f4                 	// #500
   848a8:	97fff5b4 	bl	81f78 <ktimer_start>
	I("timer start. timer id %u", t); 
   848ac:	2a0003e3 	mov	w3, w0
   848b0:	aa1303e1 	mov	x1, x19
   848b4:	91172294 	add	x20, x20, #0x5c8
   848b8:	52800322 	mov	w2, #0x19                  	// #25
	int t = ktimer_start(500, handler, (void *)0xdeadbeef, (void*)0xdeaddeed);
   848bc:	2a0003f6 	mov	w22, w0
	I("timer start. timer id %u", t); 
   848c0:	aa1403e0 	mov	x0, x20
   848c4:	97fff33d 	bl	815b8 <tfp_printf>
	ms_delay(1000);
   848c8:	52807d00 	mov	w0, #0x3e8                 	// #1000
   848cc:	97fff57b 	bl	81eb8 <ms_delay>
	I("timer %d should have fired", t); 
   848d0:	2a1603e3 	mov	w3, w22
   848d4:	aa1303e1 	mov	x1, x19
   848d8:	52800362 	mov	w2, #0x1b                  	// #27
   848dc:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   848e0:	9117e000 	add	x0, x0, #0x5f8
   848e4:	97fff335 	bl	815b8 <tfp_printf>
	t = ktimer_start(500, handler, (void *)0xdeadbeef, (void*)0xdeaddeed);
   848e8:	d29bdda3 	mov	x3, #0xdeed                	// #57069
   848ec:	d297dde2 	mov	x2, #0xbeef                	// #48879
   848f0:	aa1503e1 	mov	x1, x21
   848f4:	f2bbd5a3 	movk	x3, #0xdead, lsl #16
   848f8:	f2bbd5a2 	movk	x2, #0xdead, lsl #16
   848fc:	52803e80 	mov	w0, #0x1f4                 	// #500
   84900:	97fff59e 	bl	81f78 <ktimer_start>
	I("timer start. timer id %u", t); 
   84904:	2a0003e3 	mov	w3, w0
   84908:	aa1303e1 	mov	x1, x19
   8490c:	aa1403e0 	mov	x0, x20
   84910:	528003e2 	mov	w2, #0x1f                  	// #31
   84914:	97fff329 	bl	815b8 <tfp_printf>
	t = ktimer_start(1000, handler, (void *)0xdeadbeef, (void*)0xdeaddeed);
   84918:	d29bdda3 	mov	x3, #0xdeed                	// #57069
   8491c:	d297dde2 	mov	x2, #0xbeef                	// #48879
   84920:	aa1503e1 	mov	x1, x21
   84924:	f2bbd5a3 	movk	x3, #0xdead, lsl #16
   84928:	f2bbd5a2 	movk	x2, #0xdead, lsl #16
   8492c:	52807d00 	mov	w0, #0x3e8                 	// #1000
   84930:	97fff592 	bl	81f78 <ktimer_start>
	I("timer start. timer id %u", t); 
   84934:	2a0003e3 	mov	w3, w0
   84938:	aa1303e1 	mov	x1, x19
   8493c:	52800422 	mov	w2, #0x21                  	// #33
   84940:	aa1403e0 	mov	x0, x20
   84944:	97fff31d 	bl	815b8 <tfp_printf>
	ms_delay(2000); 
   84948:	5280fa00 	mov	w0, #0x7d0                 	// #2000
   8494c:	97fff55b 	bl	81eb8 <ms_delay>
	I("both timers should have fired"); 
   84950:	aa1303e1 	mov	x1, x19
   84954:	52800462 	mov	w2, #0x23                  	// #35
   84958:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   8495c:	9118a000 	add	x0, x0, #0x628
   84960:	97fff316 	bl	815b8 <tfp_printf>
	t = ktimer_start(500, handler, (void *)0xdeadbeef, (void*)0xdeaddeed);
   84964:	d29bdda3 	mov	x3, #0xdeed                	// #57069
   84968:	d297dde2 	mov	x2, #0xbeef                	// #48879
   8496c:	aa1503e1 	mov	x1, x21
   84970:	f2bbd5a3 	movk	x3, #0xdead, lsl #16
   84974:	f2bbd5a2 	movk	x2, #0xdead, lsl #16
   84978:	52803e80 	mov	w0, #0x1f4                 	// #500
   8497c:	97fff57f 	bl	81f78 <ktimer_start>
   84980:	2a0003f5 	mov	w21, w0
	I("timer start. timer id %u", t);
   84984:	aa1303e1 	mov	x1, x19
   84988:	2a1503e3 	mov	w3, w21
   8498c:	528004e2 	mov	w2, #0x27                  	// #39
	t = ktimer_start(500, handler, (void *)0xdeadbeef, (void*)0xdeaddeed);
   84990:	b9004fe0 	str	w0, [sp, #76]
	I("timer start. timer id %u", t);
   84994:	aa1403e0 	mov	x0, x20
   84998:	97fff308 	bl	815b8 <tfp_printf>
	ms_delay(100); 
   8499c:	52800c80 	mov	w0, #0x64                  	// #100
   849a0:	97fff546 	bl	81eb8 <ms_delay>
	int c = ktimer_cancel(t); 
   849a4:	2a1503e0 	mov	w0, w21
   849a8:	97fff5b8 	bl	82088 <ktimer_cancel>
	I("timer cancel return val = %d", c);
   849ac:	aa1303e1 	mov	x1, x19
	int c = ktimer_cancel(t); 
   849b0:	2a0003f4 	mov	w20, w0
	I("timer cancel return val = %d", c);
   849b4:	2a0003e3 	mov	w3, w0
   849b8:	52800542 	mov	w2, #0x2a                  	// #42
   849bc:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   849c0:	91198000 	add	x0, x0, #0x660
   849c4:	97fff2fd 	bl	815b8 <tfp_printf>
	BUG_ON(c < 0);
   849c8:	37f80174 	tbnz	w20, #31, 849f4 <test_ktimer+0x1e4>
	I("there shouldn't be more callback"); 
   849cc:	9110c2e1 	add	x1, x23, #0x430
   849d0:	528005a2 	mov	w2, #0x2d                  	// #45
   849d4:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   849d8:	911a8000 	add	x0, x0, #0x6a0
   849dc:	97fff2f7 	bl	815b8 <tfp_printf>
}
   849e0:	a94153f3 	ldp	x19, x20, [sp, #16]
   849e4:	a9425bf5 	ldp	x21, x22, [sp, #32]
   849e8:	f9401bf7 	ldr	x23, [sp, #48]
   849ec:	a8c67bfd 	ldp	x29, x30, [sp], #96
   849f0:	d65f03c0 	ret
	BUG_ON(c < 0);
   849f4:	aa1303e1 	mov	x1, x19
   849f8:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   849fc:	52800562 	mov	w2, #0x2b                  	// #43
   84a00:	911a4000 	add	x0, x0, #0x690
   84a04:	97fff3bd 	bl	818f8 <assertion_failed>
   84a08:	17fffff1 	b	849cc <test_ktimer+0x1bc>
   84a0c:	d503201f 	nop

0000000000084a10 <test_fb>:
void test_fb() {
   84a10:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   84a14:	910003fd 	mov	x29, sp
   84a18:	f9000bf3 	str	x19, [sp, #16]
    the_fb.width = N;
   84a1c:	b0000093 	adrp	x19, 95000 <wordsworth.1725+0xee10>
    fb_fini(); 
   84a20:	97fff6c0 	bl	82520 <fb_fini>
    the_fb.width = N;
   84a24:	f9478660 	ldr	x0, [x19, #3848]
   84a28:	b21803e2 	mov	x2, #0x10000000100         	// #1099511628032
    the_fb.vwidth = N*2; 
   84a2c:	b21703e1 	mov	x1, #0x20000000200         	// #2199023256064
   84a30:	a9008402 	stp	x2, x1, [x0, #8]
    if (fb_init() != 0) BUG();     
   84a34:	97fff7d9 	bl	82998 <fb_init>
   84a38:	35000960 	cbnz	w0, 84b64 <test_fb+0x154>
    int pitch = the_fb.pitch; 
   84a3c:	f9478661 	ldr	x1, [x19, #3848]
            setpixel(the_fb.fb,x,y,pitch,r); 
   84a40:	52802008 	mov	w8, #0x100                 	// #256
    *(PIXEL *)(buf + y*pit + x*PIXELSIZE) = p; 
   84a44:	52801fe6 	mov	w6, #0xff                  	// #255
            setpixel(the_fb.fb,x,y,pitch,r); 
   84a48:	f9400020 	ldr	x0, [x1]
    int pitch = the_fb.pitch; 
   84a4c:	b9401823 	ldr	w3, [x1, #24]
    for (y=0;y<N;y++)
   84a50:	91100004 	add	x4, x0, #0x400
            setpixel(the_fb.fb,x,y,pitch,r); 
   84a54:	aa0403e5 	mov	x5, x4
   84a58:	93407c67 	sxtw	x7, w3
        for (x=0;x<N;x++)
   84a5c:	d11000a2 	sub	x2, x5, #0x400
    *(PIXEL *)(buf + y*pit + x*PIXELSIZE) = p; 
   84a60:	b8004446 	str	w6, [x2], #4
        for (x=0;x<N;x++)
   84a64:	eb05005f 	cmp	x2, x5
   84a68:	54ffffc1 	b.ne	84a60 <test_fb+0x50>  // b.any
    for (y=0;y<N;y++)
   84a6c:	8b070045 	add	x5, x2, x7
   84a70:	71000508 	subs	w8, w8, #0x1
   84a74:	54ffff41 	b.ne	84a5c <test_fb+0x4c>  // b.any
   84a78:	91200001 	add	x1, x0, #0x800
   84a7c:	52802008 	mov	w8, #0x100                 	// #256
   84a80:	aa0103e5 	mov	x5, x1
    *(PIXEL *)(buf + y*pit + x*PIXELSIZE) = p; 
   84a84:	32009fe6 	mov	w6, #0xff00ff              	// #16711935
        for (x=N;x<2*N;x++)
   84a88:	d11000a2 	sub	x2, x5, #0x400
   84a8c:	d503201f 	nop
    *(PIXEL *)(buf + y*pit + x*PIXELSIZE) = p; 
   84a90:	b8004446 	str	w6, [x2], #4
        for (x=N;x<2*N;x++)
   84a94:	eb0200bf 	cmp	x5, x2
   84a98:	54ffffc1 	b.ne	84a90 <test_fb+0x80>  // b.any
    for (y=0;y<N;y++)
   84a9c:	8b0700a5 	add	x5, x5, x7
   84aa0:	71000508 	subs	w8, w8, #0x1
   84aa4:	54ffff21 	b.ne	84a88 <test_fb+0x78>  // b.any
   84aa8:	53185c63 	lsl	w3, w3, #8
   84aac:	52802006 	mov	w6, #0x100                 	// #256
    *(PIXEL *)(buf + y*pit + x*PIXELSIZE) = p; 
   84ab0:	529fe005 	mov	w5, #0xff00                	// #65280
   84ab4:	93407c63 	sxtw	x3, w3
   84ab8:	8b040064 	add	x4, x3, x4
        for (x=0;x<N;x++)
   84abc:	d1100082 	sub	x2, x4, #0x400
    *(PIXEL *)(buf + y*pit + x*PIXELSIZE) = p; 
   84ac0:	b8004445 	str	w5, [x2], #4
        for (x=0;x<N;x++)
   84ac4:	eb02009f 	cmp	x4, x2
   84ac8:	54ffffc1 	b.ne	84ac0 <test_fb+0xb0>  // b.any
    for (y=N;y<2*N;y++)
   84acc:	8b070084 	add	x4, x4, x7
   84ad0:	710004c6 	subs	w6, w6, #0x1
   84ad4:	54ffff41 	b.ne	84abc <test_fb+0xac>  // b.any
   84ad8:	8b010063 	add	x3, x3, x1
   84adc:	52802005 	mov	w5, #0x100                 	// #256
    *(PIXEL *)(buf + y*pit + x*PIXELSIZE) = p; 
   84ae0:	52a01fe4 	mov	w4, #0xff0000              	// #16711680
        for (x=N;x<2*N;x++)
   84ae4:	d1100062 	sub	x2, x3, #0x400
    *(PIXEL *)(buf + y*pit + x*PIXELSIZE) = p; 
   84ae8:	b8004444 	str	w4, [x2], #4
        for (x=N;x<2*N;x++)
   84aec:	eb02007f 	cmp	x3, x2
   84af0:	54ffffc1 	b.ne	84ae8 <test_fb+0xd8>  // b.any
    for (y=N;y<2*N;y++)
   84af4:	8b070063 	add	x3, x3, x7
   84af8:	710004a5 	subs	w5, w5, #0x1
   84afc:	54ffff41 	b.ne	84ae4 <test_fb+0xd4>  // b.any
    __asm_flush_dcache_range(the_fb.fb, the_fb.fb + the_fb.size); 
   84b00:	f9478673 	ldr	x19, [x19, #3848]
   84b04:	b9403661 	ldr	w1, [x19, #52]
   84b08:	8b010001 	add	x1, x0, x1
   84b0c:	94000520 	bl	85f8c <__asm_flush_dcache_range>
        fb_set_voffsets(0,0);
   84b10:	52800001 	mov	w1, #0x0                   	// #0
   84b14:	52800000 	mov	w0, #0x0                   	// #0
   84b18:	97fff648 	bl	82438 <fb_set_voffsets>
        ms_delay(1500); 
   84b1c:	5280bb80 	mov	w0, #0x5dc                 	// #1500
   84b20:	97fff4e6 	bl	81eb8 <ms_delay>
        fb_set_voffsets(0,N);
   84b24:	52802001 	mov	w1, #0x100                 	// #256
   84b28:	52800000 	mov	w0, #0x0                   	// #0
   84b2c:	97fff643 	bl	82438 <fb_set_voffsets>
        ms_delay(1500); 
   84b30:	5280bb80 	mov	w0, #0x5dc                 	// #1500
   84b34:	97fff4e1 	bl	81eb8 <ms_delay>
        fb_set_voffsets(N,0);
   84b38:	52800001 	mov	w1, #0x0                   	// #0
   84b3c:	52802000 	mov	w0, #0x100                 	// #256
   84b40:	97fff63e 	bl	82438 <fb_set_voffsets>
        ms_delay(1500); 
   84b44:	5280bb80 	mov	w0, #0x5dc                 	// #1500
   84b48:	97fff4dc 	bl	81eb8 <ms_delay>
        fb_set_voffsets(N,N);
   84b4c:	52802001 	mov	w1, #0x100                 	// #256
   84b50:	2a0103e0 	mov	w0, w1
   84b54:	97fff639 	bl	82438 <fb_set_voffsets>
        ms_delay(1500); 
   84b58:	5280bb80 	mov	w0, #0x5dc                 	// #1500
   84b5c:	97fff4d7 	bl	81eb8 <ms_delay>
    while (1) {
   84b60:	17ffffec 	b	84b10 <test_fb+0x100>
    if (fb_init() != 0) BUG();     
   84b64:	90000081 	adrp	x1, 94000 <wordsworth.1725+0xde10>
   84b68:	d0000000 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   84b6c:	9110c021 	add	x1, x1, #0x430
   84b70:	910d8000 	add	x0, x0, #0x360
   84b74:	52800b22 	mov	w2, #0x59                  	// #89
   84b78:	97fff360 	bl	818f8 <assertion_failed>
   84b7c:	17ffffb0 	b	84a3c <test_fb+0x2c>

0000000000084b80 <test_kern_tasks_print>:
void test_kern_tasks_print(void) {
   84b80:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
	int res = copy_process(PF_KTHREAD, (unsigned long)&kern_task_print, 
   84b84:	90000083 	adrp	x3, 94000 <wordsworth.1725+0xde10>
   84b88:	90000082 	adrp	x2, 94000 <wordsworth.1725+0xde10>
void test_kern_tasks_print(void) {
   84b8c:	910003fd 	mov	x29, sp
   84b90:	a90153f3 	stp	x19, x20, [sp, #16]
	int res = copy_process(PF_KTHREAD, (unsigned long)&kern_task_print, 
   84b94:	90000013 	adrp	x19, 84000 <exit_process+0x58>
   84b98:	91126273 	add	x19, x19, #0x498
   84b9c:	aa1303e1 	mov	x1, x19
   84ba0:	911b6063 	add	x3, x3, #0x6d8
   84ba4:	911b8042 	add	x2, x2, #0x6e0
   84ba8:	d2800040 	mov	x0, #0x2                   	// #2
   84bac:	90000094 	adrp	x20, 94000 <wordsworth.1725+0xde10>
void test_kern_tasks_print(void) {
   84bb0:	f90013f5 	str	x21, [sp, #32]
   84bb4:	90000095 	adrp	x21, 94000 <wordsworth.1725+0xde10>
	int res = copy_process(PF_KTHREAD, (unsigned long)&kern_task_print, 
   84bb8:	97fffdac 	bl	84268 <copy_process>
	BUG_ON(res<0); 
   84bbc:	37f80180 	tbnz	w0, #31, 84bec <test_kern_tasks_print+0x6c>
	res = copy_process(PF_KTHREAD, (unsigned long)&kern_task_print, 
   84bc0:	90000083 	adrp	x3, 94000 <wordsworth.1725+0xde10>
   84bc4:	90000082 	adrp	x2, 94000 <wordsworth.1725+0xde10>
   84bc8:	aa1303e1 	mov	x1, x19
   84bcc:	911c0063 	add	x3, x3, #0x700
   84bd0:	911c2042 	add	x2, x2, #0x708
   84bd4:	d2800040 	mov	x0, #0x2                   	// #2
   84bd8:	97fffda4 	bl	84268 <copy_process>
	BUG_ON(res<0);
   84bdc:	37f80120 	tbnz	w0, #31, 84c00 <test_kern_tasks_print+0x80>
        	yield();
   84be0:	97fffbf4 	bl	83bb0 <yield>
   84be4:	97fffbf3 	bl	83bb0 <yield>
	while (1)
   84be8:	17fffffe 	b	84be0 <test_kern_tasks_print+0x60>
	BUG_ON(res<0); 
   84bec:	9110c2a1 	add	x1, x21, #0x430
   84bf0:	911bc280 	add	x0, x20, #0x6f0
   84bf4:	528012e2 	mov	w2, #0x97                  	// #151
   84bf8:	97fff340 	bl	818f8 <assertion_failed>
   84bfc:	17fffff1 	b	84bc0 <test_kern_tasks_print+0x40>
	BUG_ON(res<0);
   84c00:	9110c2a1 	add	x1, x21, #0x430
   84c04:	911bc280 	add	x0, x20, #0x6f0
   84c08:	52801382 	mov	w2, #0x9c                  	// #156
   84c0c:	97fff33b 	bl	818f8 <assertion_failed>
        	yield();
   84c10:	97fffbe8 	bl	83bb0 <yield>
	while (1)
   84c14:	17fffff4 	b	84be4 <test_kern_tasks_print+0x64>

0000000000084c18 <test_kern_task_mgmt>:
void test_kern_task_mgmt(void) {
   84c18:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
	int res = copy_process(PF_KTHREAD, (unsigned long)&kern_task_return, 
   84c1c:	90000083 	adrp	x3, 94000 <wordsworth.1725+0xde10>
   84c20:	90000082 	adrp	x2, 94000 <wordsworth.1725+0xde10>
void test_kern_task_mgmt(void) {
   84c24:	910003fd 	mov	x29, sp
	int res = copy_process(PF_KTHREAD, (unsigned long)&kern_task_return, 
   84c28:	90000001 	adrp	x1, 84000 <exit_process+0x58>
   84c2c:	911b6063 	add	x3, x3, #0x6d8
   84c30:	911b8042 	add	x2, x2, #0x6e0
   84c34:	9113e021 	add	x1, x1, #0x4f8
   84c38:	d2800040 	mov	x0, #0x2                   	// #2
   84c3c:	97fffd8b 	bl	84268 <copy_process>
	BUG_ON(res<0); 
   84c40:	37f80180 	tbnz	w0, #31, 84c70 <test_kern_task_mgmt+0x58>
	res = copy_process(PF_KTHREAD, (unsigned long)&kern_task_exit, 
   84c44:	90000083 	adrp	x3, 94000 <wordsworth.1725+0xde10>
   84c48:	90000082 	adrp	x2, 94000 <wordsworth.1725+0xde10>
   84c4c:	90000001 	adrp	x1, 84000 <exit_process+0x58>
   84c50:	911c0063 	add	x3, x3, #0x700
   84c54:	911c2042 	add	x2, x2, #0x708
   84c58:	91152021 	add	x1, x1, #0x548
   84c5c:	d2800040 	mov	x0, #0x2                   	// #2
   84c60:	97fffd82 	bl	84268 <copy_process>
	BUG_ON(res<0);    
   84c64:	37f80140 	tbnz	w0, #31, 84c8c <test_kern_task_mgmt+0x74>
}
   84c68:	a8c17bfd 	ldp	x29, x30, [sp], #16
   84c6c:	d65f03c0 	ret
	BUG_ON(res<0); 
   84c70:	90000081 	adrp	x1, 94000 <wordsworth.1725+0xde10>
   84c74:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   84c78:	9110c021 	add	x1, x1, #0x430
   84c7c:	911bc000 	add	x0, x0, #0x6f0
   84c80:	528017e2 	mov	w2, #0xbf                  	// #191
   84c84:	97fff31d 	bl	818f8 <assertion_failed>
   84c88:	17ffffef 	b	84c44 <test_kern_task_mgmt+0x2c>
}
   84c8c:	a8c17bfd 	ldp	x29, x30, [sp], #16
	BUG_ON(res<0);    
   84c90:	90000081 	adrp	x1, 94000 <wordsworth.1725+0xde10>
   84c94:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   84c98:	9110c021 	add	x1, x1, #0x430
   84c9c:	911bc000 	add	x0, x0, #0x6f0
   84ca0:	52801882 	mov	w2, #0xc4                  	// #196
   84ca4:	17fff315 	b	818f8 <assertion_failed>

0000000000084ca8 <test_kern_reader_writer>:
void test_kern_reader_writer() {
   84ca8:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
	int res = copy_process(PF_KTHREAD, (unsigned long)&task_writer, 
   84cac:	90000083 	adrp	x3, 94000 <wordsworth.1725+0xde10>
   84cb0:	90000001 	adrp	x1, 84000 <exit_process+0x58>
void test_kern_reader_writer() {
   84cb4:	910003fd 	mov	x29, sp
	int res = copy_process(PF_KTHREAD, (unsigned long)&task_writer, 
   84cb8:	911c4063 	add	x3, x3, #0x710
   84cbc:	911c4021 	add	x1, x1, #0x710
   84cc0:	d2800002 	mov	x2, #0x0                   	// #0
   84cc4:	d2800040 	mov	x0, #0x2                   	// #2
   84cc8:	97fffd68 	bl	84268 <copy_process>
	BUG_ON(res<0); 
   84ccc:	37f80160 	tbnz	w0, #31, 84cf8 <test_kern_reader_writer+0x50>
	res = copy_process(PF_KTHREAD, (unsigned long)&task_reader, 
   84cd0:	90000083 	adrp	x3, 94000 <wordsworth.1725+0xde10>
   84cd4:	90000001 	adrp	x1, 84000 <exit_process+0x58>
   84cd8:	911c6063 	add	x3, x3, #0x718
   84cdc:	9117a021 	add	x1, x1, #0x5e8
   84ce0:	d2800002 	mov	x2, #0x0                   	// #0
   84ce4:	d2800040 	mov	x0, #0x2                   	// #2
   84ce8:	97fffd60 	bl	84268 <copy_process>
	BUG_ON(res<0);    
   84cec:	37f80220 	tbnz	w0, #31, 84d30 <test_kern_reader_writer+0x88>
}
   84cf0:	a8c17bfd 	ldp	x29, x30, [sp], #16
   84cf4:	d65f03c0 	ret
	BUG_ON(res<0); 
   84cf8:	528026e2 	mov	w2, #0x137                 	// #311
   84cfc:	90000081 	adrp	x1, 94000 <wordsworth.1725+0xde10>
   84d00:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   84d04:	9110c021 	add	x1, x1, #0x430
   84d08:	911bc000 	add	x0, x0, #0x6f0
   84d0c:	97fff2fb 	bl	818f8 <assertion_failed>
	res = copy_process(PF_KTHREAD, (unsigned long)&task_reader, 
   84d10:	90000083 	adrp	x3, 94000 <wordsworth.1725+0xde10>
   84d14:	90000001 	adrp	x1, 84000 <exit_process+0x58>
   84d18:	911c6063 	add	x3, x3, #0x718
   84d1c:	9117a021 	add	x1, x1, #0x5e8
   84d20:	d2800002 	mov	x2, #0x0                   	// #0
   84d24:	d2800040 	mov	x0, #0x2                   	// #2
   84d28:	97fffd50 	bl	84268 <copy_process>
	BUG_ON(res<0);    
   84d2c:	36fffe20 	tbz	w0, #31, 84cf0 <test_kern_reader_writer+0x48>
}
   84d30:	a8c17bfd 	ldp	x29, x30, [sp], #16
	BUG_ON(res<0);    
   84d34:	90000081 	adrp	x1, 94000 <wordsworth.1725+0xde10>
   84d38:	90000080 	adrp	x0, 94000 <wordsworth.1725+0xde10>
   84d3c:	9110c021 	add	x1, x1, #0x430
   84d40:	911bc000 	add	x0, x0, #0x6f0
   84d44:	52802742 	mov	w2, #0x13a                 	// #314
   84d48:	17fff2ec 	b	818f8 <assertion_failed>
   84d4c:	d503201f 	nop

0000000000084d50 <test_kern_tasks_donut>:

void test_kern_tasks_donut(void) {
   84d50:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
   84d54:	910003fd 	mov	x29, sp
   84d58:	a90153f3 	stp	x19, x20, [sp, #16]
   84d5c:	90000094 	adrp	x20, 94000 <wordsworth.1725+0xde10>
    char name[10]; 
    int res; 

    donut_canvas_init(); 
   84d60:	d2800013 	mov	x19, #0x0                   	// #0
    
    // spawn N donut tasks 
    for (int i=0; i<N_DONUTS; i++) {
        snprintf(name, 10, "donut-%d", i); 
   84d64:	911c8294 	add	x20, x20, #0x720
void test_kern_tasks_donut(void) {
   84d68:	a9025bf5 	stp	x21, x22, [sp, #32]
   84d6c:	90000015 	adrp	x21, 84000 <exit_process+0x58>
   84d70:	910103f6 	add	x22, sp, #0x40
   84d74:	911682b5 	add	x21, x21, #0x5a0
   84d78:	a90363f7 	stp	x23, x24, [sp, #48]
   84d7c:	90000098 	adrp	x24, 94000 <wordsworth.1725+0xde10>
   84d80:	90000097 	adrp	x23, 94000 <wordsworth.1725+0xde10>
        res = copy_process(PF_KTHREAD,
                           (unsigned long)&kern_task_donut,
                           (unsigned long)i,
                           name);

        BUG_ON(res < 0);
   84d84:	9110c318 	add	x24, x24, #0x430
   84d88:	911cc2f7 	add	x23, x23, #0x730
    donut_canvas_init(); 
   84d8c:	97fff7bf 	bl	82c88 <donut_canvas_init>
    for (int i=0; i<N_DONUTS; i++) {
   84d90:	14000003 	b	84d9c <test_kern_tasks_donut+0x4c>
   84d94:	f100667f 	cmp	x19, #0x19
   84d98:	54000260 	b.eq	84de4 <test_kern_tasks_donut+0x94>  // b.none
        snprintf(name, 10, "donut-%d", i); 
   84d9c:	2a1303e3 	mov	w3, w19
   84da0:	aa1403e2 	mov	x2, x20
   84da4:	d2800141 	mov	x1, #0xa                   	// #10
   84da8:	aa1603e0 	mov	x0, x22
   84dac:	97fff23f 	bl	816a8 <tfp_snprintf>
        res = copy_process(PF_KTHREAD,
   84db0:	aa1303e2 	mov	x2, x19
   84db4:	aa1603e3 	mov	x3, x22
   84db8:	aa1503e1 	mov	x1, x21
   84dbc:	91000673 	add	x19, x19, #0x1
   84dc0:	d2800040 	mov	x0, #0x2                   	// #2
   84dc4:	97fffd29 	bl	84268 <copy_process>
        BUG_ON(res < 0);
   84dc8:	36fffe60 	tbz	w0, #31, 84d94 <test_kern_tasks_donut+0x44>
   84dcc:	aa1803e1 	mov	x1, x24
   84dd0:	aa1703e0 	mov	x0, x23
   84dd4:	52802bc2 	mov	w2, #0x15e                 	// #350
   84dd8:	97fff2c8 	bl	818f8 <assertion_failed>
    for (int i=0; i<N_DONUTS; i++) {
   84ddc:	f100667f 	cmp	x19, #0x19
   84de0:	54fffde1 	b.ne	84d9c <test_kern_tasks_donut+0x4c>  // b.any
	// current we are on the "init" task. 
	// if we allow this function to return to kernel_main() which procceeds to wait(), 
	// and our sleep() (called by wait()) is yet to function, the kernel will crash there. so we just keep
	// the init task to keep yielding here forever. 	
	while (1)
        	yield();
   84de4:	97fffb73 	bl	83bb0 <yield>
   84de8:	97fffb72 	bl	83bb0 <yield>
	while (1)
   84dec:	17fffffe 	b	84de4 <test_kern_tasks_donut+0x94>

0000000000084df0 <uart_send>:
#define AUX_MU_BAUD_REG (PBASE+0x00215068)

// busy wait
void uart_send (char c) {
	while(1) {
		if(get32(AUX_MU_LSR_REG) & 0x20) 
   84df0:	d28a0a82 	mov	x2, #0x5054                	// #20564
void uart_send (char c) {
   84df4:	12001c00 	and	w0, w0, #0xff
		if(get32(AUX_MU_LSR_REG) & 0x20) 
   84df8:	f2a7e422 	movk	x2, #0x3f21, lsl #16
   84dfc:	d503201f 	nop
   84e00:	b9400041 	ldr	w1, [x2]
   84e04:	362fffe1 	tbz	w1, #5, 84e00 <uart_send+0x10>
			break;
	}
	put32(AUX_MU_IO_REG, c);
   84e08:	d28a0801 	mov	x1, #0x5040                	// #20544
   84e0c:	f2a7e421 	movk	x1, #0x3f21, lsl #16
   84e10:	b9000020 	str	w0, [x1]
}
   84e14:	d65f03c0 	ret

0000000000084e18 <uart_recv>:
 
// busy wait
char uart_recv (void) {
	while(1) {
		if(get32(AUX_MU_LSR_REG) & 0x01) 
   84e18:	d28a0a81 	mov	x1, #0x5054                	// #20564
   84e1c:	f2a7e421 	movk	x1, #0x3f21, lsl #16
   84e20:	b9400020 	ldr	w0, [x1]
   84e24:	3607ffe0 	tbz	w0, #0, 84e20 <uart_recv+0x8>
			break;
	}
	return(get32(AUX_MU_IO_REG) & 0xFF);
   84e28:	d28a0800 	mov	x0, #0x5040                	// #20544
   84e2c:	f2a7e420 	movk	x0, #0x3f21, lsl #16
   84e30:	b9400000 	ldr	w0, [x0]
}
   84e34:	d65f03c0 	ret

0000000000084e38 <uart_send_string>:

void uart_send_string(char* str) {
	for (int i = 0; str[i] != '\0'; i ++) {
   84e38:	39400002 	ldrb	w2, [x0]
   84e3c:	34000182 	cbz	w2, 84e6c <uart_send_string+0x34>
		if(get32(AUX_MU_LSR_REG) & 0x20) 
   84e40:	d28a0a81 	mov	x1, #0x5054                	// #20564
	put32(AUX_MU_IO_REG, c);
   84e44:	d28a0804 	mov	x4, #0x5040                	// #20544
   84e48:	91000403 	add	x3, x0, #0x1
		if(get32(AUX_MU_LSR_REG) & 0x20) 
   84e4c:	f2a7e421 	movk	x1, #0x3f21, lsl #16
	put32(AUX_MU_IO_REG, c);
   84e50:	f2a7e424 	movk	x4, #0x3f21, lsl #16
   84e54:	d503201f 	nop
		if(get32(AUX_MU_LSR_REG) & 0x20) 
   84e58:	b9400020 	ldr	w0, [x1]
   84e5c:	362fffe0 	tbz	w0, #5, 84e58 <uart_send_string+0x20>
	put32(AUX_MU_IO_REG, c);
   84e60:	b9000082 	str	w2, [x4]
	for (int i = 0; str[i] != '\0'; i ++) {
   84e64:	38401462 	ldrb	w2, [x3], #1
   84e68:	35ffff82 	cbnz	w2, 84e58 <uart_send_string+0x20>
		uart_send((char)str[i]);
	}
}
   84e6c:	d65f03c0 	ret

0000000000084e70 <putc>:
		if(get32(AUX_MU_LSR_REG) & 0x20) 
   84e70:	d28a0a82 	mov	x2, #0x5054                	// #20564

// This function is required by printf function
void putc ( void* p, char c) {
   84e74:	12001c21 	and	w1, w1, #0xff
		if(get32(AUX_MU_LSR_REG) & 0x20) 
   84e78:	f2a7e422 	movk	x2, #0x3f21, lsl #16
   84e7c:	d503201f 	nop
   84e80:	b9400040 	ldr	w0, [x2]
   84e84:	362fffe0 	tbz	w0, #5, 84e80 <putc+0x10>
	put32(AUX_MU_IO_REG, c);
   84e88:	d28a0800 	mov	x0, #0x5040                	// #20544
   84e8c:	f2a7e420 	movk	x0, #0x3f21, lsl #16
   84e90:	b9000001 	str	w1, [x0]
	uart_send(c);
}
   84e94:	d65f03c0 	ret

0000000000084e98 <uart_init>:

    // code below also showcases how to configure GPIO pins
    // cf: https://github.com/bztsrc/raspi3-tutorial/blob/master/03_uart1/uart.c#L45

    // select gpio functions for pin14,15. note 3bits per pin.
    selector = get32(GPFSEL1);
   84e98:	d2800082 	mov	x2, #0x4                   	// #4
void uart_init(void) {
   84e9c:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
    selector = get32(GPFSEL1);
   84ea0:	f2a7e402 	movk	x2, #0x3f20, lsl #16
void uart_init(void) {
   84ea4:	910003fd 	mov	x29, sp
    selector = get32(GPFSEL1);
   84ea8:	b9400041 	ldr	w1, [x2]

    // Below: set up GPIO pull modes. protocol recommended by the bcm2837 manual
    //    (pg 101, "GPIO Pull-up/down Clock Registers")
    // We need neither the pull-up nor the pull-down state, because both
    //  the 14 and 15 pins are going to be connected all the time.
    put32(GPPUD, 0); // disable pull up/down control (for pins below)
   84eac:	d2801283 	mov	x3, #0x94                  	// #148
   84eb0:	f2a7e403 	movk	x3, #0x3f20, lsl #16
    selector |= 2 << 15;    // set alt5 for gpio15
   84eb4:	52840004 	mov	w4, #0x2000                	// #8192
   84eb8:	120e6421 	and	w1, w1, #0xfffc0fff
void uart_init(void) {
   84ebc:	f9000bf3 	str	x19, [sp, #16]
    selector |= 2 << 15;    // set alt5 for gpio15
   84ec0:	72a00024 	movk	w4, #0x1, lsl #16
   84ec4:	2a040021 	orr	w1, w1, w4
    put32(GPFSEL1, selector);
   84ec8:	b9000041 	str	w1, [x2]
    delay(150);
    // "control the actuation of internal pull-downs on the respective GPIO pins."
    put32(GPPUDCLK0, (1 << 14) | (1 << 15)); // "clock the control signal into the GPIO pads"
   84ecc:	d2801313 	mov	x19, #0x98                  	// #152
    put32(GPPUD, 0); // disable pull up/down control (for pins below)
   84ed0:	b900007f 	str	wzr, [x3]
    put32(GPPUDCLK0, (1 << 14) | (1 << 15)); // "clock the control signal into the GPIO pads"
   84ed4:	f2a7e413 	movk	x19, #0x3f20, lsl #16
    delay(150);
   84ed8:	d28012c0 	mov	x0, #0x96                  	// #150
   84edc:	94000429 	bl	85f80 <delay>
    put32(GPPUDCLK0, (1 << 14) | (1 << 15)); // "clock the control signal into the GPIO pads"
   84ee0:	52980000 	mov	w0, #0xc000                	// #49152
   84ee4:	b9000260 	str	w0, [x19]
    delay(150);
   84ee8:	d28012c0 	mov	x0, #0x96                  	// #150
   84eec:	94000425 	bl	85f80 <delay>
    put32(GPPUDCLK0, 0);               // remote the clock, flush GPIO setup
   84ef0:	b900027f 	str	wzr, [x19]
    put32(AUX_MU_IIR_REG, FLUSH_UART); // flush FIFO
   84ef4:	d28a0901 	mov	x1, #0x5048                	// #20552

    put32(AUX_ENABLES, 1);     // Enable mini uart (this also enables access to it registers)
   84ef8:	d28a0082 	mov	x2, #0x5004                	// #20484
    put32(AUX_MU_IIR_REG, FLUSH_UART); // flush FIFO
   84efc:	f2a7e421 	movk	x1, #0x3f21, lsl #16
    put32(AUX_ENABLES, 1);     // Enable mini uart (this also enables access to it registers)
   84f00:	f2a7e422 	movk	x2, #0x3f21, lsl #16
    put32(AUX_MU_CNTL_REG, 0); // Disable auto flow control and disable receiver and transmitter (for now)
   84f04:	d28a0c00 	mov	x0, #0x5060                	// #20576
    put32(AUX_MU_IIR_REG, FLUSH_UART); // flush FIFO
   84f08:	528018c3 	mov	w3, #0xc6                  	// #198
    put32(AUX_MU_CNTL_REG, 0); // Disable auto flow control and disable receiver and transmitter (for now)
   84f0c:	f2a7e420 	movk	x0, #0x3f21, lsl #16

    put32(AUX_MU_IER_REG, 0);                     // Disable receive and transmit interrupts
    put32(AUX_MU_IER_REG, (3 << 2) | (0xf << 4)); // bit 7:4 3:2 must be 1

    put32(AUX_MU_LCR_REG, 3);    // Enable 8 bit mode
    put32(AUX_MU_MCR_REG, 0);    // Set RTS line to be always high
   84f10:	d28a0a04 	mov	x4, #0x5050                	// #20560
    put32(AUX_MU_BAUD_REG, 270); // Set baud rate to 115200

    put32(AUX_MU_CNTL_REG, 3); // Finally, enable transmitter and receiver
}
   84f14:	f9400bf3 	ldr	x19, [sp, #16]
    put32(AUX_MU_IIR_REG, FLUSH_UART); // flush FIFO
   84f18:	b9000023 	str	w3, [x1]
    put32(AUX_MU_IER_REG, 0);                     // Disable receive and transmit interrupts
   84f1c:	d28a0881 	mov	x1, #0x5044                	// #20548
    put32(AUX_ENABLES, 1);     // Enable mini uart (this also enables access to it registers)
   84f20:	52800023 	mov	w3, #0x1                   	// #1
    put32(AUX_MU_IER_REG, 0);                     // Disable receive and transmit interrupts
   84f24:	f2a7e421 	movk	x1, #0x3f21, lsl #16
    put32(AUX_ENABLES, 1);     // Enable mini uart (this also enables access to it registers)
   84f28:	b9000043 	str	w3, [x2]
    put32(AUX_MU_LCR_REG, 3);    // Enable 8 bit mode
   84f2c:	d28a0983 	mov	x3, #0x504c                	// #20556
    put32(AUX_MU_CNTL_REG, 0); // Disable auto flow control and disable receiver and transmitter (for now)
   84f30:	b900001f 	str	wzr, [x0]
    put32(AUX_MU_LCR_REG, 3);    // Enable 8 bit mode
   84f34:	f2a7e423 	movk	x3, #0x3f21, lsl #16
    put32(AUX_MU_IER_REG, (3 << 2) | (0xf << 4)); // bit 7:4 3:2 must be 1
   84f38:	52801f82 	mov	w2, #0xfc                  	// #252
    put32(AUX_MU_IER_REG, 0);                     // Disable receive and transmit interrupts
   84f3c:	b900003f 	str	wzr, [x1]
    put32(AUX_MU_MCR_REG, 0);    // Set RTS line to be always high
   84f40:	f2a7e424 	movk	x4, #0x3f21, lsl #16
    put32(AUX_MU_IER_REG, (3 << 2) | (0xf << 4)); // bit 7:4 3:2 must be 1
   84f44:	b9000022 	str	w2, [x1]
    put32(AUX_MU_BAUD_REG, 270); // Set baud rate to 115200
   84f48:	d28a0d02 	mov	x2, #0x5068                	// #20584
    put32(AUX_MU_LCR_REG, 3);    // Enable 8 bit mode
   84f4c:	52800061 	mov	w1, #0x3                   	// #3
    put32(AUX_MU_BAUD_REG, 270); // Set baud rate to 115200
   84f50:	f2a7e422 	movk	x2, #0x3f21, lsl #16
    put32(AUX_MU_LCR_REG, 3);    // Enable 8 bit mode
   84f54:	b9000061 	str	w1, [x3]
    put32(AUX_MU_BAUD_REG, 270); // Set baud rate to 115200
   84f58:	528021c3 	mov	w3, #0x10e                 	// #270
    put32(AUX_MU_MCR_REG, 0);    // Set RTS line to be always high
   84f5c:	b900009f 	str	wzr, [x4]
    put32(AUX_MU_BAUD_REG, 270); // Set baud rate to 115200
   84f60:	b9000043 	str	w3, [x2]
    put32(AUX_MU_CNTL_REG, 3); // Finally, enable transmitter and receiver
   84f64:	b9000001 	str	w1, [x0]
}
   84f68:	a8c27bfd 	ldp	x29, x30, [sp], #32
   84f6c:	d65f03c0 	ret
	...

0000000000085000 <vectors>:
.align	11
.globl vectors 
// Q3: quest: "two preemptive printers"
vectors:
	//  EL1t -- Exception happens when CPU is at EL1 while the stack pointer (SP) was set to be shared with EL0
	ventry	sync_invalid_el1t			// Synchronous EL1t
   85000:	1400020b 	b	8582c <sync_invalid_el1t>
   85004:	d503201f 	nop
   85008:	d503201f 	nop
   8500c:	d503201f 	nop
   85010:	d503201f 	nop
   85014:	d503201f 	nop
   85018:	d503201f 	nop
   8501c:	d503201f 	nop
   85020:	d503201f 	nop
   85024:	d503201f 	nop
   85028:	d503201f 	nop
   8502c:	d503201f 	nop
   85030:	d503201f 	nop
   85034:	d503201f 	nop
   85038:	d503201f 	nop
   8503c:	d503201f 	nop
   85040:	d503201f 	nop
   85044:	d503201f 	nop
   85048:	d503201f 	nop
   8504c:	d503201f 	nop
   85050:	d503201f 	nop
   85054:	d503201f 	nop
   85058:	d503201f 	nop
   8505c:	d503201f 	nop
   85060:	d503201f 	nop
   85064:	d503201f 	nop
   85068:	d503201f 	nop
   8506c:	d503201f 	nop
   85070:	d503201f 	nop
   85074:	d503201f 	nop
   85078:	d503201f 	nop
   8507c:	d503201f 	nop
	ventry	irq_invalid_el1t			// IRQ EL1t
   85080:	14000206 	b	85898 <irq_invalid_el1t>
   85084:	d503201f 	nop
   85088:	d503201f 	nop
   8508c:	d503201f 	nop
   85090:	d503201f 	nop
   85094:	d503201f 	nop
   85098:	d503201f 	nop
   8509c:	d503201f 	nop
   850a0:	d503201f 	nop
   850a4:	d503201f 	nop
   850a8:	d503201f 	nop
   850ac:	d503201f 	nop
   850b0:	d503201f 	nop
   850b4:	d503201f 	nop
   850b8:	d503201f 	nop
   850bc:	d503201f 	nop
   850c0:	d503201f 	nop
   850c4:	d503201f 	nop
   850c8:	d503201f 	nop
   850cc:	d503201f 	nop
   850d0:	d503201f 	nop
   850d4:	d503201f 	nop
   850d8:	d503201f 	nop
   850dc:	d503201f 	nop
   850e0:	d503201f 	nop
   850e4:	d503201f 	nop
   850e8:	d503201f 	nop
   850ec:	d503201f 	nop
   850f0:	d503201f 	nop
   850f4:	d503201f 	nop
   850f8:	d503201f 	nop
   850fc:	d503201f 	nop
	ventry	fiq_invalid_el1t			// FIQ EL1t
   85100:	14000201 	b	85904 <fiq_invalid_el1t>
   85104:	d503201f 	nop
   85108:	d503201f 	nop
   8510c:	d503201f 	nop
   85110:	d503201f 	nop
   85114:	d503201f 	nop
   85118:	d503201f 	nop
   8511c:	d503201f 	nop
   85120:	d503201f 	nop
   85124:	d503201f 	nop
   85128:	d503201f 	nop
   8512c:	d503201f 	nop
   85130:	d503201f 	nop
   85134:	d503201f 	nop
   85138:	d503201f 	nop
   8513c:	d503201f 	nop
   85140:	d503201f 	nop
   85144:	d503201f 	nop
   85148:	d503201f 	nop
   8514c:	d503201f 	nop
   85150:	d503201f 	nop
   85154:	d503201f 	nop
   85158:	d503201f 	nop
   8515c:	d503201f 	nop
   85160:	d503201f 	nop
   85164:	d503201f 	nop
   85168:	d503201f 	nop
   8516c:	d503201f 	nop
   85170:	d503201f 	nop
   85174:	d503201f 	nop
   85178:	d503201f 	nop
   8517c:	d503201f 	nop
	ventry	error_invalid_el1t			// Error EL1t
   85180:	140001fc 	b	85970 <error_invalid_el1t>
   85184:	d503201f 	nop
   85188:	d503201f 	nop
   8518c:	d503201f 	nop
   85190:	d503201f 	nop
   85194:	d503201f 	nop
   85198:	d503201f 	nop
   8519c:	d503201f 	nop
   851a0:	d503201f 	nop
   851a4:	d503201f 	nop
   851a8:	d503201f 	nop
   851ac:	d503201f 	nop
   851b0:	d503201f 	nop
   851b4:	d503201f 	nop
   851b8:	d503201f 	nop
   851bc:	d503201f 	nop
   851c0:	d503201f 	nop
   851c4:	d503201f 	nop
   851c8:	d503201f 	nop
   851cc:	d503201f 	nop
   851d0:	d503201f 	nop
   851d4:	d503201f 	nop
   851d8:	d503201f 	nop
   851dc:	d503201f 	nop
   851e0:	d503201f 	nop
   851e4:	d503201f 	nop
   851e8:	d503201f 	nop
   851ec:	d503201f 	nop
   851f0:	d503201f 	nop
   851f4:	d503201f 	nop
   851f8:	d503201f 	nop
   851fc:	d503201f 	nop

	// EL1h -- Exception happens at EL1 at the time when a dedicated SP was allocated for EL1.
	//  		This is the mode that our kernel is currently using
	ventry	sync_invalid_el1h			// Synchronous EL1h
   85200:	140001f7 	b	859dc <sync_invalid_el1h>
   85204:	d503201f 	nop
   85208:	d503201f 	nop
   8520c:	d503201f 	nop
   85210:	d503201f 	nop
   85214:	d503201f 	nop
   85218:	d503201f 	nop
   8521c:	d503201f 	nop
   85220:	d503201f 	nop
   85224:	d503201f 	nop
   85228:	d503201f 	nop
   8522c:	d503201f 	nop
   85230:	d503201f 	nop
   85234:	d503201f 	nop
   85238:	d503201f 	nop
   8523c:	d503201f 	nop
   85240:	d503201f 	nop
   85244:	d503201f 	nop
   85248:	d503201f 	nop
   8524c:	d503201f 	nop
   85250:	d503201f 	nop
   85254:	d503201f 	nop
   85258:	d503201f 	nop
   8525c:	d503201f 	nop
   85260:	d503201f 	nop
   85264:	d503201f 	nop
   85268:	d503201f 	nop
   8526c:	d503201f 	nop
   85270:	d503201f 	nop
   85274:	d503201f 	nop
   85278:	d503201f 	nop
   8527c:	d503201f 	nop
	// IRQ EL1h  
	ventry el1_irq  /* STUDENT: TODO: replace this */
   85280:	14000141 	b	85784 <el1_irq>
   85284:	d503201f 	nop
   85288:	d503201f 	nop
   8528c:	d503201f 	nop
   85290:	d503201f 	nop
   85294:	d503201f 	nop
   85298:	d503201f 	nop
   8529c:	d503201f 	nop
   852a0:	d503201f 	nop
   852a4:	d503201f 	nop
   852a8:	d503201f 	nop
   852ac:	d503201f 	nop
   852b0:	d503201f 	nop
   852b4:	d503201f 	nop
   852b8:	d503201f 	nop
   852bc:	d503201f 	nop
   852c0:	d503201f 	nop
   852c4:	d503201f 	nop
   852c8:	d503201f 	nop
   852cc:	d503201f 	nop
   852d0:	d503201f 	nop
   852d4:	d503201f 	nop
   852d8:	d503201f 	nop
   852dc:	d503201f 	nop
   852e0:	d503201f 	nop
   852e4:	d503201f 	nop
   852e8:	d503201f 	nop
   852ec:	d503201f 	nop
   852f0:	d503201f 	nop
   852f4:	d503201f 	nop
   852f8:	d503201f 	nop
   852fc:	d503201f 	nop
	ventry	fiq_invalid_el1h			// FIQ EL1h
   85300:	140001d2 	b	85a48 <fiq_invalid_el1h>
   85304:	d503201f 	nop
   85308:	d503201f 	nop
   8530c:	d503201f 	nop
   85310:	d503201f 	nop
   85314:	d503201f 	nop
   85318:	d503201f 	nop
   8531c:	d503201f 	nop
   85320:	d503201f 	nop
   85324:	d503201f 	nop
   85328:	d503201f 	nop
   8532c:	d503201f 	nop
   85330:	d503201f 	nop
   85334:	d503201f 	nop
   85338:	d503201f 	nop
   8533c:	d503201f 	nop
   85340:	d503201f 	nop
   85344:	d503201f 	nop
   85348:	d503201f 	nop
   8534c:	d503201f 	nop
   85350:	d503201f 	nop
   85354:	d503201f 	nop
   85358:	d503201f 	nop
   8535c:	d503201f 	nop
   85360:	d503201f 	nop
   85364:	d503201f 	nop
   85368:	d503201f 	nop
   8536c:	d503201f 	nop
   85370:	d503201f 	nop
   85374:	d503201f 	nop
   85378:	d503201f 	nop
   8537c:	d503201f 	nop
	ventry	error_invalid_el1h			// Error EL1h
   85380:	140001cd 	b	85ab4 <error_invalid_el1h>
   85384:	d503201f 	nop
   85388:	d503201f 	nop
   8538c:	d503201f 	nop
   85390:	d503201f 	nop
   85394:	d503201f 	nop
   85398:	d503201f 	nop
   8539c:	d503201f 	nop
   853a0:	d503201f 	nop
   853a4:	d503201f 	nop
   853a8:	d503201f 	nop
   853ac:	d503201f 	nop
   853b0:	d503201f 	nop
   853b4:	d503201f 	nop
   853b8:	d503201f 	nop
   853bc:	d503201f 	nop
   853c0:	d503201f 	nop
   853c4:	d503201f 	nop
   853c8:	d503201f 	nop
   853cc:	d503201f 	nop
   853d0:	d503201f 	nop
   853d4:	d503201f 	nop
   853d8:	d503201f 	nop
   853dc:	d503201f 	nop
   853e0:	d503201f 	nop
   853e4:	d503201f 	nop
   853e8:	d503201f 	nop
   853ec:	d503201f 	nop
   853f0:	d503201f 	nop
   853f4:	d503201f 	nop
   853f8:	d503201f 	nop
   853fc:	d503201f 	nop

	// EL0_64 -- Exception is taken from EL0 executing in 64-bit mode. 
	//		The exceptions caused in 64-bit user programs
	ventry	sync_invalid_el0_64			// Synchronous 64-bit EL0
   85400:	140001c8 	b	85b20 <sync_invalid_el0_64>
   85404:	d503201f 	nop
   85408:	d503201f 	nop
   8540c:	d503201f 	nop
   85410:	d503201f 	nop
   85414:	d503201f 	nop
   85418:	d503201f 	nop
   8541c:	d503201f 	nop
   85420:	d503201f 	nop
   85424:	d503201f 	nop
   85428:	d503201f 	nop
   8542c:	d503201f 	nop
   85430:	d503201f 	nop
   85434:	d503201f 	nop
   85438:	d503201f 	nop
   8543c:	d503201f 	nop
   85440:	d503201f 	nop
   85444:	d503201f 	nop
   85448:	d503201f 	nop
   8544c:	d503201f 	nop
   85450:	d503201f 	nop
   85454:	d503201f 	nop
   85458:	d503201f 	nop
   8545c:	d503201f 	nop
   85460:	d503201f 	nop
   85464:	d503201f 	nop
   85468:	d503201f 	nop
   8546c:	d503201f 	nop
   85470:	d503201f 	nop
   85474:	d503201f 	nop
   85478:	d503201f 	nop
   8547c:	d503201f 	nop
	ventry	irq_invalid_el0_64			// IRQ 64-bit EL0
   85480:	140001c3 	b	85b8c <irq_invalid_el0_64>
   85484:	d503201f 	nop
   85488:	d503201f 	nop
   8548c:	d503201f 	nop
   85490:	d503201f 	nop
   85494:	d503201f 	nop
   85498:	d503201f 	nop
   8549c:	d503201f 	nop
   854a0:	d503201f 	nop
   854a4:	d503201f 	nop
   854a8:	d503201f 	nop
   854ac:	d503201f 	nop
   854b0:	d503201f 	nop
   854b4:	d503201f 	nop
   854b8:	d503201f 	nop
   854bc:	d503201f 	nop
   854c0:	d503201f 	nop
   854c4:	d503201f 	nop
   854c8:	d503201f 	nop
   854cc:	d503201f 	nop
   854d0:	d503201f 	nop
   854d4:	d503201f 	nop
   854d8:	d503201f 	nop
   854dc:	d503201f 	nop
   854e0:	d503201f 	nop
   854e4:	d503201f 	nop
   854e8:	d503201f 	nop
   854ec:	d503201f 	nop
   854f0:	d503201f 	nop
   854f4:	d503201f 	nop
   854f8:	d503201f 	nop
   854fc:	d503201f 	nop
	ventry	fiq_invalid_el0_64			// FIQ 64-bit EL0
   85500:	140001be 	b	85bf8 <fiq_invalid_el0_64>
   85504:	d503201f 	nop
   85508:	d503201f 	nop
   8550c:	d503201f 	nop
   85510:	d503201f 	nop
   85514:	d503201f 	nop
   85518:	d503201f 	nop
   8551c:	d503201f 	nop
   85520:	d503201f 	nop
   85524:	d503201f 	nop
   85528:	d503201f 	nop
   8552c:	d503201f 	nop
   85530:	d503201f 	nop
   85534:	d503201f 	nop
   85538:	d503201f 	nop
   8553c:	d503201f 	nop
   85540:	d503201f 	nop
   85544:	d503201f 	nop
   85548:	d503201f 	nop
   8554c:	d503201f 	nop
   85550:	d503201f 	nop
   85554:	d503201f 	nop
   85558:	d503201f 	nop
   8555c:	d503201f 	nop
   85560:	d503201f 	nop
   85564:	d503201f 	nop
   85568:	d503201f 	nop
   8556c:	d503201f 	nop
   85570:	d503201f 	nop
   85574:	d503201f 	nop
   85578:	d503201f 	nop
   8557c:	d503201f 	nop
	ventry	error_invalid_el0_64			// Error 64-bit EL0
   85580:	140001b9 	b	85c64 <error_invalid_el0_64>
   85584:	d503201f 	nop
   85588:	d503201f 	nop
   8558c:	d503201f 	nop
   85590:	d503201f 	nop
   85594:	d503201f 	nop
   85598:	d503201f 	nop
   8559c:	d503201f 	nop
   855a0:	d503201f 	nop
   855a4:	d503201f 	nop
   855a8:	d503201f 	nop
   855ac:	d503201f 	nop
   855b0:	d503201f 	nop
   855b4:	d503201f 	nop
   855b8:	d503201f 	nop
   855bc:	d503201f 	nop
   855c0:	d503201f 	nop
   855c4:	d503201f 	nop
   855c8:	d503201f 	nop
   855cc:	d503201f 	nop
   855d0:	d503201f 	nop
   855d4:	d503201f 	nop
   855d8:	d503201f 	nop
   855dc:	d503201f 	nop
   855e0:	d503201f 	nop
   855e4:	d503201f 	nop
   855e8:	d503201f 	nop
   855ec:	d503201f 	nop
   855f0:	d503201f 	nop
   855f4:	d503201f 	nop
   855f8:	d503201f 	nop
   855fc:	d503201f 	nop

	// EL0_32 -- Exception is taken from EL0 executing in 32-bit mode
	//		The exceptions caused in 32-bit user programs
	ventry	sync_invalid_el0_32			// Synchronous 32-bit EL0
   85600:	140001b4 	b	85cd0 <sync_invalid_el0_32>
   85604:	d503201f 	nop
   85608:	d503201f 	nop
   8560c:	d503201f 	nop
   85610:	d503201f 	nop
   85614:	d503201f 	nop
   85618:	d503201f 	nop
   8561c:	d503201f 	nop
   85620:	d503201f 	nop
   85624:	d503201f 	nop
   85628:	d503201f 	nop
   8562c:	d503201f 	nop
   85630:	d503201f 	nop
   85634:	d503201f 	nop
   85638:	d503201f 	nop
   8563c:	d503201f 	nop
   85640:	d503201f 	nop
   85644:	d503201f 	nop
   85648:	d503201f 	nop
   8564c:	d503201f 	nop
   85650:	d503201f 	nop
   85654:	d503201f 	nop
   85658:	d503201f 	nop
   8565c:	d503201f 	nop
   85660:	d503201f 	nop
   85664:	d503201f 	nop
   85668:	d503201f 	nop
   8566c:	d503201f 	nop
   85670:	d503201f 	nop
   85674:	d503201f 	nop
   85678:	d503201f 	nop
   8567c:	d503201f 	nop
	ventry	irq_invalid_el0_32			// IRQ 32-bit EL0
   85680:	140001af 	b	85d3c <irq_invalid_el0_32>
   85684:	d503201f 	nop
   85688:	d503201f 	nop
   8568c:	d503201f 	nop
   85690:	d503201f 	nop
   85694:	d503201f 	nop
   85698:	d503201f 	nop
   8569c:	d503201f 	nop
   856a0:	d503201f 	nop
   856a4:	d503201f 	nop
   856a8:	d503201f 	nop
   856ac:	d503201f 	nop
   856b0:	d503201f 	nop
   856b4:	d503201f 	nop
   856b8:	d503201f 	nop
   856bc:	d503201f 	nop
   856c0:	d503201f 	nop
   856c4:	d503201f 	nop
   856c8:	d503201f 	nop
   856cc:	d503201f 	nop
   856d0:	d503201f 	nop
   856d4:	d503201f 	nop
   856d8:	d503201f 	nop
   856dc:	d503201f 	nop
   856e0:	d503201f 	nop
   856e4:	d503201f 	nop
   856e8:	d503201f 	nop
   856ec:	d503201f 	nop
   856f0:	d503201f 	nop
   856f4:	d503201f 	nop
   856f8:	d503201f 	nop
   856fc:	d503201f 	nop
	ventry	fiq_invalid_el0_32			// FIQ 32-bit EL0
   85700:	140001aa 	b	85da8 <fiq_invalid_el0_32>
   85704:	d503201f 	nop
   85708:	d503201f 	nop
   8570c:	d503201f 	nop
   85710:	d503201f 	nop
   85714:	d503201f 	nop
   85718:	d503201f 	nop
   8571c:	d503201f 	nop
   85720:	d503201f 	nop
   85724:	d503201f 	nop
   85728:	d503201f 	nop
   8572c:	d503201f 	nop
   85730:	d503201f 	nop
   85734:	d503201f 	nop
   85738:	d503201f 	nop
   8573c:	d503201f 	nop
   85740:	d503201f 	nop
   85744:	d503201f 	nop
   85748:	d503201f 	nop
   8574c:	d503201f 	nop
   85750:	d503201f 	nop
   85754:	d503201f 	nop
   85758:	d503201f 	nop
   8575c:	d503201f 	nop
   85760:	d503201f 	nop
   85764:	d503201f 	nop
   85768:	d503201f 	nop
   8576c:	d503201f 	nop
   85770:	d503201f 	nop
   85774:	d503201f 	nop
   85778:	d503201f 	nop
   8577c:	d503201f 	nop
	ventry	error_invalid_el0_32			// Error 32-bit EL0
   85780:	140001a5 	b	85e14 <error_invalid_el0_32>

0000000000085784 <el1_irq>:

/* ---------------------------- end of EL1 vectors ---------------------------- */

el1_irq:
	kernel_entry 
   85784:	d10443ff 	sub	sp, sp, #0x110
   85788:	a90007e0 	stp	x0, x1, [sp]
   8578c:	a9010fe2 	stp	x2, x3, [sp, #16]
   85790:	a90217e4 	stp	x4, x5, [sp, #32]
   85794:	a9031fe6 	stp	x6, x7, [sp, #48]
   85798:	a90427e8 	stp	x8, x9, [sp, #64]
   8579c:	a9052fea 	stp	x10, x11, [sp, #80]
   857a0:	a90637ec 	stp	x12, x13, [sp, #96]
   857a4:	a9073fee 	stp	x14, x15, [sp, #112]
   857a8:	a90847f0 	stp	x16, x17, [sp, #128]
   857ac:	a9094ff2 	stp	x18, x19, [sp, #144]
   857b0:	a90a57f4 	stp	x20, x21, [sp, #160]
   857b4:	a90b5ff6 	stp	x22, x23, [sp, #176]
   857b8:	a90c67f8 	stp	x24, x25, [sp, #192]
   857bc:	a90d6ffa 	stp	x26, x27, [sp, #208]
   857c0:	a90e77fc 	stp	x28, x29, [sp, #224]
   857c4:	d5384036 	mrs	x22, elr_el1
   857c8:	d5384017 	mrs	x23, spsr_el1
   857cc:	a90f5bfe 	stp	x30, x22, [sp, #240]
   857d0:	f90083f7 	str	x23, [sp, #256]
	bl	handle_irq
   857d4:	97ffec17 	bl	80830 <handle_irq>
	kernel_exit 
   857d8:	f94083f7 	ldr	x23, [sp, #256]
   857dc:	a94f5bfe 	ldp	x30, x22, [sp, #240]
   857e0:	d5184036 	msr	elr_el1, x22
   857e4:	d5184017 	msr	spsr_el1, x23
   857e8:	a94007e0 	ldp	x0, x1, [sp]
   857ec:	a9410fe2 	ldp	x2, x3, [sp, #16]
   857f0:	a94217e4 	ldp	x4, x5, [sp, #32]
   857f4:	a9431fe6 	ldp	x6, x7, [sp, #48]
   857f8:	a94427e8 	ldp	x8, x9, [sp, #64]
   857fc:	a9452fea 	ldp	x10, x11, [sp, #80]
   85800:	a94637ec 	ldp	x12, x13, [sp, #96]
   85804:	a9473fee 	ldp	x14, x15, [sp, #112]
   85808:	a94847f0 	ldp	x16, x17, [sp, #128]
   8580c:	a9494ff2 	ldp	x18, x19, [sp, #144]
   85810:	a94a57f4 	ldp	x20, x21, [sp, #160]
   85814:	a94b5ff6 	ldp	x22, x23, [sp, #176]
   85818:	a94c67f8 	ldp	x24, x25, [sp, #192]
   8581c:	a94d6ffa 	ldp	x26, x27, [sp, #208]
   85820:	a94e77fc 	ldp	x28, x29, [sp, #224]
   85824:	910443ff 	add	sp, sp, #0x110
   85828:	d69f03e0 	eret

000000000008582c <sync_invalid_el1t>:

/* ------ "default" entries, behavior: print error msg & hang ----*/
sync_invalid_el1t:
	handle_invalid_entry  SYNC_INVALID_EL1t
   8582c:	d10443ff 	sub	sp, sp, #0x110
   85830:	a90007e0 	stp	x0, x1, [sp]
   85834:	a9010fe2 	stp	x2, x3, [sp, #16]
   85838:	a90217e4 	stp	x4, x5, [sp, #32]
   8583c:	a9031fe6 	stp	x6, x7, [sp, #48]
   85840:	a90427e8 	stp	x8, x9, [sp, #64]
   85844:	a9052fea 	stp	x10, x11, [sp, #80]
   85848:	a90637ec 	stp	x12, x13, [sp, #96]
   8584c:	a9073fee 	stp	x14, x15, [sp, #112]
   85850:	a90847f0 	stp	x16, x17, [sp, #128]
   85854:	a9094ff2 	stp	x18, x19, [sp, #144]
   85858:	a90a57f4 	stp	x20, x21, [sp, #160]
   8585c:	a90b5ff6 	stp	x22, x23, [sp, #176]
   85860:	a90c67f8 	stp	x24, x25, [sp, #192]
   85864:	a90d6ffa 	stp	x26, x27, [sp, #208]
   85868:	a90e77fc 	stp	x28, x29, [sp, #224]
   8586c:	d5384036 	mrs	x22, elr_el1
   85870:	d5384017 	mrs	x23, spsr_el1
   85874:	a90f5bfe 	stp	x30, x22, [sp, #240]
   85878:	f90083f7 	str	x23, [sp, #256]
   8587c:	d2800000 	mov	x0, #0x0                   	// #0
   85880:	d5385201 	mrs	x1, esr_el1
   85884:	d5384022 	mrs	x2, elr_el1
   85888:	d5386003 	mrs	x3, far_el1
   8588c:	97ffec29 	bl	80930 <show_invalid_entry_message>
   85890:	d50342df 	msr	daifset, #0x2
   85894:	1400017e 	b	85e8c <err_hang>

0000000000085898 <irq_invalid_el1t>:

irq_invalid_el1t:
	handle_invalid_entry  IRQ_INVALID_EL1t
   85898:	d10443ff 	sub	sp, sp, #0x110
   8589c:	a90007e0 	stp	x0, x1, [sp]
   858a0:	a9010fe2 	stp	x2, x3, [sp, #16]
   858a4:	a90217e4 	stp	x4, x5, [sp, #32]
   858a8:	a9031fe6 	stp	x6, x7, [sp, #48]
   858ac:	a90427e8 	stp	x8, x9, [sp, #64]
   858b0:	a9052fea 	stp	x10, x11, [sp, #80]
   858b4:	a90637ec 	stp	x12, x13, [sp, #96]
   858b8:	a9073fee 	stp	x14, x15, [sp, #112]
   858bc:	a90847f0 	stp	x16, x17, [sp, #128]
   858c0:	a9094ff2 	stp	x18, x19, [sp, #144]
   858c4:	a90a57f4 	stp	x20, x21, [sp, #160]
   858c8:	a90b5ff6 	stp	x22, x23, [sp, #176]
   858cc:	a90c67f8 	stp	x24, x25, [sp, #192]
   858d0:	a90d6ffa 	stp	x26, x27, [sp, #208]
   858d4:	a90e77fc 	stp	x28, x29, [sp, #224]
   858d8:	d5384036 	mrs	x22, elr_el1
   858dc:	d5384017 	mrs	x23, spsr_el1
   858e0:	a90f5bfe 	stp	x30, x22, [sp, #240]
   858e4:	f90083f7 	str	x23, [sp, #256]
   858e8:	d2800020 	mov	x0, #0x1                   	// #1
   858ec:	d5385201 	mrs	x1, esr_el1
   858f0:	d5384022 	mrs	x2, elr_el1
   858f4:	d5386003 	mrs	x3, far_el1
   858f8:	97ffec0e 	bl	80930 <show_invalid_entry_message>
   858fc:	d50342df 	msr	daifset, #0x2
   85900:	14000163 	b	85e8c <err_hang>

0000000000085904 <fiq_invalid_el1t>:

fiq_invalid_el1t:
	handle_invalid_entry  FIQ_INVALID_EL1t
   85904:	d10443ff 	sub	sp, sp, #0x110
   85908:	a90007e0 	stp	x0, x1, [sp]
   8590c:	a9010fe2 	stp	x2, x3, [sp, #16]
   85910:	a90217e4 	stp	x4, x5, [sp, #32]
   85914:	a9031fe6 	stp	x6, x7, [sp, #48]
   85918:	a90427e8 	stp	x8, x9, [sp, #64]
   8591c:	a9052fea 	stp	x10, x11, [sp, #80]
   85920:	a90637ec 	stp	x12, x13, [sp, #96]
   85924:	a9073fee 	stp	x14, x15, [sp, #112]
   85928:	a90847f0 	stp	x16, x17, [sp, #128]
   8592c:	a9094ff2 	stp	x18, x19, [sp, #144]
   85930:	a90a57f4 	stp	x20, x21, [sp, #160]
   85934:	a90b5ff6 	stp	x22, x23, [sp, #176]
   85938:	a90c67f8 	stp	x24, x25, [sp, #192]
   8593c:	a90d6ffa 	stp	x26, x27, [sp, #208]
   85940:	a90e77fc 	stp	x28, x29, [sp, #224]
   85944:	d5384036 	mrs	x22, elr_el1
   85948:	d5384017 	mrs	x23, spsr_el1
   8594c:	a90f5bfe 	stp	x30, x22, [sp, #240]
   85950:	f90083f7 	str	x23, [sp, #256]
   85954:	d2800040 	mov	x0, #0x2                   	// #2
   85958:	d5385201 	mrs	x1, esr_el1
   8595c:	d5384022 	mrs	x2, elr_el1
   85960:	d5386003 	mrs	x3, far_el1
   85964:	97ffebf3 	bl	80930 <show_invalid_entry_message>
   85968:	d50342df 	msr	daifset, #0x2
   8596c:	14000148 	b	85e8c <err_hang>

0000000000085970 <error_invalid_el1t>:

error_invalid_el1t:
	handle_invalid_entry  ERROR_INVALID_EL1t
   85970:	d10443ff 	sub	sp, sp, #0x110
   85974:	a90007e0 	stp	x0, x1, [sp]
   85978:	a9010fe2 	stp	x2, x3, [sp, #16]
   8597c:	a90217e4 	stp	x4, x5, [sp, #32]
   85980:	a9031fe6 	stp	x6, x7, [sp, #48]
   85984:	a90427e8 	stp	x8, x9, [sp, #64]
   85988:	a9052fea 	stp	x10, x11, [sp, #80]
   8598c:	a90637ec 	stp	x12, x13, [sp, #96]
   85990:	a9073fee 	stp	x14, x15, [sp, #112]
   85994:	a90847f0 	stp	x16, x17, [sp, #128]
   85998:	a9094ff2 	stp	x18, x19, [sp, #144]
   8599c:	a90a57f4 	stp	x20, x21, [sp, #160]
   859a0:	a90b5ff6 	stp	x22, x23, [sp, #176]
   859a4:	a90c67f8 	stp	x24, x25, [sp, #192]
   859a8:	a90d6ffa 	stp	x26, x27, [sp, #208]
   859ac:	a90e77fc 	stp	x28, x29, [sp, #224]
   859b0:	d5384036 	mrs	x22, elr_el1
   859b4:	d5384017 	mrs	x23, spsr_el1
   859b8:	a90f5bfe 	stp	x30, x22, [sp, #240]
   859bc:	f90083f7 	str	x23, [sp, #256]
   859c0:	d2800060 	mov	x0, #0x3                   	// #3
   859c4:	d5385201 	mrs	x1, esr_el1
   859c8:	d5384022 	mrs	x2, elr_el1
   859cc:	d5386003 	mrs	x3, far_el1
   859d0:	97ffebd8 	bl	80930 <show_invalid_entry_message>
   859d4:	d50342df 	msr	daifset, #0x2
   859d8:	1400012d 	b	85e8c <err_hang>

00000000000859dc <sync_invalid_el1h>:

sync_invalid_el1h:
	handle_invalid_entry  SYNC_INVALID_EL1h
   859dc:	d10443ff 	sub	sp, sp, #0x110
   859e0:	a90007e0 	stp	x0, x1, [sp]
   859e4:	a9010fe2 	stp	x2, x3, [sp, #16]
   859e8:	a90217e4 	stp	x4, x5, [sp, #32]
   859ec:	a9031fe6 	stp	x6, x7, [sp, #48]
   859f0:	a90427e8 	stp	x8, x9, [sp, #64]
   859f4:	a9052fea 	stp	x10, x11, [sp, #80]
   859f8:	a90637ec 	stp	x12, x13, [sp, #96]
   859fc:	a9073fee 	stp	x14, x15, [sp, #112]
   85a00:	a90847f0 	stp	x16, x17, [sp, #128]
   85a04:	a9094ff2 	stp	x18, x19, [sp, #144]
   85a08:	a90a57f4 	stp	x20, x21, [sp, #160]
   85a0c:	a90b5ff6 	stp	x22, x23, [sp, #176]
   85a10:	a90c67f8 	stp	x24, x25, [sp, #192]
   85a14:	a90d6ffa 	stp	x26, x27, [sp, #208]
   85a18:	a90e77fc 	stp	x28, x29, [sp, #224]
   85a1c:	d5384036 	mrs	x22, elr_el1
   85a20:	d5384017 	mrs	x23, spsr_el1
   85a24:	a90f5bfe 	stp	x30, x22, [sp, #240]
   85a28:	f90083f7 	str	x23, [sp, #256]
   85a2c:	d2800080 	mov	x0, #0x4                   	// #4
   85a30:	d5385201 	mrs	x1, esr_el1
   85a34:	d5384022 	mrs	x2, elr_el1
   85a38:	d5386003 	mrs	x3, far_el1
   85a3c:	97ffebbd 	bl	80930 <show_invalid_entry_message>
   85a40:	d50342df 	msr	daifset, #0x2
   85a44:	14000112 	b	85e8c <err_hang>

0000000000085a48 <fiq_invalid_el1h>:

fiq_invalid_el1h:
	handle_invalid_entry  FIQ_INVALID_EL1h
   85a48:	d10443ff 	sub	sp, sp, #0x110
   85a4c:	a90007e0 	stp	x0, x1, [sp]
   85a50:	a9010fe2 	stp	x2, x3, [sp, #16]
   85a54:	a90217e4 	stp	x4, x5, [sp, #32]
   85a58:	a9031fe6 	stp	x6, x7, [sp, #48]
   85a5c:	a90427e8 	stp	x8, x9, [sp, #64]
   85a60:	a9052fea 	stp	x10, x11, [sp, #80]
   85a64:	a90637ec 	stp	x12, x13, [sp, #96]
   85a68:	a9073fee 	stp	x14, x15, [sp, #112]
   85a6c:	a90847f0 	stp	x16, x17, [sp, #128]
   85a70:	a9094ff2 	stp	x18, x19, [sp, #144]
   85a74:	a90a57f4 	stp	x20, x21, [sp, #160]
   85a78:	a90b5ff6 	stp	x22, x23, [sp, #176]
   85a7c:	a90c67f8 	stp	x24, x25, [sp, #192]
   85a80:	a90d6ffa 	stp	x26, x27, [sp, #208]
   85a84:	a90e77fc 	stp	x28, x29, [sp, #224]
   85a88:	d5384036 	mrs	x22, elr_el1
   85a8c:	d5384017 	mrs	x23, spsr_el1
   85a90:	a90f5bfe 	stp	x30, x22, [sp, #240]
   85a94:	f90083f7 	str	x23, [sp, #256]
   85a98:	d28000c0 	mov	x0, #0x6                   	// #6
   85a9c:	d5385201 	mrs	x1, esr_el1
   85aa0:	d5384022 	mrs	x2, elr_el1
   85aa4:	d5386003 	mrs	x3, far_el1
   85aa8:	97ffeba2 	bl	80930 <show_invalid_entry_message>
   85aac:	d50342df 	msr	daifset, #0x2
   85ab0:	140000f7 	b	85e8c <err_hang>

0000000000085ab4 <error_invalid_el1h>:

error_invalid_el1h:
	handle_invalid_entry  ERROR_INVALID_EL1h
   85ab4:	d10443ff 	sub	sp, sp, #0x110
   85ab8:	a90007e0 	stp	x0, x1, [sp]
   85abc:	a9010fe2 	stp	x2, x3, [sp, #16]
   85ac0:	a90217e4 	stp	x4, x5, [sp, #32]
   85ac4:	a9031fe6 	stp	x6, x7, [sp, #48]
   85ac8:	a90427e8 	stp	x8, x9, [sp, #64]
   85acc:	a9052fea 	stp	x10, x11, [sp, #80]
   85ad0:	a90637ec 	stp	x12, x13, [sp, #96]
   85ad4:	a9073fee 	stp	x14, x15, [sp, #112]
   85ad8:	a90847f0 	stp	x16, x17, [sp, #128]
   85adc:	a9094ff2 	stp	x18, x19, [sp, #144]
   85ae0:	a90a57f4 	stp	x20, x21, [sp, #160]
   85ae4:	a90b5ff6 	stp	x22, x23, [sp, #176]
   85ae8:	a90c67f8 	stp	x24, x25, [sp, #192]
   85aec:	a90d6ffa 	stp	x26, x27, [sp, #208]
   85af0:	a90e77fc 	stp	x28, x29, [sp, #224]
   85af4:	d5384036 	mrs	x22, elr_el1
   85af8:	d5384017 	mrs	x23, spsr_el1
   85afc:	a90f5bfe 	stp	x30, x22, [sp, #240]
   85b00:	f90083f7 	str	x23, [sp, #256]
   85b04:	d28000e0 	mov	x0, #0x7                   	// #7
   85b08:	d5385201 	mrs	x1, esr_el1
   85b0c:	d5384022 	mrs	x2, elr_el1
   85b10:	d5386003 	mrs	x3, far_el1
   85b14:	97ffeb87 	bl	80930 <show_invalid_entry_message>
   85b18:	d50342df 	msr	daifset, #0x2
   85b1c:	140000dc 	b	85e8c <err_hang>

0000000000085b20 <sync_invalid_el0_64>:

sync_invalid_el0_64:
	handle_invalid_entry  SYNC_INVALID_EL0_64
   85b20:	d10443ff 	sub	sp, sp, #0x110
   85b24:	a90007e0 	stp	x0, x1, [sp]
   85b28:	a9010fe2 	stp	x2, x3, [sp, #16]
   85b2c:	a90217e4 	stp	x4, x5, [sp, #32]
   85b30:	a9031fe6 	stp	x6, x7, [sp, #48]
   85b34:	a90427e8 	stp	x8, x9, [sp, #64]
   85b38:	a9052fea 	stp	x10, x11, [sp, #80]
   85b3c:	a90637ec 	stp	x12, x13, [sp, #96]
   85b40:	a9073fee 	stp	x14, x15, [sp, #112]
   85b44:	a90847f0 	stp	x16, x17, [sp, #128]
   85b48:	a9094ff2 	stp	x18, x19, [sp, #144]
   85b4c:	a90a57f4 	stp	x20, x21, [sp, #160]
   85b50:	a90b5ff6 	stp	x22, x23, [sp, #176]
   85b54:	a90c67f8 	stp	x24, x25, [sp, #192]
   85b58:	a90d6ffa 	stp	x26, x27, [sp, #208]
   85b5c:	a90e77fc 	stp	x28, x29, [sp, #224]
   85b60:	d5384036 	mrs	x22, elr_el1
   85b64:	d5384017 	mrs	x23, spsr_el1
   85b68:	a90f5bfe 	stp	x30, x22, [sp, #240]
   85b6c:	f90083f7 	str	x23, [sp, #256]
   85b70:	d2800100 	mov	x0, #0x8                   	// #8
   85b74:	d5385201 	mrs	x1, esr_el1
   85b78:	d5384022 	mrs	x2, elr_el1
   85b7c:	d5386003 	mrs	x3, far_el1
   85b80:	97ffeb6c 	bl	80930 <show_invalid_entry_message>
   85b84:	d50342df 	msr	daifset, #0x2
   85b88:	140000c1 	b	85e8c <err_hang>

0000000000085b8c <irq_invalid_el0_64>:

irq_invalid_el0_64:
	handle_invalid_entry  IRQ_INVALID_EL0_64
   85b8c:	d10443ff 	sub	sp, sp, #0x110
   85b90:	a90007e0 	stp	x0, x1, [sp]
   85b94:	a9010fe2 	stp	x2, x3, [sp, #16]
   85b98:	a90217e4 	stp	x4, x5, [sp, #32]
   85b9c:	a9031fe6 	stp	x6, x7, [sp, #48]
   85ba0:	a90427e8 	stp	x8, x9, [sp, #64]
   85ba4:	a9052fea 	stp	x10, x11, [sp, #80]
   85ba8:	a90637ec 	stp	x12, x13, [sp, #96]
   85bac:	a9073fee 	stp	x14, x15, [sp, #112]
   85bb0:	a90847f0 	stp	x16, x17, [sp, #128]
   85bb4:	a9094ff2 	stp	x18, x19, [sp, #144]
   85bb8:	a90a57f4 	stp	x20, x21, [sp, #160]
   85bbc:	a90b5ff6 	stp	x22, x23, [sp, #176]
   85bc0:	a90c67f8 	stp	x24, x25, [sp, #192]
   85bc4:	a90d6ffa 	stp	x26, x27, [sp, #208]
   85bc8:	a90e77fc 	stp	x28, x29, [sp, #224]
   85bcc:	d5384036 	mrs	x22, elr_el1
   85bd0:	d5384017 	mrs	x23, spsr_el1
   85bd4:	a90f5bfe 	stp	x30, x22, [sp, #240]
   85bd8:	f90083f7 	str	x23, [sp, #256]
   85bdc:	d2800120 	mov	x0, #0x9                   	// #9
   85be0:	d5385201 	mrs	x1, esr_el1
   85be4:	d5384022 	mrs	x2, elr_el1
   85be8:	d5386003 	mrs	x3, far_el1
   85bec:	97ffeb51 	bl	80930 <show_invalid_entry_message>
   85bf0:	d50342df 	msr	daifset, #0x2
   85bf4:	140000a6 	b	85e8c <err_hang>

0000000000085bf8 <fiq_invalid_el0_64>:

fiq_invalid_el0_64:
	handle_invalid_entry  FIQ_INVALID_EL0_64
   85bf8:	d10443ff 	sub	sp, sp, #0x110
   85bfc:	a90007e0 	stp	x0, x1, [sp]
   85c00:	a9010fe2 	stp	x2, x3, [sp, #16]
   85c04:	a90217e4 	stp	x4, x5, [sp, #32]
   85c08:	a9031fe6 	stp	x6, x7, [sp, #48]
   85c0c:	a90427e8 	stp	x8, x9, [sp, #64]
   85c10:	a9052fea 	stp	x10, x11, [sp, #80]
   85c14:	a90637ec 	stp	x12, x13, [sp, #96]
   85c18:	a9073fee 	stp	x14, x15, [sp, #112]
   85c1c:	a90847f0 	stp	x16, x17, [sp, #128]
   85c20:	a9094ff2 	stp	x18, x19, [sp, #144]
   85c24:	a90a57f4 	stp	x20, x21, [sp, #160]
   85c28:	a90b5ff6 	stp	x22, x23, [sp, #176]
   85c2c:	a90c67f8 	stp	x24, x25, [sp, #192]
   85c30:	a90d6ffa 	stp	x26, x27, [sp, #208]
   85c34:	a90e77fc 	stp	x28, x29, [sp, #224]
   85c38:	d5384036 	mrs	x22, elr_el1
   85c3c:	d5384017 	mrs	x23, spsr_el1
   85c40:	a90f5bfe 	stp	x30, x22, [sp, #240]
   85c44:	f90083f7 	str	x23, [sp, #256]
   85c48:	d2800140 	mov	x0, #0xa                   	// #10
   85c4c:	d5385201 	mrs	x1, esr_el1
   85c50:	d5384022 	mrs	x2, elr_el1
   85c54:	d5386003 	mrs	x3, far_el1
   85c58:	97ffeb36 	bl	80930 <show_invalid_entry_message>
   85c5c:	d50342df 	msr	daifset, #0x2
   85c60:	1400008b 	b	85e8c <err_hang>

0000000000085c64 <error_invalid_el0_64>:

error_invalid_el0_64:
	handle_invalid_entry  ERROR_INVALID_EL0_64
   85c64:	d10443ff 	sub	sp, sp, #0x110
   85c68:	a90007e0 	stp	x0, x1, [sp]
   85c6c:	a9010fe2 	stp	x2, x3, [sp, #16]
   85c70:	a90217e4 	stp	x4, x5, [sp, #32]
   85c74:	a9031fe6 	stp	x6, x7, [sp, #48]
   85c78:	a90427e8 	stp	x8, x9, [sp, #64]
   85c7c:	a9052fea 	stp	x10, x11, [sp, #80]
   85c80:	a90637ec 	stp	x12, x13, [sp, #96]
   85c84:	a9073fee 	stp	x14, x15, [sp, #112]
   85c88:	a90847f0 	stp	x16, x17, [sp, #128]
   85c8c:	a9094ff2 	stp	x18, x19, [sp, #144]
   85c90:	a90a57f4 	stp	x20, x21, [sp, #160]
   85c94:	a90b5ff6 	stp	x22, x23, [sp, #176]
   85c98:	a90c67f8 	stp	x24, x25, [sp, #192]
   85c9c:	a90d6ffa 	stp	x26, x27, [sp, #208]
   85ca0:	a90e77fc 	stp	x28, x29, [sp, #224]
   85ca4:	d5384036 	mrs	x22, elr_el1
   85ca8:	d5384017 	mrs	x23, spsr_el1
   85cac:	a90f5bfe 	stp	x30, x22, [sp, #240]
   85cb0:	f90083f7 	str	x23, [sp, #256]
   85cb4:	d2800160 	mov	x0, #0xb                   	// #11
   85cb8:	d5385201 	mrs	x1, esr_el1
   85cbc:	d5384022 	mrs	x2, elr_el1
   85cc0:	d5386003 	mrs	x3, far_el1
   85cc4:	97ffeb1b 	bl	80930 <show_invalid_entry_message>
   85cc8:	d50342df 	msr	daifset, #0x2
   85ccc:	14000070 	b	85e8c <err_hang>

0000000000085cd0 <sync_invalid_el0_32>:

sync_invalid_el0_32:
	handle_invalid_entry  SYNC_INVALID_EL0_32
   85cd0:	d10443ff 	sub	sp, sp, #0x110
   85cd4:	a90007e0 	stp	x0, x1, [sp]
   85cd8:	a9010fe2 	stp	x2, x3, [sp, #16]
   85cdc:	a90217e4 	stp	x4, x5, [sp, #32]
   85ce0:	a9031fe6 	stp	x6, x7, [sp, #48]
   85ce4:	a90427e8 	stp	x8, x9, [sp, #64]
   85ce8:	a9052fea 	stp	x10, x11, [sp, #80]
   85cec:	a90637ec 	stp	x12, x13, [sp, #96]
   85cf0:	a9073fee 	stp	x14, x15, [sp, #112]
   85cf4:	a90847f0 	stp	x16, x17, [sp, #128]
   85cf8:	a9094ff2 	stp	x18, x19, [sp, #144]
   85cfc:	a90a57f4 	stp	x20, x21, [sp, #160]
   85d00:	a90b5ff6 	stp	x22, x23, [sp, #176]
   85d04:	a90c67f8 	stp	x24, x25, [sp, #192]
   85d08:	a90d6ffa 	stp	x26, x27, [sp, #208]
   85d0c:	a90e77fc 	stp	x28, x29, [sp, #224]
   85d10:	d5384036 	mrs	x22, elr_el1
   85d14:	d5384017 	mrs	x23, spsr_el1
   85d18:	a90f5bfe 	stp	x30, x22, [sp, #240]
   85d1c:	f90083f7 	str	x23, [sp, #256]
   85d20:	d2800180 	mov	x0, #0xc                   	// #12
   85d24:	d5385201 	mrs	x1, esr_el1
   85d28:	d5384022 	mrs	x2, elr_el1
   85d2c:	d5386003 	mrs	x3, far_el1
   85d30:	97ffeb00 	bl	80930 <show_invalid_entry_message>
   85d34:	d50342df 	msr	daifset, #0x2
   85d38:	14000055 	b	85e8c <err_hang>

0000000000085d3c <irq_invalid_el0_32>:

irq_invalid_el0_32:
	handle_invalid_entry  IRQ_INVALID_EL0_32
   85d3c:	d10443ff 	sub	sp, sp, #0x110
   85d40:	a90007e0 	stp	x0, x1, [sp]
   85d44:	a9010fe2 	stp	x2, x3, [sp, #16]
   85d48:	a90217e4 	stp	x4, x5, [sp, #32]
   85d4c:	a9031fe6 	stp	x6, x7, [sp, #48]
   85d50:	a90427e8 	stp	x8, x9, [sp, #64]
   85d54:	a9052fea 	stp	x10, x11, [sp, #80]
   85d58:	a90637ec 	stp	x12, x13, [sp, #96]
   85d5c:	a9073fee 	stp	x14, x15, [sp, #112]
   85d60:	a90847f0 	stp	x16, x17, [sp, #128]
   85d64:	a9094ff2 	stp	x18, x19, [sp, #144]
   85d68:	a90a57f4 	stp	x20, x21, [sp, #160]
   85d6c:	a90b5ff6 	stp	x22, x23, [sp, #176]
   85d70:	a90c67f8 	stp	x24, x25, [sp, #192]
   85d74:	a90d6ffa 	stp	x26, x27, [sp, #208]
   85d78:	a90e77fc 	stp	x28, x29, [sp, #224]
   85d7c:	d5384036 	mrs	x22, elr_el1
   85d80:	d5384017 	mrs	x23, spsr_el1
   85d84:	a90f5bfe 	stp	x30, x22, [sp, #240]
   85d88:	f90083f7 	str	x23, [sp, #256]
   85d8c:	d28001a0 	mov	x0, #0xd                   	// #13
   85d90:	d5385201 	mrs	x1, esr_el1
   85d94:	d5384022 	mrs	x2, elr_el1
   85d98:	d5386003 	mrs	x3, far_el1
   85d9c:	97ffeae5 	bl	80930 <show_invalid_entry_message>
   85da0:	d50342df 	msr	daifset, #0x2
   85da4:	1400003a 	b	85e8c <err_hang>

0000000000085da8 <fiq_invalid_el0_32>:

fiq_invalid_el0_32:
	handle_invalid_entry  FIQ_INVALID_EL0_32
   85da8:	d10443ff 	sub	sp, sp, #0x110
   85dac:	a90007e0 	stp	x0, x1, [sp]
   85db0:	a9010fe2 	stp	x2, x3, [sp, #16]
   85db4:	a90217e4 	stp	x4, x5, [sp, #32]
   85db8:	a9031fe6 	stp	x6, x7, [sp, #48]
   85dbc:	a90427e8 	stp	x8, x9, [sp, #64]
   85dc0:	a9052fea 	stp	x10, x11, [sp, #80]
   85dc4:	a90637ec 	stp	x12, x13, [sp, #96]
   85dc8:	a9073fee 	stp	x14, x15, [sp, #112]
   85dcc:	a90847f0 	stp	x16, x17, [sp, #128]
   85dd0:	a9094ff2 	stp	x18, x19, [sp, #144]
   85dd4:	a90a57f4 	stp	x20, x21, [sp, #160]
   85dd8:	a90b5ff6 	stp	x22, x23, [sp, #176]
   85ddc:	a90c67f8 	stp	x24, x25, [sp, #192]
   85de0:	a90d6ffa 	stp	x26, x27, [sp, #208]
   85de4:	a90e77fc 	stp	x28, x29, [sp, #224]
   85de8:	d5384036 	mrs	x22, elr_el1
   85dec:	d5384017 	mrs	x23, spsr_el1
   85df0:	a90f5bfe 	stp	x30, x22, [sp, #240]
   85df4:	f90083f7 	str	x23, [sp, #256]
   85df8:	d28001c0 	mov	x0, #0xe                   	// #14
   85dfc:	d5385201 	mrs	x1, esr_el1
   85e00:	d5384022 	mrs	x2, elr_el1
   85e04:	d5386003 	mrs	x3, far_el1
   85e08:	97ffeaca 	bl	80930 <show_invalid_entry_message>
   85e0c:	d50342df 	msr	daifset, #0x2
   85e10:	1400001f 	b	85e8c <err_hang>

0000000000085e14 <error_invalid_el0_32>:

error_invalid_el0_32:
	handle_invalid_entry  ERROR_INVALID_EL0_32
   85e14:	d10443ff 	sub	sp, sp, #0x110
   85e18:	a90007e0 	stp	x0, x1, [sp]
   85e1c:	a9010fe2 	stp	x2, x3, [sp, #16]
   85e20:	a90217e4 	stp	x4, x5, [sp, #32]
   85e24:	a9031fe6 	stp	x6, x7, [sp, #48]
   85e28:	a90427e8 	stp	x8, x9, [sp, #64]
   85e2c:	a9052fea 	stp	x10, x11, [sp, #80]
   85e30:	a90637ec 	stp	x12, x13, [sp, #96]
   85e34:	a9073fee 	stp	x14, x15, [sp, #112]
   85e38:	a90847f0 	stp	x16, x17, [sp, #128]
   85e3c:	a9094ff2 	stp	x18, x19, [sp, #144]
   85e40:	a90a57f4 	stp	x20, x21, [sp, #160]
   85e44:	a90b5ff6 	stp	x22, x23, [sp, #176]
   85e48:	a90c67f8 	stp	x24, x25, [sp, #192]
   85e4c:	a90d6ffa 	stp	x26, x27, [sp, #208]
   85e50:	a90e77fc 	stp	x28, x29, [sp, #224]
   85e54:	d5384036 	mrs	x22, elr_el1
   85e58:	d5384017 	mrs	x23, spsr_el1
   85e5c:	a90f5bfe 	stp	x30, x22, [sp, #240]
   85e60:	f90083f7 	str	x23, [sp, #256]
   85e64:	d28001e0 	mov	x0, #0xf                   	// #15
   85e68:	d5385201 	mrs	x1, esr_el1
   85e6c:	d5384022 	mrs	x2, elr_el1
   85e70:	d5386003 	mrs	x3, far_el1
   85e74:	97ffeaaf 	bl	80930 <show_invalid_entry_message>
   85e78:	d50342df 	msr	daifset, #0x2
   85e7c:	14000004 	b	85e8c <err_hang>

0000000000085e80 <ret_from_fork>:
.globl ret_from_fork
// the **first** piece of code executed by a newly created process. 
// only executed once throughout a task's lifetime
// NB: despite the name "fork", we are not doing fork() as in Linux/Unix
ret_from_fork:
	bl	leave_scheduler
   85e80:	97fff6a8 	bl	83920 <leave_scheduler>
	/* 	Explanation: copy_process() saves `fn` (the process's main function) and
	`arg` (the argument passed to the process) to`task_struct.x19` and `x20`.
	When switching to a new task, the kernel restores `fn` and `arg` from
	`task_struct` to `x19` and `x20`. Below, `ret_from_fork` calls the function
	stored in `x19` register with the argument stored in `x20`. */
	mov x0, x20  /* STUDENT: TODO: replace this */
   85e84:	aa1403e0 	mov	x0, x20
	// call a kern task's main func
	blr x19 /* STUDENT: TODO: replace this */
   85e88:	d63f0260 	blr	x19

0000000000085e8c <err_hang>:
		#0  err_hang () at entry.S:212
		#1  0x0000000000085e8c in ret_from_fork () at entry.S:208
		Backtrace stopped: previous frame identical to this frame (corrupt stack?)
	*/
.globl err_hang
err_hang: b err_hang
   85e8c:	14000000 	b	85e8c <err_hang>

0000000000085e90 <cpu_switch_to>:
// save cpu regs (callee saved, sp/pc) to prev->cpu_context; 
// load next->cpu_context to the cpu regs
.globl cpu_switch_to
/* the context switch magic */
cpu_switch_to:
	mov	x10, #THREAD_CPU_CONTEXT     // sched.h
   85e90:	d280000a 	mov	x10, #0x0                   	// #0
	add	x8, x0, x10
   85e94:	8b0a0008 	add	x8, x0, x10
	// now `x8` will contain a pointer to the current `cpu_context`
	mov	x9, sp
   85e98:	910003e9 	mov	x9, sp
	
	// Below: all callee-saved registers are stored in the order in which 
	// they are defined in the `cpu_context` structure.
	// Think: why not saving x11-x18? (compare to entry.S)
	stp	x19, x20, [x8], #16		
   85e9c:	a8815113 	stp	x19, x20, [x8], #16
	stp	x21, x22, [x8], #16
   85ea0:	a8815915 	stp	x21, x22, [x8], #16
	stp	x23, x24, [x8], #16
   85ea4:	a8816117 	stp	x23, x24, [x8], #16
	stp	x25, x26, [x8], #16
   85ea8:	a8816919 	stp	x25, x26, [x8], #16
	stp	x27, x28, [x8], #16
   85eac:	a881711b 	stp	x27, x28, [x8], #16
	stp	x29, x9, [x8], #16
   85eb0:	a881251d 	stp	x29, x9, [x8], #16
	str	x30, [x8]			// save LR (x30) to cpu_context.pc, pointing to where this function is called from
   85eb4:	f900011e 	str	x30, [x8]
	
	// calculate the address of the next task's `cpu_context`
	mov x10, #THREAD_CPU_CONTEXT
   85eb8:	d280000a 	mov	x10, #0x0                   	// #0
	add x8, x1, x10/* STUDENT: TODO: replace this */
   85ebc:	8b0a0028 	add	x8, x1, x10
	
	// below: restore the CPU context of "switch_to" task to CPU regs
	/* STUDENT: TODO: your code here */
	ldp x19, x20, [x8], #16
   85ec0:	a8c15113 	ldp	x19, x20, [x8], #16
	ldp x21, x22, [x8], #16
   85ec4:	a8c15915 	ldp	x21, x22, [x8], #16
	ldp x23, x24, [x8], #16
   85ec8:	a8c16117 	ldp	x23, x24, [x8], #16
	ldp x25, x26, [x8], #16
   85ecc:	a8c16919 	ldp	x25, x26, [x8], #16
	ldp x27, x28, [x8], #16
   85ed0:	a8c1711b 	ldp	x27, x28, [x8], #16
	ldp x29, x9,  [x8], #16 
   85ed4:	a8c1251d 	ldp	x29, x9, [x8], #16
	ldr	x30, [x8]				// x30 == LR
   85ed8:	f940011e 	ldr	x30, [x8]
	// restore the value of sp, which is already loaded from the cpu context
	mov sp, x9 /* STUDENT: TODO: replace this */
   85edc:	9100013f 	mov	sp, x9
	// The `ret` instruction will jump to the location pointed to by the link 
	// register (LR or `x30`). If we are switching to a task for the first time, 
	// this will be the beginning of the `ret_from_fork` function. In all other 
	// cases this will be the address previously saved in the `cpu_context.pc` 
	// by the `cpu_switch_to` function.
	ret							
   85ee0:	d65f03c0 	ret
   85ee4:	00000000 	udf	#0

0000000000085ee8 <enable_irq>:
#endif

// daifclr/set 
.globl enable_irq
enable_irq:
	msr    daifclr, #0b0010 
   85ee8:	d50342ff 	msr	daifclr, #0x2
	ret
   85eec:	d65f03c0 	ret

0000000000085ef0 <disable_irq>:

.globl disable_irq
disable_irq:
	msr	daifset, #0b0010 
   85ef0:	d50342df 	msr	daifset, #0x2
	ret 
   85ef4:	d65f03c0 	ret

0000000000085ef8 <is_irq_masked>:

.global is_irq_masked
is_irq_masked:
	# fxl: whereas daifset/clr are lowest four bits, daif seems bit9--6
	# https://developer.arm.com/documentation/ddi0601/2023-12/AArch64-Registers/DAIF--Interrupt-Mask-Bits
	mrs x0, daif 
   85ef8:	d53b4220 	mrs	x0, daif
	lsr x0, x0, #7 
   85efc:	d347fc00 	lsr	x0, x0, #7
	and x0, x0, #1
   85f00:	92400000 	and	x0, x0, #0x1
	ret
   85f04:	d65f03c0 	ret

0000000000085f08 <cpuid>:

.global cpuid
cpuid: 
	mrs	x0, mpidr_el1
   85f08:	d53800a0 	mrs	x0, mpidr_el1
	and	x0, x0, #0xFF
   85f0c:	92401c00 	and	x0, x0, #0xff
	ret
   85f10:	d65f03c0 	ret

0000000000085f14 <set_pgd>:

// ----------------------- pgd --------------------------------------------//
// ttbr0, user va
.globl set_pgd
set_pgd:
	msr	ttbr0_el1, x0
   85f14:	d5182000 	msr	ttbr0_el1, x0
	tlbi vmalle1is
   85f18:	d508831f 	tlbi	vmalle1is
  	DSB ISH              // ensure completion of TLB invalidation
   85f1c:	d5033b9f 	dsb	ish
	isb
   85f20:	d5033fdf 	isb
	ret
   85f24:	d65f03c0 	ret

0000000000085f28 <get_pgd>:

.globl get_pgd
get_pgd:
	mov x1, 0
   85f28:	d2800001 	mov	x1, #0x0                   	// #0
	ldr x0, [x1]
   85f2c:	f9400020 	ldr	x0, [x1]
	mov x0, 0x1000
   85f30:	d2820000 	mov	x0, #0x1000                	// #4096
	msr	ttbr0_el1, x0
   85f34:	d5182000 	msr	ttbr0_el1, x0
	ldr x0, [x1]
   85f38:	f9400020 	ldr	x0, [x1]
	ret
   85f3c:	d65f03c0 	ret

0000000000085f40 <memcpy_aligned>:
// the _aligned funcs are faster than normal variants, but MUST BE used with 
// care (unaligned addr will corrupt/miss contents) to avoid nasty bugs. 
// unless the buf is large, the extra speed is not worth it
.globl memcpy_aligned
memcpy_aligned:
 	ldr x3, [x1], #8
   85f40:	f8408423 	ldr	x3, [x1], #8
 	str x3, [x0], #8
   85f44:	f8008403 	str	x3, [x0], #8
	subs x2, x2, #8
   85f48:	f1002042 	subs	x2, x2, #0x8
 	b.gt memcpy_aligned
   85f4c:	54ffffac 	b.gt	85f40 <memcpy_aligned>
 	ret
   85f50:	d65f03c0 	ret

0000000000085f54 <memzero_aligned>:

.globl memzero_aligned
memzero_aligned:
	str xzr, [x0], #8
   85f54:	f800841f 	str	xzr, [x0], #8
	subs x1, x1, #8
   85f58:	f1002021 	subs	x1, x1, #0x8
	b.gt memzero_aligned
   85f5c:	54ffffcc 	b.gt	85f54 <memzero_aligned>
	ret
   85f60:	d65f03c0 	ret

0000000000085f64 <get_el>:

.globl get_el
get_el:
	mrs x0, CurrentEL
   85f64:	d5384240 	mrs	x0, currentel
	lsr x0, x0, #2
   85f68:	d342fc00 	lsr	x0, x0, #2
	ret
   85f6c:	d65f03c0 	ret

0000000000085f70 <put32>:

.globl put32
put32:
	str w1,[x0]
   85f70:	b9000001 	str	w1, [x0]
	ret
   85f74:	d65f03c0 	ret

0000000000085f78 <get32>:

.globl get32
get32:
	ldr w0,[x0]
   85f78:	b9400000 	ldr	w0, [x0]
	ret
   85f7c:	d65f03c0 	ret

0000000000085f80 <delay>:

.globl delay
delay:
	subs x0, x0, #1
   85f80:	f1000400 	subs	x0, x0, #0x1
	bne delay
   85f84:	54ffffe1 	b.ne	85f80 <delay>  // b.any
	ret
   85f88:	d65f03c0 	ret

0000000000085f8c <__asm_flush_dcache_range>:
 * x1: end address
  * (fxl: both VA, "dc civac" - dc cache and/or inv by VA)
 */
.globl __asm_flush_dcache_range
__asm_flush_dcache_range:
    mrs    x3, ctr_el0
   85f8c:	d53b0023 	mrs	x3, ctr_el0
    lsr    x3, x3, #16
   85f90:	d350fc63 	lsr	x3, x3, #16
    and    x3, x3, #0xf
   85f94:	92400c63 	and	x3, x3, #0xf
    mov    x2, #4
   85f98:	d2800082 	mov	x2, #0x4                   	// #4
    lsl    x2, x2, x3        /* cache line size */
   85f9c:	9ac32042 	lsl	x2, x2, x3

    /* x2 <- minimal cache line size in cache system */
    sub    x3, x2, #1
   85fa0:	d1000443 	sub	x3, x2, #0x1
    bic    x0, x0, x3
   85fa4:	8a230000 	bic	x0, x0, x3

1:  dc    civac, x0    /* clean & invalidate data or unified cache */
   85fa8:	d50b7e20 	dc	civac, x0
    add    x0, x0, x2
   85fac:	8b020000 	add	x0, x0, x2
    cmp    x0, x1
   85fb0:	eb01001f 	cmp	x0, x1
    b.lo    1b
   85fb4:	54ffffa3 	b.cc	85fa8 <__asm_flush_dcache_range+0x1c>  // b.lo, b.ul, b.last
    dsb    sy
   85fb8:	d5033f9f 	dsb	sy
    ret
   85fbc:	d65f03c0 	ret

0000000000085fc0 <__asm_invalidate_dcache_range>:
 * x0: start address
 * x1: end address
 */
.globl __asm_invalidate_dcache_range
__asm_invalidate_dcache_range:
    mrs    x3, ctr_el0
   85fc0:	d53b0023 	mrs	x3, ctr_el0
    lsr    x3, x3, #16
   85fc4:	d350fc63 	lsr	x3, x3, #16
    and    x3, x3, #0xf
   85fc8:	92400c63 	and	x3, x3, #0xf
    mov    x2, #4
   85fcc:	d2800082 	mov	x2, #0x4                   	// #4
    lsl    x2, x2, x3        /* cache line size */
   85fd0:	9ac32042 	lsl	x2, x2, x3

    /* x2 <- minimal cache line size in cache system */
    sub    x3, x2, #1
   85fd4:	d1000443 	sub	x3, x2, #0x1
    bic    x0, x0, x3
   85fd8:	8a230000 	bic	x0, x0, x3

1:  dc   ivac, x0    /* invalidate data or unified cache */
   85fdc:	d5087620 	dc	ivac, x0
    add    x0, x0, x2
   85fe0:	8b020000 	add	x0, x0, x2
    cmp    x0, x1
   85fe4:	eb01001f 	cmp	x0, x1
    b.lo    1b
   85fe8:	54ffffa3 	b.cc	85fdc <__asm_invalidate_dcache_range+0x1c>  // b.lo, b.ul, b.last
    dsb    sy
   85fec:	d5033f9f 	dsb	sy
    ret
   85ff0:	d65f03c0 	ret

0000000000085ff4 <__asm_dcache_level>:
 * x1: 0 clean & invalidate, 1 invalidate only
 * x2~x9: clobbered
 */
.globl __asm_dcache_level
__asm_dcache_level:
    lsl    x12, x0, #1
   85ff4:	d37ff80c 	lsl	x12, x0, #1
    msr    csselr_el1, x12        /* select cache level */
   85ff8:	d51a000c 	msr	csselr_el1, x12
    isb                /* sync change of cssidr_el1 */
   85ffc:	d5033fdf 	isb
    mrs    x6, ccsidr_el1        /* read the new cssidr_el1 */
   86000:	d5390006 	mrs	x6, ccsidr_el1
    and    x2, x6, #7        /* x2 <- log2(cache line size)-4 */
   86004:	924008c2 	and	x2, x6, #0x7
    add    x2, x2, #4        /* x2 <- log2(cache line size) */
   86008:	91001042 	add	x2, x2, #0x4
    mov    x3, #0x3ff
   8600c:	d2807fe3 	mov	x3, #0x3ff                 	// #1023
    and    x3, x3, x6, lsr #3    /* x3 <- max number of #ways */
   86010:	8a460c63 	and	x3, x3, x6, lsr #3
    clz    w5, w3            /* bit position of #ways */
   86014:	5ac01065 	clz	w5, w3
    mov    x4, #0x7fff
   86018:	d28fffe4 	mov	x4, #0x7fff                	// #32767
    and    x4, x4, x6, lsr #13    /* x4 <- max number of #sets */
   8601c:	8a463484 	and	x4, x4, x6, lsr #13

0000000000086020 <loop_set>:
    /* x3 <- number of cache ways - 1 */
    /* x4 <- number of cache sets - 1 */
    /* x5 <- bit position of #ways */

loop_set:
    mov    x6, x3            /* x6 <- working copy of #ways */
   86020:	aa0303e6 	mov	x6, x3

0000000000086024 <loop_way>:
loop_way:
    lsl    x7, x6, x5
   86024:	9ac520c7 	lsl	x7, x6, x5
    orr    x9, x12, x7        /* map way and level to cisw value */
   86028:	aa070189 	orr	x9, x12, x7
    lsl    x7, x4, x2
   8602c:	9ac22087 	lsl	x7, x4, x2
    orr    x9, x9, x7        /* map set number to cisw value */
   86030:	aa070129 	orr	x9, x9, x7
    tbz    w1, #0, 1f
   86034:	36000061 	tbz	w1, #0, 86040 <loop_way+0x1c>
    dc    isw, x9
   86038:	d5087649 	dc	isw, x9
    b    2f
   8603c:	14000002 	b	86044 <loop_way+0x20>
1:    dc    cisw, x9        /* clean & invalidate by set/way */
   86040:	d5087e49 	dc	cisw, x9
2:    subs    x6, x6, #1        /* decrement the way */
   86044:	f10004c6 	subs	x6, x6, #0x1
    b.ge    loop_way
   86048:	54fffeea 	b.ge	86024 <loop_way>  // b.tcont
    subs    x4, x4, #1        /* decrement the set */
   8604c:	f1000484 	subs	x4, x4, #0x1
    b.ge    loop_set
   86050:	54fffe8a 	b.ge	86020 <loop_set>  // b.tcont

    ret
   86054:	d65f03c0 	ret

0000000000086058 <__asm_dcache_all>:
 *
 * flush or invalidate all data cache by SET/WAY.
 */
.globl __asm_dcache_all
__asm_dcache_all:
    mov    x1, x0
   86058:	aa0003e1 	mov	x1, x0
    dsb    sy
   8605c:	d5033f9f 	dsb	sy
    mrs    x10, clidr_el1        /* read clidr_el1 */
   86060:	d539002a 	mrs	x10, clidr_el1
    lsr    x11, x10, #24
   86064:	d358fd4b 	lsr	x11, x10, #24
    and    x11, x11, #0x7        /* x11 <- loc */
   86068:	9240096b 	and	x11, x11, #0x7
    cbz    x11, finished        /* if loc is 0, exit */
   8606c:	b400024b 	cbz	x11, 860b4 <finished>
    mov    x15, lr
   86070:	aa1e03ef 	mov	x15, x30
    mov    x0, #0            /* start flush at cache level 0 */
   86074:	d2800000 	mov	x0, #0x0                   	// #0

0000000000086078 <loop_level>:
    /* x10 <- clidr_el1 */
    /* x11 <- loc */
    /* x15 <- return address */

loop_level:
    lsl    x12, x0, #1
   86078:	d37ff80c 	lsl	x12, x0, #1
    add    x12, x12, x0        /* x0 <- tripled cache level */
   8607c:	8b00018c 	add	x12, x12, x0
    lsr    x12, x10, x12
   86080:	9acc254c 	lsr	x12, x10, x12
    and    x12, x12, #7        /* x12 <- cache type */
   86084:	9240098c 	and	x12, x12, #0x7
    cmp    x12, #2
   86088:	f100099f 	cmp	x12, #0x2
    b.lt    skip            /* skip if no cache or icache */
   8608c:	5400004b 	b.lt	86094 <skip>  // b.tstop
    bl    __asm_dcache_level    /* x1 = 0 flush, 1 invalidate */
   86090:	97ffffd9 	bl	85ff4 <__asm_dcache_level>

0000000000086094 <skip>:
skip:
    add    x0, x0, #1        /* increment cache level */
   86094:	91000400 	add	x0, x0, #0x1
    cmp    x11, x0
   86098:	eb00017f 	cmp	x11, x0
    b.gt    loop_level
   8609c:	54fffeec 	b.gt	86078 <loop_level>

    mov    x0, #0
   860a0:	d2800000 	mov	x0, #0x0                   	// #0
    msr    csselr_el1, x0        /* restore csselr_el1 */
   860a4:	d51a0000 	msr	csselr_el1, x0
    dsb    sy
   860a8:	d5033f9f 	dsb	sy
    isb
   860ac:	d5033fdf 	isb
    mov    lr, x15
   860b0:	aa0f03fe 	mov	x30, x15

00000000000860b4 <finished>:

finished:
    ret
   860b4:	d65f03c0 	ret

00000000000860b8 <__asm_flush_dcache_all>:

.globl __asm_flush_dcache_all
__asm_flush_dcache_all:
    mov    x0, #0
   860b8:	d2800000 	mov	x0, #0x0                   	// #0
    b    __asm_dcache_all
   860bc:	17ffffe7 	b	86058 <__asm_dcache_all>

00000000000860c0 <__asm_invalidate_dcache_all>:

.globl __asm_invalidate_dcache_all
__asm_invalidate_dcache_all:
    mov    x0, #0x1
   860c0:	d2800020 	mov	x0, #0x1                   	// #1
    b    __asm_dcache_all
   860c4:	17ffffe5 	b	86058 <__asm_dcache_all>

00000000000860c8 <uart_send_pa>:
#define AUX_MU_IO_REG   (PBASE+0x00215040)

.globl uart_send_pa
uart_send_pa:
1:
	ldr x1, =AUX_MU_LSR_REG
   860c8:	58000201 	ldr	x1, 86108 <uart_send_va+0x24>
	ldr w2, [x1]
   860cc:	b9400022 	ldr	w2, [x1]
	and w2, w2, #0x20
   860d0:	121b0042 	and	w2, w2, #0x20
	cbz w2, 1b
   860d4:	34ffffa2 	cbz	w2, 860c8 <uart_send_pa>
	ldr x1, =AUX_MU_IO_REG
   860d8:	580001c1 	ldr	x1, 86110 <uart_send_va+0x2c>
	str w0, [x1]
   860dc:	b9000020 	str	w0, [x1]
	ret 
   860e0:	d65f03c0 	ret

00000000000860e4 <uart_send_va>:

// NB: must write 32, not 64
.globl uart_send_va
uart_send_va:
1:
	ldr x4, =VA_START
   860e4:	580001a4 	ldr	x4, 86118 <uart_send_va+0x34>
	ldr x1, =AUX_MU_LSR_REG
   860e8:	58000101 	ldr	x1, 86108 <uart_send_va+0x24>
	ldr w2, [x1, x4]
   860ec:	b8646822 	ldr	w2, [x1, x4]
	and w2, w2, #0x20
   860f0:	121b0042 	and	w2, w2, #0x20
	cbz w2, 1b
   860f4:	34ffff82 	cbz	w2, 860e4 <uart_send_va>
	ldr x1, =AUX_MU_IO_REG
   860f8:	580000c1 	ldr	x1, 86110 <uart_send_va+0x2c>
	str w0, [x1, x4]
   860fc:	b8246820 	str	w0, [x1, x4]
   86100:	d65f03c0 	ret
   86104:	00000000 	udf	#0
   86108:	3f215054 	.word	0x3f215054
   8610c:	00000000 	.word	0x00000000
   86110:	3f215040 	.word	0x3f215040
	...
   8611c:	ffff0000 	.word	0xffff0000
