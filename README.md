# Guide for installing, setting up and building Zephyr Xtensa LX7, LX8 and LX8-SMP configs

> [!NOTE]
> The Zephyr RTOS port for Xtensa is available and supported by the Zephyr community.
> Therefore, any issues with running the RTOS on Xtensa should be addressed through the community support channel,
> on which multiple Tensilica users maintain an active presence. Cadence will assist in areas that appear to be caused
> by the Tensilica CPU or SDK but note that as Cadence does not directly maintain the Zephyr port, assistance from both
> the customer and the open-source community will likely be required.

> [!CAUTION]
> **This guide and the associated Zephyr patches for running Zephyr on Xtensa are provided for evaluation purposes only.**

## Supported configurations

This generic porting supports single-core (LX7, LX8) and multi-core SMP (LX8-SMP) Xtensa configurations
via the `foss-xtensa/common` branch. The HiFi5s configs below are used as representative examples.

| Architecture | Config type          | Example `XTENSA_CORE` | SMP |
|--------------|----------------------|-----------------------|-----|
| LX7          | Single-core          | *(user-specific)*     | No  |
| LX8          | Single-core          | `hifi5s_ao_7`        | No  |
| LX8-SMP      | Multi-core (2-core)  | `hifi5s_2c_l2`       | Yes |
| LX8-SMP      | Multi-core (4-core)  | `hifi5s_4c_l2`       | Yes |

## Configuration prerequisites

The Xtensa configurable architecture supports a vast space of processor features.
However, a minimum set of hardware capabilities is required for Zephyr to function correctly.

### Single-core requirements

* At least **one** hardware timer, with its interrupt level **≤ EXCM_LEVEL** (LX cores)
* At least **one** SW interrupt, at level **≤ EXCM_LEVEL** (LX cores)

### Additional requirements for multi-core (SMP)

* At least **one** set of Inter-Processor Interrupts (IPI); the **first** set must be at level **≤ EXCM_LEVEL** (recommended: all sets at ≤ EXCM_LEVEL)
* IPI interrupts **must** be configured as **edge-triggered**

### Zephyr-specific requirements and known issues

> [!IMPORTANT]
> **Minimum interrupt levels:** The configuration must use **at least 2 interrupt levels**.
> Configurations with only a single interrupt level are not supported.
> See [zephyr#84453](https://github.com/zephyrproject-rtos/zephyr/issues/84453) for details.

> [!WARNING]
> **SW interrupts above EXCM_LEVEL:** Configurations that have **one or more SW interrupts
> at a level > EXCM_LEVEL** are affected by a known issue:
>
> - Zephyr selects such an interrupt for internal use, but then only masks interrupts
>   up to `EXCM_LEVEL` during internal processing — leaving the high-level SW interrupt
>   unguarded and potentially causing incorrect behaviour.
> - **Resolution:** Customer configurations may need to be modified so that all SW interrupts
>   are at level ≤ EXCM_LEVEL, or a local patch must be applied.
>   See [zephyr#87483](https://github.com/zephyrproject-rtos/zephyr/pull/87483) for the patch and discussion.

## Installing and building Zephyr

This section contains a condensed guide for installing, setting up and building Zephyr using Xtensa SDK; find the full guide at:
https://docs.zephyrproject.org/latest/develop/getting_started/index.html

- Make sure we are using bash; if not type `bash` at the command prompt.
- Export needed environment variables, setting `XTENSA_CORE` to your target configuration:
```
export SHELL=/bin/bash
export XTENSA_SYSTEM='/path/to/xtensa/XtDevTools/install/tools/RJ-2026.6-linux/XtensaTools/config'
export XTENSA_CORE='hifi5s_ao_7'    # LX8 single-core example  (replace with your core)
# export XTENSA_CORE='hifi5s_2c_l2' # LX8-SMP 2-core example
# export XTENSA_CORE='hifi5s_4c_l2' # LX8-SMP 4-core example
export ZEPHYR_TOOLCHAIN_VARIANT='xt-clang'
export TOOLCHAIN_VER=RJ-2026.6-linux
export XTENSA_TOOLCHAIN_PATH="${XTENSA_SYSTEM}/../../.."
export PATH="${XTENSA_SYSTEM}/../Tools/bin/:${XTENSA_SYSTEM}/../bin:${PATH}"
```
- Create workspace and activate python3 environment:
```
cd ~
mkdir zephyrproject
python3 -m venv ~/zephyrproject/.venv
source ~/zephyrproject/.venv/bin/activate
```
- Install newer cmake (Optional if version >= 3.20.5):
```
pip install cmake
```
- Get Zephyr sources and install Python dependencies:
```
pip install west
west init ~/zephyrproject
cd ~/zephyrproject
west update
west zephyr-export
pip install -r ~/zephyrproject/zephyr/scripts/requirements.txt
```
- Checkout zephyr patch for LX7/LX8/LX8-SMP config support:
```
cd zephyr/
git remote add foss-xtensa https://github.com/foss-xtensa/zephyr
git fetch foss-xtensa
git checkout foss-xtensa/common -b common
west update
```

Above steps complete installing and setting up Zephyr using Xtensa SDK (ie: toolchain).
Note that installing the Software Development Kit (SDK) provided by the Zephyr project is optional:
https://docs.zephyrproject.org/latest/develop/getting_started/installation_linux.html#building-on-linux-without-the-zephyr-sdk

## Building Zephyr projects

This section lists steps to build Zephyr projects using Xtensa SDK.

- Activate python3 environment (Must be done only when we start working and the shell prompt is not yet prefixed with (.venv)):
```
source ~/zephyrproject/.venv/bin/activate
```
- Export needed environment variables (Must be done only when we start working):
```
export SHELL=/bin/bash
export XTENSA_SYSTEM='/path/to/xtensa/XtDevTools/install/tools/RJ-2026.6-linux/XtensaTools/config'
export XTENSA_CORE='hifi5s_ao_7'    # LX8 single-core example  (replace with your core)
# export XTENSA_CORE='hifi5s_2c_l2' # LX8-SMP 2-core example
# export XTENSA_CORE='hifi5s_4c_l2' # LX8-SMP 4-core example
export ZEPHYR_TOOLCHAIN_VARIANT='xt-clang'
export TOOLCHAIN_VER=RJ-2026.6-linux
export XTENSA_TOOLCHAIN_PATH="${XTENSA_SYSTEM}/../../.."
export PATH="${XTENSA_SYSTEM}/../Tools/bin/:${XTENSA_SYSTEM}/../bin:${PATH}"
```

### Single-core build (LX7 / LX8)

- Build sample project:
```
cd ~/zephyrproject/zephyr/
west build -b xt-sim samples/hello_world
```
- Execute sample project:
```
xt-run build/zephyr/zephyr.elf
```
- Clean project:
```
rm -rf build
```

### SMP build (LX8-SMP)

- Build sample project:
```
cd ~/zephyrproject/zephyr/
west build -b xt-sim samples/arch/smp/pi
```

#### SMP build configuration

For SMP builds, `CONFIG_SMP` and `CONFIG_MP_MAX_NUM_CPUS` must match the
number of cores in your Xtensa subsystem (`XCHAL_SUBSYS_NUM_CORES`).
They can be set in two equivalent ways:

**Option 1 — `prj.conf`** (add to the sample's or your application's conf file):
```
# prj.conf — enable SMP with N cores
CONFIG_SMP=y
CONFIG_MP_MAX_NUM_CPUS=4   # match XCHAL_SUBSYS_NUM_CORES for your core
```

**Option 2 — command-line override** (pass via `--` after the west build target):
```
west build -b xt-sim samples/arch/smp/pi -- \
    -DCONFIG_SMP=y -DCONFIG_MP_MAX_NUM_CPUS=4
```

> [!NOTE]
> `CONFIG_MP_MAX_NUM_CPUS` must be ≤ `XCHAL_SUBSYS_NUM_CORES` of the
> selected `XTENSA_CORE`. SMP samples (`samples/arch/smp/*`) require a
> multi-core configuration — they will not build for single-core targets.

- Generate xtsc subsystem:
```
mkdir -p build/subsys
cp $(xt-clang --show-config=config)/examples/MP_Subsystem/xt_sysbuilder_mp/subsys.yml build/subsys/
$(xt-clang --show-config=xttools)/libexec/xt-sysbuilder \
-xtensa-system ${XTENSA_SYSTEM} \
-subsys build/subsys/subsys.yml \
-swtools $(xt-clang --show-config=xttools) \
-build build/subsys
```
- Execute sample project — use the `xtsc-run` invocation matching your core count:

  **2-core (e.g. `hifi5s_2c_l2`):**
```
xtsc-run \
--define=DSP_0_BINARY=build/zephyr/zephyr.elf \
--define=DSP_1_BINARY=build/zephyr/zephyr.elf \
--include=build/subsys/xtsc-run/SubSystem.inc
```
  **4-core (e.g. `hifi5s_4c_l2`):**
```
xtsc-run \
--define=DSP_0_BINARY=build/zephyr/zephyr.elf \
--define=DSP_1_BINARY=build/zephyr/zephyr.elf \
--define=DSP_2_BINARY=build/zephyr/zephyr.elf \
--define=DSP_3_BINARY=build/zephyr/zephyr.elf \
--include=build/subsys/xtsc-run/SubSystem.inc
```
- Clean project:
```
rm -rf build
```

This concludes the how-to-guide for installing, setting up and building Zephyr using Xtensa SDK.
