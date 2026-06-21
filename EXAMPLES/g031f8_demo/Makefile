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
DEF = -DSTM32G031xx
INC = -I./inc

FLG := $(MCU) $(DEF) $(INC)

FLG += -std=gnu11
FLG += -Wall -Werror -Wextra -Wpedantic
FLG += -fdata-sections -ffunction-sections -fverbose-asm
FLG += -MMD -MP
FLG += -fno-common

LDS := stm32g031x8_flash.ld
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

JLINK_FLAGS = -openprj./stm32g031x8.jflash -open$(BUILD_DIR)/$(TARGET).hex -hide -auto -exit -jflashlog./jflash.log

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
	$(PREFIX)size $<

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