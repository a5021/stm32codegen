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
       HCLK                   "8    /* 8 to 64 (MHz) with a step of 4 */"\
       ""\
       SYSTICK_CLOCK_SOURCE   "0    /* 0 = HCLK / 8; 1 = HCLK         */"\
       SYSTICK_ENABLE         YES\
       SYSTICK_IRQ_ENABLE     NO\
    \
    -H "#if HCLK < 8 || HCLK > 64 || (HCLK % 4 != 0)"\
    -H "  #error \"Invalid HCLK value. Must be between 8 and 64 MHz with a step of 4 MHz.\""\
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
    -F "  void _close_r(void){} void _close(void){} void _lseek_r(void){} void _lseek(void){} void _read_r(void){} void _read(void){} void _write_r(void){}" \
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
       PA0_AF1_USART1_CTS "PIN_AF(0, 1ULL)"\
       PA1_AF0_EVENTOUT "PIN_AF(1, 0ULL)"\
       PA1_AF1_USART1_RTS "PIN_AF(1, 1ULL)"\
       PA2_AF1_USART1_TX "PIN_AF(2, 1ULL)"\
       PA3_AF1_USART1_RX "PIN_AF(3, 1ULL)"\
       PA4_AF0_SPI1_NSS "PIN_AF(4, 0ULL)"\
       PA4_AF1_USART1_CK "PIN_AF(4, 1ULL)"\
       PA4_AF4_TIM14_CH1 "PIN_AF(4, 4ULL)"\
       PA5_AF0_SPI1_SCK "PIN_AF(5, 0ULL)"\
       PA6_AF0_SPI1_MISO "PIN_AF(6, 0ULL)"\
       PA6_AF1_TIM3_CH1 "PIN_AF(6, 1ULL)"\
       PA6_AF2_TIM1_BKIN "PIN_AF(6, 2ULL)"\
       PA6_AF5_TIM16_CH1 "PIN_AF(6, 5ULL)"\
       PA6_AF6_EVENTOUT "PIN_AF(6, 6ULL)"\
       PA7_AF0_SPI1_MOSI "PIN_AF(7, 0ULL)"\
       PA7_AF1_TIM3_CH2 "PIN_AF(7, 1ULL)"\
       PA7_AF2_TIM1_CH1N "PIN_AF(7, 2ULL)"\
       PA7_AF4_TIM14_CH1 "PIN_AF(7, 4ULL)"\
       PA7_AF5_TIM17_CH1 "PIN_AF(7, 5ULL)"\
       PA7_AF6_EVENTOUT "PIN_AF(7, 6ULL)"\
       PA9_AF1_USART1_TX "PIN_AF(9, 1ULL)"\
       PA9_AF2_TIM1_CH2 "PIN_AF(9, 2ULL)"\
       PA9_AF4_I2C1_SCL "PIN_AF(9, 4ULL)"\
       PA10_AF0_TIM17_BKIN "PIN_AF(10, 0ULL)"\
       PA10_AF1_USART1_RX "PIN_AF(10, 1ULL)"\
       PA10_AF2_TIM1_CH3 "PIN_AF(10, 2ULL)"\
       PA10_AF4_I2C1_SDA "PIN_AF(10, 4ULL)"\
       PA13_AF0_SWDIO "PIN_AF(13, 0ULL)"\
       PA13_AF1_IR_OUT "PIN_AF(13, 1ULL)"\
       PA14_AF0_SWCLK "PIN_AF(14, 0ULL)"\
       PA14_AF1_USART1_TX "PIN_AF(14, 1ULL)"\
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
    -H "#ifndef USART1_EN"\
    -H "  #define USART1_EN 0"\
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
    -H '  !USART1_EN * PIN_MODE(2,  PIN_MODE_OUTPUT) /* PA2  -- OUTPUT     */ | \'\
    -H '  !USART1_EN * PIN_MODE(3,  PIN_MODE_OUTPUT) /* PA3  -- OUTPUT     */ | \'\
    -H '  USART1_EN  * PIN_MODE(2,  PIN_MODE_AF)     /* PA2  -- USART1 TX  */ | \'\
    -H '  USART1_EN  * PIN_MODE(3,  PIN_MODE_AF)     /* PA3  -- USART1 RX  */ | \'\
    -H '  !SPI1_EN   * PIN_MODE(4,  PIN_MODE_OUTPUT) /* PA4  -- OUTPUT     */ | \'\
    -H '  SPI1_EN    * PIN_MODE(4,  PIN_MODE_AF)     /* PA4  -- SPI1 CS    */ | \'\
    -H '  SPI1_EN    * PIN_MODE(5,  PIN_MODE_AF)     /* PA5  -- SPI1 SCK   */ | \'\
    -H '  SPI1_EN    * PIN_MODE(6,  PIN_MODE_AF)     /* PA6  -- SPI1 MISO  */ | \'\
    -H '  SPI1_EN    * PIN_MODE(7,  PIN_MODE_AF)     /* PA7  -- SPI1 MOSI  */ | \'\
    -H '  I2C1_EN    * PIN_MODE(9,  PIN_MODE_AF)     /* PA9  -- I2C1 SDA   */ | \'\
    -H '  I2C1_EN    * PIN_MODE(10, PIN_MODE_AF)     /* PA10 -- I2C1 SCL   */ | \'\
    -H '  SWD_EN     * PIN_MODE(13, PIN_MODE_AF)     /* PA13 -- SWDCLK     */ | \'\
    -H '  SWD_EN     * PIN_MODE(14, PIN_MODE_AF)     /* PA14 -- SWDIO      */   \'\
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
    -H "  USART1_EN * PA2_AF1_USART1_TX             | \\"\
    -H "  USART1_EN * PA3_AF1_USART1_RX             | \\"\
    -H "  SPI1_EN   * PA4_AF0_SPI1_NSS              | \\"\
    -H "  SPI1_EN   * PA5_AF0_SPI1_SCK              | \\"\
    -H "  SPI1_EN   * PA6_AF0_SPI1_MISO             | \\"\
    -H "  SPI1_EN   * PA7_AF0_SPI1_MOSI             | \\"\
    -H "  I2C1_EN   * PA9_AF4_I2C1_SCL              | \\"\
    -H "  I2C1_EN   * PA10_AF4_I2C1_SDA             | \\"\
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
/Td6WFoAAATm1rRGAgAhARwAAAAQz1jM4AQDAcRdADsbyWDW/2zquwwHdYzOwgOvw6pB2bhQyE04
OSxh7dKJxtJXcx+WPS32SgPuOcnCfpkhAX/lVcg5iFIlp044hAJI94cGdeK+X7XT2CORKAR7ioXC
4O9qB8+HmFaro4eYZP44UNWhB0HjDqKARcHdkk8x9IX1oPbzuXOnQ9ad2/4fn4otASV8QczL0pZH
ClujI8W++U/w2MHQ/ZKKzvBfTzCjXx/L4Gen6ezd67u/eoUs+jMpEHBytTc6Bzme+j2wYFyu+DLs
kp5hwhSZBOIdlYI6yX+kzAOh7qck/iHM6zbThxfk5L+lRC8X+inE6vBD5W0qDS4caAKN7z4VyWsN
da1+Uc+7ocInSHBbt9fhU2zcOZr7ImGnzZOdCILz/9tJKdbvokbke4lBwhRMzuEoNFbAOvtR+Ks/
wW+3VE33h0ZDpl09wRBe+pxAD9o1R+QaLuruXW7X4euh1HSmSTKs3xhxUy1kTT6dcv+fQfIx9PUP
37vUJyABDXIxhM4bj2DvpHV5Dm3t8jqoOppoSY18K20KG21Bz07h2rkDqQ4mOgg78dI91Qo1BV1x
+60Cx84Ik9oUJGROvRRKAkZ0BLJe0hIJzmZsAAHDJ97ieMKrAAHgA4QIAABbxZn+scRn+wIAAAAA
BFla
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
 *         depending on SYSTICK_IRQ_EN configuration
 */
#if YES == SYSTICK_IRQ_EN

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
  GPIOA->BSRR = ++*uptime() & (1 << 9) ? GPIO_BSRR_BS4 : GPIO_BSRR_BR4;

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
