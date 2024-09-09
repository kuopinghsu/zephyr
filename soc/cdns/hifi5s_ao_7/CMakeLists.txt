# SPDX-License-Identifier: Apache-2.0

zephyr_include_directories(include)

set(SOC_LINKER_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/include/hifi5s_ao_7.ld CACHE INTERNAL "")
