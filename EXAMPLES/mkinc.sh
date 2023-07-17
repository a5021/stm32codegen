#!/bin/bash

function press_any_key {
    echo -n "Press any key to continue..."
    # read one character of input and discard it
    read -n 1 -s -r
    echo ""
}


if [ -e stm32f030x6.h ]; then
    # File exists
    opt=-l
else
    # File does not exist
    opt=-s
fi

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
   --force-inline\
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

echo "created main.h file."

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
   --force-inline\
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

echo "created rcc.h file."

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
   -H "#define GPIOA_MODE (                                                    \\"\
   -H "  1          * PIN_MODE(0,  PIN_MODE_OUTPUT) /* PA0  -- OUTPUT     */ | \\"\
   -H "  1          * PIN_MODE(1,  PIN_MODE_OUTPUT) /* PA1  -- OUTPUT     */ | \\"\
   -H "  !USART1_EN * PIN_MODE(2,  PIN_MODE_OUTPUT) /* PA2  -- OUTPUT     */ | \\"\
   -H "  !USART1_EN * PIN_MODE(3,  PIN_MODE_OUTPUT) /* PA3  -- OUTPUT     */ | \\"\
   -H "  USART1_EN  * PIN_MODE(2,  PIN_MODE_AF)     /* PA2  -- USART1 TX  */ | \\"\
   -H "  USART1_EN  * PIN_MODE(3,  PIN_MODE_AF)     /* PA3  -- USART1 RX  */ | \\"\
   -H "  !SPI1_EN   * PIN_MODE(4,  PIN_MODE_OUTPUT) /* PA4  -- OUTPUT     */ | \\"\
   -H "  SPI1_EN    * PIN_MODE(4,  PIN_MODE_AF)     /* PA4  -- SPI1 CS    */ | \\"\
   -H "  SPI1_EN    * PIN_MODE(5,  PIN_MODE_AF)     /* PA5  -- SPI1 SCK   */ | \\"\
   -H "  SPI1_EN    * PIN_MODE(6,  PIN_MODE_AF)     /* PA6  -- SPI1 MISO  */ | \\"\
   -H "  SPI1_EN    * PIN_MODE(7,  PIN_MODE_AF)     /* PA7  -- SPI1 MOSI  */ | \\"\
   -H "  I2C1_EN    * PIN_MODE(9,  PIN_MODE_AF)     /* PA9  -- I2C1 SDA   */ | \\"\
   -H "  I2C1_EN    * PIN_MODE(10, PIN_MODE_AF)     /* PA10 -- I2C1 SCL   */ | \\"\
   -H "  SWD_EN     * PIN_MODE(13, PIN_MODE_AF)     /* PA13 -- SWDCLK     */ | \\"\
   -H "  SWD_EN     * PIN_MODE(14, PIN_MODE_AF)     /* PA14 -- SWDIO      */   \\"\
   -H ")"\
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
   --force-inline\
   --no-def\
   > gpio.h

echo "created gpio.h file."
press_any_key
