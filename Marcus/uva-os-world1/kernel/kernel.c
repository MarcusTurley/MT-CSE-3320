// #define K2_DEBUG_VERBOSE
#define K2_DEBUG_WARN

#include <stddef.h>
#include <stdint.h>

#include "plat.h"
#include "utils.h"
#include "sched.h"

extern void test_ktimer();     // unittests.c
extern void test_fb_voffset(); // unittests.c
extern void donut();           // donut.c
extern void donut_simple();    // donut.c
extern void donut_text();      // donut.c

void uart_send_string(char* str);

struct cpu cpus[NCPU]; 

void kernel_main() {
	/* Initialize UART and printf */
	uart_init();
	init_printf(NULL, putc);

	// Display boot message
	printf("------ kernel boot ------  core %d\n\r", cpuid());
	printf("build time (kernel.c) %s %s\n", __DATE__, __TIME__); // simplicity 

	//Setup timer
	sys_timer_init();                   // kernel timer: delay, timekeeping...
	
	// Enable interrupt controller for this core
	enable_interrupt_controller(0);     // coreid
	// Enable CPU IRQs
    enable_irq();

	generic_timer_init();               // periodic ticks alive

	if (fb_init() != 0) BUG();          // will show the OS logo

	// test_ktimer();
	test_fb_voffset();               // cycle through color quads

	// donut_simple();
	// donut_text();
	// donut();

	while (1)
		asm volatile("wfi");            // what happen here?
}