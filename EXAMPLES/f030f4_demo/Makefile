# Define the target name and build directory.
TARGET    := Project
BUILD_DIR := _build

# Find all source files.
SRC := $(wildcard ./src/*.c)
ASM := $(wildcard ./src/*.s)

# Define the toolchain used.
# If GCC_PATH is set, use that as prefix for the toolchain path,
# otherwise, assume the toolchain is in the PATH.
PREFIX := $(if $(GCC_PATH),$(GCC_PATH)/,)arm-none-eabi-

# Define the build tools used.
# CC - C compiler, AS - assembly compiler, CP - object copy program
CC = $(PREFIX)gcc
AS = $(PREFIX)gcc -x assembler-with-cpp
CP = $(PREFIX)objcopy

# Define the binary format we want to generate.
HEX = $(CP) -O ihex
BIN = $(CP) -O binary -S

# Define the CPU we are targeting, as well as any relevant flags.
MCU = -mcpu=cortex-m0 -mthumb
DEF = -DSTM32F030x6
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

# Set optimization flags
# ======================
# -Os:      optimize for size
# -g0:      disable generation of debug information
# -DNDEBUG: define a preprocessor macro to disable debugging functionality
# -s:       strip symbol tables from the resulting executable
OPT = -Os -g0 -DNDEBUG -s

# Set the LST variable to generate an assembly listing file if -flto is not set in OPT.
ifeq ($(findstring -flto,$(OPT)), -flto)
  LST =
else
  LST = -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.c=.lst))
endif

# Define the linker flags.
LDS := stm32f030x6_flash.ld
LIB := -lc -lm -lnosys
LDF := $(MCU) -specs=nano.specs -T$(LDS) $(LIB) -Wl,-Map=$(BUILD_DIR)/$(TARGET).map
LDF += -Wl,--cref,--gc-sections,--print-memory-usage -flto

JLINK_FLAGS = -openprj./stm32f030x6.jflash -open$(BUILD_DIR)/$(TARGET).hex -hide -auto -exit -jflashlog./jflash.log

ifeq ($(OS), Windows_NT)

    FLAG += -D WIN32
    ifeq ($(PROCESSOR_ARCHITEW6432), AMD64)
        FLAG += -D AMD64
    else
        ifeq ($(PROCESSOR_ARCHITECTURE), AMD64)
            FLAG += -D AMD64
        endif
        ifeq ($(PROCESSOR_ARCHITECTURE), x86)
            FLAG += -D IA32
        endif
    endif

    STLINK = ST-LINK_CLI.exe
    STLINK_FLAGS = -c UR -V -P $(BUILD_DIR)/$(TARGET).hex -Rst -Run

    JLINK = JFlash.Exe

else

    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S), Linux)
        FLAG += -D LINUX
    endif
    ifeq ($(UNAME_S), Darwin)
        FLAG += -D OSX
    endif
    UNAME_P := $(shell uname -p)
    ifeq ($(UNAME_P), x86_64)
        FLAG += -D AMD64
    endif
    ifneq ($(filter %86, $(UNAME_P)),)
        FLAG += -D IA32
    endif
    ifneq ($(filter arm%, $(UNAME_P)),)
        FLAG += -D ARM
    endif

    STLINK = st-flash
    STLINK_FLAGS = --reset --format ihex write $(BUILD_DIR)/$(TARGET).hex

    JLINK = JFlashExe

endif

GCC_DUMP_VER := $(shell $(CC) -dumpfullversion -dumpversion)
# Print version during build
$(info Using GCC version: $(GCC_DUMP_VER))
GCC_VER := $(shell echo $(GCC_DUMP_VER) | sed -e 's/\.\([0-9][0-9]\)/\1/g' -e 's/\.\([0-9]\)/0\1/g' -e 's/^[0-9]\{3,4\}$$/&00/')
GCC_VER_GE12 := $(shell expr `echo $(GCC_VER)` \>= 120000)

# Debugging tip: Uncomment the line below to verify GCC_VER_GE12
# $(info GCC_VER_GE12 = $(GCC_VER_GE12))

ifeq ($(GCC_VER_GE12), 1)
  # suppresses a warning about readable/writable/execute (RWX) segments in memory regions.
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

# Compile C files.
$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR) 
	$(CC) -c $(FLG) $(OPT) -MF"$(@:%.o=%.d)" $(LST) $< -o $@

# Compile assembly files.
$(BUILD_DIR)/%.o: %.s Makefile | $(BUILD_DIR)
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
	
# Create the build directory if it doesn't exist yet.
$(BUILD_DIR):
	mkdir $@

# Set optimization and debugging flags for the debug target.
debug:	OPT = -O3 -g3 -gdwarf
debug:	all

# Clean up all generated files.
clean:
	-rm -fR $(BUILD_DIR)

.PHONY: clean all

# Print GCC version information.
gccversion :
	@$(CC) --version

# Program the microcontroller using ST-Link.
program: $(BUILD_DIR)/$(TARGET).hex
	$(STLINK) $(STLINK_FLAGS)

# Program the device using jlink.
jprogram: $(BUILD_DIR)/$(TARGET).hex
	$(JLINK) $(JLINK_FLAGS)

# Include any dependency files.
-include $(wildcard $(BUILD_DIR)/*.d)
