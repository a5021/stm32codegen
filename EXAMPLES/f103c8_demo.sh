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

if [ -e stm32f103xb.h ]; then
    # File exists
    opt=-l
else
    # File does not exist
    opt=-s
fi

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
        /usr/bin/*|/bin/*) ;;  # Cygwin Python ??? keep cygwin path
        *) PY_GEN_PY="$(cygpath -w "$PY_GEN")" ;;  # Windows Python ??? convert
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

generate_header "main.h" $opt 103c8 -M\
    -D NO                     0\
       NONE                   NO\
       OFF                    NO\
       YES                    \(\!NO\)\
       ON                     YES\
       ""\
        HCLK                   "8    /* 8 to 72 (MHz) with a step of 4 */"\
        ""\
        SYSTICK_CLOCK_SOURCE   "0    /* 0 = HCLK / 8; 1 = HCLK         */"\
        SYSTICK_ENABLE         YES\
        SYSTICK_IRQ_ENABLE     NO\
     \
     -H "#if HCLK < 8 || HCLK > 72 || (HCLK % 4 != 0)"\
     -H "  #error \"Invalid HCLK value. Must be between 8 and 72 MHz with a step of 4 MHz.\""\
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
    -F "__STATIC_FORCEINLINE void idle(void);"\
    -F "__STATIC_FORCEINLINE unsigned process(void);"\
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

func_name=wait_for_clock_stable
tag=R
generate_header "rcc.h" -l 103c8 -p RCC -m rcc -f init_rcc\
    \
    -D $tag '(HCLK >= 16)'\
       XMUL "(HCLK / 8 - 2)     /* PLL multiplication: HCLK = 8MHz HSE * (XMUL + 2) */"\
       A    "((XMUL >> 0) & 1)  /* LSB or BIT0 of PLL multiplication factor */"\
       B    "((XMUL >> 1) & 1)  /*        BIT1 of PLL multiplication factor */"\
       C    "((XMUL >> 2) & 1)  /*        BIT2 of PLL multiplication factor */"\
       D    "((XMUL >> 3) & 1)  /* MSB or BIT3 of PLL multiplication factor */"\
    \
    --tag-bit R SW_PLL PLLON HSION HSITRIM_4\
    --tag-bit A PLLMULL0\
    --tag-bit B PLLMULL1\
    --tag-bit C PLLMULL2\
    --tag-bit D PLLMULL3\
    \
    $force_inline\
    --pre-init configure_flash\
    --post-init $func_name\
    -F "__STATIC_FORCEINLINE void configure_flash(void) {"\
    -F "  #if (HCLK > 24)"\
    -F "    /* Configure flash to use 1 wait state and enable prefetch buffer */"\
    -F "    FLASH->ACR = FLASH_ACR_LATENCY | FLASH_ACR_PRFTBE;"\
    -F "  #endif"\
    -F "}"\
    -F ""\
    -F "__STATIC_FORCEINLINE void $func_name(void) {"\
    -F "  #if $tag"\
    -F "    while(RCC_CFGR_SWS_PLL != (RCC->CFGR & RCC_CFGR_SWS_PLL)) {}"\
    -F "  #endif"\
    -F "} /* $func_name() */"\
    -F ""\
    -F "#undef A"\
    -F "#undef B"\
    -F "#undef C"\
    -F "#undef D"\
    -F "#undef $tag"

# GPIO pin configuration header (BluePill_Project_Generator style).
# Replaces the stm32cgen-generated gpio.h: the macros and the init logic
# are copied verbatim from https://github.com/a5021/BluePill_Project_Generator
# so the example uses the same proven, reviewed GPIO handling as that project.
cat > "gpio.h" << 'EOF'
#ifndef __GPIO_H__
#define __GPIO_H__

#include <stdint.h>
#include "stm32f103xb.h"

/* ------------------------------------------------------------------ */
/* Pin configuration field builder (4-bit field: CNF[1:0] + MODE[1:0]) */
/* Source: BluePill_Project_Generator (create_stm32f1_project)        */
/* ------------------------------------------------------------------ */
#define PIN_CFG(PIN, MODE)              ((MODE) << ((PIN) * 4))

/* Input mode (MODE[1:0] = 00) */
#define I_ANALOG                        (0ULL << 2)   /* Analog mode                  */
#define I_FLOAT                         (1ULL << 2)   /* Floating input               */
#define I_PULL                          (2ULL << 2)   /* Input with pull-up / down    */

/* Output mode (MODE[1:0] > 00) */
#define O_PP                            (0ULL << 2)   /* General purpose push-pull    */
#define O_OD                            (1ULL << 2)   /* General purpose open-drain   */
#define O_AF                            (2ULL << 2)   /* Alternate function            */

/* MODE[1:0]: output speed */
#define O_10MHZ                         1ULL          /* Max speed 10 MHz             */
#define O_2MHZ                          2ULL          /* Max speed 2 MHz              */
#define O_50MHZ                         3ULL          /* Max speed 50 MHz             */

/* BSRR bit masks */
#define _BR(PIN)                        GPIO_BSRR_BR ## PIN
#define _BS(PIN)                        GPIO_BSRR_BS ## PIN
#define BR(PIN)                         _BR(PIN)
#define BS(PIN)                         _BS(PIN)
#define PIN_HIGH(PIN)                   GPIO_BSRR_BS ## PIN
#define PIN_LOW(PIN)                    GPIO_BSRR_BR ## PIN
#define PULL_UP(PIN)                    GPIO_BSRR_BS ## PIN
#define PULL_DOWN(PIN)                  GPIO_BSRR_BR ## PIN

/* ------------------------------------------------------------------ */
/* Port C: on-board LED on PC13 (Blue Pill, active-low)               */
/* ------------------------------------------------------------------ */
#define PORT_C_CONFIG   PIN_CFG(13, O_2MHZ)          /* PC13: output, push-pull, 2 MHz */
#define PORT_C_STATE    PIN_HIGH(13)                 /* PC13 HIGH = LED off            */
#define IOPC_EN         (PORT_C_CONFIG != 0)

__STATIC_FORCEINLINE void init_gpio(void) {
#if defined GPIOC_BASE
  /* State (pull/level) first, then CRL/CRH (mode) */
  if (PORT_C_STATE) GPIOC->BSRR = (uint32_t)PORT_C_STATE;
  *(__IO uint64_t *)GPIOC_BASE = (uint64_t)PORT_C_CONFIG;
#endif
}

#endif /* __GPIO_H__ */
EOF
echo "File gpio.h created."
((++op_counter))


cd ..

create_file() {
    local filename="$1"
    if [ ! -f "$filename" ]; then
        cat > "$filename"
        if [ -s "$filename" ]; then
            ((++op_counter))
            echo "File $filename created."
        else
            echo "Error: $filename is empty after creation" >&2
            rm -f "$filename"
            return 1
        fi
    fi
}
create_file "Makefile" << 'EOF'
# Define the target name and build directory.
TARGET    := Project
BUILD_DIR := _build

# ------------------------------------------------------------------
#   Declare the default goal so that plain "make" builds everything
# ------------------------------------------------------------------
.DEFAULT_GOAL := all

# ------------------------------------------------------------------
#   Race-free build-directory creation
# ------------------------------------------------------------------
$(shell mkdir -p $(BUILD_DIR))

# Find all source files.
SRC := $(wildcard ./src/*.c)
ASM := $(wildcard ./src/*.s)

# Define the toolchain used.
# If GCC_PATH is set, use that as prefix for the toolchain path,
# otherwise, assume the toolchain is in the PATH.
TOOLCHAIN := $(if $(GCC_PATH),$(GCC_PATH)/,)arm-none-eabi-

# Wrapper to quote paths with spaces
Q = $(if $(findstring $(space),$(1)),"$(1)",$(1))

CC = $(call Q,$(TOOLCHAIN)gcc)
LD = $(call Q,$(TOOLCHAIN)ld)
AS = $(call Q,$(TOOLCHAIN)gcc) -x assembler-with-cpp
CP = $(call Q,$(TOOLCHAIN)objcopy)
SZ = $(call Q,$(TOOLCHAIN)size)

# Define space for the Q function
space := $(subst ,, )

# Define the binary format we want to generate.
HEX = $(CP) -O ihex
BIN = $(CP) -O binary -S

# Define the CPU we are targeting, as well as any relevant flags.
MCU = -mcpu=cortex-m3 -mthumb
DEF = -DSTM32F103xB
INC = -I./inc

# Define the compiler flags.
FLG := $(MCU) $(DEF) $(INC) 

# Use the GNU dialect of the C11 standard, which includes specific extensions and conventions provided by GCC.
FLG += -std=gnu11

# Enable strict warnings and treat warnings as errors.
FLG += -Wall -Werror -Wextra -Wpedantic

# Place each variable and function into its own separate section and generate verbose assembly code.
FLG += -fdata-sections -ffunction-sections -fverbose-asm

# The -MMD flag generates a dependency file containing only user-defined headers,
# while the -MP flag adds phony targets to the Makefile for each dependency to ensure they exist.
FLG += -MMD -MP

# Prevent common symbols (multiple definitions of uninitialized globals)
# This ensures all global variables have explicit storage allocation
FLG += -fno-common

# Define the linker flags.
LDS := stm32f103xb_flash.ld
LIB := -lc -lm -lnosys
LDF := $(MCU) -specs=nano.specs -T$(LDS) $(LIB) -Wl,-Map=$(BUILD_DIR)/$(TARGET).map
LDF += -Wl,--cref,--gc-sections,--print-memory-usage 

# Set optimization flags
# ======================
# -Os:      optimize for size
# -g0:      disable generation of debug information
# -DNDEBUG: define a preprocessor macro to disable debugging functionality
# -flto:    enable link-time optimization for smaller binaries (~10-20% reduction)
#           increases build time and complicates debugging (incompatible with LST generation)
OPT = -Os -g0 -DNDEBUG # -flto

# Set the LST variable to generate an assembly listing file if -flto is not set in OPT.
ifeq ($(findstring -flto,$(OPT)), -flto)
  LST =
  LDF += -flto
else
  LST = -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.c=.lst))
endif

# ------------------------------------------------------------------
#   Rebuild when compiler/linker flags change
# ------------------------------------------------------------------

# Write the current flags into a stamp file; objects depend on it.
FLAG_STAMP := $(BUILD_DIR)/.flags
$(FLAG_STAMP): Makefile
	@echo 'FLG=$(FLG)' >  $@.tmp
	@echo 'LDF=$(LDF)' >> $@.tmp
	@echo 'OPT=$(OPT)' >> $@.tmp
	@cmp -s $@.tmp $@ || mv $@.tmp $@
	@rm -f $@.tmp

JLINK_FLAGS = -openprj./stm32f103xb.jflash -open$(BUILD_DIR)/$(TARGET).hex -hide -auto -exit -jflashlog./jflash.log

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

# ---------- compiler / linker version detection ----------
GCC_INFO    := $(shell $(CC) -dumpfullversion 2>/dev/null | awk -F. '{print $$0, ($$1*10000+$$2*100+$$3>=120000)}')
GCC_VERSION := $(word 1,$(GCC_INFO))
GCC_GE_12   := $(word 2,$(GCC_INFO))

LD_INFO     := $(shell $(LD) --version 2>/dev/null | awk '/^GNU ld/ {match($$NF,/([0-9]+)\.([0-9]+)/,v); print v[0], (v[1]*100+v[2]>=239); exit}')
LD_VERSION  := $(word 1,$(LD_INFO))
LD_GE_2_39  := $(word 2,$(LD_INFO))

$(info using GCC $(GCC_VERSION), Binutils $(LD_VERSION))

# ---------- suppress RWX segment warnings ----------
ifneq ($(or $(filter 1,$(GCC_GE_12)),$(filter 1,$(LD_GE_2_39))),)
  LDF += -Wl,--no-warn-rwx-segments
endif

# Define the build targets and commands.

# Default target builds all targets: elf, hex and bin files.
all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/$(TARGET).bin

# Object files are placed into BUILD_DIR directory.
OBJ = $(addprefix $(BUILD_DIR)/,$(notdir $(SRC:.c=.o)))
vpath %.c $(sort $(dir $(SRC)))

OBJ += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM:.s=.o)))
vpath %.s $(sort $(dir $(ASM)))

# ------------------------------------------------------------------
#   Parallel-safe dependency handling
# ------------------------------------------------------------------
DEP := $(OBJ:.o=.d)

# Compile C files.
$(BUILD_DIR)/%.o: %.c Makefile $(FLAG_STAMP) | $(BUILD_DIR)
	$(CC) -c $(FLG) $(OPT) -MF"$(@:%.o=%.d)" $(LST) $< -o $@

# Compile assembly files.
$(BUILD_DIR)/%.o: %.s Makefile $(FLAG_STAMP) | $(BUILD_DIR)
	$(AS) -c $(FLG) $(OPT) $< -o $@

# Link all object files together into a single ELF file.
$(BUILD_DIR)/$(TARGET).elf: $(OBJ) Makefile
	$(CC) $(OBJ) $(OPT) $(LDF) -o $@

# Generate a hex file from the ELF file.
$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(HEX) $< $@
	
# Generate a binary file from the ELF file.
$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(BIN) $< $@

# ------------------------------------------------------------------
#   Quick size summary
# ------------------------------------------------------------------
size: $(BUILD_DIR)/$(TARGET).elf
	$(SZ) $<

# Create the build directory if it doesn't exist yet.
$(BUILD_DIR):
	mkdir -p $@

# Set optimization and debugging flags for the debug target.
debug:	OPT = -Og -g3 -gdwarf
debug:	all

# Clean up all generated files.
clean:
	-rm -fR $(BUILD_DIR)

.PHONY: clean all size

# Print GCC version information.
gccversion :
	@$(CC) --version

# ------------------------------------------------------------------
#   Tool overrides (example)
#   make STLINK=/opt/stlink/bin/st-flash size
# ------------------------------------------------------------------

# Program the microcontroller using ST-Link.
program: $(BUILD_DIR)/$(TARGET).hex
	$(STLINK) $(STLINK_FLAGS)

# Program the device using jlink.
jprogram: $(BUILD_DIR)/$(TARGET).hex
	$(JLINK) $(JLINK_FLAGS)

# Include any dependency files.
-include $(DEP)
EOF

create_file "stm32f103xb_flash.ld" << 'EOF'
/* Entry Point */
ENTRY(Reset_Handler)

/* Highest address of the user mode stack */
_estack = 0x20005000;    /* end of RAM (20K) */

/* Generate a link error if heap and stack don't fit into RAM */
_Min_Heap_Size = 0x0;    /* required amount of heap  */
_Min_Stack_Size = 0x200; /* required amount of stack */

/* Specify the memory areas */
MEMORY
{
    RAM (xrw)      : ORIGIN = 0x20000000, LENGTH = 20K
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
        . = ALIGN(4);
        PROVIDE_HIDDEN (__preinit_array_start = .);
        KEEP (*(.preinit_array*))
        PROVIDE_HIDDEN (__preinit_array_end = .);
        . = ALIGN(4);
    } >FLASH

    .init_array :
    {
        . = ALIGN(4);
        PROVIDE_HIDDEN (__init_array_start = .);
        KEEP (*(SORT(.init_array.*)))
        KEEP (*(.init_array*))
        PROVIDE_HIDDEN (__init_array_end = .);
        . = ALIGN(4);
    } >FLASH

    .fini_array :
    {
        . = ALIGN(4);
        PROVIDE_HIDDEN (__fini_array_start = .);
        KEEP (*(SORT(.fini_array.*)))
        KEEP (*(.fini_array*))
        PROVIDE_HIDDEN (__fini_array_end = .);
        . = ALIGN(4);
    } >FLASH

    /* Used by the startup to initialize data */
    _sidata = LOADADDR(.data);

    /* Initialized data sections goes into RAM, load LMA copy after code */
    .data :
    {
        . = ALIGN(4);
        _sdata = .;        /* create a global symbol at data start */
        *(.data)           /* .data sections */
        *(.data*)          /* .data* sections */
        *(.RamFunc)        /* .RamFunc sections */
        *(.RamFunc*)       /* .RamFunc* sections */

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

    /* User_heap_stack section, used to check that there is enough RAM left */
    ._user_heap_stack :
    {
        . = ALIGN(8);
        PROVIDE ( end = . );
        PROVIDE ( _end = . );
        . = . + _Min_Heap_Size;
        . = . + _Min_Stack_Size;
        . = ALIGN(8);
    } >RAM

    /* Remove information from the standard libraries */
    /DISCARD/ :
    {
        libc.a ( * )
        libm.a ( * )
        libgcc.a ( * )
    }

    .ARM.attributes 0 : { *(.ARM.attributes) }
}
EOF

cat > "MDK-ARM/Project.uvprojx" << 'EOF'
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
          <Device>STM32F103CB</Device>
          <Vendor>STMicroelectronics</Vendor>
          <Cpu>IRAM(0x20000000,0x00005000) IROM(0x08000000,0x00010000) CPUTYPE("Cortex-M3") CLOCK(8000000) ELITTLE</Cpu>
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
          <SFDFile>..\STM32F103xx.svd</SFDFile>
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
          <SimDlgDllArguments>-pCM0</SimDlgDllArguments>
          <TargetDllName>SARMCM3.DLL</TargetDllName>
          <TargetDllArguments> </TargetDllArguments>
          <TargetDlgDll>TARMCM1.DLL</TargetDlgDll>
          <TargetDlgDllArguments>-pCM0</TargetDlgDllArguments>
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
            <AdsCpuType>"Cortex-M3"</AdsCpuType>
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
                <Size>0x5000</Size>
              </IRAM>
              <IROM>
                <Type>1</Type>
                <StartAddress>0x8000000</StartAddress>
                <Size>0x10000</Size>
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
                <Size>0x10000</Size>
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
                <Size>0x5000</Size>
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
              <Define>DEBUG,STM32F103xB</Define>
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
              <FileName>startup_stm32f103xb.s</FileName>
              <FileType>2</FileType>
              <FilePath>..\MDK-ARM\startup_stm32f103xb.s</FilePath>
            </File>
            <File>
              <FileName>system_stm32f1xx.c</FileName>
              <FileType>1</FileType>
              <FilePath>..\src\system_stm32f1xx.c</FilePath>
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
          <Device>STM32F103CB</Device>
          <Vendor>STMicroelectronics</Vendor>
          <Cpu>IRAM(0x20000000,0x00005000) IROM(0x08000000,0x00010000) CPUTYPE("Cortex-M3") CLOCK(8000000) ELITTLE</Cpu>
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
          <SFDFile>..\STM32F103xx.svd</SFDFile>
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
          <SimDlgDllArguments>-pCM0</SimDlgDllArguments>
          <TargetDllName>SARMCM3.DLL</TargetDllName>
          <TargetDllArguments> </TargetDllArguments>
          <TargetDlgDll>TARMCM1.DLL</TargetDlgDll>
          <TargetDlgDllArguments>-pCM0</TargetDlgDllArguments>
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
            <AdsCpuType>"Cortex-M3"</AdsCpuType>
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
                <Size>0x5000</Size>
              </IRAM>
              <IROM>
                <Type>1</Type>
                <StartAddress>0x8000000</StartAddress>
                <Size>0x10000</Size>
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
                <Size>0x10000</Size>
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
                <Size>0x5000</Size>
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
              <Define>NDEBUG,STM32F103xB</Define>
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
              <FileName>startup_stm32f103xb.s</FileName>
              <FileType>2</FileType>
              <FilePath>..\MDK-ARM\startup_stm32f103xb.s</FilePath>
            </File>
            <File>
              <FileName>system_stm32f1xx.c</FileName>
              <FileType>1</FileType>
              <FilePath>..\src\system_stm32f1xx.c</FilePath>
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

cat > "project.jdebug" << 'EOF'
void OnProjectLoad (void) {
  Project.AddPathSubstitute (".", "$(ProjectDir)");
  Project.SetDevice ("STM32F103CB");
  Project.SetHostIF ("USB", "");
  Project.SetTargetIF ("SWD");
  Project.SetTIFSpeed ("4 MHz");
  Project.AddSvdFile ("$(InstallDir)/Config/CPU/Cortex-M3.svd");
  Project.AddSvdFile ("$(InstallDir)/Config/Peripherals/ARMv6M.svd");
  Project.AddSvdFile ("$(ProjectDir)/STM32F103xx.svd");
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

create_file "stm32f103xb.jflash" << 'EOF'
  AppVersion =
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
  RAMSize = 0x00001000
  CheckCoreID = 1
  CoreID = 0x0BB11477
  CoreIDMask = 0x0F000FFF
  UseAutoSpeed = 0x00000001
  ClockSpeed = 0x00000000
  EndianMode = 0
  ChipName = "ST STM32F103C8"
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

# Create SEGGER Embedded Studio project (mirrors BluePill_Project_Generator 'ses' target).
# References the same sources/headers/SVD as the MDK and Ozone configs.
cat > "project.emProject" << 'EOF'
<!DOCTYPE CrossStudio_Project_File>
<solution Name="project" target="8" version="2">
  <configuration Name="Debug" inherited_configurations="Internal;Debug" />
  <configuration Name="Internal" Platform="ARM" hidden="Yes" />
  <configuration Name="Release" inherited_configurations="Internal;Release" />
  <project Name="BluePill_F103C8">
    <configuration
      Name="Common"
      WARNING_LEVEL="4 (All)"
      arm_assembler_variant="SEGGER"
      arm_compiler_variant="SEGGER"
      arm_core_type="Cortex-M3"
      arm_endian="Little"
      arm_linker_treat_warnings_as_errors="Yes"
      arm_linker_variant="SEGGER"
      arm_target_device_name="STM32F103CB"
      arm_target_interface_type="SWD"
      c_preprocessor_definitions="STM32F103xB"
      c_user_include_directories="./inc"
      debug_svd_file="$(ProjectDir)/STM32F103xx.svd"
      debug_start_from_entry_point_symbol="No"
      debug_target_connection="J-Link"
      gcc_c_language_standard="gnu17"
      gcc_enable_all_warnings="Yes"
      gcc_strict_prototypes_warning="Yes"
      gcc_uninitialized_variables_warning="Yes"
      gcc_unused_variable_warning="Yes"
      link_linker_script_file="$(StudioDir)/samples/SEGGER_Flash.icf"
      link_map_file="Detailed"
      linker_log_file="Yes"
      linker_output_format="hex"
      linker_section_placements_segments="FLASH1 RX 0x08000000 0x00010000;RAM1 RWX 0x20000000 0x00005000;"
      project_type="Executable" />
    <configuration
      Name="Debug"
      gcc_debugging_level="Level 3"
      gcc_dwarf_version="dwarf-5" />
    <configuration
      LIBRARY_IO_TYPE="SEMIHOST (host-formatted)"
      Name="Internal" />
    <configuration
      Name="Release"
      c_preprocessor_definitions="NDEBUG"
      gcc_debugging_level="None"
      gcc_dwarf_version="None"
      gcc_optimization_level="Level 2 for size"
      gcc_strip_symbols="Yes"
      link_dedupe_code="Yes"
      link_dedupe_data="Yes"
      link_inline="Yes"
      linker_strip_debug_information="Yes" />
    <folder Name="app">
      <file file_name="./src/main.c" />
    </folder>
    <folder Name="startup">
      <file file_name="$(StudioDir)/samples/Cortex_M_Startup.s" />
      <file file_name="$(StudioDir)/samples/SEGGER_THUMB_Startup.s" />
      <file file_name="./src/system_stm32f1xx.c" />
    </folder>
  </project>
</solution>
EOF
echo "File project.emProject created."
((++op_counter))

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

/* IRQ mode: stub here; real work runs inside SysTick_Handler below */
__STATIC_FORCEINLINE void process_systick_event(void) {
}   /* stub */
void SysTick_Handler(void) {

#else

/* Polling mode: Check COUNTFLAG before processing */
__STATIC_FORCEINLINE void process_systick_event(void) {
  if (0 == (SysTick->CTRL & SysTick_CTRL_COUNTFLAG_Msk)) {
    return;  /* No event occurred, exit early */
  }

#endif

  /* Increment uptime counter and toggle PC13 LED (BluePill onboard LED)
   * based on bit 9 state. This creates a blink period of 2^10 = 1024 ticks. */
  GPIOC->BSRR = (++*uptime() & (1 << 9)) ? GPIO_BSRR_BS13 : GPIO_BSRR_BR13;

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


# URLs for files
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f1/master/Source/Templates/system_stm32f1xx.c
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f1/master/Source/Templates/gcc/startup_stm32f103xb.s
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f1/master/Source/Templates/arm/startup_stm32f103xb.s
#
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f1/master/Include/system_stm32f1xx.h
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f1/master/Include/stm32f1xx.h
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f1/master/Include/stm32f103xb.h
#
#               https://github.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include
#
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_compiler.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_armclang.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_gcc.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_iccarm.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_version.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/core_cm3.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_armcc.h
#
#    https://raw.githubusercontent.com/cmsis-svd/cmsis-svd-data/refs/heads/main/data/STMicro/STM32F103xx.svd
     
     

fname1=("system_stm32f1xx.c" "startup_stm32f103xb.s")
fname2=("system_stm32f1xx.h" "stm32f1xx.h" "stm32f103xb.h")
fname3=("cmsis_compiler.h" "cmsis_armclang.h" "cmsis_gcc.h" "cmsis_iccarm.h" "cmsis_version.h" "core_cm3.h" "cmsis_armcc.h")

raw_github="https://raw.githubusercontent.com/"

url1="${raw_github}STMicroelectronics/cmsis-device-f1/refs/heads/master"
url2="${raw_github}ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/"
url3="${raw_github}cmsis-svd/cmsis-svd-data/refs/heads/main/data/STMicro/STM32F103xx.svd"

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

download_file "${url1}/Source/Templates/${fname1[0]}" "${directories[1]}/${fname1[0]}"
download_file "${url1}/Source/Templates/gcc/${fname1[1]}" "${directories[1]}/${fname1[1]}"
download_file "${url1}/Source/Templates/arm/${fname1[1]}" "${directories[2]}/${fname1[1]}"
download_file "${url3}" "STM32F103xx.svd"

# Download files
for filename in "${fname2[@]}"
do
  download_file "${url1}/Include/${filename}" "${directories[0]}/${filename}"
done

for filename in "${fname3[@]}"
do
  download_file "${url2}${filename}" "${directories[0]}/${filename}"
done

# Create a detailed README in the demo root.
cat > "README.md" << 'EOF'
# STM32F103C8 (Blue Pill) Demo

Bare-metal blink example for the STM32F103C8 / Blue Pill board, generated by
`f103c8_demo.sh`. It blinks the on-board LED on **PC13**.

The example is intentionally small: one GPIO pin (PC13), one timer
(SysTick), no external libraries beyond CMSIS.

---

## What the script does

`f103c8_demo.sh` is a self-contained project generator. Running it:

1. Creates the directory tree (`inc/`, `src/`, `MDK-ARM/`).
2. Generates the CMSIS-based configuration headers with `stm32cgen`:
   - `inc/main.h` ? top-level config (clock, SysTick, init order) and the
     `init()` sequence (`init_rcc` ? `init_gpio` ? `init_systick`).
   - `inc/rcc.h` ? `init_rcc()` and the RCC `APB2ENR` enable bits.
   - `inc/gpio.h` ? the `init_gpio()` function and the GPIO macros
     (`PIN_CFG`, `O_PP`, `O_OD`, `O_AF`, `I_ANALOG`, `I_FLOAT`, `I_PULL`,
     `O_2MHZ`, ?) copied verbatim from BluePill_Project_Generator.
3. Downloads the vendor CMSIS files (device header, startup, system init)
   and the SVD description from upstream sources.
4. Writes the application source `src/main.c`, the linker script, the Makefile,
   and the three debugger/IDE configurations described below.
5. Builds the project with `make` to verify everything is consistent.

All downloaded files are cached ? re-running the script skips what already
exists and only rebuilds.

---

## Project structure

```
f103c8_demo/
??? README.md                 # this file
??? Makefile                  # GNU make build (arm-none-eabi-gcc)
??? STM32F103xx.svd           # peripheral description (shared by MDK/Ozone/SES)
??? project.emProject         # SEGGER Embedded Studio project
??? project.jdebug            # Ozone debugger script
??? project.jflash            # J-Link flash script
??? inc/
?   ??? main.h                # configuration + init() sequence
?   ??? rcc.h                 # init_rcc() / RCC clock enables
?   ??? gpio.h                # init_gpio() + GPIO macros (BluePill style)
?   ??? stm32f103xb.h         # CMSIS device header (downloaded)
?   ??? system_stm32f1xx.h
?   ??? ?                     # other CMSIS/core headers
??? src/
?   ??? main.c                # application: init/process/idle loop, LED toggle
?   ??? system_stm32f1xx.c    # SystemInit() stub (HSI 8 MHz default)
?   ??? ?
??? MDK-ARM/
?   ??? Project.uvprojx       # Keil MDK-ARM project
?   ??? startup_stm32f103xb.s # ARM/Keil assembly startup (for MDK)
?   ??? STM32F103xx.svd       # (same content; see note below)
??? _build/                   # make output: Project.elf / .hex / .bin / .map
```

> The SVD file lives at the demo root so it can be shared by all three
> debugger configs: MDK references it via `<SFDFile>..\STM32F103xx.svd</SFDFile>`,
> Ozone via `$(ProjectDir)/STM32F103xx.svd`, and SES via
> `debug_svd_file="$(ProjectDir)/STM32F103xx.svd"`.

---

## How the demo works

### Clock and SysTick
`main.h` sets `HCLK = 8` MHz (HSI, no PLL). `init_systick()` configures the
Cortex-M3 SysTick to fire every 1 ms:

```
SysTick->LOAD = HCLK * 1000 / (8 - SYSTICK_CLOCK_SOURCE * 7) - 1;
```

With `SYSTICK_CLOCK_SOURCE = 0` the SysTick runs from `HCLK / 8`
(1 MHz), giving a 1 ms period. `SYSTICK_IRQ_ENABLE = NO`, so the tick is
serviced by polling `SysTick->CTRL COUNTFLAG` in the idle loop.

### GPIO ? PC13 LED
The on-board LED is connected to **PC13** (active-low: writing the pin high
turns the LED off, low turns it on). `gpio.h` configures it with:

```c
#define PORT_C_CONFIG  PIN_CFG(13, O_2MHZ)   /* PC13: output, push-pull, 2 MHz */
#define PORT_C_STATE   PIN_HIGH(13)          /* PC13 HIGH = LED off            */
#define IOPC_EN        (PORT_C_CONFIG != 0)
```

`init_gpio()` first writes the idle state to `GPIOC->BSRR`, then writes the
full 64-bit `CRL+CRH` configuration through `*(uint64_t*)GPIOC_BASE`. Because
`IOPC_EN` is non-zero, `init_rcc()` enables `RCC->APB2ENR.IOPCEN`, which clocks
the GPIOC peripheral (on STM32F1 each GPIO port is gated by its own APB2 bit).

### Main loop
`src/main.c` runs the standard `for (init(); process(); idle());` loop. In
`idle()` (polling mode) `process_systick_event()` waits for the 1 ms SysTick
flag, increments a 64-bit uptime counter, and toggles PC13 based on bit 9 of
the counter ? producing a visible blink with a period of 2^10 = 1024 ticks
(~1 second).

---

## Building

### GNU Make (arm-none-eabi-gcc)
```sh
make            # minimal build -> _build/Project.elf (+ .hex, .bin)
make debug      # debug build (-Og -g3 -gdwarf)
make size       # print ELF section sizes
make program    # flash via ST-Link
make jprogram   # flash via J-Link
make clean      # remove build output
```

### Keil MDK-ARM
Open `MDK-ARM/Project.uvprojx` in ?Vision, or build headlessly:
```sh
UV4.exe -b MDK-ARM/Project.uvprojx -t "Debug"
```
The MDK project references the SVD from the demo root, so the peripheral
windows are populated during debugging without installing any device pack.

### SEGGER Embedded Studio
Open `project.emProject`, or build headlessly with `emBuild`:
```sh
emBuild.exe -config Debug project.emProject
```
SES uses its own built-in startup files; the external `startup_stm32f103xb.s`
is only consumed by the MDK project.

---

## Flashing and debugging

Connect a J-Link (or ST-Link) to the board: SWDIO ? PA13, SWCLK ? PA14,
GND ? GND, 3.3V ? 3.3V.

- **Ozone** (J-Link): open `project.jdebug`; it loads `_build/Project.elf`
  and the shared SVD.
- **J-Link Commander** flash example:
  ```sh
  JLink.exe -device STM32F103C8 -if SWD -speed 4000 \
            -CommanderScript flash.jlink
  ```
  where `flash.jlink` contains `loadfile`, `r`, `g` (see the generated
  `MDK-ARM/flash.jlink` for a working example).
- **MDK / SES**: use the integrated flash+debug buttons.

---

## Configuration knobs

The main tunables live at the top of `inc/main.h`:

| Macro                 | Default | Meaning                                  |
|-----------------------|---------|------------------------------------------|
| `HCLK`                | `8`     | System clock in MHz (8?72, step 4)       |
| `SYSTICK_CLOCK_SOURCE`| `0`     | 0 = HCLK/8, 1 = HCLK                     |
| `SYSTICK_ENABLE`      | `YES`   | enable SysTick                           |
| `SYSTICK_IRQ_ENABLE`  | `NO`    | IRQ vs polling mode                      |

To change the blinked pin or add peripherals, edit `PORT_C_CONFIG` in
`inc/gpio.h` (or extend it with `PORT_A_CONFIG` / `PORT_B_CONFIG` using the
same `PIN_CFG` macros) and the matching `IOPx_EN` enable bits.

---

## References

- STM32F103C8 datasheet, RM0008 (STM32F1 reference manual)
- [BluePill_Project_Generator](https://github.com/a5021/BluePill_Project_Generator)
  ? source of the GPIO macros and the overall structure
- [stm32codegen](https://github.com/a5021/stm32codegen) ? generates
  `main.h` / `rcc.h` from the command line
EOF
echo "File README.md created."
((++op_counter))

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
