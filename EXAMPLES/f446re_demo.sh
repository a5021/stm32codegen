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

if [ -e stm32f446xx.h ]; then
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

generate_header "main.h" $opt 446re -M\
    -D NO                     0\
       NONE                   NO\
       OFF                    NO\
       YES                    \(\!NO\)\
       ON                     YES\
       ""\
       HCLK                   "180  /* 48 to 180 (MHz) */"\
       ""\
       SYSTICK_CLOCK_SOURCE   "0    /* 0 = HCLK / 8; 1 = HCLK         */"\
       SYSTICK_ENABLE         YES\
       SYSTICK_IRQ_ENABLE     NO\
    \
    -H "#if HCLK < 48 || HCLK > 180"\
    -H "  #error \"HCLK must be between 48 and 180 MHz\""\
    -H \#endif\
    \
    $force_inline\
    --post-init $func_name\
    -F ""\
    -F "__STATIC_FORCEINLINE void $func_name(void) {"\
    -F ""\
    -F "  /* Initialize SysTick to 1 ms period */"\
    -F "  /* By default the clock source of SysTick is AHB/8. */"\
    -F "  /* LOAD uses SystemCoreClock, which init_rcc() sets to the verified"\
    -F "   * 180 MHz PLL output, so SysTick ticks at exactly 1 ms. */"\
    -F ""\
    -F "  SysTick->LOAD = (SystemCoreClock / (8 - SYSTICK_CLOCK_SOURCE * 7)) / 1000 - 1;"\
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

func_name=wait_for_clock_stable
tag=R
generate_header "rcc.h" -l 446re -p RCC -m rcc -f init_rcc\
    \
    -D $tag '(HCLK == 180)'\
       ""\
       HSE_VAL   8\
       PLLM_VAL  8\
       PLLP_VAL  2\
       PLLQ_VAL  6\
       PLLN_VAL  "(HCLK * PLLM_VAL * PLLP_VAL / HSE_VAL)  /* PLLN: HSE/PLLM*PLLN/PLLP = HCLK */"\
       ""\
       PLLM_0    "((PLLM_VAL >> 0) & 1)"\
       PLLM_1    "((PLLM_VAL >> 1) & 1)"\
       PLLM_2    "((PLLM_VAL >> 2) & 1)"\
       PLLM_3    "((PLLM_VAL >> 3) & 1)"\
       PLLM_4    "((PLLM_VAL >> 4) & 1)"\
       PLLM_5    "((PLLM_VAL >> 5) & 1)"\
       PLLN_0    "((PLLN_VAL >> 0) & 1)"\
       PLLN_1    "((PLLN_VAL >> 1) & 1)"\
       PLLN_2    "((PLLN_VAL >> 2) & 1)"\
       PLLN_3    "((PLLN_VAL >> 3) & 1)"\
       PLLN_4    "((PLLN_VAL >> 4) & 1)"\
       PLLN_5    "((PLLN_VAL >> 5) & 1)"\
       PLLN_6    "((PLLN_VAL >> 6) & 1)"\
       PLLN_7    "((PLLN_VAL >> 7) & 1)"\
       PLLN_8    "((PLLN_VAL >> 8) & 1)"\
       PLLQ_0    "((PLLQ_VAL >> 0) & 1)"\
       PLLQ_1    "((PLLQ_VAL >> 1) & 1)"\
       PLLQ_2    "((PLLQ_VAL >> 2) & 1)"\
    \
    --tag-bit PLLM_0 PLLM_0\
    --tag-bit PLLM_1 PLLM_1\
    --tag-bit PLLM_2 PLLM_2\
    --tag-bit PLLM_3 PLLM_3\
    --tag-bit PLLM_4 PLLM_4\
    --tag-bit PLLM_5 PLLM_5\
    --tag-bit PLLN_0 PLLN_0\
    --tag-bit PLLN_1 PLLN_1\
    --tag-bit PLLN_2 PLLN_2\
    --tag-bit PLLN_3 PLLN_3\
    --tag-bit PLLN_4 PLLN_4\
    --tag-bit PLLN_5 PLLN_5\
    --tag-bit PLLN_6 PLLN_6\
    --tag-bit PLLN_7 PLLN_7\
    --tag-bit PLLN_8 PLLN_8\
    --tag-bit PLLQ_0 PLLQ_0\
    --tag-bit PLLQ_1 PLLQ_1\
    --tag-bit PLLQ_2 PLLQ_2\
    \
    $force_inline\
    --pre-init configure_flash\
    --post-init $func_name\
    -F "__STATIC_FORCEINLINE void configure_flash(void) {"\
    -F "  /* F446: enable PWR clock, select regulator Scale 1 and wait for it */"\
    -F "  /* (Scale 1 is required to run the core above 84 MHz).               */"\
    -F "  RCC->APB1ENR |= RCC_APB1ENR_PWREN;"\
    -F "  PWR->CR = (PWR->CR & ~PWR_CR_VOS) | PWR_CR_VOS_1;  /* Scale 1 */"\
    -F "  /* Bounded wait: some boards/clone parts never set VOSRDY; do not hang. */"\
    -F "  for (volatile uint32_t t = 0; t < 1000000 && !(PWR->CSR & PWR_CSR_VOSRDY); ++t) {}"\
    -F "  /* F446: 6 wait states + prefetch + I/D-cache for 180 MHz */"\
    -F "  FLASH->ACR = FLASH_ACR_LATENCY_6WS | FLASH_ACR_PRFTEN | FLASH_ACR_ICEN | FLASH_ACR_DCEN;"\
    -F "}"\
    -F ""\
    -F "__STATIC_FORCEINLINE void $func_name(void) {"\
    -F "  #if $tag"\
    -F "    /* Enable HSE (8 MHz crystal) and wait until ready */"\
    -F "    RCC->CR |= RCC_CR_HSEON;"\
    -F "    while (!(RCC->CR & RCC_CR_HSERDY)) {}"\
    -F ""\
    -F "    /* HSE=8MHz, PLLM=8, PLLN=360, PLLP=2 => 180 MHz */"\
    -F "    /* PLLP field 0b00 = /2 (do not set PLLP_1, that would be /6) */"\
    -F "    RCC->PLLCFGR = RCC_PLLCFGR | RCC_PLLCFGR_PLLSRC_HSE;"\
    -F ""\
    -F "    /* Enable PLL and wait until ready */"\
    -F "    RCC->CR |= RCC_CR_PLLON;"\
    -F "    while (!(RCC->CR & RCC_CR_PLLRDY)) {}"\
    -F ""\
    -F "    /* HPRE=D1, PPRE1=D4, PPRE2=D2, SW=PLL */"\
    -F "    RCC->CFGR = RCC_CFGR_HPRE_DIV1 | RCC_CFGR_PPRE1_DIV4 | RCC_CFGR_PPRE2_DIV2 | RCC_CFGR_SW_PLL;"\
    -F "    while (RCC_CFGR_SWS_PLL != (RCC->CFGR & RCC_CFGR_SWS)) {}"\
    -F ""\
    -F "    /* PLL verified on this board at 180 MHz (PLLM=8, N=360, P=2, HSE=8 MHz). */"\
    -F "    /* APB1 (PCLK1) = HCLK / 4 = 45 MHz. */"\
    -F "    SystemCoreClock = 180000000u;"\
    -F "  #endif"\
    -F "} /* $func_name() */"\
    -F ""\
    -F "#undef PLLM_0"\
    -F "#undef PLLM_1"\
    -F "#undef PLLM_2"\
    -F "#undef PLLM_3"\
    -F "#undef PLLM_4"\
    -F "#undef PLLM_5"\
    -F "#undef PLLN_0"\
    -F "#undef PLLN_1"\
    -F "#undef PLLN_2"\
    -F "#undef PLLN_3"\
    -F "#undef PLLN_4"\
    -F "#undef PLLN_5"\
    -F "#undef PLLN_6"\
    -F "#undef PLLN_7"\
    -F "#undef PLLN_8"\
    -F "#undef PLLQ_0"\
    -F "#undef PLLQ_1"\
    -F "#undef PLLQ_2"\
    -F "#undef $tag"


generate_header "gpio.h" -l 446re -p GPIOA GPIOB GPIOC -m gpio -f init_gpio\
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
       "PIN_MODE(PIN, MODE)" "(((MODE)  << GPIO_MODER_MODER ## PIN ## _Pos) & GPIO_MODER_MODER ## PIN ## _Msk)"\
       "PIN_SPEED(PIN, SPEED)" "(((SPEED) << GPIO_OSPEEDR_OSPEED ## PIN ## _Pos) & GPIO_OSPEEDR_OSPEED ## PIN ## _Msk)"\
       "PIN_OTYPE(PIN, OTYPE)" "((OTYPE)   ? GPIO_OTYPER_OT ## PIN : 0)"\
       "PIN_PUPD(PIN, PUPD)" "(((PUPD)  << GPIO_PUPDR_PUPD ## PIN ## _Pos) & GPIO_PUPDR_PUPD ## PIN ## _Msk)"\
       "PIN_AF(PIN, AF)" "(AF << (PIN * 4))"\
       ""\
        PA2_AF7_USART2_TX "PIN_AF(2, 7ULL)"\
        PA13_AF0_SYS_JTMS_SWDIO "PIN_AF(13, 0ULL)"\
        PA14_AF0_SYS_JTCK_SWCLK "PIN_AF(14, 0ULL)"\
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
        GPIOA_MODER "(GPIO_MODE ^ (GPIOA_MODE))"\
        GPIOB_MODER "(GPIO_MODE ^ (GPIOB_MODE))"\
        GPIOC_MODER "(GPIO_MODE ^ (GPIOC_MODE))"\
         GPIOC_PUPDR "PIN_PUPD(13, PIN_PUPD_DOWN)"\
       ""\
        GPIOA_AFR_0 "(GPIOA_AF & UINT32_MAX)"\
       GPIOA_AFR_1 "((GPIOA_AF >> 32) & UINT32_MAX)"\
    \
    -H ""\
    -H "#define CONFIGURE_PIN(GPIOx, PIN, MODE, OTYPE, SPEED, PUPD) do {                               \\"\
    -H "  if (MODE)   MODIFY_REG((GPIOx)->MODER,   (0x03UL << ((PIN) * 2)), ((MODE)  << ((PIN) * 2))); \\"\
    -H "  if (SPEED)  MODIFY_REG((GPIOx)->OSPEEDR, (0x03UL << ((PIN) * 2)), ((SPEED) << ((PIN) * 2))); \\"\
    -H "  if (PUPD)   MODIFY_REG((GPIOx)->PUPDR,   (0x03UL << ((PIN) * 2)), ((PUPD)  << ((PIN) * 2))); \\"\
    -H "  if (OTYPE)  MODIFY_REG((GPIOx)->OTYPER,  (0x01UL << (PIN)),       ((OTYPE) << (PIN)));       \\"\
    -H }while\(0\)\
    -H ""\
    -H "#ifndef SWD_EN"\
    -H "  #define SWD_EN 1   /* keep PA13/PA14 = SWD; do not let init_gpio() switch them"\
    -H "                      * to analog, or the debug port dies with the firmware running */"\
    -H "#endif"\
    -H ""\
    -H "#ifndef USART2_TX_EN"\
    -H "  #define USART2_TX_EN YES"\
    -H "#endif"\
    -H ""\
    -H "#define GPIOA_MODE (                                                    \\"\
    -H '  SWD_EN     * PIN_MODE(13, PIN_MODE_AF)       /* PA13 -- SWDIO      */ | \'\
    -H '  SWD_EN     * PIN_MODE(14, PIN_MODE_AF)       /* PA14 -- SWCLK      */ | \'\
    -H '  USART2_TX_EN  * PIN_MODE(2,  PIN_MODE_AF)    /* PA2  -- USART2 TX  */   \'\
    -H ')'\
    -H ""\
    -H "#define GPIOA_OTYPE ( 0 )"\
    -H ""\
    -H "#define GPIOA_OSPEED ( 0 )"\
    -H ""\
    -H "#define GPIOA_AF (                            \\"\
    -H "  SWD_EN    * PA13_AF0_SYS_JTMS_SWDIO       | \\"\
    -H "  SWD_EN    * PA14_AF0_SYS_JTCK_SWCLK       | \\"\
    -H "  USART2_TX_EN * PA2_AF7_USART2_TX               \\"\
    -H ")"\
    -H ""\
    -H "#define GPIOB_MODE ( PIN_MODE(2, PIN_MODE_OUTPUT) /* PB2 -- LED */ )"\
    -H ""\
    -H "#define GPIOB_OTYPE ( 0 )"\
    -H ""\
    -H "#define GPIOB_OSPEED ( 0 )"\
    -H ""\
    -H "#define GPIOC_MODE ( PIN_MODE(13, PIN_MODE_INPUT)  /* PC13 -- B1  Button */ )"\
    -H ""\
    -H "#define GPIOC_OTYPE ( 0 )"\
    -H ""\
    -H "#define GPIOC_OSPEED ( 0 )"\
    \
    $force_inline\
    --no-def

# --------------------------------------------------------------------------- #
#  uart.h  — hand-written, header-only USART2 driver (PA2 = TX, 115200 8N1)   #
#  USART2 is intentionally NOT wired through the RCC *_EN auto-wiring: the    #
#  uart_init() below enables the USART2 clock itself. Keeping *_EN undefined   #
#  means main.h's init() will not call a generated init_usart()/init_pwr().   #
# --------------------------------------------------------------------------- #
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

create_file "uart.h" << 'EOF'
#ifndef __UART_H__
#define __UART_H__

#define UART2_BAUD  115200u
/* PCLK1 (APB1) = HCLK / 4, since PPRE1 = /4 */
#define UART2_PCLK (SystemCoreClock / 4u)

__STATIC_FORCEINLINE void uart_init(void) {
  /* USART2 on APB1. PA2 is already routed to USART2_TX (AF7, high speed)
   * by init_gpio() from gpio.h (PA2_AF7_USART2_TX), so here only the
   * clock, the baud rate and UE/TE are set. */
  RCC->APB1ENR |= RCC_APB1ENR_USART2EN;
  /* BRR = PCLK1 / (16 * BAUD) with rounding */
  { uint32_t clk = UART2_PCLK, div = 16UL * UART2_BAUD;
    USART2->BRR = ((clk / div) << 4) | (((clk % div) * 16UL) / div); }
  USART2->CR1 = USART_CR1_UE | USART_CR1_TE;
}

__STATIC_FORCEINLINE void uart_putc(char c) {
  while (!(USART2->SR & USART_SR_TXE)) {}
  USART2->DR = (uint32_t)(uint8_t)c;
}

__STATIC_FORCEINLINE void uart_puts(const char *s) {
  while (*s != 0) uart_putc(*s++);
}

__STATIC_FORCEINLINE void uart_print_u32(uint32_t v) {
  char  buf[10];
  int   i = 0;
  do { buf[i++] = (char)('0' + (v % 10)); v /= 10; } while (v);
  while (i) uart_putc(buf[--i]);
}

#endif /* __UART_H__ */
EOF

cd ..

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

MCU = -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard
# The board uses an 8 MHz HSE crystal; override the vendor default (25 MHz)
# in system_stm32f4xx.c so any SystemCoreClockUpdate() call computes 180 MHz.
DEF = -DSTM32F446xx -DHSE_VALUE=8000000u
INC = -I./inc

FLG := $(MCU) $(DEF) $(INC)
FLG += -std=gnu11
FLG += -Wall -Werror -Wextra -Wpedantic
FLG += -fdata-sections -ffunction-sections -fverbose-asm
FLG += -MMD -MP
FLG += -fno-common

LDS := stm32f446retx_flash.ld
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

JLINK_FLAGS = -openprj./stm32f446re.jflash -open$(BUILD_DIR)/$(TARGET).hex -hide -auto -exit -jflashlog./jflash.log

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
    STLINK_FLAGS = -c SWD SWCLK=4000 UR -V -P $(BUILD_DIR)/$(TARGET).hex -Rst -Run
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

debug: OPT = -Og -g3 -gdwarf
debug: all

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

create_file "stm32f446retx_flash.ld" << 'EOF'
/* Linker script for STM32F446RET6 (WeAct-style F446RE)
 *   512 KB Flash @ 0x08000000, 128 KB SRAM @ 0x20000000 (SRAM1 112K + SRAM2 16K)
 *   No CCM on F446. */
ENTRY(Reset_Handler)

_estack = ORIGIN(RAM) + LENGTH(RAM);

_Min_Heap_Size  = 0x200;
_Min_Stack_Size = 0x400;

MEMORY
{
  FLASH (rx)  : ORIGIN = 0x08000000, LENGTH = 512K
  RAM   (rw)  : ORIGIN = 0x20000000, LENGTH = 128K
}

SECTIONS
{
  .isr_vector :
  {
    . = ALIGN(4);
    KEEP(*(.isr_vector))
    . = ALIGN(4);
  } >FLASH

  .text :
  {
    . = ALIGN(4);
    *(.text)
    *(.text*)
    *(.glue_7)
    *(.glue_7t)
    *(.eh_frame)

    KEEP(*(.init))
    KEEP(*(.fini))

    . = ALIGN(4);
    _etext = .;
  } >FLASH

  .rodata :
  {
    . = ALIGN(4);
    *(.rodata)
    *(.rodata*)
    . = ALIGN(4);
  } >FLASH

  .ARM.extab : { *(.ARM.extab* .gnu.linkonce.armextab.*) } >FLASH
  .ARM :
  {
    __exidx_start = .;
    *(.ARM.exidx*)
    __exidx_end = .;
  } >FLASH

  .preinit_array :
  {
    PROVIDE_HIDDEN(__preinit_array_start = .);
    KEEP(*(.preinit_array*))
    PROVIDE_HIDDEN(__preinit_array_end = .);
  } >FLASH

  .init_array :
  {
    PROVIDE_HIDDEN(__init_array_start = .);
    KEEP(*(SORT(.init_array.*)))
    KEEP(*(.init_array*))
    PROVIDE_HIDDEN(__init_array_end = .);
  } >FLASH

  .fini_array :
  {
    PROVIDE_HIDDEN(__fini_array_start = .);
    KEEP(*(SORT(.fini_array.*)))
    KEEP(*(.fini_array*))
    PROVIDE_HIDDEN(__fini_array_end = .);
  } >FLASH

  _sidata = LOADADDR(.data);

  .data :
  {
    . = ALIGN(4);
    _sdata = .;
    *(.data)
    *(.data*)
    . = ALIGN(4);
    _edata = .;
  } >RAM AT> FLASH

  .bss :
  {
    . = ALIGN(4);
    _sbss = .;
    __bss_start__ = _sbss;
    *(.bss)
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);
    _ebss = .;
    __bss_end__ = _ebss;
  } >RAM

  ._user_heap_stack :
  {
    . = ALIGN(8);
    PROVIDE(end = .);
    PROVIDE(_end = .);
    . = . + _Min_Heap_Size;
    . = . + _Min_Stack_Size;
    . = ALIGN(8);
  } >RAM

  ASSERT(_estack - _end >= _Min_Stack_Size,
    "RAM overflow: .data + .bss + stack exceeds 128 KB")
}
EOF

create_file "MDK-ARM/Project.uvprojx" << 'UVEOF'
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
          <Device>STM32F446RETx</Device>
          <Vendor>STMicroelectronics</Vendor>
          <Cpu>IRAM(0x20000000,0x00020000) IROM(0x08000000,0x00080000) CPUTYPE("Cortex-M4") FPU CLOCK(180000000) ELITTLE</Cpu>
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
          <SFDFile>..\STM32F446.svd</SFDFile>
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
          <SimDlgDllArguments>-pCM4</SimDlgDllArguments>
          <TargetDllName>SARMCM3.DLL</TargetDllName>
          <TargetDllArguments> </TargetDllArguments>
          <TargetDlgDll>TARMCM1.DLL</TargetDlgDll>
          <TargetDlgDllArguments>-pCM4</TargetDlgDllArguments>
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
            <AdsCpuType>"Cortex-M4"</AdsCpuType>
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
                <Size>0x20000</Size>
              </IRAM>
              <IROM>
                <Type>1</Type>
                <StartAddress>0x08000000</StartAddress>
                <Size>0x80000</Size>
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
                <StartAddress>0x08000000</StartAddress>
                <Size>0x80000</Size>
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
                <Size>0x20000</Size>
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
              <Define>STM32F446xx DEBUG</Define>
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
              <FileName>startup_stm32f446xx.s</FileName>
              <FileType>2</FileType>
              <FilePath>..\MDK-ARM\startup_stm32f446xx.s</FilePath>
            </File>
            <File>
              <FileName>system_stm32f4xx.c</FileName>
              <FileType>1</FileType>
              <FilePath>..\src\system_stm32f4xx.c</FilePath>
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
          <Device>STM32F446RETx</Device>
          <Vendor>STMicroelectronics</Vendor>
          <Cpu>IRAM(0x20000000,0x00020000) IROM(0x08000000,0x00080000) CPUTYPE("Cortex-M4") FPU CLOCK(180000000) ELITTLE</Cpu>
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
          <SFDFile>..\STM32F446.svd</SFDFile>
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
          <SimDlgDllArguments>-pCM4</SimDlgDllArguments>
          <TargetDllName>SARMCM3.DLL</TargetDllName>
          <TargetDllArguments> </TargetDllArguments>
          <TargetDlgDll>TARMCM1.DLL</TargetDlgDll>
          <TargetDlgDllArguments>-pCM4</TargetDlgDllArguments>
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
            <AdsCpuType>"Cortex-M4"</AdsCpuType>
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
                <Size>0x20000</Size>
              </IRAM>
              <IROM>
                <Type>1</Type>
                <StartAddress>0x08000000</StartAddress>
                <Size>0x80000</Size>
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
                <StartAddress>0x08000000</StartAddress>
                <Size>0x80000</Size>
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
                <Size>0x20000</Size>
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
              <FileName>startup_stm32f446xx.s</FileName>
              <FileType>2</FileType>
              <FilePath>..\MDK-ARM\startup_stm32f446xx.s</FilePath>
            </File>
            <File>
              <FileName>system_stm32f4xx.c</FileName>
              <FileType>1</FileType>
              <FilePath>..\src\system_stm32f4xx.c</FilePath>
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
UVEOF

create_file "project.jdebug" << 'EOF'
void OnProjectLoad (void) {
  Project.AddPathSubstitute (".", "$(ProjectDir)");
  Project.SetDevice ("STM32F446RE");
  Project.SetHostIF ("USB", "");
  Project.SetTargetIF ("SWD");
  Project.SetTIFSpeed ("4 MHz");
  Project.AddSvdFile ("$(InstallDir)/Config/CPU/Cortex-M4.svd");
  Project.AddSvdFile ("$(InstallDir)/Config/Peripherals/ARMv7M.svd");
  Project.AddSvdFile ("$(ProjectDir)/STM32F446.svd");
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

create_file "stm32f446re.jflash" << 'EOF'
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
  RAMSize = 0x00020000
  CheckCoreID = 1
  CoreID = 0x0BA00477
  CoreIDMask = 0x0F000FFF
  UseAutoSpeed = 0x00000001
  ClockSpeed = 0x00000000
  EndianMode = 0
  ChipName = "ST STM32F446RE"
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

# SEGGER Embedded Studio project (SES bundles its own startup; uses ./src/*.c)
create_file "project.emProject" << 'EOF'
<!DOCTYPE CrossStudio_Project_File>
<solution Name="project" target="8" version="2">
  <configuration Name="Debug" inherited_configurations="Internal;Debug" />
  <configuration Name="Internal" Platform="ARM" hidden="Yes" />
  <configuration Name="Release" inherited_configurations="Internal;Release" />
  <project Name="F446RE">
    <configuration
      Name="Common"
      WARNING_LEVEL="4 (All)"
      arm_assembler_variant="SEGGER"
      arm_compiler_variant="SEGGER"
      arm_core_type="Cortex-M4"
      arm_endian="Little"
      arm_fpu_variant="VFPv4-D16"
      arm_fpu_abi="Hard"
      arm_linker_treat_warnings_as_errors="Yes"
      arm_linker_variant="SEGGER"
      arm_target_device_name="STM32F446RE"
      arm_target_interface_type="SWD"
      c_preprocessor_definitions="STM32F446xx"
      c_user_include_directories="./inc"
      debug_svd_file="$(ProjectDir)/STM32F446.svd"
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
      linker_section_placements_segments="FLASH1 RX 0x08000000 0x00080000;RAM1 RWX 0x20000000 0x00020000;"
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
      <file file_name="./src/system_stm32f4xx.c" />
    </folder>
  </project>
</solution>
EOF

# Create main.c file in src directory from embedded data using Here Document
main_c_file="${directories[1]}/main.c"
if [ ! -f "$main_c_file" ]; then
  op_counter=$((op_counter + 1))
  cat << 'EOF' > "$main_c_file"
#include "main.h"
#include "uart.h"


/* ---- WeAct-style F446RE: LED = PB2 (active HIGH), B1 = PC13 (active HIGH) --- */
#define LED_EFFECT_BLINK   0u  /*  500 ms on / 500 ms off                        */
#define LED_EFFECT_FAST    1u  /*  125 ms on / 125 ms off                        */
#define LED_EFFECT_SOS     2u  /*  "SOS" in Morse: 100 ms dots, 300 ms dashes    */
#define LED_EFFECT_STEADY  3u  /*  solid on                                      */
#define LED_EFFECTS        4u  /*  number of effects                             */

static __SYSTICK_VOLATILE uint64_t system_uptime = 0;
static volatile uint32_t          led_mode    = LED_EFFECT_BLINK;
static volatile uint8_t           btn_pressed = 0;


int main(void) {
  /* Main program loop: initialize, process continuously, and idle between
   * operations. UART is started on the first pass of process() below, after
   * init() has switched the system clock to the PLL output. */
  for (init(); process(); idle());
}


/**
 * @brief  Returns pointer to the system uptime counter
 * @retval Pointer to volatile 64-bit uptime value (milliseconds/ticks)
 */
__STATIC_FORCEINLINE __SYSTICK_VOLATILE uint64_t * uptime(void) {
  return &system_uptime;
}


/**
 * @brief  SysTick event processing - handles uptime increment and the LED
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

  uint64_t t = ++*uptime();

  /* While B1 is held down, light the LED solid as visual feedback */
  if (btn_pressed) {
    GPIOB->BSRR = GPIO_BSRR_BS2;
    return;
  }

  switch (led_mode) {
    case LED_EFFECT_BLINK:   /* bit [9]: toggle every 512 ms */
      GPIOB->BSRR = (t & (1ULL << 9)) ? GPIO_BSRR_BS2 : GPIO_BSRR_BR2;
      break;

    case LED_EFFECT_FAST:    /* bit [6]: toggle every 64 ms */
      GPIOB->BSRR = (t & (1ULL << 6)) ? GPIO_BSRR_BS2 : GPIO_BSRR_BR2;
      break;

    case LED_EFFECT_SOS:     /* S O S : dot=100 ms, dash=300 ms, letter gap 300 ms */
      {
        static const uint8_t sos[30] = {
          1,0,1,0,1,0,  0,0,             /* S, then letter gap (300 ms after last dot) */
          1,1,1, 0,  1,1,1, 0,  1,1,1,   /* O                                           */
          0, 0, 0,                        /* letter gap                                 */
          1,0,1,0,1,0,  0,0             /* S, then letter gap so the cycle wraps cleanly */
        };
        GPIOB->BSRR = sos[(t / 100) % 30] ? GPIO_BSRR_BS2 : GPIO_BSRR_BR2;
      }
      break;

    case LED_EFFECT_STEADY:
    default:
      GPIOB->BSRR = GPIO_BSRR_BS2;
      break;
  }
}


/**
 * @brief  Idle state handler - processes pending events during main loop idle time
 */
__STATIC_FORCEINLINE void idle(void) {
  process_systick_event();
} /* idle() */


/**
 * @brief  Main processing routine - debounces B1, cycles the LED effect and
 *         reports the uptime once per second over USART2.
 * @retval Non-zero to continue main loop execution, zero to exit
 */
__STATIC_FORCEINLINE unsigned process(void) {
  static uint8_t  started    = 0;
  static uint32_t last_sample = 0;
  static uint32_t history    = 0;
  static uint32_t last_sec   = 0;

  /* One-time startup banner once the system clock is up */
  if (!started) {
    started = 1;
    uart_init();
    uart_puts("\r\n\r\n");
    uart_puts("STM32F446RE  (STM32F446RET6)  bare-metal demo\r\n");
    uart_puts("HCLK = ");
    uart_print_u32((uint32_t)(SystemCoreClock / 1000000u));
    uart_puts(" MHz, SysTick 1 ms, USART2 115200 8N1\r\n");
    uart_puts("Press B1 (PC13) to cycle LED (PB2): 0=blink 1=fast 2=SOS 3=steady\r\n");
  }

  /* Sample the button once per SysTick (1 ms) into a 10-bit shift register
   * and treat 10 equal samples as a stable level (10 ms debounce). */
  uint32_t tick = (uint32_t)*uptime();
  if (tick != last_sample) {
    last_sample = tick;
    history = (history << 1) | (0u != (GPIOC->IDR & GPIO_IDR_ID13));
  }

  if ((history & 0x3FFu) == 0x3FFu) {      /* debounced pressed */
    if (!btn_pressed) {
      btn_pressed = 1;
      led_mode = (led_mode + 1u) % LED_EFFECTS;
      uart_puts("  B1 pressed -> LED effect = ");
      uart_print_u32(led_mode);
      uart_puts("\r\n");
    }
  } else if ((history & 0x3FFu) == 0u) {  /* debounced released */
    btn_pressed = 0;
  }

  /* Report the uptime once per second */
  uint32_t sec = (uint32_t)(*uptime() / 1000u);
  if (sec != last_sec) {
    last_sec = sec;
    uart_puts("  t = ");
    uart_print_u32(sec);
    uart_puts(" s, mode = ");
    uart_print_u32(led_mode);
    uart_puts("\r\n");
  }

  return !0;  /* Always continue loop */
} /* process() */

EOF
  echo "File $main_c_file created."
fi


# URLs for files
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f4/master/Source/Templates/system_stm32f4xx.c
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f4/master/Source/Templates/gcc/startup_stm32f446xx.s
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f4/master/Source/Templates/arm/startup_stm32f446xx.s
#
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f4/master/Include/system_stm32f4xx.h
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f4/master/Include/stm32f4xx.h
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f4/master/Include/stm32f446xx.h
#
#               https://github.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include
#
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_compiler.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_armclang.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_gcc.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_iccarm.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_version.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/core_cm4.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_armcc.h
#
#    https://raw.githubusercontent.com/cmsis-svd/cmsis-svd-data/refs/heads/main/data/STMicro/STM32F446.svd

fname1=("system_stm32f4xx.c" "startup_stm32f446xx.s")
fname2=("system_stm32f4xx.h" "stm32f4xx.h" "stm32f446xx.h")
fname3=("cmsis_compiler.h" "cmsis_armclang.h" "cmsis_gcc.h" "cmsis_iccarm.h" "cmsis_version.h" "core_cm4.h" "cmsis_armcc.h" "mpu_armv7.h")

raw_github="https://raw.githubusercontent.com/"

url1="${raw_github}STMicroelectronics/cmsis-device-f4/refs/heads/master"
url2="${raw_github}ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/"
url3="${raw_github}cmsis-svd/cmsis-svd-data/refs/heads/main/data/STMicro/STM32F446.svd"

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
download_file "${url3}" "STM32F446.svd"

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
create_file "README.md" << 'EOF'
# STM32F446RE Demo

Bare-metal example for the **STM32F446RET6** (WeAct-style board), generated by
`f446re_demo.sh`. It demonstrates a 180 MHz clock (the rated maximum for the
F446, the first Cortex-M4F at 180 MHz), a multi-effect **LED** on **PB2**,
a debounced **user button** on **PC13**, and an interactive **USART2** console
on PA2 TX — all using only CMSIS.

The example intentionally reuses the best practices of the other demos and adds
a few things none of them had: a working GPIO input (button) with debounce,
a real UART driver with an interactive console, correct F446 voltage-scaling
sequence (PWR Scale 1 + VOSRDY polling).

---

## What the script does

`f446re_demo.sh` is a self-contained project generator. Running it:

1. Creates the directory tree (`inc/`, `src/`, `MDK-ARM/`).
2. Generates the CMSIS-based configuration headers with `stm32cgen`:
   - `inc/main.h` — top-level config (clock, SysTick, init order) and the
     `init()` sequence (`init_rcc` -> `init_gpio` -> `init_systick`).
   - `inc/rcc.h` — `init_rcc()`, `configure_flash()` and
     `wait_for_clock_stable()`; the PLL factor bits are computed from
     `HCLK * PLLM * PLLP / HSE` and wired through `--tag-bit`.
   - `inc/gpio.h` — `init_gpio()` with the SWD pins, the PB2 LED, the PC13
     button (input + pull-down) and the PA2 USART2_TX alternate function.
   - `inc/uart.h` — a tiny hand-written, header-only USART2 driver
     (115200 8N1, blocking TX).
3. Downloads the vendor CMSIS files (device header, startup, system init)
   and the SVD description from upstream sources (cached for re-runs).
4. Writes `src/main.c`, the linker script, the Makefile and the
   debugger/IDE configurations.
5. Builds the project with `make debug` to verify everything is consistent.

All downloaded files are cached — re-running the script skips what already
exists and only rebuilds.

---

## Project structure

```
f446re_demo/
??? README.md                 # this file
??? Makefile                  # GNU make build (arm-none-eabi-gcc)
??? STM32F446.svd             # peripheral description (shared by MDK/Ozone/SES)
??? project.emProject         # SEGGER Embedded Studio project
??? project.jdebug            # Ozone debugger script
??? stm32f446re.jflash        # J-Link flash project
??? inc/
?   ??? main.h                # configuration + init() sequence
?   ??? rcc.h                 # init_rcc() / clock + PLL + flash configuration
?   ??? gpio.h                # init_gpio() + GPIO macros
?   ??? uart.h                # USART2 driver (hand-written)
?   ??? stm32f446xx.h         # CMSIS device header (downloaded)
?   ??? system_stm32f4xx.h
?   ??? ...                   # other CMSIS/core headers
??? src/
?   ??? main.c                # application: LED effects, button, UART console
?   ??? system_stm32f4xx.c    # SystemInit() (clock configured in init_rcc)
?   ??? startup_stm32f446xx.s # GCC startup (for the Make build)
??? MDK-ARM/
?   ??? Project.uvprojx       # Keil MDK-ARM project (Debug/Release)
?   ??? startup_stm32f446xx.s # ARM/Keil assembly startup (for MDK)
??? _build/                   # make output: Project.elf / .hex / .bin / .map
```

> The SVD file lives at the demo root so it can be shared by all the debugger
> configs: MDK via `<SFDFile>..\STM32F446.svd</SFDFile>`, Ozone via
> `$(ProjectDir)/STM32F446.svd`, and SES via
> `debug_svd_file="$(ProjectDir)/STM32F446.svd"`.

---

## Clock — 180 MHz

The F446 is the first STM32F4 to run at **180 MHz** (the F407 demo here tops
out at 168 MHz). `main.h` sets `HCLK = 180`; `rcc.h` implements:

| Stage        | Value      | Result                |
|--------------|------------|-----------------------|
| HSE          | 8 MHz      | WeAct-style F446RE crystal |
| PLLM         | 8          | VCO in = 1 MHz        |
| PLLN         | 360        | VCO = 360 MHz         |
| PLLP         | 2          | PLL = 180 MHz          |
| AHB (HPRE)   | /1         | HCLK = 180 MHz        |
| APB1 (PPRE1) | /4         | PCLK1 = 45 MHz        |
| APB2 (PPRE2) | /2         | PCLK2 = 90 MHz        |
| PLLQ         | 6          | 60 MHz (not 48)       |

### Verified 180 MHz (`SystemCoreClock` is hard-coded)

The PLL output was measured on this board (TIM2 against the 8 MHz HSE over
5 seconds) and is exactly 180 MHz, so `wait_for_clock_stable()` simply stores
`SystemCoreClock = 180000000u`. The earlier `calibrate_hclk()` measurement
(MCO1/TIM2/TIM5) was removed once the board was proven to hit the programmed
frequency.

`configure_flash()` performs the correct F446 power sequence before the clock
switch: it enables the PWR clock, selects **regulator Scale 1** by writing
`PWR_CR_VOS_1` (a two-bit field on F446, unlike the single bit on F407), waits
for `PWR_CSR_VOSRDY`, and programs the flash with **6 wait states** plus
prefetch and both caches. The PLL factor bits in `rcc.h` are computed from the
`HCLK` / `PLLM` / `PLLP` / `HSE` macros, so the same generator command can be
reused for other clock frequencies.

> Note on USB: 180 MHz cannot produce a 48 MHz USB clock from an 8 MHz HSE
> (360 / Q is never 48). To use OTG, switch `HCLK` to 168 MHz and `PLLQ` to 7
> (exactly as in the F407 demo); the rest of the code is frequency-agnostic.

---

## GPIO

- **LED — PB2**, active **HIGH** (pin HIGH = LED on).
- **B1  — PC13**, active **HIGH**, internal **pull-down**, debounced in software.
- **PA2 — USART2 TX**, AF7, high speed.
- **PA13/PA14** — SWD (kept as AF in debug builds via `SWD_EN`).

`gpio.h` is generated by `stm32cgen` (`GPIOA GPIOB GPIOC`) using the same
analog-by-default XOR scheme as the F4 demos, adapted to the F446 register
bit naming (`GPIO_MODER_MODER2`, `GPIO_OTYPER_OT2`, ...). The button input
adds a `GPIOC_PUPDR` pull-down — the first *input* in any demo here.

---

## UART console (virtual COM port)

`uart.h` configures USART2 (APB1, 45 MHz) for 115200 8N1 with a correctly
rounded `BRR` and a blocking `uart_putc()`. Connect a terminal to the board's
USART2 header (PA2 TX):

- On startup the banner is printed.
- Every second the uptime and the current LED mode are reported.
- Pressing **B1** cycles the LED effect and prints the new mode.

`USART2` is deliberately kept out of the generated RCC/GPIO `*_EN` auto-wiring:
keeping those macros undefined means `main.h`'s `init()` never tries to call a
generated `init_usart()`. The pin is still declared once in `gpio.h` as
`PA2_AF7_USART2_TX`, so `init_gpio()` routes PA2 to USART2_TX (AF7, high speed);
`uart_init()` only enables `RCC_APB1ENR_USART2EN`, programs the baud rate and
raises UE/TE, keeping the pin setup in a single place. The auto-wiring is still
demonstrated by `GPIOA_EN`/`GPIOB_EN`/`GPIOC_EN`, which the generated `rcc.h`
picks up from `gpio.h` to clock the GPIO ports.

---

## Main loop

`src/main.c` runs the standard `for (init(); process(); idle());` loop with a
1 kHz SysTick (polling mode by default; switch `SYSTICK_IRQ_ENABLE` to `YES`
for IRQ mode):

```c
uint64_t t = ++*uptime();
switch (led_mode) {
  case LED_EFFECT_BLINK: GPIOB->BSRR = (t & (1ULL << 9)) ? GPIO_BSRR_BS2 : GPIO_BSRR_BR2; break;
  case LED_EFFECT_FAST:  GPIOB->BSRR = (t & (1ULL << 6)) ? GPIO_BSRR_BS2 : GPIO_BSRR_BR2; break;
  case LED_EFFECT_SOS:   GPIOB->BSRR = sos[(t / 100) % 30] ? GPIO_BSRR_BS2 : GPIO_BSRR_BR2; break;
  case LED_EFFECT_STEADY: GPIOB->BSRR = GPIO_BSRR_BS2; break;
}
```

`process()` debounces B1 by shifting its level into a 10-bit register once per
SysTick (10 ms window), advances the effect on a rising edge, and reports the
uptime each second.

---

## Building

### GNU Make (arm-none-eabi-gcc)

```sh
bash ./f446re_demo.sh  # generate + build (debug target)
make            # minimal build -> _build/Project.elf (+ .hex, .bin)
make debug      # debug build (-Og -g3 -gdwarf)
make size       # print ELF section sizes
make program    # flash via ST-Link
make jprogram   # flash via J-Link (J-Flash)
make clean      # remove build output
```

### Keil MDK-ARM

Open `MDK-ARM/Project.uvprojx` in uVision, or build headlessly:

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

SES uses its own built-in startup files; the external
`startup_stm32f446xx.s` is only consumed by the MDK project.

---

## Flashing and debugging

Connect a J-Link (or an external ST-Link) to the board: SWDIO -> PA13,
SWCLK -> PA14, GND -> GND, 3.3V -> 3.3V.

- **Ozone** (J-Link): open `project.jdebug`; it loads `_build/Project.elf`
  and the shared SVD.
- **J-Flash / J-Link Commander**: `make jprogram` uses `stm32f446re.jflash`
  (device `STM32F446RE`).
- **ST-Link CLI** (Windows):
  ```sh
  ST-LINK_CLI.exe -c SWD SWCLK=4000 UR -P _build/Project.hex -Rst -Run
  ```
- **MDK / SES**: use the integrated flash + debug buttons.

---

## Configuration knobs

The main tunables live at the top of `inc/main.h`:

| Macro                 | Default | Meaning                          |
|-----------------------|---------|----------------------------------|
| `HCLK`                | `180`   | System clock in MHz (48-180)     |
| `SYSTICK_CLOCK_SOURCE`| `0`     | 0 = HCLK/8, 1 = HCLK             |
| `SYSTICK_ENABLE`      | `YES`   | enable SysTick                   |
| `SYSTICK_IRQ_ENABLE`  | `NO`    | IRQ vs polling mode              |

To change the LED/button pins, edit the `GPIOx_MODE` defines in
`inc/gpio.h` (or the `stm32cgen` invocation in the `.sh` script); the matching
`GPIOx_EN` clock-enable bits are derived automatically.

---

## References

- STM32F446 datasheet (DS10693), RM0390 (STM32F446 reference manual)
- [stm32codegen](https://github.com/a5021/stm32codegen) — generates
  `main.h` / `rcc.h` / `gpio.h` from the command line
- [BluePill_Project_Generator](https://github.com/a5021/BluePill_Project_Generator)
  — source of the GPIO macros and the overall structure
EOF

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
