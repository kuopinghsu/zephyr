# SPDX-License-Identifier: Apache-2.0

zephyr_library()

zephyr_library_sources(
  libc-hooks.c
  multithreading.c
)

zephyr_include_directories(include)
