/**
 * @file    stm32f103xb_test.h
 * @brief   Synthetic CMSIS header for unit-testing stm32codegen.
 *
 * This file mirrors the structure of the real stm32f103xb.h but is
 * intentionally small. It covers the subset of CMSIS header patterns
 * exercised by the parser and code generator:
 *
 *   - typedef structs with @brief descriptions
 *   - peripheral base-address macros (Peripheral_memory_map)
 *   - peripheral instance declarations with TypeDef casts
 *   - bit-field defines (Pos / Msk / final)
 *   - IRQn enum entries
 */

#ifndef __STM32F103xB_TEST_H
#define __STM32F103xB_TEST_H

#include <stdint.h>

/* ==================================================================== */
/*  Cortex-M3 core definitions                                            */
/* ==================================================================== */

#define __CM3_REV              0x0200U
#define __MPU_PRESENT          0U
#define __NVIC_PRIO_BITS       4U
#define __Vendor_SysTickConfig 0U

/* ==================================================================== */
/*  IRQn definition                                                       */
/* ==================================================================== */

typedef enum
{
  NonMaskableInt_IRQn        = -14,   /*!< 2 Non Maskable Interrupt   */
  HardFault_IRQn             = -13,   /*!< 3 Cortex-M3 Hard Fault     */

  WWDG_IRQn                  = 0,     /*!< Window watchdog            */
  PVD_IRQn                   = 1,     /*!< PVD / EXT line 16           */
  FLASH_IRQn                 = 3,     /*!< Flash global               */
  RCC_IRQn                   = 4,     /*!< RCC global                 */
  EXTI0_IRQn                 = 5,     /*!< EXTI Line0                 */
  EXTI1_IRQn                 = 6,     /*!< EXTI Line1                 */
  TIM2_IRQn                  = 28,    /*!< TIM2 global                */
  TIM3_IRQn                  = 29,    /*!< TIM3 global                */
  TIM4_IRQn                  = 30,    /*!< TIM4 global                */
  I2C1_EV_IRQn               = 31,    /*!< I2C1 Event                 */
  SPI1_IRQn                  = 35,    /*!< SPI1 global                */
  USART1_IRQn                = 37,    /*!< USART1 global              */
  ADC1_2_IRQn                = 40,    /*!< ADC1 + ADC2 global         */
} IRQn_Type;

/** @addtogroup Peripheral_registers_structures
  * @{
  */

/**
  * @brief Analog to Digital Converter
  */

typedef struct
{
  __IO uint32_t SR;
  __IO uint32_t CR1;
  __IO uint32_t CR2;
  __IO uint32_t SMPR1;
  __IO uint32_t SMPR2;
  __IO uint32_t JOFR1;
  __IO uint32_t JOFR2;
  __IO uint32_t JOFR3;
  __IO uint32_t JOFR4;
  __IO uint32_t HTR;
  __IO uint32_t LTR;
  __IO uint32_t SQR1;
  __IO uint32_t SQR2;
  __IO uint32_t SQR3;
  __IO uint32_t JSQR;
  __IO uint32_t JDR1;
  __IO uint32_t JDR2;
  __IO uint32_t JDR3;
  __IO uint32_t JDR4;
  __IO uint32_t DR;
} ADC_TypeDef;

/**
  * @brief TIM Timers
  */

typedef struct
{
  __IO uint32_t CR1;
  __IO uint32_t CR2;
  __IO uint32_t SMCR;
  __IO uint32_t DIER;
  __IO uint32_t SR;
  __IO uint32_t EGR;
  __IO uint32_t CCMR1;
  __IO uint32_t CCMR2;
  __IO uint32_t CCER;
  __IO uint32_t CNT;
  __IO uint32_t PSC;
  __IO uint32_t ARR;
  __IO uint32_t RCR;
  __IO uint32_t CCR1;
  __IO uint32_t CCR2;
  __IO uint32_t CCR3;
  __IO uint32_t CCR4;
  __IO uint32_t BDTR;
  __IO uint32_t DCR;
  __IO uint32_t DMAR;
  __IO uint32_t OR;
}TIM_TypeDef;

/**
  * @brief Reset and Clock Control
  */

typedef struct
{
  __IO uint32_t CR;
  __IO uint32_t CFGR;
  __IO uint32_t CIR;
  __IO uint32_t APB2RSTR;
  __IO uint32_t APB1RSTR;
  __IO uint32_t AHBENR;
  __IO uint32_t APB2ENR;
  __IO uint32_t APB1ENR;
  __IO uint32_t BDCR;
  __IO uint32_t CSR;
} RCC_TypeDef;

/**
  * @brief General Purpose I/O
  */

typedef struct
{
  __IO uint32_t CRL;
  __IO uint32_t CRH;
  __IO uint32_t IDR;
  __IO uint32_t ODR;
  __IO uint16_t BSRR;
  uint16_t      RESERVED0;
  __IO uint32_t BRR;
  __IO uint32_t LCKR;
} GPIO_TypeDef;

/**
  * @brief Universal Synchronous Asynchronous Receiver Transmitter
  */

typedef struct
{
  __IO uint16_t SR;
  uint16_t      RESERVED0;
  __IO uint16_t DR;
  uint16_t      RESERVED1;
  __IO uint16_t BRR;
  uint16_t      RESERVED2;
  __IO uint32_t CR1;
  __IO uint32_t CR2;
  __IO uint32_t CR3;
  __IO uint16_t GTPR;
  uint16_t      RESERVED3;
} USART_TypeDef;

/** @addtogroup Peripheral_memory_map
  * @{
  */

#define PERIPH_BASE           0x40000000UL
#define APB1PERIPH_BASE       PERIPH_BASE
#define APB2PERIPH_BASE       (PERIPH_BASE + 0x00010000UL)
#define AHBPERIPH_BASE        (PERIPH_BASE + 0x00020000UL)

#define TIM2_BASE             (APB1PERIPH_BASE + 0x00000000UL)
#define TIM3_BASE             (APB1PERIPH_BASE + 0x00000400UL)
#define TIM4_BASE             (APB1PERIPH_BASE + 0x00000800UL)
#define USART1_BASE           (APB2PERIPH_BASE + 0x00003800UL)
#define GPIOA_BASE            (APB2PERIPH_BASE + 0x00000000UL)
#define GPIOB_BASE            (APB2PERIPH_BASE + 0x00000400UL)
#define GPIOC_BASE            (APB2PERIPH_BASE + 0x00000800UL)
#define ADC1_BASE             (APB2PERIPH_BASE + 0x00002000UL)
#define ADC2_BASE             (APB2PERIPH_BASE + 0x00002400UL)
#define RCC_BASE              (AHBPERIPH_BASE  + 0x00001000UL)

/* ==================================================================== */
/*  Peripheral_declaration                                               */
/* ==================================================================== */

#define TIM2                ((TIM_TypeDef *) TIM2_BASE)
#define TIM3                ((TIM_TypeDef *) TIM3_BASE)
#define TIM4                ((TIM_TypeDef *) TIM4_BASE)
#define USART1              ((USART_TypeDef *) USART1_BASE)
#define GPIOA               ((GPIO_TypeDef *) GPIOA_BASE)
#define GPIOB               ((GPIO_TypeDef *) GPIOB_BASE)
#define GPIOC               ((GPIO_TypeDef *) GPIOC_BASE)
#define ADC1                ((ADC_TypeDef *) ADC1_BASE)
#define ADC2                ((ADC_TypeDef *) ADC2_BASE)
#define RCC                 ((RCC_TypeDef *) RCC_BASE)

/* ==================================================================== */
/*  Bit-field definitions — TIM CR1                                      */
/* ==================================================================== */

#define TIM_CR1_CEN_Pos       (0U)
#define TIM_CR1_CEN_Msk       (0x1UL << TIM_CR1_CEN_Pos)
#define TIM_CR1_CEN           TIM_CR1_CEN_Msk
/*!<Counter enable */

#define TIM_CR1_UDIS_Pos      (1U)
#define TIM_CR1_UDIS_Msk      (0x1UL << TIM_CR1_UDIS_Pos)
#define TIM_CR1_UDIS          TIM_CR1_UDIS_Msk
/*!<Update disable */

#define TIM_CR1_URS_Pos       (2U)
#define TIM_CR1_URS_Msk       (0x1UL << TIM_CR1_URS_Pos)
#define TIM_CR1_URS           TIM_CR1_URS_Msk
/*!<Update request source */

#define TIM_CR1_UDIV_Pos      (3U)
#define TIM_CR1_UDIV_Msk      (0x1UL << TIM_CR1_UDIV_Pos)
#define TIM_CR1_UDIV          TIM_CR1_UDIV_Msk
/*!<Update discard */

#define TIM_CR1_CMS_Pos       (5U)
#define TIM_CR1_CMS_Msk       (0x3UL << TIM_CR1_CMS_Pos)
#define TIM_CR1_CMS           TIM_CR1_CMS_Msk
/*!<Center-aligned mode selection */

#define TIM_CR1_DIR_Pos       (4U)
#define TIM_CR1_DIR_Msk       (0x1UL << TIM_CR1_DIR_Pos)
#define TIM_CR1_DIR           TIM_CR1_DIR_Msk
/*!<Direction */

/* ==================================================================== */
/*  Bit-field definitions — TIM DIER                                     */
/* ==================================================================== */

#define TIM_DIER_UIE_Pos      (0U)
#define TIM_DIER_UIE_Msk      (0x1UL << TIM_DIER_UIE_Pos)
#define TIM_DIER_UIE          TIM_DIER_UIE_Msk
/*!<Update interrupt enable */

#define TIM_DIER_CC1IE_Pos    (1U)
#define TIM_DIER_CC1IE_Msk    (0x1UL << TIM_DIER_CC1IE_Pos)
#define TIM_DIER_CC1IE        TIM_DIER_CC1IE_Msk
/*!<Capture/compare 1 interrupt enable */

#define TIM_DIER_CC4IE_Pos    (4U)
#define TIM_DIER_CC4IE_Msk    (0x1UL << TIM_DIER_CC4IE_Pos)
#define TIM_DIER_CC4IE        TIM_DIER_CC4IE_Msk
/*!<Capture/compare 4 interrupt enable */

#define TIM_DIER_BIE_Pos      (7U)
#define TIM_DIER_BIE_Msk      (0x1UL << TIM_DIER_BIE_Pos)
#define TIM_DIER_BIE          TIM_DIER_BIE_Msk
/*!<Break interrupt enable */

/* ==================================================================== */
/*  Bit-field definitions — ADC CR1                                      */
/* ==================================================================== */

#define ADC_CR1_AWDIE_Pos     (4U)
#define ADC_CR1_AWDIE_Msk     (0x1UL << ADC_CR1_AWDIE_Pos)
#define ADC_CR1_AWDIE         ADC_CR1_AWDIE_Msk
/*!<AWD interrupt enable */

#define ADC_CR1_EOCIE_Pos     (5U)
#define ADC_CR1_EOCIE_Msk     (0x1UL << ADC_CR1_EOCIE_Pos)
#define ADC_CR1_EOCIE         ADC_CR1_EOCIE_Msk
/*!<End of regular conversion interrupt */

/* ==================================================================== */
/*  Bit-field definitions — RCC AHBENR (peripheral clock enables)         */
/* ==================================================================== */

#define RCC_AHBENR_DMA1EN_Pos    (0U)
#define RCC_AHBENR_DMA1EN_Msk    (0x1UL << RCC_AHBENR_DMA1EN_Pos)
#define RCC_AHBENR_DMA1EN        RCC_AHBENR_DMA1EN_Msk
/*!<DMA1 clock enable */

#define RCC_AHBENR_DMA2EN_Pos    (1U)
#define RCC_AHBENR_DMA2EN_Msk    (0x1UL << RCC_AHBENR_DMA2EN_Pos)
#define RCC_AHBENR_DMA2EN        RCC_AHBENR_DMA2EN_Msk
/*!<DMA2 clock enable */

#define RCC_AHBENR_SRAMEN_Pos    (2U)
#define RCC_AHBENR_SRAMEN_Msk    (0x1UL << RCC_AHBENR_SRAMEN_Pos)
#define RCC_AHBENR_SRAMEN        RCC_AHBENR_SRAMEN_Msk
/*!<SRAM interface clock enable */

#define RCC_AHBENR_FLASGEN_Pos   (4U)
#define RCC_AHBENR_FLASGEN_Msk   (0x1UL << RCC_AHBENR_FLASGEN_Pos)
#define RCC_AHBENR_FLASGEN       RCC_AHBENR_FLASGEN_Msk
/*!<FLASH interface clock enable */

#define RCC_AHBENR_GPIOAEN_Pos   (2U)
#define RCC_AHBENR_GPIOAEN_Msk   (0x1UL << RCC_AHBENR_GPIOAEN_Pos)
#define RCC_AHBENR_GPIOAEN       RCC_AHBENR_GPIOAEN_Msk
/*!<GPIOA clock enable */

#define RCC_AHBENR_GPIOBEN_Pos   (3U)
#define RCC_AHBENR_GPIOBEN_Msk   (0x1UL << RCC_AHBENR_GPIOBEN_Pos)
#define RCC_AHBENR_GPIOBEN       RCC_AHBENR_GPIOBEN_Msk
/*!<GPIOB clock enable */

#define RCC_AHBENR_GPIOCEN_Pos   (4U)
#define RCC_AHBENR_GPIOCEN_Msk   (0x1UL << RCC_AHBENR_GPIOCEN_Pos)
#define RCC_AHBENR_GPIOCEN       RCC_AHBENR_GPIOCEN_Msk
/*!<GPIOC clock enable */

/* ==================================================================== */
/*  Bit-field definitions — GPIO CRL/CRH (F1-specific)                   */
/* ==================================================================== */

#define GPIO_CRL_MODE_Pos      (0U)
#define GPIO_CRL_MODE_Msk      (0x3UL << GPIO_CRL_MODE_Pos)
#define GPIO_CRL_MODE          GPIO_CRL_MODE_Msk
/*!<PORTA MODE */

#define GPIO_CRL_CNF_Pos       (2U)
#define GPIO_CRL_CNF_Msk       (0x3UL << GPIO_CRL_CNF_Pos)
#define GPIO_CRL_CNF           GPIO_CRL_CNF_Msk
/*!<PORTA CNF */

#define GPIO_CRH_MODE_Pos      (0U)
#define GPIO_CRH_MODE_Msk      (0x3UL << GPIO_CRH_MODE_Pos)
#define GPIO_CRH_MODE          GPIO_CRH_MODE_Msk
/*!<PORTC MODE */

#define GPIO_CRH_CNF_Pos       (2U)
#define GPIO_CRH_CNF_Msk       (0x3UL << GPIO_CRH_CNF_Pos)
#define GPIO_CRH_CNF           GPIO_CRH_CNF_Msk
/*!<PORTC CNF */

#endif /* __STM32F103xB_TEST_H */
