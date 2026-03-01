
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
   800a8:	00095f20 	.word	0x00095f20
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
   808c0:	94000356 	bl	81618 <tfp_printf>
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
   808dc:	1400041f 	b	81958 <assertion_failed>
        irq &= (~GENERIC_TIMER_INTERRUPT);
   808e0:	121e7a93 	and	w19, w20, #0xfffffffd
        handle_generic_timer_irq();
   808e4:	94000589 	bl	81f08 <handle_generic_timer_irq>
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
   80900:	9400062c 	bl	821b0 <sys_timer_irq>
        if (p1) {
   80904:	34fffbb5 	cbz	w21, 80878 <handle_irq+0x48>
            E("unknown pending irq in IRQ_PENDING_1 p1 %08x", p1); 
   80908:	2a1503e3 	mov	w3, w21
   8090c:	d0000033 	adrp	x19, 86000 <__asm_dcache_level+0xc>
   80910:	d0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   80914:	910a8261 	add	x1, x19, #0x2a0
   80918:	910aa000 	add	x0, x0, #0x2a8
   8091c:	52800bc2 	mov	w2, #0x5e                  	// #94
   80920:	9400033e 	bl	81618 <tfp_printf>
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
   80934:	b00000a4 	adrp	x4, 95000 <wordsworth.1722+0xee10>
   80938:	91360084 	add	x4, x4, #0xd80
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
   8098c:	94000323 	bl	81618 <tfp_printf>
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
   809bc:	14000317 	b	81618 <tfp_printf>

00000000000809c0 <kernel_main>:
extern void donut(int x, int y); 	//donut.c

struct cpu cpus[NCPU]; 

// Q3: quest "two preemptive printers"
void kernel_main() {
   809c0:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   809c4:	910003fd 	mov	x29, sp
	uart_init();
   809c8:	94001084 	bl	84bd8 <uart_init>
	init_printf(NULL, putc);	
   809cc:	b00000a1 	adrp	x1, 95000 <wordsworth.1722+0xee10>
   809d0:	d2800000 	mov	x0, #0x0                   	// #0
   809d4:	f9476421 	ldr	x1, [x1, #3784]
   809d8:	9400030a 	bl	81600 <init_printf>
	printf("------ kernel boot ------  core %d\n\r", cpuid());
   809dc:	9400154b 	bl	85f08 <cpuid>
   809e0:	2a0003e1 	mov	w1, w0
   809e4:	d0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   809e8:	91150000 	add	x0, x0, #0x540
   809ec:	9400030b 	bl	81618 <tfp_printf>
	printf("build time (kernel.c) %s %s\n", __DATE__, __TIME__); // simplicity 
   809f0:	d0000022 	adrp	x2, 86000 <__asm_dcache_level+0xc>
   809f4:	d0000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   809f8:	9115a042 	add	x2, x2, #0x568
   809fc:	9115e021 	add	x1, x1, #0x578
   80a00:	d0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   80a04:	91162000 	add	x0, x0, #0x588
   80a08:	94000304 	bl	81618 <tfp_printf>
			
	paging_init(); 
   80a0c:	94000b09 	bl	83630 <paging_init>
	sched_init(); 	// must be before schedule() or timertick() 
   80a10:	94000b90 	bl	83850 <sched_init>
	fb_init(); 		// reserve fb memory other page allocations
   80a14:	940007f9 	bl	829f8 <fb_init>
	sys_timer_init(); 		// kernel timer: delay, timekeeping...
   80a18:	94000564 	bl	81fa8 <sys_timer_init>
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
   80a28:	94000532 	bl	81ef0 <generic_timer_init>
	
	
	/* now cpu is on its boot stack (boot.S) belonging to the idle task. 
	schedule() will jump off to kernel stacks belonging to normal tasks
	(i.e. init_task as set up in sched_init(), sched.c) */
	schedule(); 
   80a2c:	94000c05 	bl	83a40 <schedule>
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
   80a40:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
	int wpid; 
    W("entering init");
   80a44:	d0000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   80a48:	d0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
void init(int arg/*ignored*/) {
   80a4c:	910003fd 	mov	x29, sp
    W("entering init");
   80a50:	9116a021 	add	x1, x1, #0x5a8
   80a54:	9116e000 	add	x0, x0, #0x5b8
void init(int arg/*ignored*/) {
   80a58:	a90153f3 	stp	x19, x20, [sp, #16]
   80a5c:	d0000034 	adrp	x20, 86000 <__asm_dcache_level+0xc>
	// test_kern_reader_writer(); 

	while (1) {
		wpid = wait(0 /* does not care about status */); 
		if (wpid < 0) {
			W("init: wait failed with %d", wpid);
   80a60:	91178294 	add	x20, x20, #0x5e0
void init(int arg/*ignored*/) {
   80a64:	a9025bf5 	stp	x21, x22, [sp, #32]
   80a68:	d0000036 	adrp	x22, 86000 <__asm_dcache_level+0xc>
			panic("init: maybe no child. has nothing to do. bye"); 
		} else {
			W("wait returns pid=%d", wpid);
   80a6c:	911902d6 	add	x22, x22, #0x640
    W("entering init");
   80a70:	528007a2 	mov	w2, #0x3d                  	// #61
   80a74:	d0000035 	adrp	x21, 86000 <__asm_dcache_level+0xc>
			W("wait returns pid=%d", wpid);
   80a78:	aa0103f3 	mov	x19, x1
    W("entering init");
   80a7c:	940002e7 	bl	81618 <tfp_printf>
	test_kern_tasks_donut();
   80a80:	94001004 	bl	84a90 <test_kern_tasks_donut>
   80a84:	d503201f 	nop
		wpid = wait(0 /* does not care about status */); 
   80a88:	d2800000 	mov	x0, #0x0                   	// #0
   80a8c:	94000ce9 	bl	83e30 <wait>
			W("init: wait failed with %d", wpid);
   80a90:	aa1303e1 	mov	x1, x19
		wpid = wait(0 /* does not care about status */); 
   80a94:	2a0003e3 	mov	w3, w0
			W("init: wait failed with %d", wpid);
   80a98:	52800942 	mov	w2, #0x4a                  	// #74
   80a9c:	aa1403e0 	mov	x0, x20
		if (wpid < 0) {
   80aa0:	36f80163 	tbz	w3, #31, 80acc <init+0x8c>
			W("init: wait failed with %d", wpid);
   80aa4:	940002dd 	bl	81618 <tfp_printf>
			panic("init: maybe no child. has nothing to do. bye"); 
   80aa8:	911842a0 	add	x0, x21, #0x610
   80aac:	94000361 	bl	81830 <panic>
		wpid = wait(0 /* does not care about status */); 
   80ab0:	d2800000 	mov	x0, #0x0                   	// #0
   80ab4:	94000cdf 	bl	83e30 <wait>
			W("init: wait failed with %d", wpid);
   80ab8:	aa1303e1 	mov	x1, x19
		wpid = wait(0 /* does not care about status */); 
   80abc:	2a0003e3 	mov	w3, w0
			W("init: wait failed with %d", wpid);
   80ac0:	52800942 	mov	w2, #0x4a                  	// #74
   80ac4:	aa1403e0 	mov	x0, x20
		if (wpid < 0) {
   80ac8:	37fffee3 	tbnz	w3, #31, 80aa4 <init+0x64>
			W("wait returns pid=%d", wpid);
   80acc:	aa1603e0 	mov	x0, x22
   80ad0:	528009a2 	mov	w2, #0x4d                  	// #77
   80ad4:	940002d1 	bl	81618 <tfp_printf>
   80ad8:	17ffffec 	b	80a88 <init+0x48>
   80adc:	00000000 	udf	#0

0000000000080ae0 <ulli2a>:
    unsigned long long int num, struct param *p)
{
    int n = 0;
    unsigned long long int d = 1;
    char *bf = p->bf;
    while (num / d >= p->base)
   80ae0:	b9400c26 	ldr	w6, [x1, #12]
    char *bf = p->bf;
   80ae4:	f9400829 	ldr	x9, [x1, #16]
    while (num / d >= p->base)
   80ae8:	2a0603e4 	mov	w4, w6
   80aec:	eb26401f 	cmp	x0, w6, uxtw
   80af0:	54000583 	b.cc	80ba0 <ulli2a+0xc0>  // b.lo, b.ul, b.last
    unsigned long long int d = 1;
   80af4:	d2800022 	mov	x2, #0x1                   	// #1
        d *= p->base;
   80af8:	9b047c42 	mul	x2, x2, x4
    while (num / d >= p->base)
   80afc:	9ac20803 	udiv	x3, x0, x2
   80b00:	eb04007f 	cmp	x3, x4
   80b04:	54ffffa2 	b.cs	80af8 <ulli2a+0x18>  // b.hs, b.nlast
    while (d != 0) {
   80b08:	b4000462 	cbz	x2, 80b94 <ulli2a+0xb4>
    int n = 0;
   80b0c:	52800007 	mov	w7, #0x0                   	// #0
        int dgt = num / d;
        num %= d;
        d /= p->base;
        if (n || dgt > 0 || d == 0) {
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80b10:	528006eb 	mov	w11, #0x37                  	// #55
   80b14:	52800aea 	mov	w10, #0x57                  	// #87
        if (n || dgt > 0 || d == 0) {
   80b18:	710000ff 	cmp	w7, #0x0
        num %= d;
   80b1c:	9b028060 	msub	x0, x3, x2, x0
        d /= p->base;
   80b20:	9ac40848 	udiv	x8, x2, x4
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80b24:	aa0903e5 	mov	x5, x9
        if (n || dgt > 0 || d == 0) {
   80b28:	7a400860 	ccmp	w3, #0x0, #0x0, eq  // eq = none
   80b2c:	540000ec 	b.gt	80b48 <ulli2a+0x68>
   80b30:	eb02009f 	cmp	x4, x2
   80b34:	540002c9 	b.ls	80b8c <ulli2a+0xac>  // b.plast
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80b38:	1100c063 	add	w3, w3, #0x30
   80b3c:	380014a3 	strb	w3, [x5], #1
            ++n;
        }
    }
    *bf = 0;
   80b40:	390000bf 	strb	wzr, [x5]
}
   80b44:	d65f03c0 	ret
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80b48:	7100247f 	cmp	w3, #0x9
   80b4c:	52800606 	mov	w6, #0x30                  	// #48
   80b50:	5400008d 	b.le	80b60 <ulli2a+0x80>
   80b54:	39400026 	ldrb	w6, [x1]
   80b58:	f27e00df 	tst	x6, #0x4
   80b5c:	1a8a1166 	csel	w6, w11, w10, ne  // ne = any
   80b60:	0b0300c3 	add	w3, w6, w3
   80b64:	380014a3 	strb	w3, [x5], #1
            ++n;
   80b68:	110004e7 	add	w7, w7, #0x1
    while (d != 0) {
   80b6c:	eb02009f 	cmp	x4, x2
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80b70:	aa0503e9 	mov	x9, x5
    while (d != 0) {
   80b74:	54fffe68 	b.hi	80b40 <ulli2a+0x60>  // b.pmore
   80b78:	b9400c26 	ldr	w6, [x1, #12]
   80b7c:	9ac80803 	udiv	x3, x0, x8
   80b80:	2a0603e4 	mov	w4, w6
    int n = 0;
   80b84:	aa0803e2 	mov	x2, x8
   80b88:	17ffffe4 	b	80b18 <ulli2a+0x38>
   80b8c:	52800007 	mov	w7, #0x0                   	// #0
   80b90:	17fffffb 	b	80b7c <ulli2a+0x9c>
    char *bf = p->bf;
   80b94:	aa0903e5 	mov	x5, x9
    *bf = 0;
   80b98:	390000bf 	strb	wzr, [x5]
}
   80b9c:	d65f03c0 	ret
   80ba0:	aa0003e3 	mov	x3, x0
    unsigned long long int d = 1;
   80ba4:	d2800022 	mov	x2, #0x1                   	// #1
   80ba8:	17ffffd9 	b	80b0c <ulli2a+0x2c>
   80bac:	d503201f 	nop

0000000000080bb0 <uli2a>:
static void uli2a(unsigned long int num, struct param *p)
{
    int n = 0;
    unsigned long int d = 1;
    char *bf = p->bf;
    while (num / d >= p->base)
   80bb0:	b9400c26 	ldr	w6, [x1, #12]
    char *bf = p->bf;
   80bb4:	f9400829 	ldr	x9, [x1, #16]
    while (num / d >= p->base)
   80bb8:	2a0603e4 	mov	w4, w6
   80bbc:	eb26401f 	cmp	x0, w6, uxtw
   80bc0:	54000583 	b.cc	80c70 <uli2a+0xc0>  // b.lo, b.ul, b.last
    unsigned long int d = 1;
   80bc4:	d2800022 	mov	x2, #0x1                   	// #1
        d *= p->base;
   80bc8:	9b047c42 	mul	x2, x2, x4
    while (num / d >= p->base)
   80bcc:	9ac20803 	udiv	x3, x0, x2
   80bd0:	eb04007f 	cmp	x3, x4
   80bd4:	54ffffa2 	b.cs	80bc8 <uli2a+0x18>  // b.hs, b.nlast
    while (d != 0) {
   80bd8:	b4000462 	cbz	x2, 80c64 <uli2a+0xb4>
    int n = 0;
   80bdc:	52800007 	mov	w7, #0x0                   	// #0
        int dgt = num / d;
        num %= d;
        d /= p->base;
        if (n || dgt > 0 || d == 0) {
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80be0:	528006eb 	mov	w11, #0x37                  	// #55
   80be4:	52800aea 	mov	w10, #0x57                  	// #87
        if (n || dgt > 0 || d == 0) {
   80be8:	710000ff 	cmp	w7, #0x0
        num %= d;
   80bec:	9b028060 	msub	x0, x3, x2, x0
        d /= p->base;
   80bf0:	9ac40848 	udiv	x8, x2, x4
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80bf4:	aa0903e5 	mov	x5, x9
        if (n || dgt > 0 || d == 0) {
   80bf8:	7a400860 	ccmp	w3, #0x0, #0x0, eq  // eq = none
   80bfc:	540000ec 	b.gt	80c18 <uli2a+0x68>
   80c00:	eb02009f 	cmp	x4, x2
   80c04:	540002c9 	b.ls	80c5c <uli2a+0xac>  // b.plast
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80c08:	1100c063 	add	w3, w3, #0x30
   80c0c:	380014a3 	strb	w3, [x5], #1
            ++n;
        }
    }
    *bf = 0;
   80c10:	390000bf 	strb	wzr, [x5]
}
   80c14:	d65f03c0 	ret
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80c18:	7100247f 	cmp	w3, #0x9
   80c1c:	52800606 	mov	w6, #0x30                  	// #48
   80c20:	5400008d 	b.le	80c30 <uli2a+0x80>
   80c24:	39400026 	ldrb	w6, [x1]
   80c28:	f27e00df 	tst	x6, #0x4
   80c2c:	1a8a1166 	csel	w6, w11, w10, ne  // ne = any
   80c30:	0b0300c3 	add	w3, w6, w3
   80c34:	380014a3 	strb	w3, [x5], #1
            ++n;
   80c38:	110004e7 	add	w7, w7, #0x1
    while (d != 0) {
   80c3c:	eb02009f 	cmp	x4, x2
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80c40:	aa0503e9 	mov	x9, x5
    while (d != 0) {
   80c44:	54fffe68 	b.hi	80c10 <uli2a+0x60>  // b.pmore
   80c48:	b9400c26 	ldr	w6, [x1, #12]
   80c4c:	9ac80803 	udiv	x3, x0, x8
   80c50:	2a0603e4 	mov	w4, w6
    int n = 0;
   80c54:	aa0803e2 	mov	x2, x8
   80c58:	17ffffe4 	b	80be8 <uli2a+0x38>
   80c5c:	52800007 	mov	w7, #0x0                   	// #0
   80c60:	17fffffb 	b	80c4c <uli2a+0x9c>
    char *bf = p->bf;
   80c64:	aa0903e5 	mov	x5, x9
    *bf = 0;
   80c68:	390000bf 	strb	wzr, [x5]
}
   80c6c:	d65f03c0 	ret
   80c70:	aa0003e3 	mov	x3, x0
    unsigned long int d = 1;
   80c74:	d2800022 	mov	x2, #0x1                   	// #1
   80c78:	17ffffd9 	b	80bdc <uli2a+0x2c>
   80c7c:	d503201f 	nop

0000000000080c80 <ui2a>:
static void ui2a(unsigned int num, struct param *p)
{
    int n = 0;
    unsigned int d = 1;
    char *bf = p->bf;
    while (num / d >= p->base)
   80c80:	b9400c24 	ldr	w4, [x1, #12]
    char *bf = p->bf;
   80c84:	f9400826 	ldr	x6, [x1, #16]
    while (num / d >= p->base)
   80c88:	6b04001f 	cmp	w0, w4
   80c8c:	54000583 	b.cc	80d3c <ui2a+0xbc>  // b.lo, b.ul, b.last
    unsigned int d = 1;
   80c90:	52800022 	mov	w2, #0x1                   	// #1
   80c94:	d503201f 	nop
        d *= p->base;
   80c98:	1b047c42 	mul	w2, w2, w4
    while (num / d >= p->base)
   80c9c:	1ac20803 	udiv	w3, w0, w2
   80ca0:	6b04007f 	cmp	w3, w4
   80ca4:	54ffffa2 	b.cs	80c98 <ui2a+0x18>  // b.hs, b.nlast
    while (d != 0) {
   80ca8:	34000442 	cbz	w2, 80d30 <ui2a+0xb0>
    int n = 0;
   80cac:	52800007 	mov	w7, #0x0                   	// #0
        int dgt = num / d;
        num %= d;
        d /= p->base;
        if (n || dgt > 0 || d == 0) {
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80cb0:	528006ea 	mov	w10, #0x37                  	// #55
   80cb4:	52800ae9 	mov	w9, #0x57                  	// #87
        if (n || dgt > 0 || d == 0) {
   80cb8:	710000ff 	cmp	w7, #0x0
        num %= d;
   80cbc:	1b028060 	msub	w0, w3, w2, w0
        d /= p->base;
   80cc0:	1ac40848 	udiv	w8, w2, w4
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80cc4:	aa0603e5 	mov	x5, x6
        if (n || dgt > 0 || d == 0) {
   80cc8:	7a400860 	ccmp	w3, #0x0, #0x0, eq  // eq = none
   80ccc:	540000ec 	b.gt	80ce8 <ui2a+0x68>
   80cd0:	6b04005f 	cmp	w2, w4
   80cd4:	540002a2 	b.cs	80d28 <ui2a+0xa8>  // b.hs, b.nlast
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80cd8:	1100c063 	add	w3, w3, #0x30
   80cdc:	380014a3 	strb	w3, [x5], #1
            ++n;
        }
    }
    *bf = 0;
   80ce0:	390000bf 	strb	wzr, [x5]
}
   80ce4:	d65f03c0 	ret
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80ce8:	7100247f 	cmp	w3, #0x9
   80cec:	52800606 	mov	w6, #0x30                  	// #48
   80cf0:	5400008d 	b.le	80d00 <ui2a+0x80>
   80cf4:	39400026 	ldrb	w6, [x1]
   80cf8:	f27e00df 	tst	x6, #0x4
   80cfc:	1a891146 	csel	w6, w10, w9, ne  // ne = any
   80d00:	0b0300c3 	add	w3, w6, w3
   80d04:	380014a3 	strb	w3, [x5], #1
            ++n;
   80d08:	110004e7 	add	w7, w7, #0x1
    while (d != 0) {
   80d0c:	6b04005f 	cmp	w2, w4
            *bf++ = dgt + (dgt < 10 ? '0' : (p->uc ? 'A' : 'a') - 10);
   80d10:	aa0503e6 	mov	x6, x5
    while (d != 0) {
   80d14:	54fffe63 	b.cc	80ce0 <ui2a+0x60>  // b.lo, b.ul, b.last
   80d18:	b9400c24 	ldr	w4, [x1, #12]
   80d1c:	1ac80803 	udiv	w3, w0, w8
    int n = 0;
   80d20:	2a0803e2 	mov	w2, w8
   80d24:	17ffffe5 	b	80cb8 <ui2a+0x38>
   80d28:	52800007 	mov	w7, #0x0                   	// #0
   80d2c:	17fffffc 	b	80d1c <ui2a+0x9c>
    char *bf = p->bf;
   80d30:	aa0603e5 	mov	x5, x6
    *bf = 0;
   80d34:	390000bf 	strb	wzr, [x5]
}
   80d38:	d65f03c0 	ret
   80d3c:	2a0003e3 	mov	w3, w0
    unsigned int d = 1;
   80d40:	52800022 	mov	w2, #0x1                   	// #1
   80d44:	17ffffda 	b	80cac <ui2a+0x2c>

0000000000080d48 <putchw>:
    *nump = num;
    return ch;
}

static void putchw(void *putp, putcf putf, struct param *p)
{
   80d48:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
   80d4c:	910003fd 	mov	x29, sp
   80d50:	a90153f3 	stp	x19, x20, [sp, #16]
   80d54:	aa0003f4 	mov	x20, x0
    char ch;
    int n = p->width;
   80d58:	b9400453 	ldr	w19, [x2, #4]
    char *bf = p->bf;

    /* Number of filling characters */
    while (*bf++ && n > 0)
   80d5c:	f9400840 	ldr	x0, [x2, #16]
{
   80d60:	a9025bf5 	stp	x21, x22, [sp, #32]
   80d64:	aa0103f5 	mov	x21, x1
   80d68:	f9001bf7 	str	x23, [sp, #48]
   80d6c:	aa0203f7 	mov	x23, x2
    while (*bf++ && n > 0)
   80d70:	38401401 	ldrb	w1, [x0], #1
   80d74:	7100003f 	cmp	w1, #0x0
   80d78:	7a401a64 	ccmp	w19, #0x0, #0x4, ne  // ne = any
   80d7c:	540000cd 	b.le	80d94 <putchw+0x4c>
   80d80:	38401401 	ldrb	w1, [x0], #1
        n--;
   80d84:	51000673 	sub	w19, w19, #0x1
    while (*bf++ && n > 0)
   80d88:	7100003f 	cmp	w1, #0x0
   80d8c:	7a401a64 	ccmp	w19, #0x0, #0x4, ne  // ne = any
   80d90:	54ffff8c 	b.gt	80d80 <putchw+0x38>
    if (p->sign)
   80d94:	394022e1 	ldrb	w1, [x23, #8]
        n--;
    if (p->alt && p->base == 16)
   80d98:	394002e0 	ldrb	w0, [x23]
        n--;
   80d9c:	7100003f 	cmp	w1, #0x0
   80da0:	1a9f07e2 	cset	w2, ne  // ne = any
   80da4:	4b020273 	sub	w19, w19, w2
    if (p->alt && p->base == 16)
   80da8:	360800e0 	tbz	w0, #1, 80dc4 <putchw+0x7c>
   80dac:	b9400ee2 	ldr	w2, [x23, #12]
   80db0:	7100405f 	cmp	w2, #0x10
   80db4:	54000a80 	b.eq	80f04 <putchw+0x1bc>  // b.none
        n -= 2;
    else if (p->alt && p->base == 8)
        n--;
   80db8:	7100205f 	cmp	w2, #0x8
   80dbc:	1a9f17e2 	cset	w2, eq  // eq = none
   80dc0:	4b020273 	sub	w19, w19, w2

    /* Fill with space to align to the right, before alternate or sign */
    if (!p->lz && !p->align_left) {
   80dc4:	52800122 	mov	w2, #0x9                   	// #9
   80dc8:	6a02001f 	tst	w0, w2
   80dcc:	54000181 	b.ne	80dfc <putchw+0xb4>  // b.any
        while (n-- > 0)
   80dd0:	7100027f 	cmp	w19, #0x0
   80dd4:	51000673 	sub	w19, w19, #0x1
   80dd8:	5400012d 	b.le	80dfc <putchw+0xb4>
   80ddc:	d503201f 	nop
   80de0:	51000673 	sub	w19, w19, #0x1
            putf(putp, ' ');
   80de4:	aa1403e0 	mov	x0, x20
   80de8:	52800401 	mov	w1, #0x20                  	// #32
   80dec:	d63f02a0 	blr	x21
        while (n-- > 0)
   80df0:	3100067f 	cmn	w19, #0x1
   80df4:	54ffff61 	b.ne	80de0 <putchw+0x98>  // b.any
   80df8:	394022e1 	ldrb	w1, [x23, #8]
    }

    /* print sign */
    if (p->sign)
   80dfc:	34000061 	cbz	w1, 80e08 <putchw+0xc0>
        putf(putp, p->sign);
   80e00:	aa1403e0 	mov	x0, x20
   80e04:	d63f02a0 	blr	x21

    /* Alternate */
    if (p->alt && p->base == 16) {
   80e08:	394002e0 	ldrb	w0, [x23]
   80e0c:	360800c0 	tbz	w0, #1, 80e24 <putchw+0xdc>
   80e10:	b9400ee1 	ldr	w1, [x23, #12]
   80e14:	7100403f 	cmp	w1, #0x10
   80e18:	540005e0 	b.eq	80ed4 <putchw+0x18c>  // b.none
        putf(putp, '0');
        putf(putp, (p->uc ? 'X' : 'x'));
    } else if (p->alt && p->base == 8) {
   80e1c:	7100203f 	cmp	w1, #0x8
   80e20:	54000760 	b.eq	80f0c <putchw+0x1c4>  // b.none
        putf(putp, '0');
    }

    /* Fill with zeros, after alternate or sign */
    if (p->lz) {
   80e24:	36000160 	tbz	w0, #0, 80e50 <putchw+0x108>
        while (n-- > 0)
   80e28:	7100027f 	cmp	w19, #0x0
   80e2c:	51000673 	sub	w19, w19, #0x1
   80e30:	5400010d 	b.le	80e50 <putchw+0x108>
   80e34:	d503201f 	nop
   80e38:	51000673 	sub	w19, w19, #0x1
            putf(putp, '0');
   80e3c:	aa1403e0 	mov	x0, x20
   80e40:	52800601 	mov	w1, #0x30                  	// #48
   80e44:	d63f02a0 	blr	x21
        while (n-- > 0)
   80e48:	3100067f 	cmn	w19, #0x1
   80e4c:	54ffff61 	b.ne	80e38 <putchw+0xf0>  // b.any
    }

    /* Put actual buffer */
    bf = p->bf;
    while ((ch = *bf++))
   80e50:	f9400af6 	ldr	x22, [x23, #16]
   80e54:	384016c1 	ldrb	w1, [x22], #1
   80e58:	340000c1 	cbz	w1, 80e70 <putchw+0x128>
   80e5c:	d503201f 	nop
        putf(putp, ch);
   80e60:	aa1403e0 	mov	x0, x20
   80e64:	d63f02a0 	blr	x21
    while ((ch = *bf++))
   80e68:	384016c1 	ldrb	w1, [x22], #1
   80e6c:	35ffffa1 	cbnz	w1, 80e60 <putchw+0x118>

    /* Fill with space to align to the left, after string */
    if (!p->lz && p->align_left) {
   80e70:	394002e1 	ldrb	w1, [x23]
   80e74:	52800120 	mov	w0, #0x9                   	// #9
   80e78:	0a010000 	and	w0, w0, w1
   80e7c:	7100201f 	cmp	w0, #0x8
   80e80:	540000c0 	b.eq	80e98 <putchw+0x150>  // b.none
        while (n-- > 0)
            putf(putp, ' ');
    }
}
   80e84:	a94153f3 	ldp	x19, x20, [sp, #16]
   80e88:	a9425bf5 	ldp	x21, x22, [sp, #32]
   80e8c:	f9401bf7 	ldr	x23, [sp, #48]
   80e90:	a8c47bfd 	ldp	x29, x30, [sp], #64
   80e94:	d65f03c0 	ret
        while (n-- > 0)
   80e98:	7100027f 	cmp	w19, #0x0
   80e9c:	51000673 	sub	w19, w19, #0x1
   80ea0:	54ffff2d 	b.le	80e84 <putchw+0x13c>
   80ea4:	d503201f 	nop
   80ea8:	51000673 	sub	w19, w19, #0x1
            putf(putp, ' ');
   80eac:	aa1403e0 	mov	x0, x20
   80eb0:	52800401 	mov	w1, #0x20                  	// #32
   80eb4:	d63f02a0 	blr	x21
        while (n-- > 0)
   80eb8:	3100067f 	cmn	w19, #0x1
   80ebc:	54ffff61 	b.ne	80ea8 <putchw+0x160>  // b.any
}
   80ec0:	a94153f3 	ldp	x19, x20, [sp, #16]
   80ec4:	a9425bf5 	ldp	x21, x22, [sp, #32]
   80ec8:	f9401bf7 	ldr	x23, [sp, #48]
   80ecc:	a8c47bfd 	ldp	x29, x30, [sp], #64
   80ed0:	d65f03c0 	ret
        putf(putp, '0');
   80ed4:	aa1403e0 	mov	x0, x20
   80ed8:	52800601 	mov	w1, #0x30                  	// #48
   80edc:	d63f02a0 	blr	x21
        putf(putp, (p->uc ? 'X' : 'x'));
   80ee0:	394002e3 	ldrb	w3, [x23]
   80ee4:	52800b02 	mov	w2, #0x58                  	// #88
   80ee8:	aa1403e0 	mov	x0, x20
   80eec:	52800f01 	mov	w1, #0x78                  	// #120
   80ef0:	f27e007f 	tst	x3, #0x4
   80ef4:	1a811041 	csel	w1, w2, w1, ne  // ne = any
   80ef8:	d63f02a0 	blr	x21
   80efc:	394002e0 	ldrb	w0, [x23]
   80f00:	17ffffc9 	b	80e24 <putchw+0xdc>
        n -= 2;
   80f04:	51000a73 	sub	w19, w19, #0x2
   80f08:	17ffffaf 	b	80dc4 <putchw+0x7c>
        putf(putp, '0');
   80f0c:	aa1403e0 	mov	x0, x20
   80f10:	52800601 	mov	w1, #0x30                  	// #48
   80f14:	d63f02a0 	blr	x21
   80f18:	394002e0 	ldrb	w0, [x23]
   80f1c:	17ffffc2 	b	80e24 <putchw+0xdc>

0000000000080f20 <_vsnprintf_putcf>:
};

static void _vsnprintf_putcf(void *p, char c)
{
  struct _vsnprintf_putcf_data *data = (struct _vsnprintf_putcf_data*)p;
  if (data->num_chars < data->dest_capacity)
   80f20:	f9400003 	ldr	x3, [x0]
{
   80f24:	12001c21 	and	w1, w1, #0xff
  if (data->num_chars < data->dest_capacity)
   80f28:	f9400802 	ldr	x2, [x0, #16]
   80f2c:	eb03005f 	cmp	x2, x3
   80f30:	54000082 	b.cs	80f40 <_vsnprintf_putcf+0x20>  // b.hs, b.nlast
    data->dest[data->num_chars] = c;
   80f34:	f9400403 	ldr	x3, [x0, #8]
   80f38:	38226861 	strb	w1, [x3, x2]
   80f3c:	f9400802 	ldr	x2, [x0, #16]
  data->num_chars ++;
   80f40:	91000442 	add	x2, x2, #0x1
   80f44:	f9000802 	str	x2, [x0, #16]
}
   80f48:	d65f03c0 	ret
   80f4c:	d503201f 	nop

0000000000080f50 <_vsprintf_putcf>:
};

static void _vsprintf_putcf(void *p, char c)
{
  struct _vsprintf_putcf_data *data = (struct _vsprintf_putcf_data*)p;
  data->dest[data->num_chars++] = c;
   80f50:	a9400803 	ldp	x3, x2, [x0]
   80f54:	91000444 	add	x4, x2, #0x1
   80f58:	f9000404 	str	x4, [x0, #8]
   80f5c:	38226861 	strb	w1, [x3, x2]
}
   80f60:	d65f03c0 	ret
   80f64:	d503201f 	nop

0000000000080f68 <tfp_format>:
{
   80f68:	a9b67bfd 	stp	x29, x30, [sp, #-160]!
   80f6c:	910003fd 	mov	x29, sp
   80f70:	a90573fb 	stp	x27, x28, [sp, #80]
    while ((ch = *(fmt++))) {
   80f74:	aa0203fb 	mov	x27, x2
{
   80f78:	a90153f3 	stp	x19, x20, [sp, #16]
   80f7c:	aa0103f4 	mov	x20, x1
   80f80:	aa0003f3 	mov	x19, x0
   80f84:	a9025bf5 	stp	x21, x22, [sp, #32]
   80f88:	b9401876 	ldr	w22, [x3, #24]
   80f8c:	a9046bf9 	stp	x25, x26, [sp, #64]
    p.bf = bf;
   80f90:	9101c3f9 	add	x25, sp, #0x70
    while ((ch = *(fmt++))) {
   80f94:	38401761 	ldrb	w1, [x27], #1
   80f98:	a9400075 	ldp	x21, x0, [x3]
   80f9c:	f90037e0 	str	x0, [sp, #104]
    p.bf = bf;
   80fa0:	f9004ff9 	str	x25, [sp, #152]
    while ((ch = *(fmt++))) {
   80fa4:	34000a81 	cbz	w1, 810f4 <tfp_format+0x18c>
                p.base = 10;
   80fa8:	5280015a 	mov	w26, #0xa                   	// #10
   80fac:	a90363f7 	stp	x23, x24, [sp, #48]
    ui2a(num, p);
   80fb0:	910223f7 	add	x23, sp, #0x88
            p.lz = 0;
   80fb4:	12800178 	mov	w24, #0xfffffff4            	// #-12
   80fb8:	14000008 	b	80fd8 <tfp_format+0x70>
            putf(putp, ch);
   80fbc:	aa1303e0 	mov	x0, x19
   80fc0:	d63f0280 	blr	x20
   80fc4:	aa1c03e0 	mov	x0, x28
   80fc8:	aa1b03fc 	mov	x28, x27
   80fcc:	aa0003fb 	mov	x27, x0
    while ((ch = *(fmt++))) {
   80fd0:	39400381 	ldrb	w1, [x28]
   80fd4:	340008e1 	cbz	w1, 810f0 <tfp_format+0x188>
        if (ch != '%') {
   80fd8:	7100943f 	cmp	w1, #0x25
   80fdc:	9100077c 	add	x28, x27, #0x1
   80fe0:	54fffee1 	b.ne	80fbc <tfp_format+0x54>  // b.any
            p.lz = 0;
   80fe4:	394223e0 	ldrb	w0, [sp, #136]
            while ((ch = *(fmt++))) {
   80fe8:	39400363 	ldrb	w3, [x27]
            p.lz = 0;
   80fec:	0a180000 	and	w0, w0, w24
   80ff0:	390223e0 	strb	w0, [sp, #136]
            p.width = 0;
   80ff4:	b9008fff 	str	wzr, [sp, #140]
            p.sign = 0;
   80ff8:	390243ff 	strb	wzr, [sp, #144]
            while ((ch = *(fmt++))) {
   80ffc:	340007a3 	cbz	w3, 810f0 <tfp_format+0x188>
   81000:	52800002 	mov	w2, #0x0                   	// #0
   81004:	52800001 	mov	w1, #0x0                   	// #0
   81008:	52800000 	mov	w0, #0x0                   	// #0
                switch (ch) {
   8100c:	7100b47f 	cmp	w3, #0x2d
   81010:	54000f00 	b.eq	811f0 <tfp_format+0x288>  // b.none
   81014:	7100c07f 	cmp	w3, #0x30
   81018:	540009e0 	b.eq	81154 <tfp_format+0x1ec>  // b.none
   8101c:	71008c7f 	cmp	w3, #0x23
   81020:	54000760 	b.eq	8110c <tfp_format+0x1a4>  // b.none
   81024:	34000080 	cbz	w0, 81034 <tfp_format+0xcc>
   81028:	394223e0 	ldrb	w0, [sp, #136]
   8102c:	321d0000 	orr	w0, w0, #0x8
   81030:	390223e0 	strb	w0, [sp, #136]
   81034:	34000081 	cbz	w1, 81044 <tfp_format+0xdc>
   81038:	394223e0 	ldrb	w0, [sp, #136]
   8103c:	32000000 	orr	w0, w0, #0x1
   81040:	390223e0 	strb	w0, [sp, #136]
   81044:	34000082 	cbz	w2, 81054 <tfp_format+0xec>
   81048:	394223e0 	ldrb	w0, [sp, #136]
   8104c:	321f0000 	orr	w0, w0, #0x2
   81050:	390223e0 	strb	w0, [sp, #136]
            if (ch >= '0' && ch <= '9') {
   81054:	5100c066 	sub	w6, w3, #0x30
   81058:	12001cc0 	and	w0, w6, #0xff
   8105c:	7100241f 	cmp	w0, #0x9
   81060:	54001209 	b.ls	812a0 <tfp_format+0x338>  // b.plast
            if (ch == '.') {
   81064:	7100b87f 	cmp	w3, #0x2e
   81068:	54001540 	b.eq	81310 <tfp_format+0x3a8>  // b.none
            if (ch == 'z') {
   8106c:	7101e87f 	cmp	w3, #0x7a
   81070:	540010e0 	b.eq	8128c <tfp_format+0x324>  // b.none
            if (ch == 'l') {
   81074:	7101b07f 	cmp	w3, #0x6c
   81078:	54001600 	b.eq	81338 <tfp_format+0x3d0>  // b.none
            switch (ch) {
   8107c:	7101a47f 	cmp	w3, #0x69
   81080:	54002640 	b.eq	81548 <tfp_format+0x5e0>  // b.none
            char lng = 0;  /* 1 for long, 2 for long long */
   81084:	52800000 	mov	w0, #0x0                   	// #0
            switch (ch) {
   81088:	7101a47f 	cmp	w3, #0x69
   8108c:	54000b69 	b.ls	811f8 <tfp_format+0x290>  // b.plast
   81090:	7101cc7f 	cmp	w3, #0x73
   81094:	540017e0 	b.eq	81390 <tfp_format+0x428>  // b.none
   81098:	54000889 	b.ls	811a8 <tfp_format+0x240>  // b.plast
   8109c:	7101d47f 	cmp	w3, #0x75
   810a0:	540005e1 	b.ne	8115c <tfp_format+0x1f4>  // b.any
                p.base = 10;
   810a4:	b90097fa 	str	w26, [sp, #148]
                if (2 == lng)
   810a8:	7100081f 	cmp	w0, #0x2
   810ac:	540006e0 	b.eq	81188 <tfp_format+0x220>  // b.none
                  if (1 == lng)
   810b0:	7100041f 	cmp	w0, #0x1
   810b4:	540008e0 	b.eq	811d0 <tfp_format+0x268>  // b.none
                    ui2a(va_arg(va, unsigned int), &p);
   810b8:	37f81c36 	tbnz	w22, #31, 8143c <tfp_format+0x4d4>
   810bc:	91002ea1 	add	x1, x21, #0xb
   810c0:	aa1503e0 	mov	x0, x21
   810c4:	927df035 	and	x21, x1, #0xfffffffffffffff8
   810c8:	b9400000 	ldr	w0, [x0]
   810cc:	aa1703e1 	mov	x1, x23
   810d0:	97fffeec 	bl	80c80 <ui2a>
                putchw(putp, putf, &p);
   810d4:	aa1403e1 	mov	x1, x20
   810d8:	aa1703e2 	mov	x2, x23
   810dc:	aa1303e0 	mov	x0, x19
   810e0:	97ffff1a 	bl	80d48 <putchw>
    while ((ch = *(fmt++))) {
   810e4:	39400381 	ldrb	w1, [x28]
   810e8:	9100079b 	add	x27, x28, #0x1
   810ec:	35fff761 	cbnz	w1, 80fd8 <tfp_format+0x70>
   810f0:	a94363f7 	ldp	x23, x24, [sp, #48]
}
   810f4:	a94153f3 	ldp	x19, x20, [sp, #16]
   810f8:	a9425bf5 	ldp	x21, x22, [sp, #32]
   810fc:	a9446bf9 	ldp	x25, x26, [sp, #64]
   81100:	a94573fb 	ldp	x27, x28, [sp, #80]
   81104:	a8ca7bfd 	ldp	x29, x30, [sp], #160
   81108:	d65f03c0 	ret
                    p.alt = 1;
   8110c:	52800022 	mov	w2, #0x1                   	// #1
            while ((ch = *(fmt++))) {
   81110:	38401783 	ldrb	w3, [x28], #1
   81114:	35fff7c3 	cbnz	w3, 8100c <tfp_format+0xa4>
   81118:	34000080 	cbz	w0, 81128 <tfp_format+0x1c0>
   8111c:	394223e0 	ldrb	w0, [sp, #136]
   81120:	321d0000 	orr	w0, w0, #0x8
   81124:	390223e0 	strb	w0, [sp, #136]
   81128:	34fffe41 	cbz	w1, 810f0 <tfp_format+0x188>
   8112c:	394223e0 	ldrb	w0, [sp, #136]
}
   81130:	a94153f3 	ldp	x19, x20, [sp, #16]
   81134:	32000000 	orr	w0, w0, #0x1
   81138:	390223e0 	strb	w0, [sp, #136]
   8113c:	a9425bf5 	ldp	x21, x22, [sp, #32]
   81140:	a94363f7 	ldp	x23, x24, [sp, #48]
   81144:	a9446bf9 	ldp	x25, x26, [sp, #64]
   81148:	a94573fb 	ldp	x27, x28, [sp, #80]
   8114c:	a8ca7bfd 	ldp	x29, x30, [sp], #160
   81150:	d65f03c0 	ret
                    p.lz = 1;
   81154:	52800021 	mov	w1, #0x1                   	// #1
   81158:	17ffffee 	b	81110 <tfp_format+0x1a8>
            switch (ch) {
   8115c:	7101e07f 	cmp	w3, #0x78
   81160:	54000f61 	b.ne	8134c <tfp_format+0x3e4>  // b.any
                p.uc = (ch == 'X')?1:0;
   81164:	7101607f 	cmp	w3, #0x58
   81168:	394223e1 	ldrb	w1, [sp, #136]
   8116c:	1a9f17e2 	cset	w2, eq  // eq = none
                p.base = 16;
   81170:	52800203 	mov	w3, #0x10                  	// #16
   81174:	b90097e3 	str	w3, [sp, #148]
                if (2 == lng)
   81178:	7100081f 	cmp	w0, #0x2
                p.uc = (ch == 'X')?1:0;
   8117c:	331e0041 	bfi	w1, w2, #2, #1
   81180:	390223e1 	strb	w1, [sp, #136]
                if (2 == lng)
   81184:	54fff961 	b.ne	810b0 <tfp_format+0x148>  // b.any
                    ulli2a(va_arg(va, unsigned long long int), &p);
   81188:	37f81836 	tbnz	w22, #31, 8148c <tfp_format+0x524>
   8118c:	91003ea1 	add	x1, x21, #0xf
   81190:	aa1503e0 	mov	x0, x21
   81194:	927df035 	and	x21, x1, #0xfffffffffffffff8
   81198:	f9400000 	ldr	x0, [x0]
   8119c:	aa1703e1 	mov	x1, x23
   811a0:	97fffe50 	bl	80ae0 <ulli2a>
   811a4:	17ffffcc 	b	810d4 <tfp_format+0x16c>
            switch (ch) {
   811a8:	7101bc7f 	cmp	w3, #0x6f
   811ac:	54000d40 	b.eq	81354 <tfp_format+0x3ec>  // b.none
   811b0:	7101c07f 	cmp	w3, #0x70
   811b4:	54000cc1 	b.ne	8134c <tfp_format+0x3e4>  // b.any
                p.alt = 1;
   811b8:	394223e0 	ldrb	w0, [sp, #136]
                p.base = 16;
   811bc:	52800201 	mov	w1, #0x10                  	// #16
   811c0:	b90097e1 	str	w1, [sp, #148]
                p.alt = 1;
   811c4:	121d7400 	and	w0, w0, #0xfffffff9
   811c8:	321f0000 	orr	w0, w0, #0x2
   811cc:	390223e0 	strb	w0, [sp, #136]
                    uli2a(va_arg(va, unsigned long int), &p);
   811d0:	37f81476 	tbnz	w22, #31, 8145c <tfp_format+0x4f4>
   811d4:	91003ea1 	add	x1, x21, #0xf
   811d8:	aa1503e0 	mov	x0, x21
   811dc:	927df035 	and	x21, x1, #0xfffffffffffffff8
   811e0:	f9400000 	ldr	x0, [x0]
   811e4:	aa1703e1 	mov	x1, x23
   811e8:	97fffe72 	bl	80bb0 <uli2a>
   811ec:	17ffffba 	b	810d4 <tfp_format+0x16c>
                switch (ch) {
   811f0:	52800020 	mov	w0, #0x1                   	// #1
   811f4:	17ffffc7 	b	81110 <tfp_format+0x1a8>
            switch (ch) {
   811f8:	7101607f 	cmp	w3, #0x58
   811fc:	54fffb40 	b.eq	81164 <tfp_format+0x1fc>  // b.none
   81200:	54000128 	b.hi	81224 <tfp_format+0x2bc>  // b.pmore
   81204:	34fff763 	cbz	w3, 810f0 <tfp_format+0x188>
   81208:	7100947f 	cmp	w3, #0x25
   8120c:	54000a01 	b.ne	8134c <tfp_format+0x3e4>  // b.any
                putf(putp, ch);
   81210:	9100079b 	add	x27, x28, #0x1
   81214:	2a0303e1 	mov	w1, w3
   81218:	aa1303e0 	mov	x0, x19
   8121c:	d63f0280 	blr	x20
   81220:	17ffff6c 	b	80fd0 <tfp_format+0x68>
            switch (ch) {
   81224:	71018c7f 	cmp	w3, #0x63
   81228:	54000141 	b.ne	81250 <tfp_format+0x2e8>  // b.any
                putf(putp, (char)(va_arg(va, int)));
   8122c:	37f80cd6 	tbnz	w22, #31, 813c4 <tfp_format+0x45c>
   81230:	91002ea1 	add	x1, x21, #0xb
   81234:	aa1503e0 	mov	x0, x21
   81238:	927df035 	and	x21, x1, #0xfffffffffffffff8
   8123c:	39400001 	ldrb	w1, [x0]
   81240:	9100079b 	add	x27, x28, #0x1
   81244:	aa1303e0 	mov	x0, x19
   81248:	d63f0280 	blr	x20
                break;
   8124c:	17ffff61 	b	80fd0 <tfp_format+0x68>
            switch (ch) {
   81250:	7101907f 	cmp	w3, #0x64
   81254:	540007c1 	b.ne	8134c <tfp_format+0x3e4>  // b.any
                p.base = 10;
   81258:	b90097fa 	str	w26, [sp, #148]
                if (2 == lng)
   8125c:	7100081f 	cmp	w0, #0x2
   81260:	54001261 	b.ne	814ac <tfp_format+0x544>  // b.any
                    lli2a(va_arg(va, long long int), &p);
   81264:	37f81456 	tbnz	w22, #31, 814ec <tfp_format+0x584>
   81268:	91003ea1 	add	x1, x21, #0xf
   8126c:	aa1503e0 	mov	x0, x21
   81270:	927df035 	and	x21, x1, #0xfffffffffffffff8
   81274:	f9400000 	ldr	x0, [x0]
    if (num < 0) {
   81278:	b6fff920 	tbz	x0, #63, 8119c <tfp_format+0x234>
        p->sign = '-';
   8127c:	528005a1 	mov	w1, #0x2d                  	// #45
        num = -num;
   81280:	cb0003e0 	neg	x0, x0
        p->sign = '-';
   81284:	390243e1 	strb	w1, [sp, #144]
    ulli2a(num, p);
   81288:	17ffffc5 	b	8119c <tfp_format+0x234>
                ch = *(fmt++);
   8128c:	38401783 	ldrb	w3, [x28], #1
            switch (ch) {
   81290:	7101a47f 	cmp	w3, #0x69
   81294:	54001440 	b.eq	8151c <tfp_format+0x5b4>  // b.none
   81298:	52800020 	mov	w0, #0x1                   	// #1
   8129c:	17ffff7b 	b	81088 <tfp_format+0x120>
    unsigned int num = 0;
   812a0:	52800002 	mov	w2, #0x0                   	// #0
   812a4:	1400000b 	b	812d0 <tfp_format+0x368>
    else if (ch >= 'a' && ch <= 'f')
   812a8:	7100141f 	cmp	w0, #0x5
   812ac:	54000269 	b.ls	812f8 <tfp_format+0x390>  // b.plast
    else if (ch >= 'A' && ch <= 'F')
   812b0:	7100143f 	cmp	w1, #0x5
   812b4:	54000288 	b.hi	81304 <tfp_format+0x39c>  // b.pmore
        if (digit > base)
   812b8:	710028bf 	cmp	w5, #0xa
   812bc:	54000241 	b.ne	81304 <tfp_format+0x39c>  // b.any
        ch = *p++;
   812c0:	38401783 	ldrb	w3, [x28], #1
        num = num * base + digit;
   812c4:	0b020842 	add	w2, w2, w2, lsl #2
   812c8:	5100c066 	sub	w6, w3, #0x30
   812cc:	0b0204a2 	add	w2, w5, w2, lsl #1
    else if (ch >= 'a' && ch <= 'f')
   812d0:	51018460 	sub	w0, w3, #0x61
    else if (ch >= 'A' && ch <= 'F')
   812d4:	51010461 	sub	w1, w3, #0x41
    if (ch >= '0' && ch <= '9')
   812d8:	12001cc4 	and	w4, w6, #0xff
        return ch - 'A' + 10;
   812dc:	5100dc65 	sub	w5, w3, #0x37
    else if (ch >= 'a' && ch <= 'f')
   812e0:	12001c00 	and	w0, w0, #0xff
    else if (ch >= 'A' && ch <= 'F')
   812e4:	12001c21 	and	w1, w1, #0xff
    if (ch >= '0' && ch <= '9')
   812e8:	7100249f 	cmp	w4, #0x9
   812ec:	54fffde8 	b.hi	812a8 <tfp_format+0x340>  // b.pmore
        return ch - '0';
   812f0:	2a0603e5 	mov	w5, w6
        if (digit > base)
   812f4:	17fffff3 	b	812c0 <tfp_format+0x358>
        return ch - 'a' + 10;
   812f8:	51015c65 	sub	w5, w3, #0x57
        if (digit > base)
   812fc:	710028bf 	cmp	w5, #0xa
   81300:	54fffe00 	b.eq	812c0 <tfp_format+0x358>  // b.none
    *nump = num;
   81304:	b9008fe2 	str	w2, [sp, #140]
            if (ch == '.') {
   81308:	7100b87f 	cmp	w3, #0x2e
   8130c:	54ffeb01 	b.ne	8106c <tfp_format+0x104>  // b.any
              p.lz = 1;  /* zero-padding */
   81310:	394223e0 	ldrb	w0, [sp, #136]
   81314:	32000000 	orr	w0, w0, #0x1
   81318:	390223e0 	strb	w0, [sp, #136]
   8131c:	d503201f 	nop
                ch = *(fmt++);
   81320:	38401783 	ldrb	w3, [x28], #1
              } while ((ch >= '0') && (ch <= '9'));
   81324:	5100c060 	sub	w0, w3, #0x30
   81328:	12001c00 	and	w0, w0, #0xff
   8132c:	7100241f 	cmp	w0, #0x9
   81330:	54ffff89 	b.ls	81320 <tfp_format+0x3b8>  // b.plast
   81334:	17ffff4e 	b	8106c <tfp_format+0x104>
                ch = *(fmt++);
   81338:	39400383 	ldrb	w3, [x28]
                if (ch == 'l') {
   8133c:	7101b07f 	cmp	w3, #0x6c
   81340:	54000720 	b.eq	81424 <tfp_format+0x4bc>  // b.none
                ch = *(fmt++);
   81344:	9100079c 	add	x28, x28, #0x1
   81348:	17ffffd2 	b	81290 <tfp_format+0x328>
   8134c:	9100079b 	add	x27, x28, #0x1
   81350:	17ffff20 	b	80fd0 <tfp_format+0x68>
                p.base = 8;
   81354:	52800100 	mov	w0, #0x8                   	// #8
   81358:	b90097e0 	str	w0, [sp, #148]
                ui2a(va_arg(va, unsigned int), &p);
   8135c:	37f80456 	tbnz	w22, #31, 813e4 <tfp_format+0x47c>
   81360:	91002ea1 	add	x1, x21, #0xb
   81364:	aa1503e0 	mov	x0, x21
   81368:	927df035 	and	x21, x1, #0xfffffffffffffff8
   8136c:	b9400000 	ldr	w0, [x0]
   81370:	aa1703e1 	mov	x1, x23
   81374:	9100079b 	add	x27, x28, #0x1
   81378:	97fffe42 	bl	80c80 <ui2a>
                putchw(putp, putf, &p);
   8137c:	aa1703e2 	mov	x2, x23
   81380:	aa1403e1 	mov	x1, x20
   81384:	aa1303e0 	mov	x0, x19
   81388:	97fffe70 	bl	80d48 <putchw>
                break;
   8138c:	17ffff11 	b	80fd0 <tfp_format+0x68>
                p.bf = va_arg(va, char *);
   81390:	37f803b6 	tbnz	w22, #31, 81404 <tfp_format+0x49c>
   81394:	91003ea1 	add	x1, x21, #0xf
   81398:	aa1503e0 	mov	x0, x21
   8139c:	927df035 	and	x21, x1, #0xfffffffffffffff8
   813a0:	f9400003 	ldr	x3, [x0]
                putchw(putp, putf, &p);
   813a4:	aa1703e2 	mov	x2, x23
   813a8:	aa1403e1 	mov	x1, x20
   813ac:	aa1303e0 	mov	x0, x19
   813b0:	9100079b 	add	x27, x28, #0x1
                p.bf = va_arg(va, char *);
   813b4:	f9004fe3 	str	x3, [sp, #152]
                putchw(putp, putf, &p);
   813b8:	97fffe64 	bl	80d48 <putchw>
                p.bf = bf;
   813bc:	f9004ff9 	str	x25, [sp, #152]
                break;
   813c0:	17ffff04 	b	80fd0 <tfp_format+0x68>
                putf(putp, (char)(va_arg(va, int)));
   813c4:	110022c1 	add	w1, w22, #0x8
   813c8:	7100003f 	cmp	w1, #0x0
   813cc:	54000d2d 	b.le	81570 <tfp_format+0x608>
   813d0:	91002ea2 	add	x2, x21, #0xb
   813d4:	aa1503e0 	mov	x0, x21
   813d8:	2a0103f6 	mov	w22, w1
   813dc:	927df055 	and	x21, x2, #0xfffffffffffffff8
   813e0:	17ffff97 	b	8123c <tfp_format+0x2d4>
                ui2a(va_arg(va, unsigned int), &p);
   813e4:	110022c1 	add	w1, w22, #0x8
   813e8:	7100003f 	cmp	w1, #0x0
   813ec:	54000d2d 	b.le	81590 <tfp_format+0x628>
   813f0:	91002ea2 	add	x2, x21, #0xb
   813f4:	aa1503e0 	mov	x0, x21
   813f8:	2a0103f6 	mov	w22, w1
   813fc:	927df055 	and	x21, x2, #0xfffffffffffffff8
   81400:	17ffffdb 	b	8136c <tfp_format+0x404>
                p.bf = va_arg(va, char *);
   81404:	110022c1 	add	w1, w22, #0x8
   81408:	7100003f 	cmp	w1, #0x0
   8140c:	54000bad 	b.le	81580 <tfp_format+0x618>
   81410:	91003ea2 	add	x2, x21, #0xf
   81414:	aa1503e0 	mov	x0, x21
   81418:	2a0103f6 	mov	w22, w1
   8141c:	927df055 	and	x21, x2, #0xfffffffffffffff8
   81420:	17ffffe0 	b	813a0 <tfp_format+0x438>
                  ch = *(fmt++);
   81424:	39400783 	ldrb	w3, [x28, #1]
   81428:	91000b9c 	add	x28, x28, #0x2
            switch (ch) {
   8142c:	7101a47f 	cmp	w3, #0x69
   81430:	54000d80 	b.eq	815e0 <tfp_format+0x678>  // b.none
                  lng = 2;
   81434:	52800040 	mov	w0, #0x2                   	// #2
   81438:	17ffff14 	b	81088 <tfp_format+0x120>
                    ui2a(va_arg(va, unsigned int), &p);
   8143c:	110022c1 	add	w1, w22, #0x8
   81440:	7100003f 	cmp	w1, #0x0
   81444:	540001cd 	b.le	8147c <tfp_format+0x514>
   81448:	91002ea2 	add	x2, x21, #0xb
   8144c:	aa1503e0 	mov	x0, x21
   81450:	2a0103f6 	mov	w22, w1
   81454:	927df055 	and	x21, x2, #0xfffffffffffffff8
   81458:	17ffff1c 	b	810c8 <tfp_format+0x160>
                    uli2a(va_arg(va, unsigned long int), &p);
   8145c:	110022c1 	add	w1, w22, #0x8
   81460:	7100003f 	cmp	w1, #0x0
   81464:	540003cd 	b.le	814dc <tfp_format+0x574>
   81468:	91003ea2 	add	x2, x21, #0xf
   8146c:	aa1503e0 	mov	x0, x21
   81470:	2a0103f6 	mov	w22, w1
   81474:	927df055 	and	x21, x2, #0xfffffffffffffff8
   81478:	17ffff5a 	b	811e0 <tfp_format+0x278>
                    ui2a(va_arg(va, unsigned int), &p);
   8147c:	f94037e0 	ldr	x0, [sp, #104]
   81480:	8b36c000 	add	x0, x0, w22, sxtw
   81484:	2a0103f6 	mov	w22, w1
   81488:	17ffff10 	b	810c8 <tfp_format+0x160>
                    ulli2a(va_arg(va, unsigned long long int), &p);
   8148c:	110022c1 	add	w1, w22, #0x8
   81490:	7100003f 	cmp	w1, #0x0
   81494:	540003cd 	b.le	8150c <tfp_format+0x5a4>
   81498:	91003ea2 	add	x2, x21, #0xf
   8149c:	aa1503e0 	mov	x0, x21
   814a0:	2a0103f6 	mov	w22, w1
   814a4:	927df055 	and	x21, x2, #0xfffffffffffffff8
   814a8:	17ffff3c 	b	81198 <tfp_format+0x230>
                  if (1 == lng)
   814ac:	7100041f 	cmp	w0, #0x1
   814b0:	54000380 	b.eq	81520 <tfp_format+0x5b8>  // b.none
                    i2a(va_arg(va, int), &p);
   814b4:	37f804f6 	tbnz	w22, #31, 81550 <tfp_format+0x5e8>
   814b8:	91002ea1 	add	x1, x21, #0xb
   814bc:	aa1503e0 	mov	x0, x21
   814c0:	927df035 	and	x21, x1, #0xfffffffffffffff8
   814c4:	b9400000 	ldr	w0, [x0]
    if (num < 0) {
   814c8:	36ffe020 	tbz	w0, #31, 810cc <tfp_format+0x164>
        p->sign = '-';
   814cc:	528005a1 	mov	w1, #0x2d                  	// #45
        num = -num;
   814d0:	4b0003e0 	neg	w0, w0
        p->sign = '-';
   814d4:	390243e1 	strb	w1, [sp, #144]
    ui2a(num, p);
   814d8:	17fffefd 	b	810cc <tfp_format+0x164>
                    uli2a(va_arg(va, unsigned long int), &p);
   814dc:	f94037e0 	ldr	x0, [sp, #104]
   814e0:	8b36c000 	add	x0, x0, w22, sxtw
   814e4:	2a0103f6 	mov	w22, w1
   814e8:	17ffff3e 	b	811e0 <tfp_format+0x278>
                    lli2a(va_arg(va, long long int), &p);
   814ec:	110022c1 	add	w1, w22, #0x8
   814f0:	7100003f 	cmp	w1, #0x0
   814f4:	540006ed 	b.le	815d0 <tfp_format+0x668>
   814f8:	91003ea2 	add	x2, x21, #0xf
   814fc:	aa1503e0 	mov	x0, x21
   81500:	2a0103f6 	mov	w22, w1
   81504:	927df055 	and	x21, x2, #0xfffffffffffffff8
   81508:	17ffff5b 	b	81274 <tfp_format+0x30c>
                    ulli2a(va_arg(va, unsigned long long int), &p);
   8150c:	f94037e0 	ldr	x0, [sp, #104]
   81510:	8b36c000 	add	x0, x0, w22, sxtw
   81514:	2a0103f6 	mov	w22, w1
   81518:	17ffff20 	b	81198 <tfp_format+0x230>
                p.base = 10;
   8151c:	b90097fa 	str	w26, [sp, #148]
                    li2a(va_arg(va, long int), &p);
   81520:	37f80416 	tbnz	w22, #31, 815a0 <tfp_format+0x638>
   81524:	91003ea1 	add	x1, x21, #0xf
   81528:	aa1503e0 	mov	x0, x21
   8152c:	927df035 	and	x21, x1, #0xfffffffffffffff8
   81530:	f9400000 	ldr	x0, [x0]
    if (num < 0) {
   81534:	b6ffe580 	tbz	x0, #63, 811e4 <tfp_format+0x27c>
        p->sign = '-';
   81538:	528005a1 	mov	w1, #0x2d                  	// #45
        num = -num;
   8153c:	cb0003e0 	neg	x0, x0
        p->sign = '-';
   81540:	390243e1 	strb	w1, [sp, #144]
    uli2a(num, p);
   81544:	17ffff28 	b	811e4 <tfp_format+0x27c>
                p.base = 10;
   81548:	b90097fa 	str	w26, [sp, #148]
                if (2 == lng)
   8154c:	17ffffda 	b	814b4 <tfp_format+0x54c>
                    i2a(va_arg(va, int), &p);
   81550:	110022c1 	add	w1, w22, #0x8
   81554:	7100003f 	cmp	w1, #0x0
   81558:	5400034d 	b.le	815c0 <tfp_format+0x658>
   8155c:	91002ea2 	add	x2, x21, #0xb
   81560:	aa1503e0 	mov	x0, x21
   81564:	2a0103f6 	mov	w22, w1
   81568:	927df055 	and	x21, x2, #0xfffffffffffffff8
   8156c:	17ffffd6 	b	814c4 <tfp_format+0x55c>
                putf(putp, (char)(va_arg(va, int)));
   81570:	f94037e0 	ldr	x0, [sp, #104]
   81574:	8b36c000 	add	x0, x0, w22, sxtw
   81578:	2a0103f6 	mov	w22, w1
   8157c:	17ffff30 	b	8123c <tfp_format+0x2d4>
                p.bf = va_arg(va, char *);
   81580:	f94037e0 	ldr	x0, [sp, #104]
   81584:	8b36c000 	add	x0, x0, w22, sxtw
   81588:	2a0103f6 	mov	w22, w1
   8158c:	17ffff85 	b	813a0 <tfp_format+0x438>
                ui2a(va_arg(va, unsigned int), &p);
   81590:	f94037e0 	ldr	x0, [sp, #104]
   81594:	8b36c000 	add	x0, x0, w22, sxtw
   81598:	2a0103f6 	mov	w22, w1
   8159c:	17ffff74 	b	8136c <tfp_format+0x404>
                    li2a(va_arg(va, long int), &p);
   815a0:	110022c1 	add	w1, w22, #0x8
   815a4:	7100003f 	cmp	w1, #0x0
   815a8:	5400022d 	b.le	815ec <tfp_format+0x684>
   815ac:	91003ea2 	add	x2, x21, #0xf
   815b0:	aa1503e0 	mov	x0, x21
   815b4:	2a0103f6 	mov	w22, w1
   815b8:	927df055 	and	x21, x2, #0xfffffffffffffff8
   815bc:	17ffffdd 	b	81530 <tfp_format+0x5c8>
                    i2a(va_arg(va, int), &p);
   815c0:	f94037e0 	ldr	x0, [sp, #104]
   815c4:	8b36c000 	add	x0, x0, w22, sxtw
   815c8:	2a0103f6 	mov	w22, w1
   815cc:	17ffffbe 	b	814c4 <tfp_format+0x55c>
                    lli2a(va_arg(va, long long int), &p);
   815d0:	f94037e0 	ldr	x0, [sp, #104]
   815d4:	8b36c000 	add	x0, x0, w22, sxtw
   815d8:	2a0103f6 	mov	w22, w1
   815dc:	17ffff26 	b	81274 <tfp_format+0x30c>
                p.base = 10;
   815e0:	b90097fa 	str	w26, [sp, #148]
                    lli2a(va_arg(va, long long int), &p);
   815e4:	36ffe436 	tbz	w22, #31, 81268 <tfp_format+0x300>
   815e8:	17ffffc1 	b	814ec <tfp_format+0x584>
                    li2a(va_arg(va, long int), &p);
   815ec:	f94037e0 	ldr	x0, [sp, #104]
   815f0:	8b36c000 	add	x0, x0, w22, sxtw
   815f4:	2a0103f6 	mov	w22, w1
   815f8:	17ffffce 	b	81530 <tfp_format+0x5c8>
   815fc:	d503201f 	nop

0000000000081600 <init_printf>:
    stdout_putf = putf;
   81600:	b00000a2 	adrp	x2, 96000 <stdout_putf>
   81604:	91000043 	add	x3, x2, #0x0
   81608:	f9000041 	str	x1, [x2]
    stdout_putp = putp;
   8160c:	f9000460 	str	x0, [x3, #8]
}
   81610:	d65f03c0 	ret
   81614:	d503201f 	nop

0000000000081618 <tfp_printf>:
{
   81618:	a9b77bfd 	stp	x29, x30, [sp, #-144]!
    tfp_format(stdout_putp, stdout_putf, fmt, va);
   8161c:	b00000a8 	adrp	x8, 96000 <stdout_putf>
   81620:	9100010b 	add	x11, x8, #0x0
{
   81624:	910003fd 	mov	x29, sp
   81628:	f9002fe1 	str	x1, [sp, #88]
   8162c:	aa0003ea 	mov	x10, x0
    tfp_format(stdout_putp, stdout_putf, fmt, va);
   81630:	f9400101 	ldr	x1, [x8]
    va_start(va, fmt);
   81634:	910143e9 	add	x9, sp, #0x50
    tfp_format(stdout_putp, stdout_putf, fmt, va);
   81638:	f9400560 	ldr	x0, [x11, #8]
    va_start(va, fmt);
   8163c:	910243eb 	add	x11, sp, #0x90
   81640:	a9032feb 	stp	x11, x11, [sp, #48]
   81644:	128006e8 	mov	w8, #0xffffffc8            	// #-56
   81648:	f90023e9 	str	x9, [sp, #64]
   8164c:	b9004be8 	str	w8, [sp, #72]
   81650:	b9004fff 	str	wzr, [sp, #76]
    tfp_format(stdout_putp, stdout_putf, fmt, va);
   81654:	a94327e8 	ldp	x8, x9, [sp, #48]
   81658:	a90127e8 	stp	x8, x9, [sp, #16]
   8165c:	a94427e8 	ldp	x8, x9, [sp, #64]
   81660:	a90227e8 	stp	x8, x9, [sp, #32]
{
   81664:	a9060fe2 	stp	x2, x3, [sp, #96]
    tfp_format(stdout_putp, stdout_putf, fmt, va);
   81668:	910043e3 	add	x3, sp, #0x10
   8166c:	aa0a03e2 	mov	x2, x10
{
   81670:	a90717e4 	stp	x4, x5, [sp, #112]
   81674:	a9081fe6 	stp	x6, x7, [sp, #128]
    tfp_format(stdout_putp, stdout_putf, fmt, va);
   81678:	97fffe3c 	bl	80f68 <tfp_format>
}
   8167c:	a8c97bfd 	ldp	x29, x30, [sp], #144
   81680:	d65f03c0 	ret
   81684:	d503201f 	nop

0000000000081688 <tfp_vsnprintf>:
  if (size < 1)
   81688:	b5000061 	cbnz	x1, 81694 <tfp_vsnprintf+0xc>
    return 0;
   8168c:	52800000 	mov	w0, #0x0                   	// #0
}
   81690:	d65f03c0 	ret
{
   81694:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
   81698:	aa0003e5 	mov	x5, x0
  data.dest_capacity = size-1;
   8169c:	d1000424 	sub	x4, x1, #0x1
{
   816a0:	910003fd 	mov	x29, sp
  tfp_format(&data, _vsnprintf_putcf, format, ap);
   816a4:	a9402069 	ldp	x9, x8, [x3]
   816a8:	9100e3e0 	add	x0, sp, #0x38
   816ac:	a9411867 	ldp	x7, x6, [x3, #16]
   816b0:	f0ffffe1 	adrp	x1, 80000 <_start>
   816b4:	910043e3 	add	x3, sp, #0x10
   816b8:	913c8021 	add	x1, x1, #0xf20
   816bc:	a90123e9 	stp	x9, x8, [sp, #16]
   816c0:	a9021be7 	stp	x7, x6, [sp, #32]
  data.dest = str;
   816c4:	a90397e4 	stp	x4, x5, [sp, #56]
  data.num_chars = 0;
   816c8:	f90027ff 	str	xzr, [sp, #72]
  tfp_format(&data, _vsnprintf_putcf, format, ap);
   816cc:	97fffe27 	bl	80f68 <tfp_format>
  if (data.num_chars < data.dest_capacity)
   816d0:	f9401fe0 	ldr	x0, [sp, #56]
   816d4:	f94027e1 	ldr	x1, [sp, #72]
   816d8:	eb00003f 	cmp	x1, x0
   816dc:	540000c2 	b.cs	816f4 <tfp_vsnprintf+0x6c>  // b.hs, b.nlast
    data.dest[data.num_chars] = '\0';
   816e0:	f94023e0 	ldr	x0, [sp, #64]
   816e4:	3821681f 	strb	wzr, [x0, x1]
  return data.num_chars;
   816e8:	b9404be0 	ldr	w0, [sp, #72]
}
   816ec:	a8c57bfd 	ldp	x29, x30, [sp], #80
   816f0:	d65f03c0 	ret
    data.dest[data.dest_capacity] = '\0';
   816f4:	f94023e1 	ldr	x1, [sp, #64]
   816f8:	3820683f 	strb	wzr, [x1, x0]
  return data.num_chars;
   816fc:	b9404be0 	ldr	w0, [sp, #72]
}
   81700:	a8c57bfd 	ldp	x29, x30, [sp], #80
   81704:	d65f03c0 	ret

0000000000081708 <tfp_snprintf>:
{
   81708:	a9b87bfd 	stp	x29, x30, [sp, #-128]!
  va_start(ap, format);
   8170c:	128004e8 	mov	w8, #0xffffffd8            	// #-40
{
   81710:	910003fd 	mov	x29, sp
  va_start(ap, format);
   81714:	910203ea 	add	x10, sp, #0x80
   81718:	a9032bea 	stp	x10, x10, [sp, #48]
   8171c:	910143e9 	add	x9, sp, #0x50
   81720:	f90023e9 	str	x9, [sp, #64]
   81724:	29097fe8 	stp	w8, wzr, [sp, #72]
  retval = tfp_vsnprintf(str, size, format, ap);
   81728:	a94327e8 	ldp	x8, x9, [sp, #48]
   8172c:	a90127e8 	stp	x8, x9, [sp, #16]
   81730:	a94427e8 	ldp	x8, x9, [sp, #64]
   81734:	a90227e8 	stp	x8, x9, [sp, #32]
{
   81738:	a90593e3 	stp	x3, x4, [sp, #88]
  retval = tfp_vsnprintf(str, size, format, ap);
   8173c:	910043e3 	add	x3, sp, #0x10
{
   81740:	a9069be5 	stp	x5, x6, [sp, #104]
   81744:	f9003fe7 	str	x7, [sp, #120]
  retval = tfp_vsnprintf(str, size, format, ap);
   81748:	97ffffd0 	bl	81688 <tfp_vsnprintf>
}
   8174c:	a8c87bfd 	ldp	x29, x30, [sp], #128
   81750:	d65f03c0 	ret
   81754:	d503201f 	nop

0000000000081758 <tfp_vsprintf>:

int tfp_vsprintf(char *str, const char *format, va_list ap)
{
   81758:	aa0203e4 	mov	x4, x2
   8175c:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
   81760:	aa0003e5 	mov	x5, x0
   81764:	910003fd 	mov	x29, sp
  struct _vsprintf_putcf_data data;
  data.dest = str;
  data.num_chars = 0;
  tfp_format(&data, _vsprintf_putcf, format, ap);
   81768:	a9401c86 	ldp	x6, x7, [x4]
   8176c:	f9000be6 	str	x6, [sp, #16]
   81770:	aa0103e2 	mov	x2, x1
   81774:	910043e3 	add	x3, sp, #0x10
   81778:	f9400886 	ldr	x6, [x4, #16]
   8177c:	f9000fe7 	str	x7, [sp, #24]
   81780:	9100c3e0 	add	x0, sp, #0x30
   81784:	f0ffffe1 	adrp	x1, 80000 <_start>
   81788:	f9400c84 	ldr	x4, [x4, #24]
   8178c:	913d4021 	add	x1, x1, #0xf50
   81790:	a90213e6 	stp	x6, x4, [sp, #32]
  data.num_chars = 0;
   81794:	a9037fe5 	stp	x5, xzr, [sp, #48]
  tfp_format(&data, _vsprintf_putcf, format, ap);
   81798:	97fffdf4 	bl	80f68 <tfp_format>
  data.dest[data.num_chars] = '\0';
   8179c:	a94303e1 	ldp	x1, x0, [sp, #48]
   817a0:	3820683f 	strb	wzr, [x1, x0]
  return data.num_chars;
}
   817a4:	b9403be0 	ldr	w0, [sp, #56]
   817a8:	a8c47bfd 	ldp	x29, x30, [sp], #64
   817ac:	d65f03c0 	ret

00000000000817b0 <tfp_sprintf>:

int tfp_sprintf(char *str, const char *format, ...)
{
   817b0:	a9b57bfd 	stp	x29, x30, [sp, #-176]!
  va_list ap;
  int retval;

  va_start(ap, format);
   817b4:	128005e8 	mov	w8, #0xffffffd0            	// #-48
{
   817b8:	aa0103ec 	mov	x12, x1
   817bc:	910003fd 	mov	x29, sp
  va_start(ap, format);
   817c0:	910203e9 	add	x9, sp, #0x80
   817c4:	9102c3ea 	add	x10, sp, #0xb0
   817c8:	a9042bea 	stp	x10, x10, [sp, #64]
{
   817cc:	aa0003ed 	mov	x13, x0
  tfp_format(&data, _vsprintf_putcf, format, ap);
   817d0:	f0ffffe1 	adrp	x1, 80000 <_start>
  va_start(ap, format);
   817d4:	f9002be9 	str	x9, [sp, #80]
  tfp_format(&data, _vsprintf_putcf, format, ap);
   817d8:	9100c3e0 	add	x0, sp, #0x30
  va_start(ap, format);
   817dc:	290b7fe8 	stp	w8, wzr, [sp, #88]
  tfp_format(&data, _vsprintf_putcf, format, ap);
   817e0:	913d4021 	add	x1, x1, #0xf50
   817e4:	a9442fea 	ldp	x10, x11, [sp, #64]
   817e8:	a9012fea 	stp	x10, x11, [sp, #16]
   817ec:	a94527e8 	ldp	x8, x9, [sp, #80]
   817f0:	a90227e8 	stp	x8, x9, [sp, #32]
  data.num_chars = 0;
   817f4:	a9037fed 	stp	x13, xzr, [sp, #48]
   817f8:	a9062fea 	stp	x10, x11, [sp, #96]
   817fc:	a90727e8 	stp	x8, x9, [sp, #112]
{
   81800:	a9080fe2 	stp	x2, x3, [sp, #128]
  tfp_format(&data, _vsprintf_putcf, format, ap);
   81804:	910043e3 	add	x3, sp, #0x10
   81808:	aa0c03e2 	mov	x2, x12
{
   8180c:	a90917e4 	stp	x4, x5, [sp, #144]
   81810:	a90a1fe6 	stp	x6, x7, [sp, #160]
  tfp_format(&data, _vsprintf_putcf, format, ap);
   81814:	97fffdd5 	bl	80f68 <tfp_format>
  data.dest[data.num_chars] = '\0';
   81818:	a94303e1 	ldp	x1, x0, [sp, #48]
   8181c:	3820683f 	strb	wzr, [x1, x0]
  retval = tfp_vsprintf(str, format, ap);
  va_end(ap);
  return retval;
}
   81820:	b9403be0 	ldr	w0, [sp, #56]
   81824:	a8cb7bfd 	ldp	x29, x30, [sp], #176
   81828:	d65f03c0 	ret
   8182c:	d503201f 	nop

0000000000081830 <panic>:
#endif

// xv6
void panic(char *s)
{
   81830:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
  printf("panic: ");
   81834:	b0000022 	adrp	x2, 86000 <__asm_dcache_level+0xc>
{
   81838:	910003fd 	mov	x29, sp
   8183c:	f9000bf3 	str	x19, [sp, #16]
   81840:	aa0003f3 	mov	x19, x0
  printf("panic: ");
   81844:	9119a040 	add	x0, x2, #0x668
   81848:	97ffff74 	bl	81618 <tfp_printf>
  printf("%s\n", s);
   8184c:	aa1303e1 	mov	x1, x19
   81850:	b0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   81854:	9119c000 	add	x0, x0, #0x670
   81858:	97ffff70 	bl	81618 <tfp_printf>
//   panicked = 1; // freeze uart output from other CPUs
    asm volatile("msr	daifset, #0b0010 "); // disable irq
   8185c:	d50342df 	msr	daifset, #0x2
  for(;;)
   81860:	14000000 	b	81860 <panic+0x30>
   81864:	d503201f 	nop

0000000000081868 <debug_hexdump>:
}

// circle debug.cpp
// will dump at least 16 bytes....
void debug_hexdump (const void *pStart, unsigned nBytes)
{
   81868:	d10203ff 	sub	sp, sp, #0x80
	unsigned char *pOffset = (unsigned char *) pStart;
	
	printf("Dumping 0x%x bytes starting at 0x%lx\r\n", nBytes,
   8186c:	aa0003e2 	mov	x2, x0
{
   81870:	a9057bfd 	stp	x29, x30, [sp, #80]
   81874:	910143fd 	add	x29, sp, #0x50
   81878:	a90653f3 	stp	x19, x20, [sp, #96]
   8187c:	aa0003f4 	mov	x20, x0
	printf("Dumping 0x%x bytes starting at 0x%lx\r\n", nBytes,
   81880:	b0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   81884:	9119e000 	add	x0, x0, #0x678
{
   81888:	a9075bf5 	stp	x21, x22, [sp, #112]
   8188c:	2a0103f5 	mov	w21, w1
	printf("Dumping 0x%x bytes starting at 0x%lx\r\n", nBytes,
   81890:	97ffff62 	bl	81618 <tfp_printf>
				(unsigned long) pOffset);
	
	while (nBytes > 0)
   81894:	34000575 	cbz	w21, 81940 <debug_hexdump+0xd8>
   81898:	927c6ea2 	and	x2, x21, #0xfffffff0
	unsigned char *pOffset = (unsigned char *) pStart;
   8189c:	aa1403f3 	mov	x19, x20
   818a0:	91004042 	add	x2, x2, #0x10
	while (nBytes > 0)
   818a4:	0b1402b5 	add	w21, w21, w20
   818a8:	b0000036 	adrp	x22, 86000 <__asm_dcache_level+0xc>
   818ac:	8b020294 	add	x20, x20, x2
	{
		printf(
   818b0:	911a82d6 	add	x22, x22, #0x6a0
   818b4:	14000003 	b	818c0 <debug_hexdump+0x58>
	while (nBytes > 0)
   818b8:	6b1302bf 	cmp	w21, w19
   818bc:	54000420 	b.eq	81940 <debug_hexdump+0xd8>  // b.none
		printf(
   818c0:	39402e68 	ldrb	w8, [x19, #11]
   818c4:	92403e61 	and	x1, x19, #0xffff
   818c8:	39402a69 	ldrb	w9, [x19, #10]
   818cc:	aa1603e0 	mov	x0, x22
   818d0:	3940266a 	ldrb	w10, [x19, #9]
				(unsigned) pOffset[0],  (unsigned) pOffset[1],  (unsigned) pOffset[2],  (unsigned) pOffset[3],
				(unsigned) pOffset[4],  (unsigned) pOffset[5],  (unsigned) pOffset[6],  (unsigned) pOffset[7],
				(unsigned) pOffset[8],  (unsigned) pOffset[9],  (unsigned) pOffset[10], (unsigned) pOffset[11],
				(unsigned) pOffset[12], (unsigned) pOffset[13], (unsigned) pOffset[14], (unsigned) pOffset[15]);

		pOffset += 16;
   818d4:	91004273 	add	x19, x19, #0x10
		printf(
   818d8:	385f826b 	ldurb	w11, [x19, #-8]
   818dc:	385f726c 	ldurb	w12, [x19, #-9]
   818e0:	385f626d 	ldurb	w13, [x19, #-10]
   818e4:	385f5267 	ldurb	w7, [x19, #-11]
   818e8:	385f4266 	ldurb	w6, [x19, #-12]
   818ec:	385f3265 	ldurb	w5, [x19, #-13]
   818f0:	385f2264 	ldurb	w4, [x19, #-14]
   818f4:	385f1263 	ldurb	w3, [x19, #-15]
   818f8:	385f0262 	ldurb	w2, [x19, #-16]
   818fc:	b90003ed 	str	w13, [sp]
   81900:	b9000bec 	str	w12, [sp, #8]
   81904:	b90013eb 	str	w11, [sp, #16]
   81908:	b9001bea 	str	w10, [sp, #24]
   8190c:	b90023e9 	str	w9, [sp, #32]
   81910:	b9002be8 	str	w8, [sp, #40]
   81914:	385ff268 	ldurb	w8, [x19, #-1]
   81918:	385fe269 	ldurb	w9, [x19, #-2]
   8191c:	385fd26a 	ldurb	w10, [x19, #-3]
   81920:	385fc26b 	ldurb	w11, [x19, #-4]
   81924:	b90033eb 	str	w11, [sp, #48]
   81928:	b9003bea 	str	w10, [sp, #56]
   8192c:	b90043e9 	str	w9, [sp, #64]
   81930:	b9004be8 	str	w8, [sp, #72]
   81934:	97ffff39 	bl	81618 <tfp_printf>
		if (nBytes >= 16)
   81938:	eb14027f 	cmp	x19, x20
   8193c:	54fffbe1 	b.ne	818b8 <debug_hexdump+0x50>  // b.any
		else
		{
			nBytes = 0;
		}
	}
}
   81940:	a9457bfd 	ldp	x29, x30, [sp, #80]
   81944:	a94653f3 	ldp	x19, x20, [sp, #96]
   81948:	a9475bf5 	ldp	x21, x22, [sp, #112]
   8194c:	910203ff 	add	sp, sp, #0x80
   81950:	d65f03c0 	ret
   81954:	d503201f 	nop

0000000000081958 <assertion_failed>:

// circle assert.cpp        
void assertion_failed (const char *pExpr, const char *pFile, unsigned nLine) {
   81958:	aa0103e4 	mov	x4, x1
   8195c:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
    printf("assertion failed: %s at %s:%u\n", pExpr, pFile, nLine); 
   81960:	aa0003e1 	mov	x1, x0
   81964:	2a0203e3 	mov	w3, w2
   81968:	aa0403e2 	mov	x2, x4
void assertion_failed (const char *pExpr, const char *pFile, unsigned nLine) {
   8196c:	910003fd 	mov	x29, sp
    printf("assertion failed: %s at %s:%u\n", pExpr, pFile, nLine); 
   81970:	b0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   81974:	911c0000 	add	x0, x0, #0x700
   81978:	97ffff28 	bl	81618 <tfp_printf>
    panic("kernel hangs"); 
   8197c:	b0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   81980:	911c8000 	add	x0, x0, #0x720
   81984:	97ffffab 	bl	81830 <panic>

0000000000081988 <memset>:

/* c: the fill value (byte); n: size, in bytes */
void *memset(void *dst, int c, uint n) {
    char *cdst = (char *)dst;
    int i;
    for (i = 0; i < n; i++) {
   81988:	34000122 	cbz	w2, 819ac <memset+0x24>
   8198c:	51000442 	sub	w2, w2, #0x1
   81990:	12001c23 	and	w3, w1, #0xff
   81994:	91000442 	add	x2, x2, #0x1
   81998:	aa0003e1 	mov	x1, x0
   8199c:	8b000042 	add	x2, x2, x0
        cdst[i] = c;
   819a0:	38001423 	strb	w3, [x1], #1
    for (i = 0; i < n; i++) {
   819a4:	eb02003f 	cmp	x1, x2
   819a8:	54ffffc1 	b.ne	819a0 <memset+0x18>  // b.any
    }
    return dst;
}
   819ac:	d65f03c0 	ret

00000000000819b0 <memzero>:
    for (i = 0; i < n; i++) {
   819b0:	34000101 	cbz	w1, 819d0 <memzero+0x20>
   819b4:	51000421 	sub	w1, w1, #0x1
   819b8:	8b010002 	add	x2, x0, x1
   819bc:	d503201f 	nop
        cdst[i] = c;
   819c0:	3900001f 	strb	wzr, [x0]
    for (i = 0; i < n; i++) {
   819c4:	eb02001f 	cmp	x0, x2
   819c8:	91000400 	add	x0, x0, #0x1
   819cc:	54ffffa1 	b.ne	819c0 <memzero+0x10>  // b.any

void memzero(void *dst, uint n) {
    memset(dst, 0, n);
}
   819d0:	d65f03c0 	ret
   819d4:	d503201f 	nop

00000000000819d8 <memcmp>:
int memcmp(const void *v1, const void *v2, uint n) {
    const uchar *s1, *s2;

    s1 = v1;
    s2 = v2;
    while (n-- > 0) {
   819d8:	51000446 	sub	w6, w2, #0x1
   819dc:	340001a2 	cbz	w2, 81a10 <memcmp+0x38>
   819e0:	d2800002 	mov	x2, #0x0                   	// #0
   819e4:	14000004 	b	819f4 <memcmp+0x1c>
   819e8:	eb0200df 	cmp	x6, x2
   819ec:	aa0503e2 	mov	x2, x5
   819f0:	54000100 	b.eq	81a10 <memcmp+0x38>  // b.none
        if (*s1 != *s2)
   819f4:	38626803 	ldrb	w3, [x0, x2]
   819f8:	91000445 	add	x5, x2, #0x1
   819fc:	38626824 	ldrb	w4, [x1, x2]
   81a00:	6b04007f 	cmp	w3, w4
   81a04:	54ffff20 	b.eq	819e8 <memcmp+0x10>  // b.none
            return *s1 - *s2;
   81a08:	4b040060 	sub	w0, w3, w4
        s1++, s2++;
    }

    return 0;
}
   81a0c:	d65f03c0 	ret
    return 0;
   81a10:	52800000 	mov	w0, #0x0                   	// #0
}
   81a14:	d65f03c0 	ret

0000000000081a18 <memmove>:
void *
memmove(void *dst, const void *src, uint n) {
    const char *s;
    char *d;

    if (n == 0)
   81a18:	34000162 	cbz	w2, 81a44 <memmove+0x2c>
        return dst;

    s = src;
    d = dst;
    if (s < d && s + n > d) {
   81a1c:	eb00003f 	cmp	x1, x0
   81a20:	51000445 	sub	w5, w2, #0x1
   81a24:	54000123 	b.cc	81a48 <memmove+0x30>  // b.lo, b.ul, b.last
memmove(void *dst, const void *src, uint n) {
   81a28:	d2800002 	mov	x2, #0x0                   	// #0
   81a2c:	d503201f 	nop
        d += n;
        while (n-- > 0)
            *--d = *--s;
    } else
        while (n-- > 0)
            *d++ = *s++;
   81a30:	38626824 	ldrb	w4, [x1, x2]
        while (n-- > 0)
   81a34:	eb0200bf 	cmp	x5, x2
            *d++ = *s++;
   81a38:	38226804 	strb	w4, [x0, x2]
        while (n-- > 0)
   81a3c:	91000442 	add	x2, x2, #0x1
   81a40:	54ffff81 	b.ne	81a30 <memmove+0x18>  // b.any

    return dst;
}
   81a44:	d65f03c0 	ret
    if (s < d && s + n > d) {
   81a48:	2a0203e2 	mov	w2, w2
   81a4c:	8b020024 	add	x4, x1, x2
   81a50:	eb00009f 	cmp	x4, x0
   81a54:	54fffea9 	b.ls	81a28 <memmove+0x10>  // b.plast
        d += n;
   81a58:	92800021 	mov	x1, #0xfffffffffffffffe    	// #-2
   81a5c:	8b020002 	add	x2, x0, x2
        while (n-- > 0)
   81a60:	cb254025 	sub	x5, x1, w5, uxtw
        d += n;
   81a64:	92800001 	mov	x1, #0xffffffffffffffff    	// #-1
            *--d = *--s;
   81a68:	38616883 	ldrb	w3, [x4, x1]
   81a6c:	38216843 	strb	w3, [x2, x1]
        while (n-- > 0)
   81a70:	d1000421 	sub	x1, x1, #0x1
   81a74:	eb0100bf 	cmp	x5, x1
   81a78:	54ffff81 	b.ne	81a68 <memmove+0x50>  // b.any
}
   81a7c:	d65f03c0 	ret

0000000000081a80 <memcpy>:
// memcpy exists to placate GCC.  Use memmove.
// NB: gcc will gen code to invoke memcpy for struct assignment. so the
// func below must be right (e.g. cannot assume any alignment)
void *
memcpy(void *dst, const void *src, uint n) {
    return memmove(dst, src, n);
   81a80:	17ffffe6 	b	81a18 <memmove>
   81a84:	d503201f 	nop

0000000000081a88 <strncmp>:
}

int strncmp(const char *p, const char *q, uint n) {
    while (n > 0 && *p && *p == *q)
   81a88:	340001e2 	cbz	w2, 81ac4 <strncmp+0x3c>
   81a8c:	51000446 	sub	w6, w2, #0x1
   81a90:	d2800002 	mov	x2, #0x0                   	// #0
   81a94:	14000005 	b	81aa8 <strncmp+0x20>
   81a98:	54000121 	b.ne	81abc <strncmp+0x34>  // b.any
   81a9c:	eb0200df 	cmp	x6, x2
   81aa0:	aa0503e2 	mov	x2, x5
   81aa4:	54000100 	b.eq	81ac4 <strncmp+0x3c>  // b.none
   81aa8:	38626803 	ldrb	w3, [x0, x2]
   81aac:	91000445 	add	x5, x2, #0x1
   81ab0:	38626824 	ldrb	w4, [x1, x2]
   81ab4:	6b04007f 	cmp	w3, w4
   81ab8:	35ffff03 	cbnz	w3, 81a98 <strncmp+0x10>
        n--, p++, q++;
    if (n == 0)
        return 0;
    return (uchar)*p - (uchar)*q;
   81abc:	4b040060 	sub	w0, w3, w4
}
   81ac0:	d65f03c0 	ret
        return 0;
   81ac4:	52800000 	mov	w0, #0x0                   	// #0
}
   81ac8:	d65f03c0 	ret
   81acc:	d503201f 	nop

0000000000081ad0 <strncpy>:
char *
strncpy(char *s, const char *t, int n) {
    char *os;

    os = s;
    while (n-- > 0 && (*s++ = *t++) != 0)
   81ad0:	aa0103e5 	mov	x5, x1
   81ad4:	aa0003e1 	mov	x1, x0
   81ad8:	14000004 	b	81ae8 <strncpy+0x18>
   81adc:	384014a4 	ldrb	w4, [x5], #1
   81ae0:	38001424 	strb	w4, [x1], #1
   81ae4:	340000a4 	cbz	w4, 81af8 <strncpy+0x28>
   81ae8:	2a0203e3 	mov	w3, w2
   81aec:	51000442 	sub	w2, w2, #0x1
   81af0:	7100007f 	cmp	w3, #0x0
   81af4:	54ffff4c 	b.gt	81adc <strncpy+0xc>
        ;
    while (n-- > 0)
   81af8:	7100005f 	cmp	w2, #0x0
   81afc:	0b010063 	add	w3, w3, w1
   81b00:	540000ed 	b.le	81b1c <strncpy+0x4c>
   81b04:	d503201f 	nop
        *s++ = 0;
   81b08:	3800143f 	strb	wzr, [x1], #1
    while (n-- > 0)
   81b0c:	2a2103e2 	mvn	w2, w1
   81b10:	0b030042 	add	w2, w2, w3
   81b14:	7100005f 	cmp	w2, #0x0
   81b18:	54ffff8c 	b.gt	81b08 <strncpy+0x38>
    return os;
}
   81b1c:	d65f03c0 	ret

0000000000081b20 <safestrcpy>:
char *
safestrcpy(char *s, const char *t, int n) {
    char *os;

    os = s;
    if (n <= 0)
   81b20:	7100005f 	cmp	w2, #0x0
   81b24:	5400016d 	b.le	81b50 <safestrcpy+0x30>
   81b28:	51000442 	sub	w2, w2, #0x1
   81b2c:	aa0003e3 	mov	x3, x0
   81b30:	8b020024 	add	x4, x1, x2
   81b34:	14000004 	b	81b44 <safestrcpy+0x24>
        return os;
    while (--n > 0 && (*s++ = *t++) != 0)
   81b38:	38401422 	ldrb	w2, [x1], #1
   81b3c:	38001462 	strb	w2, [x3], #1
   81b40:	34000062 	cbz	w2, 81b4c <safestrcpy+0x2c>
   81b44:	eb04003f 	cmp	x1, x4
   81b48:	54ffff81 	b.ne	81b38 <safestrcpy+0x18>  // b.any
        ;
    *s = 0;
   81b4c:	3900007f 	strb	wzr, [x3]
    return os;
}
   81b50:	d65f03c0 	ret
   81b54:	d503201f 	nop

0000000000081b58 <strlen>:

int strlen(const char *s) {
    int n;

    for (n = 0; s[n]; n++)
   81b58:	39400001 	ldrb	w1, [x0]
   81b5c:	34000101 	cbz	w1, 81b7c <strlen+0x24>
   81b60:	d1000403 	sub	x3, x0, #0x1
   81b64:	d2800021 	mov	x1, #0x1                   	// #1
   81b68:	2a0103e0 	mov	w0, w1
   81b6c:	91000421 	add	x1, x1, #0x1
   81b70:	38616862 	ldrb	w2, [x3, x1]
   81b74:	35ffffa2 	cbnz	w2, 81b68 <strlen+0x10>
        ;
    return n;
}
   81b78:	d65f03c0 	ret
    for (n = 0; s[n]; n++)
   81b7c:	52800000 	mov	w0, #0x0                   	// #0
}
   81b80:	d65f03c0 	ret
   81b84:	d503201f 	nop

0000000000081b88 <atoi>:

int atoi(const char *s) {
    int n;
    n = 0;
    while ('0' <= *s && *s <= '9')
   81b88:	39400002 	ldrb	w2, [x0]
int atoi(const char *s) {
   81b8c:	aa0003e3 	mov	x3, x0
    while ('0' <= *s && *s <= '9')
   81b90:	5100c040 	sub	w0, w2, #0x30
   81b94:	12001c00 	and	w0, w0, #0xff
   81b98:	7100241f 	cmp	w0, #0x9
    n = 0;
   81b9c:	52800000 	mov	w0, #0x0                   	// #0
    while ('0' <= *s && *s <= '9')
   81ba0:	54000148 	b.hi	81bc8 <atoi+0x40>  // b.pmore
   81ba4:	d503201f 	nop
        n = n * 10 + *s++ - '0';
   81ba8:	0b000800 	add	w0, w0, w0, lsl #2
   81bac:	0b000440 	add	w0, w2, w0, lsl #1
    while ('0' <= *s && *s <= '9')
   81bb0:	38401c62 	ldrb	w2, [x3, #1]!
        n = n * 10 + *s++ - '0';
   81bb4:	5100c000 	sub	w0, w0, #0x30
    while ('0' <= *s && *s <= '9')
   81bb8:	5100c041 	sub	w1, w2, #0x30
   81bbc:	12001c21 	and	w1, w1, #0xff
   81bc0:	7100243f 	cmp	w1, #0x9
   81bc4:	54ffff29 	b.ls	81ba8 <atoi+0x20>  // b.plast
    return n;
}
   81bc8:	d65f03c0 	ret
   81bcc:	00000000 	udf	#0

0000000000081bd0 <initlock>:

// #define SPINLOCK_DEBUG 1

void initlock(struct spinlock *lk, char *name) {
    lk->name = name;
    lk->locked = 0;
   81bd0:	b900001f 	str	wzr, [x0]
    lk->cpu = 0;
   81bd4:	a900fc01 	stp	x1, xzr, [x0, #8]
}
   81bd8:	d65f03c0 	ret
   81bdc:	d503201f 	nop

0000000000081be0 <holding>:
// Check whether this cpu is holding the lock.
// Interrupts must be off.
int holding(struct spinlock *lk) {
    int r;
    // W("%lx %s %d", (unsigned long)lk, lk->name, lk->locked);
    r = (lk->locked && lk->cpu == mycpu());
   81be0:	b9400001 	ldr	w1, [x0]
   81be4:	340000e1 	cbz	w1, 81c00 <holding+0x20>
   81be8:	900000a1 	adrp	x1, 95000 <wordsworth.1722+0xee10>
   81bec:	f9400802 	ldr	x2, [x0, #16]
   81bf0:	f9475c20 	ldr	x0, [x1, #3768]
   81bf4:	eb00005f 	cmp	x2, x0
   81bf8:	1a9f17e0 	cset	w0, eq  // eq = none
    return r;
}
   81bfc:	d65f03c0 	ret
    r = (lk->locked && lk->cpu == mycpu());
   81c00:	52800000 	mov	w0, #0x0                   	// #0
}
   81c04:	d65f03c0 	ret

0000000000081c08 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.
//
// "intena" is the irq status (on/off) when noff (i.e. the "balance") is 0.
// hence, the irq status must be restored when noff reaches 0 again
void push_off(void) {
   81c08:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   81c0c:	910003fd 	mov	x29, sp
   81c10:	f9000bf3 	str	x19, [sp, #16]
void irq_vector_init( void );    
void enable_irq( void ); 
void disable_irq( void );
int is_irq_masked(void); 
/*return 1 if irq enabled, 0 otherwise*/
static inline int intr_get(void) {return 1-is_irq_masked();}; 
   81c14:	940010b9 	bl	85ef8 <is_irq_masked>
   81c18:	2a0003f3 	mov	w19, w0
    int old = intr_get();

    disable_irq();
   81c1c:	940010b5 	bl	85ef0 <disable_irq>
    if (mycpu()->noff == 0)
   81c20:	900000a1 	adrp	x1, 95000 <wordsworth.1722+0xee10>
   81c24:	f9475c23 	ldr	x3, [x1, #3768]
   81c28:	b9400862 	ldr	w2, [x3, #8]
   81c2c:	35000082 	cbnz	w2, 81c3c <push_off+0x34>
   81c30:	52800020 	mov	w0, #0x1                   	// #1
   81c34:	4b130000 	sub	w0, w0, w19
        mycpu()->intena = old;
   81c38:	b9000c60 	str	w0, [x3, #12]
    mycpu()->noff += 1;
   81c3c:	f9475c21 	ldr	x1, [x1, #3768]
   81c40:	11000442 	add	w2, w2, #0x1
}
   81c44:	f9400bf3 	ldr	x19, [sp, #16]
    mycpu()->noff += 1;
   81c48:	b9000822 	str	w2, [x1, #8]
}
   81c4c:	a8c27bfd 	ldp	x29, x30, [sp], #32
   81c50:	d65f03c0 	ret
   81c54:	d503201f 	nop

0000000000081c58 <acquire>:
void acquire(struct spinlock *lk) {
   81c58:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   81c5c:	910003fd 	mov	x29, sp
   81c60:	a90153f3 	stp	x19, x20, [sp, #16]
   81c64:	aa0003f3 	mov	x19, x0
   81c68:	900000b4 	adrp	x20, 95000 <wordsworth.1722+0xee10>
    push_off(); // disable interrupts to avoid deadlock.
   81c6c:	97ffffe7 	bl	81c08 <push_off>
    if (!lk || holding(lk)) {
   81c70:	b4000273 	cbz	x19, 81cbc <acquire+0x64>
    r = (lk->locked && lk->cpu == mycpu());
   81c74:	b9400261 	ldr	w1, [x19]
   81c78:	900000b4 	adrp	x20, 95000 <wordsworth.1722+0xee10>
   81c7c:	34000101 	cbz	w1, 81c9c <acquire+0x44>
   81c80:	f9475e80 	ldr	x0, [x20, #3768]
   81c84:	f9400a62 	ldr	x2, [x19, #16]
   81c88:	eb00005f 	cmp	x2, x0
   81c8c:	54000180 	b.eq	81cbc <acquire+0x64>  // b.none
    while (lk->locked == 1)
   81c90:	7100043f 	cmp	w1, #0x1
   81c94:	54000041 	b.ne	81c9c <acquire+0x44>  // b.any
   81c98:	14000000 	b	81c98 <acquire+0x40>
    lk->locked = 1;
   81c9c:	52800020 	mov	w0, #0x1                   	// #1
   81ca0:	b9000260 	str	w0, [x19]
    __sync_synchronize();
   81ca4:	d5033bbf 	dmb	ish
    lk->cpu = mycpu();
   81ca8:	f9475e94 	ldr	x20, [x20, #3768]
   81cac:	f9000a74 	str	x20, [x19, #16]
}
   81cb0:	a94153f3 	ldp	x19, x20, [sp, #16]
   81cb4:	a8c27bfd 	ldp	x29, x30, [sp], #32
   81cb8:	d65f03c0 	ret
        printf("%s ", lk->name);
   81cbc:	f9400661 	ldr	x1, [x19, #8]
   81cc0:	b0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   81cc4:	911cc000 	add	x0, x0, #0x730
   81cc8:	97fffe54 	bl	81618 <tfp_printf>
        panic("acquire");
   81ccc:	b0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   81cd0:	911ce000 	add	x0, x0, #0x738
   81cd4:	97fffed7 	bl	81830 <panic>
   81cd8:	b9400261 	ldr	w1, [x19]
   81cdc:	17ffffed 	b	81c90 <acquire+0x38>

0000000000081ce0 <pop_off>:

// pop_off must be done with a positive counter (noff)
//  i.e. it's a bug if irq is already enabled and then pop_off
void pop_off(void) {
   81ce0:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   81ce4:	910003fd 	mov	x29, sp
   81ce8:	a90153f3 	stp	x19, x20, [sp, #16]
   81cec:	94001083 	bl	85ef8 <is_irq_masked>
    struct cpu *c = mycpu();
    if (intr_get())
   81cf0:	7100041f 	cmp	w0, #0x1
   81cf4:	54000080 	b.eq	81d04 <pop_off+0x24>  // b.none
        panic("pop_off - interruptible");
   81cf8:	b0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   81cfc:	911d0000 	add	x0, x0, #0x740
   81d00:	97fffecc 	bl	81830 <panic>
    if (c->noff < 1)
   81d04:	900000b3 	adrp	x19, 95000 <wordsworth.1722+0xee10>
   81d08:	f9475e74 	ldr	x20, [x19, #3768]
   81d0c:	b9400a80 	ldr	w0, [x20, #8]
   81d10:	7100001f 	cmp	w0, #0x0
   81d14:	5400014d 	b.le	81d3c <pop_off+0x5c>
        panic("pop_off");
    c->noff -= 1;
   81d18:	f9475e73 	ldr	x19, [x19, #3768]
   81d1c:	51000400 	sub	w0, w0, #0x1
   81d20:	b9000a60 	str	w0, [x19, #8]
    if (c->noff == 0 && c->intena)
   81d24:	35000060 	cbnz	w0, 81d30 <pop_off+0x50>
   81d28:	b9400e60 	ldr	w0, [x19, #12]
   81d2c:	35000120 	cbnz	w0, 81d50 <pop_off+0x70>
        enable_irq();
}
   81d30:	a94153f3 	ldp	x19, x20, [sp, #16]
   81d34:	a8c27bfd 	ldp	x29, x30, [sp], #32
   81d38:	d65f03c0 	ret
        panic("pop_off");
   81d3c:	b0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   81d40:	911d6000 	add	x0, x0, #0x758
   81d44:	97fffebb 	bl	81830 <panic>
   81d48:	b9400a80 	ldr	w0, [x20, #8]
   81d4c:	17fffff3 	b	81d18 <pop_off+0x38>
}
   81d50:	a94153f3 	ldp	x19, x20, [sp, #16]
   81d54:	a8c27bfd 	ldp	x29, x30, [sp], #32
        enable_irq();
   81d58:	14001064 	b	85ee8 <enable_irq>
   81d5c:	d503201f 	nop

0000000000081d60 <release>:
void release(struct spinlock *lk) {
   81d60:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   81d64:	910003fd 	mov	x29, sp
   81d68:	f9000bf3 	str	x19, [sp, #16]
   81d6c:	aa0003f3 	mov	x19, x0
    if (!lk || !holding(lk)) {
   81d70:	b4000060 	cbz	x0, 81d7c <release+0x1c>
    r = (lk->locked && lk->cpu == mycpu());
   81d74:	b9400000 	ldr	w0, [x0]
   81d78:	350001c0 	cbnz	w0, 81db0 <release+0x50>
        printf("%s ", lk->name);
   81d7c:	f9400661 	ldr	x1, [x19, #8]
   81d80:	b0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   81d84:	911cc000 	add	x0, x0, #0x730
   81d88:	97fffe24 	bl	81618 <tfp_printf>
        panic("release");
   81d8c:	b0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   81d90:	911d8000 	add	x0, x0, #0x760
   81d94:	97fffea7 	bl	81830 <panic>
    lk->cpu = 0;
   81d98:	f9000a7f 	str	xzr, [x19, #16]
    __sync_synchronize();
   81d9c:	d5033bbf 	dmb	ish
    lk->locked = 0;
   81da0:	b900027f 	str	wzr, [x19]
}
   81da4:	f9400bf3 	ldr	x19, [sp, #16]
   81da8:	a8c27bfd 	ldp	x29, x30, [sp], #32
    pop_off();
   81dac:	17ffffcd 	b	81ce0 <pop_off>
    r = (lk->locked && lk->cpu == mycpu());
   81db0:	900000a0 	adrp	x0, 95000 <wordsworth.1722+0xee10>
   81db4:	f9400a61 	ldr	x1, [x19, #16]
   81db8:	f9475c00 	ldr	x0, [x0, #3768]
   81dbc:	eb00003f 	cmp	x1, x0
   81dc0:	54fffde1 	b.ne	81d7c <release+0x1c>  // b.any
    lk->cpu = 0;
   81dc4:	f9000a7f 	str	xzr, [x19, #16]
    __sync_synchronize();
   81dc8:	d5033bbf 	dmb	ish
    lk->locked = 0;
   81dcc:	b900027f 	str	wzr, [x19]
}
   81dd0:	f9400bf3 	ldr	x19, [sp, #16]
   81dd4:	a8c27bfd 	ldp	x29, x30, [sp], #32
    pop_off();
   81dd8:	17ffffc2 	b	81ce0 <pop_off>
   81ddc:	00000000 	udf	#0

0000000000081de0 <adjust_sys_timer>:

// we have added/removed a virt timer, now adjust the phys timer accordingly
// caller must hold timerlock
// return 0 on success
static int adjust_sys_timer(void)
{
   81de0:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
   81de4:	910003fd 	mov	x29, sp
   81de8:	a90363f7 	stp	x23, x24, [sp, #48]
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   81dec:	d2860118 	mov	x24, #0x3008                	// #12296
   81df0:	d2860097 	mov	x23, #0x3004                	// #12292
   81df4:	f2a7e018 	movk	x24, #0x3f00, lsl #16
   81df8:	f2a7e017 	movk	x23, #0x3f00, lsl #16
{
   81dfc:	a90153f3 	stp	x19, x20, [sp, #16]
   81e00:	b00000b3 	adrp	x19, 96000 <stdout_putf>
   81e04:	d2800014 	mov	x20, #0x0                   	// #0
   81e08:	91004273 	add	x19, x19, #0x10
   81e0c:	a9025bf5 	stp	x21, x22, [sp, #32]
	unsigned long next = (unsigned long)-1; // upcoming firing time, to be determined
   81e10:	92800015 	mov	x21, #0xffffffffffffffff    	// #-1
				(*timers[tt].handler)(tt, timers[tt].param, timers[tt].context);
				timers[tt].handler = 0; 
			} else 
				/* give "next" a bit slack so current_counter() won't exceed
				"next" before we retuen from this function */
				next = timers[tt].elapseat + 10*1000 /*10ms*/;
   81e14:	d284e216 	mov	x22, #0x2710                	// #10000
   81e18:	14000008 	b	81e38 <adjust_sys_timer+0x58>
				(*timers[tt].handler)(tt, timers[tt].param, timers[tt].context);
   81e1c:	a9410a61 	ldp	x1, x2, [x19, #16]
   81e20:	d63f0060 	blr	x3
				timers[tt].handler = 0; 
   81e24:	f900027f 	str	xzr, [x19]
	for (int tt = 0; tt < N_TIMERS; tt++) {
   81e28:	91000694 	add	x20, x20, #0x1
   81e2c:	91008273 	add	x19, x19, #0x20
   81e30:	f100529f 	cmp	x20, #0x14
   81e34:	54000240 	b.eq	81e7c <adjust_sys_timer+0x9c>  // b.none
		if (!timers[tt].handler)
   81e38:	f9400263 	ldr	x3, [x19]
   81e3c:	b4ffff63 	cbz	x3, 81e28 <adjust_sys_timer+0x48>
		if (timers[tt].elapseat < next) {
   81e40:	f9400661 	ldr	x1, [x19, #8]
   81e44:	eb15003f 	cmp	x1, x21
   81e48:	54ffff02 	b.cs	81e28 <adjust_sys_timer+0x48>  // b.hs, b.nlast
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   81e4c:	b9400302 	ldr	w2, [x24]
				(*timers[tt].handler)(tt, timers[tt].param, timers[tt].context);
   81e50:	aa1403e0 	mov	x0, x20
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   81e54:	b94002e4 	ldr	w4, [x23]
   81e58:	2a0403e4 	mov	w4, w4
   81e5c:	aa028082 	orr	x2, x4, x2, lsl #32
			if (timers[tt].elapseat < current_counter()) {
   81e60:	eb02003f 	cmp	x1, x2
   81e64:	54fffdc3 	b.cc	81e1c <adjust_sys_timer+0x3c>  // b.lo, b.ul, b.last
   81e68:	91000694 	add	x20, x20, #0x1
				next = timers[tt].elapseat + 10*1000 /*10ms*/;
   81e6c:	8b160035 	add	x21, x1, x22
	for (int tt = 0; tt < N_TIMERS; tt++) {
   81e70:	91008273 	add	x19, x19, #0x20
   81e74:	f100529f 	cmp	x20, #0x14
   81e78:	54fffe01 	b.ne	81e38 <adjust_sys_timer+0x58>  // b.any
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   81e7c:	d2860100 	mov	x0, #0x3008                	// #12296
   81e80:	d2860081 	mov	x1, #0x3004                	// #12292
   81e84:	f2a7e000 	movk	x0, #0x3f00, lsl #16
   81e88:	f2a7e001 	movk	x1, #0x3f00, lsl #16
   81e8c:	b9400000 	ldr	w0, [x0]
   81e90:	b9400021 	ldr	w1, [x1]
   81e94:	2a0103e1 	mov	w1, w1
   81e98:	aa008020 	orr	x0, x1, x0, lsl #32
		}
	}

	// a known bug (TBD. may occur: when qemu is very slow, or on actual hw
	// timer expired, but handler not called?? should we handle it?
	BUG_ON(current_counter() > next); 
   81e9c:	eb0002bf 	cmp	x21, x0
   81ea0:	54000183 	b.cc	81ed0 <adjust_sys_timer+0xf0>  // b.lo, b.ul, b.last

	// if no valid handlers, we leave TIMER_C1 as is. it will trigger a timer
	// irq when wrapping around (~4000 sec later). this is fine as our isr
	// compares 64bit counters. 
	if (next == 0xFFFFFFFFFFFFFFFF) 
   81ea4:	b10006bf 	cmn	x21, #0x1
   81ea8:	54000080 	b.eq	81eb8 <adjust_sys_timer+0xd8>  // b.none
		return 0; 

	// the compare reg is only 32 bits so we have to ignore the high 32 bits of
	// the counter. this is ok even if the low 32 bits have to wrap around 
	// in order to match TIMER_C1 (cf the isr)	
	put32(TIMER_C1, (unsigned)next);  
   81eac:	d2860200 	mov	x0, #0x3010                	// #12304
   81eb0:	f2a7e000 	movk	x0, #0x3f00, lsl #16
   81eb4:	b9000015 	str	w21, [x0]

	return 0; 
}
   81eb8:	52800000 	mov	w0, #0x0                   	// #0
   81ebc:	a94153f3 	ldp	x19, x20, [sp, #16]
   81ec0:	a9425bf5 	ldp	x21, x22, [sp, #32]
   81ec4:	a94363f7 	ldp	x23, x24, [sp, #48]
   81ec8:	a8c47bfd 	ldp	x29, x30, [sp], #64
   81ecc:	d65f03c0 	ret
	BUG_ON(current_counter() > next); 
   81ed0:	b0000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   81ed4:	b0000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   81ed8:	911da021 	add	x1, x1, #0x768
   81edc:	911dc000 	add	x0, x0, #0x770
   81ee0:	52801ae2 	mov	w2, #0xd7                  	// #215
   81ee4:	97fffe9d 	bl	81958 <assertion_failed>
	if (next == 0xFFFFFFFFFFFFFFFF) 
   81ee8:	17fffff1 	b	81eac <adjust_sys_timer+0xcc>
   81eec:	d503201f 	nop

0000000000081ef0 <generic_timer_init>:
	asm volatile("msr CNTP_CTL_EL0, %0" : : "r"(1));
   81ef0:	52800020 	mov	w0, #0x1                   	// #1
   81ef4:	d51be220 	msr	cntp_ctl_el0, x0
	generic_timer_reset(interval);	// kickoff 1st time firing
   81ef8:	900000a0 	adrp	x0, 95000 <wordsworth.1722+0xee10>
	asm volatile("msr CNTP_TVAL_EL0, %0" : : "r"(intv));  // TVAL is 32bit, signed
   81efc:	b9451800 	ldr	w0, [x0, #1304]
   81f00:	d51be200 	msr	cntp_tval_el0, x0
}
   81f04:	d65f03c0 	ret

0000000000081f08 <handle_generic_timer_irq>:
	generic_timer_reset(interval);
   81f08:	900000a0 	adrp	x0, 95000 <wordsworth.1722+0xee10>
	asm volatile("msr CNTP_TVAL_EL0, %0" : : "r"(intv));  // TVAL is 32bit, signed
   81f0c:	b9451800 	ldr	w0, [x0, #1304]
   81f10:	d51be200 	msr	cntp_tval_el0, x0
	timer_tick();
   81f14:	14000751 	b	83c58 <timer_tick>

0000000000081f18 <ms_delay>:
	delay(cycles_per_ms * ms); 
   81f18:	52944bc1 	mov	w1, #0xa25e                	// #41566
   81f1c:	72a000c1 	movk	w1, #0x6, lsl #16
   81f20:	1b017c00 	mul	w0, w0, w1
   81f24:	14001017 	b	85f80 <delay>

0000000000081f28 <us_delay>:
	delay(cycles_per_us * us); 
   81f28:	52803641 	mov	w1, #0x1b2                 	// #434
   81f2c:	1b017c00 	mul	w0, w0, w1
   81f30:	14001014 	b	85f80 <delay>
   81f34:	d503201f 	nop

0000000000081f38 <current_time>:
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   81f38:	d2860102 	mov	x2, #0x3008                	// #12296
   81f3c:	d2860085 	mov	x5, #0x3004                	// #12292
   81f40:	f2a7e002 	movk	x2, #0x3f00, lsl #16
   81f44:	f2a7e005 	movk	x5, #0x3f00, lsl #16
	*sec =  (unsigned) (cur / TICKPERSEC); 
   81f48:	d2869b63 	mov	x3, #0x34db                	// #13531
	cur -= (*sec) * TICKPERSEC; 
   81f4c:	52884804 	mov	w4, #0x4240                	// #16960
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   81f50:	b9400042 	ldr	w2, [x2]
	*sec =  (unsigned) (cur / TICKPERSEC); 
   81f54:	f2baf6c3 	movk	x3, #0xd7b6, lsl #16
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   81f58:	b94000a5 	ldr	w5, [x5]
	*sec =  (unsigned) (cur / TICKPERSEC); 
   81f5c:	f2dbd043 	movk	x3, #0xde82, lsl #32
   81f60:	f2e86363 	movk	x3, #0x431b, lsl #48
	cur -= (*sec) * TICKPERSEC; 
   81f64:	72a001e4 	movk	w4, #0xf, lsl #16
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   81f68:	2a0503e5 	mov	w5, w5
	*msec = (unsigned) (cur / TICKPERMS);	
   81f6c:	d29ef9e6 	mov	x6, #0xf7cf                	// #63439
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   81f70:	aa0280a2 	orr	x2, x5, x2, lsl #32
	*msec = (unsigned) (cur / TICKPERMS);	
   81f74:	f2bc6a66 	movk	x6, #0xe353, lsl #16
   81f78:	f2d374a6 	movk	x6, #0x9ba5, lsl #32
   81f7c:	f2e41886 	movk	x6, #0x20c4, lsl #48
	*sec =  (unsigned) (cur / TICKPERSEC); 
   81f80:	9bc37c43 	umulh	x3, x2, x3
   81f84:	d352fc63 	lsr	x3, x3, #18
   81f88:	b9000003 	str	w3, [x0]
	cur -= (*sec) * TICKPERSEC; 
   81f8c:	1b037c83 	mul	w3, w4, w3
   81f90:	cb234042 	sub	x2, x2, w3, uxtw
	*msec = (unsigned) (cur / TICKPERMS);	
   81f94:	d343fc42 	lsr	x2, x2, #3
   81f98:	9bc67c42 	umulh	x2, x2, x6
   81f9c:	d344fc42 	lsr	x2, x2, #4
   81fa0:	b9000022 	str	w2, [x1]
}
   81fa4:	d65f03c0 	ret

0000000000081fa8 <sys_timer_init>:
{
   81fa8:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
	initlock(&timerlock, "timer"); 
   81fac:	900000a0 	adrp	x0, 95000 <wordsworth.1722+0xee10>
   81fb0:	b0000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
{
   81fb4:	910003fd 	mov	x29, sp
	initlock(&timerlock, "timer"); 
   81fb8:	f9474000 	ldr	x0, [x0, #3712]
   81fbc:	911e4021 	add	x1, x1, #0x790
   81fc0:	97ffff04 	bl	81bd0 <initlock>
}
   81fc4:	a8c17bfd 	ldp	x29, x30, [sp], #16
	memzero(timers, sizeof(timers)); 	// all field zeros	
   81fc8:	b00000a0 	adrp	x0, 96000 <stdout_putf>
   81fcc:	52805001 	mov	w1, #0x280                 	// #640
   81fd0:	91004000 	add	x0, x0, #0x10
   81fd4:	17fffe77 	b	819b0 <memzero>

0000000000081fd8 <ktimer_start>:
	adjust_sys_timer(); 
	return t; 
}

int ktimer_start(unsigned delayms, TKernelTimerHandler *handler, 
		void *para, void *context) {
   81fd8:	a9ba7bfd 	stp	x29, x30, [sp, #-96]!
   81fdc:	910003fd 	mov	x29, sp
   81fe0:	a90363f7 	stp	x23, x24, [sp, #48]
	int ret;
	acquire(&timerlock); 
   81fe4:	900000b7 	adrp	x23, 95000 <wordsworth.1722+0xee10>
		void *para, void *context) {
   81fe8:	2a0003f8 	mov	w24, w0
	acquire(&timerlock); 
   81fec:	f94742e0 	ldr	x0, [x23, #3712]
		void *para, void *context) {
   81ff0:	a90153f3 	stp	x19, x20, [sp, #16]
   81ff4:	aa0103f4 	mov	x20, x1
   81ff8:	a9025bf5 	stp	x21, x22, [sp, #32]
   81ffc:	aa0203f5 	mov	x21, x2
   82000:	aa0303f6 	mov	x22, x3
   82004:	f90023f9 	str	x25, [sp, #64]
	acquire(&timerlock); 
   82008:	97ffff14 	bl	81c58 <acquire>
	for (t = 0; t < N_TIMERS; t++) {
   8200c:	900000b9 	adrp	x25, 96000 <stdout_putf>
   82010:	52800013 	mov	w19, #0x0                   	// #0
   82014:	91004320 	add	x0, x25, #0x10
   82018:	14000004 	b	82028 <ktimer_start+0x50>
   8201c:	11000673 	add	w19, w19, #0x1
   82020:	7100527f 	cmp	w19, #0x14
   82024:	54000400 	b.eq	820a4 <ktimer_start+0xcc>  // b.none
		if (timers[t].handler == 0) 
   82028:	f9400001 	ldr	x1, [x0]
   8202c:	91008000 	add	x0, x0, #0x20
   82030:	b5ffff61 	cbnz	x1, 8201c <ktimer_start+0x44>
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   82034:	d2860101 	mov	x1, #0x3008                	// #12296
   82038:	d2860080 	mov	x0, #0x3004                	// #12292
   8203c:	f2a7e001 	movk	x1, #0x3f00, lsl #16
   82040:	f2a7e000 	movk	x0, #0x3f00, lsl #16
	BUG_ON(cur + TICKPERMS * delayms < cur); // 64bit counter wraps around??
   82044:	52807d04 	mov	w4, #0x3e8                 	// #1000
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   82048:	b9400025 	ldr	w5, [x1]
   8204c:	b9400001 	ldr	w1, [x0]
	BUG_ON(cur + TICKPERMS * delayms < cur); // 64bit counter wraps around??
   82050:	1b047f00 	mul	w0, w24, w4
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   82054:	2a0103e1 	mov	w1, w1
   82058:	aa058024 	orr	x4, x1, x5, lsl #32
   8205c:	ab000084 	adds	x4, x4, x0
   82060:	54000322 	b.cs	820c4 <ktimer_start+0xec>  // b.hs, b.nlast
	timers[t].handler = handler; 
   82064:	91004339 	add	x25, x25, #0x10
   82068:	d37b7e61 	ubfiz	x1, x19, #5, #32
   8206c:	8b010320 	add	x0, x25, x1
   82070:	f8216b34 	str	x20, [x25, x1]
	timers[t].param = para; 
   82074:	a900d404 	stp	x4, x21, [x0, #8]
	timers[t].context = context; 
   82078:	f9000c16 	str	x22, [x0, #24]
	adjust_sys_timer(); 
   8207c:	97ffff59 	bl	81de0 <adjust_sys_timer>
	ret = ktimer_start_nolock(delayms, handler, para, context); 
	release(&timerlock); 
   82080:	f94742e0 	ldr	x0, [x23, #3712]
   82084:	97ffff37 	bl	81d60 <release>
	return ret;
}
   82088:	2a1303e0 	mov	w0, w19
   8208c:	a94153f3 	ldp	x19, x20, [sp, #16]
   82090:	a9425bf5 	ldp	x21, x22, [sp, #32]
   82094:	a94363f7 	ldp	x23, x24, [sp, #48]
   82098:	f94023f9 	ldr	x25, [sp, #64]
   8209c:	a8c67bfd 	ldp	x29, x30, [sp], #96
   820a0:	d65f03c0 	ret
		E("ktimer_start failed. # max timer reached"); 
   820a4:	90000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   820a8:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   820ac:	911da021 	add	x1, x1, #0x768
   820b0:	911f2000 	add	x0, x0, #0x7c8
   820b4:	52801ec2 	mov	w2, #0xf6                  	// #246
		return -1; 
   820b8:	12800013 	mov	w19, #0xffffffff            	// #-1
		E("ktimer_start failed. # max timer reached"); 
   820bc:	97fffd57 	bl	81618 <tfp_printf>
		return -1; 
   820c0:	17fffff0 	b	82080 <ktimer_start+0xa8>
	BUG_ON(cur + TICKPERMS * delayms < cur); // 64bit counter wraps around??
   820c4:	90000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   820c8:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   820cc:	911da021 	add	x1, x1, #0x768
   820d0:	911e6000 	add	x0, x0, #0x798
   820d4:	52801f62 	mov	w2, #0xfb                  	// #251
   820d8:	f9002fe4 	str	x4, [sp, #88]
   820dc:	97fffe1f 	bl	81958 <assertion_failed>
   820e0:	f9402fe4 	ldr	x4, [sp, #88]
   820e4:	17ffffe0 	b	82064 <ktimer_start+0x8c>

00000000000820e8 <ktimer_cancel>:
// return 0 on okay, -1 if no such timer/handler, 
//	-2 if already fired (will clean anyway)
int ktimer_cancel(int t) {
	unsigned long cur; 

	if (t < 0 || t >= N_TIMERS)
   820e8:	71004c1f 	cmp	w0, #0x13
   820ec:	54000488 	b.hi	8217c <ktimer_cancel+0x94>  // b.pmore
int ktimer_cancel(int t) {
   820f0:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   820f4:	d2860101 	mov	x1, #0x3008                	// #12296
   820f8:	f2a7e001 	movk	x1, #0x3f00, lsl #16
int ktimer_cancel(int t) {
   820fc:	910003fd 	mov	x29, sp
   82100:	a90153f3 	stp	x19, x20, [sp, #16]
   82104:	2a0003f3 	mov	w19, w0
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   82108:	d2860080 	mov	x0, #0x3004                	// #12292
   8210c:	f2a7e000 	movk	x0, #0x3f00, lsl #16
   82110:	b9400022 	ldr	w2, [x1]
		return -1; 

	cur = current_counter();
	acquire(&timerlock); 
   82114:	f0000094 	adrp	x20, 95000 <wordsworth.1722+0xee10>
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   82118:	b9400001 	ldr	w1, [x0]
	acquire(&timerlock); 
   8211c:	f9474294 	ldr	x20, [x20, #3712]
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   82120:	2a0103e1 	mov	w1, w1
int ktimer_cancel(int t) {
   82124:	f90013f5 	str	x21, [sp, #32]
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   82128:	aa028035 	orr	x21, x1, x2, lsl #32
	acquire(&timerlock); 
   8212c:	aa1403e0 	mov	x0, x20
   82130:	97fffeca 	bl	81c58 <acquire>

	if (!timers[t].handler) {	// invalid handler
   82134:	937b7e61 	sbfiz	x1, x19, #5, #32
   82138:	900000a2 	adrp	x2, 96000 <stdout_putf>
   8213c:	91004042 	add	x2, x2, #0x10
   82140:	8b010043 	add	x3, x2, x1
   82144:	f8616840 	ldr	x0, [x2, x1]
   82148:	b40002a0 	cbz	x0, 8219c <ktimer_cancel+0xb4>
		release(&timerlock); 
		return -1; 
	}

	if (timers[t].elapseat < cur) { // already fired? 
   8214c:	f9400460 	ldr	x0, [x3, #8]
   82150:	eb15001f 	cmp	x0, x21
   82154:	54000183 	b.cc	82184 <ktimer_cancel+0x9c>  // b.lo, b.ul, b.last
		timers[t].param = 0; 
		release(&timerlock); 
		return -2; 
	}

	timers[t].handler = 0; 
   82158:	f821685f 	str	xzr, [x2, x1]

	adjust_sys_timer(); 	
   8215c:	97ffff21 	bl	81de0 <adjust_sys_timer>
	release(&timerlock);
   82160:	aa1403e0 	mov	x0, x20
   82164:	97fffeff 	bl	81d60 <release>

	return 0;  
   82168:	52800000 	mov	w0, #0x0                   	// #0
}
   8216c:	a94153f3 	ldp	x19, x20, [sp, #16]
   82170:	f94013f5 	ldr	x21, [sp, #32]
   82174:	a8c37bfd 	ldp	x29, x30, [sp], #48
   82178:	d65f03c0 	ret
		return -1; 
   8217c:	12800000 	mov	w0, #0xffffffff            	// #-1
}
   82180:	d65f03c0 	ret
		timers[t].handler = 0; 
   82184:	f821685f 	str	xzr, [x2, x1]
		release(&timerlock); 
   82188:	aa1403e0 	mov	x0, x20
		timers[t].context = 0; 
   8218c:	a9017c7f 	stp	xzr, xzr, [x3, #16]
		release(&timerlock); 
   82190:	97fffef4 	bl	81d60 <release>
		return -2; 
   82194:	12800020 	mov	w0, #0xfffffffe            	// #-2
   82198:	17fffff5 	b	8216c <ktimer_cancel+0x84>
		release(&timerlock); 
   8219c:	aa1403e0 	mov	x0, x20
   821a0:	97fffef0 	bl	81d60 <release>
		return -1; 
   821a4:	12800000 	mov	w0, #0xffffffff            	// #-1
   821a8:	17fffff1 	b	8216c <ktimer_cancel+0x84>
   821ac:	d503201f 	nop

00000000000821b0 <sys_timer_irq>:
void sys_timer_irq(void) 
{
	V("called");	

	// timer1 must have pending match. below could happen under high load. why?
	BUG_ON(!(get32(TIMER_CS) & TIMER_CS_M1));  
   821b0:	d2860000 	mov	x0, #0x3000                	// #12288
{
   821b4:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
	BUG_ON(!(get32(TIMER_CS) & TIMER_CS_M1));  
   821b8:	f2a7e000 	movk	x0, #0x3f00, lsl #16
{
   821bc:	910003fd 	mov	x29, sp
	BUG_ON(!(get32(TIMER_CS) & TIMER_CS_M1));  
   821c0:	b9400000 	ldr	w0, [x0]
{
   821c4:	a90153f3 	stp	x19, x20, [sp, #16]
   821c8:	a9025bf5 	stp	x21, x22, [sp, #32]
	BUG_ON(!(get32(TIMER_CS) & TIMER_CS_M1));  
   821cc:	360804c0 	tbz	w0, #1, 82264 <sys_timer_irq+0xb4>
	put32(TIMER_CS, TIMER_CS_M1);	// clear timer1 match
   821d0:	d2860000 	mov	x0, #0x3000                	// #12288
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   821d4:	d2860102 	mov	x2, #0x3008                	// #12296
	put32(TIMER_CS, TIMER_CS_M1);	// clear timer1 match
   821d8:	f2a7e000 	movk	x0, #0x3f00, lsl #16
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   821dc:	d2860081 	mov	x1, #0x3004                	// #12292
	put32(TIMER_CS, TIMER_CS_M1);	// clear timer1 match
   821e0:	52800043 	mov	w3, #0x2                   	// #2
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   821e4:	f2a7e002 	movk	x2, #0x3f00, lsl #16
   821e8:	f2a7e001 	movk	x1, #0x3f00, lsl #16
	put32(TIMER_CS, TIMER_CS_M1);	// clear timer1 match
   821ec:	b9000003 	str	w3, [x0]

	unsigned long cur = current_counter(); 

	acquire(&timerlock); 
   821f0:	f0000096 	adrp	x22, 95000 <wordsworth.1722+0xee10>
   821f4:	900000b3 	adrp	x19, 96000 <stdout_putf>
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   821f8:	b9400055 	ldr	w21, [x2]
   821fc:	91004273 	add	x19, x19, #0x10
   82200:	b9400021 	ldr	w1, [x1]
	acquire(&timerlock); 
   82204:	d2800014 	mov	x20, #0x0                   	// #0
   82208:	f94742c0 	ldr	x0, [x22, #3712]
	return ((unsigned long) get32(TIMER_CHI) << 32) | get32(TIMER_CLO); 
   8220c:	2a0103e1 	mov	w1, w1
   82210:	aa158035 	orr	x21, x1, x21, lsl #32
	acquire(&timerlock); 
   82214:	97fffe91 	bl	81c58 <acquire>
	for (int t = 0; t < N_TIMERS; t++) {
		TKernelTimerHandler *h = timers[t].handler; 
   82218:	f9400263 	ldr	x3, [x19]
		if (h == 0) 
			continue; 
		if (timers[t].elapseat <= cur) { // should fire  
			V("called, id %d h %lx", t, (unsigned long)timers[t].handler);	
			timers[t].handler = 0; 
			(*h)(t, timers[t].param, timers[t].context); 			
   8221c:	aa1403e0 	mov	x0, x20
   82220:	91000694 	add	x20, x20, #0x1
		if (h == 0) 
   82224:	b40000e3 	cbz	x3, 82240 <sys_timer_irq+0x90>
		if (timers[t].elapseat <= cur) { // should fire  
   82228:	f9400661 	ldr	x1, [x19, #8]
   8222c:	eb15003f 	cmp	x1, x21
   82230:	54000088 	b.hi	82240 <sys_timer_irq+0x90>  // b.pmore
			(*h)(t, timers[t].param, timers[t].context); 			
   82234:	a9410a61 	ldp	x1, x2, [x19, #16]
			timers[t].handler = 0; 
   82238:	f900027f 	str	xzr, [x19]
			(*h)(t, timers[t].param, timers[t].context); 			
   8223c:	d63f0060 	blr	x3
	for (int t = 0; t < N_TIMERS; t++) {
   82240:	91008273 	add	x19, x19, #0x20
   82244:	f100529f 	cmp	x20, #0x14
   82248:	54fffe81 	b.ne	82218 <sys_timer_irq+0x68>  // b.any
		}		
	}
	adjust_sys_timer(); 
   8224c:	97fffee5 	bl	81de0 <adjust_sys_timer>
	release(&timerlock);
   82250:	f94742c0 	ldr	x0, [x22, #3712]
}
   82254:	a94153f3 	ldp	x19, x20, [sp, #16]
   82258:	a9425bf5 	ldp	x21, x22, [sp, #32]
   8225c:	a8c37bfd 	ldp	x29, x30, [sp], #48
	release(&timerlock);
   82260:	17fffec0 	b	81d60 <release>
	BUG_ON(!(get32(TIMER_CS) & TIMER_CS_M1));  
   82264:	90000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   82268:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   8226c:	911da021 	add	x1, x1, #0x768
   82270:	91202000 	add	x0, x0, #0x808
   82274:	528026c2 	mov	w2, #0x136                 	// #310
   82278:	97fffdb8 	bl	81958 <assertion_failed>
   8227c:	17ffffd5 	b	821d0 <sys_timer_irq+0x20>

0000000000082280 <mbox_call>:
 * Returns 0 on failure, non-zero on success
 * 
 * caller must hold mboxlock
 */
int mbox_call(unsigned char ch)
{
   82280:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
    // the buf addr (pa) w/ ch (chan id) in LSB 
    unsigned int r = (((unsigned int)((unsigned long)&mbox)&~0xF) | (ch&0xF));
    r = BUS_ADDRESS(r); 
    /* wait until we can write to the mailbox */
    do{asm volatile("nop");}while(*MBOX_STATUS & MBOX_FULL);
   82284:	d2971301 	mov	x1, #0xb898                	// #47256
   82288:	f2a7e001 	movk	x1, #0x3f00, lsl #16
{
   8228c:	910003fd 	mov	x29, sp
   82290:	a90363f7 	stp	x23, x24, [sp, #48]
    unsigned int r = (((unsigned int)((unsigned long)&mbox)&~0xF) | (ch&0xF));
   82294:	f0000098 	adrp	x24, 95000 <wordsworth.1722+0xee10>
{
   82298:	a90153f3 	stp	x19, x20, [sp, #16]
    unsigned int r = (((unsigned int)((unsigned long)&mbox)&~0xF) | (ch&0xF));
   8229c:	12000c14 	and	w20, w0, #0xf
   822a0:	f9473f00 	ldr	x0, [x24, #3704]
{
   822a4:	a9025bf5 	stp	x21, x22, [sp, #32]
    unsigned int r = (((unsigned int)((unsigned long)&mbox)&~0xF) | (ch&0xF));
   822a8:	2a000294 	orr	w20, w20, w0
    r = BUS_ADDRESS(r); 
   822ac:	32020694 	orr	w20, w20, #0xc0000000
    do{asm volatile("nop");}while(*MBOX_STATUS & MBOX_FULL);
   822b0:	d503201f 	nop
   822b4:	b9400020 	ldr	w0, [x1]
   822b8:	37ffffc0 	tbnz	w0, #31, 822b0 <mbox_call+0x30>
    __asm__ volatile ("dmb sy" ::: "memory");    // mem barrier, ensuring msg in mem
   822bc:	d5033fbf 	dmb	sy
    __asm_flush_dcache_range((void *)mbox, (char *)mbox + sizeof(mbox)); 
   822c0:	f9473f00 	ldr	x0, [x24, #3704]
    /* write the address of our message to the mailbox with channel identifier */
    *MBOX_WRITE = r; 
    /* now wait for the response */
    while(1) {
        /* is there a response? */
        do{asm volatile("nop");}while(*MBOX_STATUS & MBOX_EMPTY);
   822c4:	d2971313 	mov	x19, #0xb898                	// #47256
        /* is it a response to our message? */
        if(r == *MBOX_READ) {
   822c8:	d2971017 	mov	x23, #0xb880                	// #47232
            __asm_invalidate_dcache_range((void *)mbox, (char *)mbox + sizeof(mbox)); 
            /* is it a valid successful response? (strange it's benign) */
            if (mbox[1]!=MBOX_RESPONSE) I("mbox[1] is %08x", mbox[1]);            
            return mbox[1]==MBOX_RESPONSE;
        } else {
            W("got an irrelvant msg. bug?"); 
   822cc:	90000035 	adrp	x21, 86000 <__asm_dcache_level+0xc>
    __asm_flush_dcache_range((void *)mbox, (char *)mbox + sizeof(mbox)); 
   822d0:	91024001 	add	x1, x0, #0x90
            W("got an irrelvant msg. bug?"); 
   822d4:	912162b5 	add	x21, x21, #0x858
    __asm_flush_dcache_range((void *)mbox, (char *)mbox + sizeof(mbox)); 
   822d8:	94000f2d 	bl	85f8c <__asm_flush_dcache_range>
        do{asm volatile("nop");}while(*MBOX_STATUS & MBOX_EMPTY);
   822dc:	f2a7e013 	movk	x19, #0x3f00, lsl #16
    *MBOX_WRITE = r; 
   822e0:	d2971400 	mov	x0, #0xb8a0                	// #47264
        if(r == *MBOX_READ) {
   822e4:	f2a7e017 	movk	x23, #0x3f00, lsl #16
    *MBOX_WRITE = r; 
   822e8:	f2a7e000 	movk	x0, #0x3f00, lsl #16
            W("got an irrelvant msg. bug?"); 
   822ec:	90000036 	adrp	x22, 86000 <__asm_dcache_level+0xc>
    *MBOX_WRITE = r; 
   822f0:	b9000014 	str	w20, [x0]
   822f4:	d503201f 	nop
        do{asm volatile("nop");}while(*MBOX_STATUS & MBOX_EMPTY);
   822f8:	d503201f 	nop
   822fc:	b9400260 	ldr	w0, [x19]
   82300:	37f7ffc0 	tbnz	w0, #30, 822f8 <mbox_call+0x78>
        if(r == *MBOX_READ) {
   82304:	b94002e3 	ldr	w3, [x23]
            W("got an irrelvant msg. bug?"); 
   82308:	aa1503e1 	mov	x1, x21
   8230c:	912222c0 	add	x0, x22, #0x888
   82310:	52800822 	mov	w2, #0x41                  	// #65
        if(r == *MBOX_READ) {
   82314:	6b14007f 	cmp	w3, w20
   82318:	54000060 	b.eq	82324 <mbox_call+0xa4>  // b.none
            W("got an irrelvant msg. bug?"); 
   8231c:	97fffcbf 	bl	81618 <tfp_printf>
    while(1) {
   82320:	17fffff6 	b	822f8 <mbox_call+0x78>
            __asm_invalidate_dcache_range((void *)mbox, (char *)mbox + sizeof(mbox)); 
   82324:	f9473f13 	ldr	x19, [x24, #3704]
   82328:	91024261 	add	x1, x19, #0x90
   8232c:	aa1303e0 	mov	x0, x19
   82330:	94000f24 	bl	85fc0 <__asm_invalidate_dcache_range>
            if (mbox[1]!=MBOX_RESPONSE) I("mbox[1] is %08x", mbox[1]);            
   82334:	b9400661 	ldr	w1, [x19, #4]
   82338:	52b00000 	mov	w0, #0x80000000            	// #-2147483648
   8233c:	6b00003f 	cmp	w1, w0
   82340:	54000100 	b.eq	82360 <mbox_call+0xe0>  // b.none
   82344:	b9400663 	ldr	w3, [x19, #4]
   82348:	90000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   8234c:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   82350:	91216021 	add	x1, x1, #0x858
   82354:	91218000 	add	x0, x0, #0x860
   82358:	528007c2 	mov	w2, #0x3e                  	// #62
   8235c:	97fffcaf 	bl	81618 <tfp_printf>
            return mbox[1]==MBOX_RESPONSE;
   82360:	f9473f18 	ldr	x24, [x24, #3704]
   82364:	52b00000 	mov	w0, #0x80000000            	// #-2147483648
        }
    }
    return 0;
}
   82368:	a94153f3 	ldp	x19, x20, [sp, #16]
            return mbox[1]==MBOX_RESPONSE;
   8236c:	b9400701 	ldr	w1, [x24, #4]
}
   82370:	a9425bf5 	ldp	x21, x22, [sp, #32]
            return mbox[1]==MBOX_RESPONSE;
   82374:	6b00003f 	cmp	w1, w0
   82378:	1a9f17e0 	cset	w0, eq  // eq = none
}
   8237c:	a94363f7 	ldp	x23, x24, [sp, #48]
   82380:	a8c47bfd 	ldp	x29, x30, [sp], #64
   82384:	d65f03c0 	ret

0000000000082388 <fb_detect_scr_dim>:
    return: 0 on success 

    FL's 720p monitor: 1360 768
    qemu 640 480 (initial? subject to reconfig for larger fb)
*/
int fb_detect_scr_dim(uint *w, uint *h) {
   82388:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
    mbox[0] = 8*4;     // size of the whole buf that follows
   8238c:	52800404 	mov	w4, #0x20                  	// #32
    mbox[1] = MBOX_REQUEST; // cpu->gpu request
        mbox[2] = 0x40003;     // rls framebuffer
   82390:	52800063 	mov	w3, #0x3                   	// #3
int fb_detect_scr_dim(uint *w, uint *h) {
   82394:	910003fd 	mov	x29, sp
   82398:	a90153f3 	stp	x19, x20, [sp, #16]
    mbox[0] = 8*4;     // size of the whole buf that follows
   8239c:	f0000093 	adrp	x19, 95000 <wordsworth.1722+0xee10>
        mbox[2] = 0x40003;     // rls framebuffer
   823a0:	72a00083 	movk	w3, #0x4, lsl #16
    mbox[0] = 8*4;     // size of the whole buf that follows
   823a4:	f9473e73 	ldr	x19, [x19, #3704]
int fb_detect_scr_dim(uint *w, uint *h) {
   823a8:	a9025bf5 	stp	x21, x22, [sp, #32]
        mbox[3] = 8;           // total buf size
   823ac:	52800102 	mov	w2, #0x8                   	// #8
int fb_detect_scr_dim(uint *w, uint *h) {
   823b0:	aa0003f4 	mov	x20, x0
   823b4:	aa0103f5 	mov	x21, x1
    mbox[0] = 8*4;     // size of the whole buf that follows
   823b8:	b9000264 	str	w4, [x19]
        mbox[4] = 0;           // req para size
        mbox[5] = 0;           // resp: width
        mbox[6] = 0;           // resp: height
    mbox[7] = MBOX_TAG_LAST;

    if(!mbox_call(MBOX_CH_PROP)) {
   823bc:	2a0203e0 	mov	w0, w2
    mbox[1] = MBOX_REQUEST; // cpu->gpu request
   823c0:	b900067f 	str	wzr, [x19, #4]
        mbox[2] = 0x40003;     // rls framebuffer
   823c4:	b9000a63 	str	w3, [x19, #8]
        mbox[3] = 8;           // total buf size
   823c8:	b9000e62 	str	w2, [x19, #12]
        mbox[4] = 0;           // req para size
   823cc:	b900127f 	str	wzr, [x19, #16]
        mbox[5] = 0;           // resp: width
   823d0:	b900167f 	str	wzr, [x19, #20]
        mbox[6] = 0;           // resp: height
   823d4:	b9001a7f 	str	wzr, [x19, #24]
    mbox[7] = MBOX_TAG_LAST;
   823d8:	b9001e7f 	str	wzr, [x19, #28]
    if(!mbox_call(MBOX_CH_PROP)) {
   823dc:	97ffffa9 	bl	82280 <mbox_call>
   823e0:	340004a0 	cbz	w0, 82474 <fb_detect_scr_dim+0xec>
        E("failed to get screen dim");
        return -1;
    } 

    *w=mbox[5];*h=mbox[6]; I("detected screen dim %d %d", *w, *h);
   823e4:	b9401660 	ldr	w0, [x19, #20]
   823e8:	90000036 	adrp	x22, 86000 <__asm_dcache_level+0xc>
   823ec:	b9000280 	str	w0, [x20]
   823f0:	912162c1 	add	x1, x22, #0x858
   823f4:	52801a02 	mov	w2, #0xd0                  	// #208
   823f8:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   823fc:	b9401a64 	ldr	w4, [x19, #24]
   82400:	9123a000 	add	x0, x0, #0x8e8
   82404:	b90002a4 	str	w4, [x21]
   82408:	b9400283 	ldr	w3, [x20]
   8240c:	97fffc83 	bl	81618 <tfp_printf>

    if (*w == 1184 || *h == 624) {
   82410:	b9400280 	ldr	w0, [x20]
   82414:	7112801f 	cmp	w0, #0x4a0
   82418:	54000120 	b.eq	8243c <fb_detect_scr_dim+0xb4>  // b.none
   8241c:	b94002a1 	ldr	w1, [x21]
        W("detected screen 1184x624. assume a Waveshare HAT. force 480 320");
        *w = 480; *h = 320;
    }    
    return 0; 
   82420:	52800000 	mov	w0, #0x0                   	// #0
    if (*w == 1184 || *h == 624) {
   82424:	7109c03f 	cmp	w1, #0x270
   82428:	540000a0 	b.eq	8243c <fb_detect_scr_dim+0xb4>  // b.none
}
   8242c:	a94153f3 	ldp	x19, x20, [sp, #16]
   82430:	a9425bf5 	ldp	x21, x22, [sp, #32]
   82434:	a8c37bfd 	ldp	x29, x30, [sp], #48
   82438:	d65f03c0 	ret
        W("detected screen 1184x624. assume a Waveshare HAT. force 480 320");
   8243c:	912162c1 	add	x1, x22, #0x858
   82440:	52801a62 	mov	w2, #0xd3                  	// #211
   82444:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   82448:	91246000 	add	x0, x0, #0x918
   8244c:	97fffc73 	bl	81618 <tfp_printf>
        *w = 480; *h = 320;
   82450:	52803c00 	mov	w0, #0x1e0                 	// #480
   82454:	b9000280 	str	w0, [x20]
   82458:	52802801 	mov	w1, #0x140                 	// #320
   8245c:	b90002a1 	str	w1, [x21]
    return 0; 
   82460:	52800000 	mov	w0, #0x0                   	// #0
}
   82464:	a94153f3 	ldp	x19, x20, [sp, #16]
   82468:	a9425bf5 	ldp	x21, x22, [sp, #32]
   8246c:	a8c37bfd 	ldp	x29, x30, [sp], #48
   82470:	d65f03c0 	ret
        E("failed to get screen dim");
   82474:	90000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   82478:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   8247c:	91216021 	add	x1, x1, #0x858
   82480:	9122e000 	add	x0, x0, #0x8b8
   82484:	52801982 	mov	w2, #0xcc                  	// #204
   82488:	97fffc64 	bl	81618 <tfp_printf>
        return -1;
   8248c:	12800000 	mov	w0, #0xffffffff            	// #-1
   82490:	17ffffe7 	b	8242c <fb_detect_scr_dim+0xa4>
   82494:	d503201f 	nop

0000000000082498 <fb_set_voffsets>:

// set virt offset
// caller must hold mboxlock
// 0 on success
int fb_set_voffsets(int offsetx, int offsety) {
   82498:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!

    mbox[0] = 8*4;
   8249c:	52800404 	mov	w4, #0x20                  	// #32
    mbox[1] = MBOX_REQUEST;
    
    mbox[2] = 0x48009; 
   824a0:	52900123 	mov	w3, #0x8009                	// #32777
int fb_set_voffsets(int offsetx, int offsety) {
   824a4:	910003fd 	mov	x29, sp
   824a8:	a9025bf5 	stp	x21, x22, [sp, #32]
    mbox[0] = 8*4;
   824ac:	f0000096 	adrp	x22, 95000 <wordsworth.1722+0xee10>
    mbox[2] = 0x48009; 
   824b0:	72a00083 	movk	w3, #0x4, lsl #16
int fb_set_voffsets(int offsetx, int offsety) {
   824b4:	a90153f3 	stp	x19, x20, [sp, #16]
    mbox[3] = 8;
   824b8:	52800102 	mov	w2, #0x8                   	// #8
int fb_set_voffsets(int offsetx, int offsety) {
   824bc:	2a0003f4 	mov	w20, w0
    mbox[0] = 8*4;
   824c0:	f9473ed3 	ldr	x19, [x22, #3704]
int fb_set_voffsets(int offsetx, int offsety) {
   824c4:	2a0103f5 	mov	w21, w1
    mbox[5] =  offsetx;           //FrameBufferInfo.x_offset
    mbox[6] =  offsety;           //FrameBufferInfo.y.offset    

    mbox[7] = MBOX_TAG_LAST;

    if(!mbox_call(MBOX_CH_PROP)) {
   824c8:	2a0203e0 	mov	w0, w2
    mbox[0] = 8*4;
   824cc:	b9000264 	str	w4, [x19]
    mbox[1] = MBOX_REQUEST;
   824d0:	b900067f 	str	wzr, [x19, #4]
    mbox[2] = 0x48009; 
   824d4:	b9000a63 	str	w3, [x19, #8]
    mbox[3] = 8;
   824d8:	b9000e62 	str	w2, [x19, #12]
    mbox[4] = 8;
   824dc:	b9001262 	str	w2, [x19, #16]
    mbox[5] =  offsetx;           //FrameBufferInfo.x_offset
   824e0:	b9001674 	str	w20, [x19, #20]
    mbox[6] =  offsety;           //FrameBufferInfo.y.offset    
   824e4:	b9001a61 	str	w1, [x19, #24]
    mbox[7] = MBOX_TAG_LAST;
   824e8:	b9001e7f 	str	wzr, [x19, #28]
    if(!mbox_call(MBOX_CH_PROP)) {
   824ec:	97ffff65 	bl	82280 <mbox_call>
   824f0:	34000320 	cbz	w0, 82554 <fb_set_voffsets+0xbc>
        E("failed to set virt offsets, requested x=%d y=%d", offsetx, offsety);
        return -1;
    }     
     if (mbox[5] != offsetx || mbox[6] != offsety) {
   824f4:	b9401660 	ldr	w0, [x19, #20]
   824f8:	6b00029f 	cmp	w20, w0
   824fc:	54000121 	b.ne	82520 <fb_set_voffsets+0x88>  // b.any
   82500:	b9401a61 	ldr	w1, [x19, #24]
            offsetx, offsety, mbox[5], mbox[6]);
        return -1;     
     }
     V("set OK: offsetx %u offsety %u res: offsetx %u offsety %u", 
            offsetx, offsety, mbox[5], mbox[6]);
     return 0; 
   82504:	52800000 	mov	w0, #0x0                   	// #0
     if (mbox[5] != offsetx || mbox[6] != offsety) {
   82508:	6b0102bf 	cmp	w21, w1
   8250c:	540000a1 	b.ne	82520 <fb_set_voffsets+0x88>  // b.any
}
   82510:	a94153f3 	ldp	x19, x20, [sp, #16]
   82514:	a9425bf5 	ldp	x21, x22, [sp, #32]
   82518:	a8c37bfd 	ldp	x29, x30, [sp], #48
   8251c:	d65f03c0 	ret
        E("failed set: offsetx %u offsety %u res: offsetx %u offsety %u", 
   82520:	f9473ed6 	ldr	x22, [x22, #3704]
   82524:	2a1503e4 	mov	w4, w21
   82528:	2a1403e3 	mov	w3, w20
   8252c:	90000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   82530:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   82534:	91216021 	add	x1, x1, #0x858
   82538:	b94016c5 	ldr	w5, [x22, #20]
   8253c:	9126e000 	add	x0, x0, #0x9b8
   82540:	b9401ac6 	ldr	w6, [x22, #24]
   82544:	52801dc2 	mov	w2, #0xee                  	// #238
   82548:	97fffc34 	bl	81618 <tfp_printf>
        return -1;     
   8254c:	12800000 	mov	w0, #0xffffffff            	// #-1
   82550:	17fffff0 	b	82510 <fb_set_voffsets+0x78>
        E("failed to set virt offsets, requested x=%d y=%d", offsetx, offsety);
   82554:	2a1503e4 	mov	w4, w21
   82558:	2a1403e3 	mov	w3, w20
   8255c:	90000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   82560:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   82564:	91216021 	add	x1, x1, #0x858
   82568:	9125c000 	add	x0, x0, #0x970
   8256c:	52801d42 	mov	w2, #0xea                  	// #234
   82570:	97fffc2a 	bl	81618 <tfp_printf>
        return -1;
   82574:	12800000 	mov	w0, #0xffffffff            	// #-1
   82578:	17ffffe6 	b	82510 <fb_set_voffsets+0x78>
   8257c:	d503201f 	nop

0000000000082580 <fb_fini>:
}

/* finalize the fb, clean up. 
    return 0 on success (display will go blank)
*/
int fb_fini(void) {
   82580:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   82584:	910003fd 	mov	x29, sp
   82588:	a90153f3 	stp	x19, x20, [sp, #16]
    int ret = 0; 

    acquire(&mboxlock); 
    if (!the_fb.fb || !the_fb.size) {
   8258c:	f0000093 	adrp	x19, 95000 <wordsworth.1722+0xee10>
int fb_fini(void) {
   82590:	f90013f5 	str	x21, [sp, #32]
    acquire(&mboxlock); 
   82594:	f0000095 	adrp	x21, 95000 <wordsworth.1722+0xee10>
   82598:	913802a0 	add	x0, x21, #0xe00
   8259c:	97fffdaf 	bl	81c58 <acquire>
    if (!the_fb.fb || !the_fb.size) {
   825a0:	f9429260 	ldr	x0, [x19, #1312]
   825a4:	b4000620 	cbz	x0, 82668 <fb_fini+0xe8>
   825a8:	91148261 	add	x1, x19, #0x520
   825ac:	b9403422 	ldr	w2, [x1, #52]
   825b0:	340005c2 	cbz	w2, 82668 <fb_fini+0xe8>
        ret = -1; 
        goto out; 
    }

#ifdef PLAT_RPI3QEMU    // avoid artifacts: qemu does not clear old fb
    memset(the_fb.fb, 0, the_fb.size);     
   825b4:	52800001 	mov	w1, #0x0                   	// #0
   825b8:	97fffcf4 	bl	81988 <memset>
#endif

    mbox[0] = 6*4;     // size of the whole buf that follows
   825bc:	f0000081 	adrp	x1, 95000 <wordsworth.1722+0xee10>
   825c0:	52800303 	mov	w3, #0x18                  	// #24
    mbox[1] = MBOX_REQUEST; // cpu->gpu request

    mbox[2] = 0x48001;     // rls framebuffer
   825c4:	52900022 	mov	w2, #0x8001                	// #32769
    mbox[3] = 0;           // total buf size
    mbox[4] = 0;           // req para size
        
    mbox[5] = MBOX_TAG_LAST;

    if(!mbox_call(MBOX_CH_PROP))
   825c8:	52800100 	mov	w0, #0x8                   	// #8
    mbox[0] = 6*4;     // size of the whole buf that follows
   825cc:	f9473c21 	ldr	x1, [x1, #3704]
    mbox[2] = 0x48001;     // rls framebuffer
   825d0:	72a00082 	movk	w2, #0x4, lsl #16
    mbox[0] = 6*4;     // size of the whole buf that follows
   825d4:	b9000023 	str	w3, [x1]
    mbox[1] = MBOX_REQUEST; // cpu->gpu request
   825d8:	b900043f 	str	wzr, [x1, #4]
    mbox[2] = 0x48001;     // rls framebuffer
   825dc:	b9000822 	str	w2, [x1, #8]
    mbox[3] = 0;           // total buf size
   825e0:	b9000c3f 	str	wzr, [x1, #12]
    mbox[4] = 0;           // req para size
   825e4:	b900103f 	str	wzr, [x1, #16]
    mbox[5] = MBOX_TAG_LAST;
   825e8:	b900143f 	str	wzr, [x1, #20]
    if(!mbox_call(MBOX_CH_PROP))
   825ec:	97ffff25 	bl	82280 <mbox_call>
   825f0:	340002e0 	cbz	w0, 8264c <fb_fini+0xcc>
        I("failed to rls fb with GPU (could be benign)"); 
        // response code always 0x80000001 (failure). couldn't figure out why

    if (free_phys_region((unsigned long)the_fb.fb, the_fb.size)) {
   825f4:	91148261 	add	x1, x19, #0x520
   825f8:	f9429260 	ldr	x0, [x19, #1312]
   825fc:	b9403421 	ldr	w1, [x1, #52]
   82600:	940003f4 	bl	835d0 <free_phys_region>
   82604:	2a0003f4 	mov	w20, w0
   82608:	35000120 	cbnz	w0, 8262c <fb_fini+0xac>
        E("failed to free fb memory. bug?"); 
        ret = -2; 
    }
    the_fb.fb = 0; 
   8260c:	f902927f 	str	xzr, [x19, #1312]
out:
    release(&mboxlock);          
   82610:	913802a0 	add	x0, x21, #0xe00
   82614:	97fffdd3 	bl	81d60 <release>
    return ret; 
}
   82618:	2a1403e0 	mov	w0, w20
   8261c:	a94153f3 	ldp	x19, x20, [sp, #16]
   82620:	f94013f5 	ldr	x21, [sp, #32]
   82624:	a8c37bfd 	ldp	x29, x30, [sp], #48
   82628:	d65f03c0 	ret
        ret = -2; 
   8262c:	12800034 	mov	w20, #0xfffffffe            	// #-2
        E("failed to free fb memory. bug?"); 
   82630:	90000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   82634:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   82638:	91216021 	add	x1, x1, #0x858
   8263c:	91292000 	add	x0, x0, #0xa48
   82640:	528030a2 	mov	w2, #0x185                 	// #389
   82644:	97fffbf5 	bl	81618 <tfp_printf>
        ret = -2; 
   82648:	17fffff1 	b	8260c <fb_fini+0x8c>
        I("failed to rls fb with GPU (could be benign)"); 
   8264c:	90000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   82650:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   82654:	91216021 	add	x1, x1, #0x858
   82658:	91282000 	add	x0, x0, #0xa08
   8265c:	52803022 	mov	w2, #0x181                 	// #385
   82660:	97fffbee 	bl	81618 <tfp_printf>
   82664:	17ffffe4 	b	825f4 <fb_fini+0x74>
        ret = -1; 
   82668:	12800014 	mov	w20, #0xffffffff            	// #-1
   8266c:	17ffffe9 	b	82610 <fb_fini+0x90>

0000000000082670 <fb_print>:
    unsigned char *fb = the_fb.fb; 

    // get our font
    psf_t *font = (psf_t*)&_binary_font_psf_start;
    // draw next character if it's not zero
    while(*s) {
   82670:	39400043 	ldrb	w3, [x2]
    unsigned pitch = the_fb.pitch; 
   82674:	f0000084 	adrp	x4, 95000 <wordsworth.1722+0xee10>
   82678:	91148085 	add	x5, x4, #0x520
    unsigned char *fb = the_fb.fb; 
   8267c:	f942908f 	ldr	x15, [x4, #1312]
    unsigned pitch = the_fb.pitch; 
   82680:	b94018aa 	ldr	w10, [x5, #24]
    while(*s) {
   82684:	34000f23 	cbz	w3, 82868 <fb_print+0x1f8>
{
   82688:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
        /* get offset of the glyph. Need to adjust this to support unicode table */
        unsigned char *glyph = (unsigned char*)&_binary_font_psf_start +
         font->headersize + (*((unsigned char*)s)<font->numglyph?*s:0)*font->bytesperglyph;
   8268c:	f0000084 	adrp	x4, 95000 <wordsworth.1722+0xee10>
        } else {
            // display a character
            for(j=0;j<font->height;j++){
                // display one row
                line=offs;
                mask=1<<(font->width-1);
   82690:	5280002e 	mov	w14, #0x1                   	// #1
{
   82694:	910003fd 	mov	x29, sp
         font->headersize + (*((unsigned char*)s)<font->numglyph?*s:0)*font->bytesperglyph;
   82698:	f9476c84 	ldr	x4, [x4, #3800]
{
   8269c:	a90153f3 	stp	x19, x20, [sp, #16]
   826a0:	910011f1 	add	x17, x15, #0x4
   826a4:	a9025bf5 	stp	x21, x22, [sp, #32]
        unsigned char *glyph = (unsigned char*)&_binary_font_psf_start +
   826a8:	aa0403f4 	mov	x20, x4
                for(i=0;i<font->width;i++){
                    // if bit set, we use white color, otherwise black
                    *((unsigned int*)(fb + line))=((int)*glyph) & mask?0xFFFFFF:0;
   826ac:	12bfe008 	mov	w8, #0xffffff              	// #16777215
         font->headersize + (*((unsigned char*)s)<font->numglyph?*s:0)*font->bytesperglyph;
   826b0:	39402085 	ldrb	w5, [x4, #8]
   826b4:	39402489 	ldrb	w9, [x4, #9]
   826b8:	92401ca5 	and	x5, x5, #0xff
   826bc:	3940288c 	ldrb	w12, [x4, #10]
   826c0:	39402c96 	ldrb	w22, [x4, #11]
   826c4:	d3781d29 	ubfiz	x9, x9, #8, #8
   826c8:	39404086 	ldrb	w6, [x4, #16]
   826cc:	39404487 	ldrb	w7, [x4, #17]
   826d0:	aa050129 	orr	x9, x9, x5
   826d4:	3940489e 	ldrb	w30, [x4, #18]
   826d8:	92401cc6 	and	x6, x6, #0xff
   826dc:	39404c8d 	ldrb	w13, [x4, #19]
   826e0:	d3701d8c 	ubfiz	x12, x12, #16, #8
   826e4:	39405085 	ldrb	w5, [x4, #20]
   826e8:	d3781ce7 	ubfiz	x7, x7, #8, #8
   826ec:	3940548b 	ldrb	w11, [x4, #21]
   826f0:	aa0600e7 	orr	x7, x7, x6
   826f4:	92401ca5 	and	x5, x5, #0xff
   826f8:	39405886 	ldrb	w6, [x4, #22]
   826fc:	39405c92 	ldrb	w18, [x4, #23]
   82700:	aa09018c 	orr	x12, x12, x9
        int i,j, line,mask, bytesperline=(font->width+7)/8;
   82704:	39407090 	ldrb	w16, [x4, #28]
         font->headersize + (*((unsigned char*)s)<font->numglyph?*s:0)*font->bytesperglyph;
   82708:	d3781d6b 	ubfiz	x11, x11, #8, #8
        int i,j, line,mask, bytesperline=(font->width+7)/8;
   8270c:	39407493 	ldrb	w19, [x4, #29]
         font->headersize + (*((unsigned char*)s)<font->numglyph?*s:0)*font->bytesperglyph;
   82710:	aa05016b 	orr	x11, x11, x5
        int i,j, line,mask, bytesperline=(font->width+7)/8;
   82714:	39407885 	ldrb	w5, [x4, #30]
   82718:	92401e10 	and	x16, x16, #0xff
   8271c:	39407c95 	ldrb	w21, [x4, #31]
         font->headersize + (*((unsigned char*)s)<font->numglyph?*s:0)*font->bytesperglyph;
   82720:	d3701cc6 	ubfiz	x6, x6, #16, #8
        int i,j, line,mask, bytesperline=(font->width+7)/8;
   82724:	d3781e73 	ubfiz	x19, x19, #8, #8
         font->headersize + (*((unsigned char*)s)<font->numglyph?*s:0)*font->bytesperglyph;
   82728:	d3701fde 	ubfiz	x30, x30, #16, #8
        int i,j, line,mask, bytesperline=(font->width+7)/8;
   8272c:	aa100273 	orr	x19, x19, x16
   82730:	d3701ca5 	ubfiz	x5, x5, #16, #8
            for(j=0;j<font->height;j++){
   82734:	39406090 	ldrb	w16, [x4, #24]
        int i,j, line,mask, bytesperline=(font->width+7)/8;
   82738:	aa1300a5 	orr	x5, x5, x19
            for(j=0;j<font->height;j++){
   8273c:	39406489 	ldrb	w9, [x4, #25]
        int i,j, line,mask, bytesperline=(font->width+7)/8;
   82740:	53081eb3 	lsl	w19, w21, #24
   82744:	aa050273 	orr	x19, x19, x5
            for(j=0;j<font->height;j++){
   82748:	39406885 	ldrb	w5, [x4, #26]
   8274c:	92401e10 	and	x16, x16, #0xff
   82750:	39406c95 	ldrb	w21, [x4, #27]
   82754:	d3781d24 	ubfiz	x4, x9, #8, #8
         font->headersize + (*((unsigned char*)s)<font->numglyph?*s:0)*font->bytesperglyph;
   82758:	aa0b00c6 	orr	x6, x6, x11
            for(j=0;j<font->height;j++){
   8275c:	aa100089 	orr	x9, x4, x16
        int i,j, line,mask, bytesperline=(font->width+7)/8;
   82760:	11001e6b 	add	w11, w19, #0x7
                mask=1<<(font->width-1);
   82764:	51000670 	sub	w16, w19, #0x1
            for(j=0;j<font->height;j++){
   82768:	d3701ca4 	ubfiz	x4, x5, #16, #8
         font->headersize + (*((unsigned char*)s)<font->numglyph?*s:0)*font->bytesperglyph;
   8276c:	53081ed6 	lsl	w22, w22, #24
   82770:	aa0703c7 	orr	x7, x30, x7
            for(j=0;j<font->height;j++){
   82774:	aa090084 	orr	x4, x4, x9
         font->headersize + (*((unsigned char*)s)<font->numglyph?*s:0)*font->bytesperglyph;
   82778:	2a0d60fe 	orr	w30, w7, w13, lsl #24
   8277c:	aa0c02cc 	orr	x12, x22, x12
        int i,j, line,mask, bytesperline=(font->width+7)/8;
   82780:	2a1303ed 	mov	w13, w19
         font->headersize + (*((unsigned char*)s)<font->numglyph?*s:0)*font->bytesperglyph;
   82784:	2a1260d2 	orr	w18, w6, w18, lsl #24
   82788:	0b0e0273 	add	w19, w19, w14
   8278c:	53037d6b 	lsr	w11, w11, #3
            for(j=0;j<font->height;j++){
   82790:	2a156089 	orr	w9, w4, w21, lsl #24
                mask=1<<(font->width-1);
   82794:	1ad021ce 	lsl	w14, w14, w16
   82798:	14000009 	b	827bc <fb_print+0x14c>
        if(*s == '\n') {
   8279c:	7100287f 	cmp	w3, #0xa
   827a0:	54000281 	b.ne	827f0 <fb_print+0x180>  // b.any
            *x = 0; *y += font->height;
   827a4:	b900001f 	str	wzr, [x0]
   827a8:	b9400023 	ldr	w3, [x1]
   827ac:	0b090063 	add	w3, w3, w9
   827b0:	b9000023 	str	w3, [x1]
    while(*s) {
   827b4:	38401c43 	ldrb	w3, [x2, #1]!
   827b8:	34000143 	cbz	w3, 827e0 <fb_print+0x170>
        unsigned char *glyph = (unsigned char*)&_binary_font_psf_start +
   827bc:	1b127c66 	mul	w6, w3, w18
   827c0:	6b1e007f 	cmp	w3, w30
   827c4:	8b0c00c6 	add	x6, x6, x12
   827c8:	9a8c30c6 	csel	x6, x6, x12, cc  // cc = lo, ul, last
        if(*s == '\r') {
   827cc:	7100347f 	cmp	w3, #0xd
   827d0:	54fffe61 	b.ne	8279c <fb_print+0x12c>  // b.any
            *x = 0;
   827d4:	b900001f 	str	wzr, [x0]
    while(*s) {
   827d8:	38401c43 	ldrb	w3, [x2, #1]!
   827dc:	35ffff03 	cbnz	w3, 827bc <fb_print+0x14c>
            *x += (font->width+1);
        }
        // next character
        s++;
    }
}
   827e0:	a94153f3 	ldp	x19, x20, [sp, #16]
   827e4:	a9425bf5 	ldp	x21, x22, [sp, #32]
   827e8:	a8c37bfd 	ldp	x29, x30, [sp], #48
   827ec:	d65f03c0 	ret
        int offs = (*y * pitch) + (*x * 4);
   827f0:	b9400003 	ldr	w3, [x0]
            for(j=0;j<font->height;j++){
   827f4:	34000349 	cbz	w9, 8285c <fb_print+0x1ec>
        int offs = (*y * pitch) + (*x * 4);
   827f8:	b9400035 	ldr	w21, [x1]
   827fc:	531e7463 	lsl	w3, w3, #2
        unsigned char *glyph = (unsigned char*)&_binary_font_psf_start +
   82800:	8b1400c6 	add	x6, x6, x20
            for(j=0;j<font->height;j++){
   82804:	52800016 	mov	w22, #0x0                   	// #0
        int offs = (*y * pitch) + (*x * 4);
   82808:	1b150d55 	madd	w21, w10, w21, w3
   8280c:	d503201f 	nop
                for(i=0;i<font->width;i++){
   82810:	340001ad 	cbz	w13, 82844 <fb_print+0x1d4>
   82814:	93407ea3 	sxtw	x3, w21
                mask=1<<(font->width-1);
   82818:	2a0e03e4 	mov	w4, w14
   8281c:	8b304867 	add	x7, x3, w16, uxtw #2
   82820:	8b0301e3 	add	x3, x15, x3
   82824:	8b1100e7 	add	x7, x7, x17
                    *((unsigned int*)(fb + line))=((int)*glyph) & mask?0xFFFFFF:0;
   82828:	394000c5 	ldrb	w5, [x6]
   8282c:	6a0400bf 	tst	w5, w4
                    mask>>=1;
   82830:	13017c84 	asr	w4, w4, #1
                    *((unsigned int*)(fb + line))=((int)*glyph) & mask?0xFFFFFF:0;
   82834:	1a9f1105 	csel	w5, w8, wzr, ne  // ne = any
   82838:	b8004465 	str	w5, [x3], #4
                for(i=0;i<font->width;i++){
   8283c:	eb07007f 	cmp	x3, x7
   82840:	54ffff41 	b.ne	82828 <fb_print+0x1b8>  // b.any
            for(j=0;j<font->height;j++){
   82844:	110006d6 	add	w22, w22, #0x1
                glyph+=bytesperline;
   82848:	8b0b00c6 	add	x6, x6, x11
            for(j=0;j<font->height;j++){
   8284c:	6b0902df 	cmp	w22, w9
   82850:	0b0a02b5 	add	w21, w21, w10
   82854:	54fffde1 	b.ne	82810 <fb_print+0x1a0>  // b.any
   82858:	b9400003 	ldr	w3, [x0]
            *x += (font->width+1);
   8285c:	0b130063 	add	w3, w3, w19
   82860:	b9000003 	str	w3, [x0]
   82864:	17ffffd4 	b	827b4 <fb_print+0x144>
   82868:	d65f03c0 	ret
   8286c:	d503201f 	nop

0000000000082870 <fb_showpicture>:
#define IMG_DATA header_data      
#define IMG_HEIGHT height
#define IMG_WIDTH width

void fb_showpicture()
{
   82870:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
    int x,y;
    unsigned char *ptr=the_fb.fb;
    char *data=IMG_DATA, pixel[4];
    // fill framebuf. crop img data per the framebuf size
    unsigned int img_fb_height = the_fb.vheight < IMG_HEIGHT ? the_fb.vheight : IMG_HEIGHT; 
   82874:	52800ecb 	mov	w11, #0x76                  	// #118
    unsigned int img_fb_width = the_fb.vwidth < IMG_WIDTH ? the_fb.vwidth : IMG_WIDTH; 
   82878:	52800e8a 	mov	w10, #0x74                  	// #116
{
   8287c:	910003fd 	mov	x29, sp
   82880:	a90153f3 	stp	x19, x20, [sp, #16]
    unsigned char *ptr=the_fb.fb;
   82884:	f0000093 	adrp	x19, 95000 <wordsworth.1722+0xee10>
   82888:	91148269 	add	x9, x19, #0x520
   8288c:	f9429265 	ldr	x5, [x19, #1312]
{
   82890:	a9025bf5 	stp	x21, x22, [sp, #32]

    // copy the image pixels to the start (top) of framebuf    
    //ptr += (vheight-img_fb_height)/2*pitch + (vwidth-img_fb_width)*2;  
    ptr += (the_fb.vwidth-img_fb_width)/2*PIXELSIZE;  // top center
    ptr += (the_fb.vheight-img_fb_height)/2*the_fb.pitch; 
   82894:	b9401921 	ldr	w1, [x9, #24]
    unsigned int img_fb_height = the_fb.vheight < IMG_HEIGHT ? the_fb.vheight : IMG_HEIGHT; 
   82898:	2942092c 	ldp	w12, w2, [x9, #16]
    
    for(y=0;y<img_fb_height;y++) {
   8289c:	b9003fff 	str	wzr, [sp, #60]
    unsigned int img_fb_height = the_fb.vheight < IMG_HEIGHT ? the_fb.vheight : IMG_HEIGHT; 
   828a0:	6b0b005f 	cmp	w2, w11
   828a4:	1a8b904b 	csel	w11, w2, w11, ls  // ls = plast
    unsigned int img_fb_width = the_fb.vwidth < IMG_WIDTH ? the_fb.vwidth : IMG_WIDTH; 
   828a8:	6b0a019f 	cmp	w12, w10
    ptr += (the_fb.vheight-img_fb_height)/2*the_fb.pitch; 
   828ac:	4b0b0040 	sub	w0, w2, w11
    unsigned int img_fb_width = the_fb.vwidth < IMG_WIDTH ? the_fb.vwidth : IMG_WIDTH; 
   828b0:	1a8a918a 	csel	w10, w12, w10, ls  // ls = plast
    ptr += (the_fb.vwidth-img_fb_width)/2*PIXELSIZE;  // top center
   828b4:	4b0a0183 	sub	w3, w12, w10
    ptr += (the_fb.vheight-img_fb_height)/2*the_fb.pitch; 
   828b8:	53017c00 	lsr	w0, w0, #1
    ptr += (the_fb.vwidth-img_fb_width)/2*PIXELSIZE;  // top center
   828bc:	53017c63 	lsr	w3, w3, #1
    ptr += (the_fb.vheight-img_fb_height)/2*the_fb.pitch; 
   828c0:	1b017c00 	mul	w0, w0, w1
    ptr += (the_fb.vwidth-img_fb_width)/2*PIXELSIZE;  // top center
   828c4:	531e7461 	lsl	w1, w3, #2
    ptr += (the_fb.vheight-img_fb_height)/2*the_fb.pitch; 
   828c8:	8b010000 	add	x0, x0, x1
   828cc:	8b0000a5 	add	x5, x5, x0
    for(y=0;y<img_fb_height;y++) {
   828d0:	34000622 	cbz	w2, 82994 <fb_showpicture+0x124>
    char *data=IMG_DATA, pixel[4];
   828d4:	90000023 	adrp	x3, 86000 <__asm_dcache_level+0xc>
            *((unsigned int*)ptr)=the_fb.isrgb ? *((unsigned int *)&pixel) 
                : (unsigned int)(pixel[0]<<16 | pixel[1]<<8 | pixel[2]);
            // *((unsigned int*)ptr)=(!the_fb.isrgb) ? *((unsigned int *)&pixel) : (unsigned int)(pixel[0]<<16 | pixel[1]<<8 | pixel[2]);
            ptr+=4;
        }
        ptr+=the_fb.pitch-img_fb_width*4;
   828d8:	531e754d 	lsl	w13, w10, #2
    char *data=IMG_DATA, pixel[4];
   828dc:	912a0063 	add	x3, x3, #0xa80
        for(x=0;x<img_fb_width;x++) {
   828e0:	b9003bff 	str	wzr, [sp, #56]
   828e4:	3400042c 	cbz	w12, 82968 <fb_showpicture+0xf8>
            HEADER_PIXEL(data, pixel);
   828e8:	39400861 	ldrb	w1, [x3, #2]
   828ec:	91001063 	add	x3, x3, #0x4
   828f0:	385fd062 	ldurb	w2, [x3, #-3]
   828f4:	51008421 	sub	w1, w1, #0x21
   828f8:	385fc060 	ldurb	w0, [x3, #-4]
   828fc:	51008442 	sub	w2, w2, #0x21
   82900:	385ff064 	ldurb	w4, [x3, #-1]
   82904:	13027c27 	asr	w7, w1, #2
   82908:	51008400 	sub	w0, w0, #0x21
   8290c:	13047c48 	asr	w8, w2, #4
   82910:	2a0210e2 	orr	w2, w7, w2, lsl #4
   82914:	51008484 	sub	w4, w4, #0x21
   82918:	12001c42 	and	w2, w2, #0xff
   8291c:	2a000900 	orr	w0, w8, w0, lsl #2
                : (unsigned int)(pixel[0]<<16 | pixel[1]<<8 | pixel[2]);
   82920:	b9402926 	ldr	w6, [x9, #40]
            HEADER_PIXEL(data, pixel);
   82924:	2a011881 	orr	w1, w4, w1, lsl #6
   82928:	12001c00 	and	w0, w0, #0xff
   8292c:	12001c21 	and	w1, w1, #0xff
                : (unsigned int)(pixel[0]<<16 | pixel[1]<<8 | pixel[2]);
   82930:	53185c44 	lsl	w4, w2, #8
            HEADER_PIXEL(data, pixel);
   82934:	3900c3e0 	strb	w0, [sp, #48]
                : (unsigned int)(pixel[0]<<16 | pixel[1]<<8 | pixel[2]);
   82938:	2a004080 	orr	w0, w4, w0, lsl #16
            HEADER_PIXEL(data, pixel);
   8293c:	3900c7e2 	strb	w2, [sp, #49]
                : (unsigned int)(pixel[0]<<16 | pixel[1]<<8 | pixel[2]);
   82940:	2a010000 	orr	w0, w0, w1
            HEADER_PIXEL(data, pixel);
   82944:	3900cbe1 	strb	w1, [sp, #50]
                : (unsigned int)(pixel[0]<<16 | pixel[1]<<8 | pixel[2]);
   82948:	34000046 	cbz	w6, 82950 <fb_showpicture+0xe0>
   8294c:	b94033e0 	ldr	w0, [sp, #48]
            *((unsigned int*)ptr)=the_fb.isrgb ? *((unsigned int *)&pixel) 
   82950:	b80044a0 	str	w0, [x5], #4
        for(x=0;x<img_fb_width;x++) {
   82954:	b9403be0 	ldr	w0, [sp, #56]
   82958:	11000400 	add	w0, w0, #0x1
   8295c:	b9003be0 	str	w0, [sp, #56]
   82960:	6b0a001f 	cmp	w0, w10
   82964:	54fffc23 	b.cc	828e8 <fb_showpicture+0x78>  // b.lo, b.ul, b.last
    for(y=0;y<img_fb_height;y++) {
   82968:	b9403fe0 	ldr	w0, [sp, #60]
        ptr+=the_fb.pitch-img_fb_width*4;
   8296c:	b9401921 	ldr	w1, [x9, #24]
    for(y=0;y<img_fb_height;y++) {
   82970:	11000400 	add	w0, w0, #0x1
   82974:	b9003fe0 	str	w0, [sp, #60]
        ptr+=the_fb.pitch-img_fb_width*4;
   82978:	4b0d0021 	sub	w1, w1, w13
    for(y=0;y<img_fb_height;y++) {
   8297c:	6b0b001f 	cmp	w0, w11
        ptr+=the_fb.pitch-img_fb_width*4;
   82980:	8b0100a5 	add	x5, x5, x1
    for(y=0;y<img_fb_height;y++) {
   82984:	54fffae3 	b.cc	828e0 <fb_showpicture+0x70>  // b.lo, b.ul, b.last
   82988:	29420923 	ldp	w3, w2, [x9, #16]
   8298c:	4b0a0063 	sub	w3, w3, w10
   82990:	53017c63 	lsr	w3, w3, #1
    }

    // show text strings
    x = (the_fb.vwidth-img_fb_width)/2;
    y = the_fb.vheight/2 + img_fb_height/2;
   82994:	53017d6b 	lsr	w11, w11, #1
    fb_print(&x, &y, "UVA OS");
    char res[16]; 
    sprintf(res, " %dx%d", the_fb.width, the_fb.height); // debug info 
   82998:	91148273 	add	x19, x19, #0x520
    y = the_fb.vheight/2 + img_fb_height/2;
   8299c:	0b42056b 	add	w11, w11, w2, lsr #1
    fb_print(&x, &y, "UVA OS");
   829a0:	9100f3f5 	add	x21, sp, #0x3c
   829a4:	9100e3f4 	add	x20, sp, #0x38
   829a8:	aa1503e1 	mov	x1, x21
   829ac:	aa1403e0 	mov	x0, x20
   829b0:	d0000082 	adrp	x2, 94000 <wordsworth.1722+0xde10>
   829b4:	9101a042 	add	x2, x2, #0x68
    y = the_fb.vheight/2 + img_fb_height/2;
   829b8:	29072fe3 	stp	w3, w11, [sp, #56]
    fb_print(&x, &y, "UVA OS");
   829bc:	97ffff2d 	bl	82670 <fb_print>
    sprintf(res, " %dx%d", the_fb.width, the_fb.height); // debug info 
   829c0:	910103f6 	add	x22, sp, #0x40
   829c4:	29410e62 	ldp	w2, w3, [x19, #8]
   829c8:	aa1603e0 	mov	x0, x22
   829cc:	d0000081 	adrp	x1, 94000 <wordsworth.1722+0xde10>
   829d0:	9101c021 	add	x1, x1, #0x70
   829d4:	97fffb77 	bl	817b0 <tfp_sprintf>
    fb_print(&x, &y, res);
   829d8:	aa1603e2 	mov	x2, x22
   829dc:	aa1503e1 	mov	x1, x21
   829e0:	aa1403e0 	mov	x0, x20
   829e4:	97ffff23 	bl	82670 <fb_print>
    // __asm_flush_dcache_range(the_fb.fb, the_fb.fb + the_fb.size); 
}
   829e8:	a94153f3 	ldp	x19, x20, [sp, #16]
   829ec:	a9425bf5 	ldp	x21, x22, [sp, #32]
   829f0:	a8c57bfd 	ldp	x29, x30, [sp], #80
   829f4:	d65f03c0 	ret

00000000000829f8 <fb_init>:
int fb_init(void) {
   829f8:	d10143ff 	sub	sp, sp, #0x50
   829fc:	a9017bfd 	stp	x29, x30, [sp, #16]
   82a00:	910043fd 	add	x29, sp, #0x10
   82a04:	a9035bf5 	stp	x21, x22, [sp, #48]
    mbox[0] = 35*4;     // size of the whole buf that follows
   82a08:	f0000095 	adrp	x21, 95000 <wordsworth.1722+0xee10>
    acquire(&mboxlock); 
   82a0c:	f0000096 	adrp	x22, 95000 <wordsworth.1722+0xee10>
   82a10:	913802c0 	add	x0, x22, #0xe00
int fb_init(void) {
   82a14:	a90253f3 	stp	x19, x20, [sp, #32]
   82a18:	a90463f7 	stp	x23, x24, [sp, #64]
    acquire(&mboxlock); 
   82a1c:	97fffc8f 	bl	81c58 <acquire>
    mbox[0] = 35*4;     // size of the whole buf that follows
   82a20:	52801182 	mov	w2, #0x8c                  	// #140
   82a24:	f9473eb3 	ldr	x19, [x21, #3704]
    mbox[5] = fbs->width;           //(val) FrameBufferInfo.width
   82a28:	f0000098 	adrp	x24, 95000 <wordsworth.1722+0xee10>
    mbox[2] = 0x48003;  //set phy width & height
   82a2c:	52900060 	mov	w0, #0x8003                	// #32771
    mbox[5] = fbs->width;           //(val) FrameBufferInfo.width
   82a30:	91148314 	add	x20, x24, #0x520
    mbox[2] = 0x48003;  //set phy width & height
   82a34:	72a00080 	movk	w0, #0x4, lsl #16
    mbox[3] = 8;        // total buf size of this tag
   82a38:	52800101 	mov	w1, #0x8                   	// #8
    mbox[0] = 35*4;     // size of the whole buf that follows
   82a3c:	b9000262 	str	w2, [x19]
    mbox[7] = 0x48004;  //set virt width & height
   82a40:	52900089 	mov	w9, #0x8004                	// #32772
    mbox[1] = MBOX_REQUEST; // cpu->gpu request
   82a44:	b900067f 	str	wzr, [x19, #4]
    mbox[7] = 0x48004;  //set virt width & height
   82a48:	72a00089 	movk	w9, #0x4, lsl #16
    mbox[2] = 0x48003;  //set phy width & height
   82a4c:	b9000a60 	str	w0, [x19, #8]
    mbox[12] = 0x48009; //set virt offset
   82a50:	52900128 	mov	w8, #0x8009                	// #32777
    mbox[3] = 8;        // total buf size of this tag
   82a54:	b9000e61 	str	w1, [x19, #12]
    mbox[12] = 0x48009; //set virt offset
   82a58:	72a00088 	movk	w8, #0x4, lsl #16
    mbox[5] = fbs->width;           //(val) FrameBufferInfo.width
   82a5c:	b9400a80 	ldr	w0, [x20, #8]
    mbox[17] = 0x48005; //set depth
   82a60:	529000a7 	mov	w7, #0x8005                	// #32773
    mbox[4] = 8;        // req val size (needed?), to be overwritten as resp val size
   82a64:	b9001261 	str	w1, [x19, #16]
    mbox[17] = 0x48005; //set depth
   82a68:	72a00087 	movk	w7, #0x4, lsl #16
    mbox[5] = fbs->width;           //(val) FrameBufferInfo.width
   82a6c:	b9001660 	str	w0, [x19, #20]
    mbox[18] = 4;
   82a70:	52800082 	mov	w2, #0x4                   	// #4
    mbox[6] = fbs->height;          //(val) FrameBufferInfo.height
   82a74:	b9400e80 	ldr	w0, [x20, #12]
    mbox[21] = 0x48006;     //set pixel order
   82a78:	529000c6 	mov	w6, #0x8006                	// #32774
    mbox[6] = fbs->height;          //(val) FrameBufferInfo.height
   82a7c:	b9001a60 	str	w0, [x19, #24]
    mbox[21] = 0x48006;     //set pixel order
   82a80:	72a00086 	movk	w6, #0x4, lsl #16
    mbox[7] = 0x48004;  //set virt width & height
   82a84:	b9001e69 	str	w9, [x19, #28]
    mbox[25] = 0x40001;     //get framebuffer, gets alignment on request
   82a88:	52800025 	mov	w5, #0x1                   	// #1
    mbox[8] = 8;
   82a8c:	b9002261 	str	w1, [x19, #32]
    mbox[25] = 0x40001;     //get framebuffer, gets alignment on request
   82a90:	72a00085 	movk	w5, #0x4, lsl #16
    mbox[10] = fbs->vwidth;        //FrameBufferInfo.virtual_width
   82a94:	b9401289 	ldr	w9, [x20, #16]
    mbox[28] = 4096;        //req: alignment; resp: FrameBufferInfo.pointer
   82a98:	52820004 	mov	w4, #0x1000                	// #4096
    mbox[9] = 8;
   82a9c:	b9002661 	str	w1, [x19, #36]
    mbox[30] = 0x40008;     //get pitch
   82aa0:	52800103 	mov	w3, #0x8                   	// #8
    mbox[10] = fbs->vwidth;        //FrameBufferInfo.virtual_width
   82aa4:	b9002a69 	str	w9, [x19, #40]
    mbox[30] = 0x40008;     //get pitch
   82aa8:	72a00083 	movk	w3, #0x4, lsl #16
    mbox[11] = fbs->vheight;         //FrameBufferInfo.virtual_height
   82aac:	b9401689 	ldr	w9, [x20, #20]
    if(mbox_call(MBOX_CH_PROP) 
   82ab0:	2a0103e0 	mov	w0, w1
    mbox[11] = fbs->vheight;         //FrameBufferInfo.virtual_height
   82ab4:	b9002e69 	str	w9, [x19, #44]
    mbox[12] = 0x48009; //set virt offset
   82ab8:	b9003268 	str	w8, [x19, #48]
    mbox[13] = 8;
   82abc:	b9003661 	str	w1, [x19, #52]
    mbox[15] = fbs->offsetx;           
   82ac0:	b9402e88 	ldr	w8, [x20, #44]
    mbox[14] = 8;
   82ac4:	b9003a61 	str	w1, [x19, #56]
    mbox[15] = fbs->offsetx;           
   82ac8:	b9003e68 	str	w8, [x19, #60]
    mbox[16] = fbs->offsety;           
   82acc:	b9403288 	ldr	w8, [x20, #48]
   82ad0:	b9004268 	str	w8, [x19, #64]
    mbox[17] = 0x48005; //set depth
   82ad4:	b9004667 	str	w7, [x19, #68]
    mbox[18] = 4;
   82ad8:	b9004a62 	str	w2, [x19, #72]
    mbox[20] = fbs->depth;       
   82adc:	b9402687 	ldr	w7, [x20, #36]
    mbox[19] = 4;
   82ae0:	b9004e62 	str	w2, [x19, #76]
    mbox[20] = fbs->depth;       
   82ae4:	b9005267 	str	w7, [x19, #80]
    mbox[21] = 0x48006;     //set pixel order
   82ae8:	b9005666 	str	w6, [x19, #84]
    mbox[22] = 4;
   82aec:	b9005a62 	str	w2, [x19, #88]
    mbox[23] = 4;
   82af0:	b9005e62 	str	w2, [x19, #92]
    mbox[24] = fbs->isrgb;           //RGB, not BGR preferably
   82af4:	b9402a86 	ldr	w6, [x20, #40]
   82af8:	b9006266 	str	w6, [x19, #96]
    mbox[25] = 0x40001;     //get framebuffer, gets alignment on request
   82afc:	b9006665 	str	w5, [x19, #100]
    mbox[26] = 8;
   82b00:	b9006a61 	str	w1, [x19, #104]
    mbox[27] = 8;           // fxl: should be 4?? (req para size)
   82b04:	b9006e61 	str	w1, [x19, #108]
    mbox[28] = 4096;        //req: alignment; resp: FrameBufferInfo.pointer
   82b08:	b9007264 	str	w4, [x19, #112]
    mbox[29] = 0;           //resp: FrameBufferInfo.size
   82b0c:	b900767f 	str	wzr, [x19, #116]
    mbox[30] = 0x40008;     //get pitch
   82b10:	b9007a63 	str	w3, [x19, #120]
    mbox[31] = 4;
   82b14:	b9007e62 	str	w2, [x19, #124]
    mbox[32] = 4;
   82b18:	b9008262 	str	w2, [x19, #128]
    mbox[33] = 0;           //FrameBufferInfo.pitch
   82b1c:	b900867f 	str	wzr, [x19, #132]
    mbox[34] = MBOX_TAG_LAST;   // the end of tag seq
   82b20:	b9008a7f 	str	wzr, [x19, #136]
    if(mbox_call(MBOX_CH_PROP) 
   82b24:	97fffdd7 	bl	82280 <mbox_call>
   82b28:	34000ae0 	cbz	w0, 82c84 <fb_init+0x28c>
        && mbox[20]==fbs->depth /*depth*/ 
   82b2c:	b9405261 	ldr	w1, [x19, #80]
   82b30:	b9402680 	ldr	w0, [x20, #36]
   82b34:	6b00003f 	cmp	w1, w0
   82b38:	54000a61 	b.ne	82c84 <fb_init+0x28c>  // b.any
        && mbox[28]!=0 /*framebuf*/) {
   82b3c:	b9407260 	ldr	w0, [x19, #112]
   82b40:	34000a20 	cbz	w0, 82c84 <fb_init+0x28c>
        mbox[28]&=0x3FFFFFFF;  
   82b44:	b9407260 	ldr	w0, [x19, #112]
   82b48:	90000037 	adrp	x23, 86000 <__asm_dcache_level+0xc>
   82b4c:	12007400 	and	w0, w0, #0x3fffffff
   82b50:	b9007260 	str	w0, [x19, #112]
        fbs->fb = (unsigned char *)((unsigned long)mbox[28]);   // save framebuf ptr
   82b54:	b9407260 	ldr	w0, [x19, #112]
        fbs->width=mbox[5];
   82b58:	b9401664 	ldr	w4, [x19, #20]
        fbs->height=mbox[6];
   82b5c:	b9401a65 	ldr	w5, [x19, #24]
        fbs->fb = (unsigned char *)((unsigned long)mbox[28]);   // save framebuf ptr
   82b60:	2a0003e0 	mov	w0, w0
        fbs->vwidth=mbox[10];
   82b64:	b9402a66 	ldr	w6, [x19, #40]
        fbs->vheight=mbox[11];        
   82b68:	b9402e67 	ldr	w7, [x19, #44]
        fbs->depth=mbox[20]; 
   82b6c:	b9405261 	ldr	w1, [x19, #80]
        fbs->isrgb=mbox[24];         // channel order        
   82b70:	b9406268 	ldr	w8, [x19, #96]
        fbs->pitch=mbox[33];
   82b74:	b9408662 	ldr	w2, [x19, #132]
        if(fbs->pitch * fbs->vheight > mbox[29])  // possible that pitch*vheight < actual allocation
   82b78:	b9407663 	ldr	w3, [x19, #116]
        fbs->fb = (unsigned char *)((unsigned long)mbox[28]);   // save framebuf ptr
   82b7c:	f9029300 	str	x0, [x24, #1312]
        fbs->height=mbox[6];
   82b80:	29011684 	stp	w4, w5, [x20, #8]
        if(fbs->pitch * fbs->vheight > mbox[29])  // possible that pitch*vheight < actual allocation
   82b84:	1b027ce0 	mul	w0, w7, w2
        fbs->vheight=mbox[11];        
   82b88:	29021e86 	stp	w6, w7, [x20, #16]
        fbs->pitch=mbox[33];
   82b8c:	b9001a82 	str	w2, [x20, #24]
        fbs->isrgb=mbox[24];         // channel order        
   82b90:	2904a281 	stp	w1, w8, [x20, #36]
        if(fbs->pitch * fbs->vheight > mbox[29])  // possible that pitch*vheight < actual allocation
   82b94:	6b03001f 	cmp	w0, w3
   82b98:	540003c8 	b.hi	82c10 <fb_init+0x218>  // b.pmore
        I("From GPU: fb pa: 0x%08x w %u h %u vw %u vh %u pitch %u isrgb %u", 
   82b9c:	f9473eb5 	ldr	x21, [x21, #3704]
        fbs->size = PGROUNDUP(fbs->pitch * fbs->vheight);  // roundup b/c we'll reserve pages for it
   82ba0:	113ffc00 	add	w0, w0, #0xfff
   82ba4:	91148318 	add	x24, x24, #0x520
        I("From GPU: fb pa: 0x%08x w %u h %u vw %u vh %u pitch %u isrgb %u", 
   82ba8:	912162f7 	add	x23, x23, #0x858
   82bac:	aa1703e1 	mov	x1, x23
   82bb0:	b94072a3 	ldr	w3, [x21, #112]
   82bb4:	b9000be8 	str	w8, [sp, #8]
        fbs->size = PGROUNDUP(fbs->pitch * fbs->vheight);  // roundup b/c we'll reserve pages for it
   82bb8:	12144c08 	and	w8, w0, #0xfffff000
        I("From GPU: fb pa: 0x%08x w %u h %u vw %u vh %u pitch %u isrgb %u", 
   82bbc:	b90003e2 	str	w2, [sp]
   82bc0:	52802922 	mov	w2, #0x149                 	// #329
   82bc4:	d0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   82bc8:	9102c000 	add	x0, x0, #0xb0
        fbs->size = PGROUNDUP(fbs->pitch * fbs->vheight);  // roundup b/c we'll reserve pages for it
   82bcc:	b9003708 	str	w8, [x24, #52]
        I("From GPU: fb pa: 0x%08x w %u h %u vw %u vh %u pitch %u isrgb %u", 
   82bd0:	97fffa92 	bl	81618 <tfp_printf>
    release(&mboxlock); 
   82bd4:	913802c0 	add	x0, x22, #0xe00
   82bd8:	97fffc62 	bl	81d60 <release>
    if (reserve_phys_region(mbox[28], fbs->size)) {
   82bdc:	b9403701 	ldr	w1, [x24, #52]
   82be0:	b94072a0 	ldr	w0, [x21, #112]
   82be4:	2a0003e0 	mov	w0, w0
   82be8:	94000262 	bl	83570 <reserve_phys_region>
   82bec:	35000600 	cbnz	w0, 82cac <fb_init+0x2b4>
    if (ret==0 && once)
   82bf0:	b9403b00 	ldr	w0, [x24, #56]
   82bf4:	35000360 	cbnz	w0, 82c60 <fb_init+0x268>
}
   82bf8:	a9417bfd 	ldp	x29, x30, [sp, #16]
   82bfc:	a94253f3 	ldp	x19, x20, [sp, #32]
   82c00:	a9435bf5 	ldp	x21, x22, [sp, #48]
   82c04:	a94463f7 	ldp	x23, x24, [sp, #64]
   82c08:	910143ff 	add	sp, sp, #0x50
   82c0c:	d65f03c0 	ret
            {W("pitch %d x vheight %d!= mbox[29] %u", fbs->pitch, fbs->vheight, mbox[29]);BUG();}
   82c10:	b9407665 	ldr	w5, [x19, #116]
   82c14:	2a0703e4 	mov	w4, w7
   82c18:	2a0203e3 	mov	w3, w2
   82c1c:	912162f3 	add	x19, x23, #0x858
   82c20:	aa1303e1 	mov	x1, x19
   82c24:	528028e2 	mov	w2, #0x147                 	// #327
   82c28:	d0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   82c2c:	9101e000 	add	x0, x0, #0x78
   82c30:	97fffa7a 	bl	81618 <tfp_printf>
   82c34:	528028e2 	mov	w2, #0x147                 	// #327
   82c38:	aa1303e1 	mov	x1, x19
   82c3c:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   82c40:	910d8000 	add	x0, x0, #0x360
   82c44:	97fffb45 	bl	81958 <assertion_failed>
   82c48:	29421e86 	ldp	w6, w7, [x20, #16]
   82c4c:	b9401a82 	ldr	w2, [x20, #24]
   82c50:	29411684 	ldp	w4, w5, [x20, #8]
   82c54:	b9402a88 	ldr	w8, [x20, #40]
   82c58:	1b077c40 	mul	w0, w2, w7
   82c5c:	17ffffd0 	b	82b9c <fb_init+0x1a4>
        {fb_showpicture(); once=0;}
   82c60:	97ffff04 	bl	82870 <fb_showpicture>
   82c64:	b9003b1f 	str	wzr, [x24, #56]
        return 0; 
   82c68:	52800000 	mov	w0, #0x0                   	// #0
}
   82c6c:	a9417bfd 	ldp	x29, x30, [sp, #16]
   82c70:	a94253f3 	ldp	x19, x20, [sp, #32]
   82c74:	a9435bf5 	ldp	x21, x22, [sp, #48]
   82c78:	a94463f7 	ldp	x23, x24, [sp, #64]
   82c7c:	910143ff 	add	sp, sp, #0x50
   82c80:	d65f03c0 	ret
        E("Unable to set scr res to %d x %d\n", fbs->width, fbs->height);
   82c84:	91148313 	add	x19, x24, #0x520
   82c88:	90000021 	adrp	x1, 86000 <__asm_dcache_level+0xc>
   82c8c:	d0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   82c90:	91216021 	add	x1, x1, #0x858
   82c94:	91042000 	add	x0, x0, #0x108
   82c98:	528029a2 	mov	w2, #0x14d                 	// #333
   82c9c:	29411263 	ldp	w3, w4, [x19, #8]
   82ca0:	97fffa5e 	bl	81618 <tfp_printf>
        return -2; 
   82ca4:	12800020 	mov	w0, #0xfffffffe            	// #-2
   82ca8:	17ffffd4 	b	82bf8 <fb_init+0x200>
        E("failed to reserve fb mem. pa 0x%x size 0x%x already in use.",
   82cac:	b94072a3 	ldr	w3, [x21, #112]
   82cb0:	aa1703e1 	mov	x1, x23
   82cb4:	b9403704 	ldr	w4, [x24, #52]
   82cb8:	52802a62 	mov	w2, #0x153                 	// #339
   82cbc:	d0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   82cc0:	91050000 	add	x0, x0, #0x140
   82cc4:	97fffa55 	bl	81618 <tfp_printf>
            mbox[28], fbs->size); BUG(); 
   82cc8:	aa1703e1 	mov	x1, x23
   82ccc:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   82cd0:	52802a82 	mov	w2, #0x154                 	// #340
   82cd4:	910d8000 	add	x0, x0, #0x360
   82cd8:	97fffb20 	bl	81958 <assertion_failed>
        return -1; 
   82cdc:	12800000 	mov	w0, #0xffffffff            	// #-1
   82ce0:	17ffffc6 	b	82bf8 <fb_init+0x200>
   82ce4:	00000000 	udf	#0

0000000000082ce8 <donut_canvas_init>:
_Static_assert(22*K*2  <= NN/2); // rows

static char b[N_DONUTS][1760];        // text buffer (W 80 H 22?
static signed char z[N_DONUTS][1760]; // z buffer

void donut_canvas_init(void) {
   82ce8:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   82cec:	910003fd 	mov	x29, sp
    fb_fini();
   82cf0:	97fffe24 	bl	82580 <fb_fini>
    // acquire(&mboxlock);      //it's a test. so no lock

    the_fb.width = NN;
   82cf4:	f0000080 	adrp	x0, 95000 <wordsworth.1722+0xee10>
   82cf8:	d2805001 	mov	x1, #0x280                 	// #640
   82cfc:	f2c05001 	movk	x1, #0x280, lsl #32
   82d00:	f9476000 	ldr	x0, [x0, #3776]
    the_fb.height = NN;

    the_fb.vwidth = NN;
   82d04:	a9008401 	stp	x1, x1, [x0, #8]
    the_fb.vheight = NN;

    if (fb_init() != 0)
   82d08:	97ffff3c 	bl	829f8 <fb_init>
   82d0c:	35000060 	cbnz	w0, 82d18 <donut_canvas_init+0x30>
        BUG();
}
   82d10:	a8c17bfd 	ldp	x29, x30, [sp], #16
   82d14:	d65f03c0 	ret
   82d18:	a8c17bfd 	ldp	x29, x30, [sp], #16
        BUG();
   82d1c:	d0000081 	adrp	x1, 94000 <wordsworth.1722+0xde10>
   82d20:	90000020 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   82d24:	91068021 	add	x1, x1, #0x1a0
   82d28:	910d8000 	add	x0, x0, #0x360
   82d2c:	528007e2 	mov	w2, #0x3f                  	// #63
   82d30:	17fffb0a 	b	81958 <assertion_failed>
   82d34:	d503201f 	nop

0000000000082d38 <donut_pixel>:
// draw dots on canvas, closer to the original js version (see comment at the end)
// Q4: quest: "two donuts". understand code below
// Q7: quest: "donuts in sync"
static int frame_count[N_DONUTS] = {0};
void donut_pixel(int idx) {
    int sA = 1024, cA = 0, sB = 1024, cB = 0, _;
   82d38:	93407c05 	sxtw	x5, w0
                    lumince = lumince<0? 0 : lumince/5; 
                    lumince = lumince<255? lumince : 255; 

                int o = x + 80 * y; // fxl: 80 chars per row
                signed char zz = (x6 - K2) >> 15;
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82d3c:	937d7c01 	sbfiz	x1, x0, #3, #32
   82d40:	cb050021 	sub	x1, x1, x5
            R(9, 7, cj, sj) // rotate j
        }
        //R(5, 7, cA, sA);
        //R(5, 8, cB, sB);

        for (int t = 0; t <=idx%4; t++) {
   82d44:	6b0003e3 	negs	w3, w0
   82d48:	5280dc02 	mov	w2, #0x6e0                 	// #1760
void donut_pixel(int idx) {
   82d4c:	a9b27bfd 	stp	x29, x30, [sp, #-224]!
        for (int t = 0; t <=idx%4; t++) {
   82d50:	12000404 	and	w4, w0, #0x3
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82d54:	d37df021 	lsl	x1, x1, #3
        for (int t = 0; t <=idx%4; t++) {
   82d58:	12000463 	and	w3, w3, #0x3
   82d5c:	5a834483 	csneg	w3, w4, w3, mi  // mi = first
   82d60:	9b227c02 	smull	x2, w0, w2
   82d64:	7100081f 	cmp	w0, #0x2
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82d68:	cb050020 	sub	x0, x1, x5
void donut_pixel(int idx) {
   82d6c:	910003fd 	mov	x29, sp
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82d70:	d37be800 	lsl	x0, x0, #5
        memset(b[idx], 0, 1760);  // text buffer 0: black bkgnd
   82d74:	d00000e1 	adrp	x1, a0000 <z+0x9d08>
        for (int t = 0; t <=idx%4; t++) {
   82d78:	b9007fe3 	str	w3, [sp, #124]
        memset(b[idx], 0, 1760);  // text buffer 0: black bkgnd
   82d7c:	913b6023 	add	x3, x1, #0xed8
        memset(z[idx], 127, 1760); // z buffer
   82d80:	900000a1 	adrp	x1, 96000 <stdout_putf>
   82d84:	910be021 	add	x1, x1, #0x2f8
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82d88:	f90067e0 	str	x0, [sp, #200]
        memset(b[idx], 0, 1760);  // text buffer 0: black bkgnd
   82d8c:	8b030040 	add	x0, x2, x3
void donut_pixel(int idx) {
   82d90:	a90573fb 	stp	x27, x28, [sp, #80]
                    lumince = lumince<0? 0 : lumince/5; 
   82d94:	528cccfc 	mov	w28, #0x6667                	// #26215
    int sA = 1024, cA = 0, sB = 1024, cB = 0, _;
   82d98:	52808003 	mov	w3, #0x400                 	// #1024
        memset(b[idx], 0, 1760);  // text buffer 0: black bkgnd
   82d9c:	f9003be0 	str	x0, [sp, #112]
        memset(z[idx], 127, 1760); // z buffer
   82da0:	8b010040 	add	x0, x2, x1
    int sA = 1024, cA = 0, sB = 1024, cB = 0, _;
   82da4:	52800004 	mov	w4, #0x0                   	// #0
   82da8:	52800007 	mov	w7, #0x0                   	// #0
   82dac:	12807fe6 	mov	w6, #0xfffffc00            	// #-1024
                    lumince = lumince<0? 0 : lumince/5; 
   82db0:	72acccdc 	movk	w28, #0x6666, lsl #16
void donut_pixel(int idx) {
   82db4:	a90153f3 	stp	x19, x20, [sp, #16]
    int sA = 1024, cA = 0, sB = 1024, cB = 0, _;
   82db8:	52800013 	mov	w19, #0x0                   	// #0
void donut_pixel(int idx) {
   82dbc:	a9025bf5 	stp	x21, x22, [sp, #32]
   82dc0:	a90363f7 	stp	x23, x24, [sp, #48]
   82dc4:	a9046bf9 	stp	x25, x26, [sp, #64]
                    lumince = lumince<0? 0 : lumince/5; 
   82dc8:	b9006be4 	str	w4, [sp, #104]
   82dcc:	b9006fe3 	str	w3, [sp, #108]
   82dd0:	b9007be3 	str	w3, [sp, #120]
   82dd4:	f90043e5 	str	x5, [sp, #128]
   82dd8:	29141be7 	stp	w7, w6, [sp, #160]
        memset(z[idx], 127, 1760); // z buffer
   82ddc:	f90057e0 	str	x0, [sp, #168]
   82de0:	1a9f17e0 	cset	w0, eq  // eq = none
   82de4:	b900c7e0 	str	w0, [sp, #196]
        memset(b[idx], 0, 1760);  // text buffer 0: black bkgnd
   82de8:	f9403be0 	ldr	x0, [sp, #112]
   82dec:	5280dc02 	mov	w2, #0x6e0                 	// #1760
   82df0:	52800001 	mov	w1, #0x0                   	// #0
        int sj = 0, cj = 1024;
   82df4:	5280801a 	mov	w26, #0x400                 	// #1024
   82df8:	52800019 	mov	w25, #0x0                   	// #0
   82dfc:	52801ff7 	mov	w23, #0xff                  	// #255
        memset(b[idx], 0, 1760);  // text buffer 0: black bkgnd
   82e00:	97fffae2 	bl	81988 <memset>
                R(5, 8, ci, si) // rotate i
   82e04:	52a00616 	mov	w22, #0x300000              	// #3145728
        memset(z[idx], 127, 1760); // z buffer
   82e08:	f94057e0 	ldr	x0, [sp, #168]
   82e0c:	5280dc02 	mov	w2, #0x6e0                 	// #1760
   82e10:	52800fe1 	mov	w1, #0x7f                  	// #127
   82e14:	97fffadd 	bl	81988 <memset>
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82e18:	900000a0 	adrp	x0, 96000 <stdout_putf>
   82e1c:	910be018 	add	x24, x0, #0x2f8
                    b[idx][o] = lumince;
   82e20:	d00000e0 	adrp	x0, a0000 <z+0x9d08>
   82e24:	913b601b 	add	x27, x0, #0xed8
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82e28:	f94067e0 	ldr	x0, [sp, #200]
        memset(z[idx], 127, 1760); // z buffer
   82e2c:	52800b5e 	mov	w30, #0x5a                  	// #90
   82e30:	294d17e4 	ldp	w4, w5, [sp, #104]
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82e34:	8b000318 	add	x24, x24, x0
   82e38:	b9407be3 	ldr	w3, [sp, #120]
                    b[idx][o] = lumince;
   82e3c:	8b00037b 	add	x27, x27, x0
   82e40:	29541be7 	ldp	w7, w6, [sp, #160]
                    x5 = sA * sj >> 10,
   82e44:	1b197cac 	mul	w12, w5, w25
                    x2 = cA * sj >> 10,
   82e48:	1b197c8d 	mul	w13, w4, w25
            int si = 0, ci = 1024; // sine and cosine of angle i
   82e4c:	52808000 	mov	w0, #0x400                 	// #1024
                    lumince = (((-cA * x7 - cB * ((-sA * x7 >> 10) + x2) - ci * (cj * sB >> 10)) >> 10) - x5); 
   82e50:	1b1a7c6f 	mul	w15, w3, w26
                    x6 = K2 + R1 * 1024 * x5 + cA * x3,
   82e54:	12165590 	and	w16, w12, #0xfffffc00
   82e58:	1120034e 	add	w14, w26, #0x800
   82e5c:	11540210 	add	w16, w16, #0x500, lsl #12
                    x5 = sA * sj >> 10,
   82e60:	130a7d8c 	asr	w12, w12, #10
                    x2 = cA * sj >> 10,
   82e64:	130a7dad 	asr	w13, w13, #10
                    lumince = (((-cA * x7 - cB * ((-sA * x7 >> 10) + x2) - ci * (cj * sB >> 10)) >> 10) - x5); 
   82e68:	130a7def 	asr	w15, w15, #10
   82e6c:	2a0003f1 	mov	w17, w0
   82e70:	5280288b 	mov	w11, #0x144                 	// #324
            int si = 0, ci = 1024; // sine and cosine of angle i
   82e74:	52800001 	mov	w1, #0x0                   	// #0
                    x3 = si * x0 >> 10,
   82e78:	1b0e7c28 	mul	w8, w1, w14
                R(5, 8, ci, si) // rotate i
   82e7c:	0b010834 	add	w20, w1, w1, lsl #2
                    x1 = ci * x0 >> 10,
   82e80:	1b0e7e35 	mul	w21, w17, w14
                R(5, 8, ci, si) // rotate i
   82e84:	0b110a22 	add	w2, w17, w17, lsl #2
   82e88:	4b942234 	sub	w20, w17, w20, asr #8
                    x7 = cj * si >> 10,
   82e8c:	4b012d09 	sub	w9, w8, w1, lsl #11
                    x3 = si * x0 >> 10,
   82e90:	130a7d08 	asr	w8, w8, #10
                R(5, 8, ci, si) // rotate i
   82e94:	0b822021 	add	w1, w1, w2, asr #8
                    x1 = ci * x0 >> 10,
   82e98:	130a7eb5 	asr	w21, w21, #10
                    x7 = cj * si >> 10,
   82e9c:	130a7d29 	asr	w9, w9, #10
                R(5, 8, ci, si) // rotate i
   82ea0:	1b14da82 	msub	w2, w20, w20, w22
                    x4 = R1 * x2 - (sA * x3 >> 10),
   82ea4:	1b087caa 	mul	w10, w5, w8
                    x = 25 + 30 * (cB * x1 - sB * x4) / x6,
   82ea8:	1b157e72 	mul	w18, w19, w21
                    lumince = (((-cA * x7 - cB * ((-sA * x7 >> 10) + x2) - ci * (cj * sB >> 10)) >> 10) - x5); 
   82eac:	1b067d20 	mul	w0, w9, w6
                    x4 = R1 * x2 - (sA * x3 >> 10),
   82eb0:	4b8a29aa 	sub	w10, w13, w10, asr #10
                R(5, 8, ci, si) // rotate i
   82eb4:	1b018822 	msub	w2, w1, w1, w2
                    y = 12 + 15 * (cB * x4 + sB * x1) / x6,
   82eb8:	1b157c75 	mul	w21, w3, w21
                    lumince = (((-cA * x7 - cB * ((-sA * x7 >> 10) + x2) - ci * (cj * sB >> 10)) >> 10) - x5); 
   82ebc:	0b8029a0 	add	w0, w13, w0, asr #10
   82ec0:	1b077d29 	mul	w9, w9, w7
                    x = 25 + 30 * (cB * x1 - sB * x4) / x6,
   82ec4:	1b0ac872 	msub	w18, w3, w10, w18
                R(5, 8, ci, si) // rotate i
   82ec8:	130b7c42 	asr	w2, w2, #11
                    y = 12 + 15 * (cB * x4 + sB * x1) / x6,
   82ecc:	1b0a566a 	madd	w10, w19, w10, w21
                    lumince = (((-cA * x7 - cB * ((-sA * x7 >> 10) + x2) - ci * (cj * sB >> 10)) >> 10) - x5); 
   82ed0:	1b13a400 	msub	w0, w0, w19, w9
   82ed4:	52800009 	mov	w9, #0x0                   	// #0
                    x = 25 + 30 * (cB * x1 - sB * x4) / x6,
   82ed8:	531c6e55 	lsl	w21, w18, #4
                    lumince = (((-cA * x7 - cB * ((-sA * x7 >> 10) + x2) - ci * (cj * sB >> 10)) >> 10) - x5); 
   82edc:	1b1181e0 	msub	w0, w15, w17, w0
                    x = 25 + 30 * (cB * x1 - sB * x4) / x6,
   82ee0:	4b1202b2 	sub	w18, w21, w18
                    x6 = K2 + R1 * 1024 * x5 + cA * x3,
   82ee4:	1b084088 	madd	w8, w4, w8, w16
                    y = 12 + 15 * (cB * x4 + sB * x1) / x6,
   82ee8:	531c6d55 	lsl	w21, w10, #4
                R(5, 8, ci, si) // rotate i
   82eec:	1b027e91 	mul	w17, w20, w2
                    y = 12 + 15 * (cB * x4 + sB * x1) / x6,
   82ef0:	4b0a02aa 	sub	w10, w21, w10
                    lumince = (((-cA * x7 - cB * ((-sA * x7 >> 10) + x2) - ci * (cj * sB >> 10)) >> 10) - x5); 
   82ef4:	130a7c00 	asr	w0, w0, #10
                R(5, 8, ci, si) // rotate i
   82ef8:	1b027c21 	mul	w1, w1, w2
                    x = 25 + 30 * (cB * x1 - sB * x4) / x6,
   82efc:	531f7a52 	lsl	w18, w18, #1
                    lumince = lumince<0? 0 : lumince/5; 
   82f00:	6b0c0000 	subs	w0, w0, w12
                R(5, 8, ci, si) // rotate i
   82f04:	130a7e31 	asr	w17, w17, #10
                    y = 12 + 15 * (cB * x4 + sB * x1) / x6,
   82f08:	1ac80d4a 	sdiv	w10, w10, w8
                    lumince = lumince<0? 0 : lumince/5; 
   82f0c:	540000c4 	b.mi	82f24 <donut_pixel+0x1ec>  // b.first
   82f10:	9b3c7c09 	smull	x9, w0, w28
   82f14:	9361fd29 	asr	x9, x9, #33
   82f18:	4b807d29 	sub	w9, w9, w0, asr #31
   82f1c:	7103fd3f 	cmp	w9, #0xff
   82f20:	1a97d129 	csel	w9, w9, w23, le
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82f24:	11002d40 	add	w0, w10, #0xb
                R(5, 8, ci, si) // rotate i
   82f28:	130a7c21 	asr	w1, w1, #10
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82f2c:	7100501f 	cmp	w0, #0x14
   82f30:	54000208 	b.hi	82f70 <donut_pixel+0x238>  // b.pmore
                    x = 25 + 30 * (cB * x1 - sB * x4) / x6,
   82f34:	1ac80e52 	sdiv	w18, w18, w8
                    y = 12 + 15 * (cB * x4 + sB * x1) / x6,
   82f38:	11003142 	add	w2, w10, #0xc
                signed char zz = (x6 - K2) >> 15;
   82f3c:	51540108 	sub	w8, w8, #0x500, lsl #12
                int o = x + 80 * y; // fxl: 80 chars per row
   82f40:	0b020842 	add	w2, w2, w2, lsl #2
                signed char zz = (x6 - K2) >> 15;
   82f44:	934f5908 	sbfx	x8, x8, #15, #8
                    x = 25 + 30 * (cB * x1 - sB * x4) / x6,
   82f48:	11006640 	add	w0, w18, #0x19
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82f4c:	11006252 	add	w18, w18, #0x18
   82f50:	71013a5f 	cmp	w18, #0x4e
   82f54:	540000e8 	b.hi	82f70 <donut_pixel+0x238>  // b.pmore
                int o = x + 80 * y; // fxl: 80 chars per row
   82f58:	0b021002 	add	w2, w0, w2, lsl #4
                if (22 > y && y > 0 && x > 0 && 80 > x && zz < z[idx][o]) { // fxl: z depth will control visibility
   82f5c:	38e2cb00 	ldrsb	w0, [x24, w2, sxtw]
   82f60:	6b08001f 	cmp	w0, w8
   82f64:	5400006d 	b.le	82f70 <donut_pixel+0x238>
                    z[idx][o] = zz;
   82f68:	3822cb08 	strb	w8, [x24, w2, sxtw]
                    b[idx][o] = lumince;
   82f6c:	3822cb69 	strb	w9, [x27, w2, sxtw]
            for (int i = 0; i < 324; i++) {
   82f70:	7100056b 	subs	w11, w11, #0x1
   82f74:	54fff821 	b.ne	82e78 <donut_pixel+0x140>  // b.any
            R(9, 7, cj, sj) // rotate j
   82f78:	0b190f21 	add	w1, w25, w25, lsl #3
   82f7c:	0b1a0f40 	add	w0, w26, w26, lsl #3
        for (int j = 0; j < 90; j++) {
   82f80:	710007de 	subs	w30, w30, #0x1
            R(9, 7, cj, sj) // rotate j
   82f84:	4b811f5a 	sub	w26, w26, w1, asr #7
   82f88:	0b801f39 	add	w25, w25, w0, asr #7
   82f8c:	1b1adb40 	msub	w0, w26, w26, w22
   82f90:	1b198320 	msub	w0, w25, w25, w0
   82f94:	130b7c00 	asr	w0, w0, #11
   82f98:	1b007f5a 	mul	w26, w26, w0
   82f9c:	1b007f39 	mul	w25, w25, w0
   82fa0:	130a7f5a 	asr	w26, w26, #10
   82fa4:	130a7f39 	asr	w25, w25, #10
        for (int j = 0; j < 90; j++) {
   82fa8:	54fff4e1 	b.ne	82e44 <donut_pixel+0x10c>  // b.any
        for (int t = 0; t <=idx%4; t++) {
   82fac:	b9407fe0 	ldr	w0, [sp, #124]
   82fb0:	52800008 	mov	w8, #0x0                   	// #0
            R(5, 7, cA, sA);
   82fb4:	52a00609 	mov	w9, #0x300000              	// #3145728
        for (int t = 0; t <=idx%4; t++) {
   82fb8:	37f80460 	tbnz	w0, #31, 83044 <donut_pixel+0x30c>
   82fbc:	294d17e4 	ldp	w4, w5, [sp, #104]
   82fc0:	b9407be3 	ldr	w3, [sp, #120]
            R(5, 7, cA, sA);
   82fc4:	0b0508a6 	add	w6, w5, w5, lsl #2
            R(5, 8, cB, sB);
   82fc8:	0b030861 	add	w1, w3, w3, lsl #2
            R(5, 7, cA, sA);
   82fcc:	0b040882 	add	w2, w4, w4, lsl #2
            R(5, 8, cB, sB);
   82fd0:	0b130a60 	add	w0, w19, w19, lsl #2
   82fd4:	4b812261 	sub	w1, w19, w1, asr #8
            R(5, 7, cA, sA);
   82fd8:	4b861c84 	sub	w4, w4, w6, asr #7
   82fdc:	0b821ca2 	add	w2, w5, w2, asr #7
            R(5, 8, cB, sB);
   82fe0:	0b802060 	add	w0, w3, w0, asr #8
        for (int t = 0; t <=idx%4; t++) {
   82fe4:	b9407fe3 	ldr	w3, [sp, #124]
   82fe8:	11000508 	add	w8, w8, #0x1
            R(5, 7, cA, sA);
   82fec:	1b04a485 	msub	w5, w4, w4, w9
        for (int t = 0; t <=idx%4; t++) {
   82ff0:	6b03011f 	cmp	w8, w3
            R(5, 8, cB, sB);
   82ff4:	1b01a423 	msub	w3, w1, w1, w9
            R(5, 7, cA, sA);
   82ff8:	1b029445 	msub	w5, w2, w2, w5
            R(5, 8, cB, sB);
   82ffc:	1b008c03 	msub	w3, w0, w0, w3
            R(5, 7, cA, sA);
   83000:	130b7ca5 	asr	w5, w5, #11
            R(5, 8, cB, sB);
   83004:	130b7c63 	asr	w3, w3, #11
            R(5, 7, cA, sA);
   83008:	1b057c84 	mul	w4, w4, w5
            R(5, 8, cB, sB);
   8300c:	1b037c21 	mul	w1, w1, w3
            R(5, 7, cA, sA);
   83010:	1b057c42 	mul	w2, w2, w5
            R(5, 8, cB, sB);
   83014:	1b037c00 	mul	w0, w0, w3
            R(5, 7, cA, sA);
   83018:	130a7c84 	asr	w4, w4, #10
            R(5, 8, cB, sB);
   8301c:	130a7c33 	asr	w19, w1, #10
            R(5, 7, cA, sA);
   83020:	130a7c45 	asr	w5, w2, #10
            R(5, 8, cB, sB);
   83024:	130a7c03 	asr	w3, w0, #10
        for (int t = 0; t <=idx%4; t++) {
   83028:	54fffced 	b.le	82fc4 <donut_pixel+0x28c>
   8302c:	4b0403e0 	neg	w0, w4
   83030:	290d17e4 	stp	w4, w5, [sp, #104]
   83034:	b9007be3 	str	w3, [sp, #120]
   83038:	b900a3e0 	str	w0, [sp, #160]
   8303c:	4b0503e0 	neg	w0, w5
   83040:	b900a7e0 	str	w0, [sp, #164]
        }

        // screen_clear(idx);   // not needed
        int offsetx = xoff[idx], offsety = yoff[idx]; 
   83044:	f0000000 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   83048:	91048000 	add	x0, x0, #0x120
   8304c:	f94043e3 	ldr	x3, [sp, #128]
   83050:	9101a001 	add	x1, x0, #0x68
                    // PIXEL clr = b[k]; // blue only
                    PIXEL clr = int2rgb(b[idx][k]); // to a color spectrum
                    // W("fb %lx idx %d xx %d yy %d pitch %d",
                    //     (unsigned long)the_fb.fb, idx, xx, yy, the_fb.pitch);
                    // expand to a neighborhood of 4 pixels
                    setpixel(the_fb.fb, xx, yy, the_fb.pitch, clr);
   83054:	d0000082 	adrp	x2, 95000 <wordsworth.1722+0xee10>
        int offsetx = xoff[idx], offsety = yoff[idx]; 
   83058:	d280001b 	mov	x27, #0x0                   	// #0
        int y = 0, x = 0;
   8305c:	5280001a 	mov	w26, #0x0                   	// #0
   83060:	52800017 	mov	w23, #0x0                   	// #0
                    setpixel(the_fb.fb, xx, yy, the_fb.pitch, clr);
   83064:	f9476042 	ldr	x2, [x2, #3776]
        int offsetx = xoff[idx], offsety = yoff[idx]; 
   83068:	529999b9 	mov	w25, #0xcccd                	// #52429
   8306c:	b8637821 	ldr	w1, [x1, x3, lsl #2]
            if (k % 80) {
   83070:	52866678 	mov	w24, #0x3333                	// #13107
        int offsetx = xoff[idx], offsety = yoff[idx]; 
   83074:	b8637800 	ldr	w0, [x0, x3, lsl #2]
            if (k % 80) {
   83078:	2a1a03f5 	mov	w21, w26
   8307c:	aa1b03f6 	mov	x22, x27
   83080:	b900d3f3 	str	w19, [sp, #208]
   83084:	2a1703f3 	mov	w19, w23
        int offsetx = xoff[idx], offsety = yoff[idx]; 
   83088:	72b99999 	movk	w25, #0xcccc, lsl #16
            if (k % 80) {
   8308c:	72a06678 	movk	w24, #0x333, lsl #16
                    setpixel(the_fb.fb, xx+1, yy, the_fb.pitch, clr);
   83090:	a9088be2 	stp	x2, x2, [sp, #136]
                    setpixel(the_fb.fb, xx, yy+1, the_fb.pitch, clr);
   83094:	f9004fe2 	str	x2, [sp, #152]
        int offsetx = xoff[idx], offsety = yoff[idx]; 
   83098:	291607e0 	stp	w0, w1, [sp, #176]
   8309c:	d503201f 	nop
   830a0:	1b197ec0 	mul	w0, w22, w25
   830a4:	13801000 	ror	w0, w0, #4
            if (k % 80) {
   830a8:	6b18001f 	cmp	w0, w24
   830ac:	54000ae9 	b.ls	83208 <donut_pixel+0x4d0>  // b.plast
                if (x < 50) {
   830b0:	7100c6bf 	cmp	w21, #0x31
   830b4:	5400028d 	b.le	83104 <donut_pixel+0x3cc>
                    setpixel(the_fb.fb, xx+1, yy+1, the_fb.pitch, clr);
                }
                x++;
   830b8:	110006b5 	add	w21, w21, #0x1
        for (int k = 0; 1761 > k; k++) {
   830bc:	910006d6 	add	x22, x22, #0x1
   830c0:	f11b86df 	cmp	x22, #0x6e1
   830c4:	54fffee1 	b.ne	830a0 <donut_pixel+0x368>  // b.any
                y++;
                x = 1;
            }
        }
        /* STUDENT: TODO: your code here */
        yield();
   830c8:	b940d3f3 	ldr	w19, [sp, #208]
   830cc:	940002d1 	bl	83c10 <yield>

        frame_count[idx]++;
   830d0:	f94043e2 	ldr	x2, [sp, #128]
   830d4:	f0000080 	adrp	x0, 96000 <stdout_putf>
   830d8:	910a4001 	add	x1, x0, #0x290
   830dc:	b8627820 	ldr	w0, [x1, x2, lsl #2]
   830e0:	11000400 	add	w0, w0, #0x1
   830e4:	b8227820 	str	w0, [x1, x2, lsl #2]

        // Exit condition: after ~3 seconds
        // Suppose each frame is roughly 100 ms (adjust if different)
        if (frame_count[idx] == 100 && idx==2) {
   830e8:	7101901f 	cmp	w0, #0x64
   830ec:	b940c7e0 	ldr	w0, [sp, #196]
   830f0:	7a400804 	ccmp	w0, #0x0, #0x4, eq  // eq = none
   830f4:	54ffe7a0 	b.eq	82de8 <donut_pixel+0xb0>  // b.none
            exit_process(0);
   830f8:	52800000 	mov	w0, #0x0                   	// #0
   830fc:	94000397 	bl	83f58 <exit_process>
   83100:	17ffff3a 	b	82de8 <donut_pixel+0xb0>
                    int xx=x*K+offsetx, yy=y*K*2+offsety;
   83104:	b940b3e1 	ldr	w1, [sp, #176]
                    PIXEL clr = int2rgb(b[idx][k]); // to a color spectrum
   83108:	f9403be0 	ldr	x0, [sp, #112]
                    int xx=x*K+offsetx, yy=y*K*2+offsety;
   8310c:	0b15043b 	add	w27, w1, w21, lsl #1
   83110:	b940b7e1 	ldr	w1, [sp, #180]
                    PIXEL clr = int2rgb(b[idx][k]); // to a color spectrum
   83114:	38766800 	ldrb	w0, [x0, x22]
                    int xx=x*K+offsetx, yy=y*K*2+offsety;
   83118:	0b13083a 	add	w26, w1, w19, lsl #2

// map luminance [0..255] to rgb color
// value: 0..255, PIXEL: argb
static PIXEL int2rgb (int value) {
    int r,g,b;     
    if (value >= 0 && value <= 85) {
   8311c:	7101541f 	cmp	w0, #0x55
   83120:	540007a8 	b.hi	83214 <donut_pixel+0x4dc>  // b.pmore
        // Black to Yellow (R stays 0, G increases, B stays 0)
        r = 0;
        g = (value * 3);
   83124:	0b000400 	add	w0, w0, w0, lsl #1
   83128:	53185c14 	lsl	w20, w0, #8
                    setpixel(the_fb.fb, xx, yy, the_fb.pitch, clr);
   8312c:	f94047e1 	ldr	x1, [sp, #136]
    assert(x >= 0 && y >= 0); // important guard
   83130:	2a3b03e0 	mvn	w0, w27
   83134:	2a3a03e7 	mvn	w7, w26
   83138:	531f7c00 	lsr	w0, w0, #31
   8313c:	b900c3e0 	str	w0, [sp, #192]
                    setpixel(the_fb.fb, xx, yy, the_fb.pitch, clr);
   83140:	f940002b 	ldr	x11, [x1]
    assert(x >= 0 && y >= 0); // important guard
   83144:	7100001f 	cmp	w0, #0x0
   83148:	531f7cf7 	lsr	w23, w7, #31
                    setpixel(the_fb.fb, xx, yy, the_fb.pitch, clr);
   8314c:	b940182c 	ldr	w12, [x1, #24]
    assert(x >= 0 && y >= 0); // important guard
   83150:	7a401ae4 	ccmp	w23, #0x0, #0x4, ne  // ne = any
   83154:	aa0b03e9 	mov	x9, x11
   83158:	540007e0 	b.eq	83254 <donut_pixel+0x51c>  // b.none
    *(PIXEL *)(buf + y * pit + x * PIXELSIZE) = p;
   8315c:	531e776a 	lsl	w10, w27, #2
   83160:	1b1a7d8c 	mul	w12, w12, w26
    assert(x >= 0 && y >= 0); // important guard
   83164:	3100077f 	cmn	w27, #0x1
   83168:	aa0903e7 	mov	x7, x9
    *(PIXEL *)(buf + y * pit + x * PIXELSIZE) = p;
   8316c:	93407d40 	sxtw	x0, w10
   83170:	f9005fe0 	str	x0, [sp, #184]
   83174:	8b00016b 	add	x11, x11, x0
    assert(x >= 0 && y >= 0); // important guard
   83178:	1a9fb7fb 	cset	w27, ge  // ge = tcont
                    setpixel(the_fb.fb, xx+1, yy, the_fb.pitch, clr);
   8317c:	f9404be0 	ldr	x0, [sp, #144]
    assert(x >= 0 && y >= 0); // important guard
   83180:	7100037f 	cmp	w27, #0x0
    *(PIXEL *)(buf + y * pit + x * PIXELSIZE) = p;
   83184:	b82cc974 	str	w20, [x11, w12, sxtw]
    assert(x >= 0 && y >= 0); // important guard
   83188:	7a401ae4 	ccmp	w23, #0x0, #0x4, ne  // ne = any
                    setpixel(the_fb.fb, xx+1, yy, the_fb.pitch, clr);
   8318c:	b9401817 	ldr	w23, [x0, #24]
    assert(x >= 0 && y >= 0); // important guard
   83190:	54000b00 	b.eq	832f0 <donut_pixel+0x5b8>  // b.none
    *(PIXEL *)(buf + y * pit + x * PIXELSIZE) = p;
   83194:	1100114a 	add	w10, w10, #0x4
   83198:	1b1a7ee8 	mul	w8, w23, w26
                    setpixel(the_fb.fb, xx, yy+1, the_fb.pitch, clr);
   8319c:	1100075a 	add	w26, w26, #0x1
    assert(x >= 0 && y >= 0); // important guard
   831a0:	b940c3e0 	ldr	w0, [sp, #192]
    *(PIXEL *)(buf + y * pit + x * PIXELSIZE) = p;
   831a4:	93407d57 	sxtw	x23, w10
    assert(x >= 0 && y >= 0); // important guard
   831a8:	2a3a03ea 	mvn	w10, w26
    *(PIXEL *)(buf + y * pit + x * PIXELSIZE) = p;
   831ac:	8b170129 	add	x9, x9, x23
    assert(x >= 0 && y >= 0); // important guard
   831b0:	531f7d4a 	lsr	w10, w10, #31
   831b4:	7100015f 	cmp	w10, #0x0
   831b8:	7a401804 	ccmp	w0, #0x0, #0x4, ne  // ne = any
    *(PIXEL *)(buf + y * pit + x * PIXELSIZE) = p;
   831bc:	b828c934 	str	w20, [x9, w8, sxtw]
                    setpixel(the_fb.fb, xx, yy+1, the_fb.pitch, clr);
   831c0:	f9404fe0 	ldr	x0, [sp, #152]
   831c4:	aa0703e8 	mov	x8, x7
   831c8:	b9401809 	ldr	w9, [x0, #24]
    assert(x >= 0 && y >= 0); // important guard
   831cc:	54000740 	b.eq	832b4 <donut_pixel+0x57c>  // b.none
    *(PIXEL *)(buf + y * pit + x * PIXELSIZE) = p;
   831d0:	f9405fe0 	ldr	x0, [sp, #184]
   831d4:	1b097f49 	mul	w9, w26, w9
    assert(x >= 0 && y >= 0); // important guard
   831d8:	7100015f 	cmp	w10, #0x0
    *(PIXEL *)(buf + y * pit + x * PIXELSIZE) = p;
   831dc:	8b0000e7 	add	x7, x7, x0
                    setpixel(the_fb.fb, xx+1, yy+1, the_fb.pitch, clr);
   831e0:	d0000080 	adrp	x0, 95000 <wordsworth.1722+0xee10>
    assert(x >= 0 && y >= 0); // important guard
   831e4:	7a401b64 	ccmp	w27, #0x0, #0x4, ne  // ne = any
                    setpixel(the_fb.fb, xx+1, yy+1, the_fb.pitch, clr);
   831e8:	f9476000 	ldr	x0, [x0, #3776]
    *(PIXEL *)(buf + y * pit + x * PIXELSIZE) = p;
   831ec:	b829c8f4 	str	w20, [x7, w9, sxtw]
                    setpixel(the_fb.fb, xx+1, yy+1, the_fb.pitch, clr);
   831f0:	b9401807 	ldr	w7, [x0, #24]
    assert(x >= 0 && y >= 0); // important guard
   831f4:	540004a0 	b.eq	83288 <donut_pixel+0x550>  // b.none
    *(PIXEL *)(buf + y * pit + x * PIXELSIZE) = p;
   831f8:	1b077f46 	mul	w6, w26, w7
   831fc:	8b170108 	add	x8, x8, x23
   83200:	b826c914 	str	w20, [x8, w6, sxtw]
}
   83204:	17ffffad 	b	830b8 <donut_pixel+0x380>
                y++;
   83208:	11000673 	add	w19, w19, #0x1
                x = 1;
   8320c:	52800035 	mov	w21, #0x1                   	// #1
   83210:	17ffffab 	b	830bc <donut_pixel+0x384>
        b = 0;
    } else if (value > 85 && value <= 170) {
   83214:	51015801 	sub	w1, w0, #0x56
   83218:	7101503f 	cmp	w1, #0x54
   8321c:	54000108 	b.hi	8323c <donut_pixel+0x504>  // b.pmore
        // Yellow to Cyan (G stays 255, R decreases, B increases)
        r = 255 - ((value - 85) * 3);
   83220:	51015400 	sub	w0, w0, #0x55
   83224:	4b000814 	sub	w20, w0, w0, lsl #2
        g = 255;
        b = (value - 85) * 3;
   83228:	0b000400 	add	w0, w0, w0, lsl #1
        r = 255 - ((value - 85) * 3);
   8322c:	1103fe94 	add	w20, w20, #0xff
   83230:	2a144000 	orr	w0, w0, w20, lsl #16
   83234:	32181c14 	orr	w20, w0, #0xff00
   83238:	17ffffbd 	b	8312c <donut_pixel+0x3f4>
    } else if (value > 170 && value <= 255) {
        // Cyan to Blue (G decreases, B stays 255, R stays 0)
        r = 0;
        g = 255 - ((value - 170) * 3);
   8323c:	5102a800 	sub	w0, w0, #0xaa
   83240:	4b000800 	sub	w0, w0, w0, lsl #2
   83244:	1103fc14 	add	w20, w0, #0xff
   83248:	53185e94 	lsl	w20, w20, #8
   8324c:	32001e94 	orr	w20, w20, #0xff
   83250:	17ffffb7 	b	8312c <donut_pixel+0x3f4>
    assert(x >= 0 && y >= 0); // important guard
   83254:	b0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   83258:	52800302 	mov	w2, #0x18                  	// #24
   8325c:	91068001 	add	x1, x0, #0x1a0
   83260:	b0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   83264:	9106a000 	add	x0, x0, #0x1a8
   83268:	f9005feb 	str	x11, [sp, #184]
   8326c:	b900d7ec 	str	w12, [sp, #212]
   83270:	97fff9ba 	bl	81958 <assertion_failed>
   83274:	f94047e0 	ldr	x0, [sp, #136]
   83278:	b940d7ec 	ldr	w12, [sp, #212]
   8327c:	f9405feb 	ldr	x11, [sp, #184]
   83280:	f9400009 	ldr	x9, [x0]
   83284:	17ffffb6 	b	8315c <donut_pixel+0x424>
   83288:	b0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   8328c:	52800302 	mov	w2, #0x18                  	// #24
   83290:	91068001 	add	x1, x0, #0x1a0
   83294:	b0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   83298:	9106a000 	add	x0, x0, #0x1a8
   8329c:	f9005fe8 	str	x8, [sp, #184]
   832a0:	b900c3e7 	str	w7, [sp, #192]
   832a4:	97fff9ad 	bl	81958 <assertion_failed>
   832a8:	b940c3e7 	ldr	w7, [sp, #192]
   832ac:	f9405fe8 	ldr	x8, [sp, #184]
   832b0:	17ffffd2 	b	831f8 <donut_pixel+0x4c0>
   832b4:	b0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   832b8:	52800302 	mov	w2, #0x18                  	// #24
   832bc:	91068001 	add	x1, x0, #0x1a0
   832c0:	b0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   832c4:	9106a000 	add	x0, x0, #0x1a8
   832c8:	b900c3e9 	str	w9, [sp, #192]
   832cc:	b900d7ea 	str	w10, [sp, #212]
   832d0:	f9006fe7 	str	x7, [sp, #216]
   832d4:	97fff9a1 	bl	81958 <assertion_failed>
   832d8:	f9404fe0 	ldr	x0, [sp, #152]
   832dc:	b940c3e9 	ldr	w9, [sp, #192]
   832e0:	b940d7ea 	ldr	w10, [sp, #212]
   832e4:	f9400008 	ldr	x8, [x0]
   832e8:	f9406fe7 	ldr	x7, [sp, #216]
   832ec:	17ffffb9 	b	831d0 <donut_pixel+0x498>
   832f0:	b0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   832f4:	52800302 	mov	w2, #0x18                  	// #24
   832f8:	91068001 	add	x1, x0, #0x1a0
   832fc:	b0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   83300:	9106a000 	add	x0, x0, #0x1a8
   83304:	b900d7ea 	str	w10, [sp, #212]
   83308:	f9006fe9 	str	x9, [sp, #216]
   8330c:	97fff993 	bl	81958 <assertion_failed>
   83310:	f9404be0 	ldr	x0, [sp, #144]
   83314:	b940d7ea 	ldr	w10, [sp, #212]
   83318:	f9406fe9 	ldr	x9, [sp, #216]
   8331c:	f9400007 	ldr	x7, [x0]
   83320:	17ffff9d 	b	83194 <donut_pixel+0x45c>
   83324:	d503201f 	nop

0000000000083328 <donut>:
    return (r<<16)|(g<<8)|b; 
}

// idx: region in the canvas
// 
void donut(int idx) {
   83328:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   8332c:	910003fd 	mov	x29, sp
    donut_pixel(idx);
   83330:	97fffe82 	bl	82d38 <donut_pixel>
   83334:	00000000 	udf	#0

0000000000083338 <_reserve_phys_region>:
	caller MUST hold alloc_lock
	is_reserve: 1 for reserve, 0 for free
	return 0 if OK  */
static int _reserve_phys_region(unsigned long pa_start, 
	unsigned long size, int is_reserve) {
	if ((pa_start & ~PAGE_MASK) != 0 || (size & ~PAGE_MASK) != 0) // must align
   83338:	aa010003 	orr	x3, x0, x1
   8333c:	f2402c7f 	tst	x3, #0xfff
   83340:	540005a1 	b.ne	833f4 <_reserve_phys_region+0xbc>  // b.any
		{W("pa_start %lx size %lx", pa_start, size);BUG(); return -1;}

	for (unsigned i = ((pa_start-LOW_MEMORY)>>PAGE_SHIFT); 
   83344:	9000014a 	adrp	x10, ab000 <b+0xa128>
   83348:	90000149 	adrp	x9, ab000 <b+0xa128>
			i<((pa_start-LOW_MEMORY+size)>>PAGE_SHIFT); i++){
		if (mem_map[i] == is_reserve)	
   8334c:	912b6128 	add	x8, x9, #0xad8
	for (unsigned i = ((pa_start-LOW_MEMORY)>>PAGE_SHIFT); 
   83350:	f9455d43 	ldr	x3, [x10, #2744]
   83354:	cb030000 	sub	x0, x0, x3
			i<((pa_start-LOW_MEMORY+size)>>PAGE_SHIFT); i++){
   83358:	8b010007 	add	x7, x0, x1
	for (unsigned i = ((pa_start-LOW_MEMORY)>>PAGE_SHIFT); 
   8335c:	d34cfc00 	lsr	x0, x0, #12
   83360:	92407c04 	and	x4, x0, #0xffffffff
   83364:	2a0003e5 	mov	w5, w0
   83368:	eb47309f 	cmp	x4, x7, lsr #12
   8336c:	aa0503e3 	mov	x3, x5
			i<((pa_start-LOW_MEMORY+size)>>PAGE_SHIFT); i++){
   83370:	d34cfce7 	lsr	x7, x7, #12
	for (unsigned i = ((pa_start-LOW_MEMORY)>>PAGE_SHIFT); 
   83374:	54000083 	b.cc	83384 <_reserve_phys_region+0x4c>  // b.lo, b.ul, b.last
   83378:	14000013 	b	833c4 <_reserve_phys_region+0x8c>
   8337c:	eb2540ff 	cmp	x7, w5, uxtw
   83380:	54000109 	b.ls	833a0 <_reserve_phys_region+0x68>  // b.plast
		if (mem_map[i] == is_reserve)	
   83384:	38656906 	ldrb	w6, [x8, x5]
			i<((pa_start-LOW_MEMORY+size)>>PAGE_SHIFT); i++){
   83388:	11000405 	add	w5, w0, #0x1
   8338c:	aa0503e0 	mov	x0, x5
		if (mem_map[i] == is_reserve)	
   83390:	6b0200df 	cmp	w6, w2
   83394:	54ffff41 	b.ne	8337c <_reserve_phys_region+0x44>  // b.any
			{return -2;}      // page already reserved / freed? 
   83398:	12800020 	mov	w0, #0xfffffffe            	// #-2

	I("%s: %s. pa_start %lx -- %lx size %lx",
		 __func__, is_reserve?"reserved":"freed", 
		 pa_start, pa_start+size, size);
	return 0; 
}
   8339c:	d65f03c0 	ret
		mem_map[i] = is_reserve; 
   833a0:	912b6125 	add	x5, x9, #0xad8
   833a4:	12001c44 	and	w4, w2, #0xff
   833a8:	2a0303e0 	mov	w0, w3
   833ac:	d503201f 	nop
		i<((pa_start-LOW_MEMORY+size)>>PAGE_SHIFT); i++){
   833b0:	11000463 	add	w3, w3, #0x1
		mem_map[i] = is_reserve; 
   833b4:	382068a4 	strb	w4, [x5, x0]
		i<((pa_start-LOW_MEMORY+size)>>PAGE_SHIFT); i++){
   833b8:	2a0303e0 	mov	w0, w3
	for (unsigned i = ((pa_start-LOW_MEMORY)>>PAGE_SHIFT); 
   833bc:	eb2340ff 	cmp	x7, w3, uxtw
   833c0:	54ffff88 	b.hi	833b0 <_reserve_phys_region+0x78>  // b.pmore
	if (is_reserve) paging_pages_used += (size>>PAGE_SHIFT); 
   833c4:	912ae14a 	add	x10, x10, #0xab8
   833c8:	d34cfc21 	lsr	x1, x1, #12
   833cc:	b9400940 	ldr	w0, [x10, #8]
   833d0:	340000a2 	cbz	w2, 833e4 <_reserve_phys_region+0xac>
   833d4:	0b010001 	add	w1, w0, w1
	return 0; 
   833d8:	52800000 	mov	w0, #0x0                   	// #0
	if (is_reserve) paging_pages_used += (size>>PAGE_SHIFT); 
   833dc:	b9000941 	str	w1, [x10, #8]
   833e0:	d65f03c0 	ret
		else paging_pages_used -= (size>>PAGE_SHIFT);
   833e4:	4b010001 	sub	w1, w0, w1
	return 0; 
   833e8:	52800000 	mov	w0, #0x0                   	// #0
		else paging_pages_used -= (size>>PAGE_SHIFT);
   833ec:	b9000941 	str	w1, [x10, #8]
   833f0:	d65f03c0 	ret
	unsigned long size, int is_reserve) {
   833f4:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
		{W("pa_start %lx size %lx", pa_start, size);BUG(); return -1;}
   833f8:	aa0103e4 	mov	x4, x1
   833fc:	aa0003e3 	mov	x3, x0
	unsigned long size, int is_reserve) {
   83400:	910003fd 	mov	x29, sp
		{W("pa_start %lx size %lx", pa_start, size);BUG(); return -1;}
   83404:	b0000081 	adrp	x1, 94000 <wordsworth.1722+0xde10>
	unsigned long size, int is_reserve) {
   83408:	f9000bf3 	str	x19, [sp, #16]
		{W("pa_start %lx size %lx", pa_start, size);BUG(); return -1;}
   8340c:	91070033 	add	x19, x1, #0x1c0
   83410:	52800a02 	mov	w2, #0x50                  	// #80
   83414:	aa1303e1 	mov	x1, x19
   83418:	b0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   8341c:	91072000 	add	x0, x0, #0x1c8
   83420:	97fff87e 	bl	81618 <tfp_printf>
   83424:	aa1303e1 	mov	x1, x19
   83428:	52800a02 	mov	w2, #0x50                  	// #80
   8342c:	f0000000 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   83430:	910d8000 	add	x0, x0, #0x360
   83434:	97fff949 	bl	81958 <assertion_failed>
   83438:	12800000 	mov	w0, #0xffffffff            	// #-1
}
   8343c:	f9400bf3 	ldr	x19, [sp, #16]
   83440:	a8c27bfd 	ldp	x29, x30, [sp], #32
   83444:	d65f03c0 	ret

0000000000083448 <get_free_page>:
unsigned long get_free_page() {
   83448:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   8344c:	910003fd 	mov	x29, sp
   83450:	a90153f3 	stp	x19, x20, [sp, #16]
	acquire(&alloc_lock);
   83454:	d0000094 	adrp	x20, 95000 <wordsworth.1722+0xee10>
   83458:	91386280 	add	x0, x20, #0xe18
unsigned long get_free_page() {
   8345c:	f90013f5 	str	x21, [sp, #32]
	acquire(&alloc_lock);
   83460:	97fff9fe 	bl	81c58 <acquire>
	for (int i = 0; i < PAGING_PAGES-MALLOC_PAGES; i++){
   83464:	90000155 	adrp	x21, ab000 <b+0xa128>
   83468:	912ae2a0 	add	x0, x21, #0xab8
   8346c:	f9400802 	ldr	x2, [x0, #16]
   83470:	f1200042 	subs	x2, x2, #0x800
   83474:	540003c0 	b.eq	834ec <get_free_page+0xa4>  // b.none
   83478:	90000143 	adrp	x3, ab000 <b+0xa128>
   8347c:	d2800000 	mov	x0, #0x0                   	// #0
		if (mem_map[i] == 0){
   83480:	912b6063 	add	x3, x3, #0xad8
   83484:	14000002 	b	8348c <get_free_page+0x44>
	for (int i = 0; i < PAGING_PAGES-MALLOC_PAGES; i++){
   83488:	54000320 	b.eq	834ec <get_free_page+0xa4>  // b.none
		if (mem_map[i] == 0){
   8348c:	38636801 	ldrb	w1, [x0, x3]
   83490:	2a0003f3 	mov	w19, w0
   83494:	91000400 	add	x0, x0, #0x1
	for (int i = 0; i < PAGING_PAGES-MALLOC_PAGES; i++){
   83498:	eb02001f 	cmp	x0, x2
		if (mem_map[i] == 0){
   8349c:	35ffff61 	cbnz	w1, 83488 <get_free_page+0x40>
			mem_map[i] = 1; paging_pages_used++;
   834a0:	912ae2a2 	add	x2, x21, #0xab8
   834a4:	52800021 	mov	w1, #0x1                   	// #1
   834a8:	3833c861 	strb	w1, [x3, w19, sxtw]
			release(&alloc_lock);
   834ac:	91386280 	add	x0, x20, #0xe18
			unsigned long page = LOW_MEMORY + i*PAGE_SIZE;
   834b0:	53144e73 	lsl	w19, w19, #12
			mem_map[i] = 1; paging_pages_used++;
   834b4:	b9400841 	ldr	w1, [x2, #8]
   834b8:	11000421 	add	w1, w1, #0x1
   834bc:	b9000841 	str	w1, [x2, #8]
			release(&alloc_lock);
   834c0:	97fffa28 	bl	81d60 <release>
			unsigned long page = LOW_MEMORY + i*PAGE_SIZE;
   834c4:	f9455ea0 	ldr	x0, [x21, #2744]
			memzero_aligned((void *)page, PAGE_SIZE);
   834c8:	d2820001 	mov	x1, #0x1000                	// #4096
			unsigned long page = LOW_MEMORY + i*PAGE_SIZE;
   834cc:	8b33c013 	add	x19, x0, w19, sxtw
			memzero_aligned((void *)page, PAGE_SIZE);
   834d0:	aa1303e0 	mov	x0, x19
   834d4:	94000aa0 	bl	85f54 <memzero_aligned>
}
   834d8:	aa1303e0 	mov	x0, x19
   834dc:	a94153f3 	ldp	x19, x20, [sp, #16]
   834e0:	f94013f5 	ldr	x21, [sp, #32]
   834e4:	a8c37bfd 	ldp	x29, x30, [sp], #48
   834e8:	d65f03c0 	ret
	release(&alloc_lock);
   834ec:	91386280 	add	x0, x20, #0xe18
	return 0;
   834f0:	d2800013 	mov	x19, #0x0                   	// #0
	release(&alloc_lock);
   834f4:	97fffa1b 	bl	81d60 <release>
}
   834f8:	aa1303e0 	mov	x0, x19
   834fc:	a94153f3 	ldp	x19, x20, [sp, #16]
   83500:	f94013f5 	ldr	x21, [sp, #32]
   83504:	a8c37bfd 	ldp	x29, x30, [sp], #48
   83508:	d65f03c0 	ret
   8350c:	d503201f 	nop

0000000000083510 <free_page>:
void free_page(unsigned long p){
   83510:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   83514:	910003fd 	mov	x29, sp
   83518:	a90153f3 	stp	x19, x20, [sp, #16]
	acquire(&alloc_lock);
   8351c:	d0000094 	adrp	x20, 95000 <wordsworth.1722+0xee10>
   83520:	91386294 	add	x20, x20, #0xe18
void free_page(unsigned long p){
   83524:	aa0003f3 	mov	x19, x0
	acquire(&alloc_lock);
   83528:	aa1403e0 	mov	x0, x20
   8352c:	97fff9cb 	bl	81c58 <acquire>
	mem_map[(p - LOW_MEMORY)>>PAGE_SHIFT] = 0; paging_pages_used--;
   83530:	90000140 	adrp	x0, ab000 <b+0xa128>
   83534:	90000141 	adrp	x1, ab000 <b+0xa128>
   83538:	912ae003 	add	x3, x0, #0xab8
   8353c:	912b6021 	add	x1, x1, #0xad8
   83540:	f9455c04 	ldr	x4, [x0, #2744]
	release(&alloc_lock);
   83544:	aa1403e0 	mov	x0, x20
	mem_map[(p - LOW_MEMORY)>>PAGE_SHIFT] = 0; paging_pages_used--;
   83548:	b9400862 	ldr	w2, [x3, #8]
   8354c:	cb040273 	sub	x19, x19, x4
   83550:	51000442 	sub	w2, w2, #0x1
   83554:	d34cfe73 	lsr	x19, x19, #12
   83558:	3833683f 	strb	wzr, [x1, x19]
}
   8355c:	a94153f3 	ldp	x19, x20, [sp, #16]
	mem_map[(p - LOW_MEMORY)>>PAGE_SHIFT] = 0; paging_pages_used--;
   83560:	b9000862 	str	w2, [x3, #8]
}
   83564:	a8c27bfd 	ldp	x29, x30, [sp], #32
	release(&alloc_lock);
   83568:	17fff9fe 	b	81d60 <release>
   8356c:	d503201f 	nop

0000000000083570 <reserve_phys_region>:

/* same as above. but caller MUST NOT hold alloc_lock */
int reserve_phys_region(unsigned long pa_start, unsigned long size) {
   83570:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   83574:	910003fd 	mov	x29, sp
   83578:	a90153f3 	stp	x19, x20, [sp, #16]
	int ret; 
	acquire(&alloc_lock); 
   8357c:	d0000093 	adrp	x19, 95000 <wordsworth.1722+0xee10>
   83580:	91386273 	add	x19, x19, #0xe18
int reserve_phys_region(unsigned long pa_start, unsigned long size) {
   83584:	aa0003f4 	mov	x20, x0
	acquire(&alloc_lock); 
   83588:	aa1303e0 	mov	x0, x19
int reserve_phys_region(unsigned long pa_start, unsigned long size) {
   8358c:	f90013f5 	str	x21, [sp, #32]
   83590:	aa0103f5 	mov	x21, x1
	acquire(&alloc_lock); 
   83594:	97fff9b1 	bl	81c58 <acquire>
	ret = _reserve_phys_region(pa_start, size, 1/*reserve*/);
   83598:	aa1503e1 	mov	x1, x21
   8359c:	52800022 	mov	w2, #0x1                   	// #1
   835a0:	aa1403e0 	mov	x0, x20
   835a4:	97ffff65 	bl	83338 <_reserve_phys_region>
   835a8:	2a0003e1 	mov	w1, w0
	release(&alloc_lock); 
   835ac:	aa1303e0 	mov	x0, x19
	ret = _reserve_phys_region(pa_start, size, 1/*reserve*/);
   835b0:	2a0103f3 	mov	w19, w1
	release(&alloc_lock); 
   835b4:	97fff9eb 	bl	81d60 <release>
	return ret; 
}
   835b8:	2a1303e0 	mov	w0, w19
   835bc:	a94153f3 	ldp	x19, x20, [sp, #16]
   835c0:	f94013f5 	ldr	x21, [sp, #32]
   835c4:	a8c37bfd 	ldp	x29, x30, [sp], #48
   835c8:	d65f03c0 	ret
   835cc:	d503201f 	nop

00000000000835d0 <free_phys_region>:

/* same as above. but caller MUST NOT hold alloc_lock */
int free_phys_region(unsigned long pa_start, unsigned long size) {
   835d0:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   835d4:	910003fd 	mov	x29, sp
   835d8:	a90153f3 	stp	x19, x20, [sp, #16]
	int ret; 
	acquire(&alloc_lock); 
   835dc:	d0000093 	adrp	x19, 95000 <wordsworth.1722+0xee10>
   835e0:	91386273 	add	x19, x19, #0xe18
int free_phys_region(unsigned long pa_start, unsigned long size) {
   835e4:	aa0003f4 	mov	x20, x0
	acquire(&alloc_lock); 
   835e8:	aa1303e0 	mov	x0, x19
int free_phys_region(unsigned long pa_start, unsigned long size) {
   835ec:	f90013f5 	str	x21, [sp, #32]
   835f0:	aa0103f5 	mov	x21, x1
	acquire(&alloc_lock); 
   835f4:	97fff999 	bl	81c58 <acquire>
	ret = _reserve_phys_region(pa_start, size, 0/*free*/);
   835f8:	aa1503e1 	mov	x1, x21
   835fc:	52800002 	mov	w2, #0x0                   	// #0
   83600:	aa1403e0 	mov	x0, x20
   83604:	97ffff4d 	bl	83338 <_reserve_phys_region>
   83608:	2a0003e1 	mov	w1, w0
	release(&alloc_lock); 
   8360c:	aa1303e0 	mov	x0, x19
	ret = _reserve_phys_region(pa_start, size, 0/*free*/);
   83610:	2a0103f3 	mov	w19, w1
	release(&alloc_lock); 
   83614:	97fff9d3 	bl	81d60 <release>
	return ret; 
}
   83618:	2a1303e0 	mov	w0, w19
   8361c:	a94153f3 	ldp	x19, x20, [sp, #16]
   83620:	f94013f5 	ldr	x21, [sp, #32]
   83624:	a8c37bfd 	ldp	x29, x30, [sp], #48
   83628:	d65f03c0 	ret
   8362c:	d503201f 	nop

0000000000083630 <paging_init>:

/* init kernel's memory mgmt 
	return: # of paging pages */
unsigned int paging_init() {
   83630:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
	LOW_MEMORY = PGROUNDUP((unsigned long)&kernel_end);
	PAGING_PAGES = (HIGH_MEMORY0 - LOW_MEMORY) / PAGE_SIZE; // comment above
   83634:	d2a78200 	mov	x0, #0x3c100000            	// #1007681536
unsigned int paging_init() {
   83638:	910003fd 	mov	x29, sp
   8363c:	a90153f3 	stp	x19, x20, [sp, #16]
	LOW_MEMORY = PGROUNDUP((unsigned long)&kernel_end);
   83640:	d0000094 	adrp	x20, 95000 <wordsworth.1722+0xee10>
   83644:	90000153 	adrp	x19, ab000 <b+0xa128>
   83648:	f9475294 	ldr	x20, [x20, #3744]
   8364c:	912ae262 	add	x2, x19, #0xab8
unsigned int paging_init() {
   83650:	f90013f5 	str	x21, [sp, #32]
	LOW_MEMORY = PGROUNDUP((unsigned long)&kernel_end);
   83654:	913ffe81 	add	x1, x20, #0xfff
   83658:	9274cc21 	and	x1, x1, #0xfffffffffffff000
   8365c:	f9055e61 	str	x1, [x19, #2744]
	PAGING_PAGES = (HIGH_MEMORY0 - LOW_MEMORY) / PAGE_SIZE; // comment above
   83660:	cb010000 	sub	x0, x0, x1
   83664:	d34cfc00 	lsr	x0, x0, #12
   83668:	f9000840 	str	x0, [x2, #16]
	
    BUG_ON(2 * MALLOC_PAGES >= PAGING_PAGES); // too many malloc pages 
   8366c:	f140041f 	cmp	x0, #0x1, lsl #12
   83670:	54000aa9 	b.ls	837c4 <paging_init+0x194>  // b.plast

    /* reserve a virtually contig region for malloc()  */
    if (MALLOC_PAGES) {
        acquire(&alloc_lock); 
   83674:	d0000095 	adrp	x21, 95000 <wordsworth.1722+0xee10>
   83678:	913862a0 	add	x0, x21, #0xe18
   8367c:	97fff977 	bl	81c58 <acquire>
		int ret = _reserve_phys_region(HIGH_MEMORY0-MALLOC_PAGES*PAGE_SIZE, 
   83680:	52800022 	mov	w2, #0x1                   	// #1
   83684:	d2a01001 	mov	x1, #0x800000              	// #8388608
   83688:	d2a77200 	mov	x0, #0x3b900000            	// #999292928
   8368c:	97ffff2b 	bl	83338 <_reserve_phys_region>
			MALLOC_PAGES*PAGE_SIZE, 1); 
        BUG_ON(ret); 
   83690:	35000b80 	cbnz	w0, 83800 <paging_init+0x1d0>
        release(&alloc_lock);
   83694:	913862a0 	add	x0, x21, #0xe18
   83698:	97fff9b2 	bl	81d60 <release>
    }

	printf("phys mem: %08x -- %08x\n", PHYS_BASE, PHYS_BASE + PHYS_SIZE);
   8369c:	52a7e002 	mov	w2, #0x3f000000            	// #1056964608
   836a0:	52800001 	mov	w1, #0x0                   	// #0
   836a4:	b0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   836a8:	91094000 	add	x0, x0, #0x250
   836ac:	97fff7db 	bl	81618 <tfp_printf>
	printf("\t kernel: %08x -- %08lx\n", KERNEL_START, (unsigned long)(&kernel_end));
   836b0:	aa1403e2 	mov	x2, x20
   836b4:	52a00101 	mov	w1, #0x80000               	// #524288
   836b8:	b0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   836bc:	9109a000 	add	x0, x0, #0x268
   836c0:	97fff7d6 	bl	81618 <tfp_printf>
	printf("\t paging mem: %08lx -- %08x\n", LOW_MEMORY, HIGH_MEMORY0-(MALLOC_PAGES<<PAGE_SHIFT));
   836c4:	f9455e61 	ldr	x1, [x19, #2744]
   836c8:	b0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   836cc:	52a77202 	mov	w2, #0x3b900000            	// #999292928
   836d0:	910a2000 	add	x0, x0, #0x288
   836d4:	97fff7d1 	bl	81618 <tfp_printf>
	printf("\t\t %lu%s %ld pages\n", 
		int_val((HIGH_MEMORY0 - LOW_MEMORY)),
   836d8:	f9455e60 	ldr	x0, [x19, #2744]
   836dc:	d2a78201 	mov	x1, #0x3c100000            	// #1007681536
   836e0:	cb000021 	sub	x1, x1, x0
   836e4:	f10ffc3f 	cmp	x1, #0x3ff
   836e8:	54000129 	b.ls	8370c <paging_init+0xdc>  // b.plast
   836ec:	b2404fe0 	mov	x0, #0xfffff               	// #1048575
   836f0:	eb00003f 	cmp	x1, x0
   836f4:	54000508 	b.hi	83794 <paging_init+0x164>  // b.pmore
		int_postfix((HIGH_MEMORY0 - LOW_MEMORY)),
   836f8:	b0000082 	adrp	x2, 94000 <wordsworth.1722+0xde10>
		int_val((HIGH_MEMORY0 - LOW_MEMORY)),
   836fc:	d34afc21 	lsr	x1, x1, #10
		int_postfix((HIGH_MEMORY0 - LOW_MEMORY)),
   83700:	91080042 	add	x2, x2, #0x200
   83704:	b0000095 	adrp	x21, 94000 <wordsworth.1722+0xde10>
   83708:	14000004 	b	83718 <paging_init+0xe8>
   8370c:	f0000002 	adrp	x2, 86000 <__asm_dcache_level+0xc>
   83710:	911be042 	add	x2, x2, #0x6f8
   83714:	b0000095 	adrp	x21, 94000 <wordsworth.1722+0xde10>
	printf("\t\t %lu%s %ld pages\n", 
   83718:	912ae274 	add	x20, x19, #0xab8
   8371c:	b0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   83720:	910aa000 	add	x0, x0, #0x2a8
   83724:	f9400a83 	ldr	x3, [x20, #16]
   83728:	97fff7bc 	bl	81618 <tfp_printf>
		PAGING_PAGES);
    printf("\t malloc mem: %08x -- %08x\n", HIGH_MEMORY0-(MALLOC_PAGES<<PAGE_SHIFT), HIGH_MEMORY0);
   8372c:	52a78202 	mov	w2, #0x3c100000            	// #1007681536
   83730:	52a77201 	mov	w1, #0x3b900000            	// #999292928
   83734:	b0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   83738:	910b0000 	add	x0, x0, #0x2c0
   8373c:	97fff7b7 	bl	81618 <tfp_printf>
	printf("\t\t %lu%s\n", int_val(MALLOC_PAGES * PAGE_SIZE),
   83740:	910822a2 	add	x2, x21, #0x208
   83744:	d2800101 	mov	x1, #0x8                   	// #8
   83748:	b0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   8374c:	910b8000 	add	x0, x0, #0x2e0
   83750:	97fff7b2 	bl	81618 <tfp_printf>
                                 int_postfix(MALLOC_PAGES * PAGE_SIZE)); 
	printf("\t reserved for framebuffer: %08x -- %08x\n", 
   83754:	52a7e002 	mov	w2, #0x3f000000            	// #1056964608
   83758:	52a78201 	mov	w1, #0x3c100000            	// #1007681536
   8375c:	b0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   83760:	910bc000 	add	x0, x0, #0x2f0
   83764:	97fff7ad 	bl	81618 <tfp_printf>
		HIGH_MEMORY0, HIGH_MEMORY);

	paging_pages_total = ((HIGH_MEMORY0-LOW_MEMORY)>>PAGE_SHIFT) - MALLOC_PAGES; 
   83768:	f9455e62 	ldr	x2, [x19, #2744]
   8376c:	d2a78201 	mov	x1, #0x3c100000            	// #1007681536

	return PAGING_PAGES; 
}
   83770:	f94013f5 	ldr	x21, [sp, #32]
	paging_pages_total = ((HIGH_MEMORY0-LOW_MEMORY)>>PAGE_SHIFT) - MALLOC_PAGES; 
   83774:	cb020021 	sub	x1, x1, x2
}
   83778:	b9401280 	ldr	w0, [x20, #16]
	paging_pages_total = ((HIGH_MEMORY0-LOW_MEMORY)>>PAGE_SHIFT) - MALLOC_PAGES; 
   8377c:	d34cfc21 	lsr	x1, x1, #12
   83780:	51200021 	sub	w1, w1, #0x800
   83784:	b9001a81 	str	w1, [x20, #24]
}
   83788:	a94153f3 	ldp	x19, x20, [sp, #16]
   8378c:	a8c37bfd 	ldp	x29, x30, [sp], #48
   83790:	d65f03c0 	ret
		int_val((HIGH_MEMORY0 - LOW_MEMORY)),
   83794:	b24077e0 	mov	x0, #0x3fffffff            	// #1073741823
   83798:	eb00003f 	cmp	x1, x0
   8379c:	540000a8 	b.hi	837b0 <paging_init+0x180>  // b.pmore
		int_postfix((HIGH_MEMORY0 - LOW_MEMORY)),
   837a0:	b0000095 	adrp	x21, 94000 <wordsworth.1722+0xde10>
		int_val((HIGH_MEMORY0 - LOW_MEMORY)),
   837a4:	d354fc21 	lsr	x1, x1, #20
		int_postfix((HIGH_MEMORY0 - LOW_MEMORY)),
   837a8:	910822a2 	add	x2, x21, #0x208
   837ac:	17ffffdb 	b	83718 <paging_init+0xe8>
   837b0:	b0000082 	adrp	x2, 94000 <wordsworth.1722+0xde10>
		int_val((HIGH_MEMORY0 - LOW_MEMORY)),
   837b4:	d35efc21 	lsr	x1, x1, #30
		int_postfix((HIGH_MEMORY0 - LOW_MEMORY)),
   837b8:	9107e042 	add	x2, x2, #0x1f8
   837bc:	b0000095 	adrp	x21, 94000 <wordsworth.1722+0xde10>
   837c0:	17ffffd6 	b	83718 <paging_init+0xe8>
    BUG_ON(2 * MALLOC_PAGES >= PAGING_PAGES); // too many malloc pages 
   837c4:	b0000081 	adrp	x1, 94000 <wordsworth.1722+0xde10>
   837c8:	91070021 	add	x1, x1, #0x1c0
   837cc:	52800f82 	mov	w2, #0x7c                  	// #124
   837d0:	b0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   837d4:	91084000 	add	x0, x0, #0x210
   837d8:	97fff860 	bl	81958 <assertion_failed>
        acquire(&alloc_lock); 
   837dc:	d0000095 	adrp	x21, 95000 <wordsworth.1722+0xee10>
   837e0:	913862a0 	add	x0, x21, #0xe18
   837e4:	97fff91d 	bl	81c58 <acquire>
		int ret = _reserve_phys_region(HIGH_MEMORY0-MALLOC_PAGES*PAGE_SIZE, 
   837e8:	52800022 	mov	w2, #0x1                   	// #1
   837ec:	d2a01001 	mov	x1, #0x800000              	// #8388608
   837f0:	d2a77200 	mov	x0, #0x3b900000            	// #999292928
   837f4:	97fffed1 	bl	83338 <_reserve_phys_region>
        BUG_ON(ret); 
   837f8:	34fff4e0 	cbz	w0, 83694 <paging_init+0x64>
   837fc:	d503201f 	nop
   83800:	b0000081 	adrp	x1, 94000 <wordsworth.1722+0xde10>
   83804:	b0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   83808:	91070021 	add	x1, x1, #0x1c0
   8380c:	91092000 	add	x0, x0, #0x248
   83810:	52801062 	mov	w2, #0x83                  	// #131
   83814:	97fff851 	bl	81958 <assertion_failed>
   83818:	17ffff9f 	b	83694 <paging_init+0x64>
   8381c:	00000000 	udf	#0

0000000000083820 <myproc>:
    [TASK_RUNNING]  "RUNNING ",
    [TASK_SLEEPING] "SLEEP   ",
    [TASK_RUNNABLE] "RUNNABLE",
    [TASK_ZOMBIE]   "ZOMBIE  "};
    
struct task_struct *myproc(void) {      
   83820:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   83824:	910003fd 	mov	x29, sp
   83828:	f9000bf3 	str	x19, [sp, #16]
    struct task_struct *p;
    /* need disable irq b/c: if right after mycpu(), the cur task moves to 
    a diff cpu, then cpu still points to a previous cpu and ->proc 
    is not this task but a diff one */
	push_off(); 
   8382c:	97fff8f7 	bl	81c08 <push_off>
    p=mycpu()->proc; 
   83830:	d0000080 	adrp	x0, 95000 <wordsworth.1722+0xee10>
   83834:	f9475c00 	ldr	x0, [x0, #3768]
   83838:	f9400013 	ldr	x19, [x0]
    pop_off(); 
   8383c:	97fff929 	bl	81ce0 <pop_off>
	return p; 
};
   83840:	aa1303e0 	mov	x0, x19
   83844:	f9400bf3 	ldr	x19, [sp, #16]
   83848:	a8c27bfd 	ldp	x29, x30, [sp], #32
   8384c:	d65f03c0 	ret

0000000000083850 <sched_init>:

extern void init(int arg); // kernel.c

/* must be called BEFORE any schedule() or timertick() occurs */
void sched_init(void) {
   83850:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
   83854:	910003fd 	mov	x29, sp
   83858:	f9001bf7 	str	x23, [sp, #48]
   8385c:	d0000097 	adrp	x23, 95000 <wordsworth.1722+0xee10>
   83860:	a90153f3 	stp	x19, x20, [sp, #16]
   83864:	b0000353 	adrp	x19, ec000 <kernel_stacks>
   83868:	91000273 	add	x19, x19, #0x0
   8386c:	f94756f4 	ldr	x20, [x23, #3752]
   83870:	a9025bf5 	stp	x21, x22, [sp, #32]
   83874:	b0000095 	adrp	x21, 94000 <wordsworth.1722+0xde10>
   83878:	91408276 	add	x22, x19, #0x20, lsl #12
    for (int i = 0; i < NR_TASKS; i++) {
        task[i] = (struct task_struct *)(&kernel_stacks[i][0]); 
        BUG_ON((unsigned long)task[i] & ~PAGE_MASK);  // must be page aligned. see above
        memset(task[i], 0, sizeof(struct task_struct)); // zero everything
        initlock(&(task[i]->lock), "task");
   8387c:	910cc2b5 	add	x21, x21, #0x330
        task[i] = (struct task_struct *)(&kernel_stacks[i][0]); 
   83880:	f9000293 	str	x19, [x20]
        memset(task[i], 0, sizeof(struct task_struct)); // zero everything
   83884:	aa1303e0 	mov	x0, x19
   83888:	52802d02 	mov	w2, #0x168                 	// #360
   8388c:	52800001 	mov	w1, #0x0                   	// #0
   83890:	97fff83e 	bl	81988 <memset>
        initlock(&(task[i]->lock), "task");
   83894:	91400673 	add	x19, x19, #0x1, lsl #12
   83898:	f9400280 	ldr	x0, [x20]
   8389c:	aa1503e1 	mov	x1, x21
   838a0:	91046000 	add	x0, x0, #0x118
   838a4:	97fff8cb 	bl	81bd0 <initlock>
        task[i]->state = TASK_UNUSED;
   838a8:	f8408680 	ldr	x0, [x20], #8
    for (int i = 0; i < NR_TASKS; i++) {
   838ac:	eb16027f 	cmp	x19, x22
        task[i]->state = TASK_UNUSED;
   838b0:	b901381f 	str	wzr, [x0, #312]
    for (int i = 0; i < NR_TASKS; i++) {
   838b4:	54fffe61 	b.ne	83880 <sched_init+0x30>  // b.any
    }

    for (int i = 0; i < NCPU; i++) {
        idle_tasks[i] = (struct task_struct *)(&boot_stacks[i][0]); 
        cpus[i].proc = idle_tasks[i]; 
   838b8:	d0000082 	adrp	x2, 95000 <wordsworth.1722+0xee10>
        idle_tasks[i] = (struct task_struct *)(&boot_stacks[i][0]); 
   838bc:	d0000093 	adrp	x19, 95000 <wordsworth.1722+0xee10>
   838c0:	d0000080 	adrp	x0, 95000 <wordsworth.1722+0xee10>
        initlock(&(idle_tasks[i]->lock), "idle"); // some code will try to grab
   838c4:	b0000081 	adrp	x1, 94000 <wordsworth.1722+0xde10>
        cpus[i].proc = idle_tasks[i]; 
   838c8:	f9475c42 	ldr	x2, [x2, #3768]
        initlock(&(idle_tasks[i]->lock), "idle"); // some code will try to grab
   838cc:	910ce021 	add	x1, x1, #0x338
        idle_tasks[i] = (struct task_struct *)(&boot_stacks[i][0]); 
   838d0:	f9474e73 	ldr	x19, [x19, #3736]
   838d4:	f9473400 	ldr	x0, [x0, #3688]
        cpus[i].proc = idle_tasks[i]; 
   838d8:	f9000040 	str	x0, [x2]
        idle_tasks[i] = (struct task_struct *)(&boot_stacks[i][0]); 
   838dc:	f9000260 	str	x0, [x19]
        initlock(&(idle_tasks[i]->lock), "idle"); // some code will try to grab
   838e0:	91046000 	add	x0, x0, #0x118
   838e4:	97fff8bb 	bl	81bd0 <initlock>
        snprintf(idle_tasks[i]->name, 10, "idle-%d", i); 
   838e8:	f9400260 	ldr	x0, [x19]
   838ec:	52800003 	mov	w3, #0x0                   	// #0
   838f0:	d2800141 	mov	x1, #0xa                   	// #10
   838f4:	b0000082 	adrp	x2, 94000 <wordsworth.1722+0xde10>
   838f8:	9103c000 	add	x0, x0, #0xf0
   838fc:	910d0042 	add	x2, x2, #0x340
   83900:	97fff782 	bl	81708 <tfp_snprintf>
        jump off the idle task to "normal" ones, saving cpu_context 
        (inc sp/pc) to idle_tasks[i] */
    }
    
    /* init task, will be picked up once cpu0 calls schedule() for the 1st time */
    init_task = task[0]; 
   83904:	f94756f7 	ldr	x23, [x23, #3752]
   83908:	d0000081 	adrp	x1, 95000 <wordsworth.1722+0xee10>
        idle_tasks[i]->pid = -1; // not meaningful. a placeholder
   8390c:	f9400264 	ldr	x4, [x19]
    init_task->state = TASK_RUNNABLE;
    init_task->cpu_context.x19 = (unsigned long)init; 
   83910:	d0000080 	adrp	x0, 95000 <wordsworth.1722+0xee10>
    init_task = task[0]; 
   83914:	f9474821 	ldr	x1, [x1, #3728]
    init_task->cpu_context.pc = (unsigned long)ret_from_fork; // entry.S
   83918:	d0000082 	adrp	x2, 95000 <wordsworth.1722+0xee10>
    init_task = task[0]; 
   8391c:	f94002e3 	ldr	x3, [x23]
        idle_tasks[i]->pid = -1; // not meaningful. a placeholder
   83920:	12800005 	mov	w5, #0xffffffff            	// #-1
    init_task->cpu_context.x19 = (unsigned long)init; 
   83924:	f9475800 	ldr	x0, [x0, #3760]
    init_task->cpu_context.pc = (unsigned long)ret_from_fork; // entry.S
   83928:	f9476842 	ldr	x2, [x2, #3792]
    init_task->flags = PF_KTHREAD;
    // init_task->mm = 0;  // nothing (kernel task) 
    init_task->chan = 0;
    init_task->pid = 0;
    safestrcpy(init_task->name, "init", 5);
}
   8392c:	a94153f3 	ldp	x19, x20, [sp, #16]
   83930:	a9425bf5 	ldp	x21, x22, [sp, #32]
   83934:	f9401bf7 	ldr	x23, [sp, #48]
    init_task = task[0]; 
   83938:	f9000023 	str	x3, [x1]
        idle_tasks[i]->pid = -1; // not meaningful. a placeholder
   8393c:	b9013485 	str	w5, [x4, #308]
    init_task->cpu_context.sp = (unsigned long)init_task + THREAD_SIZE; 
   83940:	91400461 	add	x1, x3, #0x1, lsl #12
    init_task->priority = 2;
   83944:	d2800044 	mov	x4, #0x2                   	// #2
    init_task->state = TASK_RUNNABLE;
   83948:	52800085 	mov	w5, #0x4                   	// #4
    init_task->cpu_context.x19 = (unsigned long)init; 
   8394c:	f9000060 	str	x0, [x3]
    safestrcpy(init_task->name, "init", 5);
   83950:	9103c060 	add	x0, x3, #0xf0
    init_task->cpu_context.pc = (unsigned long)ret_from_fork; // entry.S
   83954:	a9058861 	stp	x1, x2, [x3, #88]
    safestrcpy(init_task->name, "init", 5);
   83958:	b0000081 	adrp	x1, 94000 <wordsworth.1722+0xde10>
   8395c:	528000a2 	mov	w2, #0x5                   	// #5
    init_task->flags = PF_KTHREAD;
   83960:	f9008464 	str	x4, [x3, #264]
    safestrcpy(init_task->name, "init", 5);
   83964:	910d2021 	add	x1, x1, #0x348
    init_task->pid = 0;
   83968:	b901347f 	str	wzr, [x3, #308]
    init_task->state = TASK_RUNNABLE;
   8396c:	b9013865 	str	w5, [x3, #312]
    init_task->priority = 2;
   83970:	a914107f 	stp	xzr, x4, [x3, #320]
    init_task->chan = 0;
   83974:	f900ac7f 	str	xzr, [x3, #344]
}
   83978:	a8c47bfd 	ldp	x29, x30, [sp], #64
    safestrcpy(init_task->name, "init", 5);
   8397c:	17fff869 	b	81b20 <safestrcpy>

0000000000083980 <leave_scheduler>:
    This function is needed b/c when a task is "switched to" for the first time,
    the task starts to execute from ret_from_fork instead of the instruction
    right after the callsite to cpu_switch_to(), (see comments in switch_to()).
    To balance the irq_disable/enable, ret_from_fork must call leave_scheduler()
    below */
void leave_scheduler(void) {
   83980:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
    release(&sched_lock);
   83984:	d0000080 	adrp	x0, 95000 <wordsworth.1722+0xee10>
   83988:	9138c000 	add	x0, x0, #0xe30
void leave_scheduler(void) {
   8398c:	910003fd 	mov	x29, sp
    release(&sched_lock);
   83990:	97fff8f4 	bl	81d60 <release>
    enable_irq(); // new task must turn on irq. cf timer_tick() comments
}
   83994:	a8c17bfd 	ldp	x29, x30, [sp], #16
    enable_irq(); // new task must turn on irq. cf timer_tick() comments
   83998:	14000954 	b	85ee8 <enable_irq>
   8399c:	d503201f 	nop

00000000000839a0 <switch_to>:
}

/* caller must hold sched_lock, and not holding next->lock
called when preemption is disabled, so the cur task wont lose cpu */
// Q2: quest: "two cooperative printers"
void switch_to(struct task_struct * next) {
   839a0:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   839a4:	910003fd 	mov	x29, sp
   839a8:	f90013f5 	str	x21, [sp, #32]
    p=mycpu()->proc; 
   839ac:	d0000095 	adrp	x21, 95000 <wordsworth.1722+0xee10>
void switch_to(struct task_struct * next) {
   839b0:	a90153f3 	stp	x19, x20, [sp, #16]
   839b4:	aa0003f3 	mov	x19, x0
	push_off(); 
   839b8:	97fff894 	bl	81c08 <push_off>
    p=mycpu()->proc; 
   839bc:	f9475ea0 	ldr	x0, [x21, #3768]
   839c0:	f9400014 	ldr	x20, [x0]
    pop_off(); 
   839c4:	97fff8c7 	bl	81ce0 <pop_off>
	struct task_struct * prev; 
    struct task_struct *cur; 

    cur = myproc(); BUG_ON(!cur); 
   839c8:	b40002d4 	cbz	x20, 83a20 <switch_to+0x80>
	if (cur == next) 
   839cc:	eb14027f 	cmp	x19, x20
   839d0:	54000200 	b.eq	83a10 <switch_to+0x70>  // b.none
		return; 

	prev = cur;
	mycpu()->proc = next;
   839d4:	f9475eb5 	ldr	x21, [x21, #3768]

	if (prev->state == TASK_RUNNING) // preempted 
   839d8:	b9413a80 	ldr	w0, [x20, #312]
	mycpu()->proc = next;
   839dc:	f90002b3 	str	x19, [x21]
	if (prev->state == TASK_RUNNING) // preempted 
   839e0:	7100041f 	cmp	w0, #0x1
   839e4:	54000061 	b.ne	839f0 <switch_to+0x50>  // b.any
		prev->state = TASK_RUNNABLE; 
   839e8:	52800080 	mov	w0, #0x4                   	// #4
   839ec:	b9013a80 	str	w0, [x20, #312]
	next->state = TASK_RUNNING;
   839f0:	52800020 	mov	w0, #0x1                   	// #1

        cpu_switch_to() does not need task::lock, cf "locking protocol" on the top
    */

    /* below: cpu_switch_to() in switch.S. it will branch to next->cpu_context.pc */
    cpu_switch_to(prev, next);   /* STUDENT: TODO: replace this */
   839f4:	aa1303e1 	mov	x1, x19
}
   839f8:	f94013f5 	ldr	x21, [sp, #32]
	next->state = TASK_RUNNING;
   839fc:	b9013a60 	str	w0, [x19, #312]
    cpu_switch_to(prev, next);   /* STUDENT: TODO: replace this */
   83a00:	aa1403e0 	mov	x0, x20
}
   83a04:	a94153f3 	ldp	x19, x20, [sp, #16]
   83a08:	a8c37bfd 	ldp	x29, x30, [sp], #48
    cpu_switch_to(prev, next);   /* STUDENT: TODO: replace this */
   83a0c:	14000921 	b	85e90 <cpu_switch_to>
}
   83a10:	a94153f3 	ldp	x19, x20, [sp, #16]
   83a14:	f94013f5 	ldr	x21, [sp, #32]
   83a18:	a8c37bfd 	ldp	x29, x30, [sp], #48
   83a1c:	d65f03c0 	ret
    cur = myproc(); BUG_ON(!cur); 
   83a20:	b0000081 	adrp	x1, 94000 <wordsworth.1722+0xde10>
   83a24:	b0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   83a28:	910d4021 	add	x1, x1, #0x350
   83a2c:	910d6000 	add	x0, x0, #0x358
   83a30:	528018c2 	mov	w2, #0xc6                  	// #198
   83a34:	97fff7c9 	bl	81958 <assertion_failed>
   83a38:	17ffffe5 	b	839cc <switch_to+0x2c>
   83a3c:	d503201f 	nop

0000000000083a40 <schedule>:
void schedule() {
   83a40:	a9b97bfd 	stp	x29, x30, [sp, #-112]!
   83a44:	910003fd 	mov	x29, sp
   83a48:	a90573fb 	stp	x27, x28, [sp, #80]
    p=mycpu()->proc; 
   83a4c:	d000009c 	adrp	x28, 95000 <wordsworth.1722+0xee10>
void schedule() {
   83a50:	a90153f3 	stp	x19, x20, [sp, #16]
   83a54:	a9025bf5 	stp	x21, x22, [sp, #32]
   83a58:	a90363f7 	stp	x23, x24, [sp, #48]
			p = task[i]; BUG_ON(!p);
   83a5c:	b0000098 	adrp	x24, 94000 <wordsworth.1722+0xde10>
   83a60:	910d4318 	add	x24, x24, #0x350
void schedule() {
   83a64:	a9046bf9 	stp	x25, x26, [sp, #64]
	push_off(); 
   83a68:	97fff868 	bl	81c08 <push_off>
    p=mycpu()->proc; 
   83a6c:	f9475f80 	ldr	x0, [x28, #3768]
   83a70:	f9400015 	ldr	x21, [x0]
    pop_off(); 
   83a74:	97fff89b 	bl	81ce0 <pop_off>
    acquire(&sched_lock); 
   83a78:	d0000080 	adrp	x0, 95000 <wordsworth.1722+0xee10>
   83a7c:	9138c000 	add	x0, x0, #0xe30
   83a80:	97fff876 	bl	81c58 <acquire>
    cpu = cpuid();  // holding sched_lock, the cur process wont mirgrate across cpus
   83a84:	94000921 	bl	85f08 <cpuid>
   83a88:	2a0003f6 	mov	w22, w0
			p = task[i]; BUG_ON(!p);
   83a8c:	b0000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   83a90:	910d8000 	add	x0, x0, #0x360
   83a94:	f90037e0 	str	x0, [sp, #104]
   83a98:	d0000080 	adrp	x0, 95000 <wordsworth.1722+0xee10>
void schedule() {
   83a9c:	d2800013 	mov	x19, #0x0                   	// #0
        has_runnable = 0; 
   83aa0:	52800006 	mov	w6, #0x0                   	// #0
		max_cr = -1; 
   83aa4:	12800019 	mov	w25, #0xffffffff            	// #-1
			p = task[i]; BUG_ON(!p);
   83aa8:	f947541b 	ldr	x27, [x0, #3752]
		next = 0;
   83aac:	52800017 	mov	w23, #0x0                   	// #0
   83ab0:	14000004 	b	83ac0 <schedule+0x80>
		for (int i = 0; i < NR_TASKS; i++){
   83ab4:	91000673 	add	x19, x19, #0x1
   83ab8:	f100827f 	cmp	x19, #0x20
   83abc:	540002e0 	b.eq	83b18 <schedule+0xd8>  // b.none
			p = task[i]; BUG_ON(!p);
   83ac0:	f8737b74 	ldr	x20, [x27, x19, lsl #3]
        if (cpus[i].proc == p)
   83ac4:	2a1303fa 	mov	w26, w19
			p = task[i]; BUG_ON(!p);
   83ac8:	b40006b4 	cbz	x20, 83b9c <schedule+0x15c>
        if (cpus[i].proc == p)
   83acc:	f9475f80 	ldr	x0, [x28, #3768]
   83ad0:	f9400000 	ldr	x0, [x0]
   83ad4:	eb00029f 	cmp	x20, x0
   83ad8:	54000041 	b.ne	83ae0 <schedule+0xa0>  // b.any
            if (oncpu != -1 && oncpu != cpu) 
   83adc:	35fffed6 	cbnz	w22, 83ab4 <schedule+0x74>
				if (p->credits > max_cr) { max_cr = p->credits; next = i; }
   83ae0:	b9413a80 	ldr	w0, [x20, #312]
   83ae4:	93407f21 	sxtw	x1, w25
			if ((p == cur && p->state == TASK_RUNNING)
   83ae8:	eb15029f 	cmp	x20, x21
   83aec:	54000480 	b.eq	83b7c <schedule+0x13c>  // b.none
                || p->state == TASK_RUNNABLE) {
   83af0:	7100101f 	cmp	w0, #0x4
   83af4:	54fffe01 	b.ne	83ab4 <schedule+0x74>  // b.any
				if (p->credits > max_cr) { max_cr = p->credits; next = i; }
   83af8:	f940a280 	ldr	x0, [x20, #320]
   83afc:	52800026 	mov	w6, #0x1                   	// #1
   83b00:	eb01001f 	cmp	x0, x1
   83b04:	1a80d339 	csel	w25, w25, w0, le
   83b08:	1a9ad2f7 	csel	w23, w23, w26, le
		for (int i = 0; i < NR_TASKS; i++){
   83b0c:	91000673 	add	x19, x19, #0x1
   83b10:	f100827f 	cmp	x19, #0x20
   83b14:	54fffd61 	b.ne	83ac0 <schedule+0x80>  // b.any
		if (max_cr > 0) {
   83b18:	7100033f 	cmp	w25, #0x0
            switch_to(task[next]);  /* STUDENT: TODO: replace this */
   83b1c:	d0000080 	adrp	x0, 95000 <wordsworth.1722+0xee10>
		if (max_cr > 0) {
   83b20:	5400056c 	b.gt	83bcc <schedule+0x18c>
        if (has_runnable) { 
   83b24:	340006c6 	cbz	w6, 83bfc <schedule+0x1bc>
                p = task[i]; BUG_ON(!p);
   83b28:	f9475414 	ldr	x20, [x0, #3752]
   83b2c:	91040299 	add	x25, x20, #0x100
   83b30:	91002294 	add	x20, x20, #0x8
   83b34:	f85f8293 	ldur	x19, [x20, #-8]
   83b38:	b4000193 	cbz	x19, 83b68 <schedule+0x128>
   83b3c:	d503201f 	nop
                if (p->state != TASK_UNUSED) {
   83b40:	b9413a60 	ldr	w0, [x19, #312]
            for (int i = 0; i < NR_TASKS; i++) {
   83b44:	eb14033f 	cmp	x25, x20
                if (p->state != TASK_UNUSED) {
   83b48:	34000080 	cbz	w0, 83b58 <schedule+0x118>
                    p->credits = (p->credits >> 1) + p->priority;  // per priority
   83b4c:	a9540660 	ldp	x0, x1, [x19, #320]
   83b50:	8b800420 	add	x0, x1, x0, asr #1
   83b54:	f900a260 	str	x0, [x19, #320]
            for (int i = 0; i < NR_TASKS; i++) {
   83b58:	54fffa00 	b.eq	83a98 <schedule+0x58>  // b.none
                p = task[i]; BUG_ON(!p);
   83b5c:	f9400293 	ldr	x19, [x20]
   83b60:	91002294 	add	x20, x20, #0x8
   83b64:	b5fffef3 	cbnz	x19, 83b40 <schedule+0x100>
   83b68:	f94037e0 	ldr	x0, [sp, #104]
   83b6c:	aa1803e1 	mov	x1, x24
   83b70:	528012a2 	mov	w2, #0x95                  	// #149
   83b74:	97fff779 	bl	81958 <assertion_failed>
   83b78:	17fffff2 	b	83b40 <schedule+0x100>
			if ((p == cur && p->state == TASK_RUNNING)
   83b7c:	7100041f 	cmp	w0, #0x1
   83b80:	54fffb81 	b.ne	83af0 <schedule+0xb0>  // b.any
				if (p->credits > max_cr) { max_cr = p->credits; next = i; }
   83b84:	f940a280 	ldr	x0, [x20, #320]
   83b88:	52800026 	mov	w6, #0x1                   	// #1
   83b8c:	eb01001f 	cmp	x0, x1
   83b90:	1a80d339 	csel	w25, w25, w0, le
   83b94:	1a9ad2f7 	csel	w23, w23, w26, le
   83b98:	17ffffdd 	b	83b0c <schedule+0xcc>
			p = task[i]; BUG_ON(!p);
   83b9c:	f94037e0 	ldr	x0, [sp, #104]
   83ba0:	aa1803e1 	mov	x1, x24
   83ba4:	52800fa2 	mov	w2, #0x7d                  	// #125
   83ba8:	b90067e6 	str	w6, [sp, #100]
   83bac:	97fff76b 	bl	81958 <assertion_failed>
    if (!p) {BUG(); return -1;}
   83bb0:	aa1803e1 	mov	x1, x24
   83bb4:	52800b62 	mov	w2, #0x5b                  	// #91
   83bb8:	f0000000 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   83bbc:	910d8000 	add	x0, x0, #0x360
   83bc0:	97fff766 	bl	81958 <assertion_failed>
   83bc4:	b94067e6 	ldr	w6, [sp, #100]
   83bc8:	17ffffc6 	b	83ae0 <schedule+0xa0>
            switch_to(task[next]);  /* STUDENT: TODO: replace this */
   83bcc:	f9475416 	ldr	x22, [x0, #3752]
   83bd0:	f877dac0 	ldr	x0, [x22, w23, sxtw #3]
   83bd4:	97ffff73 	bl	839a0 <switch_to>
}
   83bd8:	a94153f3 	ldp	x19, x20, [sp, #16]
    release(&sched_lock);
   83bdc:	d0000080 	adrp	x0, 95000 <wordsworth.1722+0xee10>
}
   83be0:	a9425bf5 	ldp	x21, x22, [sp, #32]
    release(&sched_lock);
   83be4:	9138c000 	add	x0, x0, #0xe30
}
   83be8:	a94363f7 	ldp	x23, x24, [sp, #48]
   83bec:	a9446bf9 	ldp	x25, x26, [sp, #64]
   83bf0:	a94573fb 	ldp	x27, x28, [sp, #80]
   83bf4:	a8c77bfd 	ldp	x29, x30, [sp], #112
    release(&sched_lock);
   83bf8:	17fff85a 	b	81d60 <release>
            switch_to(task[0]);   /* STUDENT: TODO: replace this */
   83bfc:	f9475416 	ldr	x22, [x0, #3752]
   83c00:	f94002c0 	ldr	x0, [x22]
   83c04:	97ffff67 	bl	839a0 <switch_to>
            break;
   83c08:	17fffff4 	b	83bd8 <schedule+0x198>
   83c0c:	d503201f 	nop

0000000000083c10 <yield>:
void yield(void) {    
   83c10:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   83c14:	910003fd 	mov	x29, sp
   83c18:	a90153f3 	stp	x19, x20, [sp, #16]
	push_off(); 
   83c1c:	97fff7fb 	bl	81c08 <push_off>
    p=mycpu()->proc; 
   83c20:	d0000080 	adrp	x0, 95000 <wordsworth.1722+0xee10>
    acquire(&sched_lock); p->credits = 0; release(&sched_lock);
   83c24:	d0000093 	adrp	x19, 95000 <wordsworth.1722+0xee10>
   83c28:	9138c273 	add	x19, x19, #0xe30
    p=mycpu()->proc; 
   83c2c:	f9475c00 	ldr	x0, [x0, #3768]
   83c30:	f9400014 	ldr	x20, [x0]
    pop_off(); 
   83c34:	97fff82b 	bl	81ce0 <pop_off>
    acquire(&sched_lock); p->credits = 0; release(&sched_lock);
   83c38:	aa1303e0 	mov	x0, x19
   83c3c:	97fff807 	bl	81c58 <acquire>
   83c40:	aa1303e0 	mov	x0, x19
   83c44:	f900a29f 	str	xzr, [x20, #320]
   83c48:	97fff846 	bl	81d60 <release>
}
   83c4c:	a94153f3 	ldp	x19, x20, [sp, #16]
   83c50:	a8c27bfd 	ldp	x29, x30, [sp], #32
    schedule();
   83c54:	17ffff7b 	b	83a40 <schedule>

0000000000083c58 <timer_tick>:
#define CPU_UTIL_INTERVAL 10  // cal cpu measurement every X ticks

/* Called by handle_generic_timer_irq(), i.e. timer irq handler, with irq 
    automatically turned off by hardware. irq status can be checked by 
    is_irq_masked() */
void timer_tick() {
   83c58:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   83c5c:	910003fd 	mov	x29, sp
   83c60:	a90153f3 	stp	x19, x20, [sp, #16]
    p=mycpu()->proc; 
   83c64:	d0000093 	adrp	x19, 95000 <wordsworth.1722+0xee10>
void timer_tick() {
   83c68:	f90013f5 	str	x21, [sp, #32]
	push_off(); 
   83c6c:	97fff7e7 	bl	81c08 <push_off>
    p=mycpu()->proc; 
   83c70:	f9475e75 	ldr	x21, [x19, #3768]
   83c74:	f94002b4 	ldr	x20, [x21]
    pop_off(); 
   83c78:	97fff81a 	bl	81ce0 <pop_off>
    struct task_struct *cur = myproc();
    struct cpu* cp = mycpu(); 

    if (cur) { // update task::credits, decide if schedule() is needed
   83c7c:	b4000494 	cbz	x20, 83d0c <timer_tick+0xb4>
        V("enter timer_tick cpu%d task %s pid %d", cpuid(), cur->name, cur->pid);
        if (cur->pid>=0 && cur->state == TASK_RUNNING) // not "idle" (pid -1), and running
   83c80:	b9413680 	ldr	w0, [x20, #308]
   83c84:	37f80080 	tbnz	w0, #31, 83c94 <timer_tick+0x3c>
   83c88:	b9413a80 	ldr	w0, [x20, #312]
   83c8c:	7100041f 	cmp	w0, #0x1
   83c90:	54000460 	b.eq	83d1c <timer_tick+0xc4>  // b.none
            cp->busy++; 

        // calculate cpu util %     Qx: quest: hide this until later lab
        if ((cp->total++ % CPU_UTIL_INTERVAL) == CPU_UTIL_INTERVAL - 1) {
   83c94:	f9475e61 	ldr	x1, [x19, #3768]
   83c98:	b202e7e0 	mov	x0, #0xcccccccccccccccc    	// #-3689348814741910324
   83c9c:	f29999a0 	movk	x0, #0xcccd
   83ca0:	f9400c22 	ldr	x2, [x1, #24]
   83ca4:	91000443 	add	x3, x2, #0x1
   83ca8:	f9000c23 	str	x3, [x1, #24]
   83cac:	9bc07c40 	umulh	x0, x2, x0
   83cb0:	d343fc00 	lsr	x0, x0, #3
   83cb4:	8b000800 	add	x0, x0, x0, lsl #2
   83cb8:	cb000440 	sub	x0, x2, x0, lsl #1
   83cbc:	f100241f 	cmp	x0, #0x9
   83cc0:	540000a1 	b.ne	83cd4 <timer_tick+0x7c>  // b.any
            cp->last_util = cp->busy * 100 / CPU_UTIL_INTERVAL; 
   83cc4:	b9401020 	ldr	w0, [x1, #16]
   83cc8:	0b000800 	add	w0, w0, w0, lsl #2
   83ccc:	531f7800 	lsl	w0, w0, #1
   83cd0:	2902003f 	stp	wzr, w0, [x1, #16]
            if (cpuid()==0)
                procdump();
            #endif
        }

        acquire(&sched_lock); 
   83cd4:	d0000093 	adrp	x19, 95000 <wordsworth.1722+0xee10>
   83cd8:	9138c275 	add	x21, x19, #0xe30
   83cdc:	aa1503e0 	mov	x0, x21
   83ce0:	97fff7de 	bl	81c58 <acquire>
        if (cur->pid>=0 && --cur->credits > 0) { 
   83ce4:	b9413680 	ldr	w0, [x20, #308]
   83ce8:	37f800c0 	tbnz	w0, #31, 83d00 <timer_tick+0xa8>
   83cec:	f940a281 	ldr	x1, [x20, #320]
   83cf0:	d1000421 	sub	x1, x1, #0x1
   83cf4:	f900a281 	str	x1, [x20, #320]
   83cf8:	f100003f 	cmp	x1, #0x0
   83cfc:	5400018c 	b.gt	83d2c <timer_tick+0xd4>
            // let "cur" task to continue execution 
            V("leave timer_tick. no resche");
            release(&sched_lock); return;
        }
        cur->credits=0;
   83d00:	f900a29f 	str	xzr, [x20, #320]
        release(&sched_lock);
   83d04:	9138c260 	add	x0, x19, #0xe30
   83d08:	97fff816 	bl	81d60 <release>

    V("leave timer_tick cpu%d task %s pid %d", cpuid(), cur->name, cur->pid);
	
    /* irq disabled until kernel_exit, in which eret will restore the 
       DAIF.I flag from spsr, which sets irq on. */
}
   83d0c:	a94153f3 	ldp	x19, x20, [sp, #16]
   83d10:	f94013f5 	ldr	x21, [sp, #32]
   83d14:	a8c37bfd 	ldp	x29, x30, [sp], #48
	schedule();
   83d18:	17ffff4a 	b	83a40 <schedule>
            cp->busy++; 
   83d1c:	b94012a0 	ldr	w0, [x21, #16]
   83d20:	11000400 	add	w0, w0, #0x1
   83d24:	b90012a0 	str	w0, [x21, #16]
   83d28:	17ffffdb 	b	83c94 <timer_tick+0x3c>
            release(&sched_lock); return;
   83d2c:	aa1503e0 	mov	x0, x21
}
   83d30:	a94153f3 	ldp	x19, x20, [sp, #16]
   83d34:	f94013f5 	ldr	x21, [sp, #32]
   83d38:	a8c37bfd 	ldp	x29, x30, [sp], #48
            release(&sched_lock); return;
   83d3c:	17fff809 	b	81d60 <release>

0000000000083d40 <wakeup>:

/* Must be called WITHOUT sched_lock 
Called from irq (many drivers) or task
return # of tasks woken up */
// Q9: quest: "wordsmith"
int wakeup(void *chan) {
   83d40:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   83d44:	910003fd 	mov	x29, sp
   83d48:	f9000bf3 	str	x19, [sp, #16]
    int cnt; 
    acquire(&sched_lock);     
   83d4c:	d0000093 	adrp	x19, 95000 <wordsworth.1722+0xee10>
   83d50:	9138c273 	add	x19, x19, #0xe30
   83d54:	aa1303e0 	mov	x0, x19
   83d58:	97fff7c0 	bl	81c58 <acquire>
    cnt = wakeup_nolock(chan); 
    release(&sched_lock);
   83d5c:	aa1303e0 	mov	x0, x19
   83d60:	97fff800 	bl	81d60 <release>
    return cnt; 
}
   83d64:	52800000 	mov	w0, #0x0                   	// #0
   83d68:	f9400bf3 	ldr	x19, [sp, #16]
   83d6c:	a8c27bfd 	ldp	x29, x30, [sp], #32
   83d70:	d65f03c0 	ret
   83d74:	d503201f 	nop

0000000000083d78 <sleep>:

/* Atomically release "lk" and sleep on chan.
Reacquires lk when awakened.
Called by tasks with @lk held */
// Q9: quest: "wordsmith"
void sleep(void *chan, struct spinlock *lk) {
   83d78:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   83d7c:	910003fd 	mov	x29, sp
   83d80:	a9025bf5 	stp	x21, x22, [sp, #32]
    p=mycpu()->proc; 
   83d84:	d0000095 	adrp	x21, 95000 <wordsworth.1722+0xee10>
void sleep(void *chan, struct spinlock *lk) {
   83d88:	a90153f3 	stp	x19, x20, [sp, #16]
   83d8c:	aa0103f3 	mov	x19, x1
	push_off(); 
   83d90:	97fff79e 	bl	81c08 <push_off>
    p=mycpu()->proc; 
   83d94:	f9475eb5 	ldr	x21, [x21, #3768]
     * 
     * Corner case: lk==sched_lock, which is already held by cur task. the right
     * behavior of sleep(): keep sched_lock and switch to idle task, which later
     * will release the lock
     */
    if (lk != &sched_lock) {
   83d98:	d0000094 	adrp	x20, 95000 <wordsworth.1722+0xee10>
   83d9c:	9138c294 	add	x20, x20, #0xe30
    p=mycpu()->proc; 
   83da0:	f94002b6 	ldr	x22, [x21]
    pop_off(); 
   83da4:	97fff7cf 	bl	81ce0 <pop_off>
    if (lk != &sched_lock) {
   83da8:	eb14027f 	cmp	x19, x20
   83dac:	54000280 	b.eq	83dfc <sleep+0x84>  // b.none
        acquire(&sched_lock);
   83db0:	aa1403e0 	mov	x0, x20
   83db4:	97fff7a9 	bl	81c58 <acquire>
        release(lk);
   83db8:	aa1303e0 	mov	x0, x19
   83dbc:	97fff7e9 	bl	81d60 <release>
    /* Go to sleep. */
    /* STUDENT: TODO: your code here */

    /* although the task has not used up the current tick, bill it regardless.
    thus this task will be disadvantaged in future scheduling  */
    p->credits --; 
   83dc0:	f940a2c2 	ldr	x2, [x22, #320]
    /* switch the cpu away from the current kern stack to the idle task, which we
    know exists for sure. the idle task will return from the schedule() and 
    rls sched_lock. the next timertick will call schedule() and switch 
    to a normal task (if any)  */
    struct task_struct *idle = 0;
    mycpu()->proc = idle;
   83dc4:	f90002bf 	str	xzr, [x21]
    cpu_switch_to(p, idle);  
   83dc8:	aa1603e0 	mov	x0, x22
   83dcc:	d2800001 	mov	x1, #0x0                   	// #0
    p->credits --; 
   83dd0:	d1000442 	sub	x2, x2, #0x1
   83dd4:	f900a2c2 	str	x2, [x22, #320]
    cpu_switch_to(p, idle);  
   83dd8:	9400082e 	bl	85e90 <cpu_switch_to>
    
    /* cpu_switch_to() back here when the cur task is woken up. 
    it now has sched_lock.  */

    /* Tidy up. */
    p->chan = 0;
   83ddc:	f900aedf 	str	xzr, [x22, #344]

    if (lk != &sched_lock) {
        release(&sched_lock); 
   83de0:	aa1403e0 	mov	x0, x20
   83de4:	97fff7df 	bl	81d60 <release>
        acquire(lk); 
   83de8:	aa1303e0 	mov	x0, x19
        - T1 tries to reacquire lk (before releasing sched_lock)
        - T2 has lk, but cannot run b/c T1 has sched_lock -- deadlock         
            cf unittests.c do_write()
        */
    } /* else keep holding sched_lock */
}
   83dec:	a94153f3 	ldp	x19, x20, [sp, #16]
   83df0:	a9425bf5 	ldp	x21, x22, [sp, #32]
   83df4:	a8c37bfd 	ldp	x29, x30, [sp], #48
        acquire(lk); 
   83df8:	17fff798 	b	81c58 <acquire>
    p->credits --; 
   83dfc:	f940a2c2 	ldr	x2, [x22, #320]
    mycpu()->proc = idle;
   83e00:	f90002bf 	str	xzr, [x21]
    cpu_switch_to(p, idle);  
   83e04:	aa1603e0 	mov	x0, x22
   83e08:	d2800001 	mov	x1, #0x0                   	// #0
    p->credits --; 
   83e0c:	d1000442 	sub	x2, x2, #0x1
   83e10:	f900a2c2 	str	x2, [x22, #320]
    cpu_switch_to(p, idle);  
   83e14:	9400081f 	bl	85e90 <cpu_switch_to>
}
   83e18:	a94153f3 	ldp	x19, x20, [sp, #16]
    p->chan = 0;
   83e1c:	f900aedf 	str	xzr, [x22, #344]
}
   83e20:	a9425bf5 	ldp	x21, x22, [sp, #32]
   83e24:	a8c37bfd 	ldp	x29, x30, [sp], #48
   83e28:	d65f03c0 	ret
   83e2c:	d503201f 	nop

0000000000083e30 <wait>:

/* Wait for a child process to exit and return its pid.
    Return -1 if this process has no children. 
    addr=0 a special case, dont care about status
    --- "addr" ignored for lab2 */
int wait(uint64 addr /*dst user va to copy status to */) {
   83e30:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
   83e34:	910003fd 	mov	x29, sp
   83e38:	a90153f3 	stp	x19, x20, [sp, #16]
   83e3c:	a9025bf5 	stp	x21, x22, [sp, #32]

    for (;;) {
        // Scan through table looking for exited children.  pp:child
        havekids = 0;
        for (pp = task; pp < &task[NR_TASKS]; pp++) {
            struct task_struct *p0 = *pp; BUG_ON(!p0); 
   83e40:	b0000096 	adrp	x22, 94000 <wordsworth.1722+0xde10>
   83e44:	d0000095 	adrp	x21, 95000 <wordsworth.1722+0xee10>
int wait(uint64 addr /*dst user va to copy status to */) {
   83e48:	a90363f7 	stp	x23, x24, [sp, #48]
            struct task_struct *p0 = *pp; BUG_ON(!p0); 
   83e4c:	910da2d6 	add	x22, x22, #0x368
    acquire(&sched_lock); 
   83e50:	d0000098 	adrp	x24, 95000 <wordsworth.1722+0xee10>
int wait(uint64 addr /*dst user va to copy status to */) {
   83e54:	a9046bf9 	stp	x25, x26, [sp, #64]
	push_off(); 
   83e58:	97fff76c 	bl	81c08 <push_off>
    p=mycpu()->proc; 
   83e5c:	d0000080 	adrp	x0, 95000 <wordsworth.1722+0xee10>
            struct task_struct *p0 = *pp; BUG_ON(!p0); 
   83e60:	b0000097 	adrp	x23, 94000 <wordsworth.1722+0xde10>
   83e64:	910d42f7 	add	x23, x23, #0x350
    p=mycpu()->proc; 
   83e68:	f9475c00 	ldr	x0, [x0, #3768]
   83e6c:	f9400019 	ldr	x25, [x0]
    pop_off(); 
   83e70:	97fff79c 	bl	81ce0 <pop_off>
    acquire(&sched_lock); 
   83e74:	9138c300 	add	x0, x24, #0xe30
   83e78:	97fff778 	bl	81c58 <acquire>
        for (pp = task; pp < &task[NR_TASKS]; pp++) {
   83e7c:	f94756b3 	ldr	x19, [x21, #3752]
        havekids = 0;
   83e80:	5280001a 	mov	w26, #0x0                   	// #0
   83e84:	14000005 	b	83e98 <wait+0x68>
        for (pp = task; pp < &task[NR_TASKS]; pp++) {
   83e88:	f94756a0 	ldr	x0, [x21, #3752]
   83e8c:	91040000 	add	x0, x0, #0x100
   83e90:	eb00027f 	cmp	x19, x0
   83e94:	54000420 	b.eq	83f18 <wait+0xe8>  // b.none
            struct task_struct *p0 = *pp; BUG_ON(!p0); 
   83e98:	f9400274 	ldr	x20, [x19]
        for (pp = task; pp < &task[NR_TASKS]; pp++) {
   83e9c:	91002273 	add	x19, x19, #0x8
            struct task_struct *p0 = *pp; BUG_ON(!p0); 
   83ea0:	b4000334 	cbz	x20, 83f04 <wait+0xd4>
            if (p0->state == TASK_UNUSED) continue; 
   83ea4:	b9413a80 	ldr	w0, [x20, #312]
   83ea8:	34ffff00 	cbz	w0, 83e88 <wait+0x58>
            if (p0->parent == p) {
   83eac:	f940b281 	ldr	x1, [x20, #352]
   83eb0:	eb19003f 	cmp	x1, x25
   83eb4:	54fffea1 	b.ne	83e88 <wait+0x58>  // b.any
                havekids = 1;
                if (p0->state == TASK_ZOMBIE) {
   83eb8:	71000c1f 	cmp	w0, #0x3
                havekids = 1;
   83ebc:	5280003a 	mov	w26, #0x1                   	// #1
                if (p0->state == TASK_ZOMBIE) {
   83ec0:	54fffe41 	b.ne	83e88 <wait+0x58>  // b.any
                    // Found one.
                    pid = p0->pid;
   83ec4:	b9413693 	ldr	w19, [x20, #308]
                    I("found zombie pid=%d", pid); 
                    freeproc(p0);       // will mark the task slot as unused                    
                    release(&sched_lock); 
   83ec8:	9138c300 	add	x0, x24, #0xe30
    BUG_ON(!p); V("%s entered. pid %d", __func__, p->pid);

    p->state = TASK_UNUSED; // mark the slot as unused
    // o need to zero task_struct, which is among the task's kernel page
    // FIX: since we cannot recycle task slot now, so we dont dec nr_tasks ...
    p->flags = 0; 
   83ecc:	f900869f 	str	xzr, [x20, #264]
    p->killed = 0; 
   83ed0:	f9009a9f 	str	xzr, [x20, #304]
    p->state = TASK_UNUSED; // mark the slot as unused
   83ed4:	b9013a9f 	str	wzr, [x20, #312]
    p->credits = 0; 
   83ed8:	f900a29f 	str	xzr, [x20, #320]
    p->chan = 0; 
    p->pid = 0; 
    p->xstate = 0; 
   83edc:	b901529f 	str	wzr, [x20, #336]
    p->chan = 0; 
   83ee0:	f900ae9f 	str	xzr, [x20, #344]
                    release(&sched_lock); 
   83ee4:	97fff79f 	bl	81d60 <release>
}
   83ee8:	2a1303e0 	mov	w0, w19
   83eec:	a94153f3 	ldp	x19, x20, [sp, #16]
   83ef0:	a9425bf5 	ldp	x21, x22, [sp, #32]
   83ef4:	a94363f7 	ldp	x23, x24, [sp, #48]
   83ef8:	a9446bf9 	ldp	x25, x26, [sp, #64]
   83efc:	a8c57bfd 	ldp	x29, x30, [sp], #80
   83f00:	d65f03c0 	ret
            struct task_struct *p0 = *pp; BUG_ON(!p0); 
   83f04:	aa1703e1 	mov	x1, x23
   83f08:	aa1603e0 	mov	x0, x22
   83f0c:	528037a2 	mov	w2, #0x1bd                 	// #445
   83f10:	97fff692 	bl	81958 <assertion_failed>
   83f14:	17ffffe4 	b	83ea4 <wait+0x74>
        if (!havekids) {
   83f18:	340000ba 	cbz	w26, 83f2c <wait+0xfc>
        sleep(p, &sched_lock); // sleep on own task_struct
   83f1c:	9138c301 	add	x1, x24, #0xe30
   83f20:	aa1903e0 	mov	x0, x25
   83f24:	97ffff95 	bl	83d78 <sleep>
        havekids = 0;
   83f28:	17ffffd5 	b	83e7c <wait+0x4c>
            release(&sched_lock);
   83f2c:	9138c300 	add	x0, x24, #0xe30
            return -1;
   83f30:	12800013 	mov	w19, #0xffffffff            	// #-1
            release(&sched_lock);
   83f34:	97fff78b 	bl	81d60 <release>
}
   83f38:	2a1303e0 	mov	w0, w19
   83f3c:	a94153f3 	ldp	x19, x20, [sp, #16]
   83f40:	a9425bf5 	ldp	x21, x22, [sp, #32]
   83f44:	a94363f7 	ldp	x23, x24, [sp, #48]
   83f48:	a9446bf9 	ldp	x25, x26, [sp, #64]
   83f4c:	a8c57bfd 	ldp	x29, x30, [sp], #80
   83f50:	d65f03c0 	ret
   83f54:	d503201f 	nop

0000000000083f58 <exit_process>:
void exit_process(int status) {
   83f58:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
   83f5c:	910003fd 	mov	x29, sp
   83f60:	a9025bf5 	stp	x21, x22, [sp, #32]
    p=mycpu()->proc; 
   83f64:	d0000095 	adrp	x21, 95000 <wordsworth.1722+0xee10>
void exit_process(int status) {
   83f68:	2a0003f6 	mov	w22, w0
   83f6c:	a90153f3 	stp	x19, x20, [sp, #16]
   83f70:	a90363f7 	stp	x23, x24, [sp, #48]
   83f74:	a9046bf9 	stp	x25, x26, [sp, #64]
	push_off(); 
   83f78:	97fff724 	bl	81c08 <push_off>
    if (p == init_task)
   83f7c:	d0000099 	adrp	x25, 95000 <wordsworth.1722+0xee10>
    p=mycpu()->proc; 
   83f80:	f9475ea0 	ldr	x0, [x21, #3768]
   83f84:	f9400014 	ldr	x20, [x0]
    pop_off(); 
   83f88:	97fff756 	bl	81ce0 <pop_off>
    if (p == init_task)
   83f8c:	f9474b20 	ldr	x0, [x25, #3728]
   83f90:	f9400000 	ldr	x0, [x0]
   83f94:	eb14001f 	cmp	x0, x20
   83f98:	540006a0 	b.eq	8406c <exit_process+0x114>  // b.none
    for (child = task; child < &task[NR_TASKS]; child++) {
   83f9c:	d0000093 	adrp	x19, 95000 <wordsworth.1722+0xee10>
    acquire(&sched_lock); 
   83fa0:	d0000080 	adrp	x0, 95000 <wordsworth.1722+0xee10>
   83fa4:	9138c000 	add	x0, x0, #0xe30
   83fa8:	97fff72c 	bl	81c58 <acquire>
    for (child = task; child < &task[NR_TASKS]; child++) {
   83fac:	f9475673 	ldr	x19, [x19, #3752]
        BUG_ON(!(*child));
   83fb0:	b0000098 	adrp	x24, 94000 <wordsworth.1722+0xde10>
   83fb4:	b0000097 	adrp	x23, 94000 <wordsworth.1722+0xde10>
   83fb8:	910d4318 	add	x24, x24, #0x350
   83fbc:	910e02f7 	add	x23, x23, #0x380
    for (child = task; child < &task[NR_TASKS]; child++) {
   83fc0:	9104027a 	add	x26, x19, #0x100
   83fc4:	14000003 	b	83fd0 <exit_process+0x78>
   83fc8:	eb1a027f 	cmp	x19, x26
   83fcc:	540001c0 	b.eq	84004 <exit_process+0xac>  // b.none
        BUG_ON(!(*child));
   83fd0:	f9400262 	ldr	x2, [x19]
   83fd4:	b4000402 	cbz	x2, 84054 <exit_process+0xfc>
        if ((*child)->state == TASK_UNUSED) continue;
   83fd8:	b9413840 	ldr	w0, [x2, #312]
    for (child = task; child < &task[NR_TASKS]; child++) {
   83fdc:	91002273 	add	x19, x19, #0x8
        if ((*child)->state == TASK_UNUSED) continue;
   83fe0:	34ffff40 	cbz	w0, 83fc8 <exit_process+0x70>
        if ((*child)->parent == p) {
   83fe4:	f940b040 	ldr	x0, [x2, #352]
   83fe8:	eb00029f 	cmp	x20, x0
   83fec:	54fffee1 	b.ne	83fc8 <exit_process+0x70>  // b.any
            (*child)->parent = init_task;
   83ff0:	f9474b20 	ldr	x0, [x25, #3728]
    for (child = task; child < &task[NR_TASKS]; child++) {
   83ff4:	eb1a027f 	cmp	x19, x26
            (*child)->parent = init_task;
   83ff8:	f9400000 	ldr	x0, [x0]
   83ffc:	f900b040 	str	x0, [x2, #352]
    for (child = task; child < &task[NR_TASKS]; child++) {
   84000:	54fffe81 	b.ne	83fd0 <exit_process+0x78>  // b.any
    p->state = TASK_ZOMBIE;
   84004:	52800060 	mov	w0, #0x3                   	// #3
   84008:	b9013a80 	str	w0, [x20, #312]
    p->xstate = status;
   8400c:	b9015296 	str	w22, [x20, #336]
    struct task_struct *idle = idle_tasks[cpuid()];
   84010:	940007be 	bl	85f08 <cpuid>
   84014:	2a0003e2 	mov	w2, w0
   84018:	b0000081 	adrp	x1, 95000 <wordsworth.1722+0xee10>
    cpu_switch_to(p, idle);
   8401c:	aa1403e0 	mov	x0, x20
    mycpu()->proc = idle;
   84020:	f9475eb5 	ldr	x21, [x21, #3768]
    struct task_struct *idle = idle_tasks[cpuid()];
   84024:	f9474c21 	ldr	x1, [x1, #3736]
   84028:	f862d821 	ldr	x1, [x1, w2, sxtw #3]
    mycpu()->proc = idle;
   8402c:	f90002a1 	str	x1, [x21]
    cpu_switch_to(p, idle);
   84030:	94000798 	bl	85e90 <cpu_switch_to>
}
   84034:	a94153f3 	ldp	x19, x20, [sp, #16]
    panic("zombie exit");
   84038:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
}
   8403c:	a9425bf5 	ldp	x21, x22, [sp, #32]
    panic("zombie exit");
   84040:	910e4000 	add	x0, x0, #0x390
}
   84044:	a94363f7 	ldp	x23, x24, [sp, #48]
   84048:	a9446bf9 	ldp	x25, x26, [sp, #64]
   8404c:	a8c57bfd 	ldp	x29, x30, [sp], #80
    panic("zombie exit");
   84050:	17fff5f8 	b	81830 <panic>
        BUG_ON(!(*child));
   84054:	528033a2 	mov	w2, #0x19d                 	// #413
   84058:	aa1803e1 	mov	x1, x24
   8405c:	aa1703e0 	mov	x0, x23
   84060:	97fff63e 	bl	81958 <assertion_failed>
   84064:	f9400262 	ldr	x2, [x19]
   84068:	17ffffdc 	b	83fd8 <exit_process+0x80>
        panic("init exiting");
   8406c:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   84070:	910dc000 	add	x0, x0, #0x370
   84074:	97fff5ef 	bl	81830 <panic>
   84078:	17ffffc9 	b	83f9c <exit_process+0x44>
   8407c:	d503201f 	nop

0000000000084080 <procdump>:
}

/* Print a process listing to console.  For debugging.
Runs when user types ^P on console.
No lock to avoid wedging a stuck machine further. */
void procdump(void) {
   84080:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
    struct task_struct *p;
    char *state;

    printf("\t %5s %10s %10s %20s\n", "pid", "state", "name", "sleep-on");
   84084:	90000084 	adrp	x4, 94000 <wordsworth.1722+0xde10>
   84088:	90000083 	adrp	x3, 94000 <wordsworth.1722+0xde10>
void procdump(void) {
   8408c:	910003fd 	mov	x29, sp
   84090:	a90153f3 	stp	x19, x20, [sp, #16]
   84094:	b0000093 	adrp	x19, 95000 <wordsworth.1722+0xee10>
    printf("\t %5s %10s %10s %20s\n", "pid", "state", "name", "sleep-on");
   84098:	910ea084 	add	x4, x4, #0x3a8
   8409c:	910ee063 	add	x3, x3, #0x3b8
   840a0:	90000082 	adrp	x2, 94000 <wordsworth.1722+0xde10>
   840a4:	90000081 	adrp	x1, 94000 <wordsworth.1722+0xde10>
   840a8:	910f0042 	add	x2, x2, #0x3c0
   840ac:	910f2021 	add	x1, x1, #0x3c8
   840b0:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   840b4:	910f4000 	add	x0, x0, #0x3d0
void procdump(void) {
   840b8:	a9025bf5 	stp	x21, x22, [sp, #32]
        if (p->state == TASK_UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
            state = states[p->state];
        else
            state = "???";
   840bc:	90000094 	adrp	x20, 94000 <wordsworth.1722+0xde10>
void procdump(void) {
   840c0:	f9001bf7 	str	x23, [sp, #48]
    printf("\t %5s %10s %10s %20s\n", "pid", "state", "name", "sleep-on");
   840c4:	97fff555 	bl	81618 <tfp_printf>
    for (int i = 0; i < NR_TASKS; i++) {
   840c8:	f9475673 	ldr	x19, [x19, #3752]
        printf("\t %5d %10s %10s %20lx\n", p->pid, state, p->name, 
   840cc:	90000095 	adrp	x21, 94000 <wordsworth.1722+0xde10>
            state = "???";
   840d0:	910e8294 	add	x20, x20, #0x3a0
        printf("\t %5d %10s %10s %20lx\n", p->pid, state, p->name, 
   840d4:	910fa2b5 	add	x21, x21, #0x3e8
   840d8:	91040276 	add	x22, x19, #0x100
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
   840dc:	b0000097 	adrp	x23, 95000 <wordsworth.1722+0xee10>
        p = task[i];
   840e0:	f9400264 	ldr	x4, [x19]
            state = "???";
   840e4:	aa1403e2 	mov	x2, x20
        printf("\t %5d %10s %10s %20lx\n", p->pid, state, p->name, 
   840e8:	aa1503e0 	mov	x0, x21
   840ec:	91002273 	add	x19, x19, #0x8
   840f0:	9103c083 	add	x3, x4, #0xf0
        if (p->state == TASK_UNUSED)
   840f4:	b9413881 	ldr	w1, [x4, #312]
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
   840f8:	7100103f 	cmp	w1, #0x4
        if (p->state == TASK_UNUSED)
   840fc:	34000121 	cbz	w1, 84120 <procdump+0xa0>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
   84100:	913be2e5 	add	x5, x23, #0xef8
   84104:	54000088 	b.hi	84114 <procdump+0x94>  // b.pmore
   84108:	f861d8a2 	ldr	x2, [x5, w1, sxtw #3]
            state = "???";
   8410c:	f100005f 	cmp	x2, #0x0
   84110:	9a820282 	csel	x2, x20, x2, eq  // eq = none
        printf("\t %5d %10s %10s %20lx\n", p->pid, state, p->name, 
   84114:	b9413481 	ldr	w1, [x4, #308]
   84118:	f940ac84 	ldr	x4, [x4, #344]
   8411c:	97fff53f 	bl	81618 <tfp_printf>
    for (int i = 0; i < NR_TASKS; i++) {
   84120:	eb1302df 	cmp	x22, x19
   84124:	54fffde1 	b.ne	840e0 <procdump+0x60>  // b.any
               (unsigned long)p->chan);
    }
    
    extern unsigned paging_pages_used, paging_pages_total; // alloc.c
	printf("paging mem: used %u total %u (%u/100)\n", 
   84128:	b0000081 	adrp	x1, 95000 <wordsworth.1722+0xee10>
   8412c:	b0000082 	adrp	x2, 95000 <wordsworth.1722+0xee10>
		paging_pages_used, paging_pages_total, 
        paging_pages_used*100/(paging_pages_total));
   84130:	52800c83 	mov	w3, #0x64                  	// #100
	printf("paging mem: used %u total %u (%u/100)\n", 
   84134:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   84138:	f9474421 	ldr	x1, [x1, #3720]
   8413c:	91100000 	add	x0, x0, #0x400
   84140:	f9473842 	ldr	x2, [x2, #3696]
   84144:	b9400021 	ldr	w1, [x1]
}
   84148:	a94153f3 	ldp	x19, x20, [sp, #16]
	printf("paging mem: used %u total %u (%u/100)\n", 
   8414c:	b9400042 	ldr	w2, [x2]
        paging_pages_used*100/(paging_pages_total));
   84150:	1b037c23 	mul	w3, w1, w3
}
   84154:	a9425bf5 	ldp	x21, x22, [sp, #32]
   84158:	f9401bf7 	ldr	x23, [sp, #48]
   8415c:	a8c47bfd 	ldp	x29, x30, [sp], #64
	printf("paging mem: used %u total %u (%u/100)\n", 
   84160:	1ac20863 	udiv	w3, w3, w2
   84164:	17fff52d 	b	81618 <tfp_printf>

0000000000084168 <copy_process>:
    arg: arg to kernel thread; or stack (userva) for user thread
    name: to be copied to task->name[]. if null, copy parent's name
*/
// Q2: quest "two cooperative printers"
int copy_process(unsigned long clone_flags, unsigned long fn, unsigned long arg,
    const char *name) {
   84168:	a9b87bfd 	stp	x29, x30, [sp, #-128]!
   8416c:	910003fd 	mov	x29, sp
   84170:	a90153f3 	stp	x19, x20, [sp, #16]
   84174:	aa0303f3 	mov	x19, x3
   84178:	a9025bf5 	stp	x21, x22, [sp, #32]
   8417c:	a90363f7 	stp	x23, x24, [sp, #48]
	struct task_struct *p = 0, *cur=myproc(); 
    int i, pid; 

	acquire(&sched_lock);	
   84180:	b0000098 	adrp	x24, 95000 <wordsworth.1722+0xee10>
   84184:	b0000097 	adrp	x23, 95000 <wordsworth.1722+0xee10>
    const char *name) {
   84188:	a9046bf9 	stp	x25, x26, [sp, #64]
   8418c:	a90573fb 	stp	x27, x28, [sp, #80]
	// find an empty tcb slot
	for (i = 0; i < NR_TASKS; i++) {
   84190:	5280001c 	mov	w28, #0x0                   	// #0
    const char *name) {
   84194:	a90687e0 	stp	x0, x1, [sp, #104]
   84198:	f9003fe2 	str	x2, [sp, #120]
	push_off(); 
   8419c:	97fff69b 	bl	81c08 <push_off>
    p=mycpu()->proc; 
   841a0:	b0000080 	adrp	x0, 95000 <wordsworth.1722+0xee10>
        pid = (lastpid+1+i) % NR_TASKS; 
   841a4:	f0000321 	adrp	x1, eb000 <lastpid>
   841a8:	91000039 	add	x25, x1, #0x0
    p=mycpu()->proc; 
   841ac:	f9475c00 	ldr	x0, [x0, #3768]
   841b0:	f9400014 	ldr	x20, [x0]
    pop_off(); 
   841b4:	97fff6cb 	bl	81ce0 <pop_off>
	acquire(&sched_lock);	
   841b8:	9138c300 	add	x0, x24, #0xe30
   841bc:	97fff6a7 	bl	81c58 <acquire>
		p = task[pid]; BUG_ON(!p); 
   841c0:	90000081 	adrp	x1, 94000 <wordsworth.1722+0xde10>
   841c4:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   841c8:	910d4036 	add	x22, x1, #0x350
   841cc:	910d8015 	add	x21, x0, #0x360
   841d0:	14000005 	b	841e4 <copy_process+0x7c>
		if (p->state == TASK_UNUSED)
   841d4:	b9413b62 	ldr	w2, [x27, #312]
	for (i = 0; i < NR_TASKS; i++) {
   841d8:	7100839f 	cmp	w28, #0x20
		if (p->state == TASK_UNUSED)
   841dc:	340002a2 	cbz	w2, 84230 <copy_process+0xc8>
	for (i = 0; i < NR_TASKS; i++) {
   841e0:	54000920 	b.eq	84304 <copy_process+0x19c>  // b.none
        pid = (lastpid+1+i) % NR_TASKS; 
   841e4:	b9400324 	ldr	w4, [x25]
		p = task[pid]; BUG_ON(!p); 
   841e8:	f94756e2 	ldr	x2, [x23, #3752]
        pid = (lastpid+1+i) % NR_TASKS; 
   841ec:	11000484 	add	w4, w4, #0x1
   841f0:	0b1c0084 	add	w4, w4, w28
   841f4:	1100079c 	add	w28, w28, #0x1
   841f8:	6b0403fa 	negs	w26, w4
   841fc:	12001084 	and	w4, w4, #0x1f
   84200:	1200135a 	and	w26, w26, #0x1f
   84204:	5a9a449a 	csneg	w26, w4, w26, mi  // mi = first
		p = task[pid]; BUG_ON(!p); 
   84208:	f87ad85b 	ldr	x27, [x2, w26, sxtw #3]
   8420c:	b5fffe5b 	cbnz	x27, 841d4 <copy_process+0x6c>
   84210:	528049c2 	mov	w2, #0x24e                 	// #590
   84214:	aa1603e1 	mov	x1, x22
   84218:	aa1503e0 	mov	x0, x21
   8421c:	97fff5cf 	bl	81958 <assertion_failed>
		if (p->state == TASK_UNUSED)
   84220:	b9413b62 	ldr	w2, [x27, #312]
	for (i = 0; i < NR_TASKS; i++) {
   84224:	7100839f 	cmp	w28, #0x20
		if (p->state == TASK_UNUSED)
   84228:	35fffdc2 	cbnz	w2, 841e0 <copy_process+0x78>
   8422c:	d503201f 	nop
			{V("alloc pid %d", pid); lastpid=pid; break;}
   84230:	f0000320 	adrp	x0, eb000 <lastpid>
	}
	if (i == NR_TASKS) 
		{release(&sched_lock); return -1;}

	memset(p, 0, sizeof(struct task_struct));
   84234:	52802d02 	mov	w2, #0x168                 	// #360
   84238:	52800001 	mov	w1, #0x0                   	// #0
	initlock(&p->lock, "proc");
   8423c:	91046379 	add	x25, x27, #0x118
			{V("alloc pid %d", pid); lastpid=pid; break;}
   84240:	b900001a 	str	w26, [x0]
	memset(p, 0, sizeof(struct task_struct));
   84244:	aa1b03e0 	mov	x0, x27
   84248:	97fff5d0 	bl	81988 <memset>

	acquire(&p->lock);	
    acquire(&cur->lock);	
   8424c:	9104629c 	add	x28, x20, #0x118
	initlock(&p->lock, "proc");
   84250:	90000081 	adrp	x1, 94000 <wordsworth.1722+0xde10>
   84254:	9110a021 	add	x1, x1, #0x428
   84258:	aa1903e0 	mov	x0, x25
   8425c:	97fff65d 	bl	81bd0 <initlock>
	acquire(&p->lock);	
   84260:	aa1903e0 	mov	x0, x25
   84264:	97fff67d 	bl	81c58 <acquire>
    acquire(&cur->lock);	
   84268:	aa1c03e0 	mov	x0, x28
   8426c:	97fff67b 	bl	81c58 <acquire>

    // load fn/arg to cpu context. cf ret_from_fork
    /* STUDENT: TODO: your code here */
    
    p->cpu_context.x19 = fn;
    p->cpu_context.x20 = arg;
   84270:	a94707e0 	ldp	x0, x1, [sp, #112]
   84274:	a9000760 	stp	x0, x1, [x27]


    // also inherit task name
    if (name)
   84278:	9103c360 	add	x0, x27, #0xf0
   8427c:	b40003d3 	cbz	x19, 842f4 <copy_process+0x18c>
        safestrcpy(p->name, name, sizeof(p->name));
   84280:	aa1303e1 	mov	x1, x19
   84284:	52800202 	mov	w2, #0x10                  	// #16
   84288:	97fff626 	bl	81b20 <safestrcpy>
	/* STUDENT: TODO: your code here */

    unsigned long stack_top = (unsigned long)p + THREAD_SIZE;

    p->cpu_context.sp = stack_top;
    p->cpu_context.pc = (unsigned long)ret_from_fork;
   8428c:	b0000080 	adrp	x0, 95000 <wordsworth.1722+0xee10>
    unsigned long stack_top = (unsigned long)p + THREAD_SIZE;
   84290:	91400762 	add	x2, x27, #0x1, lsl #12
	p->credits = p->priority = cur->priority;
   84294:	f940a681 	ldr	x1, [x20, #328]
	p->pid = pid; 
   84298:	b901377a 	str	w26, [x27, #308]
    p->cpu_context.pc = (unsigned long)ret_from_fork;
   8429c:	f9476800 	ldr	x0, [x0, #3792]
   842a0:	a9058362 	stp	x2, x0, [x27, #88]
	p->flags = clone_flags;
   842a4:	f94037e0 	ldr	x0, [sp, #104]
   842a8:	f9008760 	str	x0, [x27, #264]
	p->credits = p->priority = cur->priority;
   842ac:	a9140761 	stp	x1, x1, [x27, #320]
	
    release(&cur->lock);
   842b0:	aa1c03e0 	mov	x0, x28
   842b4:	97fff6ab 	bl	81d60 <release>
	release(&p->lock);
   842b8:	aa1903e0 	mov	x0, x25
   842bc:	97fff6a9 	bl	81d60 <release>
 	p->parent = cur;
	// the last thing: change the task's state so that the scheduler can pick up
    // the task to run in the future
	/* STUDENT: TODO: your code here */

    p->state = TASK_RUNNABLE;
   842c0:	52800080 	mov	w0, #0x4                   	// #4
   842c4:	b9013b60 	str	w0, [x27, #312]
 	p->parent = cur;
   842c8:	f900b374 	str	x20, [x27, #352]
	
	release(&sched_lock);
   842cc:	9138c300 	add	x0, x24, #0xe30
   842d0:	97fff6a4 	bl	81d60 <release>

	return pid;
}
   842d4:	2a1a03e0 	mov	w0, w26
   842d8:	a94153f3 	ldp	x19, x20, [sp, #16]
   842dc:	a9425bf5 	ldp	x21, x22, [sp, #32]
   842e0:	a94363f7 	ldp	x23, x24, [sp, #48]
   842e4:	a9446bf9 	ldp	x25, x26, [sp, #64]
   842e8:	a94573fb 	ldp	x27, x28, [sp, #80]
   842ec:	a8c87bfd 	ldp	x29, x30, [sp], #128
   842f0:	d65f03c0 	ret
	    safestrcpy(p->name, cur->name, sizeof(cur->name));
   842f4:	9103c281 	add	x1, x20, #0xf0
   842f8:	52800202 	mov	w2, #0x10                  	// #16
   842fc:	97fff609 	bl	81b20 <safestrcpy>
   84300:	17ffffe3 	b	8428c <copy_process+0x124>
		{release(&sched_lock); return -1;}
   84304:	9138c300 	add	x0, x24, #0xe30
   84308:	1280001a 	mov	w26, #0xffffffff            	// #-1
   8430c:	97fff695 	bl	81d60 <release>
   84310:	17fffff1 	b	842d4 <copy_process+0x16c>
   84314:	00000000 	udf	#0

0000000000084318 <handler>:
#include "plat.h"
#include "utils.h"
#include "debug.h"
#include "sched.h"

static void handler(TKernelTimerHandle hTimer, void *param, void *context) {
   84318:	d10183ff 	sub	sp, sp, #0x60
   8431c:	a9017bfd 	stp	x29, x30, [sp, #16]
   84320:	910043fd 	add	x29, sp, #0x10
   84324:	a90253f3 	stp	x19, x20, [sp, #32]
   84328:	aa0003f3 	mov	x19, x0
   8432c:	aa0103f4 	mov	x20, x1
	unsigned sec, msec; 
	current_time(&sec, &msec);
   84330:	910163e0 	add	x0, sp, #0x58
   84334:	910173e1 	add	x1, sp, #0x5c
static void handler(TKernelTimerHandle hTimer, void *param, void *context) {
   84338:	a9035bf5 	stp	x21, x22, [sp, #48]
   8433c:	aa0203f5 	mov	x21, x2
   84340:	f90023f7 	str	x23, [sp, #64]
	current_time(&sec, &msec);
   84344:	97fff6fd 	bl	81f38 <current_time>
	I("%u.%03u: fired. on cpu %d. htimer %ld, param %lx, contex %lx", sec, msec,
   84348:	294b5ff6 	ldp	w22, w23, [sp, #88]
   8434c:	940006ef 	bl	85f08 <cpuid>
   84350:	f90003f5 	str	x21, [sp]
   84354:	aa1403e7 	mov	x7, x20
   84358:	aa1303e6 	mov	x6, x19
   8435c:	2a1703e4 	mov	w4, w23
   84360:	2a1603e3 	mov	w3, w22
   84364:	2a0003e5 	mov	w5, w0
   84368:	52800122 	mov	w2, #0x9                   	// #9
   8436c:	90000081 	adrp	x1, 94000 <wordsworth.1722+0xde10>
   84370:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   84374:	91122021 	add	x1, x1, #0x488
   84378:	91126000 	add	x0, x0, #0x498
   8437c:	97fff4a7 	bl	81618 <tfp_printf>
		cpuid(), hTimer, (unsigned long)param, (unsigned long)context); 
}
   84380:	a9417bfd 	ldp	x29, x30, [sp, #16]
   84384:	a94253f3 	ldp	x19, x20, [sp, #32]
   84388:	a9435bf5 	ldp	x21, x22, [sp, #48]
   8438c:	f94023f7 	ldr	x23, [sp, #64]
   84390:	910183ff 	add	sp, sp, #0x60
   84394:	d65f03c0 	ret

0000000000084398 <kern_task_print>:
////////////////////////////////////////////////
//  two kernel tasks print msgs. 
//  simple test for scheduler and context switch 

// a simple kernel task: print a message, yield
static void kern_task_print(const char *str) {
   84398:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   8439c:	910003fd 	mov	x29, sp
   843a0:	a90153f3 	stp	x19, x20, [sp, #16]
   843a4:	aa0003f4 	mov	x20, x0
	printf("Kernel task started at EL %d, pid %d\r\n", get_el(), myproc()->pid);
   843a8:	940006ef 	bl	85f64 <get_el>
   843ac:	2a0003f3 	mov	w19, w0
   843b0:	97fffd1c 	bl	83820 <myproc>
   843b4:	aa0003e2 	mov	x2, x0
   843b8:	2a1303e1 	mov	w1, w19
   843bc:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   843c0:	90000093 	adrp	x19, 94000 <wordsworth.1722+0xde10>
   843c4:	9113a000 	add	x0, x0, #0x4e8

	while (1) {
		printf("%s", str); 
   843c8:	91144273 	add	x19, x19, #0x510
	printf("Kernel task started at EL %d, pid %d\r\n", get_el(), myproc()->pid);
   843cc:	b9413442 	ldr	w2, [x2, #308]
   843d0:	97fff492 	bl	81618 <tfp_printf>
   843d4:	d503201f 	nop
		printf("%s", str); 
   843d8:	aa1403e1 	mov	x1, x20
   843dc:	aa1303e0 	mov	x0, x19
   843e0:	97fff48e 	bl	81618 <tfp_printf>
		ms_delay(10); // NB: spin waiting (silly). for testing sched only
   843e4:	52800140 	mov	w0, #0xa                   	// #10
   843e8:	97fff6cc 	bl	81f18 <ms_delay>
		yield();
   843ec:	97fffe09 	bl	83c10 <yield>
	while (1) {
   843f0:	17fffffa 	b	843d8 <kern_task_print+0x40>
   843f4:	d503201f 	nop

00000000000843f8 <kern_task_return>:

////////////////////////////////////////////////
// test kernel task return, exit() 

// a task returns from its func
static void kern_task_return(const char *str) {
   843f8:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   843fc:	910003fd 	mov	x29, sp
   84400:	a90153f3 	stp	x19, x20, [sp, #16]
   84404:	aa0003f3 	mov	x19, x0
	printf("Kernel task started at EL %d, pid %d\r\n", get_el(), myproc()->pid);
   84408:	940006d7 	bl	85f64 <get_el>
   8440c:	2a0003f4 	mov	w20, w0
   84410:	97fffd04 	bl	83820 <myproc>
   84414:	aa0003e2 	mov	x2, x0
   84418:	2a1403e1 	mov	w1, w20
   8441c:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   84420:	9113a000 	add	x0, x0, #0x4e8
   84424:	b9413442 	ldr	w2, [x2, #308]
   84428:	97fff47c 	bl	81618 <tfp_printf>
    printf("%s", str); 
   8442c:	aa1303e1 	mov	x1, x19
   84430:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
    return;     
    // what will happen? 
    // this func is called from ret_from_fork (entry.S). after returning from 
	// this func, it goes back to ret_from_fork and continues there -- in an inf loop
    // (cf entry.S ret_from_fork)
}
   84434:	a94153f3 	ldp	x19, x20, [sp, #16]
    printf("%s", str); 
   84438:	91144000 	add	x0, x0, #0x510
}
   8443c:	a8c27bfd 	ldp	x29, x30, [sp], #32
    printf("%s", str); 
   84440:	17fff476 	b	81618 <tfp_printf>
   84444:	d503201f 	nop

0000000000084448 <kern_task_exit>:

// a task calling "exit"
static void kern_task_exit(const char *str) {
   84448:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   8444c:	910003fd 	mov	x29, sp
   84450:	a90153f3 	stp	x19, x20, [sp, #16]
   84454:	aa0003f3 	mov	x19, x0
	printf("Kernel task started at EL %d, pid %d\r\n", get_el(), myproc()->pid);
   84458:	940006c3 	bl	85f64 <get_el>
   8445c:	2a0003f4 	mov	w20, w0
   84460:	97fffcf0 	bl	83820 <myproc>
   84464:	aa0003e2 	mov	x2, x0
   84468:	2a1403e1 	mov	w1, w20
   8446c:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   84470:	9113a000 	add	x0, x0, #0x4e8
   84474:	b9413442 	ldr	w2, [x2, #308]
   84478:	97fff468 	bl	81618 <tfp_printf>
    printf("%s", str); 
   8447c:	aa1303e1 	mov	x1, x19
   84480:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   84484:	91144000 	add	x0, x0, #0x510
   84488:	97fff464 	bl	81618 <tfp_printf>
    exit_process(0); 
}
   8448c:	a94153f3 	ldp	x19, x20, [sp, #16]
    exit_process(0); 
   84490:	52800000 	mov	w0, #0x0                   	// #0
}
   84494:	a8c27bfd 	ldp	x29, x30, [sp], #32
    exit_process(0); 
   84498:	17fffeb0 	b	83f58 <exit_process>
   8449c:	d503201f 	nop

00000000000844a0 <task_writer>:
    /* STUDENT: TODO: your code here */
    release(&testlock); 
    return i; 
}

static void task_writer() {
   844a0:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   844a4:	910003fd 	mov	x29, sp
   844a8:	a90153f3 	stp	x19, x20, [sp, #16]
   844ac:	b0000094 	adrp	x20, 95000 <wordsworth.1722+0xee10>
    acquire(&testlock); 
   844b0:	91392294 	add	x20, x20, #0xe48
static void task_writer() {
   844b4:	f90013f5 	str	x21, [sp, #32]
   844b8:	d0000015 	adrp	x21, 86000 <__asm_dcache_level+0xc>
                    "Thy gentle whispers calm the restless soul;"
                    "The streams, the woods, the sky, the endless sea,"
                    "In thee, we find our being's truest goal.";

    while (1) {
        do_write(wordsworth, strlen(wordsworth)); // NB: strlen does NOT count '\0'
   844bc:	9107c2b5 	add	x21, x21, #0x1f0
   844c0:	aa1503e0 	mov	x0, x21
   844c4:	97fff5a5 	bl	81b58 <strlen>
   844c8:	2a0003f3 	mov	w19, w0
    acquire(&testlock); 
   844cc:	aa1403e0 	mov	x0, x20
   844d0:	97fff5e2 	bl	81c58 <acquire>
    while (i<n) {
   844d4:	d503201f 	nop
   844d8:	7100027f 	cmp	w19, #0x0
   844dc:	54ffffec 	b.gt	844d8 <task_writer+0x38>
    release(&testlock); 
   844e0:	aa1403e0 	mov	x0, x20
   844e4:	97fff61f 	bl	81d60 <release>
        ms_delay(100); // spin waiting (silly). for testing only
   844e8:	52800c80 	mov	w0, #0x64                  	// #100
   844ec:	97fff68b 	bl	81f18 <ms_delay>
        do_write(wordsworth, strlen(wordsworth)); // NB: strlen does NOT count '\0'
   844f0:	17fffff4 	b	844c0 <task_writer+0x20>
   844f4:	d503201f 	nop

00000000000844f8 <kern_task_donut>:
//  modeled after test_kern_tasks_print()

// Q4: quest: "two donuts"
extern void donut(int idx); 	//donut.c
extern void donut_canvas_init(void); //donut.c don't forget to init canvas -- once
void kern_task_donut(int idx) {
   844f8:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   844fc:	910003fd 	mov	x29, sp
   84500:	a90153f3 	stp	x19, x20, [sp, #16]
   84504:	2a0003f3 	mov	w19, w0
	printf("process started EL %d, pid %d idx %d\r\n", 
   84508:	94000697 	bl	85f64 <get_el>
   8450c:	2a0003f4 	mov	w20, w0
        get_el(), myproc()->pid, idx);
   84510:	97fffcc4 	bl	83820 <myproc>
   84514:	aa0003e2 	mov	x2, x0
	printf("process started EL %d, pid %d idx %d\r\n", 
   84518:	2a1403e1 	mov	w1, w20
   8451c:	2a1303e3 	mov	w3, w19
   84520:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   84524:	91146000 	add	x0, x0, #0x518
   84528:	b9413442 	ldr	w2, [x2, #308]
   8452c:	97fff43b 	bl	81618 <tfp_printf>
    // exp: diff proirities --> donuts will turn at diff rates
	/* STUDENT: TODO: your code here */
    donut(idx);
   84530:	2a1303e0 	mov	w0, w19
}
   84534:	a94153f3 	ldp	x19, x20, [sp, #16]
   84538:	a8c27bfd 	ldp	x29, x30, [sp], #32
    donut(idx);
   8453c:	17fffb7b 	b	83328 <donut>

0000000000084540 <task_reader>:
static void task_reader() {
   84540:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
    acquire(&testlock); 
   84544:	b0000080 	adrp	x0, 95000 <wordsworth.1722+0xee10>
   84548:	91392000 	add	x0, x0, #0xe48
static void task_reader() {
   8454c:	910003fd 	mov	x29, sp
    acquire(&testlock); 
   84550:	97fff5c2 	bl	81c58 <acquire>
    while (nread == nwrite) {   // pipe empty
   84554:	14000000 	b	84554 <task_reader+0x14>

0000000000084558 <test_ktimer>:
void test_ktimer() {
   84558:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
   8455c:	910003fd 	mov	x29, sp
   84560:	a90153f3 	stp	x19, x20, [sp, #16]
	current_time(&sec, &msec); 
   84564:	910123f4 	add	x20, sp, #0x48
   84568:	aa1403e0 	mov	x0, x20
void test_ktimer() {
   8456c:	a9025bf5 	stp	x21, x22, [sp, #32]
	current_time(&sec, &msec); 
   84570:	910133f5 	add	x21, sp, #0x4c
   84574:	aa1503e1 	mov	x1, x21
void test_ktimer() {
   84578:	f9001bf7 	str	x23, [sp, #48]
	current_time(&sec, &msec); 
   8457c:	97fff66f 	bl	81f38 <current_time>
	I("%u.%03u start delaying 500ms...", sec, msec); 
   84580:	294913e3 	ldp	w3, w4, [sp, #72]
   84584:	90000097 	adrp	x23, 94000 <wordsworth.1722+0xde10>
   84588:	911222f3 	add	x19, x23, #0x488
   8458c:	52800242 	mov	w2, #0x12                  	// #18
   84590:	aa1303e1 	mov	x1, x19
   84594:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   84598:	91150000 	add	x0, x0, #0x540
   8459c:	97fff41f 	bl	81618 <tfp_printf>
	ms_delay(500); 
   845a0:	52803e80 	mov	w0, #0x1f4                 	// #500
   845a4:	97fff65d 	bl	81f18 <ms_delay>
	current_time(&sec, &msec);
   845a8:	aa1503e1 	mov	x1, x21
   845ac:	aa1403e0 	mov	x0, x20
   845b0:	97fff662 	bl	81f38 <current_time>
	int t = ktimer_start(500, handler, (void *)0xdeadbeef, (void*)0xdeaddeed);
   845b4:	90000015 	adrp	x21, 84000 <exit_process+0xa8>
	I("%u.%03u ended delaying 500ms", sec, msec); 
   845b8:	294913e3 	ldp	w3, w4, [sp, #72]
   845bc:	aa1303e1 	mov	x1, x19
   845c0:	528002a2 	mov	w2, #0x15                  	// #21
   845c4:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   845c8:	9115e000 	add	x0, x0, #0x578
	int t = ktimer_start(500, handler, (void *)0xdeadbeef, (void*)0xdeaddeed);
   845cc:	910c62b5 	add	x21, x21, #0x318
	I("%u.%03u ended delaying 500ms", sec, msec); 
   845d0:	97fff412 	bl	81618 <tfp_printf>
	I("timer start. timer id %u", t); 
   845d4:	90000094 	adrp	x20, 94000 <wordsworth.1722+0xde10>
	int t = ktimer_start(500, handler, (void *)0xdeadbeef, (void*)0xdeaddeed);
   845d8:	d29bdda3 	mov	x3, #0xdeed                	// #57069
   845dc:	d297dde2 	mov	x2, #0xbeef                	// #48879
   845e0:	aa1503e1 	mov	x1, x21
   845e4:	f2bbd5a3 	movk	x3, #0xdead, lsl #16
   845e8:	f2bbd5a2 	movk	x2, #0xdead, lsl #16
   845ec:	52803e80 	mov	w0, #0x1f4                 	// #500
   845f0:	97fff67a 	bl	81fd8 <ktimer_start>
	I("timer start. timer id %u", t); 
   845f4:	2a0003e3 	mov	w3, w0
   845f8:	aa1303e1 	mov	x1, x19
   845fc:	9116a294 	add	x20, x20, #0x5a8
   84600:	52800322 	mov	w2, #0x19                  	// #25
	int t = ktimer_start(500, handler, (void *)0xdeadbeef, (void*)0xdeaddeed);
   84604:	2a0003f6 	mov	w22, w0
	I("timer start. timer id %u", t); 
   84608:	aa1403e0 	mov	x0, x20
   8460c:	97fff403 	bl	81618 <tfp_printf>
	ms_delay(1000);
   84610:	52807d00 	mov	w0, #0x3e8                 	// #1000
   84614:	97fff641 	bl	81f18 <ms_delay>
	I("timer %d should have fired", t); 
   84618:	2a1603e3 	mov	w3, w22
   8461c:	aa1303e1 	mov	x1, x19
   84620:	52800362 	mov	w2, #0x1b                  	// #27
   84624:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   84628:	91176000 	add	x0, x0, #0x5d8
   8462c:	97fff3fb 	bl	81618 <tfp_printf>
	t = ktimer_start(500, handler, (void *)0xdeadbeef, (void*)0xdeaddeed);
   84630:	d29bdda3 	mov	x3, #0xdeed                	// #57069
   84634:	d297dde2 	mov	x2, #0xbeef                	// #48879
   84638:	aa1503e1 	mov	x1, x21
   8463c:	f2bbd5a3 	movk	x3, #0xdead, lsl #16
   84640:	f2bbd5a2 	movk	x2, #0xdead, lsl #16
   84644:	52803e80 	mov	w0, #0x1f4                 	// #500
   84648:	97fff664 	bl	81fd8 <ktimer_start>
	I("timer start. timer id %u", t); 
   8464c:	2a0003e3 	mov	w3, w0
   84650:	aa1303e1 	mov	x1, x19
   84654:	aa1403e0 	mov	x0, x20
   84658:	528003e2 	mov	w2, #0x1f                  	// #31
   8465c:	97fff3ef 	bl	81618 <tfp_printf>
	t = ktimer_start(1000, handler, (void *)0xdeadbeef, (void*)0xdeaddeed);
   84660:	d29bdda3 	mov	x3, #0xdeed                	// #57069
   84664:	d297dde2 	mov	x2, #0xbeef                	// #48879
   84668:	aa1503e1 	mov	x1, x21
   8466c:	f2bbd5a3 	movk	x3, #0xdead, lsl #16
   84670:	f2bbd5a2 	movk	x2, #0xdead, lsl #16
   84674:	52807d00 	mov	w0, #0x3e8                 	// #1000
   84678:	97fff658 	bl	81fd8 <ktimer_start>
	I("timer start. timer id %u", t); 
   8467c:	2a0003e3 	mov	w3, w0
   84680:	aa1303e1 	mov	x1, x19
   84684:	52800422 	mov	w2, #0x21                  	// #33
   84688:	aa1403e0 	mov	x0, x20
   8468c:	97fff3e3 	bl	81618 <tfp_printf>
	ms_delay(2000); 
   84690:	5280fa00 	mov	w0, #0x7d0                 	// #2000
   84694:	97fff621 	bl	81f18 <ms_delay>
	I("both timers should have fired"); 
   84698:	aa1303e1 	mov	x1, x19
   8469c:	52800462 	mov	w2, #0x23                  	// #35
   846a0:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   846a4:	91182000 	add	x0, x0, #0x608
   846a8:	97fff3dc 	bl	81618 <tfp_printf>
	t = ktimer_start(500, handler, (void *)0xdeadbeef, (void*)0xdeaddeed);
   846ac:	d29bdda3 	mov	x3, #0xdeed                	// #57069
   846b0:	d297dde2 	mov	x2, #0xbeef                	// #48879
   846b4:	aa1503e1 	mov	x1, x21
   846b8:	f2bbd5a3 	movk	x3, #0xdead, lsl #16
   846bc:	f2bbd5a2 	movk	x2, #0xdead, lsl #16
   846c0:	52803e80 	mov	w0, #0x1f4                 	// #500
   846c4:	97fff645 	bl	81fd8 <ktimer_start>
	I("timer start. timer id %u", t);
   846c8:	2a0003e3 	mov	w3, w0
   846cc:	aa1303e1 	mov	x1, x19
   846d0:	528004e2 	mov	w2, #0x27                  	// #39
	t = ktimer_start(500, handler, (void *)0xdeadbeef, (void*)0xdeaddeed);
   846d4:	2a0003f5 	mov	w21, w0
	I("timer start. timer id %u", t);
   846d8:	aa1403e0 	mov	x0, x20
   846dc:	97fff3cf 	bl	81618 <tfp_printf>
	ms_delay(100); 
   846e0:	52800c80 	mov	w0, #0x64                  	// #100
   846e4:	97fff60d 	bl	81f18 <ms_delay>
	int c = ktimer_cancel(t); 
   846e8:	2a1503e0 	mov	w0, w21
   846ec:	97fff67f 	bl	820e8 <ktimer_cancel>
	I("timer cancel return val = %d", c);
   846f0:	aa1303e1 	mov	x1, x19
	int c = ktimer_cancel(t); 
   846f4:	2a0003f4 	mov	w20, w0
	I("timer cancel return val = %d", c);
   846f8:	2a0003e3 	mov	w3, w0
   846fc:	52800542 	mov	w2, #0x2a                  	// #42
   84700:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   84704:	91190000 	add	x0, x0, #0x640
   84708:	97fff3c4 	bl	81618 <tfp_printf>
	BUG_ON(c < 0);
   8470c:	37f80174 	tbnz	w20, #31, 84738 <test_ktimer+0x1e0>
	I("there shouldn't be more callback"); 
   84710:	911222e1 	add	x1, x23, #0x488
   84714:	528005a2 	mov	w2, #0x2d                  	// #45
   84718:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   8471c:	911a0000 	add	x0, x0, #0x680
   84720:	97fff3be 	bl	81618 <tfp_printf>
}
   84724:	a94153f3 	ldp	x19, x20, [sp, #16]
   84728:	a9425bf5 	ldp	x21, x22, [sp, #32]
   8472c:	f9401bf7 	ldr	x23, [sp, #48]
   84730:	a8c57bfd 	ldp	x29, x30, [sp], #80
   84734:	d65f03c0 	ret
	BUG_ON(c < 0);
   84738:	aa1303e1 	mov	x1, x19
   8473c:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   84740:	52800562 	mov	w2, #0x2b                  	// #43
   84744:	9119c000 	add	x0, x0, #0x670
   84748:	97fff484 	bl	81958 <assertion_failed>
   8474c:	17fffff1 	b	84710 <test_ktimer+0x1b8>

0000000000084750 <test_fb>:
void test_fb() {
   84750:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   84754:	910003fd 	mov	x29, sp
   84758:	f9000bf3 	str	x19, [sp, #16]
    the_fb.width = N;
   8475c:	b0000093 	adrp	x19, 95000 <wordsworth.1722+0xee10>
    fb_fini(); 
   84760:	97fff788 	bl	82580 <fb_fini>
    the_fb.width = N;
   84764:	f9476260 	ldr	x0, [x19, #3776]
   84768:	b21803e2 	mov	x2, #0x10000000100         	// #1099511628032
    the_fb.vwidth = N*2; 
   8476c:	b21703e1 	mov	x1, #0x20000000200         	// #2199023256064
   84770:	a9008402 	stp	x2, x1, [x0, #8]
    if (fb_init() != 0) BUG();     
   84774:	97fff8a1 	bl	829f8 <fb_init>
   84778:	35000960 	cbnz	w0, 848a4 <test_fb+0x154>
    int pitch = the_fb.pitch; 
   8477c:	f9476261 	ldr	x1, [x19, #3776]
            setpixel(the_fb.fb,x,y,pitch,r); 
   84780:	52802008 	mov	w8, #0x100                 	// #256
    *(PIXEL *)(buf + y*pit + x*PIXELSIZE) = p; 
   84784:	52801fe6 	mov	w6, #0xff                  	// #255
            setpixel(the_fb.fb,x,y,pitch,r); 
   84788:	f9400020 	ldr	x0, [x1]
    int pitch = the_fb.pitch; 
   8478c:	b9401823 	ldr	w3, [x1, #24]
    for (y=0;y<N;y++)
   84790:	91100004 	add	x4, x0, #0x400
            setpixel(the_fb.fb,x,y,pitch,r); 
   84794:	aa0403e5 	mov	x5, x4
   84798:	93407c67 	sxtw	x7, w3
        for (x=0;x<N;x++)
   8479c:	d11000a2 	sub	x2, x5, #0x400
    *(PIXEL *)(buf + y*pit + x*PIXELSIZE) = p; 
   847a0:	b8004446 	str	w6, [x2], #4
        for (x=0;x<N;x++)
   847a4:	eb05005f 	cmp	x2, x5
   847a8:	54ffffc1 	b.ne	847a0 <test_fb+0x50>  // b.any
    for (y=0;y<N;y++)
   847ac:	8b070045 	add	x5, x2, x7
   847b0:	71000508 	subs	w8, w8, #0x1
   847b4:	54ffff41 	b.ne	8479c <test_fb+0x4c>  // b.any
   847b8:	91200001 	add	x1, x0, #0x800
   847bc:	52802008 	mov	w8, #0x100                 	// #256
   847c0:	aa0103e5 	mov	x5, x1
    *(PIXEL *)(buf + y*pit + x*PIXELSIZE) = p; 
   847c4:	32009fe6 	mov	w6, #0xff00ff              	// #16711935
        for (x=N;x<2*N;x++)
   847c8:	d11000a2 	sub	x2, x5, #0x400
   847cc:	d503201f 	nop
    *(PIXEL *)(buf + y*pit + x*PIXELSIZE) = p; 
   847d0:	b8004446 	str	w6, [x2], #4
        for (x=N;x<2*N;x++)
   847d4:	eb0200bf 	cmp	x5, x2
   847d8:	54ffffc1 	b.ne	847d0 <test_fb+0x80>  // b.any
    for (y=0;y<N;y++)
   847dc:	8b0700a5 	add	x5, x5, x7
   847e0:	71000508 	subs	w8, w8, #0x1
   847e4:	54ffff21 	b.ne	847c8 <test_fb+0x78>  // b.any
   847e8:	53185c63 	lsl	w3, w3, #8
   847ec:	52802006 	mov	w6, #0x100                 	// #256
    *(PIXEL *)(buf + y*pit + x*PIXELSIZE) = p; 
   847f0:	529fe005 	mov	w5, #0xff00                	// #65280
   847f4:	93407c63 	sxtw	x3, w3
   847f8:	8b040064 	add	x4, x3, x4
        for (x=0;x<N;x++)
   847fc:	d1100082 	sub	x2, x4, #0x400
    *(PIXEL *)(buf + y*pit + x*PIXELSIZE) = p; 
   84800:	b8004445 	str	w5, [x2], #4
        for (x=0;x<N;x++)
   84804:	eb02009f 	cmp	x4, x2
   84808:	54ffffc1 	b.ne	84800 <test_fb+0xb0>  // b.any
    for (y=N;y<2*N;y++)
   8480c:	8b070084 	add	x4, x4, x7
   84810:	710004c6 	subs	w6, w6, #0x1
   84814:	54ffff41 	b.ne	847fc <test_fb+0xac>  // b.any
   84818:	8b010063 	add	x3, x3, x1
   8481c:	52802005 	mov	w5, #0x100                 	// #256
    *(PIXEL *)(buf + y*pit + x*PIXELSIZE) = p; 
   84820:	52a01fe4 	mov	w4, #0xff0000              	// #16711680
        for (x=N;x<2*N;x++)
   84824:	d1100062 	sub	x2, x3, #0x400
    *(PIXEL *)(buf + y*pit + x*PIXELSIZE) = p; 
   84828:	b8004444 	str	w4, [x2], #4
        for (x=N;x<2*N;x++)
   8482c:	eb02007f 	cmp	x3, x2
   84830:	54ffffc1 	b.ne	84828 <test_fb+0xd8>  // b.any
    for (y=N;y<2*N;y++)
   84834:	8b070063 	add	x3, x3, x7
   84838:	710004a5 	subs	w5, w5, #0x1
   8483c:	54ffff41 	b.ne	84824 <test_fb+0xd4>  // b.any
    __asm_flush_dcache_range(the_fb.fb, the_fb.fb + the_fb.size); 
   84840:	f9476273 	ldr	x19, [x19, #3776]
   84844:	b9403661 	ldr	w1, [x19, #52]
   84848:	8b010001 	add	x1, x0, x1
   8484c:	940005d0 	bl	85f8c <__asm_flush_dcache_range>
        fb_set_voffsets(0,0);
   84850:	52800001 	mov	w1, #0x0                   	// #0
   84854:	52800000 	mov	w0, #0x0                   	// #0
   84858:	97fff710 	bl	82498 <fb_set_voffsets>
        ms_delay(1500); 
   8485c:	5280bb80 	mov	w0, #0x5dc                 	// #1500
   84860:	97fff5ae 	bl	81f18 <ms_delay>
        fb_set_voffsets(0,N);
   84864:	52802001 	mov	w1, #0x100                 	// #256
   84868:	52800000 	mov	w0, #0x0                   	// #0
   8486c:	97fff70b 	bl	82498 <fb_set_voffsets>
        ms_delay(1500); 
   84870:	5280bb80 	mov	w0, #0x5dc                 	// #1500
   84874:	97fff5a9 	bl	81f18 <ms_delay>
        fb_set_voffsets(N,0);
   84878:	52800001 	mov	w1, #0x0                   	// #0
   8487c:	52802000 	mov	w0, #0x100                 	// #256
   84880:	97fff706 	bl	82498 <fb_set_voffsets>
        ms_delay(1500); 
   84884:	5280bb80 	mov	w0, #0x5dc                 	// #1500
   84888:	97fff5a4 	bl	81f18 <ms_delay>
        fb_set_voffsets(N,N);
   8488c:	52802001 	mov	w1, #0x100                 	// #256
   84890:	2a0103e0 	mov	w0, w1
   84894:	97fff701 	bl	82498 <fb_set_voffsets>
        ms_delay(1500); 
   84898:	5280bb80 	mov	w0, #0x5dc                 	// #1500
   8489c:	97fff59f 	bl	81f18 <ms_delay>
    while (1) {
   848a0:	17ffffec 	b	84850 <test_fb+0x100>
    if (fb_init() != 0) BUG();     
   848a4:	90000081 	adrp	x1, 94000 <wordsworth.1722+0xde10>
   848a8:	d0000000 	adrp	x0, 86000 <__asm_dcache_level+0xc>
   848ac:	91122021 	add	x1, x1, #0x488
   848b0:	910d8000 	add	x0, x0, #0x360
   848b4:	52800b22 	mov	w2, #0x59                  	// #89
   848b8:	97fff428 	bl	81958 <assertion_failed>
   848bc:	17ffffb0 	b	8477c <test_fb+0x2c>

00000000000848c0 <test_kern_tasks_print>:
void test_kern_tasks_print(void) {
   848c0:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
	int res = copy_process(PF_KTHREAD, (unsigned long)&kern_task_print, 
   848c4:	90000083 	adrp	x3, 94000 <wordsworth.1722+0xde10>
   848c8:	90000082 	adrp	x2, 94000 <wordsworth.1722+0xde10>
void test_kern_tasks_print(void) {
   848cc:	910003fd 	mov	x29, sp
   848d0:	a90153f3 	stp	x19, x20, [sp, #16]
	int res = copy_process(PF_KTHREAD, (unsigned long)&kern_task_print, 
   848d4:	90000013 	adrp	x19, 84000 <exit_process+0xa8>
   848d8:	910e6273 	add	x19, x19, #0x398
   848dc:	aa1303e1 	mov	x1, x19
   848e0:	911ae063 	add	x3, x3, #0x6b8
   848e4:	911b0042 	add	x2, x2, #0x6c0
   848e8:	d2800040 	mov	x0, #0x2                   	// #2
   848ec:	90000094 	adrp	x20, 94000 <wordsworth.1722+0xde10>
void test_kern_tasks_print(void) {
   848f0:	f90013f5 	str	x21, [sp, #32]
   848f4:	90000095 	adrp	x21, 94000 <wordsworth.1722+0xde10>
	int res = copy_process(PF_KTHREAD, (unsigned long)&kern_task_print, 
   848f8:	97fffe1c 	bl	84168 <copy_process>
	BUG_ON(res<0); 
   848fc:	37f80180 	tbnz	w0, #31, 8492c <test_kern_tasks_print+0x6c>
	res = copy_process(PF_KTHREAD, (unsigned long)&kern_task_print, 
   84900:	90000083 	adrp	x3, 94000 <wordsworth.1722+0xde10>
   84904:	90000082 	adrp	x2, 94000 <wordsworth.1722+0xde10>
   84908:	aa1303e1 	mov	x1, x19
   8490c:	911b8063 	add	x3, x3, #0x6e0
   84910:	911ba042 	add	x2, x2, #0x6e8
   84914:	d2800040 	mov	x0, #0x2                   	// #2
   84918:	97fffe14 	bl	84168 <copy_process>
	BUG_ON(res<0);
   8491c:	37f80120 	tbnz	w0, #31, 84940 <test_kern_tasks_print+0x80>
        	yield();
   84920:	97fffcbc 	bl	83c10 <yield>
   84924:	97fffcbb 	bl	83c10 <yield>
	while (1)
   84928:	17fffffe 	b	84920 <test_kern_tasks_print+0x60>
	BUG_ON(res<0); 
   8492c:	911222a1 	add	x1, x21, #0x488
   84930:	911b4280 	add	x0, x20, #0x6d0
   84934:	528012e2 	mov	w2, #0x97                  	// #151
   84938:	97fff408 	bl	81958 <assertion_failed>
   8493c:	17fffff1 	b	84900 <test_kern_tasks_print+0x40>
	BUG_ON(res<0);
   84940:	911222a1 	add	x1, x21, #0x488
   84944:	911b4280 	add	x0, x20, #0x6d0
   84948:	52801382 	mov	w2, #0x9c                  	// #156
   8494c:	97fff403 	bl	81958 <assertion_failed>
        	yield();
   84950:	97fffcb0 	bl	83c10 <yield>
	while (1)
   84954:	17fffff4 	b	84924 <test_kern_tasks_print+0x64>

0000000000084958 <test_kern_task_mgmt>:
void test_kern_task_mgmt(void) {
   84958:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
	int res = copy_process(PF_KTHREAD, (unsigned long)&kern_task_return, 
   8495c:	90000083 	adrp	x3, 94000 <wordsworth.1722+0xde10>
   84960:	90000082 	adrp	x2, 94000 <wordsworth.1722+0xde10>
void test_kern_task_mgmt(void) {
   84964:	910003fd 	mov	x29, sp
	int res = copy_process(PF_KTHREAD, (unsigned long)&kern_task_return, 
   84968:	90000001 	adrp	x1, 84000 <exit_process+0xa8>
   8496c:	911ae063 	add	x3, x3, #0x6b8
   84970:	911b0042 	add	x2, x2, #0x6c0
   84974:	910fe021 	add	x1, x1, #0x3f8
   84978:	d2800040 	mov	x0, #0x2                   	// #2
   8497c:	97fffdfb 	bl	84168 <copy_process>
	BUG_ON(res<0); 
   84980:	37f80180 	tbnz	w0, #31, 849b0 <test_kern_task_mgmt+0x58>
	res = copy_process(PF_KTHREAD, (unsigned long)&kern_task_exit, 
   84984:	90000083 	adrp	x3, 94000 <wordsworth.1722+0xde10>
   84988:	90000082 	adrp	x2, 94000 <wordsworth.1722+0xde10>
   8498c:	90000001 	adrp	x1, 84000 <exit_process+0xa8>
   84990:	911b8063 	add	x3, x3, #0x6e0
   84994:	911ba042 	add	x2, x2, #0x6e8
   84998:	91112021 	add	x1, x1, #0x448
   8499c:	d2800040 	mov	x0, #0x2                   	// #2
   849a0:	97fffdf2 	bl	84168 <copy_process>
	BUG_ON(res<0);    
   849a4:	37f80140 	tbnz	w0, #31, 849cc <test_kern_task_mgmt+0x74>
}
   849a8:	a8c17bfd 	ldp	x29, x30, [sp], #16
   849ac:	d65f03c0 	ret
	BUG_ON(res<0); 
   849b0:	90000081 	adrp	x1, 94000 <wordsworth.1722+0xde10>
   849b4:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   849b8:	91122021 	add	x1, x1, #0x488
   849bc:	911b4000 	add	x0, x0, #0x6d0
   849c0:	528017e2 	mov	w2, #0xbf                  	// #191
   849c4:	97fff3e5 	bl	81958 <assertion_failed>
   849c8:	17ffffef 	b	84984 <test_kern_task_mgmt+0x2c>
}
   849cc:	a8c17bfd 	ldp	x29, x30, [sp], #16
	BUG_ON(res<0);    
   849d0:	90000081 	adrp	x1, 94000 <wordsworth.1722+0xde10>
   849d4:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   849d8:	91122021 	add	x1, x1, #0x488
   849dc:	911b4000 	add	x0, x0, #0x6d0
   849e0:	52801882 	mov	w2, #0xc4                  	// #196
   849e4:	17fff3dd 	b	81958 <assertion_failed>

00000000000849e8 <test_kern_reader_writer>:
void test_kern_reader_writer() {
   849e8:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
	int res = copy_process(PF_KTHREAD, (unsigned long)&task_writer, 
   849ec:	90000083 	adrp	x3, 94000 <wordsworth.1722+0xde10>
   849f0:	90000001 	adrp	x1, 84000 <exit_process+0xa8>
void test_kern_reader_writer() {
   849f4:	910003fd 	mov	x29, sp
	int res = copy_process(PF_KTHREAD, (unsigned long)&task_writer, 
   849f8:	911bc063 	add	x3, x3, #0x6f0
   849fc:	91128021 	add	x1, x1, #0x4a0
   84a00:	d2800002 	mov	x2, #0x0                   	// #0
   84a04:	d2800040 	mov	x0, #0x2                   	// #2
   84a08:	97fffdd8 	bl	84168 <copy_process>
	BUG_ON(res<0); 
   84a0c:	37f80160 	tbnz	w0, #31, 84a38 <test_kern_reader_writer+0x50>
	res = copy_process(PF_KTHREAD, (unsigned long)&task_reader, 
   84a10:	90000083 	adrp	x3, 94000 <wordsworth.1722+0xde10>
   84a14:	90000001 	adrp	x1, 84000 <exit_process+0xa8>
   84a18:	911be063 	add	x3, x3, #0x6f8
   84a1c:	91150021 	add	x1, x1, #0x540
   84a20:	d2800002 	mov	x2, #0x0                   	// #0
   84a24:	d2800040 	mov	x0, #0x2                   	// #2
   84a28:	97fffdd0 	bl	84168 <copy_process>
	BUG_ON(res<0);    
   84a2c:	37f80220 	tbnz	w0, #31, 84a70 <test_kern_reader_writer+0x88>
}
   84a30:	a8c17bfd 	ldp	x29, x30, [sp], #16
   84a34:	d65f03c0 	ret
	BUG_ON(res<0); 
   84a38:	52802402 	mov	w2, #0x120                 	// #288
   84a3c:	90000081 	adrp	x1, 94000 <wordsworth.1722+0xde10>
   84a40:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   84a44:	91122021 	add	x1, x1, #0x488
   84a48:	911b4000 	add	x0, x0, #0x6d0
   84a4c:	97fff3c3 	bl	81958 <assertion_failed>
	res = copy_process(PF_KTHREAD, (unsigned long)&task_reader, 
   84a50:	90000083 	adrp	x3, 94000 <wordsworth.1722+0xde10>
   84a54:	90000001 	adrp	x1, 84000 <exit_process+0xa8>
   84a58:	911be063 	add	x3, x3, #0x6f8
   84a5c:	91150021 	add	x1, x1, #0x540
   84a60:	d2800002 	mov	x2, #0x0                   	// #0
   84a64:	d2800040 	mov	x0, #0x2                   	// #2
   84a68:	97fffdc0 	bl	84168 <copy_process>
	BUG_ON(res<0);    
   84a6c:	36fffe20 	tbz	w0, #31, 84a30 <test_kern_reader_writer+0x48>
}
   84a70:	a8c17bfd 	ldp	x29, x30, [sp], #16
	BUG_ON(res<0);    
   84a74:	90000081 	adrp	x1, 94000 <wordsworth.1722+0xde10>
   84a78:	90000080 	adrp	x0, 94000 <wordsworth.1722+0xde10>
   84a7c:	91122021 	add	x1, x1, #0x488
   84a80:	911b4000 	add	x0, x0, #0x6d0
   84a84:	52802482 	mov	w2, #0x124                 	// #292
   84a88:	17fff3b4 	b	81958 <assertion_failed>
   84a8c:	d503201f 	nop

0000000000084a90 <test_kern_tasks_donut>:

void test_kern_tasks_donut(void) {
   84a90:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
   84a94:	910003fd 	mov	x29, sp
   84a98:	a90153f3 	stp	x19, x20, [sp, #16]
   84a9c:	90000094 	adrp	x20, 94000 <wordsworth.1722+0xde10>
    char name[10]; 
    int res; 

    donut_canvas_init(); 
   84aa0:	d2800013 	mov	x19, #0x0                   	// #0
    
    // spawn N donut tasks 
    for (int i=0; i<N_DONUTS; i++) {
        snprintf(name, 10, "donut-%d", i); 
   84aa4:	911c0294 	add	x20, x20, #0x700
void test_kern_tasks_donut(void) {
   84aa8:	a9025bf5 	stp	x21, x22, [sp, #32]
   84aac:	90000015 	adrp	x21, 84000 <exit_process+0xa8>
   84ab0:	910103f6 	add	x22, sp, #0x40
   84ab4:	9113e2b5 	add	x21, x21, #0x4f8
   84ab8:	a90363f7 	stp	x23, x24, [sp, #48]
   84abc:	90000098 	adrp	x24, 94000 <wordsworth.1722+0xde10>
   84ac0:	90000097 	adrp	x23, 94000 <wordsworth.1722+0xde10>
        res = copy_process(PF_KTHREAD,
                           (unsigned long)&kern_task_donut,
                           (unsigned long)i,
                           name);

        BUG_ON(res < 0);
   84ac4:	91122318 	add	x24, x24, #0x488
   84ac8:	911c42f7 	add	x23, x23, #0x710
    donut_canvas_init(); 
   84acc:	97fff887 	bl	82ce8 <donut_canvas_init>
    for (int i=0; i<N_DONUTS; i++) {
   84ad0:	14000003 	b	84adc <test_kern_tasks_donut+0x4c>
   84ad4:	f100667f 	cmp	x19, #0x19
   84ad8:	54000260 	b.eq	84b24 <test_kern_tasks_donut+0x94>  // b.none
        snprintf(name, 10, "donut-%d", i); 
   84adc:	2a1303e3 	mov	w3, w19
   84ae0:	aa1403e2 	mov	x2, x20
   84ae4:	d2800141 	mov	x1, #0xa                   	// #10
   84ae8:	aa1603e0 	mov	x0, x22
   84aec:	97fff307 	bl	81708 <tfp_snprintf>
        res = copy_process(PF_KTHREAD,
   84af0:	aa1303e2 	mov	x2, x19
   84af4:	aa1603e3 	mov	x3, x22
   84af8:	aa1503e1 	mov	x1, x21
   84afc:	91000673 	add	x19, x19, #0x1
   84b00:	d2800040 	mov	x0, #0x2                   	// #2
   84b04:	97fffd99 	bl	84168 <copy_process>
        BUG_ON(res < 0);
   84b08:	36fffe60 	tbz	w0, #31, 84ad4 <test_kern_tasks_donut+0x44>
   84b0c:	aa1803e1 	mov	x1, x24
   84b10:	aa1703e0 	mov	x0, x23
   84b14:	52802902 	mov	w2, #0x148                 	// #328
   84b18:	97fff390 	bl	81958 <assertion_failed>
    for (int i=0; i<N_DONUTS; i++) {
   84b1c:	f100667f 	cmp	x19, #0x19
   84b20:	54fffde1 	b.ne	84adc <test_kern_tasks_donut+0x4c>  // b.any
	// current we are on the "init" task. 
	// if we allow this function to return to kernel_main() which procceeds to wait(), 
	// and our sleep() (called by wait()) is yet to function, the kernel will crash there. so we just keep
	// the init task to keep yielding here forever. 	
	while (1)
        	yield();
   84b24:	97fffc3b 	bl	83c10 <yield>
   84b28:	97fffc3a 	bl	83c10 <yield>
	while (1)
   84b2c:	17fffffe 	b	84b24 <test_kern_tasks_donut+0x94>

0000000000084b30 <uart_send>:
#define AUX_MU_BAUD_REG (PBASE+0x00215068)

// busy wait
void uart_send (char c) {
	while(1) {
		if(get32(AUX_MU_LSR_REG) & 0x20) 
   84b30:	d28a0a82 	mov	x2, #0x5054                	// #20564
void uart_send (char c) {
   84b34:	12001c00 	and	w0, w0, #0xff
		if(get32(AUX_MU_LSR_REG) & 0x20) 
   84b38:	f2a7e422 	movk	x2, #0x3f21, lsl #16
   84b3c:	d503201f 	nop
   84b40:	b9400041 	ldr	w1, [x2]
   84b44:	362fffe1 	tbz	w1, #5, 84b40 <uart_send+0x10>
			break;
	}
	put32(AUX_MU_IO_REG, c);
   84b48:	d28a0801 	mov	x1, #0x5040                	// #20544
   84b4c:	f2a7e421 	movk	x1, #0x3f21, lsl #16
   84b50:	b9000020 	str	w0, [x1]
}
   84b54:	d65f03c0 	ret

0000000000084b58 <uart_recv>:
 
// busy wait
char uart_recv (void) {
	while(1) {
		if(get32(AUX_MU_LSR_REG) & 0x01) 
   84b58:	d28a0a81 	mov	x1, #0x5054                	// #20564
   84b5c:	f2a7e421 	movk	x1, #0x3f21, lsl #16
   84b60:	b9400020 	ldr	w0, [x1]
   84b64:	3607ffe0 	tbz	w0, #0, 84b60 <uart_recv+0x8>
			break;
	}
	return(get32(AUX_MU_IO_REG) & 0xFF);
   84b68:	d28a0800 	mov	x0, #0x5040                	// #20544
   84b6c:	f2a7e420 	movk	x0, #0x3f21, lsl #16
   84b70:	b9400000 	ldr	w0, [x0]
}
   84b74:	d65f03c0 	ret

0000000000084b78 <uart_send_string>:

void uart_send_string(char* str) {
	for (int i = 0; str[i] != '\0'; i ++) {
   84b78:	39400002 	ldrb	w2, [x0]
   84b7c:	34000182 	cbz	w2, 84bac <uart_send_string+0x34>
		if(get32(AUX_MU_LSR_REG) & 0x20) 
   84b80:	d28a0a81 	mov	x1, #0x5054                	// #20564
	put32(AUX_MU_IO_REG, c);
   84b84:	d28a0804 	mov	x4, #0x5040                	// #20544
   84b88:	91000403 	add	x3, x0, #0x1
		if(get32(AUX_MU_LSR_REG) & 0x20) 
   84b8c:	f2a7e421 	movk	x1, #0x3f21, lsl #16
	put32(AUX_MU_IO_REG, c);
   84b90:	f2a7e424 	movk	x4, #0x3f21, lsl #16
   84b94:	d503201f 	nop
		if(get32(AUX_MU_LSR_REG) & 0x20) 
   84b98:	b9400020 	ldr	w0, [x1]
   84b9c:	362fffe0 	tbz	w0, #5, 84b98 <uart_send_string+0x20>
	put32(AUX_MU_IO_REG, c);
   84ba0:	b9000082 	str	w2, [x4]
	for (int i = 0; str[i] != '\0'; i ++) {
   84ba4:	38401462 	ldrb	w2, [x3], #1
   84ba8:	35ffff82 	cbnz	w2, 84b98 <uart_send_string+0x20>
		uart_send((char)str[i]);
	}
}
   84bac:	d65f03c0 	ret

0000000000084bb0 <putc>:
		if(get32(AUX_MU_LSR_REG) & 0x20) 
   84bb0:	d28a0a82 	mov	x2, #0x5054                	// #20564

// This function is required by printf function
void putc ( void* p, char c) {
   84bb4:	12001c21 	and	w1, w1, #0xff
		if(get32(AUX_MU_LSR_REG) & 0x20) 
   84bb8:	f2a7e422 	movk	x2, #0x3f21, lsl #16
   84bbc:	d503201f 	nop
   84bc0:	b9400040 	ldr	w0, [x2]
   84bc4:	362fffe0 	tbz	w0, #5, 84bc0 <putc+0x10>
	put32(AUX_MU_IO_REG, c);
   84bc8:	d28a0800 	mov	x0, #0x5040                	// #20544
   84bcc:	f2a7e420 	movk	x0, #0x3f21, lsl #16
   84bd0:	b9000001 	str	w1, [x0]
	uart_send(c);
}
   84bd4:	d65f03c0 	ret

0000000000084bd8 <uart_init>:

    // code below also showcases how to configure GPIO pins
    // cf: https://github.com/bztsrc/raspi3-tutorial/blob/master/03_uart1/uart.c#L45

    // select gpio functions for pin14,15. note 3bits per pin.
    selector = get32(GPFSEL1);
   84bd8:	d2800082 	mov	x2, #0x4                   	// #4
void uart_init(void) {
   84bdc:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
    selector = get32(GPFSEL1);
   84be0:	f2a7e402 	movk	x2, #0x3f20, lsl #16
void uart_init(void) {
   84be4:	910003fd 	mov	x29, sp
    selector = get32(GPFSEL1);
   84be8:	b9400041 	ldr	w1, [x2]

    // Below: set up GPIO pull modes. protocol recommended by the bcm2837 manual
    //    (pg 101, "GPIO Pull-up/down Clock Registers")
    // We need neither the pull-up nor the pull-down state, because both
    //  the 14 and 15 pins are going to be connected all the time.
    put32(GPPUD, 0); // disable pull up/down control (for pins below)
   84bec:	d2801283 	mov	x3, #0x94                  	// #148
   84bf0:	f2a7e403 	movk	x3, #0x3f20, lsl #16
    selector |= 2 << 15;    // set alt5 for gpio15
   84bf4:	52840004 	mov	w4, #0x2000                	// #8192
   84bf8:	120e6421 	and	w1, w1, #0xfffc0fff
void uart_init(void) {
   84bfc:	f9000bf3 	str	x19, [sp, #16]
    selector |= 2 << 15;    // set alt5 for gpio15
   84c00:	72a00024 	movk	w4, #0x1, lsl #16
   84c04:	2a040021 	orr	w1, w1, w4
    put32(GPFSEL1, selector);
   84c08:	b9000041 	str	w1, [x2]
    delay(150);
    // "control the actuation of internal pull-downs on the respective GPIO pins."
    put32(GPPUDCLK0, (1 << 14) | (1 << 15)); // "clock the control signal into the GPIO pads"
   84c0c:	d2801313 	mov	x19, #0x98                  	// #152
    put32(GPPUD, 0); // disable pull up/down control (for pins below)
   84c10:	b900007f 	str	wzr, [x3]
    put32(GPPUDCLK0, (1 << 14) | (1 << 15)); // "clock the control signal into the GPIO pads"
   84c14:	f2a7e413 	movk	x19, #0x3f20, lsl #16
    delay(150);
   84c18:	d28012c0 	mov	x0, #0x96                  	// #150
   84c1c:	940004d9 	bl	85f80 <delay>
    put32(GPPUDCLK0, (1 << 14) | (1 << 15)); // "clock the control signal into the GPIO pads"
   84c20:	52980000 	mov	w0, #0xc000                	// #49152
   84c24:	b9000260 	str	w0, [x19]
    delay(150);
   84c28:	d28012c0 	mov	x0, #0x96                  	// #150
   84c2c:	940004d5 	bl	85f80 <delay>
    put32(GPPUDCLK0, 0);               // remote the clock, flush GPIO setup
   84c30:	b900027f 	str	wzr, [x19]
    put32(AUX_MU_IIR_REG, FLUSH_UART); // flush FIFO
   84c34:	d28a0901 	mov	x1, #0x5048                	// #20552

    put32(AUX_ENABLES, 1);     // Enable mini uart (this also enables access to it registers)
   84c38:	d28a0082 	mov	x2, #0x5004                	// #20484
    put32(AUX_MU_IIR_REG, FLUSH_UART); // flush FIFO
   84c3c:	f2a7e421 	movk	x1, #0x3f21, lsl #16
    put32(AUX_ENABLES, 1);     // Enable mini uart (this also enables access to it registers)
   84c40:	f2a7e422 	movk	x2, #0x3f21, lsl #16
    put32(AUX_MU_CNTL_REG, 0); // Disable auto flow control and disable receiver and transmitter (for now)
   84c44:	d28a0c00 	mov	x0, #0x5060                	// #20576
    put32(AUX_MU_IIR_REG, FLUSH_UART); // flush FIFO
   84c48:	528018c3 	mov	w3, #0xc6                  	// #198
    put32(AUX_MU_CNTL_REG, 0); // Disable auto flow control and disable receiver and transmitter (for now)
   84c4c:	f2a7e420 	movk	x0, #0x3f21, lsl #16

    put32(AUX_MU_IER_REG, 0);                     // Disable receive and transmit interrupts
    put32(AUX_MU_IER_REG, (3 << 2) | (0xf << 4)); // bit 7:4 3:2 must be 1

    put32(AUX_MU_LCR_REG, 3);    // Enable 8 bit mode
    put32(AUX_MU_MCR_REG, 0);    // Set RTS line to be always high
   84c50:	d28a0a04 	mov	x4, #0x5050                	// #20560
    put32(AUX_MU_BAUD_REG, 270); // Set baud rate to 115200

    put32(AUX_MU_CNTL_REG, 3); // Finally, enable transmitter and receiver
}
   84c54:	f9400bf3 	ldr	x19, [sp, #16]
    put32(AUX_MU_IIR_REG, FLUSH_UART); // flush FIFO
   84c58:	b9000023 	str	w3, [x1]
    put32(AUX_MU_IER_REG, 0);                     // Disable receive and transmit interrupts
   84c5c:	d28a0881 	mov	x1, #0x5044                	// #20548
    put32(AUX_ENABLES, 1);     // Enable mini uart (this also enables access to it registers)
   84c60:	52800023 	mov	w3, #0x1                   	// #1
    put32(AUX_MU_IER_REG, 0);                     // Disable receive and transmit interrupts
   84c64:	f2a7e421 	movk	x1, #0x3f21, lsl #16
    put32(AUX_ENABLES, 1);     // Enable mini uart (this also enables access to it registers)
   84c68:	b9000043 	str	w3, [x2]
    put32(AUX_MU_LCR_REG, 3);    // Enable 8 bit mode
   84c6c:	d28a0983 	mov	x3, #0x504c                	// #20556
    put32(AUX_MU_CNTL_REG, 0); // Disable auto flow control and disable receiver and transmitter (for now)
   84c70:	b900001f 	str	wzr, [x0]
    put32(AUX_MU_LCR_REG, 3);    // Enable 8 bit mode
   84c74:	f2a7e423 	movk	x3, #0x3f21, lsl #16
    put32(AUX_MU_IER_REG, (3 << 2) | (0xf << 4)); // bit 7:4 3:2 must be 1
   84c78:	52801f82 	mov	w2, #0xfc                  	// #252
    put32(AUX_MU_IER_REG, 0);                     // Disable receive and transmit interrupts
   84c7c:	b900003f 	str	wzr, [x1]
    put32(AUX_MU_MCR_REG, 0);    // Set RTS line to be always high
   84c80:	f2a7e424 	movk	x4, #0x3f21, lsl #16
    put32(AUX_MU_IER_REG, (3 << 2) | (0xf << 4)); // bit 7:4 3:2 must be 1
   84c84:	b9000022 	str	w2, [x1]
    put32(AUX_MU_BAUD_REG, 270); // Set baud rate to 115200
   84c88:	d28a0d02 	mov	x2, #0x5068                	// #20584
    put32(AUX_MU_LCR_REG, 3);    // Enable 8 bit mode
   84c8c:	52800061 	mov	w1, #0x3                   	// #3
    put32(AUX_MU_BAUD_REG, 270); // Set baud rate to 115200
   84c90:	f2a7e422 	movk	x2, #0x3f21, lsl #16
    put32(AUX_MU_LCR_REG, 3);    // Enable 8 bit mode
   84c94:	b9000061 	str	w1, [x3]
    put32(AUX_MU_BAUD_REG, 270); // Set baud rate to 115200
   84c98:	528021c3 	mov	w3, #0x10e                 	// #270
    put32(AUX_MU_MCR_REG, 0);    // Set RTS line to be always high
   84c9c:	b900009f 	str	wzr, [x4]
    put32(AUX_MU_BAUD_REG, 270); // Set baud rate to 115200
   84ca0:	b9000043 	str	w3, [x2]
    put32(AUX_MU_CNTL_REG, 3); // Finally, enable transmitter and receiver
   84ca4:	b9000001 	str	w1, [x0]
}
   84ca8:	a8c27bfd 	ldp	x29, x30, [sp], #32
   84cac:	d65f03c0 	ret
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
   85784:	d10483ff 	sub	sp, sp, #0x120
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
   85824:	910483ff 	add	sp, sp, #0x120
   85828:	d69f03e0 	eret

000000000008582c <sync_invalid_el1t>:

/* ------ "default" entries, behavior: print error msg & hang ----*/
sync_invalid_el1t:
	handle_invalid_entry  SYNC_INVALID_EL1t
   8582c:	d10483ff 	sub	sp, sp, #0x120
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
   85898:	d10483ff 	sub	sp, sp, #0x120
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
   85904:	d10483ff 	sub	sp, sp, #0x120
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
   85970:	d10483ff 	sub	sp, sp, #0x120
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
   859dc:	d10483ff 	sub	sp, sp, #0x120
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
   85a48:	d10483ff 	sub	sp, sp, #0x120
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
   85ab4:	d10483ff 	sub	sp, sp, #0x120
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
   85b20:	d10483ff 	sub	sp, sp, #0x120
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
   85b8c:	d10483ff 	sub	sp, sp, #0x120
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
   85bf8:	d10483ff 	sub	sp, sp, #0x120
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
   85c64:	d10483ff 	sub	sp, sp, #0x120
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
   85cd0:	d10483ff 	sub	sp, sp, #0x120
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
   85d3c:	d10483ff 	sub	sp, sp, #0x120
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
   85da8:	d10483ff 	sub	sp, sp, #0x120
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
   85e14:	d10483ff 	sub	sp, sp, #0x120
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
   85e80:	97fff6c0 	bl	83980 <leave_scheduler>
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
