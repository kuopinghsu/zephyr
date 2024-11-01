# Guide for installing, setting up and building Zephyr hifi5s_2c_l2 config

> [!NOTE]
> The Zephyr RTOS port for Xtensa is available and supported by the Zephyr community.
> Therefore, any issues with running the RTOS on Xtensa should be addressed through the community support channel,
> on which multiple Tensilica users maintain an active presence. Cadence will assist in areas that appear to be caused
> by the Tensilica CPU or SDK but note that as Cadence does not directly maintain the Zephyr port, assistance from both
> the customer and the open-source community will likely be required.

> [!CAUTION]
> **This guide and the associated Zephyr patches for running Zephyr SMP on Xtensa are provided for evaluation purposes only.**

## Installing and building Zephyr

This section contains a condensed guide for installing, setting up and building Zephyr using Xtensa SDK; find the full guide at:
https://docs.zephyrproject.org/latest/develop/getting_started/index.html

- Make sure we are using bash; if not type `bash` at the command prompt.
- Export needed environment variables:
```
export SHELL=/bin/bash
export XTENSA_SYSTEM='/path/to/xtensa/XtDevTools/install/tools/RJ-2025.5-linux/XtensaTools/config'
export XTENSA_CORE='hifi5s_2c_l2'
export ZEPHYR_TOOLCHAIN_VARIANT='xt-clang'
export TOOLCHAIN_VER=RJ-2025.5-linux
export XTENSA_TOOLCHAIN_PATH="${XTENSA_SYSTEM}/../../.."
export PATH="${XTENSA_SYSTEM}/../Tools/bin/:${XTENSA_SYSTEM}/../bin:${PATH}"
```
- Create workspace and active python3 environment:
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
- Checkout zephyr patch for HiFi5s config support:
```
cd zephyr/
git remote add foss-xtensa https://github.com/foss-xtensa/zephyr
git fetch foss-xtensa
git checkout foss-xtensa/hifi5s_2c_l2 -b hifi5s_2c_l2
west update
```

Above steps complete installing and setting up Zephyr using Xtensa SDK (ie: toolchain).
Note that installing the Software Development Kit (SDK) provided by the Zephyr project is optional:
https://docs.zephyrproject.org/latest/develop/getting_started/installation_linux.html#building-on-linux-without-the-zephyr-sdk

## Building Zephyr projects

This section lists steps to build Zephyr projects using Xtensa SDK.

- Activate python3 environment (Must be done only when we start working and the shell prompt is not yet prefixed with (.venv):
```
source ~/zephyrproject/.venv/bin/activate
```
- Export needed environment variables (Must be done only when we start working):
```
export SHELL=/bin/bash
export XTENSA_SYSTEM='/path/to/xtensa/XtDevTools/install/tools/RJ-2025.5-linux/XtensaTools/config'
export XTENSA_CORE='hifi5s_2c_l2'
export ZEPHYR_TOOLCHAIN_VARIANT='xt-clang'
export TOOLCHAIN_VER=RJ-2025.5-linux
export XTENSA_TOOLCHAIN_PATH="${XTENSA_SYSTEM}/../../.."
export PATH="${XTENSA_SYSTEM}/../Tools/bin/:${XTENSA_SYSTEM}/../bin:${PATH}"
```
- Build sample project:
```
cd ~/zephyrproject/zephyr/
west build -b xt-sim samples/arch/smp/pi
```
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
- Execute sample project:
```
xtsc-run \
--define=DSP_0_BINARY=build/zephyr/zephyr.elf \
--define=DSP_1_BINARY=build/zephyr/zephyr.elf \
--include=build/subsys/xtsc-run/SubSystem.inc
```
- Clean project:
```
rm -rf build
```

This concludes the how-to-guide for installing, setting up and building Zephyr using Xtensa SDK.
