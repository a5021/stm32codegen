/**
  * @file    tim14.h
  * @brief   This file contains all the register definitions for TIM14 peripheral
  *          on STM32G031F4P6 microcontroller.
  */

#ifndef TIM14_H
#define TIM14_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* TIM14 register definitions -------------------------------------------------*/

/**
  * @brief TIM14 Control Register 1 (TIM14_CR1)
  * @note  Address offset: 0x00
  *        Reset value: 0x0000
  */
typedef union {
    uint32_t reg;
    struct {
        uint32_t CEN       : 1;  /*!< Counter enable */
        uint32_t UDIS      : 1;  /*!< Update disable */
        uint32_t URS       : 1;  /*!< Update request source */
        uint32_t OPM       : 1;  /*!< One-pulse mode */
        uint32_t           : 3;  /*!< Reserved */
        uint32_t ARPE      : 1;  /*!< Auto-reload preload enable */
        uint32_t CKD       : 2;  /*!< Clock division */
        uint32_t           : 1;  /*!< Reserved */
        uint32_t UIFREMAP  : 1;  /*!< UIF status bit remapping */
        uint32_t           : 4;  /*!< Reserved */
    };
} T14_CR1_t;

/**
  * @brief TIM14 Interrupt Enable Register (TIM14_DIER)
  * @note  Address offset: 0x0C
  *        Reset value: 0x0000
  */
typedef union {
    uint32_t reg;
    struct {
        uint32_t UIE       : 1;  /*!< Update interrupt enable */
        uint32_t CC1IE     : 1;  /*!< Capture/Compare 1 interrupt enable */
        uint32_t           : 14; /*!< Reserved */
    };
} T14_DIER_t;

/**
  * @brief TIM14 Status Register (TIM14_SR)
  * @note  Address offset: 0x10
  *        Reset value: 0x0000
  */
typedef union {
    uint32_t reg;
    struct {
        uint32_t UIF       : 1;  /*!< Update interrupt flag */
        uint32_t CC1IF     : 1;  /*!< Capture/compare 1 interrupt flag */
        uint32_t           : 6;  /*!< Reserved */
        uint32_t CC1OF     : 1;  /*!< Capture/Compare 1 overcapture flag */
        uint32_t           : 6;  /*!< Reserved */
    };
} T14_SR_t;

/**
  * @brief TIM14 Event Generation Register (TIM14_EGR)
  * @note  Address offset: 0x14
  *        Reset value: 0x0000
  */
typedef union {
    uint32_t reg;
    struct {
        uint32_t UG        : 1;  /*!< Update generation */
        uint32_t CC1G      : 1;  /*!< Capture/compare 1 generation */
        uint32_t           : 14; /*!< Reserved */
    };
} T14_EGR_t;

/**
  * @brief TIM14 Capture/Compare Mode Register 1 (TIM14_CCMR1)
  * @note  Address offset: 0x18
  *        Reset value: 0x0000
  */
typedef union {
    uint32_t reg;
    struct {  /* Input capture mode */
        uint32_t CC1S      : 2;  /*!< Capture/Compare 1 selection */
        uint32_t IC1PSC    : 2;  /*!< Input capture 1 prescaler */
        uint32_t IC1F      : 4;  /*!< Input capture 1 filter */
        uint32_t           : 24; /*!< Reserved */
    };
    struct {  /* Output compare mode */
        uint32_t          : 2;  /* CC1S */
        uint32_t OC1FE     : 1;  /*!< Output compare 1 fast enable */
        uint32_t OC1PE     : 1;  /*!< Output compare 1 preload enable */
        uint32_t OC1M      : 3;  /*!< Output compare 1 mode */
        uint32_t           : 1;  /*!< Reserved */
        uint32_t OC1M_3    : 1;  /*!< Output compare 1 mode bit 3 */
        uint32_t           : 23; /*!< Reserved */
    };
} T14_CCMR1_t;

/**
  * @brief TIM14 Capture/Compare Enable Register (TIM14_CCER)
  * @note  Address offset: 0x20
  *        Reset value: 0x0000
  */
typedef union {
    uint32_t reg;
    struct {
        uint32_t CC1E      : 1;  /*!< Capture/Compare 1 output enable */
        uint32_t CC1P      : 1;  /*!< Capture/Compare 1 output Polarity */
        uint32_t           : 1;  /*!< Reserved */
        uint32_t CC1NP     : 1;  /*!< Capture/Compare 1 complementary output Polarity */
        uint32_t           : 12; /*!< Reserved */
    };
} T14_CCER_t;

/**
  * @brief TIM14 Counter Register (TIM14_CNT)
  * @note  Address offset: 0x24
  *        Reset value: 0x0000
  */
typedef union {
    uint32_t reg;
    struct {
        uint32_t CNT       : 16; /*!< Counter value */
        uint32_t           : 15; /*!< Reserved */
        uint32_t UIFCPY    : 1;  /*!< UIF Copy */
    };
} T14_CNT_t;

/**
  * @brief TIM14 Prescaler Register (TIM14_PSC)
  * @note  Address offset: 0x28
  *        Reset value: 0x0000
  */
typedef union {
    uint32_t reg;
    struct {
        uint32_t PSC       : 16; /*!< Prescaler value */
        uint32_t           : 16; /*!< Reserved */
    };
} T14_PSC_t;

/**
  * @brief TIM14 Auto-Reload Register (TIM14_ARR)
  * @note  Address offset: 0x2C
  *        Reset value: 0xFFFF
  */
typedef union {
    uint32_t reg;
    struct {
        uint32_t ARR       : 16; /*!< Auto-reload value */
        uint32_t           : 16; /*!< Reserved */
    };
} T14_ARR_t;

/**
  * @brief TIM14 Capture/Compare Register 1 (TIM14_CCR1)
  * @note  Address offset: 0x34
  *        Reset value: 0x0000
  */
typedef union {
    uint32_t reg;
    struct {
        uint32_t CCR1      : 16; /*!< Capture/Compare 1 value */
        uint32_t           : 16; /*!< Reserved */
    };
} T14_CCR1_t;

/**
  * @brief TIM14 Timer Input Selection Register (TIM14_TISEL)
  * @note  Address offset: 0x68
  *        Reset value: 0x0000
  */
typedef union {
    uint32_t reg;
    struct {
        uint32_t TI1SEL    : 4;  /*!< TI1 input selection */
        uint32_t           : 12; /*!< Reserved */
    };
} T14_TISEL_t;

/* TIM14 peripheral structure -------------------------------------------------*/

/**
  * @brief TIM14 Register Structure
  * @note  This structure maps all TIM14 registers in memory order
  */
typedef struct {
  T14_CR1_t         CR1;          /*!< Control register 1,              offset: 0x00 */
  uint32_t          reserved1;    /*!< Reserved,                        offset: 0x04 */
  uint32_t          reserved2;    /*!< Reserved,                        offset: 0x08 */
  T14_DIER_t        DIER;         /*!< DMA/Interrupt enable register,   offset: 0x0C */
  T14_SR_t          SR;           /*!< Status register,                 offset: 0x10 */
  T14_EGR_t         EGR;          /*!< Event generation register,       offset: 0x14 */
  T14_CCMR1_t       CCMR1;        /*!< Capture/compare mode register 1, offset: 0x18 */
  uint32_t          reserved3;    /*!< Reserved,                        offset: 0x1C */
  T14_CCER_t        CCER;         /*!< Capture/compare enable register, offset: 0x20 */
  T14_CNT_t         CNT;          /*!< Counter,                         offset: 0x24 */
  T14_PSC_t         PSC;          /*!< Prescaler,                       offset: 0x28 */
  T14_ARR_t         ARR;          /*!< Auto-reload register,            offset: 0x2C */
  uint32_t          reserved4;    /*!< Reserved,                        offset: 0x30 */
  T14_CCR1_t        CCR1;         /*!< Capture/compare register 1,      offset: 0x34 */
  uint32_t          reserved5[6]; /*!< Reserved,                        offset: 0x38-0x4C */
  T14_TISEL_t       TISEL;        /*!< Input selection register,        offset: 0x68 */
} T14_TypeDef;

/* Peripheral memory map -----------------------------------------------------*/

#define T14_BASE            (0x40002000UL)  /*!< TIM14 base address */
#define T14                 (*(volatile T14_TypeDef *)T14_BASE)  /*!< TIM14 peripheral pointer */

#ifdef __cplusplus
}
#endif

#endif /* TIM14_H */
