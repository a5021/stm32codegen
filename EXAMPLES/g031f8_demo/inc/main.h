#ifndef __MAIN_H__
#define __MAIN_H__

#ifdef __cplusplus /* provide compatibility between C and C++ */
  extern "C" {
#endif

#define NO                             0
#define NONE                           NO
#define OFF                            NO
#define YES                            (!NO)
#define ON                             YES

#define HCLK                           8    /* 8 to 64 (MHz) with a step of 4 */

#define SYSTICK_CLOCK_SOURCE           0    /* 0 = HCLK / 8; 1 = HCLK         */
#define SYSTICK_ENABLE                 YES
#define SYSTICK_IRQ_ENABLE             NO

#if HCLK < 8 || HCLK > 64 || (HCLK % 4 != 0)
  #error "Invalid HCLK value. Must be between 8 and 64 MHz with a step of 4 MHz."
#endif 


#include "stm32g031xx.h" /* Include CMSIS header file */

/* Uncomment the corresponding line if using the peripheral is intended. */
// #include "pwr.h"
// #include "tim.h"
// #include "rtc.h"
// #include "wwdg.h"
// #include "iwdg.h"
// #include "spi.h"
// #include "usart.h"
// #include "i2c.h"
// #include "lptim.h"
// #include "tamp.h"
// #include "syscfg.h"
// #include "vrefbuf.h"
// #include "adc.h"
// #include "dbg.h"
// #include "dma.h"
// #include "dmamux.h"
// #include "exti.h"
// #include "crc.h"
// #include "flash.h"

#include "gpio.h"
#include "rcc.h"


__STATIC_FORCEINLINE void init_systick(void);


/* Initialize all the required peripherals */
__STATIC_FORCEINLINE void init(void) {

#if(defined(FLASH_EN) && FLASH_EN)
  init_flash();
#endif

  /* RCC should always be initialized as it is essential peripheral for the functioning of the system. */
  init_rcc();

#if(defined(PWR_EN) && PWR_EN)
  init_pwr();
#endif

#if(defined(TIM1_EN) && TIM1_EN) || (defined(TIM2_EN) && TIM2_EN) || (defined(TIM3_EN) && TIM3_EN) || (defined(TIM14_EN) && TIM14_EN) || (defined(TIM16_EN) && TIM16_EN) || (defined(TIM17_EN) && TIM17_EN)
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

#if(defined(LPUART1_EN) && LPUART1_EN) || (defined(USART1_EN) && USART1_EN) || (defined(USART2_EN) && USART2_EN)
  init_usart();
#endif

#if(defined(I2C1_EN) && I2C1_EN) || (defined(I2C2_EN) && I2C2_EN)
  init_i2c();
#endif

#if(defined(LPTIM1_EN) && LPTIM1_EN) || (defined(LPTIM2_EN) && LPTIM2_EN)
  init_lptim();
#endif

#if(defined(TAMP_EN) && TAMP_EN)
  init_tamp();
#endif

#if(defined(SYSCFG_EN) && SYSCFG_EN)
  init_syscfg();
#endif

#if(defined(VREFBUF_EN) && VREFBUF_EN)
  init_vrefbuf();
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

  /* Perform additional steps after initialization */
  init_systick();

} /* init() */


__STATIC_FORCEINLINE void init_systick(void) {

  /* Initialize SysTick to 1 ms period */

  SysTick->LOAD = HCLK * 1000 / (8 - SYSTICK_CLOCK_SOURCE * 7) - 1;
  SysTick->VAL  = SysTick->LOAD;
  SysTick->CTRL = (
    + SYSTICK_CLOCK_SOURCE * SysTick_CTRL_CLKSOURCE_Msk
    + SYSTICK_IRQ_ENABLE   * SysTick_CTRL_TICKINT_Msk
    + SYSTICK_ENABLE       * SysTick_CTRL_ENABLE_Msk
  );
} /* init_systick() */


__STATIC_FORCEINLINE void idle(void); // {
  /* Routine to handle idle state (waiting for an event) */


//} /* idle() */


__STATIC_FORCEINLINE unsigned process(void); // {
  /* Routine to perform main loop operations */


//} /* process() */

#if YES == SYSTICK_IRQ_ENABLE
  #define __SYSTICK_VOLATILE volatile
#else
  #define __SYSTICK_VOLATILE
#endif

#if defined(__GNUC__) && ! defined(__clang__)
  void _close_r(void){} void _close(void){} void _lseek_r(void){} void _lseek(void){} void _read_r(void){} void _read(void){} void _write_r(void){}
#endif

////////////////////////////////////////////////////////////////////////////////////////
//  This code was generated for the stm32g031xx microcontroller by "stm32cgen" tool.
//                          https://github.com/a5021/stm32codegen                          
//  Arguments used:
//    -s g031f8 -M -D NO 0 NONE NO OFF NO YES (!NO) ON YES "" HCLK "8    /* 8 to 64
//    (MHz) with a step of 4 */" "" SYSTICK_CLOCK_SOURCE "0    /* 0 = HCLK / 8; 1 =
//    HCLK         */" SYSTICK_ENABLE YES SYSTICK_IRQ_ENABLE NO -H "#if HCLK < 8 ||
//    HCLK > 64 || (HCLK % 4 != 0)" -H "  #error "Invalid HCLK value. Must be between
//    8 and 64 MHz with a step of 4 MHz."" -H #endif --force-inline --post-init
//    init_systick -F "" -F "__STATIC_FORCEINLINE void init_systick(void) {" -F "" -F
//    "  /* Initialize SysTick to 1 ms period */" -F "" -F "  SysTick->LOAD = HCLK *
//    1000 / (8 - SYSTICK_CLOCK_SOURCE * 7) - 1;" -F "  SysTick->VAL  =
//    SysTick->LOAD;" -F "  SysTick->CTRL = (" -F "    + SYSTICK_CLOCK_SOURCE *
//    SysTick_CTRL_CLKSOURCE_Msk" -F "    + SYSTICK_IRQ_ENABLE   *
//    SysTick_CTRL_TICKINT_Msk" -F "    + SYSTICK_ENABLE       *
//    SysTick_CTRL_ENABLE_Msk" -F "  );" -F "} /* init_systick() */" -F "" -F "" -F
//    "__STATIC_FORCEINLINE void idle(void); // {" -F "  /* Routine to handle idle
//    state (waiting for an event) */" -F "" -F "" -F "//} /* idle() */" -F "" -F ""
//    -F "__STATIC_FORCEINLINE unsigned process(void); // {" -F "  /* Routine to
//    perform main loop operations */" -F "" -F "" -F "//} /* process() */" -F "" -F
//    "#if YES == SYSTICK_IRQ_ENABLE" -F "  #define __SYSTICK_VOLATILE volatile" -F
//    #else -F "  #define __SYSTICK_VOLATILE" -F #endif -F "" -F "#if
//    defined(__GNUC__) && ! defined(__clang__)" -F "  void _close_r(void){} void
//    _close(void){} void _lseek_r(void){} void _lseek(void){} void _read_r(void){}
//    void _read(void){} void _write_r(void){}" -F #endif
////////////////////////////////////////////////////////////////////////////////////////


#ifdef __cplusplus
  }
#endif /* __cplusplus */
#endif /* __MAIN_H__ */

