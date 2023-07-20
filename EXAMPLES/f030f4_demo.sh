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

force_inline=--force-inline
func_name=init_systick
py_gen="python3 $PY_GEN/stm32cgen.py"

$py_gen $opt 030f4 -M\
    -D NO                     0\
       NONE                   NO\
       OFF                    NO\
       YES                    \(\!NO\)\
       ON                     YES\
       ""\
       HCLK                   "8    /* 8 to 64 (MHz) with a step of 4 */"\
       ""\
       SYSTICK_CLOCK_SOURCE   "0    /* 0 = HCLK / 8; 1 = HCLK         */"\
       SYSTICK_EN             YES\
       SYSTICK_IRQ_EN         NO\
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
    -F "    + SYSTICK_IRQ_EN       * SysTick_CTRL_TICKINT_Msk"\
    -F "    + SYSTICK_EN           * SysTick_CTRL_ENABLE_Msk"\
    -F "  );"\
    -F "} /* $func_name() */"\
    -F ""\
    -F ""\
    -F "__STATIC_FORCEINLINE void idle(void); // {"\
    -F "  /* The body of the main program loop follows here */"\
    -F ""\
    -F ""\
    -F "//} /* idle() */"\
    -F ""\
    -F "#if YES == SYSTICK_IRQ_EN"\
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
    echo "main.h created."
else
    echo "Creation of main.h failed with status $status"
fi

func_name=wait_for_clock_settles
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
    echo "rcc.h created."
else
    echo "Creation of rcc.h failed with status $status"
fi

$py_gen -l 030f4 -p GPIOA GPIOB GPIOF -m gpio -f init_gpio\
    -D USE_ANALOG_MODE_FOR_ALL_PINS_BY_DEFALUT 1\
       ""\
       GPIO_MODE "(USE_ANALOG_MODE_FOR_ALL_PINS_BY_DEFALUT * UINT32_MAX)"\
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
    echo "gpio.h created."
else
    echo "Creation of gpio.h failed with status $status"
fi

cd ..

# Function to check for the existence of a file and create it if it doesn't exist
create_file() {
  if [ ! -f "$1" ]; then
    echo "$2" | base64 -d | tar xjf -
    op_counter=$(expr $op_counter + 1)
    echo "File $1 created."
  fi
}


create_file "Makefile" "`cat << EOF
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
EOF`"

create_file "stm32f030x6_flash.ld" "`cat << EOF
QlpoOTFBWSZTWc/QOOoABrjfkP+SQP3/3y/v3yD/7//6BAAACFAFmCPLNGwbbQFCiGSQyaaaRiCA
B6nqepoAGgBoGmg0AHDTTBDIaaZGTCAaaAMJo0yYAEDQSaihNE9FPVPSaekxGjanqBoeo0aHqDan
6UPUAPIhw00wQyGmmRkwgGmgDCaNMmABA0EiQmgTTQyTSeVDRtJpkNMQAZBpoDIHqd37vVW2g0xC
FnIgT90LVVYQSOUERCAdwCAenn+Smcrb7HhTGqdBworJsbRNj6aovnwrmmiTXrMEilVClaooxmqN
pgW2RtVwKq5bVmAYE8/Rps73EQjzJUkkNEgSTWSGgkJ26FEItyqCRoYej+cumeY6CecHKBev7BwC
w5oXFk9vjHIVzQa8UMFKIUhhYkQbPI8YSAG2iXXdSTiYRwoLc1b2Z4qXPXRcFIQuKIsI0U5kqlXh
GAWeIqJE4BmvnmylR4xbXULuRnqkYAwhmqlIN67Al2Sul/IcqlSnTL1+DCH588by28iYdOvZunSV
NSJd+qLC+Cm0w2UzLrBuT5ZXY0umVK4yoYk7dkqygcN62JAxRkFBDYKaEDZLUVMs9tr7U0d81ijT
IFiFgONAdaCk8gR50xCXns3YbcsSNnZ233vB02VezmXXsy/3LAuaJn+UznCjdcqroKnlPChJs1FY
fgsOURg0My3WFcO6mWoA+b7rTvs6UDE8rSPYSFngVJidwVx917/EYZZFVQpcbQtpF8vZduFLVUvJ
JJ19XV1b7vP7/UlDsoyR1CVVVafZTI1RI9aePqp/r9spbq83CzyOAfi0PxYRzxPRll4q5CC7Ilyo
2GB0KRu7IanwSiJxPmgrCHbNiEWKRRqCAh5ND42JIPI0js9fvSBeYD97hdEKf6b/VKvo9Ymy8TF5
ooy39QMpCwPBgBIVT0gb4WAl9RGCFwOaCXqF/QG8yBewrsr2dnwgbfYhUOoExowaaMNOfHjvBi1N
wKkhuvOtmBqSwAqBtApv6jdIhmewYvQBC1nz69ulqFM0Cxj2k9DhdRGAG7UZnjOMnR0G7WvD9FwP
zy5A4yV0qirF0MNa9Z2tl8SwN7qxCACFqXJw4udgaFqLyWkIEQkjyUMSMwqSCnha6hPSdGXZiVEi
z1URvtQidv0XEEnCxN0NsuDjlv2Wpd7TExNpw39ngx1m0ilSdwGSBb6AUkLOQQyme3bTKgUpBEDb
dsCJBbbG6qaN/aUW5ufpnHbdWrmwpZGszShQocRlpxO5wmxGJQgtHZeHi10qGXu8C1sGPvxQ4ZY4
4QcJ10rqDxvsxutIyZUUGVyvZ8nJFAqWj2OJ8refKKJWphfcc8r8l4W2qmw5yK0gtEw0DgX+2ovu
6R8QedEUIFntY3tgdDZiZyRlixG8vn1PAlcJeMvGMuRJg7w4osrb3O8oJUCOKKsN07rv763nLDLP
B7tjnPZRBohYpcKYHawnyslRIilxCPDI2YiNBYo0S9tlAyRPx7kRgtH4mB8dyxsd3VjHKCHtNwMO
vkcyy7XiViBtNnuGuzSe0SrWUZ7zwBia7CxjLXtRZjhMSwvhI7vwX36oq7HG5dbulNqJJuHvLSA4
Lckao6VwpcahNAd+ZjdU6TXRcGfSyceoy46B26TBO29uBjxZeiVGbLpIKIRNWi6xgm1YTMLjqmw2
JatXh12tBdkiiJF2hQorDII4hf2neILQwDXt58iwmYHT7BM0XtNBmqXPjeTSN6NQPKeRBm2RDVQW
Q/8XckU4UJDP0Djq
EOF
`"

create_file "MDK-ARM/Project.uvprojx" "`cat << EOF
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
5IpwoSE3Z2LA
EOF
`"

create_file "project.jdebug" "`cat << EOF
QlpoOTFBWSZTWT2Fk5UAAeLfkNwQdGf/Hj/m34D/9d/6BAAACEACNUpEUEkiBoFNqemTVG2knijy
janqMmmmmI0NNHlAkhCIMhTxJmmkep6Go0ephpGQZNGjT9UY5gTE0GEyZMmRhME00yMTAEMBzAmJ
oMJkyZMjCYJppkYmAIYMXzaq7/omhMyW94TCBkyCiOM01r/J3d0FrjpmBye5UmdiCCMQtW7MvqvF
juao7x/k1mvYQuuqsrKGKkPfrZxDvOHYll/Utkyaul4xJRrMrBAtYwxG/i4dXv1379pcXUIJBUpa
szOTpMhsImBuhk/YWBKKCCcdR0URRswuLEEedhe9BHt7P5bgeDrHlMrIq43EN1Mvr6dM6tg8mN0k
83g6N/bBQx2HNG/hrwDUxzszcMTlBY4uFb1Fq69SMQeeGidKQPF60jKQabKd5acrw0kXOppSb0sf
f1jsO2Il0tNaiZ5jBx6KTNtpNBFQbtH0w4FrpXeYa81BeC3v4Wq/jNS3LBiIm3qqwzpa15lbLOuo
1bbCxpoOi08VcV5v70whEyAcOZOGx1nRPhQXQE1aXX4GY9k6IDyWHUqaaj16Iak0ZXyVHWLy0Oc5
zDMjtheVKFZlMLCQ5kDKYswxAnMSxST6g5pZU1BkFKZokBVYMjgmyfsoLWef29QONi3k6JZ6+Fd4
GbPlQG4YlTuF9YZ7eTDa6/Xe0CZ2ZZlJA3JjSMjIyGedXoM1jX5xwKjGTQcKpIKq3gyGYYYGGBgx
dE9D1KaDkpN0ZVBQIK0vKyQLFxY6Z1IpvM/zfALou7sLTnrSmBlil/xdyRThQkD2Fk5U
EOF
`"

# Create main.c file in src directory from embedded data using Here Document
main_c_file="${directories[1]}/main.c"
if [ ! -f "$main_c_file" ]; then
  op_counter=$(expr $op_counter + 1)
  cat << EOF > "$main_c_file"
#include "main.h"


int main(void) {

  for(init();;idle());

}


__STATIC_FORCEINLINE __SYSTICK_VOLATILE uint32_t * get_uptime(void) {
  extern __SYSTICK_VOLATILE uint32_t uptime;
  return &uptime;
}


__STATIC_FORCEINLINE void set_uptime(uint32_t t) {
  extern __SYSTICK_VOLATILE uint32_t uptime;
  uptime = t;
}


#if YES == SYSTICK_IRQ_EN

__STATIC_FORCEINLINE void process_systick_event(void) {}
void SysTick_Handler(void);
void SysTick_Handler(void) {

#else

__STATIC_FORCEINLINE void process_systick_event(void) {
  if (0 == (SysTick->CTRL & SysTick_CTRL_COUNTFLAG_Msk)) {
    return;
  }
  
#endif

  {
    static uint32_t cnt;
  
    if (++cnt == 1000) {
      cnt = 0;
      set_uptime(*get_uptime() + 1);
    }
  }

}


__STATIC_FORCEINLINE void idle(void) {
  /* The body of the main program loop follows here */
  
  process_systick_event();
  
} /* idle() */


__SYSTICK_VOLATILE uint32_t uptime = 0;

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
#    https://raw.githubusercontent.com/posborne/cmsis-svd/master/data/STMicro/STM32F030.svd
#    https://raw.githubusercontent.com/posborne/cmsis-svd/master/data/STMicro/STM32F031x.svd

fname1=("system_stm32f0xx.c" "startup_stm32f030x6.s")
fname2=("system_stm32f0xx.h" "stm32f0xx.h" "stm32f030x6.h")
fname3=("cmsis_compiler.h" "cmsis_armclang.h" "cmsis_gcc.h" "cmsis_iccarm.h" "cmsis_version.h" "core_cm0.h" "cmsis_armcc.h")

raw_github="https://raw.githubusercontent.com/"

url1="${raw_github}STMicroelectronics/cmsis_device_f0/master"
url2="${raw_github}ARM-software/CMSIS_6/main/CMSIS/Core/Include/"
url3="${raw_github}posborne/cmsis-svd/master/data/STMicro/STM32F031x.svd"

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
