# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.20.0)

# Try to find Zephyr, but don't fail if not found
find_package(Zephyr QUIET HINTS $ENV{ZEPHYR_BASE})

if(Zephyr_FOUND)
    project(zephyr_gpio_blinky)
    target_sources(app PRIVATE src/main.c)
else()
    message(WARNING "Zephyr SDK not found - this is a Zephyr RTOS project")
    message(STATUS "Install Zephyr: https://docs.zephyrproject.org/latest/getting_started/")
    project(zephyr_gpio_blinky NONE)
endif()
