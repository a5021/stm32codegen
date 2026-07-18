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

generate_header "gpio.h" -l 103c8 -p GPIOA GPIOB GPIOC -m gpio -f init_gpio\
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
       "PIN_CFG(PIN, MODE)" "((MODE) << ((PIN) * 4))"\
       "PIN_CFGH(PIN, MODE)" "((MODE) << (((PIN) - 8) * 4))"\
       "PIN_MODE(PIN, MODE)" "(((MODE) & 3UL) << ((PIN) * 4))"\
       "PIN_MODEH(PIN, MODE)" "(((MODE) & 3UL) << (((PIN) - 8) * 4))"\
       "PIN_CNF(PIN, CNF)" "(((CNF) & 3UL) << (((PIN) * 4) + 2))"\
       "PIN_CNFH(PIN, CNF)" "(((CNF) & 3UL) << ((((PIN) - 8) * 4) + 2))"\
       "PIN_SPEED(PIN, SPEED)" "PIN_MODE(PIN, SPEED)"\
       "PIN_SPEEDH(PIN, SPEED)" "PIN_MODEH(PIN, SPEED)"\
       "PIN_OTYPE(PIN, OTYPE)" "PIN_CNF(PIN, OTYPE)"\
       "PIN_OTYPEH(PIN, OTYPE)" "PIN_CNFH(PIN, OTYPE)"\
       "PIN_PUPD(PIN, PUPD)" "PIN_CNF(PIN, PUPD)"\
       "PIN_PUPDH(PIN, PUPD)" "PIN_CNFH(PIN, PUPD)"\
       "PIN_AF(PIN, AF)" "((AF) << ((PIN) * 4))"\
       ""\
       PA0_AF1_USART1_CTS "PIN_AF(0, 1ULL)"\
       PA1_AF0_EVENTOUT "PIN_AF(1, 0ULL)"\
       PA1_AF1_USART1_RTS "PIN_AF(1, 1ULL)"\
       PA2_AF1_USART1_TX "PIN_AF(2, 1ULL)"\
       PA3_AF1_USART1_RX "PIN_AF(3, 1ULL)"\
       PA4_AF0_SPI1_NSS "PIN_AF(4, 0ULL)"\
       PA4_AF1_USART1_CK "PIN_AF(4, 1ULL)"\
       PA5_AF0_SPI1_SCK "PIN_AF(5, 0ULL)"\
       PA6_AF0_SPI1_MISO "PIN_AF(6, 0ULL)"\
       PA6_AF1_TIM3_CH1 "PIN_AF(6, 1ULL)"\
       PA7_AF0_SPI1_MOSI "PIN_AF(7, 0ULL)"\
       PA7_AF1_TIM3_CH2 "PIN_AF(7, 1ULL)"\
       PA8_AF0_EVENTOUT "PIN_AF(8, 0ULL)"\
       PA9_AF1_USART1_TX "PIN_AF(9, 1ULL)"\
       PA9_AF4_I2C1_SCL "PIN_AF(9, 4ULL)"\
       PA10_AF1_USART1_RX "PIN_AF(10, 1ULL)"\
       PA10_AF4_I2C1_SDA "PIN_AF(10, 4ULL)"\
       PA13_AF0_SWDIO "PIN_AF(13, 0ULL)"\
       PA14_AF0_SWCLK "PIN_AF(14, 0ULL)"\
       PA15_AF0_EVENTOUT "PIN_AF(15, 0ULL)"\
       ""\
       PB0_AF1_TIM3_CH3 "PIN_AF(0, 1ULL)"\
       PB1_AF0_TIM14_CH1 "PIN_AF(1, 0ULL)"\
       PB1_AF1_TIM3_CH4 "PIN_AF(1, 1ULL)"\
       PB6_AF0_I2C1_SCL "PIN_AF(6, 0ULL)"\
       PB7_AF0_I2C1_SDA "PIN_AF(7, 0ULL)"\
       PB10_AF1_USART3_TX "PIN_AF(10, 1ULL)"\
       PB11_AF1_USART3_RX "PIN_AF(11, 1ULL)"\
       ""\
       PC13_AF0_EVENTOUT "PIN_AF(13, 0ULL)"\
       ""\
       PIN_TYPE_PP 0x00UL\
       PIN_TYPE_OD 0x01UL\
       ""\
       PIN_SPEED_10MHZ 0x01UL\
       PIN_SPEED_2MHZ 0x02UL\
       PIN_SPEED_50MHZ 0x03UL\
       ""\
       PIN_PUPD_NONE 0x00UL\
       PIN_PUPD_UP 0x01UL\
       PIN_PUPD_DOWN 0x02UL\
       ""\
        _BR\(PIN\) "GPIO_BSRR_BR ## PIN"\
        BR\(PIN\) _BR\(PIN\)\
        _BS\(PIN\) "GPIO_BSRR_BS ## PIN"\
        BS\(PIN\) _BS\(PIN\)\
       _ODR\(PIN\) "GPIO_ODR_ ## PIN"\
       ODR\(PIN\) _ODR\(PIN\)\
       ""\
       GPIOA_CRL "(GPIO_MODE ^ (GPIOA_MODE))"\
       GPIOB_CRL "(GPIO_MODE ^ (GPIOB_MODE))"\
       GPIOC_CRL "(GPIO_MODE ^ (GPIOC_MODE))"\
    \
    -H ""\
    -H "/* Configure a single GPIO pin on F1 (CRL for pins 0-7, CRH for pins 8-15). */"\
    -H "/* Each pin occupies a 4-bit field: CNF[1:0] (bits 3:2) + MODE[1:0] (bits 1:0). */"\
    -H "#define CONFIGURE_PIN(GPIOx, PIN, MODE, OTYPE, SPEED, PUPD) do {                                \\"\
    -H "  if ((PIN) < 8) {                                                                         \\"\
    -H "    if (MODE)  MODIFY_REG((GPIOx)->CRL, (0x03UL << ((PIN) * 4)),       ((MODE)  << ((PIN) * 4)));       \\"\
    -H "    if (SPEED) MODIFY_REG((GPIOx)->CRL, (0x03UL << ((PIN) * 4)),       ((SPEED) << ((PIN) * 4)));       \\"\
    -H "    if (PUPD)  MODIFY_REG((GPIOx)->CRL, (0x0CUL << ((PIN) * 4)),       ((PUPD)  << (((PIN) * 4) + 2))); \\"\
    -H "    if (OTYPE) MODIFY_REG((GPIOx)->CRL, (0x0CUL << ((PIN) * 4)),       ((OTYPE) << (((PIN) * 4) + 2))); \\"\
    -H "  } else {                                                                                  \\"\
    -H "    if (MODE)  MODIFY_REG((GPIOx)->CRH, (0x03UL << (((PIN) - 8) * 4)), ((MODE)  << (((PIN) - 8) * 4)));     \\"\
    -H "    if (SPEED) MODIFY_REG((GPIOx)->CRH, (0x03UL << (((PIN) - 8) * 4)), ((SPEED) << (((PIN) - 8) * 4)));     \\"\
    -H "    if (PUPD)  MODIFY_REG((GPIOx)->CRH, (0x0CUL << (((PIN) - 8) * 4)), ((PUPD)  << ((((PIN) - 8) * 4) + 2))); \\"\
    -H "    if (OTYPE) MODIFY_REG((GPIOx)->CRH, (0x0CUL << (((PIN) - 8) * 4)), ((OTYPE) << ((((PIN) - 8) * 4) + 2))); \\"\
    -H "  }                                                                                         \\"\
    -H "} while (0)"\
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
    -H "  + PIN_MODEH(8,  PIN_MODE_ANALOG) \\"\
    -H "  + PIN_MODEH(9,  PIN_MODE_ANALOG) \\"\
    -H "  + PIN_MODEH(10, PIN_MODE_ANALOG) \\"\
    -H "  + PIN_MODEH(11, PIN_MODE_ANALOG) \\"\
    -H "  + PIN_MODEH(12, PIN_MODE_ANALOG) \\"\
    -H "  + PIN_MODEH(13, PIN_MODE_ANALOG) \\"\
    -H "  + PIN_MODEH(14, PIN_MODE_ANALOG) \\"\
    -H "  + PIN_MODEH(15, PIN_MODE_ANALOG) \\"\
    -H ")"\
    -H ""\
    -H '#define GPIOA_MODE (                                                    \'\
    -H '  !0         * PIN_MODE(0,  PIN_MODE_OUTPUT) /* PA0  -- OUTPUT     */ | \'\
    -H '  !0         * PIN_MODE(1,  PIN_MODE_OUTPUT) /* PA1  -- OUTPUT     */ | \'\
    -H '  !SPI1_EN   * PIN_MODE(4,  PIN_MODE_OUTPUT) /* PA4  -- OUTPUT     */ | \'\
    -H '  SPI1_EN    * PIN_MODE(4,  PIN_MODE_AF)     /* PA4  -- SPI1 CS    */ | \'\
    -H '  SPI1_EN    * PIN_MODE(5,  PIN_MODE_AF)     /* PA5  -- SPI1 SCK   */ | \'\
    -H '  SPI1_EN    * PIN_MODE(6,  PIN_MODE_AF)     /* PA6  -- SPI1 MISO  */ | \'\
    -H '  SPI1_EN    * PIN_MODE(7,  PIN_MODE_AF)     /* PA7  -- SPI1 MOSI  */ | \'\
    -H '  USART1_EN  * PIN_MODEH(9,  PIN_MODE_AF)    /* PA9  -- USART1 TX  */ | \'\
    -H '  USART1_EN  * PIN_MODEH(10, PIN_MODE_AF)    /* PA10 -- USART1 RX  */ | \'\
    -H '  SWD_EN     * PIN_MODEH(13, PIN_MODE_AF)    /* PA13 -- SWDIO      */ | \'\
    -H '  SWD_EN     * PIN_MODEH(14, PIN_MODE_AF)    /* PA14 -- SWDCLK     */   \'\
    -H ')'\
    -H ""\
    -H "#define GPIOA_OSPEED (                        \\"\
    -H "  SPI1_EN   * PIN_SPEED(4,  PIN_SPEED_50MHZ) | \\"\
    -H "  SPI1_EN   * PIN_SPEED(5,  PIN_SPEED_50MHZ) | \\"\
    -H "  SPI1_EN   * PIN_SPEED(6,  PIN_SPEED_50MHZ) | \\"\
    -H "  SPI1_EN   * PIN_SPEED(7,  PIN_SPEED_50MHZ)   \\"\
    -H ")"\
    -H ""\
    -H "#define GPIOA_AF (                            \\"\
    -H "  SPI1_EN   * PA4_AF0_SPI1_NSS              | \\"\
    -H "  SPI1_EN   * PA5_AF0_SPI1_SCK              | \\"\
    -H "  SPI1_EN   * PA6_AF0_SPI1_MISO             | \\"\
    -H "  SPI1_EN   * PA7_AF0_SPI1_MOSI             | \\"\
    -H "  USART1_EN * PA9_AF1_USART1_TX             | \\"\
    -H "  USART1_EN * PA10_AF1_USART1_RX            | \\"\
    -H "  SWD_EN    * PA13_AF0_SWDIO                | \\"\
    -H "  SWD_EN    * PA14_AF0_SWCLK                  \\"\
    -H ")"\
    -H ""\
    -H "#define GPIOB_MODE                     PIN_MODE(1,  PIN_MODE_AF)"\
    -H "#define GPIOB_OSPEED                   PIN_SPEED(1, PIN_SPEED_50MHZ)"\
    -H ""\
    -H "#define GPIOB_AF                       PB6_AF0_I2C1_SCL"\
    -H ""\
    -H "#define GPIOC_MODE (                          \\"\
    -H "  PIN_MODEH(13, PIN_MODE_OUTPUT)           | \\"\
    -H "  PIN_MODEH(14, PIN_MODE_INPUT)              \\"\
    -H ")"\
    -H ""\
    -H "#define GPIOC_PUPDR (                         \\"\
    -H "  PIN_PUPDH(14, PIN_PUPD_UP)                \\"\
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
EOF

create_file "stm32f103xb_flash.ld" << 'EOF'
/Td6WFoAAATm1rRGAgAhARwAAAAQz1jM4A8NBIpdABeKgCRDWZigxFgAKUhK1Ev7lGpI9l8XUoFV5/QHJi6P4/TdOYJw3WwqJ3YkQNxliitnsSeWQRVTcXAeaRrSbZuvr1yyI6JOM6SBLRq5rX68Himl7Dw69JMmTCKn3g7UAQpOuI0wOZBBGyIOktyFNOUAfT3MoUEGc4Sbvh6rScR5iHXtHvpaSsNcMTSyrg9nTyXmb4boMIsd0afdV0/rXGPX6M4Z7STaEbgOUcNFnt0+w959DsmhPgIdz7Vay5s8qh7I2hV3Kz6zrcqN6BKT58DUnE9cjrSDFVV22n2j9kzLR/0dTGxPFV3HHCHKFzhccLYQNTggriO8bxKa/UOwFTzYIvIVOWivVee7py8DeqcmjfrUzCqusAieeeSa0JMmqHw6ie56bz16gwQhP/QGXapkPtoUeOUHi8hJcR8A7URnD2fDqcWVASw+Eqvo2iuMBazqZpMXWVIzkFom/hNJkJZRRLiWdz02uRHm0A2gmfqyECey8ewmrtvh9nIYwlh2Nvgo/zBpcl2xYdfdS2sLnuarf6MEqcILwxb/CoxXPTtloB884pt3EFgtPXtj3TlpXkXdp5TZ4OEsF8BtFx/IL4hSueaS+zmJEZPIFPtFCfK8ai6oXuA/va+26rOiMm70RpknyFz7ITRZyJSf+iSoTpt1VEALW7vsSfO65UrX8kN/qRrxxjlDErx1hLw1a5L1m/1NCPggCE+Nazh4ufrfVMU6+/96Iqzg5VzdAfN7Pqv1/sr5bvZ6N4vKfb+64PLHZf2xx2nKfSUDCdRW7r8sVeJU8LGFB/ygTtDcDaViLXkYhty1zWkY2BEUV0A9WXYB/K5u8AsFNUoajiEKWhKFHnwlZ7lNOagmFoUhpLGp85vVkgzpv9UUaaFnJ62uLH8ZivVDYqge/kBdMWYO4Szq2N6q3oEUTyVYJybIy+HRfABVxJMe2JTa1cPCgWdtzyGWG1mFY3wDT5X3BGcFnuF7DsWXnyCKESxToneXyeKSzlSqla4mlsudZJLOT8vhfIsqe7rTWjDiicNtO7X1b+QQaZqd1K9DpV17QLsfXSse5QBATp6AqQZdpW0OhNL/l9mythii5ph9JFIwns/Q+UFDs/bGAxO++6RgALZDSDpS7zLyMXGqIjNhTaqsF7EEvrm1K+WI2a+QTXLUbHZ8eXe0iQ0UObikrhKGuCv4QOm1b87IpWN97kFQLwsjssuYISKij2RTXKdILgiLC4T6nYCx370V+3O5RROL/vpBWvImOECzrSQWBCEOpyAm+qHqpZK8/oVZmAptEMHlFpr5UzYKO5NSBx+lkc8z6VbnQ5qSmpywzXjx9xxsBodhZO00Sfn+iZLHE6uYen+PnoJVfC9tsp7TmtpEcDdTTtxo6Q5yj5iKaTlkrxS4O9zady1nRLSy5c/U8kAxwsIpatQu+Tk7KU+dZreANDFEZVt3Ib6eyxS6mKfv1W1MwKRiriuu5MBlaeV0PmW7K0acJste/saemeyp7KGzGOWWq6Sxrg9b0wJ3n1i4vciNsAa3y/31XNpC+4nIf9OEWcOgzSAAAACO8oDZLul0PAABpgmOHgAALQs+GrHEZ/sCAAAAAARZWg==
EOF

create_file "MDK-ARM/Project.uvprojx" << 'EOF'
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
EOF

create_file "project.jdebug" << 'EOF'
/Td6WFoAAATm1rRGAgAhARwAAAAQz1jM4AQEAcVdADsbyWDW/2zquwwHdYzOwgOvw6pB2bhQyE04OSxh7dKJxtJXcx+WPS32SgPuOcnCfpkhAX/lVcg5iFIlp044hAJI94cGdeK+X7XT2CORKAR7ioXC4O9qB1yv/59fpvwAQ49o+J8+9dfBzqPvi8Cs+tkQ8T1jyTjRmzaLRFsYx1YuroJR3XO+W/bGJK08PCMROl5dg/zIflLXvjwquVNKX5tpMW6LRcp3xIJvPBtVCMPyJYCCSSG7NxqwjD4Hy2ElkaIwu1Mte1EBXTHgNtxCbvZ24wRA+MTN0xmkdFUJBUAPwUUGbcNlECFd+tDZZRgZ4S73/DNoHjqnSKuR5gMLigsYa3fFHAWIqGd/f7onAVoReWLWYw19dFJgVKnAg6V3N0u2gCls421cPO6C2klRS7F0z5/ZbJuQ4fgSbiBd9W4qPfHBSymOVdhXbfQjAy/juHbHsEN/UJfqZn6X1BMRfNQCFOUqWt1/raa+gHiliI7RcOOkyj11AdXId87p+HogaLisHgcych5O85+JgmK2u9+Wc1KN0PFObeVSLqz1JwTHK2eAksG4bzsh31MfP+/B3CWMf6A1n1A8+fM6pJuNH61SEpMRIAAAAABbCBZXytURWQAB4QOFCAAAm3F5jbHEZ/sCAAAAAARZWg==
EOF

create_file "stm32f103xb.jflash" << 'EOF'
/Td6WFoAAATm1rRGAgAhARwAAAAQz1jM4AewAwZdABBhAOGFYzOihg56UIqKCKQrnqKasrAxa6gWaeZG86Pk+G/iEId5CVjqnEwXAprd+mfglT4i426SWo/xS7YaD+CzdQCIqK5WCRH/2RwmT8+YuwJBPpqcRsdUYfOKkq4h0s3MNcWVwMPOzcra1Mz2E7c/ufx7PcVXHoKnnAGUMvm4KmD9CsTR2PmMFFMlH3wr484iM7+vJvsy8EiQQ1nbBIoLenldsybldPbO95PH68xcmlmXJYuhcKYKQVFjBWAmswQvjVHT2Fwde7zHqLfzQa9KvCPkWbD/ALiUhL4Dum0p3xlKrgWSUlBInXyh6b0TsLznCs9ZlguX3w11XmdhG4uPslLk3mxej0M67O3QE/SUKTJU9He8ODHT5mZjCFMhqDzCfeHu7lVBpoL8TSqwEaUlJYxA30zMB13OUSfdRLd7v20DJJyH0+HTKlmlzkOD5DDabNTQJZheesSnHSv8D4iWlPFyWW5Vv67JsOKSl2IR0THA1JU9FqiIMc7/c4NOFKY/9FSx5Sgyjwwa2TUzIgZhFm+mRwzA+Nzy1tK+u4Ac7ldi7nph+o8Oin97fIVEUW48dOkUr1ZyJI2mGcB1IDaHkWlE0ZWCvZdwhe9alKcddHBtVo6LG/Qrr97ZY8xMfxRQYPmfToMwh9gNi8Lc/qamJwdFd1riK4GOKWhCGPcypXvuWzd4J+rmlCjBytqdhPp2EKhqcA/dP2bRMFG9zUNKNkmGex8KwNSIZjSyGwbLdEdobqjABUt9puOl1CMMGJ4gyWAsgeWE3ZKNbYEsS0hoDzrO04Nt/jc+3V0zddOMtpodAn5ZKjI3hr2PuQ3maeqz94m57+4beTf+sYd0YNxV9lEckzBJribIGHBnyu4BHhM1nvKKZcW4FKPDd9nVesB3ea6nHdkeAMkCHwyLqqnx7qSRxrZV/ppKZxc8XaN5qPClUBfig0Iya7UGyHNxXoGcnPVQ0yK+HxbKal4NRMQNVzrXginnC9j32tqE5pHuUvlbWQ0BrHhXKQDYweOiClDt01GWAAAAAJ84fh2c2eeFAAGiBrEPAABa/1O2scRn+wIAAAAABFla
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
  
  /* Increment uptime counter and toggle PC13 LED (BluePill onboard LED)
   * based on bit 9 state. This creates a blink period of 2^10 = 1024 ticks. */
  GPIOC->BSRR = ++*uptime() & (1 << 9) ? GPIO_BSRR_BS13 : GPIO_BSRR_BR13;

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
