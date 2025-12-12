/*
 * Copyright (c) 2024 Qualcomm Innovation Center, Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr/kernel.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/sys/printk.h>

/* Thread stack sizes */
#define STACKSIZE 1024

/* Thread priorities */
#define THREAD0_PRIORITY 7
#define THREAD1_PRIORITY 7

/* GPIO specifications from device tree */
#define LED0_NODE DT_ALIAS(led0)
#define LED1_NODE DT_ALIAS(led1)

#if !DT_NODE_HAS_STATUS(LED0_NODE, okay)
#error "Unsupported board: led0 devicetree alias is not defined or enabled"
#endif

#if !DT_NODE_HAS_STATUS(LED1_NODE, okay)
#error "Unsupported board: led1 devicetree alias is not defined or enabled"
#endif

static const struct gpio_dt_spec led0 = GPIO_DT_SPEC_GET(LED0_NODE, gpios);
static const struct gpio_dt_spec led1 = GPIO_DT_SPEC_GET(LED1_NODE, gpios);

/* Thread 0: Toggle LED0/GPIO at 1Hz */
void thread0_entry(void *p1, void *p2, void *p3)
{
	ARG_UNUSED(p1);
	ARG_UNUSED(p2);
	ARG_UNUSED(p3);

	int ret;

	printk("Thread 0 started - GPIO %d (LED0) toggling at 1Hz\n", led0.pin);

	ret = gpio_pin_configure_dt(&led0, GPIO_OUTPUT_ACTIVE);
	if (ret < 0) {
		printk("Error %d: failed to configure LED0 pin %d\n", ret, led0.pin);
		return;
	}

	while (1) {
		gpio_pin_toggle_dt(&led0);
		k_msleep(500);  /* Toggle every 500ms = 1Hz square wave */
	}
}

/* Thread 1: Toggle LED1/GPIO at 2Hz */
void thread1_entry(void *p1, void *p2, void *p3)
{
	ARG_UNUSED(p1);
	ARG_UNUSED(p2);
	ARG_UNUSED(p3);

	int ret;

	printk("Thread 1 started - GPIO %d (LED1) toggling at 2Hz\n", led1.pin);

	ret = gpio_pin_configure_dt(&led1, GPIO_OUTPUT_ACTIVE);
	if (ret < 0) {
		printk("Error %d: failed to configure LED1 pin %d\n", ret, led1.pin);
		return;
	}

	while (1) {
		gpio_pin_toggle_dt(&led1);
		k_msleep(250);  /* Toggle every 250ms = 2Hz square wave */
	}
}

/* Define and initialize threads */
K_THREAD_DEFINE(thread0_id, STACKSIZE, thread0_entry, NULL, NULL, NULL,
		THREAD0_PRIORITY, 0, 0);

K_THREAD_DEFINE(thread1_id, STACKSIZE, thread1_entry, NULL, NULL, NULL,
		THREAD1_PRIORITY, 0, 0);

int main(void)
{
	printk("\n");
	printk("╔════════════════════════════════════════╗\n");
	printk("║  Zephyr RTOS Dual-Thread GPIO Blinky  ║\n");
	printk("║  EVK-QCC748M-2-01-0-AA                 ║\n");
	printk("╚════════════════════════════════════════╝\n");
	printk("\n");

	if (!gpio_is_ready_dt(&led0)) {
		printk("Error: LED0 device %s is not ready\n", led0.port->name);
		return 0;
	}

	if (!gpio_is_ready_dt(&led1)) {
		printk("Error: LED1 device %s is not ready\n", led1.port->name);
		return 0;
	}

	printk("GPIO devices ready\n");
	printk("LED0: GPIO %d - 1Hz (500ms period)\n", led0.pin);
	printk("LED1: GPIO %d - 2Hz (250ms period)\n", led1.pin);
	printk("\n");
	printk("Connect logic analyzer to observe:\n");
	printk("  Channel 1: GPIO %d (1Hz square wave)\n", led0.pin);
	printk("  Channel 2: GPIO %d (2Hz square wave)\n", led1.pin);
	printk("\n");

	/* Threads are auto-started by K_THREAD_DEFINE */
	printk("Threads started. Press Ctrl+] to exit monitor.\n");

	return 0;
}
