#!/bin/bash

base_dir=$(basename "$0" .sh)

# Array with directory names
directories=("inc" "src" "MDK-ARM")
op_counter=0

# Function to check for the existence of a directory and create it if it doesn't exist
create_directory() {
  if [ ! -d "$1" ]; then
    mkdir "$1"
    op_counter=$(expr $op_counter + 1)
    echo "Directory $1 created."
  fi
}

# Create directories
create_directory "$base_dir" && cd "$base_dir"

for dir in "${directories[@]}"
do
  create_directory "$dir"
done

cd ${directories[0]}

if [ -z "$PY_GEN" ]; then
    PY_GEN=../../..
fi

if [ -e stm32f030x6.h ]; then
    # File exists
    opt=-l
else
    # File does not exist
    opt=-s
fi

py_name=''

case $(uname | tr '[:upper:]' '[:lower:]') in
  linux*)
    py_name='python3'
    # export OS_NAME=linux
    ;;
  darwin*)
    py_name='python3'
    # export OS_NAME=osx
    ;;
  msys*)
    py_name='python'
    # export OS_NAME=windows/msys
    ;;
  cygwin*)
    py_name='python'
    #export OS_NAME=windows/cygwin
    ;;
  *)
    py_name='python'
    #export OS_NAME=notset
    ;;
esac


force_inline=--force-inline
func_name=init_systick
py_gen="$py_name $PY_GEN/stm32cgen.py"

$py_gen $opt 030f4 -M\
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
    -F \#endif\
    > main.h

# Check if the previous command was successful
status=$?
if [ $status -eq 0 ]
then
    echo "File main.h created."
else
    echo "Creation of main.h failed with status $status"
fi

func_name=wait_for_clock_stable
tag=R
$py_gen -l 030f4 -p RCC -m rcc -f init_rcc\
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
    -F "#undef $tag"\
    > rcc.h

# Check if the previous command was successful
status=$?
if [ $status -eq 0 ]
then
    echo "File rcc.h created."
else
    echo "Creation of rcc.h failed with status $status"
fi

$py_gen -l 030f4 -p GPIOA GPIOB GPIOF -m gpio -f init_gpio\
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

# Function to check for the existence of a file and create it if it doesn't exist
create_file() {
  if [ ! -f "$1" ]; then
    echo "$2" | base64 -d | xz -qdc >$1
    op_counter=$(expr $op_counter + 1)
    echo "File $1 created."
  fi
}


create_file "Makefile" "`cat << EOF
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
E98sAACySVEzscRn+wIAAAAABFla
EOF`"


create_file "stm32f030x6_flash.ld" "`cat << EOF
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
`"

create_file "MDK-ARM/Project.uvprojx" "`cat << EOF
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
EOF
`"

create_file "project.jdebug" "`cat << EOF
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
`"

create_file "stm32f030x6.jflash" "`cat << EOF
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
`"


# Create main.c file in src directory from embedded data using Here Document
main_c_file="${directories[1]}/main.c"
if [ ! -f "$main_c_file" ]; then
  op_counter=$(expr $op_counter + 1)
  cat << EOF > "$main_c_file"
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


if ! command -v curl &> /dev/null; then
    echo "curl is not installed. Please install curl and try again."
    echo "For Debian/Ubuntu users: sudo apt-get install curl"
    echo "For Red Hat/CentOS users: sudo yum install curl"
    press_any_key
    exit 1
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
#               https://github.com/ARM-software/CMSIS_6/tree/main/CMSIS/Core/Include
#
#    https://raw.githubusercontent.com/ARM-software/CMSIS_6/main/CMSIS/Core/Include/cmsis_compiler.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_6/main/CMSIS/Core/Include/cmsis_armclang.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_6/main/CMSIS/Core/Include/cmsis_gcc.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_6/main/CMSIS/Core/Include/cmsis_iccarm.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_6/main/CMSIS/Core/Include/cmsis_version.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_6/main/CMSIS/Core/Include/core_cm0.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_6/main/CMSIS/Core/Include/cmsis_armcc.h
#
#    https://raw.githubusercontent.com/cmsis-svd/cmsis-svd-data/refs/heads/main/data/STMicro/STM32F030.svd 
#    https://raw.githubusercontent.com/cmsis-svd/cmsis-svd-data/refs/heads/main/data/STMicro/STM32F031x.svd
     
     

fname1=("system_stm32f0xx.c" "startup_stm32f030x6.s")
fname2=("system_stm32f0xx.h" "stm32f0xx.h" "stm32f030x6.h")
fname3=("cmsis_compiler.h" "cmsis_armclang.h" "cmsis_gcc.h" "cmsis_iccarm.h" "cmsis_version.h" "core_cm0.h" "cmsis_armcc.h")

raw_github="https://raw.githubusercontent.com/"

url1="${raw_github}STMicroelectronics/cmsis-device-f0/refs/heads/master"
url2="${raw_github}ARM-software/CMSIS_5/refs/heads/develop/CMSIS/Core/Include/"
url3="${raw_github}cmsis-svd/cmsis-svd-data/refs/heads/main/data/STMicro/STM32F031x.svd"

# Function to check if a file exists and download it if it doesn't
download_file() {
  if [ ! -f "$2" ]; then
    curl -s "$1" | tr -cd '\11\12\15\40-\176' > "$2"
    op_counter=$(expr $op_counter + 1)
    echo "File $2 downloaded."
  fi
}

download_file "${url1}/Source/Templates/${fname1[0]}" "${directories[1]}/${fname1[0]}"
download_file "${url1}/Source/Templates/gcc/${fname1[1]}" "${directories[1]}/${fname1[1]}"
download_file "${url1}/Source/Templates/arm/${fname1[1]}" "${directories[2]}/${fname1[1]}"
download_file "${url3}" STM32F031x.svd

# Download files
for filename in "${fname2[@]}"
do
  download_file "${url1}/Include/${filename}" "${directories[0]}/${filename}"
done

for filename in "${fname3[@]}"
do
  download_file "${url2}${filename}" "${directories[0]}/${filename}"
done

if ! command -v arm-none-eabi-gcc &> /dev/null; then
    echo "GCC is not installed. Please install arm-none-eabi-gcc and try again."
    echo "For Debian/Ubuntu users: sudo apt-get install gcc"
    echo "For Red Hat/CentOS users: sudo yum install gcc"
    press_any_key
    exit 1
fi

echo -e "\nBuilding sources..\n"
make debug

function press_any_key {
    echo -n "Press any key to continue..."
    # read one character of input and discard it
    read -n 1 -s -r
    echo ""
}

press_any_key
