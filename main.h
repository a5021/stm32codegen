#ifndef __MAIN_H__
#define __MAIN_H__

#ifdef __cplusplus /* provide compatibility between C and C++ */
  extern "C" {
#endif
#include "stm32g030xx.h" /* Include CMSIS header file */

/* Uncomment the corresponding line if using the peripheral is intended. */
// #include "pwr.h"
// #include "tim.h"
// #include "rtc.h"
// #include "wwdg.h"
// #include "iwdg.h"
// #include "spi.h"
// #include "usart.h"
// #include "i2c.h"
// #include "tamp.h"
// #include "syscfg.h"
// #include "adc.h"
// #include "dbg.h"
// #include "dma.h"
// #include "dmamux.h"
// #include "exti.h"
// #include "crc.h"
// #include "flash.h"

#include "gpio.h"
#include "rcc.h"


/* Initialize all the required peripherals */
__STATIC_INLINE void init(void) {

#if(defined(FLASH_EN) && FLASH_EN)
  init_flash();
#endif

  /* RCC should always be initialized as it is essential peripheral for the functioning of the system. */
  init_rcc();

#if(defined(PWR_EN) && PWR_EN)
  init_pwr();
#endif

#if(defined(TIM1_EN) && TIM1_EN) || (defined(TIM3_EN) && TIM3_EN) || (defined(TIM14_EN) && TIM14_EN) || (defined(TIM16_EN) && TIM16_EN) || (defined(TIM17_EN) && TIM17_EN)
  init_tim();
#endif

#if(defined(RTC_EN) && RTC_EN)
  init_rtc();
#endif

#if(defined(WWDG_EN) && WWDG_EN)
  init_wwdg();
#endif

#if(defined(IWDG_EN) && IWDG_EN)
  init_iwdg();
#endif

#if(defined(SPI1_EN) && SPI1_EN) || (defined(SPI2_EN) && SPI2_EN)
  init_spi();
#endif

#if(defined(USART1_EN) && USART1_EN) || (defined(USART2_EN) && USART2_EN)
  init_usart();
#endif

#if(defined(I2C1_EN) && I2C1_EN) || (defined(I2C2_EN) && I2C2_EN)
  init_i2c();
#endif

#if(defined(TAMP_EN) && TAMP_EN)
  init_tamp();
#endif

#if(defined(SYSCFG_EN) && SYSCFG_EN)
  init_syscfg();
#endif

#if(defined(ADC1_EN) && ADC1_EN)
  init_adc();
#endif

#if(defined(DBG_EN) && DBG_EN)
  init_dbg();
#endif

#if(defined(DMA1_EN) && DMA1_EN)
  init_dma();
#endif

#if(defined(DMAMUX1_EN) && DMAMUX1_EN) || (defined(DMAMUX1_Channel0_EN) && DMAMUX1_Channel0_EN) || (defined(DMAMUX1_Channel1_EN) && DMAMUX1_Channel1_EN) || (defined(DMAMUX1_Channel2_EN) && DMAMUX1_Channel2_EN) || (defined(DMAMUX1_Channel3_EN) && DMAMUX1_Channel3_EN) || (defined(DMAMUX1_Channel4_EN) && DMAMUX1_Channel4_EN)
  init_dmamux();
#endif

#if(defined(EXTI_EN) && EXTI_EN)
  init_exti();
#endif

#if(defined(CRC_EN) && CRC_EN)
  init_crc();
#endif

  /* GPIO should always be initialized as it is essential peripheral for the functioning of the system. */
  init_gpio();

} /* init() */


////////////////////////////////////////////////////////////////////////////////////////
//  This code was generated for the stm32g030xx microcontroller by "stm32cgen" tool.
//                          https://github.com/a5021/stm32codegen                          
//  Arguments used: -l g030f6 -M
////////////////////////////////////////////////////////////////////////////////////////


#ifdef __cplusplus
  }
#endif /* __cplusplus */
#endif /* __MAIN_H__ */

