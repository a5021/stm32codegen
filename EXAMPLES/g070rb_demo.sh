#!/bin/bash

set -euo pipefail  # Exit on error, undefined vars, pipe failures
IFS=$'\n\t'        # Safer field splitting

ORIGINAL_DIR="$(pwd)"

# === Error Handling ===
cleanup() {
    local exit_code=$?

    # Capture ERR context if available
    if [[ ${__err_line:-} ]]; then
        echo "ERROR at line $__err_line: $__err_command failed" >&2
    fi

    if [ $exit_code -ne 0 ]; then
        echo "" >&2
        echo "====================================" >&2
        echo "Script failed - returning to $ORIGINAL_DIR" >&2
        echo "====================================" >&2
    fi

    cd "$ORIGINAL_DIR" 2>/dev/null || true
    exit $exit_code
}

# Store ERR context for cleanup
trap '__err_line=$LINENO; __err_command=$BASH_COMMAND' ERR
trap cleanup EXIT

VERBOSE="${VERBOSE:-0}"
DEBUG="${DEBUG:-0}"

[ "$VERBOSE" = "1" ] && set -x

cd "$(dirname "${BASH_SOURCE[0]}")"

base_dir=$(basename "$0" .sh)

# Array with directory names
directories=("inc" "src" "MDK-ARM")
op_counter=0

check_dependencies() {
    local missing=()

    for cmd in curl arm-none-eabi-gcc make; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "Error: Missing required tools: ${missing[*]}" >&2
        echo "" >&2
        echo "Installation instructions:" >&2
        echo "  Debian/Ubuntu: sudo apt-get install ${missing[*]}" >&2
        echo "  Red Hat/CentOS: sudo yum install ${missing[*]}" >&2
        exit 1
    fi
}

press_any_key() {
    echo -n "Press any key to continue..."
    # read one character of input and discard it
    read -n 1 -s -r || true
    echo ""
}

check_dependencies

# Function to check for the existence of a directory and create it if it doesn't exist
create_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        if mkdir "$dir"; then
            ((++op_counter))
            echo "Directory $dir created."
        else
            echo "Error: Failed to create directory $dir" >&2
            exit 1
        fi
    fi
}

# Create directories
create_directory "$base_dir" && cd "$base_dir"

for dir in "${directories[@]}"
do
  create_directory "$dir"
done

cd "${directories[0]}"

PY_GEN="$(realpath "${PY_GEN:-../../..}")"

py_name=''

# Detect Python
case $(uname -s | tr '[:upper:]' '[:lower:]') in
    linux*|darwin*)  py_name='python3' ;;
    *)               py_name='python' ;;  # Windows and others
esac

# Verify Python works
if ! command -v "$py_name" &>/dev/null; then
    echo "Error: $py_name not found" >&2
    exit 1
fi

force_inline=--force-inline
func_name=init_systick
PY_GEN_PY="$PY_GEN"
if command -v cygpath &>/dev/null; then
    py_path="$(command -v "$py_name")"
    case "$py_path" in
        /usr/bin/*|/bin/*) ;;  # Cygwin Python — keep cygwin path
        *) PY_GEN_PY="$(cygpath -w "$PY_GEN")" ;;  # Windows Python — convert
    esac
fi
py_gen=("$py_name" "$PY_GEN_PY/stm32cgen.py")

# Validate stm32cgen.py exists and is readable
if [ ! -f "$PY_GEN/stm32cgen.py" ]; then
    echo "Error: stm32cgen.py not found at $PY_GEN" >&2
    echo "Current PY_GEN=$PY_GEN" >&2
    exit 1
fi

generate_header() {
    local output_file="$1"
    shift  # Remove first argument

    if "${py_gen[@]}" "$@" > "$output_file"; then
        echo "File $output_file created."
        ((++op_counter))
    else
        echo "Error: Failed to generate $output_file" >&2
        exit 1
    fi
}

# URLs for files
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_g0/master/Source/Templates/system_stm32g0xx.c
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_g0/master/Source/Templates/gcc/startup_stm32g070xx.s
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_g0/master/Source/Templates/arm/startup_stm32g070xx.s
#
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_g0/master/Include/system_stm32g0xx.h
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_g0/master/Include/stm32g0xx.h
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_g0/master/Include/stm32g070xx.h
#
#               https://github.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include
#
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_compiler.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_armclang.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_gcc.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_iccarm.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_version.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/core_cm0plus.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_armcc.h
#
#    https://raw.githubusercontent.com/cmsis-svd/cmsis-svd-data/refs/heads/main/data/STMicro/STM32G070.svd

fname1=("system_stm32g0xx.c" "startup_stm32g070xx.s")
fname2=("system_stm32g0xx.h" "stm32g0xx.h" "stm32g070xx.h")
fname3=("cmsis_compiler.h" "cmsis_armclang.h" "cmsis_gcc.h" "cmsis_iccarm.h" "cmsis_version.h" "core_cm0plus.h" "cmsis_armcc.h" "mpu_armv7.h")

raw_github="https://raw.githubusercontent.com/"

url1="${raw_github}STMicroelectronics/cmsis-device-g0/refs/heads/master"
url2="${raw_github}ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/"
url3="${raw_github}cmsis-svd/cmsis-svd-data/refs/heads/main/data/STMicro/STM32G070.svd"

# Function to check if a file exists and download it if it doesn't
download_file() {
    local url="$1"
    local dest="$2"

    if [ ! -f "$dest" ]; then
        if curl -fsSL "$url" | tr -cd '\11\12\15\40-\176' > "$dest"; then
            if [ -s "$dest" ]; then  # Check file is not empty
                ((++op_counter))
                echo "File $dest downloaded."
            else
                echo "Error: Downloaded file $dest is empty" >&2
                rm -f "$dest"
                return 1
            fi
        else
            echo "Error: Failed to download $url" >&2
            return 1
        fi
    fi
}

# Download the CMSIS device header for G070RB (needed by -l local generation)
# NOTE: we are currently inside ${directories[0]} (inc), so use bare filename
download_file "${url1}/Include/${fname2[2]}" "${fname2[2]}"

if [ -e ${fname2[2]} ]; then
    # File exists
    opt=-l
else
    # File does not exist
    opt=-s
fi

generate_header "main.h" $opt g070rb -M\
    -D NO                     0\
       NONE                   NO\
       OFF                    NO\
       YES                    \(\!NO\)\
       ON                     YES\
       ""\
       HCLK                   "64   /* 16 to 64 (MHz) with a step of 4 */"\
       ""\
       SYSTICK_CLOCK_SOURCE   "0    /* 0 = HCLK / 8; 1 = HCLK         */"\
       SYSTICK_ENABLE         YES\
       SYSTICK_IRQ_ENABLE     NO\
    \
    -H "#if HCLK < 16 || HCLK > 64 || (HCLK % 4 != 0)"\
    -H "  #error \"Invalid HCLK value. Must be between 16 and 64 MHz with a step of 4 MHz.\""\
    -H \#endif\
    \
    $force_inline\
    --post-init $func_name\
    -F ""\
    -F "__STATIC_FORCEINLINE void $func_name(void) {"\
    -F ""\
    -F "  /* Initialize SysTick to 1 ms period */"\
    -F ""\
    -F "  SysTick->LOAD = HCLK * 1000 / (8 - SYSTICK_CLOCK_SOURCE * 7) - 1;"\
    -F "  SysTick->VAL  = SysTick->LOAD;"\
    -F "  SysTick->CTRL = ("\
    -F "    + SYSTICK_CLOCK_SOURCE * SysTick_CTRL_CLKSOURCE_Msk"\
    -F "    + SYSTICK_IRQ_ENABLE   * SysTick_CTRL_TICKINT_Msk"\
    -F "    + SYSTICK_ENABLE       * SysTick_CTRL_ENABLE_Msk"\
    -F "  );"\
    -F "} /* $func_name() */"\
    -F ""\
    -F ""\
    -F "__STATIC_FORCEINLINE void idle(void); // {"\
    -F "  /* Routine to handle idle state (waiting for an event) */"\
    -F ""\
    -F ""\
    -F "//} /* idle() */"\
    -F ""\
    -F ""\
    -F "__STATIC_FORCEINLINE unsigned process(void); // {"\
    -F "  /* Routine to perform main loop operations */"\
    -F ""\
    -F ""\
    -F "//} /* process() */"\
    -F ""\
    -F "#if YES == SYSTICK_IRQ_ENABLE"\
    -F "  #define __SYSTICK_VOLATILE volatile"\
    -F "#else"\
    -F "  #define __SYSTICK_VOLATILE"\
    -F "#endif"\
    -F ""\
    -F "#if defined(__GNUC__) && ! defined(__clang__)" \
    -F "  __attribute__((used)) int _close(int fd)                          { (void)fd; return -1; }" \
    -F "  __attribute__((used)) int _lseek(int fd, int offset, int whence)  { (void)fd; (void)offset; (void)whence; return -1; }" \
    -F "  __attribute__((used)) int _read(int fd, char *buf, int len)       { (void)fd; (void)buf; (void)len; return -1; }" \
    -F "  __attribute__((used)) int _write(int fd, const char *buf, int len) { (void)fd; (void)buf; (void)len; return -1; }" \
    -F \#endif

func_name=setup_sysclk
tag=R
generate_header "rcc.h" -l g070rb -p RCC -m rcc -f init_rcc\
    \
    --exclude-register CR CFGR PLLCFGR\
    \
    -D $tag '(HCLK >= 32)'\
       ""\
       PLLN_VAL "(HCLK / 4)        /* HSE 8MHz: 8/1*PLLN/2 = HCLK */"\
    \
    $force_inline\
    --pre-init configure_flash\
    --post-init $func_name\
    -F "__STATIC_FORCEINLINE void configure_flash(void) {"\
    -F "  #if (HCLK > 48)"\
    -F "    /* G0: 2 wait states for >48MHz */"\
    -F "    FLASH->ACR = FLASH_ACR_LATENCY_2;"\
    -F "  #elif (HCLK > 24)"\
    -F "    /* G0: 1 wait state for 24-48MHz */"\
    -F "    FLASH->ACR = FLASH_ACR_LATENCY_1;"\
    -F "  #endif"\
    -F "}"\
    -F ""\
    -F "__STATIC_FORCEINLINE void $func_name(void) {"\
    -F "  #if $tag"\
    -F "    /* HSE 8 MHz: PLLM=1, PLLN=HCLK/4, PLLR=2 => 8/1*PLLN/2 = HCLK */"\
    -F "    RCC->CR |= RCC_CR_HSEON;"\
    -F "    while(!(RCC->CR & RCC_CR_HSERDY)) {}"\
    -F "    RCC->PLLCFGR = ("\
    -F "      RCC_PLLCFGR_PLLSRC_HSE"\
    -F "    | RCC_PLLCFGR_PLLR_0"\
    -F "    | RCC_PLLCFGR_PLLREN"\
    -F "    | (PLLN_VAL << RCC_PLLCFGR_PLLN_Pos)"\
    -F "    );"\
    -F "    RCC->CR |= RCC_CR_PLLON;"\
    -F "    while(!(RCC->CR & RCC_CR_PLLRDY)) {}"\
    -F "    RCC->CFGR |= RCC_CFGR_SW_PLLRCLK;"\
    -F "    while(RCC_CFGR_SWS_PLLRCLK != (RCC->CFGR & RCC_CFGR_SWS)) {}"\
    -F "  #else"\
    -F "    /* HSI16 direct: 16 MHz */"\
    -F "    RCC->CR |= RCC_CR_HSION;"\
    -F "    while(!(RCC->CR & RCC_CR_HSIRDY)) {}"\
    -F "  #endif"\
    -F "} /* $func_name() */"\
    -F ""\
    -F "#undef $tag"

"${py_gen[@]}" -l g070rb -p GPIOC -m gpio -f init_gpio\
    --exclude-register IDR LCKR\
    -D USE_ANALOG_MODE_FOR_ALL_PINS_BY_DEFAULT 1\
       ""\
       GPIO_MODE "(USE_ANALOG_MODE_FOR_ALL_PINS_BY_DEFAULT * UINT32_MAX)"\
       PIN_XOR "(GPIO_MODE & 3UL)"\
       ""\
       PIN_MODE_INPUT "(0x00UL ^ PIN_XOR)"\
       PIN_MODE_OUTPUT "(0x01UL ^ PIN_XOR)"\
       PIN_MODE_AF "(0x02UL ^ PIN_XOR)"\
       PIN_MODE_ANALOG "(0x03UL ^ PIN_XOR)"\
       ""\
       "PIN_CFG(PIN, MODE)" "((MODE)   << ((PIN) * 2))"\
       "PIN_MODE(PIN, MODE)" "(((MODE)  << GPIO_MODER_MODE ## PIN ## _Pos) & GPIO_MODER_MODE ## PIN ## _Msk)"\
       "PIN_SPEED(PIN, SPEED)" "(((SPEED) << GPIO_OSPEEDR_OSPEED ## PIN ## _Pos) & GPIO_OSPEEDR_OSPEED ## PIN ## _Msk)"\
       "PIN_OTYPE(PIN, OTYPE)" "((OTYPE)   ? GPIO_OTYPER_OT ## PIN : 0)"\
       "PIN_PUPD(PIN, PUPD)" "(((PUPD)  << GPIO_PUPDR_PUPD ## PIN ## _Pos) & GPIO_PUPDR_PUPD ## PIN ## _Msk)"\
       "PIN_AF(PIN, AF)" "(AF << (PIN * 4))"\
       ""\
        PC13_AF0_TIM14_CH1 "PIN_AF(13, 0ULL)"\
        PC14_AF0_RTC_CALIB "PIN_AF(14, 0ULL)"\
        PC15_AF0_RTC_CALIB "PIN_AF(15, 0ULL)"\
       ""\
       PIN_TYPE_PP 0x00UL\
       PIN_TYPE_OD 0x01UL\
       ""\
       PIN_SPEED_LOW 0x00UL\
       PIN_SPEED_MED 0x01UL\
       PIN_SPEED_HIGH 0x03UL\
       ""\
       PIN_PUPD_NONE 0x00UL\
       PIN_PUPD_UP 0x01UL\
       PIN_PUPD_DOWN 0x02UL\
       ""\
       _BR\(PIN\) "GPIO_BSRR_BR ## PIN"\
       BR\(PIN\) _BR\(PIN\)\
       _BS\(PIN\) "GPIO_BSRR_BS ## PIN"\
       BS\(PIN\) _BS\(PIN\)\
       _ODR\(PIN\) "GPIO_ODR_OD ## PIN"\
       ODR\(PIN\) _ODR\(PIN\)\
       ""\
       GPIOC_MODER "(GPIO_MODE ^ (GPIOC_MODE))"\
       ""\
       GPIOC_AFR_0 "(GPIOC_AF & UINT32_MAX)"\
       GPIOC_AFR_1 "((GPIOC_AF >> 32) & UINT32_MAX)"\
    \
    -H ""\
    -H "#define CONFIGURE_PIN(GPIOx, PIN, MODE, OTYPE, SPEED, PUPD) do {                               \\"\
    -H "  if (MODE)   MODIFY_REG((GPIOx)->MODER,   (0x03UL << ((PIN) * 2)), ((MODE)  << ((PIN) * 2))); \\"\
    -H "  if (SPEED)  MODIFY_REG((GPIOx)->OSPEEDR, (0x03UL << ((PIN) * 2)), ((SPEED) << ((PIN) * 2))); \\"\
    -H "  if (PUPD)   MODIFY_REG((GPIOx)->PUPDR,   (0x03UL << ((PIN) * 2)), ((PUPD)  << ((PIN) * 2))); \\"\
    -H "  if (OTYPE)  MODIFY_REG((GPIOx)->OTYPER,  (0x01UL << (PIN)),       ((OTYPE) << (PIN)));       \\"\
    -H }while\(0\)\
    -H ""\
    -H '#define GPIOC_MODE (                                                    \'\
    -H '  !0         * PIN_MODE(8, PIN_MODE_OUTPUT) /* PC8 -- LED (active low) */ \'\
    -H ')'\
    -H ""\
    -H "#define GPIOC_AF (0ULL)"\
    -H ""\
    -H '#define GPIOC_OSPEED (                                                \'\
    -H '  !0         * PIN_SPEED(8, PIN_SPEED_LOW)  /* PC8 -- LED (active low) */ \'\
    -H ')'\
    \
    $force_inline\
    --no-def\
    > gpio.h

# Check if the previous command was successful
status=$?
if [ $status -eq 0 ]
then
    echo "File gpio.h created."
else
    echo "Creation of gpio.h failed with status $status"
fi

cd ..

create_file() {
    local filename="$1"

    if [ ! -f "$filename" ]; then
        if cat > "$filename"; then
            if [ -s "$filename" ]; then  # Check file is not empty
                ((++op_counter))
                echo "File $filename created."
            else
                echo "Error: $filename is empty after creation" >&2
                rm -f "$filename"
                return 1
            fi
        else
            echo "Error: Failed to create $filename" >&2
            return 1
        fi
    fi
}

# Embedded Makefile (here-doc)
create_file "Makefile" << 'EOF'
# Define the target name and build directory.
TARGET    := Project
BUILD_DIR := _build

.DEFAULT_GOAL := all

$(shell mkdir -p $(BUILD_DIR))

SRC := $(wildcard ./src/*.c)
ASM := $(wildcard ./src/*.s)

TOOLCHAIN := $(if $(GCC_PATH),$(GCC_PATH)/,)arm-none-eabi-

Q = $(if $(findstring $(space),$(1)),"$(1)",$(1))

CC = $(call Q,$(TOOLCHAIN)gcc)
LD = $(call Q,$(TOOLCHAIN)ld)
AS = $(call Q,$(TOOLCHAIN)gcc) -x assembler-with-cpp
CP = $(call Q,$(TOOLCHAIN)objcopy)
SZ = $(call Q,$(TOOLCHAIN)size)

space := $(subst ,, )

HEX = $(CP) -O ihex
BIN = $(CP) -O binary -S

MCU = -mcpu=cortex-m0plus -mthumb
DEF = -DSTM32G070xx
INC = -I./inc

FLG := $(MCU) $(DEF) $(INC)

FLG += -std=gnu11
FLG += -Wall -Werror -Wextra -Wpedantic
FLG += -fdata-sections -ffunction-sections -fverbose-asm
FLG += -MMD -MP
FLG += -fno-common

LDS := stm32g070xx_flash.ld
LIB := -lc -lm -lnosys
LDF := $(MCU) -specs=nano.specs -T$(LDS) $(LIB) -Wl,-Map=$(BUILD_DIR)/$(TARGET).map
LDF += -Wl,--cref,--gc-sections,--print-memory-usage

OPT = -Os -g0 -DNDEBUG

ifeq ($(findstring -flto,$(OPT)), -flto)
  LST =
  LDF += -flto
else
  LST = -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.c=.lst))
endif

FLAG_STAMP := $(BUILD_DIR)/.flags
$(FLAG_STAMP): Makefile
	@echo 'FLG=$(FLG)' >  $@.tmp
	@echo 'LDF=$(LDF)' >> $@.tmp
	@echo 'OPT=$(OPT)' >> $@.tmp
	@cmp -s $@.tmp $@ || mv $@.tmp $@
	@rm -f $@.tmp

JLINK_FLAGS = -openprj./stm32g070xx.jflash -open$(BUILD_DIR)/$(TARGET).hex -hide -auto -exit -jflashlog./jflash.log

ifeq ($(OS), Windows_NT)
    FLG += -D WIN32
    ifeq ($(PROCESSOR_ARCHITEW6432), AMD64)
        FLG += -D AMD64
    else
        ifeq ($(PROCESSOR_ARCHITECTURE), AMD64)
            FLG += -D AMD64
        endif
        ifeq ($(PROCESSOR_ARCHITECTURE), x86)
            FLG += -D IA32
        endif
    endif
    STLINK ?= ST-LINK_CLI.exe
    STLINK_FLAGS = -c UR -V -P $(BUILD_DIR)/$(TARGET).hex -Rst -Run
    JLINK ?= JFlash.Exe
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S), Linux)
        FLG += -D LINUX
    endif
    ifeq ($(UNAME_S), Darwin)
        FLG += -D OSX
    endif
    UNAME_P := $(shell uname -p)
    ifeq ($(UNAME_P), x86_64)
        FLG += -D AMD64
    endif
    ifneq ($(filter %86, $(UNAME_P)),)
        FLG += -D IA32
    endif
    ifneq ($(filter arm%, $(UNAME_P)),)
        FLG += -D ARM
    endif
    STLINK ?= st-flash
    STLINK_FLAGS = --reset --format ihex write $(BUILD_DIR)/$(TARGET).hex
    JLINK ?= JFlashExe
endif

GCC_INFO    := $(shell $(CC) -dumpfullversion 2>/dev/null | awk -F. '{print $$0, ($$1*10000+$$2*100+$$3>=120000)}')
GCC_VERSION := $(word 1,$(GCC_INFO))
GCC_GE_12   := $(word 2,$(GCC_INFO))

LD_INFO     := $(shell $(LD) --version 2>/dev/null | awk '/^GNU ld/ {match($$NF,/([0-9]+)\.([0-9]+)/,v); print v[0], (v[1]*100+v[2]>=239); exit}')
LD_VERSION  := $(word 1,$(LD_INFO))
LD_GE_2_39  := $(word 2,$(LD_INFO))

$(info using GCC $(GCC_VERSION), Binutils $(LD_VERSION))

ifneq ($(or $(filter 1,$(GCC_GE_12)),$(filter 1,$(LD_GE_2_39))),)
  LDF += -Wl,--no-warn-rwx-segments
endif

all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/$(TARGET).bin

OBJ = $(addprefix $(BUILD_DIR)/,$(notdir $(SRC:.c=.o)))
vpath %.c $(sort $(dir $(SRC)))
OBJ += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM:.s=.o)))
vpath %.s $(sort $(dir $(ASM)))

DEP := $(OBJ:.o=.d)

$(BUILD_DIR)/%.o: %.c Makefile $(FLAG_STAMP) | $(BUILD_DIR)
	$(CC) -c $(FLG) $(OPT) -MF"$(@:%.o=%.d)" $(LST) $< -o $@

$(BUILD_DIR)/%.o: %.s Makefile $(FLAG_STAMP) | $(BUILD_DIR)
	$(AS) -c $(FLG) $(OPT) $< -o $@

$(BUILD_DIR)/$(TARGET).elf: $(OBJ) Makefile
	$(CC) $(OBJ) $(OPT) $(LDF) -o $@

$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(HEX) $< $@

$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(BIN) $< $@

size: $(BUILD_DIR)/$(TARGET).elf
	$(SZ) $<

$(BUILD_DIR):
	mkdir -p $@

debug:	OPT = -Og -g3 -gdwarf
debug:	all

clean:
	-rm -fR $(BUILD_DIR)

.PHONY: clean all size

gccversion :
	@$(CC) --version

program: $(BUILD_DIR)/$(TARGET).hex
	$(STLINK) $(STLINK_FLAGS)

jprogram: $(BUILD_DIR)/$(TARGET).hex
	$(JLINK) $(JLINK_FLAGS)

-include $(DEP)

EOF

create_file "stm32g070xx_flash.ld" << 'EOF'
/* Entry Point */
ENTRY(Reset_Handler)

/* Highest address of the user mode stack */
_estack = 0x20009000;    /* end of RAM (36KB) */

/* Generate a link error if heap and stack don't fit into RAM */
_Min_Heap_Size = 0x0;    /* required amount of heap  */
_Min_Stack_Size = 0x200; /* required amount of stack */

/* Specify the memory areas */
MEMORY
{
    RAM (xrw)      : ORIGIN = 0x20000000, LENGTH = 36K
    FLASH (rx)      : ORIGIN = 0x8000000, LENGTH = 128K
}

/* Define output sections */
SECTIONS
{
    /* The startup code goes first into FLASH */
    .isr_vector :
    {
        . = ALIGN(4);
        KEEP(*(.isr_vector)) /* Startup code */
        . = ALIGN(4);
    } >FLASH

    /* The program code and other data goes into FLASH */
    .text :
    {
        . = ALIGN(4);
        *(.text)           /* .text sections (code) */
        *(.text*)          /* .text* sections (code) */
        *(.glue_7)         /* glue arm to thumb code */
        *(.glue_7t)        /* glue thumb to arm code */
        *(.eh_frame)

        KEEP (*(.init))
        KEEP (*(.fini))

        . = ALIGN(4);
        _etext = .;        /* define a global symbols at end of code */
    } >FLASH

    /* Constant data goes into FLASH */
    .rodata :
    {
        . = ALIGN(4);
        *(.rodata)         /* .rodata sections (constants, strings, etc.) */
        *(.rodata*)        /* .rodata* sections (constants, strings, etc.) */
        . = ALIGN(4);
    } >FLASH

    .ARM.extab   : { *(.ARM.extab* .gnu.linkonce.armextab.*) } >FLASH
    .ARM : {
        __exidx_start = .;
        *(.ARM.exidx*)
        __exidx_end = .;
    } >FLASH

    .preinit_array     :
    {
        PROVIDE_HIDDEN (__preinit_array_start = .);
        KEEP (*(.preinit_array*))
        PROVIDE_HIDDEN (__preinit_array_end = .);
    } >FLASH

    .init_array :
    {
        PROVIDE_HIDDEN (__init_array_start = .);
        KEEP (*(SORT(.init_array.*)))
        KEEP (*(.init_array*))
        PROVIDE_HIDDEN (__init_array_end = .);
    } >FLASH

    .fini_array :
    {
        PROVIDE_HIDDEN (__fini_array_start = .);
        KEEP (*(SORT(.fini_array.*)))
        KEEP (*(.fini_array*))
        PROVIDE_HIDDEN (__fini_array_end = .);
    } >FLASH

    /* used by the startup to initialize data */
    _sidata = LOADADDR(.data);

    /* Initialized data sections goes into RAM after program code */
    .data :
    {
        . = ALIGN(4);
        _sdata = .;        /* create a global symbol at data start */
        *(.data)           /* .data sections */
        *(.data*)          /* .data* sections */

        . = ALIGN(4);
        _edata = .;        /* define a global symbol at data end */
    } >RAM AT> FLASH

    /* Uninitialized data section */
    . = ALIGN(4);
    .bss :
    {
        /* This is used by the startup in order to initialize the .bss section */
        _sbss = .;         /* define a global symbol at bss start */
        __bss_start__ = _sbss;
        *(.bss)
        *(.bss*)
        *(COMMON)

        . = ALIGN(4);
        _ebss = .;         /* define a global symbol at bss end */
        __bss_end__ = _ebss;
    } >RAM

    /* Remove information from the compiler libraries */
    /DISCARD/ :
    {
        libc.a ( * )
        libm.a ( * )
        libgcc.a ( * )
    }

    .ARM.attributes 0 : { *(.ARM.attributes) }
}

EOF

create_file "MDK-ARM/Project.uvprojx" << 'EOF'
<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<Project xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="project_projx.xsd">

  <SchemaVersion>2.1</SchemaVersion>

  <Header>### uVision Project, (C) Keil Software</Header>

  <Targets>
    <Target>
      <TargetName>Debug</TargetName>
      <ToolsetNumber>0x4</ToolsetNumber>
      <ToolsetName>ARM-ADS</ToolsetName>
      <uAC6>1</uAC6>
      <TargetOption>
        <TargetCommonOption>
          <Device>STM32G070RB</Device>
          <Vendor>STMicroelectronics</Vendor>
          <Cpu>IRAM(0x20000000,0x00009000) IROM(0x08000000,0x00020000) CPUTYPE("Cortex-M0+") CLOCK(64000000) ELITTLE</Cpu>
          <FlashUtilSpec></FlashUtilSpec>
          <StartupFile></StartupFile>
          <FlashDriverDll></FlashDriverDll>
          <DeviceId></DeviceId>
          <RegisterFile></RegisterFile>
          <MemoryEnv></MemoryEnv>
          <Cmp></Cmp>
          <Asm></Asm>
          <Linker></Linker>
          <OHString></OHString>
          <InfinionOptionDll></InfinionOptionDll>
          <SLE66CMisc></SLE66CMisc>
          <SLE66AMisc></SLE66AMisc>
          <SLE66LinkerMisc></SLE66LinkerMisc>
          <SFDFile>..\STM32G070.svd</SFDFile>
          <bCustSvd>0</bCustSvd>
          <UseEnv>0</UseEnv>
          <BinPath></BinPath>
          <IncludePath></IncludePath>
          <LibPath></LibPath>
          <RegisterFilePath></RegisterFilePath>
          <DBRegisterFilePath></DBRegisterFilePath>
          <TargetStatus>
            <Error>0</Error>
            <ExitCodeStop>0</ExitCodeStop>
            <ButtonStop>0</ButtonStop>
            <NotGenerated>0</NotGenerated>
            <InvalidFlash>1</InvalidFlash>
          </TargetStatus>
          <OutputDirectory>.\Objects\</OutputDirectory>
          <OutputName>Project</OutputName>
          <CreateExecutable>1</CreateExecutable>
          <CreateLib>0</CreateLib>
          <CreateHexFile>1</CreateHexFile>
          <DebugInformation>1</DebugInformation>
          <BrowseInformation>1</BrowseInformation>
          <ListingPath>.\Listings\</ListingPath>
          <HexFormatSelection>1</HexFormatSelection>
          <Merge32K>0</Merge32K>
          <CreateBatchFile>0</CreateBatchFile>
          <BeforeCompile>
            <RunUserProg1>0</RunUserProg1>
            <RunUserProg2>0</RunUserProg2>
            <UserProg1Name></UserProg1Name>
            <UserProg2Name></UserProg2Name>
            <UserProg1Dos16Mode>0</UserProg1Dos16Mode>
            <UserProg2Dos16Mode>0</UserProg2Dos16Mode>
            <nStopU1X>0</nStopU1X>
            <nStopU2X>0</nStopU2X>
          </BeforeCompile>
          <BeforeMake>
            <RunUserProg1>0</RunUserProg1>
            <RunUserProg2>0</RunUserProg2>
            <UserProg1Name></UserProg1Name>
            <UserProg2Name></UserProg2Name>
            <UserProg1Dos16Mode>0</UserProg1Dos16Mode>
            <UserProg2Dos16Mode>0</UserProg2Dos16Mode>
            <nStopB1X>0</nStopB1X>
            <nStopB2X>0</nStopB2X>
          </BeforeMake>
          <AfterMake>
            <RunUserProg1>0</RunUserProg1>
            <RunUserProg2>0</RunUserProg2>
            <UserProg1Name></UserProg1Name>
            <UserProg2Name></UserProg2Name>
            <UserProg1Dos16Mode>0</UserProg1Dos16Mode>
            <UserProg2Dos16Mode>0</UserProg2Dos16Mode>
            <nStopA1X>0</nStopA1X>
            <nStopA2X>0</nStopA2X>
          </AfterMake>
          <SelectedForBatchBuild>0</SelectedForBatchBuild>
          <SVCSIdString></SVCSIdString>
        </TargetCommonOption>
        <CommonProperty>
          <UseCPPCompiler>0</UseCPPCompiler>
          <RVCTCodeConst>0</RVCTCodeConst>
          <RVCTZI>0</RVCTZI>
          <RVCTOtherData>0</RVCTOtherData>
          <ModuleSelection>0</ModuleSelection>
          <IncludeInBuild>1</IncludeInBuild>
          <AlwaysBuild>0</AlwaysBuild>
          <GenerateAssemblyFile>0</GenerateAssemblyFile>
          <AssembleAssemblyFile>0</AssembleAssemblyFile>
          <PublicsOnly>0</PublicsOnly>
          <StopOnExitCode>3</StopOnExitCode>
          <CustomArgument></CustomArgument>
          <IncludeLibraryModules></IncludeLibraryModules>
          <ComprImg>1</ComprImg>
        </CommonProperty>
        <DllOption>
          <SimDllName>SARMCM3.DLL</SimDllName>
          <SimDllArguments> -REMAP </SimDllArguments>
          <SimDlgDll>DARMCM1.DLL</SimDlgDll>
          <SimDlgDllArguments>-pCM0plus</SimDlgDllArguments>
          <TargetDllName>SARMCM3.DLL</TargetDllName>
          <TargetDllArguments> </TargetDllArguments>
          <TargetDlgDll>TARMCM1.DLL</TargetDlgDll>
          <TargetDlgDllArguments>-pCM0plus</TargetDlgDllArguments>
        </DllOption>
        <DebugOption>
          <OPTHX>
            <HexSelection>1</HexSelection>
            <HexRangeLowAddress>0</HexRangeLowAddress>
            <HexRangeHighAddress>0</HexRangeHighAddress>
            <HexOffset>0</HexOffset>
            <Oh166RecLen>16</Oh166RecLen>
          </OPTHX>
        </DebugOption>
        <Utilities>
          <Flash1>
            <UseTargetDll>1</UseTargetDll>
            <UseExternalTool>0</UseExternalTool>
            <RunIndependent>0</RunIndependent>
            <UpdateFlashBeforeDebugging>1</UpdateFlashBeforeDebugging>
            <Capability>1</Capability>
            <DriverSelection>4096</DriverSelection>
          </Flash1>
          <bUseTDR>1</bUseTDR>
          <Flash2>BIN\UL2CM3.DLL</Flash2>
          <Flash3></Flash3>
          <Flash4></Flash4>
          <pFcarmOut></pFcarmOut>
          <pFcarmGrp></pFcarmGrp>
          <pFcArmRoot></pFcArmRoot>
          <FcArmLst>0</FcArmLst>
        </Utilities>
        <TargetArmAds>
          <ArmAdsMisc>
            <GenerateListings>0</GenerateListings>
            <asHll>1</asHll>
            <asAsm>1</asAsm>
            <asMacX>1</asMacX>
            <asSyms>1</asSyms>
            <asFals>1</asFals>
            <asDbgD>1</asDbgD>
            <asForm>1</asForm>
            <ldLst>0</ldLst>
            <ldmm>1</ldmm>
            <ldXref>1</ldXref>
            <BigEnd>0</BigEnd>
            <AdsALst>1</AdsALst>
            <AdsACrf>1</AdsACrf>
            <AdsANop>0</AdsANop>
            <AdsANot>0</AdsANot>
            <AdsLLst>1</AdsLLst>
            <AdsLmap>1</AdsLmap>
            <AdsLcgr>1</AdsLcgr>
            <AdsLsym>1</AdsLsym>
            <AdsLszi>1</AdsLszi>
            <AdsLtoi>1</AdsLtoi>
            <AdsLsun>1</AdsLsun>
            <AdsLven>1</AdsLven>
            <AdsLsxf>1</AdsLsxf>
            <RvctClst>0</RvctClst>
            <GenPPlst>0</GenPPlst>
            <AdsCpuType>"Cortex-M0+"</AdsCpuType>
            <RvctDeviceName></RvctDeviceName>
            <mOS>0</mOS>
            <uocRom>0</uocRom>
            <uocRam>0</uocRam>
            <hadIROM>1</hadIROM>
            <hadIRAM>1</hadIRAM>
            <hadXRAM>0</hadXRAM>
            <uocXRam>0</uocXRam>
            <RvdsVP>0</RvdsVP>
            <RvdsMve>0</RvdsMve>
            <RvdsCdeCp>0</RvdsCdeCp>
            <hadIRAM2>0</hadIRAM2>
            <hadIROM2>0</hadIROM2>
            <StupSel>8</StupSel>
            <useUlib>1</useUlib>
            <EndSel>0</EndSel>
            <uLtcg>0</uLtcg>
            <nSecure>0</nSecure>
            <RoSelD>3</RoSelD>
            <RwSelD>3</RwSelD>
            <CodeSel>0</CodeSel>
            <OptFeed>0</OptFeed>
            <NoZi1>0</NoZi1>
            <NoZi2>0</NoZi2>
            <NoZi3>0</NoZi3>
            <NoZi4>0</NoZi4>
            <NoZi5>0</NoZi5>
            <Ro1Chk>0</Ro1Chk>
            <Ro2Chk>0</Ro2Chk>
            <Ro3Chk>0</Ro3Chk>
            <Ir1Chk>1</Ir1Chk>
            <Ir2Chk>0</Ir2Chk>
            <Ra1Chk>0</Ra1Chk>
            <Ra2Chk>0</Ra2Chk>
            <Ra3Chk>0</Ra3Chk>
            <Im1Chk>1</Im1Chk>
            <Im2Chk>0</Im2Chk>
            <OnChipMemories>
              <Ocm1>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm1>
              <Ocm2>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm2>
              <Ocm3>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm3>
              <Ocm4>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm4>
              <Ocm5>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm5>
              <Ocm6>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm6>
              <IRAM>
                <Type>0</Type>
                <StartAddress>0x20000000</StartAddress>
                <Size>0x9000</Size>
              </IRAM>
              <IROM>
                <Type>1</Type>
                <StartAddress>0x8000000</StartAddress>
                <Size>0x20000</Size>
              </IROM>
              <XRAM>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </XRAM>
              <OCR_RVCT1>
                <Type>1</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT1>
              <OCR_RVCT2>
                <Type>1</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT2>
              <OCR_RVCT3>
                <Type>1</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT3>
              <OCR_RVCT4>
                <Type>1</Type>
                <StartAddress>0x8000000</StartAddress>
                <Size>0x20000</Size>
              </OCR_RVCT4>
              <OCR_RVCT5>
                <Type>1</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT5>
              <OCR_RVCT6>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT6>
              <OCR_RVCT7>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT7>
              <OCR_RVCT8>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT8>
              <OCR_RVCT9>
                <Type>0</Type>
                <StartAddress>0x20000000</StartAddress>
                <Size>0x9000</Size>
              </OCR_RVCT9>
              <OCR_RVCT10>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT10>
            </OnChipMemories>
            <RvctStartVector></RvctStartVector>
          </ArmAdsMisc>
          <Cads>
            <interw>1</interw>
            <Optim>1</Optim>
            <oTime>0</oTime>
            <SplitLS>0</SplitLS>
            <OneElfS>1</OneElfS>
            <Strict>0</Strict>
            <EnumInt>0</EnumInt>
            <PlainCh>0</PlainCh>
            <Ropi>0</Ropi>
            <Rwpi>0</Rwpi>
            <wLevel>2</wLevel>
            <uThumb>0</uThumb>
            <uSurpInc>0</uSurpInc>
            <uC99>0</uC99>
            <uGnu>0</uGnu>
            <useXO>0</useXO>
            <v6Lang>6</v6Lang>
            <v6LangP>9</v6LangP>
            <vShortEn>1</vShortEn>
            <vShortWch>1</vShortWch>
            <v6Lto>0</v6Lto>
            <v6WtE>1</v6WtE>
            <v6Rtti>0</v6Rtti>
            <VariousControls>
              <MiscControls>-Wpedantic -Wextra</MiscControls>
              <Define>DEBUG</Define>
              <Undefine></Undefine>
              <IncludePath>../inc</IncludePath>
            </VariousControls>
          </Cads>
          <Aads>
            <interw>1</interw>
            <Ropi>0</Ropi>
            <Rwpi>0</Rwpi>
            <thumb>0</thumb>
            <SplitLS>0</SplitLS>
            <SwStkChk>0</SwStkChk>
            <NoWarn>0</NoWarn>
            <uSurpInc>0</uSurpInc>
            <useXO>0</useXO>
            <ClangAsOpt>1</ClangAsOpt>
            <VariousControls>
              <MiscControls></MiscControls>
              <Define></Define>
              <Undefine></Undefine>
              <IncludePath></IncludePath>
            </VariousControls>
          </Aads>
          <LDads>
            <umfTarg>1</umfTarg>
            <Ropi>0</Ropi>
            <Rwpi>0</Rwpi>
            <noStLib>0</noStLib>
            <RepFail>1</RepFail>
            <useFile>0</useFile>
            <TextAddressRange>0x08000000</TextAddressRange>
            <DataAddressRange>0x20000000</DataAddressRange>
            <pXoBase></pXoBase>
            <ScatterFile></ScatterFile>
            <IncludeLibs></IncludeLibs>
            <IncludeLibsPath></IncludeLibsPath>
            <Misc></Misc>
            <LinkerInputFile></LinkerInputFile>
            <DisabledWarnings></DisabledWarnings>
          </LDads>
        </TargetArmAds>
      </TargetOption>
      <Groups>
        <Group>
          <GroupName>src</GroupName>
          <Files>
            <File>
              <FileName>main.c</FileName>
              <FileType>1</FileType>
              <FilePath>..\src\main.c</FilePath>
            </File>
            <File>
              <FileName>startup_stm32g070xx.s</FileName>
              <FileType>2</FileType>
              <FilePath>..\MDK-ARM\startup_stm32g070xx.s</FilePath>
            </File>
            <File>
              <FileName>system_stm32g0xx.c</FileName>
              <FileType>1</FileType>
              <FilePath>..\src\system_stm32g0xx.c</FilePath>
            </File>
          </Files>
        </Group>
      </Groups>
    </Target>
    <Target>
      <TargetName>Release</TargetName>
      <ToolsetNumber>0x4</ToolsetNumber>
      <ToolsetName>ARM-ADS</ToolsetName>
      <uAC6>1</uAC6>
      <TargetOption>
        <TargetCommonOption>
          <Device>STM32G070RB</Device>
          <Vendor>STMicroelectronics</Vendor>
          <Cpu>IRAM(0x20000000,0x00009000) IROM(0x08000000,0x00020000) CPUTYPE("Cortex-M0+") CLOCK(64000000) ELITTLE</Cpu>
          <FlashUtilSpec></FlashUtilSpec>
          <StartupFile></StartupFile>
          <FlashDriverDll></FlashDriverDll>
          <DeviceId></DeviceId>
          <RegisterFile></RegisterFile>
          <MemoryEnv></MemoryEnv>
          <Cmp></Cmp>
          <Asm></Asm>
          <Linker></Linker>
          <OHString></OHString>
          <InfinionOptionDll></InfinionOptionDll>
          <SLE66CMisc></SLE66CMisc>
          <SLE66AMisc></SLE66AMisc>
          <SLE66LinkerMisc></SLE66LinkerMisc>
          <SFDFile>..\STM32G070.svd</SFDFile>
          <bCustSvd>0</bCustSvd>
          <UseEnv>0</UseEnv>
          <BinPath></BinPath>
          <IncludePath></IncludePath>
          <LibPath></LibPath>
          <RegisterFilePath></RegisterFilePath>
          <DBRegisterFilePath></DBRegisterFilePath>
          <TargetStatus>
            <Error>0</Error>
            <ExitCodeStop>0</ExitCodeStop>
            <ButtonStop>0</ButtonStop>
            <NotGenerated>0</NotGenerated>
            <InvalidFlash>1</InvalidFlash>
          </TargetStatus>
          <OutputDirectory>.\Objects\</OutputDirectory>
          <OutputName>Project</OutputName>
          <CreateExecutable>1</CreateExecutable>
          <CreateLib>0</CreateLib>
          <CreateHexFile>1</CreateHexFile>
          <DebugInformation>0</DebugInformation>
          <BrowseInformation>0</BrowseInformation>
          <ListingPath>.\Listings\</ListingPath>
          <HexFormatSelection>1</HexFormatSelection>
          <Merge32K>0</Merge32K>
          <CreateBatchFile>0</CreateBatchFile>
          <BeforeCompile>
            <RunUserProg1>0</RunUserProg1>
            <RunUserProg2>0</RunUserProg2>
            <UserProg1Name></UserProg1Name>
            <UserProg2Name></UserProg2Name>
            <UserProg1Dos16Mode>0</UserProg1Dos16Mode>
            <UserProg2Dos16Mode>0</UserProg2Dos16Mode>
            <nStopU1X>0</nStopU1X>
            <nStopU2X>0</nStopU2X>
          </BeforeCompile>
          <BeforeMake>
            <RunUserProg1>0</RunUserProg1>
            <RunUserProg2>0</RunUserProg2>
            <UserProg1Name></UserProg1Name>
            <UserProg2Name></UserProg2Name>
            <UserProg1Dos16Mode>0</UserProg1Dos16Mode>
            <UserProg2Dos16Mode>0</UserProg2Dos16Mode>
            <nStopB1X>0</nStopB1X>
            <nStopB2X>0</nStopB2X>
          </BeforeMake>
          <AfterMake>
            <RunUserProg1>0</RunUserProg1>
            <RunUserProg2>0</RunUserProg2>
            <UserProg1Name></UserProg1Name>
            <UserProg2Name></UserProg2Name>
            <UserProg1Dos16Mode>0</UserProg1Dos16Mode>
            <UserProg2Dos16Mode>0</UserProg2Dos16Mode>
            <nStopA1X>0</nStopA1X>
            <nStopA2X>0</nStopA2X>
          </AfterMake>
          <SelectedForBatchBuild>0</SelectedForBatchBuild>
          <SVCSIdString></SVCSIdString>
        </TargetCommonOption>
        <CommonProperty>
          <UseCPPCompiler>0</UseCPPCompiler>
          <RVCTCodeConst>0</RVCTCodeConst>
          <RVCTZI>0</RVCTZI>
          <RVCTOtherData>0</RVCTOtherData>
          <ModuleSelection>0</ModuleSelection>
          <IncludeInBuild>1</IncludeInBuild>
          <AlwaysBuild>0</AlwaysBuild>
          <GenerateAssemblyFile>0</GenerateAssemblyFile>
          <AssembleAssemblyFile>0</AssembleAssemblyFile>
          <PublicsOnly>0</PublicsOnly>
          <StopOnExitCode>3</StopOnExitCode>
          <CustomArgument></CustomArgument>
          <IncludeLibraryModules></IncludeLibraryModules>
          <ComprImg>1</ComprImg>
        </CommonProperty>
        <DllOption>
          <SimDllName>SARMCM3.DLL</SimDllName>
          <SimDllArguments> -REMAP </SimDllArguments>
          <SimDlgDll>DARMCM1.DLL</SimDlgDll>
          <SimDlgDllArguments>-pCM0plus</SimDlgDllArguments>
          <TargetDllName>SARMCM3.DLL</TargetDllName>
          <TargetDllArguments> </TargetDllArguments>
          <TargetDlgDll>TARMCM1.DLL</TargetDlgDll>
          <TargetDlgDllArguments>-pCM0plus</TargetDlgDllArguments>
        </DllOption>
        <DebugOption>
          <OPTHX>
            <HexSelection>1</HexSelection>
            <HexRangeLowAddress>0</HexRangeLowAddress>
            <HexRangeHighAddress>0</HexRangeHighAddress>
            <HexOffset>0</HexOffset>
            <Oh166RecLen>16</Oh166RecLen>
          </OPTHX>
        </DebugOption>
        <Utilities>
          <Flash1>
            <UseTargetDll>1</UseTargetDll>
            <UseExternalTool>0</UseExternalTool>
            <RunIndependent>0</RunIndependent>
            <UpdateFlashBeforeDebugging>1</UpdateFlashBeforeDebugging>
            <Capability>1</Capability>
            <DriverSelection>4096</DriverSelection>
          </Flash1>
          <bUseTDR>1</bUseTDR>
          <Flash2>BIN\UL2CM3.DLL</Flash2>
          <Flash3>"" ()</Flash3>
          <Flash4></Flash4>
          <pFcarmOut></pFcarmOut>
          <pFcarmGrp></pFcarmGrp>
          <pFcArmRoot></pFcArmRoot>
          <FcArmLst>0</FcArmLst>
        </Utilities>
        <TargetArmAds>
          <ArmAdsMisc>
            <GenerateListings>0</GenerateListings>
            <asHll>1</asHll>
            <asAsm>1</asAsm>
            <asMacX>1</asMacX>
            <asSyms>1</asSyms>
            <asFals>1</asFals>
            <asDbgD>1</asDbgD>
            <asForm>1</asForm>
            <ldLst>0</ldLst>
            <ldmm>1</ldmm>
            <ldXref>1</ldXref>
            <BigEnd>0</BigEnd>
            <AdsALst>0</AdsALst>
            <AdsACrf>1</AdsACrf>
            <AdsANop>0</AdsANop>
            <AdsANot>0</AdsANot>
            <AdsLLst>1</AdsLLst>
            <AdsLmap>1</AdsLmap>
            <AdsLcgr>1</AdsLcgr>
            <AdsLsym>1</AdsLsym>
            <AdsLszi>1</AdsLszi>
            <AdsLtoi>1</AdsLtoi>
            <AdsLsun>1</AdsLsun>
            <AdsLven>1</AdsLven>
            <AdsLsxf>1</AdsLsxf>
            <RvctClst>0</RvctClst>
            <GenPPlst>0</GenPPlst>
            <AdsCpuType>"Cortex-M0+"</AdsCpuType>
            <RvctDeviceName></RvctDeviceName>
            <mOS>0</mOS>
            <uocRom>0</uocRom>
            <uocRam>0</uocRam>
            <hadIROM>1</hadIROM>
            <hadIRAM>1</hadIRAM>
            <hadXRAM>0</hadXRAM>
            <uocXRam>0</uocXRam>
            <RvdsVP>0</RvdsVP>
            <RvdsMve>0</RvdsMve>
            <RvdsCdeCp>0</RvdsCdeCp>
            <hadIRAM2>0</hadIRAM2>
            <hadIROM2>0</hadIROM2>
            <StupSel>8</StupSel>
            <useUlib>1</useUlib>
            <EndSel>0</EndSel>
            <uLtcg>0</uLtcg>
            <nSecure>0</nSecure>
            <RoSelD>3</RoSelD>
            <RwSelD>3</RwSelD>
            <CodeSel>0</CodeSel>
            <OptFeed>0</OptFeed>
            <NoZi1>0</NoZi1>
            <NoZi2>0</NoZi2>
            <NoZi3>0</NoZi3>
            <NoZi4>0</NoZi4>
            <NoZi5>0</NoZi5>
            <Ro1Chk>0</Ro1Chk>
            <Ro2Chk>0</Ro2Chk>
            <Ro3Chk>0</Ro3Chk>
            <Ir1Chk>1</Ir1Chk>
            <Ir2Chk>0</Ir2Chk>
            <Ra1Chk>0</Ra1Chk>
            <Ra2Chk>0</Ra2Chk>
            <Ra3Chk>0</Ra3Chk>
            <Im1Chk>1</Im1Chk>
            <Im2Chk>0</Im2Chk>
            <OnChipMemories>
              <Ocm1>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm1>
              <Ocm2>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm2>
              <Ocm3>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm3>
              <Ocm4>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm4>
              <Ocm5>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm5>
              <Ocm6>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm6>
              <IRAM>
                <Type>0</Type>
                <StartAddress>0x20000000</StartAddress>
                <Size>0x9000</Size>
              </IRAM>
              <IROM>
                <Type>1</Type>
                <StartAddress>0x8000000</StartAddress>
                <Size>0x20000</Size>
              </IROM>
              <XRAM>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </XRAM>
              <OCR_RVCT1>
                <Type>1</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT1>
              <OCR_RVCT2>
                <Type>1</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT2>
              <OCR_RVCT3>
                <Type>1</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT3>
              <OCR_RVCT4>
                <Type>1</Type>
                <StartAddress>0x8000000</StartAddress>
                <Size>0x20000</Size>
              </OCR_RVCT4>
              <OCR_RVCT5>
                <Type>1</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT5>
              <OCR_RVCT6>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT6>
              <OCR_RVCT7>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT7>
              <OCR_RVCT8>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT8>
              <OCR_RVCT9>
                <Type>0</Type>
                <StartAddress>0x20000000</StartAddress>
                <Size>0x9000</Size>
              </OCR_RVCT9>
              <OCR_RVCT10>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT10>
            </OnChipMemories>
            <RvctStartVector></RvctStartVector>
          </ArmAdsMisc>
          <Cads>
            <interw>1</interw>
            <Optim>6</Optim>
            <oTime>0</oTime>
            <SplitLS>0</SplitLS>
            <OneElfS>1</OneElfS>
            <Strict>0</Strict>
            <EnumInt>0</EnumInt>
            <PlainCh>0</PlainCh>
            <Ropi>0</Ropi>
            <Rwpi>0</Rwpi>
            <wLevel>2</wLevel>
            <uThumb>0</uThumb>
            <uSurpInc>0</uSurpInc>
            <uC99>0</uC99>
            <uGnu>0</uGnu>
            <useXO>0</useXO>
            <v6Lang>6</v6Lang>
            <v6LangP>9</v6LangP>
            <vShortEn>1</vShortEn>
            <vShortWch>1</vShortWch>
            <v6Lto>1</v6Lto>
            <v6WtE>1</v6WtE>
            <v6Rtti>0</v6Rtti>
            <VariousControls>
              <MiscControls>-Wpedantic -Wextra</MiscControls>
              <Define>NDEBUG</Define>
              <Undefine></Undefine>
              <IncludePath>../inc</IncludePath>
            </VariousControls>
          </Cads>
          <Aads>
            <interw>1</interw>
            <Ropi>0</Ropi>
            <Rwpi>0</Rwpi>
            <thumb>0</thumb>
            <SplitLS>0</SplitLS>
            <SwStkChk>0</SwStkChk>
            <NoWarn>0</NoWarn>
            <uSurpInc>0</uSurpInc>
            <useXO>0</useXO>
            <ClangAsOpt>1</ClangAsOpt>
            <VariousControls>
              <MiscControls></MiscControls>
              <Define></Define>
              <Undefine></Undefine>
              <IncludePath></IncludePath>
            </VariousControls>
          </Aads>
          <LDads>
            <umfTarg>1</umfTarg>
            <Ropi>0</Ropi>
            <Rwpi>0</Rwpi>
            <noStLib>0</noStLib>
            <RepFail>1</RepFail>
            <useFile>0</useFile>
            <TextAddressRange>0x08000000</TextAddressRange>
            <DataAddressRange>0x20000000</DataAddressRange>
            <pXoBase></pXoBase>
            <ScatterFile></ScatterFile>
            <IncludeLibs></IncludeLibs>
            <IncludeLibsPath></IncludeLibsPath>
            <Misc></Misc>
            <LinkerInputFile></LinkerInputFile>
            <DisabledWarnings></DisabledWarnings>
          </LDads>
        </TargetArmAds>
      </TargetOption>
      <Groups>
        <Group>
          <GroupName>src</GroupName>
          <Files>
            <File>
              <FileName>main.c</FileName>
              <FileType>1</FileType>
              <FilePath>..\src\main.c</FilePath>
            </File>
            <File>
              <FileName>startup_stm32g070xx.s</FileName>
              <FileType>2</FileType>
              <FilePath>..\MDK-ARM\startup_stm32g070xx.s</FilePath>
            </File>
            <File>
              <FileName>system_stm32g0xx.c</FileName>
              <FileType>1</FileType>
              <FilePath>..\src\system_stm32g0xx.c</FilePath>
            </File>
          </Files>
        </Group>
      </Groups>
    </Target>
  </Targets>

  <RTE>
    <apis/>
    <components/>
    <files/>
  </RTE>

  <LayerInfo>
    <Layers>
      <Layer>
        <LayName>Project</LayName>
        <LayPrjMark>1</LayPrjMark>
      </Layer>
    </Layers>
  </LayerInfo>

</Project>

EOF

create_file "project.jdebug" << 'EOF'
void OnProjectLoad (void) {
  Project.AddPathSubstitute (".", "$(ProjectDir)");
  Project.SetDevice ("STM32G070RB");
  Project.SetHostIF ("USB", "");
  Project.SetTargetIF ("SWD");
  Project.SetTIFSpeed ("4 MHz");
  Project.AddSvdFile ("$(InstallDir)/Config/CPU/Cortex-M0+.svd");
  Project.AddSvdFile ("$(InstallDir)/Config/Peripherals/ARMv6M.svd");
  Project.AddSvdFile ("$(ProjectDir)/STM32G070.svd");
  File.Open ("$(ProjectDir)/_build/Project.elf");
}

void AfterTargetReset (void) {
  _SetupTarget();
}

void AfterTargetDownload (void) {
  _SetupTarget();
}

void _SetupTarget(void) {
  unsigned int SP;
  unsigned int PC;
  unsigned int VectorTableAddr;

  VectorTableAddr = Elf.GetBaseAddr();
  SP = Target.ReadU32(VectorTableAddr);
  if (SP != 0xFFFFFFFF) {
    Target.SetReg("SP", SP);
  }
  PC = Elf.GetEntryPointPC();
  if (PC != 0xFFFFFFFF) {
    Target.SetReg("PC", PC);
  } else {
    Util.Error("Project script error: failed to set up entry point PC", 1);
  }
}

EOF

create_file "stm32g070xx.jflash" << 'EOF'
  AppVersion =
  FileVersion = 2
[GENERAL]
  aATEModuleSel[24] = 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  ConnectMode = 0
  CurrentFile = ""
  DataFileSAddr = 0x00000000
  GUIMode = 0
  HostName = ""
  TargetIF = 1
  USBPort = 0
  USBSerialNo = 0x00000000
  UseATEModuleSelection = 0
[JTAG]
  IRLen = 0
  MultipleTargets = 0
  NumDevices = 0
  Speed0 = 4000
  Speed1 = 4000
  TAP_Number = 0
  UseAdaptive0 = 0
  UseAdaptive1 = 0
  UseMaxSpeed0 = 0
  UseMaxSpeed1 = 0
[CPU]
  NumInitSteps = 1
  InitStep0_Action = "Reset"
  InitStep0_Value0 = 0x00000000
  InitStep0_Value1 = 0x00000000
  InitStep0_Comment = "Reset and halt target"
  NumExitSteps = 0
  UseScriptFile = 0
  ScriptFile = ""
  UseRAM = 1
  RAMAddr = 0x20000000
  RAMSize = 0x00009000
  CheckCoreID = 1
  CoreID = 0x0BB11477
  CoreIDMask = 0x0F000FFF
  UseAutoSpeed = 0x00000001
  ClockSpeed = 0x00000000
  EndianMode = 0
  ChipName = "ST STM32G070RB"
[FLASH]
  aRangeSel[1] = 0-31
  BankName = "Internal flash"
  BankSelMode = 1
  BaseAddr = 0x08000000
  NumBanks = 1
[PRODUCTION]
  AutoPerformsDisconnect = 0
  AutoPerformsErase = 1
  AutoPerformsProgram = 1
  AutoPerformsSecure = 0
  AutoPerformsStartApp = 0
  AutoPerformsUnsecure = 0
  AutoPerformsVerify = 1
  EnableFixedVTref = 0
  EnableTargetPower = 0
  EraseType = 1
  FixedVTref = 0x00000CE4
  MonitorVTref = 0
  MonitorVTrefMax = 0x0000157C
  MonitorVTrefMin = 0x000003E8
  OverrideTimeouts = 0
  ProgramSN = 0
  SerialFile = ""
  SNAddr = 0x00000000
  SNInc = 0x00000001
  SNLen = 0x00000004
  SNListFile = ""
  SNValue = 0x00000001
  StartAppType = 0
  TargetPowerDelay = 0x00000014
  TimeoutErase = 0x00003A98
  TimeoutProgram = 0x00002710
  TimeoutVerify = 0x00002710
  VerifyType = 1
[PERFORMANCE]
  DisableSkipBlankDataOnProgram = 0x00000000
  PerfromBlankCheckPriorEraseChip = 0x00000001
  PerfromBlankCheckPriorEraseSelectedSectors = 0x00000001

EOF

# Create main.c file in src directory from embedded data using Here Document
main_c_file="${directories[1]}/main.c"
if [ ! -f "$main_c_file" ]; then
  op_counter=$((op_counter + 1))
  cat << 'EOF' > "$main_c_file"
#include "main.h"


int main(void) {
  /* Main program loop: initialize, process continuously, and idle between operations */
  for (init(); process(); idle());
}


/**
 * @brief  Returns pointer to the system uptime counter
 * @retval Pointer to volatile 64-bit uptime value (milliseconds/ticks)
 */
__STATIC_FORCEINLINE __SYSTICK_VOLATILE uint64_t * uptime(void) {
  extern __SYSTICK_VOLATILE uint64_t system_uptime;
  return &system_uptime;
}


/**
 * @brief  SysTick event processing - handles uptime increment and LED toggle
 * @note   Implementation is shared between polling and interrupt modes
 *         depending on SYSTICK_IRQ_ENABLE configuration
 */
#if YES == SYSTICK_IRQ_ENABLE

/* IRQ mode: Empty inline stub; actual implementation runs in interrupt handler */
__STATIC_FORCEINLINE void process_systick_event(void) {}

/* SysTick interrupt service routine */
void SysTick_Handler(void);
void SysTick_Handler(void) {

#else

/* Polling mode: Check COUNTFLAG before processing */
__STATIC_FORCEINLINE void process_systick_event(void) {
  if (0 == (SysTick->CTRL & SysTick_CTRL_COUNTFLAG_Msk)) {
    return;  /* No event occurred, exit early */
  }

#endif

  /* ========== Shared implementation (IRQ or polling) ========== */

  /* Increment uptime counter and toggle PC8 LED based on bit 9 state
   * When bit 9 of uptime is set: turn LED on (BR8 -- drive pin low)
   * When bit 9 of uptime is clear: turn LED off (BS8 -- drive pin high)
   * This creates a blink period of 2^10 = 1024 ticks */
  GPIOC->BSRR = (++*uptime() & (1 << 9)) ? GPIO_BSRR_BR8 : GPIO_BSRR_BS8;

}


/**
 * @brief  Idle state handler - processes pending events during main loop idle time
 * @note   Called repeatedly from main loop when no work is pending
 */
__STATIC_FORCEINLINE void idle(void) {
  process_systick_event();
} /* idle() */


/**
 * @brief  Main processing routine - executes application logic
 * @retval Non-zero to continue main loop execution, zero to exit
 */
__STATIC_FORCEINLINE unsigned process(void) {
  /* TODO: Add application-specific processing here */
  return !0;  /* Always continue loop */
} /* process() */


/* System uptime counter in SysTick ticks (incremented every SysTick event) */
__SYSTICK_VOLATILE uint64_t system_uptime = 0;

EOF
  echo "File $main_c_file created."
fi

download_file "${url1}/Source/Templates/${fname1[0]}" "${directories[1]}/${fname1[0]}"
download_file "${url1}/Source/Templates/gcc/${fname1[1]}" "${directories[1]}/${fname1[1]}"
download_file "${url1}/Source/Templates/arm/${fname1[1]}" "${directories[2]}/${fname1[1]}"
download_file "${url3}" "STM32G070.svd"

# Download files
for filename in "${fname2[@]}"
do
  download_file "${url1}/Include/${filename}" "${directories[0]}/${filename}"
done

for filename in "${fname3[@]}"
do
  download_file "${url2}${filename}" "${directories[0]}/${filename}"
done

echo -e "\nBuilding sources..\n"

if make debug; then
    echo ""
    echo "====================================="
    echo "Project setup complete!"
    echo "  Operations performed: $op_counter"
    echo "  Project directory: $base_dir"
    echo "  Build: SUCCESS"
    echo "====================================="
    echo ""
else
    echo ""
    echo "====================================="
    echo "Build FAILED!"
    echo "  Check error messages above"
    echo "====================================="
    echo ""
    exit 1
fi

press_any_key
