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
    
    for cmd in curl arm-none-eabi-gcc base64 xz make; do
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

if [ -e stm32g031xx.h ]; then
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

generate_header "main.h" $opt g031f8 -M\
    -D NO                     0\
       NONE                   NO\
       OFF                    NO\
       YES                    \(\!NO\)\
       ON                     YES\
       ""\
       HCLK                   "16   /* 16 to 64 (MHz) with a step of 4 */"\
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
    -F "  __attribute__((used)) void _close_r(void){} __attribute__((used)) void _close(void){} __attribute__((used)) void _lseek_r(void){} __attribute__((used)) void _lseek(void){} __attribute__((used)) void _read_r(void){} __attribute__((used)) void _read(void){} __attribute__((used)) void _write_r(void){} __attribute__((used)) void _write(void){}" \
    -F \#endif

func_name=wait_for_clock_stable
tag=R
generate_header "rcc.h" -l g031f8 -p RCC -m rcc -f init_rcc\
    \
    -D $tag '(HCLK >= 32)'\
       ""\
       PLLN_VAL "(HCLK / 4)        /* PLLN: HSI16/1*PLLN/4 = HCLK */"\
       PLLN_0    "((PLLN_VAL >> 0) & 1)"\
       PLLN_1    "((PLLN_VAL >> 1) & 1)"\
       PLLN_2    "((PLLN_VAL >> 2) & 1)"\
       PLLN_3    "((PLLN_VAL >> 3) & 1)"\
       PLLN_4    "((PLLN_VAL >> 4) & 1)"\
       PLLN_5    "((PLLN_VAL >> 5) & 1)"\
       PLLN_6    "((PLLN_VAL >> 6) & 1)"\
    \
    --tag-bit R PLLON HSION\
    --tag-bit PLLN_0 PLLN_0\
    --tag-bit PLLN_1 PLLN_1\
    --tag-bit PLLN_2 PLLN_2\
    --tag-bit PLLN_3 PLLN_3\
    --tag-bit PLLN_4 PLLN_4\
    --tag-bit PLLN_5 PLLN_5\
    --tag-bit PLLN_6 PLLN_6\
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
    -F "    /* PLLM=1, PLLR=4 => PLL output = HSI16 * PLLN / 4 = HCLK */"\
    -F "    RCC->PLLCFGR = ("\
    -F "      RCC_PLLCFGR_PLLSRC_HSI"\
    -F "    | RCC_PLLCFGR_PLLM_0"\
    -F "    | RCC_PLLCFGR_PLLR_1"\
    -F "    | RCC_PLLCFGR_PLLREN"\
    -F "    | (PLLN_VAL << RCC_PLLCFGR_PLLN_Pos)"\
    -F "    );"\
    -F "    while(RCC_CFGR_SWS_PLLRCLK != (RCC->CFGR & RCC_CFGR_SWS)) {}"\
    -F "  #endif"\
    -F "} /* $func_name() */"\
    -F ""\
    -F "#undef PLLN_0"\
    -F "#undef PLLN_1"\
    -F "#undef PLLN_2"\
    -F "#undef PLLN_3"\
    -F "#undef PLLN_4"\
    -F "#undef PLLN_5"\
    -F "#undef PLLN_6"\
    -F "#undef $tag"


"${py_gen[@]}" -l g031f8 -p GPIOA -m gpio -f init_gpio\
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
        PA0_AF1_USART2_CTS "PIN_AF(0, 1ULL)"\
        PA0_AF5_LPTIM1_OUT "PIN_AF(0, 5ULL)"\
        PA1_AF0_SPI1_SCK "PIN_AF(1, 0ULL)"\
        PA1_AF1_USART2_RTS "PIN_AF(1, 1ULL)"\
        PA1_AF2_TIM2_CH2 "PIN_AF(1, 2ULL)"\
        PA1_AF6_I2C1_SMBA "PIN_AF(1, 6ULL)"\
        PA1_AF7_EVENTOUT "PIN_AF(1, 7ULL)"\
        PA2_AF0_SPI1_MOSI "PIN_AF(2, 0ULL)"\
        PA2_AF1_USART2_TX "PIN_AF(2, 1ULL)"\
        PA2_AF2_TIM2_CH3 "PIN_AF(2, 2ULL)"\
        PA2_AF6_LPUART1_TX "PIN_AF(2, 6ULL)"\
        PA3_AF0_SPI2_MISO "PIN_AF(3, 0ULL)"\
        PA3_AF1_USART2_RX "PIN_AF(3, 1ULL)"\
        PA3_AF2_TIM2_CH4 "PIN_AF(3, 2ULL)"\
        PA3_AF6_LPUART1_RX "PIN_AF(3, 6ULL)"\
        PA3_AF7_EVENTOUT "PIN_AF(3, 7ULL)"\
        PA4_AF0_SPI1_NSS "PIN_AF(4, 0ULL)"\
        PA4_AF1_SPI2_MOSI "PIN_AF(4, 1ULL)"\
        PA4_AF4_TIM14_CH1 "PIN_AF(4, 4ULL)"\
        PA4_AF5_LPTIM2_OUT "PIN_AF(4, 5ULL)"\
        PA4_AF7_EVENTOUT "PIN_AF(4, 7ULL)"\
        PA5_AF0_SPI1_SCK "PIN_AF(5, 0ULL)"\
        PA5_AF2_TIM2_CH1 "PIN_AF(5, 2ULL)"\
        PA5_AF5_LPTIM2_ETR "PIN_AF(5, 5ULL)"\
        PA5_AF7_EVENTOUT "PIN_AF(5, 7ULL)"\
        PA6_AF0_SPI1_MISO "PIN_AF(6, 0ULL)"\
        PA6_AF1_TIM3_CH1 "PIN_AF(6, 1ULL)"\
        PA6_AF2_TIM1_BK "PIN_AF(6, 2ULL)"\
        PA6_AF5_TIM16_CH1 "PIN_AF(6, 5ULL)"\
        PA6_AF6_LPUART1_CTS "PIN_AF(6, 6ULL)"\
        PA7_AF0_SPI1_MOSI "PIN_AF(7, 0ULL)"\
        PA7_AF1_TIM3_CH2 "PIN_AF(7, 1ULL)"\
        PA7_AF2_TIM1_CH1N "PIN_AF(7, 2ULL)"\
        PA7_AF4_TIM14_CH1 "PIN_AF(7, 4ULL)"\
        PA7_AF5_TIM17_CH1 "PIN_AF(7, 5ULL)"\
        PA9_AF1_USART1_TX "PIN_AF(9, 1ULL)"\
        PA9_AF2_TIM1_CH2 "PIN_AF(9, 2ULL)"\
        PA9_AF4_SPI2_MISO "PIN_AF(9, 4ULL)"\
        PA9_AF6_I2C1_SCL "PIN_AF(9, 6ULL)"\
        PA9_AF7_EVENTOUT "PIN_AF(9, 7ULL)"\
        PA10_AF1_USART1_RX "PIN_AF(10, 1ULL)"\
        PA10_AF2_TIM1_CH3 "PIN_AF(10, 2ULL)"\
        PA10_AF5_TIM17_BK "PIN_AF(10, 5ULL)"\
        PA10_AF6_I2C1_SDA "PIN_AF(10, 6ULL)"\
        PA10_AF7_EVENTOUT "PIN_AF(10, 7ULL)"\
        PA13_AF0_SWDIO "PIN_AF(13, 0ULL)"\
        PA13_AF1_IR_OUT "PIN_AF(13, 1ULL)"\
        PA13_AF7_EVENTOUT "PIN_AF(13, 7ULL)"\
        PA14_AF0_SWCLK "PIN_AF(14, 0ULL)"\
        PA14_AF1_USART2_TX "PIN_AF(14, 1ULL)"\
        PA14_AF7_EVENTOUT "PIN_AF(14, 7ULL)"\
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
    -H "#ifndef USART_EN"\
    -H "  #define USART_EN 0"\
    -H "#endif"\
    -H ""\
    -H "#ifndef SPI1_EN"\
    -H "  #define SPI1_EN 0"\
    -H "#endif"\
    -H ""\
    -H "#ifndef I2C1_EN"\
    -H "  #define I2C1_EN 0"\
    -H "#endif"\
    -H ""\
    -H "#ifndef SWD_EN"\
    -H "  #ifndef NDEBUG"\
    -H "    #define SWD_EN 1"\
    -H "  #else"\
    -H "    #define SWD_EN 0"\
    -H "  #endif"\
    -H "#endif"\
    -H ""\
    -H "#define GPIO_MODE_EXAMPLE (       \\"\
    -H "  + PIN_MODE(0,  PIN_MODE_ANALOG) \\"\
    -H "  + PIN_MODE(1,  PIN_MODE_ANALOG) \\"\
    -H "  + PIN_MODE(2,  PIN_MODE_ANALOG) \\"\
    -H "  + PIN_MODE(3,  PIN_MODE_ANALOG) \\"\
    -H "  + PIN_MODE(4,  PIN_MODE_ANALOG) \\"\
    -H "  + PIN_MODE(5,  PIN_MODE_ANALOG) \\"\
    -H "  + PIN_MODE(6,  PIN_MODE_ANALOG) \\"\
    -H "  + PIN_MODE(7,  PIN_MODE_ANALOG) \\"\
    -H "  + PIN_MODE(8,  PIN_MODE_ANALOG) \\"\
    -H "  + PIN_MODE(9,  PIN_MODE_ANALOG) \\"\
    -H "  + PIN_MODE(10, PIN_MODE_ANALOG) \\"\
    -H "  + PIN_MODE(11, PIN_MODE_ANALOG) \\"\
    -H "  + PIN_MODE(12, PIN_MODE_ANALOG) \\"\
    -H "  + PIN_MODE(13, PIN_MODE_ANALOG) \\"\
    -H "  + PIN_MODE(14, PIN_MODE_ANALOG) \\"\
    -H "  + PIN_MODE(15, PIN_MODE_ANALOG) \\"\
    -H ")"\
    -H ""\
    -H '#define GPIOA_MODE (                                                    \'\
    -H '  !0         * PIN_MODE(0,  PIN_MODE_OUTPUT) /* PA0  -- OUTPUT     */ | \'\
    -H '  !0         * PIN_MODE(1,  PIN_MODE_OUTPUT) /* PA1  -- OUTPUT     */ | \'\
    -H '  !USART_EN * PIN_MODE(2,  PIN_MODE_OUTPUT) /* PA2  -- OUTPUT     */ | \'\
    -H '  !USART_EN * PIN_MODE(3,  PIN_MODE_OUTPUT) /* PA3  -- OUTPUT     */ | \'\
    -H '  USART_EN  * PIN_MODE(2,  PIN_MODE_AF)     /* PA2  -- USART2 TX  */ | \'\
    -H '  USART_EN  * PIN_MODE(3,  PIN_MODE_AF)     /* PA3  -- USART2 RX  */ | \'\
    -H '  !SPI1_EN   * PIN_MODE(4,  PIN_MODE_OUTPUT) /* PA4  -- OUTPUT     */ | \'\
    -H '  SPI1_EN    * PIN_MODE(4,  PIN_MODE_AF)     /* PA4  -- SPI1 CS    */ | \'\
    -H '  SPI1_EN    * PIN_MODE(5,  PIN_MODE_AF)     /* PA5  -- SPI1 SCK   */ | \'\
    -H '  SPI1_EN    * PIN_MODE(6,  PIN_MODE_AF)     /* PA6  -- SPI1 MISO  */ | \'\
    -H '  SPI1_EN    * PIN_MODE(7,  PIN_MODE_AF)     /* PA7  -- SPI1 MOSI  */ | \'\
    -H '  I2C1_EN    * PIN_MODE(9,  PIN_MODE_AF)     /* PA9  -- I2C1 SCL   */ | \'\
    -H '  I2C1_EN    * PIN_MODE(10, PIN_MODE_AF)     /* PA10 -- I2C1 SDA   */ | \'\
    -H '  SWD_EN     * PIN_MODE(13, PIN_MODE_AF)     /* PA13 -- SWDIO      */ | \'\
    -H '  SWD_EN     * PIN_MODE(14, PIN_MODE_AF)     /* PA14 -- SWDCLK     */   \'\
    -H ')'\
    -H ""\
    -H "#if 0"\
    -H "#define GPIOA_OTYPE (                         \\"\
    -H "  I2C1_EN   * (PIN_TYPE_OD << 9)            | \\"\
    -H "  I2C1_EN   * (PIN_TYPE_OD << 10)             \\"\
    -H ")"\
    -H "#else"\
    -H "#define GPIOA_OTYPE (                         \\"\
    -H "  I2C1_EN   * PIN_OTYPE(9,  PIN_TYPE_OD)    | \\"\
    -H "  I2C1_EN   * PIN_OTYPE(10, PIN_TYPE_OD)      \\"\
    -H ")"\
    -H "#endif"\
    -H ""\
    -H "#define GPIOA_OSPEED (                        \\"\
    -H "  SPI1_EN   * PIN_SPEED(4,  PIN_SPEED_HIGH) | \\"\
    -H "  SPI1_EN   * PIN_SPEED(5,  PIN_SPEED_HIGH) | \\"\
    -H "  SPI1_EN   * PIN_SPEED(6,  PIN_SPEED_HIGH) | \\"\
    -H "  SPI1_EN   * PIN_SPEED(7,  PIN_SPEED_HIGH)   \\"\
    -H ")"\
    -H ""\
    -H "#define GPIOA_AF (                            \\"\
    -H "  USART_EN  * PA2_AF1_USART2_TX             | \\"\
    -H "  USART_EN  * PA3_AF1_USART2_RX             | \\"\
    -H "  SPI1_EN   * PA4_AF0_SPI1_NSS              | \\"\
    -H "  SPI1_EN   * PA5_AF0_SPI1_SCK              | \\"\
    -H "  SPI1_EN   * PA6_AF0_SPI1_MISO             | \\"\
    -H "  SPI1_EN   * PA7_AF0_SPI1_MOSI             | \\"\
    -H "  I2C1_EN   * PA9_AF6_I2C1_SCL              | \\"\
    -H "  I2C1_EN   * PA10_AF6_I2C1_SDA             | \\"\
    -H "  SWD_EN    * PA13_AF0_SWDIO                | \\"\
    -H "  SWD_EN    * PA14_AF0_SWCLK                  \\"\
    -H ")"\
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
        if base64 -d | xz -qdc > "$filename"; then
            if [ -s "$filename" ]; then  # Check file is not empty
                ((++op_counter))
                echo "File $filename created."
            else
                echo "Error: $filename is empty after creation" >&2
                rm -f "$filename"
                return 1
            fi
        else
            echo "Error: Failed to decode/decompress $filename" >&2
            return 1
        fi
    fi
}

# Base64-encoded xz-compressed Makefile (generated with: cat Makefile | xz -9c | base64)
create_file "Makefile" << 'EOF'
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
EOF

create_file "stm32g031x8_flash.ld" << 'EOF'
/Td6WFoAAATm1rRGAgAhARYAAAB0L+Wj4Az4BBddABeKgCRDWZigxFgAKUhK1Ev7lGpI9l8XUoFV
5/QHJi6P4/TdOYJw3WwqJ3YkQNxliitnsSeWQRVTcXAeaRrSbZuvr1yyI6JOM6SBLRq5rX68Himl
7Dw69JMmTCKn3il/7hn6WW/v0PqOxmm3hyVF/N6sJWcrTbtwWfpbRhQ5Ixx1k9FZjEPG6h8WvDpq
Cz6UD33xcc4VsoZUa8rEKOpjv5ByCqr2U5/E6/r+uGSgZVaZTR+n1SyPesnsXQIM8nP+rVeoU3rt
O2tlfE1lKgRPf9MxWYColB5zb7ylHqeyLnQISLAqJh1URxQHsIn17XolM8pl2h9geX3vBKd1zRcQ
nG7ENEriwvjQzAuXFAqYITHcdcgn8mzi/ET0uibEYegeS7fGg38e12lPKrTJCz9VlW5rpzOmGQ5f
hVnYAXpUzTlKhLXQHD9Wnhwn6iiC1ZGEtLgI16tClg47IAcb8bxTJJmBmoNLbc9mdeO1H78F4lzz
ELz7b4VlSdxmwUMrGNGCJ0mz6ghvH9gobCEeXU4NeBvT5isd85IL1JIKHe9iRlG1rivn3KfREMAK
jOuqfgh/po+yVQKUQVzL9Z9yWKJ3/zVUEjIo1vSu10or0adMUffjun5aF8WcYBffJVZj6zv3pqOb
4y6rXnGPuXwI8UKzB8wPXs0a3iPRZr0tqCzKXA9Y0dHUZPZEnWA+AdkZOBDepsRnnW0ar91uUoCw
/h9ogpSRhQp1jVxDd4eCUjBF1JeTc4Fldh+RCLmJwAt5m37g+IvAWyI7+ni90zAC4bUbFpeL44yj
zima3qnLLyWsSlHcX/FfoATNnre0UvQKUKTJ1VxSBdk1Pqt+FjRTc91vCZcRLnTTKAAlzhv03GLV
5QfPw9EbWM/GpNVcSlRsxQCElIQCV4Vf0+R7oDrA7d4B9zYAgmgKqDDsKeXK9gCW1kjs6YTsYSN8
tZQpEVBYuv4OT78Ih1uB9Tv83hD+QE10LoDimXpu/mi2WcXND2NdgG8nud6wsEH2pU8yIqh+17f4
/b+yZStWsuuxjOMIXU+sYA9QPRX8RQJpeOtAiRKrIv0uKslM8GOXe8VBqo1VnMFkth5FHe6Nvcvr
dlDJJ/zDXQwKzHBuCN2wxvPCd78A91mu/GFbgDcraj8xT27H7NlbI58VEoKTre3WiHQ8afjkoZId
xnXpJ+vCpCVMYSDg9SIfhmmQwQlJotXSFzLCs3Lf2mgg2G61ssgPQXL1PGmFmtSen7aNLZhGb3MT
jpHEHjDHSOnmTlO1dRr9OyokSaaO+tdeL6YF5FliddF1s/2LEXZyRJ8sWHJMZUFHve+B5hg9jtaK
yDzqMA38asxaqjclQEmcRRQuDDgPPZeyka01WTUDEguGBaTXanHwFf5WkeRBWhQicwFgAAAAB+87
y0UqK1sAAbMI+RkAABU/4oexxGf7AgAAAAAEWVo=
EOF

create_file "MDK-ARM/Project.uvprojx" << 'EOF'
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
EOF

create_file "project.jdebug" << 'EOF'
/Td6WFoAAATm1rRGBMDNA9AHIQEcAAAAAAAAADTwe53gA88BxV0AOxvJYNb/bOq7DAd1jM7CA6/D
qkHZuFDITTg5LGHt0onG0ldzH5Y9LfZKA+45ycJ+mSEBf+VVyDmIUiWnTjiEAkj3hwZwbQosT8Dr
ntRGpss8S3WCYYF0PYOF6JP14SLUMT9xNOgYoNDY4WpZ5hTHTxmvgIAgEPg5gu03Td0R+XColeQD
VRvw/rJ6uQ7xQo7oXo1OFIs+ZuglR5BZpIUOGwqXGX5pQOg4Xj2kdOzsVtLmkHz2k19NpHBtwnoZ
Zckgt3CvSQQVwi2NNe14pV8G07vUq3ZDie4cTCC0bdZ8jO+KMLFOAgiK6cVRdve68oHqtaLiX+OR
B2uu4ID9FhQWmKAYZvBQrWF1huY82B1Ma4eD3mjHVAmmyoXGUIV8tNj+xrGTxhsDr2uosmyFDz8b
T7TIHBNxXCVMV8h30vcyJ1MMsRrIWdc8QYPOt8dDaULJ6SM9EAXobm2jrKQba4RCNiL2vJzGTv+j
bDkKx8JfqfD7Ds9KnQkxh4YQ+44L5smKxnE+mueWzpzTdBi/8uRnX5ZZDQmvBXyGwa9vuYeb5thH
hzn1P8tRPHYXJXojbO82m05oUw2mRfuuG1N8WuwgiKlBjTWAAAAAANvXKz9r7fCNAAHpA9AHAABb
S6WWscRn+wIAAAAABFla
EOF

create_file "stm32g031x8.jflash" << 'EOF'
/Td6WFoAAATm1rRGAgAhARYAAAB0L+Wj4AewAwZdABBhAOGFYzOihg56UIqKCKQrnqKasrAxa6gW
aeZG86Pk+G/iEId5CVjqnEwXAprd+mfglT4i426SWo/xS7YaD+CzdQCIqK5WCRH/2RwmT8+YuwJB
PpqcRsdUYfOKkq4h0s3MNcWVwMPOzcra1Mz2E7c/ufx7PcVXHoKnnAGUMvm4KmD9CsTR2PmMFFMl
H3wr484iM7+vJvsy8EiQQ1nbBIoLenldsybldPbO95PH68xcmlmXJYuhcKYKQVFjBWAmswQvjVHT
2Fwde7zHqLfzQa9KvCPkWbD/ALiUhL4Dum0p3xlKrgWSUlBInXyh6b0TsLznCs9ZlguX3w11Xmdh
G4uPslLk3mxej0M67O3QE/SUKTJU9He8ODHT5mZjCFMhqDzCfeHu7lVBpoL8TSqwEaUlJYxA30zM
B13OUSfdRLd7v20DJJyH0+HTKlmlzkOD5DDabNTQJZheesSnHSv8D4iWlPFyWW5Vv67JsOKSl2IR
0THA1JU9FqiIMc7/c4NOFKY/9FSx5Sgyjwwa2TUzIgZhFm+mRwzA+Nzy1tK+u4Ac7ldoTAGupGmN
+Gb0jLxcWtZhL6RRz8/uQpGzzI3+u2alKShFCor1iok+Qfh00vAJyTFOMVyLFyTQz7+LsJTRTWN0
s21i/452w2qm/NEXO8JAhXaXgB82IdnrOObqFEGuV2LSD6Cvv3Jbj2lpQ8lfgEUgU40qBfWAkVfo
UFMMMxSotnR8QKQgusmjwnvj2tLGFyRzd+m4/M2+CsnLfwtEz9Sz4U6pbFw26+3o7JNoLmKlm5cH
7IpNu3TIVTuUMGpSZ7NEMF/U+P0XuT43o801HIreTckaJ76DVm6cNYmR42qPgnqEZ7bEgFbOkr/c
YRVqAzOW25NC++jPyPhGNZahSwVBGymA34KDvcCaqTz0r6XlWEAzepHTmWgrqLYeLuOb/94z4rpA
koHqswJFOxpoCg9sQdMCkQTtYXPQnPPOiBTyS6fUsu5O8rjJ+dTN6EiIiL/4TXZX4ftWyzTOY5cI
nV/R+oiBRwAAABT7FKjJJSjjAAGiBrEPAABa/1O2scRn+wIAAAAABFla
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
  
  /* Increment uptime counter and toggle PA4 LED based on bit 9 state
   * When bit 9 of uptime is set: turn LED on (BSRR BS4)
   * When bit 9 of uptime is clear: turn LED off (BSRR BR4)
   * This creates a blink period of 2^10 = 1024 ticks */
  GPIOA->BSRR = (++*uptime() & (1 << 9)) ? GPIO_BSRR_BS4 : GPIO_BSRR_BR4;

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
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_g0/master/Source/Templates/system_stm32g0xx.c
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_g0/master/Source/Templates/gcc/startup_stm32g031xx.s
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_g0/master/Source/Templates/arm/startup_stm32g031xx.s
#
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_g0/master/Include/system_stm32g0xx.h
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_g0/master/Include/stm32g0xx.h
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_g0/master/Include/stm32g031xx.h
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
#    https://raw.githubusercontent.com/cmsis-svd/cmsis-svd-data/refs/heads/main/data/STMicro/STM32G031.svd 
#    https://raw.githubusercontent.com/cmsis-svd/cmsis-svd-data/refs/heads/main/data/STMicro/STM32G031.svd
     
     

fname1=("system_stm32g0xx.c" "startup_stm32g031xx.s")
fname2=("system_stm32g0xx.h" "stm32g0xx.h" "stm32g031xx.h")
fname3=("cmsis_compiler.h" "cmsis_armclang.h" "cmsis_gcc.h" "cmsis_iccarm.h" "cmsis_version.h" "core_cm0plus.h" "cmsis_armcc.h" "mpu_armv7.h")

raw_github="https://raw.githubusercontent.com/"

url1="${raw_github}STMicroelectronics/cmsis-device-g0/refs/heads/master"
url2="${raw_github}ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/"
url3="${raw_github}cmsis-svd/cmsis-svd-data/refs/heads/main/data/STMicro/STM32G031.svd"

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
download_file "${url3}" "STM32G031.svd"

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
