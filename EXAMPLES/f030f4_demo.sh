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
    read -n 1 -s -r
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

if [ -e stm32f030x6.h ]; then
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
py_gen=("$py_name" "$PY_GEN/stm32cgen.py")

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

generate_header "main.h" $opt 030f4 -M\
    -D NO                     0\
       NONE                   NO\
       OFF                    NO\
       YES                    \(\!NO\)\
       ON                     YES\
       ""\
       HCLK                   "8    /* 8 to 68 (MHz) with a step of 4 */"\
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
generate_header "rcc.h" -l 030f4 -p RCC -m rcc -f init_rcc\
    \
    -D $tag '(HCLK >= 12)'\
       XMUL "(HCLK / 4 - 2)     /* Calculate PLL multiplication factor      */"\
       A    "((XMUL >> 0) & 1)  /* LSB or BIT0 of PLL multiplication factor */"\
       B    "((XMUL >> 1) & 1)  /*        BIT1 of PLL multiplication factor */"\
       C    "((XMUL >> 2) & 1)  /*        BIT2 of PLL multiplication factor */"\
       D    "((XMUL >> 3) & 1)  /* MSB or BIT3 of PLL multiplication factor */"\
    \
    --tag-bit R SW_PLL PLLON HSION HSITRIM_4\
    --tag-bit A PLLMUL_0\
    --tag-bit B PLLMUL_1\
    --tag-bit C PLLMUL_2\
    --tag-bit D PLLMUL_3\
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

generate_header "gpio.h" -l 030f4 -p GPIOA GPIOB GPIOF -m gpio -f init_gpio\
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
       "PIN_SPEED(PIN, SPEED)" "(((SPEED) << GPIO_OSPEEDR_OSPEEDR ## PIN ## _Pos) & GPIO_OSPEEDR_OSPEEDR ## PIN ## _Msk)"\
       "PIN_OTYPE(PIN, OTYPE)" "((OTYPE)   ? GPIO_OTYPER_OT_ ## PIN : 0)"\
       "PIN_PUPD(PIN, PUPD)" "(((PUPD)  << GPIO_PUPDR_PUPDR ## PIN ## _Pos) & GPIO_PUPDR_PUPDR ## PIN ## _Msk)"\
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
       PB1_AF0_TIM14_CH1 "PIN_AF(1, 0ULL)"\
       PB1_AF1_TIM3_CH4 "PIN_AF(1, 1ULL)"\
       PB1_AF2_TIM1_CH3N "PIN_AF(1, 2ULL)"\
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
       _BR\(PIN\) "GPIO_BSRR_BR_ ## PIN"\
       BR\(PIN\) _BR\(PIN\)\
       _BS\(PIN\) "GPIO_BSRR_BS_ ## PIN"\
       BS\(PIN\) _BS\(PIN\)\
       _ODR\(PIN\) "GPIO_ODR_ ## PIN"\
       ODR\(PIN\) _ODR\(PIN\)\
       ""\
       GPIOA_MODER "(GPIO_MODE ^ (GPIOA_MODE))"\
       GPIOB_MODER "(GPIO_MODE ^ (GPIOB_MODE))"\
       GPIOF_MODER "(GPIO_MODE ^ (GPIOF_MODE))"\
       ""\
       GPIOA_AFR_0 "(GPIOA_AF & UINT32_MAX)"\
       GPIOA_AFR_1 "((GPIOA_AF >> 32) & UINT32_MAX)"\
       ""\
       GPIOB_AFR_0 "(GPIOB_AF & UINT32_MAX)"\
       GPIOB_AFR_1 "((GPIOB_AF >> 32) & UINT32_MAX)"\
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
    -H ""\
    -H "#define GPIOB_MODE                     PIN_MODE(1,  PIN_MODE_AF)"\
    -H "#define GPIOB_OSPEEDR                  PIN_SPEED(1, PIN_SPEED_HIGH)"\
    -H ""\
    -H "#define GPIOB_AF                       PB1_AF2_TIM1_CH3N"\
    -H ""\
    -H "#define GPIOF_MODE (                          \\"\
    -H "  PIN_MODE(0,  PIN_MODE_INPUT)              | \\"\
    -H "  PIN_MODE(1,  PIN_MODE_INPUT)                \\"\
    -H ")"\
    -H ""\
    -H "#define GPIOF_PUPDR (                         \\"\
    -H "  PIN_PUPD(0,  PIN_PUPD_UP)                 | \\"\
    -H "  PIN_PUPD(1,  PIN_PUPD_UP)                   \\"\
    -H ")"\
    \
    $force_inline\
    --no-def

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
Wg==
EOF

create_file "stm32f030x6_flash.ld" << 'EOF'
/Td6WFoAAATm1rRGAgAhARYAAAB0L+Wj4A6qBH5dABeKgCRDWZigxFgAKUhK1Ev7lGr397uylF5a
pw3JtGOkunwCrQw36ueYGMJ64IlgXXIHXcVuvo7tX3vVNCUZPW5pf5syFAc/CsV4iOQIQVz0kNFL
R3HL1SnsLdgkSUn9yVIp+J/dOgDe4tPCn0+OXHPAJaXKCfr0fULwZG3+QzkUjlHeFtpJfwP3tqbz
9WNiDOQvW1sEmUaSIGoZ7/fq8IjKmDPZZeF7w57Jy9fcNPGAHS0ZSI71WhSJNsrEm1nv06LglPfU
UbX5XLozMq0MKxD1oDCyvAX6JPjPUJx3gMi38jHihmmAOPCShKYIUTWbnSuiiSxzaM3ZSQ+4eWOE
PhDM22Mv+8vZqXKuwL5cV7sHzVW9xSsAMVjHzlnQC6badvgSV9q3HWXv4LnviPgjkf74Fcp02nzF
h6uKWS4e/eo+z+En4rdmdQ8w6DZ3iYYRKfSBscpuA0aOM6T1YhaTSnwAluZ7nUJMxJEMNwtlCgVt
XlmiHVe9IdBuFXwREPlzEV9STd56UsNKhxdrJ3P0UzGJsXkc44fFaCbLkRuuHxcw55yxxLd7mJHl
wJyKJcx5m6maw1GvmBQtQubuacJrZyNMxz3wDt9MUPmHFWOaUOfvlJYihIcCXXHgoKYE6o0lxpHE
nenAMobE/JLTbmz6uBf561ZlYtK7X1HnVX+a6J2xIQlp2t6AJj2r4wb8ZdKwJsh21Enu99csKNhc
5Gc0s/A3zGl0i9duYlzLe5s+Uw0yGQmlJyZcTlJBAL61DD0H4jKpla45/iBQZWpiy6P++9tQJ4WK
q7h9QUHepQO5VsSQSkkWoIjLUfTHRhV2YUN9o9gqHX+ba2BfU09EEsyeDcoehrh+e53apmKOO2ik
6qS7dgYDvG1ayrls3Gz95YXFgQKhYF59pKOoR9TsE91kFwHBxT/yG3/GjB1HAV017HP1rJ+1pRZr
Du8wW+A7wUXs+ASHtU6KZT56uYeNqvrjkxTIaCjq8gjFa1+sPO9D+kSLW6Uvax/aCQRXtVWHXpZ/
mGWW0oj+DLbBKb4ivQ8gJ3zymiTM+m9JF/t/y9tecONaBVUOLaaIYJLPZ6zy/3mMzxu+yU7O5tO1
Ongyp/qQOqS9X5fqqKJwRrE/XrXSgY1WSq7pRk6HjlFsRhA4bBaBn39NAv/7oFzBstVq14ZxnPZO
1pYWdddl0phLCWx4Diqw7q6zZLQH2ML+8czfU0PA55+PjmWyesZ8i/1A8lQiaM2Tiux+Oszg+NaY
VUIiZolaD5/7kbvG/z0HXK2AK5bKS8hbzTkqcHS1ZfZw66tGK9xBJT1EXISITpYm1yM29ruBx2l4
MhU821+Lp5h7dTriTEBxmu44xLoZWHiuoYpDh0mW1FIxtNbSBWEtayLzJiUdNebSwTgHadKEwToH
hLFpe6hcjo+QsJNhHG6PPkJwd3mTffBp3tBaGFo+CC9gNRsierY5h+87HTV8q2Zmqfex9rNIoOsK
sqLrolOVYm8nd5KzDmM54vs/sWIvg8s/uv93TtFJdiEoP/622rOb5roAAAC5teH6yPxNUAABmgmr
HQAAri0s/LHEZ/sCAAAAAARZWg==
EOF

create_file "MDK-ARM/Project.uvprojx" << 'EOF'
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
EOF

create_file "project.jdebug" << 'EOF'
/Td6WFoAAATm1rRGAgAhARYAAAB0L+Wj4AQDAcVdADsbyWDW/2zquwwHdYzOwgOvw6pB2bhQyE04
OSxh7dKJxtJXcx+WPS32SgPuOcnCfpkhAX/lVcg5iFIlp044hAJI94cGdeK+X7XT2CORKAR7ioXC
4O9qB1xgm+XxQAt1Y1hPTgFJJMUpVQ4DCrhjxKOhK1fzR1DRej23syL4IuZvhqSMBkOw6C3u8red
qO95b60KexjhfBtwkt3UFAjqAP2uxPgjnbvF9DlmNYh0RqsynX3Itshhiwy3dIdUuQ6OzM4k/iAg
Ac60atbFvUaz3pRN5s1NLCQKRR89+gaN292tsO47yBqL/Mxd3kYxd7taynC1WV0XTRXTIk7XtJCy
6Lxj5PP2Y28xh476YXcOH6cwyPjD64HS4Nf803mZ2bn5KhN49VUqO2d2TW1nsRdYIGik/EUoXaPO
eyTaXE9XXg6gj6jeb6wLVAX/CQZ+YqmeJZO2hHkX/q5E5dvdAu+ZcOuaaJrRHFYgJbsxb/+Ci8J8
Mouci8kSjeVyDTnG1oTPv4K6RdWHFNs1oR3/s6Z3rhdW4iVe10ke7DoUFXIfR/T6v9PWObqC8MMZ
4mtSQoh2kNhHHnzEF4WOoFAF9IUfjPJZPTZZvQAAAACgpA/87yNf9wAB4QOECAAA/hbFNbHEZ/sC
AAAAAARZWg==
EOF

create_file "stm32f030x6.jflash" << 'EOF'
/Td6WFoAAATm1rRGAgAhARYAAAB0L+Wj4AewAwZdABBhAOGFYzOihg56UIqKCKQrnqKasrAxa6gW
aeZG86Pk+G/iEId5CVjqnEwXAprd+mfglT4i426SWo/xS7YaD+CzdQCIqK5WCRH/2RwmT8+YuwJB
PpqcRsdUYfOKkq4h0s3MNcWVwMPOzcra1Mz2E7c/ufx7PcVXHoKnnAGUMvm4KmD9CsTR2PmMFFMl
H3wr484iM7+vJvsy8EiQQ1nbBIoLenldsybldPbO95PH68xcmlmXJYuhcKYKQVFjBWAmswQvjVHT
2Fwde7zHqLfzQa9KvCPkWbD/ALiUhL4Dum0p3xlKrgWSUlBInXyh6b0TsLznCs9ZlguX3w11Xmdh
G4uPslLk3mxej0M67O3QE/SUKTJU9He8ODHT5mZjCFMhqDzCfeHu7lVBpoL8TSqwEaUlJYxA30zM
B13OUSfdRLd7v20DJJyH0+HTKlmlzkOD5DDabNTQJZheesSnHSv8D4iWlPFyWW5Vv67JsOKSl2IR
0THA1JU9FqiIMc7/c4NOFKY/9FSx5Sgyjwwa2TUzIgZhFm+mRwzA+Nzy1tK+u4Ac7lls+XJCO9rM
nvTcCTMekBCML3hIafYXD42NJL5PMJneUB4zgDfFrK9SpGeBgNF9LoVMRzbds6oFd6wRDrWYYNnW
51nprNpt/BMDR/6SXIMvRGgSYoKk99bjro7arWKE3dJeZOAs5dwhT6PdJzCKG+yZYdi7FMPQj5Gw
xTrRZt7Ka+b18UDLbiqZs+A2sT4VPZSKVRKtoxJY7HWiJptU2y2DnGqGN1kxb/laHZBSlzVEV4hN
FoZpFwm7M8SwTQXihAEUaETdGzfRuTpHyaFC2PAlaCUtatXYrHEC3s6CkFiQms3MUtLvVceYRNRG
vco7dIA+2/qZmA1WsJDKTICUUSC5ZmPdc7ENYrHAT6QRPWo5KdWABP1oYFM3/qjhLwfThmskNpyz
IOU9+h6SYul8rdVD1wxV7r1aXmc+I40sp8iqQ6TwTQizzBhxtH1ZsVMsEEQswRF86CtJurIxSrrV
7gPl2QkPAAAAAN+3R7rS5jhmAAGiBrEPAABa/1O2scRn+wIAAAAABFla
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
  GPIOA->BSRR = ++*uptime() & (1 << 9) ? GPIO_BSRR_BS_4 : GPIO_BSRR_BR_4;

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
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f0/master/Source/Templates/system_stm32f0xx.c
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f0/master/Source/Templates/gcc/startup_stm32f030x6.s
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f0/master/Source/Templates/arm/startup_stm32f030x6.s
#
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f0/master/Include/system_stm32f0xx.h
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f0/master/Include/stm32f0xx.h
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f0/master/Include/stm32f030x6.h
#
#               https://github.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include
#
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_compiler.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_armclang.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_gcc.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_iccarm.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_version.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/core_cm0.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_armcc.h
#
#    https://raw.githubusercontent.com/cmsis-svd/cmsis-svd-data/refs/heads/main/data/STMicro/STM32F030.svd 
#    https://raw.githubusercontent.com/cmsis-svd/cmsis-svd-data/refs/heads/main/data/STMicro/STM32F031x.svd
     
     

fname1=("system_stm32f0xx.c" "startup_stm32f030x6.s")
fname2=("system_stm32f0xx.h" "stm32f0xx.h" "stm32f030x6.h")
fname3=("cmsis_compiler.h" "cmsis_armclang.h" "cmsis_gcc.h" "cmsis_iccarm.h" "cmsis_version.h" "core_cm0.h" "cmsis_armcc.h")

raw_github="https://raw.githubusercontent.com/"

url1="${raw_github}STMicroelectronics/cmsis-device-f0/refs/heads/master"
url2="${raw_github}ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/"
url3="${raw_github}cmsis-svd/cmsis-svd-data/refs/heads/main/data/STMicro/STM32F031x.svd"

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
download_file "${url3}" "STM32F031x.svd"

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
