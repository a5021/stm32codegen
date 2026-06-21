#ifndef __GPIO_H__
#define __GPIO_H__

#ifdef __cplusplus
  extern "C" {
#endif


#define USE_ANALOG_MODE_FOR_ALL_PINS_BY_DEFALUT        1

#define GPIO_MODE                      (USE_ANALOG_MODE_FOR_ALL_PINS_BY_DEFALUT * UINT32_MAX)
#define PIN_XOR                        (GPIO_MODE & 3UL)

#define PIN_MODE_INPUT                 (0x00UL ^ PIN_XOR)
#define PIN_MODE_OUTPUT                (0x01UL ^ PIN_XOR)
#define PIN_MODE_AF                    (0x02UL ^ PIN_XOR)
#define PIN_MODE_ANALOG                (0x03UL ^ PIN_XOR)

#define PIN_CFG(PIN, MODE)             ((MODE)   << ((PIN) * 2))
#define PIN_MODE(PIN, MODE)            (((MODE)  << GPIO_MODER_MODE ## PIN ## _Pos) & GPIO_MODER_MODE ## PIN ## _Msk)
#define PIN_SPEED(PIN, SPEED)          (((SPEED) << GPIO_OSPEEDR_OSPEEDR ## PIN ## _Pos) & GPIO_OSPEEDR_OSPEEDR ## PIN ## _Msk)
#define PIN_OTYPE(PIN, OTYPE)          ((OTYPE)   ? GPIO_OTYPER_OT_ ## PIN : 0)
#define PIN_PUPD(PIN, PUPD)            (((PUPD)  << GPIO_PUPDR_PUPDR ## PIN ## _Pos) & GPIO_PUPDR_PUPDR ## PIN ## _Msk)
#define PIN_AF(PIN, AF)                (AF << (PIN * 4))

#define PA0_AF1_USART1_CTS             PIN_AF(0, 1ULL)
#define PA1_AF0_EVENTOUT               PIN_AF(1, 0ULL)
#define PA1_AF1_USART1_RTS             PIN_AF(1, 1ULL)
#define PA2_AF1_USART1_TX              PIN_AF(2, 1ULL)
#define PA3_AF1_USART1_RX              PIN_AF(3, 1ULL)
#define PA4_AF0_SPI1_NSS               PIN_AF(4, 0ULL)
#define PA4_AF1_USART1_CK              PIN_AF(4, 1ULL)
#define PA4_AF4_TIM14_CH1              PIN_AF(4, 4ULL)
#define PA5_AF0_SPI1_SCK               PIN_AF(5, 0ULL)
#define PA6_AF0_SPI1_MISO              PIN_AF(6, 0ULL)
#define PA6_AF1_TIM3_CH1               PIN_AF(6, 1ULL)
#define PA6_AF2_TIM1_BKIN              PIN_AF(6, 2ULL)
#define PA6_AF5_TIM16_CH1              PIN_AF(6, 5ULL)
#define PA6_AF6_EVENTOUT               PIN_AF(6, 6ULL)
#define PA7_AF0_SPI1_MOSI              PIN_AF(7, 0ULL)
#define PA7_AF1_TIM3_CH2               PIN_AF(7, 1ULL)
#define PA7_AF2_TIM1_CH1N              PIN_AF(7, 2ULL)
#define PA7_AF4_TIM14_CH1              PIN_AF(7, 4ULL)
#define PA7_AF5_TIM17_CH1              PIN_AF(7, 5ULL)
#define PA7_AF6_EVENTOUT               PIN_AF(7, 6ULL)
#define PA9_AF1_USART1_TX              PIN_AF(9, 1ULL)
#define PA9_AF2_TIM1_CH2               PIN_AF(9, 2ULL)
#define PA9_AF4_I2C1_SCL               PIN_AF(9, 4ULL)
#define PA10_AF0_TIM17_BKIN            PIN_AF(10, 0ULL)
#define PA10_AF1_USART1_RX             PIN_AF(10, 1ULL)
#define PA10_AF2_TIM1_CH3              PIN_AF(10, 2ULL)
#define PA10_AF4_I2C1_SDA              PIN_AF(10, 4ULL)
#define PA13_AF0_SWDIO                 PIN_AF(13, 0ULL)
#define PA13_AF1_IR_OUT                PIN_AF(13, 1ULL)
#define PA14_AF0_SWCLK                 PIN_AF(14, 0ULL)
#define PA14_AF1_USART1_TX             PIN_AF(14, 1ULL)

#define PB1_AF0_TIM14_CH1              PIN_AF(1, 0ULL)
#define PB1_AF1_TIM3_CH4               PIN_AF(1, 1ULL)
#define PB1_AF2_TIM1_CH3N              PIN_AF(1, 2ULL)

#define PIN_TYPE_PP                    0x00UL
#define PIN_TYPE_OD                    0x01UL

#define PIN_SPEED_LOW                  0x00UL
#define PIN_SPEED_MED                  0x01UL
#define PIN_SPEED_HIGH                 0x03UL

#define PIN_PUPD_NONE                  0x00UL
#define PIN_PUPD_UP                    0x01UL
#define PIN_PUPD_DOWN                  0x02UL

#define _BR(PIN)                       GPIO_BSRR_BR ## PIN
#define BR(PIN)                        _BR(PIN)
#define _BS(PIN)                       GPIO_BSRR_BS ## PIN
#define BS(PIN)                        _BS(PIN)
#define _ODR(PIN)                      GPIO_ODR_ ## PIN
#define ODR(PIN)                       _ODR(PIN)

#define GPIOA_MODER                    (GPIO_MODE ^ (GPIOA_MODE))
#define GPIOB_MODER                    (GPIO_MODE ^ (GPIOB_MODE))
#define GPIOF_MODER                    (GPIO_MODE ^ (GPIOF_MODE))

#define GPIOA_AFR_0                    (GPIOA_AF & UINT32_MAX)
#define GPIOA_AFR_1                    ((GPIOA_AF >> 32) & UINT32_MAX)

#define GPIOB_AFR_0                    (GPIOB_AF & UINT32_MAX)
#define GPIOB_AFR_1                    ((GPIOB_AF >> 32) & UINT32_MAX)


#define CONFIGURE_PIN(GPIOx, PIN, MODE, OTYPE, SPEED, PUPD) do {                               \
  if (MODE)   MODIFY_REG((GPIOx)->MODER,   (0x03UL << ((PIN) * 2)), ((MODE)  << ((PIN) * 2))); \
  if (SPEED)  MODIFY_REG((GPIOx)->OSPEEDR, (0x03UL << ((PIN) * 2)), ((SPEED) << ((PIN) * 2))); \
  if (PUPD)   MODIFY_REG((GPIOx)->PUPDR,   (0x03UL << ((PIN) * 2)), ((PUPD)  << ((PIN) * 2))); \
  if (OTYPE)  MODIFY_REG((GPIOx)->OTYPER,  (0x01UL << (PIN)),       ((OTYPE) << (PIN)));       \
}while(0)

#ifndef USART1_EN
  #define USART1_EN 0
#endif

#ifndef SPI1_EN
  #define SPI1_EN 0
#endif

#ifndef I2C1_EN
  #define I2C1_EN 0
#endif

#ifndef SWD_EN
  #ifndef NDEBUG
    #define SWD_EN 1
  #else
    #define SWD_EN 0
  #endif
#endif

#define GPIO_MODE_EXAMPLE (       \
  + PIN_MODE(0,  PIN_MODE_ANALOG) \
  + PIN_MODE(1,  PIN_MODE_ANALOG) \
  + PIN_MODE(2,  PIN_MODE_ANALOG) \
  + PIN_MODE(3,  PIN_MODE_ANALOG) \
  + PIN_MODE(4,  PIN_MODE_ANALOG) \
  + PIN_MODE(5,  PIN_MODE_ANALOG) \
  + PIN_MODE(6,  PIN_MODE_ANALOG) \
  + PIN_MODE(7,  PIN_MODE_ANALOG) \
  + PIN_MODE(8,  PIN_MODE_ANALOG) \
  + PIN_MODE(9,  PIN_MODE_ANALOG) \
  + PIN_MODE(10, PIN_MODE_ANALOG) \
  + PIN_MODE(11, PIN_MODE_ANALOG) \
  + PIN_MODE(12, PIN_MODE_ANALOG) \
  + PIN_MODE(13, PIN_MODE_ANALOG) \
  + PIN_MODE(14, PIN_MODE_ANALOG) \
  + PIN_MODE(15, PIN_MODE_ANALOG) \
)

#define GPIOA_MODE (                                                    \
  !0         * PIN_MODE(0,  PIN_MODE_OUTPUT) /* PA0  -- OUTPUT     */ | \
  !0         * PIN_MODE(1,  PIN_MODE_OUTPUT) /* PA1  -- OUTPUT     */ | \
  !USART1_EN * PIN_MODE(2,  PIN_MODE_OUTPUT) /* PA2  -- OUTPUT     */ | \
  !USART1_EN * PIN_MODE(3,  PIN_MODE_OUTPUT) /* PA3  -- OUTPUT     */ | \
  USART1_EN  * PIN_MODE(2,  PIN_MODE_AF)     /* PA2  -- USART1 TX  */ | \
  USART1_EN  * PIN_MODE(3,  PIN_MODE_AF)     /* PA3  -- USART1 RX  */ | \
  !SPI1_EN   * PIN_MODE(4,  PIN_MODE_OUTPUT) /* PA4  -- OUTPUT     */ | \
  SPI1_EN    * PIN_MODE(4,  PIN_MODE_AF)     /* PA4  -- SPI1 CS    */ | \
  SPI1_EN    * PIN_MODE(5,  PIN_MODE_AF)     /* PA5  -- SPI1 SCK   */ | \
  SPI1_EN    * PIN_MODE(6,  PIN_MODE_AF)     /* PA6  -- SPI1 MISO  */ | \
  SPI1_EN    * PIN_MODE(7,  PIN_MODE_AF)     /* PA7  -- SPI1 MOSI  */ | \
  I2C1_EN    * PIN_MODE(9,  PIN_MODE_AF)     /* PA9  -- I2C1 SDA   */ | \
  I2C1_EN    * PIN_MODE(10, PIN_MODE_AF)     /* PA10 -- I2C1 SCL   */ | \
  SWD_EN     * PIN_MODE(13, PIN_MODE_AF)     /* PA13 -- SWDCLK     */ | \
  SWD_EN     * PIN_MODE(14, PIN_MODE_AF)     /* PA14 -- SWDIO      */   \
)

#if 0
#define GPIOA_OTYPE (                         \
  I2C1_EN   * (PIN_TYPE_OD << 9)            | \
  I2C1_EN   * (PIN_TYPE_OD << 10)             \
)
#else
#define GPIOA_OTYPE (                         \
  I2C1_EN   * PIN_OTYPE(9,  PIN_TYPE_OD)    | \
  I2C1_EN   * PIN_OTYPE(10, PIN_TYPE_OD)      \
)
#endif

#define GPIOA_OSPEED (                        \
  SPI1_EN   * PIN_SPEED(4,  PIN_SPEED_HIGH) | \
  SPI1_EN   * PIN_SPEED(5,  PIN_SPEED_HIGH) | \
  SPI1_EN   * PIN_SPEED(6,  PIN_SPEED_HIGH) | \
  SPI1_EN   * PIN_SPEED(7,  PIN_SPEED_HIGH)   \
)

#define GPIOA_AF (                            \
  USART1_EN * PA2_AF1_USART1_TX             | \
  USART1_EN * PA3_AF1_USART1_RX             | \
  SPI1_EN   * PA4_AF0_SPI1_NSS              | \
  SPI1_EN   * PA5_AF0_SPI1_SCK              | \
  SPI1_EN   * PA6_AF0_SPI1_MISO             | \
  SPI1_EN   * PA7_AF0_SPI1_MOSI             | \
  I2C1_EN   * PA9_AF4_I2C1_SCL              | \
  I2C1_EN   * PA10_AF4_I2C1_SDA             | \
  SWD_EN    * PA13_AF0_SWDIO                | \
  SWD_EN    * PA14_AF0_SWCLK                  \
)

#define GPIOB_MODE                     PIN_MODE(0,  PIN_MODE_OUTPUT)
#define GPIOB_OSPEEDR                  PIN_SPEED(0, PIN_SPEED_HIGH)

#define GPIOB_AF                       PB1_AF2_TIM1_CH3N

#define GPIOF_MODE (                          \
  PIN_MODE(0,  PIN_MODE_INPUT)              | \
  PIN_MODE(1,  PIN_MODE_INPUT)                \
)

#define GPIOF_PUPDR (                         \
  PIN_PUPD(0,  PIN_PUPD_UP)                 | \
  PIN_PUPD(1,  PIN_PUPD_UP)                   \
)

__STATIC_FORCEINLINE void init_gpio(void) {


  #if defined GPIOA_BRR
    #if GPIOA_BRR != 0
      GPIOA->BRR = GPIOA_BRR; /* 0x50000028: GPIO Bit Reset register, Address offset: 0x28 */
    #endif
  #else
    #define GPIOA_BRR 0
  #endif

  #if defined GPIOA_AFR_0
    #if GPIOA_AFR_0 != 0
      GPIOA->AFR[0] = GPIOA_AFR_0; /* 0x50000020: GPIO alternate function registers, Address offset: 0x20-0x24 */
    #endif
  #else
    #define GPIOA_AFR_0 0
  #endif

  #if defined GPIOA_AFR_1
    #if GPIOA_AFR_1 != 0
      GPIOA->AFR[1] = GPIOA_AFR_1; /* 0x50000024: GPIO alternate function registers, Address offset: 0x20-0x24 */
    #endif
  #else
    #define GPIOA_AFR_1 0
  #endif

  #if defined GPIOA_BSRR
    #if GPIOA_BSRR != 0
      GPIOA->BSRR = GPIOA_BSRR; /* 0x50000018: GPIO port bit set/reset register, Address offset: 0x18 */
    #endif
  #else
    #define GPIOA_BSRR 0
  #endif

  #if defined GPIOA_IDR
    #if GPIOA_IDR != 0
      GPIOA->IDR = GPIOA_IDR; /* 0x50000010: GPIO port input data register, Address offset: 0x10 */
    #endif
  #else
    #define GPIOA_IDR 0
  #endif

  #if defined GPIOA_LCKR
    #if GPIOA_LCKR != 0
      GPIOA->LCKR = GPIOA_LCKR; /* 0x5000001C: GPIO port configuration lock register, Address offset: 0x1C */
    #endif
  #else
    #define GPIOA_LCKR 0
  #endif

  #if defined GPIOA_MODER
    #if GPIOA_MODER != 0
      GPIOA->MODER = GPIOA_MODER; /* 0x50000000: GPIO port mode register, Address offset: 0x00 */
    #endif
  #else
    #define GPIOA_MODER 0
  #endif

  #if defined GPIOA_ODR
    #if GPIOA_ODR != 0
      GPIOA->ODR = GPIOA_ODR; /* 0x50000014: GPIO port output data register, Address offset: 0x14 */
    #endif
  #else
    #define GPIOA_ODR 0
  #endif

  #if defined GPIOA_OSPEEDR
    #if GPIOA_OSPEEDR != 0
      GPIOA->OSPEEDR = GPIOA_OSPEEDR; /* 0x50000008: GPIO port output speed register, Address offset: 0x08 */
    #endif
  #else
    #define GPIOA_OSPEEDR 0
  #endif

  #if defined GPIOA_OTYPER
    #if GPIOA_OTYPER != 0
      GPIOA->OTYPER = GPIOA_OTYPER; /* 0x50000004: GPIO port output type register, Address offset: 0x04 */
    #endif
  #else
    #define GPIOA_OTYPER 0
  #endif

  #if defined GPIOA_PUPDR
    #if GPIOA_PUPDR != 0
      GPIOA->PUPDR = GPIOA_PUPDR; /* 0x5000000C: GPIO port pull-up/pull-down register, Address offset: 0x0C */
    #endif
  #else
    #define GPIOA_PUPDR 0
  #endif

  #if defined GPIOB_BRR
    #if GPIOB_BRR != 0
      GPIOB->BRR = GPIOB_BRR; /* 0x50000428: GPIO Bit Reset register, Address offset: 0x28 */
    #endif
  #else
    #define GPIOB_BRR 0
  #endif

  #if defined GPIOB_AFR_0
    #if GPIOB_AFR_0 != 0
      GPIOB->AFR[0] = GPIOB_AFR_0; /* 0x50000420: GPIO alternate function registers, Address offset: 0x20-0x24 */
    #endif
  #else
    #define GPIOB_AFR_0 0
  #endif

  #if defined GPIOB_AFR_1
    #if GPIOB_AFR_1 != 0
      GPIOB->AFR[1] = GPIOB_AFR_1; /* 0x50000424: GPIO alternate function registers, Address offset: 0x20-0x24 */
    #endif
  #else
    #define GPIOB_AFR_1 0
  #endif

  #if defined GPIOB_BSRR
    #if GPIOB_BSRR != 0
      GPIOB->BSRR = GPIOB_BSRR; /* 0x50000418: GPIO port bit set/reset register, Address offset: 0x18 */
    #endif
  #else
    #define GPIOB_BSRR 0
  #endif

  #if defined GPIOB_IDR
    #if GPIOB_IDR != 0
      GPIOB->IDR = GPIOB_IDR; /* 0x50000410: GPIO port input data register, Address offset: 0x10 */
    #endif
  #else
    #define GPIOB_IDR 0
  #endif

  #if defined GPIOB_LCKR
    #if GPIOB_LCKR != 0
      GPIOB->LCKR = GPIOB_LCKR; /* 0x5000041C: GPIO port configuration lock register, Address offset: 0x1C */
    #endif
  #else
    #define GPIOB_LCKR 0
  #endif

  #if defined GPIOB_MODER
    #if GPIOB_MODER != 0
      GPIOB->MODER = GPIOB_MODER; /* 0x50000400: GPIO port mode register, Address offset: 0x00 */
    #endif
  #else
    #define GPIOB_MODER 0
  #endif

  #if defined GPIOB_ODR
    #if GPIOB_ODR != 0
      GPIOB->ODR = GPIOB_ODR; /* 0x50000414: GPIO port output data register, Address offset: 0x14 */
    #endif
  #else
    #define GPIOB_ODR 0
  #endif

  #if defined GPIOB_OSPEEDR
    #if GPIOB_OSPEEDR != 0
      GPIOB->OSPEEDR = GPIOB_OSPEEDR; /* 0x50000408: GPIO port output speed register, Address offset: 0x08 */
    #endif
  #else
    #define GPIOB_OSPEEDR 0
  #endif

  #if defined GPIOB_OTYPER
    #if GPIOB_OTYPER != 0
      GPIOB->OTYPER = GPIOB_OTYPER; /* 0x50000404: GPIO port output type register, Address offset: 0x04 */
    #endif
  #else
    #define GPIOB_OTYPER 0
  #endif

  #if defined GPIOB_PUPDR
    #if GPIOB_PUPDR != 0
      GPIOB->PUPDR = GPIOB_PUPDR; /* 0x5000040C: GPIO port pull-up/pull-down register, Address offset: 0x0C */
    #endif
  #else
    #define GPIOB_PUPDR 0
  #endif

  #if defined GPIOF_BRR
    #if GPIOF_BRR != 0
      GPIOF->BRR = GPIOF_BRR; /* 0x50001428: GPIO Bit Reset register, Address offset: 0x28 */
    #endif
  #else
    #define GPIOF_BRR 0
  #endif

  #if defined GPIOF_AFR_0
    #if GPIOF_AFR_0 != 0
      GPIOF->AFR[0] = GPIOF_AFR_0; /* 0x50001420: GPIO alternate function registers, Address offset: 0x20-0x24 */
    #endif
  #else
    #define GPIOF_AFR_0 0
  #endif

  #if defined GPIOF_AFR_1
    #if GPIOF_AFR_1 != 0
      GPIOF->AFR[1] = GPIOF_AFR_1; /* 0x50001424: GPIO alternate function registers, Address offset: 0x20-0x24 */
    #endif
  #else
    #define GPIOF_AFR_1 0
  #endif

  #if defined GPIOF_BSRR
    #if GPIOF_BSRR != 0
      GPIOF->BSRR = GPIOF_BSRR; /* 0x50001418: GPIO port bit set/reset register, Address offset: 0x18 */
    #endif
  #else
    #define GPIOF_BSRR 0
  #endif

  #if defined GPIOF_IDR
    #if GPIOF_IDR != 0
      GPIOF->IDR = GPIOF_IDR; /* 0x50001410: GPIO port input data register, Address offset: 0x10 */
    #endif
  #else
    #define GPIOF_IDR 0
  #endif

  #if defined GPIOF_LCKR
    #if GPIOF_LCKR != 0
      GPIOF->LCKR = GPIOF_LCKR; /* 0x5000141C: GPIO port configuration lock register, Address offset: 0x1C */
    #endif
  #else
    #define GPIOF_LCKR 0
  #endif

  #if defined GPIOF_MODER
    #if GPIOF_MODER != 0
      GPIOF->MODER = GPIOF_MODER; /* 0x50001400: GPIO port mode register, Address offset: 0x00 */
    #endif
  #else
    #define GPIOF_MODER 0
  #endif

  #if defined GPIOF_ODR
    #if GPIOF_ODR != 0
      GPIOF->ODR = GPIOF_ODR; /* 0x50001414: GPIO port output data register, Address offset: 0x14 */
    #endif
  #else
    #define GPIOF_ODR 0
  #endif

  #if defined GPIOF_OSPEEDR
    #if GPIOF_OSPEEDR != 0
      GPIOF->OSPEEDR = GPIOF_OSPEEDR; /* 0x50001408: GPIO port output speed register, Address offset: 0x08 */
    #endif
  #else
    #define GPIOF_OSPEEDR 0
  #endif

  #if defined GPIOF_OTYPER
    #if GPIOF_OTYPER != 0
      GPIOF->OTYPER = GPIOF_OTYPER; /* 0x50001404: GPIO port output type register, Address offset: 0x04 */
    #endif
  #else
    #define GPIOF_OTYPER 0
  #endif

  #if defined GPIOF_PUPDR
    #if GPIOF_PUPDR != 0
      GPIOF->PUPDR = GPIOF_PUPDR; /* 0x5000140C: GPIO port pull-up/pull-down register, Address offset: 0x0C */
    #endif
  #else
    #define GPIOF_PUPDR 0
  #endif  
} /* init_gpio() */

#if (GPIOA_AFR_0 != 0) || (GPIOA_AFR_1 != 0) || (GPIOA_BRR != 0) || (GPIOA_BSRR != 0) || (GPIOA_IDR != 0) || \
    (GPIOA_LCKR != 0) || (GPIOA_MODER != 0) || (GPIOA_ODR != 0) || (GPIOA_OSPEEDR != 0) || (GPIOA_OTYPER != 0) || \
    (GPIOA_PUPDR != 0)

  #define GPIOA_EN (!0)
#else
  #define GPIOA_EN 0
#endif

#if (GPIOB_AFR_0 != 0) || (GPIOB_AFR_1 != 0) || (GPIOB_BRR != 0) || (GPIOB_BSRR != 0) || (GPIOB_IDR != 0) || \
    (GPIOB_LCKR != 0) || (GPIOB_MODER != 0) || (GPIOB_ODR != 0) || (GPIOB_OSPEEDR != 0) || (GPIOB_OTYPER != 0) || \
    (GPIOB_PUPDR != 0)

  #define GPIOB_EN (!0)
#else
  #define GPIOB_EN 0
#endif

#if (GPIOF_AFR_0 != 0) || (GPIOF_AFR_1 != 0) || (GPIOF_BRR != 0) || (GPIOF_BSRR != 0) || (GPIOF_IDR != 0) || \
    (GPIOF_LCKR != 0) || (GPIOF_MODER != 0) || (GPIOF_ODR != 0) || (GPIOF_OSPEEDR != 0) || (GPIOF_OTYPER != 0) || \
    (GPIOF_PUPDR != 0)

  #define GPIOF_EN (!0)
#else
  #define GPIOF_EN 0
#endif

#if 0
  #if (GPIOA_EN != 0) || (GPIOB_EN != 0) || (GPIOF_EN != 0)
    init_gpio();
  #endif
#endif


////////////////////////////////////////////////////////////////////////////////////////
//  This code was generated for the stm32g031xx microcontroller by "stm32cgen" tool.
//                          https://github.com/a5021/stm32codegen                          
//  Arguments used:
//    -l g031f6 -p GPIOA GPIOB GPIOF -m gpio -f init_gpio -D
//    USE_ANALOG_MODE_FOR_ALL_PINS_BY_DEFALUT 1 "" GPIO_MODE
//    "(USE_ANALOG_MODE_FOR_ALL_PINS_BY_DEFALUT * UINT32_MAX)" PIN_XOR "(GPIO_MODE &
//    3UL)" "" PIN_MODE_INPUT "(0x00UL ^ PIN_XOR)" PIN_MODE_OUTPUT "(0x01UL ^
//    PIN_XOR)" PIN_MODE_AF "(0x02UL ^ PIN_XOR)" PIN_MODE_ANALOG "(0x03UL ^ PIN_XOR)"
//    "" "PIN_CFG(PIN, MODE)" "((MODE)   << ((PIN) * 2))" "PIN_MODE(PIN, MODE)"
//    "(((MODE)  << GPIO_MODER_MODER ## PIN ## _Pos) & GPIO_MODER_MODER ## PIN ##
//    _Msk)" "PIN_SPEED(PIN, SPEED)" "(((SPEED) << GPIO_OSPEEDR_OSPEEDR ## PIN ##
//    _Pos) & GPIO_OSPEEDR_OSPEEDR ## PIN ## _Msk)" "PIN_OTYPE(PIN, OTYPE)" "((OTYPE)
//    ? GPIO_OTYPER_OT_ ## PIN : 0)" "PIN_PUPD(PIN, PUPD)" "(((PUPD)  <<
//    GPIO_PUPDR_PUPDR ## PIN ## _Pos) & GPIO_PUPDR_PUPDR ## PIN ## _Msk)"
//    "PIN_AF(PIN, AF)" "(AF << (PIN * 4))" "" PA0_AF1_USART1_CTS "PIN_AF(0, 1ULL)"
//    PA1_AF0_EVENTOUT "PIN_AF(1, 0ULL)" PA1_AF1_USART1_RTS "PIN_AF(1, 1ULL)"
//    PA2_AF1_USART1_TX "PIN_AF(2, 1ULL)" PA3_AF1_USART1_RX "PIN_AF(3, 1ULL)"
//    PA4_AF0_SPI1_NSS "PIN_AF(4, 0ULL)" PA4_AF1_USART1_CK "PIN_AF(4, 1ULL)"
//    PA4_AF4_TIM14_CH1 "PIN_AF(4, 4ULL)" PA5_AF0_SPI1_SCK "PIN_AF(5, 0ULL)"
//    PA6_AF0_SPI1_MISO "PIN_AF(6, 0ULL)" PA6_AF1_TIM3_CH1 "PIN_AF(6, 1ULL)"
//    PA6_AF2_TIM1_BKIN "PIN_AF(6, 2ULL)" PA6_AF5_TIM16_CH1 "PIN_AF(6, 5ULL)"
//    PA6_AF6_EVENTOUT "PIN_AF(6, 6ULL)" PA7_AF0_SPI1_MOSI "PIN_AF(7, 0ULL)"
//    PA7_AF1_TIM3_CH2 "PIN_AF(7, 1ULL)" PA7_AF2_TIM1_CH1N "PIN_AF(7, 2ULL)"
//    PA7_AF4_TIM14_CH1 "PIN_AF(7, 4ULL)" PA7_AF5_TIM17_CH1 "PIN_AF(7, 5ULL)"
//    PA7_AF6_EVENTOUT "PIN_AF(7, 6ULL)" PA9_AF1_USART1_TX "PIN_AF(9, 1ULL)"
//    PA9_AF2_TIM1_CH2 "PIN_AF(9, 2ULL)" PA9_AF4_I2C1_SCL "PIN_AF(9, 4ULL)"
//    PA10_AF0_TIM17_BKIN "PIN_AF(10, 0ULL)" PA10_AF1_USART1_RX "PIN_AF(10, 1ULL)"
//    PA10_AF2_TIM1_CH3 "PIN_AF(10, 2ULL)" PA10_AF4_I2C1_SDA "PIN_AF(10, 4ULL)"
//    PA13_AF0_SWDIO "PIN_AF(13, 0ULL)" PA13_AF1_IR_OUT "PIN_AF(13, 1ULL)"
//    PA14_AF0_SWCLK "PIN_AF(14, 0ULL)" PA14_AF1_USART1_TX "PIN_AF(14, 1ULL)" ""
//    PB1_AF0_TIM14_CH1 "PIN_AF(1, 0ULL)" PB1_AF1_TIM3_CH4 "PIN_AF(1, 1ULL)"
//    PB1_AF2_TIM1_CH3N "PIN_AF(1, 2ULL)" "" PIN_TYPE_PP 0x00UL PIN_TYPE_OD 0x01UL ""
//    PIN_SPEED_LOW 0x00UL PIN_SPEED_MED 0x01UL PIN_SPEED_HIGH 0x03UL "" PIN_PUPD_NONE
//    0x00UL PIN_PUPD_UP 0x01UL PIN_PUPD_DOWN 0x02UL "" _BR(PIN) "GPIO_BSRR_BR_ ##
//    PIN" BR(PIN) _BR(PIN) _BS(PIN) "GPIO_BSRR_BS_ ## PIN" BS(PIN) _BS(PIN) _ODR(PIN)
//    "GPIO_ODR_ ## PIN" ODR(PIN) _ODR(PIN) "" GPIOA_MODER "(GPIO_MODE ^
//    (GPIOA_MODE))" GPIOB_MODER "(GPIO_MODE ^ (GPIOB_MODE))" GPIOF_MODER "(GPIO_MODE
//    ^ (GPIOF_MODE))" "" GPIOA_AFR_0 "(GPIOA_AF & UINT32_MAX)" GPIOA_AFR_1
//    "((GPIOA_AF >> 32) & UINT32_MAX)" "" GPIOB_AFR_0 "(GPIOB_AF & UINT32_MAX)"
//    GPIOB_AFR_1 "((GPIOB_AF >> 32) & UINT32_MAX)" -H "" -H "#define
//    CONFIGURE_PIN(GPIOx, PIN, MODE, OTYPE, SPEED, PUPD) do {
//    \" -H "  if (MODE)   MODIFY_REG((GPIOx)->MODER,   (0x03UL << ((PIN) * 2)),
//    ((MODE)  << ((PIN) * 2))); \" -H "  if (SPEED)  MODIFY_REG((GPIOx)->OSPEEDR,
//    (0x03UL << ((PIN) * 2)), ((SPEED) << ((PIN) * 2))); \" -H "  if (PUPD)
//    MODIFY_REG((GPIOx)->PUPDR,   (0x03UL << ((PIN) * 2)), ((PUPD)  << ((PIN) * 2)));
//    \" -H "  if (OTYPE)  MODIFY_REG((GPIOx)->OTYPER,  (0x01UL << (PIN)),
//    ((OTYPE) << (PIN)));       \" -H }while(0) -H "" -H "#ifndef USART1_EN" -H "
//    #define USART1_EN 0" -H #endif -H "" -H "#ifndef SPI1_EN" -H "  #define SPI1_EN
//    0" -H #endif -H "" -H "#ifndef I2C1_EN" -H "  #define I2C1_EN 0" -H #endif -H ""
//    -H "#ifndef SWD_EN" -H "  #ifndef NDEBUG" -H "    #define SWD_EN 1" -H "  #else"
//    -H "    #define SWD_EN 0" -H "  #endif" -H #endif -H "" -H "#define
//    GPIO_MODE_EXAMPLE (       \" -H "  + PIN_MODE(0,  PIN_MODE_ANALOG) \" -H "  +
//    PIN_MODE(1,  PIN_MODE_ANALOG) \" -H "  + PIN_MODE(2,  PIN_MODE_ANALOG) \" -H "
//    + PIN_MODE(3,  PIN_MODE_ANALOG) \" -H "  + PIN_MODE(4,  PIN_MODE_ANALOG) \" -H "
//    + PIN_MODE(5,  PIN_MODE_ANALOG) \" -H "  + PIN_MODE(6,  PIN_MODE_ANALOG) \" -H "
//    + PIN_MODE(7,  PIN_MODE_ANALOG) \" -H "  + PIN_MODE(8,  PIN_MODE_ANALOG) \" -H "
//    + PIN_MODE(9,  PIN_MODE_ANALOG) \" -H "  + PIN_MODE(10, PIN_MODE_ANALOG) \" -H "
//    + PIN_MODE(11, PIN_MODE_ANALOG) \" -H "  + PIN_MODE(12, PIN_MODE_ANALOG) \" -H "
//    + PIN_MODE(13, PIN_MODE_ANALOG) \" -H "  + PIN_MODE(14, PIN_MODE_ANALOG) \" -H "
//    + PIN_MODE(15, PIN_MODE_ANALOG) \" -H ) -H "" -H "#define GPIOA_MODE (
//    \" -H "  !0         * PIN_MODE(0,  PIN_MODE_OUTPUT) /* PA0  -- OUTPUT     */ |
//    \" -H "  !0         * PIN_MODE(1,  PIN_MODE_OUTPUT) /* PA1  -- OUTPUT     */ |
//    \" -H "  !USART1_EN * PIN_MODE(2,  PIN_MODE_OUTPUT) /* PA2  -- OUTPUT     */ |
//    \" -H "  !USART1_EN * PIN_MODE(3,  PIN_MODE_OUTPUT) /* PA3  -- OUTPUT     */ |
//    \" -H "  USART1_EN  * PIN_MODE(2,  PIN_MODE_AF)     /* PA2  -- USART1 TX  */ |
//    \" -H "  USART1_EN  * PIN_MODE(3,  PIN_MODE_AF)     /* PA3  -- USART1 RX  */ |
//    \" -H "  !SPI1_EN   * PIN_MODE(4,  PIN_MODE_OUTPUT) /* PA4  -- OUTPUT     */ |
//    \" -H "  SPI1_EN    * PIN_MODE(4,  PIN_MODE_AF)     /* PA4  -- SPI1 CS    */ |
//    \" -H "  SPI1_EN    * PIN_MODE(5,  PIN_MODE_AF)     /* PA5  -- SPI1 SCK   */ |
//    \" -H "  SPI1_EN    * PIN_MODE(6,  PIN_MODE_AF)     /* PA6  -- SPI1 MISO  */ |
//    \" -H "  SPI1_EN    * PIN_MODE(7,  PIN_MODE_AF)     /* PA7  -- SPI1 MOSI  */ |
//    \" -H "  I2C1_EN    * PIN_MODE(9,  PIN_MODE_AF)     /* PA9  -- I2C1 SDA   */ |
//    \" -H "  I2C1_EN    * PIN_MODE(10, PIN_MODE_AF)     /* PA10 -- I2C1 SCL   */ |
//    \" -H "  SWD_EN     * PIN_MODE(13, PIN_MODE_AF)     /* PA13 -- SWDCLK     */ |
//    \" -H "  SWD_EN     * PIN_MODE(14, PIN_MODE_AF)     /* PA14 -- SWDIO      */
//    \" -H ) -H "" -H "#if 0" -H "#define GPIOA_OTYPE (                         \" -H
//    "  I2C1_EN   * (PIN_TYPE_OD << 9)            | \" -H "  I2C1_EN   * (PIN_TYPE_OD
//    << 10)             \" -H ) -H #else -H "#define GPIOA_OTYPE (
//    \" -H "  I2C1_EN   * PIN_OTYPE(9,  PIN_TYPE_OD)    | \" -H "  I2C1_EN   *
//    PIN_OTYPE(10, PIN_TYPE_OD)      \" -H ) -H #endif -H "" -H "#define GPIOA_OSPEED
//    (                        \" -H "  SPI1_EN   * PIN_SPEED(4,  PIN_SPEED_HIGH) | \"
//    -H "  SPI1_EN   * PIN_SPEED(5,  PIN_SPEED_HIGH) | \" -H "  SPI1_EN   *
//    PIN_SPEED(6,  PIN_SPEED_HIGH) | \" -H "  SPI1_EN   * PIN_SPEED(7,
//    PIN_SPEED_HIGH)   \" -H ) -H "" -H "#define GPIOA_AF (
//    \" -H "  USART1_EN * PA2_AF1_USART1_TX             | \" -H "  USART1_EN *
//    PA3_AF1_USART1_RX             | \" -H "  SPI1_EN   * PA4_AF0_SPI1_NSS
//    | \" -H "  SPI1_EN   * PA5_AF0_SPI1_SCK              | \" -H "  SPI1_EN   *
//    PA6_AF0_SPI1_MISO             | \" -H "  SPI1_EN   * PA7_AF0_SPI1_MOSI
//    | \" -H "  I2C1_EN   * PA9_AF4_I2C1_SCL              | \" -H "  I2C1_EN   *
//    PA10_AF4_I2C1_SDA             | \" -H "  SWD_EN    * PA13_AF0_SWDIO
//    | \" -H "  SWD_EN    * PA14_AF0_SWCLK                  \" -H ) -H "" -H "#define
//    GPIOB_MODE                     PIN_MODE(1,  PIN_MODE_AF)" -H "#define
//    GPIOB_OSPEEDR                  PIN_SPEED(1, PIN_SPEED_HIGH)" -H "" -H "#define
//    GPIOB_AF                       PB1_AF2_TIM1_CH3N" -H "" -H "#define GPIOF_MODE (
//    \" -H "  PIN_MODE(0,  PIN_MODE_INPUT)              | \" -H "  PIN_MODE(1,
//    PIN_MODE_INPUT)                \" -H ) -H "" -H "#define GPIOF_PUPDR (
//    \" -H "  PIN_PUPD(0,  PIN_PUPD_UP)                 | \" -H "  PIN_PUPD(1,
//    PIN_PUPD_UP)                   \" -H ) --force-inline --no-def
////////////////////////////////////////////////////////////////////////////////////////


#ifdef __cplusplus
  }
#endif /* __cplusplus */
#endif /* __GPIO_H__ */

