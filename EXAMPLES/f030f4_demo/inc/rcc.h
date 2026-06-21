#ifndef __RCC_H__
#define __RCC_H__

#ifdef __cplusplus
  extern "C" {
#endif


#define R                              (HCLK >= 12)
#define XMUL                           (HCLK / 4 - 2)     /* Calculate PLL multiplication factor      */
#define A                              ((XMUL >> 0) & 1)  /* LSB or BIT0 of PLL multiplication factor */
#define B                              ((XMUL >> 1) & 1)  /*        BIT1 of PLL multiplication factor */
#define C                              ((XMUL >> 2) & 1)  /*        BIT2 of PLL multiplication factor */
#define D                              ((XMUL >> 3) & 1)  /* MSB or BIT3 of PLL multiplication factor */


__STATIC_FORCEINLINE void configure_flash(void);
__STATIC_FORCEINLINE void wait_for_clock_stable(void);


#define RCC_CFGR (                      \
  0 * RCC_CFGR_SW                       |  /* (3 << 0)     SW[1:0] bits (System clock Switch)                        0x00000003  */\
  0 * RCC_CFGR_SW_0                     |  /* (1 << 0)       0x00000001                                                          */\
  0 * RCC_CFGR_SW_1                     |  /* (2 << 0)       0x00000002                                                          */\
  0 * RCC_CFGR_SW_HSI                   |  /* 0x00000000   HSI selected as system clock                                          */\
  0 * RCC_CFGR_SW_HSE                   |  /* 0x00000001   HSE selected as system clock                                          */\
  R * RCC_CFGR_SW_PLL                   |  /* 0x00000002   PLL selected as system clock                                          */\
  0 * RCC_CFGR_SWS                      |  /* (3 << 2)     SWS[1:0] bits (System Clock Switch Status)                0x0000000C  */\
  0 * RCC_CFGR_SWS_0                    |  /* (1 << 2)       0x00000004                                                          */\
  0 * RCC_CFGR_SWS_1                    |  /* (2 << 2)       0x00000008                                                          */\
  0 * RCC_CFGR_SWS_HSI                  |  /* 0x00000000   HSI oscillator used as system clock                                   */\
  0 * RCC_CFGR_SWS_HSE                  |  /* 0x00000004   HSE oscillator used as system clock                                   */\
  0 * RCC_CFGR_SWS_PLL                  |  /* 0x00000008   PLL used as system clock                                              */\
  0 * RCC_CFGR_HPRE                     |  /* (0xF << 4)   HPRE[3:0] bits (AHB prescaler)                            0x000000F0  */\
  0 * RCC_CFGR_HPRE_0                   |  /* (1 << 4)       0x00000010                                                          */\
  0 * RCC_CFGR_HPRE_1                   |  /* (2 << 4)       0x00000020                                                          */\
  0 * RCC_CFGR_HPRE_2                   |  /* (4 << 4)       0x00000040                                                          */\
  0 * RCC_CFGR_HPRE_3                   |  /* (8 << 4)       0x00000080                                                          */\
  0 * RCC_CFGR_HPRE_DIV1                |  /* 0x00000000   SYSCLK not divided                                                    */\
  0 * RCC_CFGR_HPRE_DIV2                |  /* 0x00000080   SYSCLK divided by 2                                                   */\
  0 * RCC_CFGR_HPRE_DIV4                |  /* 0x00000090   SYSCLK divided by 4                                                   */\
  0 * RCC_CFGR_HPRE_DIV8                |  /* 0x000000A0   SYSCLK divided by 8                                                   */\
  0 * RCC_CFGR_HPRE_DIV16               |  /* 0x000000B0   SYSCLK divided by 16                                                  */\
  0 * RCC_CFGR_HPRE_DIV64               |  /* 0x000000C0   SYSCLK divided by 64                                                  */\
  0 * RCC_CFGR_HPRE_DIV128              |  /* 0x000000D0   SYSCLK divided by 128                                                 */\
  0 * RCC_CFGR_HPRE_DIV256              |  /* 0x000000E0   SYSCLK divided by 256                                                 */\
  0 * RCC_CFGR_HPRE_DIV512              |  /* 0x000000F0   SYSCLK divided by 512                                                 */\
  0 * RCC_CFGR_PPRE                     |  /* (7 << 8)     PRE[2:0] bits (APB prescaler)                             0x00000700  */\
  0 * RCC_CFGR_PPRE_0                   |  /* (1 << 8)       0x00000100                                                          */\
  0 * RCC_CFGR_PPRE_1                   |  /* (2 << 8)       0x00000200                                                          */\
  0 * RCC_CFGR_PPRE_2                   |  /* (4 << 8)       0x00000400                                                          */\
  0 * RCC_CFGR_PPRE_DIV1                |  /* 0x00000000   HCLK not divided                                                      */\
  0 * RCC_CFGR_PPRE_DIV2                |  /* (1 << 10)    HCLK divided by 2                                         0x00000400  */\
  0 * RCC_CFGR_PPRE_DIV4                |  /* (5 << 8)     HCLK divided by 4                                         0x00000500  */\
  0 * RCC_CFGR_PPRE_DIV8                |  /* (3 << 9)     HCLK divided by 8                                         0x00000600  */\
  0 * RCC_CFGR_PPRE_DIV16               |  /* (7 << 8)     HCLK divided by 16                                        0x00000700  */\
  0 * RCC_CFGR_ADCPRE                   |  /* (1 << 14)    ADCPRE bit (ADC prescaler)                                0x00004000  */\
  0 * RCC_CFGR_ADCPRE_DIV2              |  /* 0x00000000   PCLK divided by 2                                                     */\
  0 * RCC_CFGR_ADCPRE_DIV4              |  /* 0x00004000   PCLK divided by 4                                                     */\
  0 * RCC_CFGR_PLLSRC                   |  /* (1 << 16)    PLL entry clock source                                    0x00010000  */\
  0 * RCC_CFGR_PLLSRC_HSI_DIV2          |  /* 0x00000000   HSI clock divided by 2 selected as PLL entry clock source             */\
  0 * RCC_CFGR_PLLSRC_HSE_PREDIV        |  /* 0x00010000   HSE/PREDIV clock selected as PLL entry clock source                   */\
  0 * RCC_CFGR_PLLXTPRE                 |  /* (1 << 17)    HSE divider for PLL entry                                 0x00020000  */\
  0 * RCC_CFGR_PLLXTPRE_HSE_PREDIV_DIV1 |  /* 0x00000000   HSE/PREDIV clock not divided for PLL entry                            */\
  0 * RCC_CFGR_PLLXTPRE_HSE_PREDIV_DIV2 |  /* 0x00020000   HSE/PREDIV clock divided by 2 for PLL entry                           */\
  0 * RCC_CFGR_PLLMUL                   |  /* (0xF << 18)  PLLMUL[3:0] bits (PLL multiplication factor)              0x003C0000  */\
  A * RCC_CFGR_PLLMUL_0                 |  /* (1 << 18)      0x00040000                                                          */\
  B * RCC_CFGR_PLLMUL_1                 |  /* (2 << 18)      0x00080000                                                          */\
  C * RCC_CFGR_PLLMUL_2                 |  /* (4 << 18)      0x00100000                                                          */\
  D * RCC_CFGR_PLLMUL_3                 |  /* (8 << 18)      0x00200000                                                          */\
  0 * RCC_CFGR_PLLMUL2                  |  /* 0x00000000   PLL input clock*2                                                     */\
  0 * RCC_CFGR_PLLMUL3                  |  /* 0x00040000   PLL input clock*3                                                     */\
  0 * RCC_CFGR_PLLMUL4                  |  /* 0x00080000   PLL input clock*4                                                     */\
  0 * RCC_CFGR_PLLMUL5                  |  /* 0x000C0000   PLL input clock*5                                                     */\
  0 * RCC_CFGR_PLLMUL6                  |  /* 0x00100000   PLL input clock*6                                                     */\
  0 * RCC_CFGR_PLLMUL7                  |  /* 0x00140000   PLL input clock*7                                                     */\
  0 * RCC_CFGR_PLLMUL8                  |  /* 0x00180000   PLL input clock*8                                                     */\
  0 * RCC_CFGR_PLLMUL9                  |  /* 0x001C0000   PLL input clock*9                                                     */\
  0 * RCC_CFGR_PLLMUL10                 |  /* 0x00200000   PLL input clock10                                                     */\
  0 * RCC_CFGR_PLLMUL11                 |  /* 0x00240000   PLL input clock*11                                                    */\
  0 * RCC_CFGR_PLLMUL12                 |  /* 0x00280000   PLL input clock*12                                                    */\
  0 * RCC_CFGR_PLLMUL13                 |  /* 0x002C0000   PLL input clock*13                                                    */\
  0 * RCC_CFGR_PLLMUL14                 |  /* 0x00300000   PLL input clock*14                                                    */\
  0 * RCC_CFGR_PLLMUL15                 |  /* 0x00340000   PLL input clock*15                                                    */\
  0 * RCC_CFGR_PLLMUL16                 |  /* 0x00380000   PLL input clock*16                                                    */\
  0 * RCC_CFGR_MCO                      |  /* (0xF << 24)  MCO[3:0] bits (Microcontroller Clock Output)              0x0F000000  */\
  0 * RCC_CFGR_MCO_0                    |  /* (1 << 24)      0x01000000                                                          */\
  0 * RCC_CFGR_MCO_1                    |  /* (2 << 24)      0x02000000                                                          */\
  0 * RCC_CFGR_MCO_2                    |  /* (4 << 24)      0x04000000                                                          */\
  0 * RCC_CFGR_MCO_NOCLOCK              |  /* 0x00000000   No clock                                                              */\
  0 * RCC_CFGR_MCO_HSI14                |  /* 0x01000000   HSI14 clock selected as MCO source                                    */\
  0 * RCC_CFGR_MCO_LSI                  |  /* 0x02000000   LSI clock selected as MCO source                                      */\
  0 * RCC_CFGR_MCO_LSE                  |  /* 0x03000000   LSE clock selected as MCO source                                      */\
  0 * RCC_CFGR_MCO_SYSCLK               |  /* 0x04000000   System clock selected as MCO source                                   */\
  0 * RCC_CFGR_MCO_HSI                  |  /* 0x05000000   HSI clock selected as MCO source                                      */\
  0 * RCC_CFGR_MCO_HSE                  |  /* 0x06000000   HSE clock selected as MCO source                                      */\
  0 * RCC_CFGR_MCO_PLL                  |  /* 0x07000000   PLL clock divided by 2 selected as MCO source                         */\
  0 * RCC_CFGR_MCOPRE                   |  /* (7 << 28)    MCO prescaler                                             0x70000000  */\
  0 * RCC_CFGR_MCOPRE_DIV1              |  /* 0x00000000   MCO is divided by 1                                                   */\
  0 * RCC_CFGR_MCOPRE_DIV2              |  /* 0x10000000   MCO is divided by 2                                                   */\
  0 * RCC_CFGR_MCOPRE_DIV4              |  /* 0x20000000   MCO is divided by 4                                                   */\
  0 * RCC_CFGR_MCOPRE_DIV8              |  /* 0x30000000   MCO is divided by 8                                                   */\
  0 * RCC_CFGR_MCOPRE_DIV16             |  /* 0x40000000   MCO is divided by 16                                                  */\
  0 * RCC_CFGR_MCOPRE_DIV32             |  /* 0x50000000   MCO is divided by 32                                                  */\
  0 * RCC_CFGR_MCOPRE_DIV64             |  /* 0x60000000   MCO is divided by 64                                                  */\
  0 * RCC_CFGR_MCOPRE_DIV128            |  /* 0x70000000   MCO is divided by 128                                                 */\
  0 * RCC_CFGR_PLLNODIV                 |  /* (1 << 31)    PLL is not divided to MCO                                 0x80000000  */\
  0 * RCC_CFGR_MCOSEL                   |  /* (0xF << 24)  0x0F000000                                                            */\
  0 * RCC_CFGR_MCOSEL_0                 |  /* (1 << 24)    0x01000000                                                            */\
  0 * RCC_CFGR_MCOSEL_1                 |  /* (2 << 24)    0x02000000                                                            */\
  0 * RCC_CFGR_MCOSEL_2                 |  /* (4 << 24)    0x04000000                                                            */\
  0 * RCC_CFGR_MCOSEL_NOCLOCK           |  /* 0x00000000   No clock                                                              */\
  0 * RCC_CFGR_MCOSEL_HSI14             |  /* 0x01000000   HSI14 clock selected as MCO source                                    */\
  0 * RCC_CFGR_MCOSEL_LSI               |  /* 0x02000000   LSI clock selected as MCO source                                      */\
  0 * RCC_CFGR_MCOSEL_LSE               |  /* 0x03000000   LSE clock selected as MCO source                                      */\
  0 * RCC_CFGR_MCOSEL_SYSCLK            |  /* 0x04000000   System clock selected as MCO source                                   */\
  0 * RCC_CFGR_MCOSEL_HSI               |  /* 0x05000000   HSI clock selected as MCO source                                      */\
  0 * RCC_CFGR_MCOSEL_HSE               |  /* 0x06000000   HSE clock selected as MCO source                                      */\
  0 * RCC_CFGR_MCOSEL_PLL_DIV2             /* 0x07000000   PLL clock divided by 2 selected as MCO source                         */\
)


#define RCC_CFGR2 (                     \
  0 * RCC_CFGR2_PREDIV                  |  /* (0xF << 0)   PREDIV[3:0] bits                                          0x0000000F  */\
  0 * RCC_CFGR2_PREDIV_0                |  /* (1 << 0)       0x00000001                                                          */\
  0 * RCC_CFGR2_PREDIV_1                |  /* (2 << 0)       0x00000002                                                          */\
  0 * RCC_CFGR2_PREDIV_2                |  /* (4 << 0)       0x00000004                                                          */\
  0 * RCC_CFGR2_PREDIV_3                |  /* (8 << 0)       0x00000008                                                          */\
  0 * RCC_CFGR2_PREDIV_DIV1             |  /* 0x00000000   PREDIV input clock not divided                                        */\
  0 * RCC_CFGR2_PREDIV_DIV2             |  /* 0x00000001   PREDIV input clock divided by 2                                       */\
  0 * RCC_CFGR2_PREDIV_DIV3             |  /* 0x00000002   PREDIV input clock divided by 3                                       */\
  0 * RCC_CFGR2_PREDIV_DIV4             |  /* 0x00000003   PREDIV input clock divided by 4                                       */\
  0 * RCC_CFGR2_PREDIV_DIV5             |  /* 0x00000004   PREDIV input clock divided by 5                                       */\
  0 * RCC_CFGR2_PREDIV_DIV6             |  /* 0x00000005   PREDIV input clock divided by 6                                       */\
  0 * RCC_CFGR2_PREDIV_DIV7             |  /* 0x00000006   PREDIV input clock divided by 7                                       */\
  0 * RCC_CFGR2_PREDIV_DIV8             |  /* 0x00000007   PREDIV input clock divided by 8                                       */\
  0 * RCC_CFGR2_PREDIV_DIV9             |  /* 0x00000008   PREDIV input clock divided by 9                                       */\
  0 * RCC_CFGR2_PREDIV_DIV10            |  /* 0x00000009   PREDIV input clock divided by 10                                      */\
  0 * RCC_CFGR2_PREDIV_DIV11            |  /* 0x0000000A   PREDIV input clock divided by 11                                      */\
  0 * RCC_CFGR2_PREDIV_DIV12            |  /* 0x0000000B   PREDIV input clock divided by 12                                      */\
  0 * RCC_CFGR2_PREDIV_DIV13            |  /* 0x0000000C   PREDIV input clock divided by 13                                      */\
  0 * RCC_CFGR2_PREDIV_DIV14            |  /* 0x0000000D   PREDIV input clock divided by 14                                      */\
  0 * RCC_CFGR2_PREDIV_DIV15            |  /* 0x0000000E   PREDIV input clock divided by 15                                      */\
  0 * RCC_CFGR2_PREDIV_DIV16               /* 0x0000000F   PREDIV input clock divided by 16                                      */\
)


#define RCC_CFGR3 (                     \
  0 * RCC_CFGR3_USART1SW                |  /* (3 << 0)     USART1SW[1:0] bits                                        0x00000003  */\
  0 * RCC_CFGR3_USART1SW_0              |  /* (1 << 0)       0x00000001                                                          */\
  0 * RCC_CFGR3_USART1SW_1              |  /* (2 << 0)       0x00000002                                                          */\
  0 * RCC_CFGR3_USART1SW_PCLK           |  /* 0x00000000   PCLK clock used as USART1 clock source                                */\
  0 * RCC_CFGR3_USART1SW_SYSCLK         |  /* 0x00000001   System clock selected as USART1 clock source                          */\
  0 * RCC_CFGR3_USART1SW_LSE            |  /* 0x00000002   LSE oscillator clock used as USART1 clock source                      */\
  0 * RCC_CFGR3_USART1SW_HSI            |  /* 0x00000003   HSI oscillator clock used as USART1 clock source                      */\
  0 * RCC_CFGR3_I2C1SW                  |  /* (1 << 4)     I2C1SW bits                                               0x00000010  */\
  0 * RCC_CFGR3_I2C1SW_HSI              |  /* 0x00000000   HSI oscillator clock used as I2C1 clock source                        */\
  0 * RCC_CFGR3_I2C1SW_SYSCLK              /* (1 << 4)     System clock selected as I2C1 clock source                0x00000010  */\
)


#define RCC_CSR (                       \
  0 * RCC_CSR_LSION                     |  /* (1 << 0)     Internal Low Speed oscillator enable                      0x00000001  */\
  0 * RCC_CSR_LSIRDY                    |  /* (1 << 1)     Internal Low Speed oscillator Ready                       0x00000002  */\
  0 * RCC_CSR_V18PWRRSTF                |  /* (1 << 23)    V1.8 power domain reset flag                              0x00800000  */\
  0 * RCC_CSR_RMVF                      |  /* (1 << 24)    Remove reset flag                                         0x01000000  */\
  0 * RCC_CSR_OBLRSTF                   |  /* (1 << 25)    OBL reset flag                                            0x02000000  */\
  0 * RCC_CSR_PINRSTF                   |  /* (1 << 26)    PIN reset flag                                            0x04000000  */\
  0 * RCC_CSR_PORRSTF                   |  /* (1 << 27)    POR/PDR reset flag                                        0x08000000  */\
  0 * RCC_CSR_SFTRSTF                   |  /* (1 << 28)    Software Reset flag                                       0x10000000  */\
  0 * RCC_CSR_IWDGRSTF                  |  /* (1 << 29)    Independent Watchdog reset flag                           0x20000000  */\
  0 * RCC_CSR_WWDGRSTF                  |  /* (1 << 30)    Window watchdog reset flag                                0x40000000  */\
  0 * RCC_CSR_LPWRRSTF                  |  /* (1 << 31)    Low-Power reset flag                                      0x80000000  */\
  0 * RCC_CSR_OBL                          /* (1 << 25)    OBL reset flag                                            0x02000000  */\
)


#define RCC_AHBRSTR (                   \
  0 * RCC_AHBRSTR_GPIOARST              |  /* (1 << 17)    GPIOA reset                                               0x00020000  */\
  0 * RCC_AHBRSTR_GPIOBRST              |  /* (1 << 18)    GPIOB reset                                               0x00040000  */\
  0 * RCC_AHBRSTR_GPIOCRST              |  /* (1 << 19)    GPIOC reset                                               0x00080000  */\
  0 * RCC_AHBRSTR_GPIODRST              |  /* (1 << 20)    GPIOD reset                                               0x00100000  */\
  0 * RCC_AHBRSTR_GPIOFRST                 /* (1 << 22)    GPIOF reset                                               0x00400000  */\
)


#define RCC_APB1RSTR (                  \
  0 * RCC_APB1RSTR_TIM3RST              |  /* (1 << 1)     Timer 3 reset                                             0x00000002  */\
  0 * RCC_APB1RSTR_TIM14RST             |  /* (1 << 8)     Timer 14 reset                                            0x00000100  */\
  0 * RCC_APB1RSTR_WWDGRST              |  /* (1 << 11)    Window Watchdog reset                                     0x00000800  */\
  0 * RCC_APB1RSTR_I2C1RST              |  /* (1 << 21)    I2C 1 reset                                               0x00200000  */\
  0 * RCC_APB1RSTR_PWRRST                  /* (1 << 28)    PWR reset                                                 0x10000000  */\
)


#define RCC_APB2RSTR (                  \
  0 * RCC_APB2RSTR_SYSCFGRST            |  /* (1 << 0)     SYSCFG reset                                              0x00000001  */\
  0 * RCC_APB2RSTR_ADCRST               |  /* (1 << 9)     ADC reset                                                 0x00000200  */\
  0 * RCC_APB2RSTR_TIM1RST              |  /* (1 << 11)    TIM1 reset                                                0x00000800  */\
  0 * RCC_APB2RSTR_SPI1RST              |  /* (1 << 12)    SPI1 reset                                                0x00001000  */\
  0 * RCC_APB2RSTR_USART1RST            |  /* (1 << 14)    USART1 reset                                              0x00004000  */\
  0 * RCC_APB2RSTR_TIM16RST             |  /* (1 << 17)    TIM16 reset                                               0x00020000  */\
  0 * RCC_APB2RSTR_TIM17RST             |  /* (1 << 18)    TIM17 reset                                               0x00040000  */\
  0 * RCC_APB2RSTR_DBGMCURST            |  /* (1 << 22)    DBGMCU reset                                              0x00400000  */\
  0 * RCC_APB2RSTR_ADC1RST                 /* (1 << 9)     0x00000200                                                            */\
)


#define RCC_BDCR (                      \
  0 * RCC_BDCR_LSEON                    |  /* (1 << 0)     External Low Speed oscillator enable                      0x00000001  */\
  0 * RCC_BDCR_LSERDY                   |  /* (1 << 1)     External Low Speed oscillator Ready                       0x00000002  */\
  0 * RCC_BDCR_LSEBYP                   |  /* (1 << 2)     External Low Speed oscillator Bypass                      0x00000004  */\
  0 * RCC_BDCR_LSEDRV                   |  /* (3 << 3)     LSEDRV[1:0] bits (LSE Osc. drive capability)              0x00000018  */\
  0 * RCC_BDCR_LSEDRV_0                 |  /* (1 << 3)       0x00000008                                                          */\
  0 * RCC_BDCR_LSEDRV_1                 |  /* (2 << 3)       0x00000010                                                          */\
  0 * RCC_BDCR_RTCSEL                   |  /* (3 << 8)     RTCSEL[1:0] bits (RTC clock source selection)             0x00000300  */\
  0 * RCC_BDCR_RTCSEL_0                 |  /* (1 << 8)       0x00000100                                                          */\
  0 * RCC_BDCR_RTCSEL_1                 |  /* (2 << 8)       0x00000200                                                          */\
  0 * RCC_BDCR_RTCSEL_NOCLOCK           |  /* 0x00000000   No clock                                                              */\
  0 * RCC_BDCR_RTCSEL_LSE               |  /* 0x00000100   LSE oscillator clock used as RTC clock                                */\
  0 * RCC_BDCR_RTCSEL_LSI               |  /* 0x00000200   LSI oscillator clock used as RTC clock                                */\
  0 * RCC_BDCR_RTCSEL_HSE               |  /* 0x00000300   HSE oscillator clock divided by 128 used as RTC clock                 */\
  0 * RCC_BDCR_RTCEN                    |  /* (1 << 15)    RTC clock enable                                          0x00008000  */\
  0 * RCC_BDCR_BDRST                       /* (1 << 16)    Backup domain software reset                              0x00010000  */\
)


#define RCC_CR (       \
  R * RCC_CR_HSION     |  /* (1 << 0)     Internal High Speed clock enable      0x00000001  */\
  0 * RCC_CR_HSIRDY    |  /* (1 << 1)     Internal High Speed clock ready flag  0x00000002  */\
  0 * RCC_CR_HSITRIM   |  /* (0x1F << 3)  Internal High Speed clock trimming    0x000000F8  */\
  0 * RCC_CR_HSITRIM_0 |  /* (0x01 << 3)    0x00000008                                      */\
  0 * RCC_CR_HSITRIM_1 |  /* (0x02 << 3)    0x00000010                                      */\
  0 * RCC_CR_HSITRIM_2 |  /* (0x04 << 3)    0x00000020                                      */\
  0 * RCC_CR_HSITRIM_3 |  /* (0x08 << 3)    0x00000040                                      */\
  R * RCC_CR_HSITRIM_4 |  /* (0x10 << 3)    0x00000080                                      */\
  0 * RCC_CR_HSICAL    |  /* (0xFF << 8)  Internal High Speed clock Calibration 0x0000FF00  */\
  0 * RCC_CR_HSICAL_0  |  /* (0x01 << 8)    0x00000100                                      */\
  0 * RCC_CR_HSICAL_1  |  /* (0x02 << 8)    0x00000200                                      */\
  0 * RCC_CR_HSICAL_2  |  /* (0x04 << 8)    0x00000400                                      */\
  0 * RCC_CR_HSICAL_3  |  /* (0x08 << 8)    0x00000800                                      */\
  0 * RCC_CR_HSICAL_4  |  /* (0x10 << 8)    0x00001000                                      */\
  0 * RCC_CR_HSICAL_5  |  /* (0x20 << 8)    0x00002000                                      */\
  0 * RCC_CR_HSICAL_6  |  /* (0x40 << 8)    0x00004000                                      */\
  0 * RCC_CR_HSICAL_7  |  /* (0x80 << 8)    0x00008000                                      */\
  0 * RCC_CR_HSEON     |  /* (1 << 16)    External High Speed clock enable      0x00010000  */\
  0 * RCC_CR_HSERDY    |  /* (1 << 17)    External High Speed clock ready flag  0x00020000  */\
  0 * RCC_CR_HSEBYP    |  /* (1 << 18)    External High Speed clock Bypass      0x00040000  */\
  0 * RCC_CR_CSSON     |  /* (1 << 19)    Clock Security System enable          0x00080000  */\
  R * RCC_CR_PLLON     |  /* (1 << 24)    PLL enable                            0x01000000  */\
  0 * RCC_CR_PLLRDY       /* (1 << 25)    PLL clock ready flag                  0x02000000  */\
)


#define RCC_CR2 (                       \
  0 * RCC_CR2_HSI14ON                   |  /* (1 << 0)     Internal High Speed 14MHz clock enable                    0x00000001  */\
  0 * RCC_CR2_HSI14RDY                  |  /* (1 << 1)     Internal High Speed 14MHz clock ready flag                0x00000002  */\
  0 * RCC_CR2_HSI14DIS                  |  /* (1 << 2)     Internal High Speed 14MHz clock disable                   0x00000004  */\
  0 * RCC_CR2_HSI14TRIM                 |  /* (0x1F << 3)  Internal High Speed 14MHz clock trimming                  0x000000F8  */\
  0 * RCC_CR2_HSI14CAL                     /* (0xFF << 8)  Internal High Speed 14MHz clock Calibration               0x0000FF00  */\
)


#define RCC_CIR (                       \
  0 * RCC_CIR_LSIRDYF                   |  /* (1 << 0)     LSI Ready Interrupt flag                                  0x00000001  */\
  0 * RCC_CIR_LSERDYF                   |  /* (1 << 1)     LSE Ready Interrupt flag                                  0x00000002  */\
  0 * RCC_CIR_HSIRDYF                   |  /* (1 << 2)     HSI Ready Interrupt flag                                  0x00000004  */\
  0 * RCC_CIR_HSERDYF                   |  /* (1 << 3)     HSE Ready Interrupt flag                                  0x00000008  */\
  0 * RCC_CIR_PLLRDYF                   |  /* (1 << 4)     PLL Ready Interrupt flag                                  0x00000010  */\
  0 * RCC_CIR_HSI14RDYF                 |  /* (1 << 5)     HSI14 Ready Interrupt flag                                0x00000020  */\
  0 * RCC_CIR_CSSF                      |  /* (1 << 7)     Clock Security System Interrupt flag                      0x00000080  */\
  0 * RCC_CIR_LSIRDYIE                  |  /* (1 << 8)     LSI Ready Interrupt Enable                                0x00000100  */\
  0 * RCC_CIR_LSERDYIE                  |  /* (1 << 9)     LSE Ready Interrupt Enable                                0x00000200  */\
  0 * RCC_CIR_HSIRDYIE                  |  /* (1 << 10)    HSI Ready Interrupt Enable                                0x00000400  */\
  0 * RCC_CIR_HSERDYIE                  |  /* (1 << 11)    HSE Ready Interrupt Enable                                0x00000800  */\
  0 * RCC_CIR_PLLRDYIE                  |  /* (1 << 12)    PLL Ready Interrupt Enable                                0x00001000  */\
  0 * RCC_CIR_HSI14RDYIE                |  /* (1 << 13)    HSI14 Ready Interrupt Enable                              0x00002000  */\
  0 * RCC_CIR_LSIRDYC                   |  /* (1 << 16)    LSI Ready Interrupt Clear                                 0x00010000  */\
  0 * RCC_CIR_LSERDYC                   |  /* (1 << 17)    LSE Ready Interrupt Clear                                 0x00020000  */\
  0 * RCC_CIR_HSIRDYC                   |  /* (1 << 18)    HSI Ready Interrupt Clear                                 0x00040000  */\
  0 * RCC_CIR_HSERDYC                   |  /* (1 << 19)    HSE Ready Interrupt Clear                                 0x00080000  */\
  0 * RCC_CIR_PLLRDYC                   |  /* (1 << 20)    PLL Ready Interrupt Clear                                 0x00100000  */\
  0 * RCC_CIR_HSI14RDYC                 |  /* (1 << 21)    HSI14 Ready Interrupt Clear                               0x00200000  */\
  0 * RCC_CIR_CSSC                         /* (1 << 23)    Clock Security System Interrupt Clear                     0x00800000  */\
)

#if !defined(DMA_EN)
  #define DMA_EN 0
#endif

#if !defined(SRAM_EN)
  #define SRAM_EN 0
#endif

#if !defined(FLITF_EN)
  #define FLITF_EN 0
#endif

#if !defined(CRC_EN)
  #define CRC_EN 0
#endif

#if !defined(GPIOA_EN)
  #define GPIOA_EN 0
#endif

#if !defined(GPIOB_EN)
  #define GPIOB_EN 0
#endif

#if !defined(GPIOC_EN)
  #define GPIOC_EN 0
#endif

#if !defined(GPIOD_EN)
  #define GPIOD_EN 0
#endif

#if !defined(GPIOF_EN)
  #define GPIOF_EN 0
#endif

#if !defined(DMA1_EN)
  #define DMA1_EN 0
#endif


#define RCC_AHBENR (                                \
  DMA_EN        * RCC_AHBENR_DMAEN                  |  /* (1 << 0)     DMA1 clock enable                                         0x00000001  */\
  SRAM_EN       * RCC_AHBENR_SRAMEN                 |  /* (1 << 2)     SRAM interface clock enable                               0x00000004  */\
  FLITF_EN      * RCC_AHBENR_FLITFEN                |  /* (1 << 4)     FLITF clock enable                                        0x00000010  */\
  CRC_EN        * RCC_AHBENR_CRCEN                  |  /* (1 << 6)     CRC clock enable                                          0x00000040  */\
  GPIOA_EN      * RCC_AHBENR_GPIOAEN                |  /* (1 << 17)    GPIOA clock enable                                        0x00020000  */\
  GPIOB_EN      * RCC_AHBENR_GPIOBEN                |  /* (1 << 18)    GPIOB clock enable                                        0x00040000  */\
  GPIOC_EN      * RCC_AHBENR_GPIOCEN                |  /* (1 << 19)    GPIOC clock enable                                        0x00080000  */\
  GPIOD_EN      * RCC_AHBENR_GPIODEN                |  /* (1 << 20)    GPIOD clock enable                                        0x00100000  */\
  GPIOF_EN      * RCC_AHBENR_GPIOFEN                |  /* (1 << 22)    GPIOF clock enable                                        0x00400000  */\
  DMA1_EN       * RCC_AHBENR_DMA1EN                    /* (1 << 0)     DMA1 clock enable                                         0x00000001  */\
)

#if !defined(SYSCFGCOMP_EN)
  #define SYSCFGCOMP_EN 0
#endif

#if !defined(ADC_EN)
  #define ADC_EN 0
#endif

#if !defined(TIM1_EN)
  #define TIM1_EN 0
#endif

#if !defined(SPI1_EN)
  #define SPI1_EN 0
#endif

#if !defined(USART1_EN)
  #define USART1_EN 0
#endif

#if !defined(TIM16_EN)
  #define TIM16_EN 0
#endif

#if !defined(TIM17_EN)
  #define TIM17_EN 0
#endif

#if !defined(DBGMCU_EN)
  #define DBGMCU_EN 0
#endif

#if !defined(SYSCFG_EN)
  #define SYSCFG_EN 0
#endif

#if !defined(ADC1_EN)
  #define ADC1_EN 0
#endif


#define RCC_APB2ENR (                               \
  SYSCFGCOMP_EN * RCC_APB2ENR_SYSCFGCOMPEN          |  /* (1 << 0)     SYSCFG and comparator clock enable                        0x00000001  */\
  ADC_EN        * RCC_APB2ENR_ADCEN                 |  /* (1 << 9)     ADC1 clock enable                                         0x00000200  */\
  TIM1_EN       * RCC_APB2ENR_TIM1EN                |  /* (1 << 11)    TIM1 clock enable                                         0x00000800  */\
  SPI1_EN       * RCC_APB2ENR_SPI1EN                |  /* (1 << 12)    SPI1 clock enable                                         0x00001000  */\
  USART1_EN     * RCC_APB2ENR_USART1EN              |  /* (1 << 14)    USART1 clock enable                                       0x00004000  */\
  TIM16_EN      * RCC_APB2ENR_TIM16EN               |  /* (1 << 17)    TIM16 clock enable                                        0x00020000  */\
  TIM17_EN      * RCC_APB2ENR_TIM17EN               |  /* (1 << 18)    TIM17 clock enable                                        0x00040000  */\
  DBGMCU_EN     * RCC_APB2ENR_DBGMCUEN              |  /* (1 << 22)    DBGMCU clock enable                                       0x00400000  */\
  SYSCFG_EN     * RCC_APB2ENR_SYSCFGEN              |  /* (1 << 0)     SYSCFG clock enable                                       0x00000001  */\
  ADC1_EN       * RCC_APB2ENR_ADC1EN                   /* (1 << 9)     ADC1 clock enable                                         0x00000200  */\
)

#if !defined(TIM3_EN)
  #define TIM3_EN 0
#endif

#if !defined(TIM14_EN)
  #define TIM14_EN 0
#endif

#if !defined(WWDG_EN)
  #define WWDG_EN 0
#endif

#if !defined(I2C1_EN)
  #define I2C1_EN 0
#endif

#if !defined(PWR_EN)
  #define PWR_EN 0
#endif


#define RCC_APB1ENR (                               \
  TIM3_EN       * RCC_APB1ENR_TIM3EN                |  /* (1 << 1)     Timer 3 clock enable                                      0x00000002  */\
  TIM14_EN      * RCC_APB1ENR_TIM14EN               |  /* (1 << 8)     Timer 14 clock enable                                     0x00000100  */\
  WWDG_EN       * RCC_APB1ENR_WWDGEN                |  /* (1 << 11)    Window Watchdog clock enable                              0x00000800  */\
  I2C1_EN       * RCC_APB1ENR_I2C1EN                |  /* (1 << 21)    I2C1 clock enable                                         0x00200000  */\
  PWR_EN        * RCC_APB1ENR_PWREN                    /* (1 << 28)    PWR clock enable                                          0x10000000  */\
)


__STATIC_FORCEINLINE void init_rcc(void) {

  /* Perform pre-configuration of the hardware */
  configure_flash();

  #if defined RCC_AHBENR
    #if RCC_AHBENR != 0
      RCC->AHBENR = RCC_AHBENR; /* 0x40021014: RCC AHB peripheral clock register, Address offset: 0x14                               */
    #endif
  #else
    #define RCC_AHBENR 0
  #endif

  #if defined RCC_APB1ENR
    #if RCC_APB1ENR != 0
      RCC->APB1ENR = RCC_APB1ENR; /* 0x4002101C: RCC APB1 peripheral clock enable register, Address offset: 0x1C                       */
    #endif
  #else
    #define RCC_APB1ENR 0
  #endif

  #if defined RCC_APB2ENR
    #if RCC_APB2ENR != 0
      RCC->APB2ENR = RCC_APB2ENR; /* 0x40021018: RCC APB2 peripheral clock enable register, Address offset: 0x18                       */
    #endif
  #else
    #define RCC_APB2ENR 0
  #endif

  #if defined RCC_CFGR
    #if RCC_CFGR != 0
      RCC->CFGR = RCC_CFGR; /* 0x40021004: RCC clock configuration register, Address offset: 0x04                                */
    #endif
  #else
    #define RCC_CFGR 0
  #endif

  #if defined RCC_CFGR2
    #if RCC_CFGR2 != 0
      RCC->CFGR2 = RCC_CFGR2; /* 0x4002102C: RCC clock configuration register 2, Address offset: 0x2C                              */
    #endif
  #else
    #define RCC_CFGR2 0
  #endif

  #if defined RCC_CFGR3
    #if RCC_CFGR3 != 0
      RCC->CFGR3 = RCC_CFGR3; /* 0x40021030: RCC clock configuration register 3, Address offset: 0x30                              */
    #endif
  #else
    #define RCC_CFGR3 0
  #endif

  #if defined RCC_CSR
    #if RCC_CSR != 0
      RCC->CSR = RCC_CSR; /* 0x40021024: RCC clock control & status register, Address offset: 0x24                             */
    #endif
  #else
    #define RCC_CSR 0
  #endif

  #if defined RCC_AHBRSTR
    #if RCC_AHBRSTR != 0
      RCC->AHBRSTR = RCC_AHBRSTR; /* 0x40021028: RCC AHB peripheral reset register, Address offset: 0x28                               */
    #endif
  #else
    #define RCC_AHBRSTR 0
  #endif

  #if defined RCC_APB1RSTR
    #if RCC_APB1RSTR != 0
      RCC->APB1RSTR = RCC_APB1RSTR; /* 0x40021010: RCC APB1 peripheral reset register, Address offset: 0x10                              */
    #endif
  #else
    #define RCC_APB1RSTR 0
  #endif

  #if defined RCC_APB2RSTR
    #if RCC_APB2RSTR != 0
      RCC->APB2RSTR = RCC_APB2RSTR; /* 0x4002100C: RCC APB2 peripheral reset register, Address offset: 0x0C                              */
    #endif
  #else
    #define RCC_APB2RSTR 0
  #endif

  #if defined RCC_BDCR
    #if RCC_BDCR != 0
      RCC->BDCR = RCC_BDCR; /* 0x40021020: RCC Backup domain control register, Address offset: 0x20                              */
    #endif
  #else
    #define RCC_BDCR 0
  #endif

  #if defined RCC_CIR
    #if RCC_CIR != 0
      RCC->CIR = RCC_CIR; /* 0x40021008: RCC clock interrupt register, Address offset: 0x08                                    */
    #endif
  #else
    #define RCC_CIR 0
  #endif

  #if defined RCC_CR
    #if RCC_CR != 0
      RCC->CR = RCC_CR; /* 0x40021000: RCC clock control register, Address offset: 0x00                  */
    #endif
  #else
    #define RCC_CR 0
  #endif

  #if defined RCC_CR2
    #if RCC_CR2 != 0
      RCC->CR2 = RCC_CR2; /* 0x40021034: RCC clock control register 2, Address offset: 0x34                                    */
    #endif
  #else
    #define RCC_CR2 0
  #endif

#if 0
  NVIC_SetPriority(RCC_IRQn, NVIC_EncodePriority(NVIC_GetPriorityGrouping(), 0, 0));
  NVIC_ClearPendingIRQ(RCC_IRQn);
  NVIC_EnableIRQ(RCC_IRQn);
#endif
  
  /* Proceed with additional actions */
  wait_for_clock_stable();

} /* init_rcc() */


__STATIC_FORCEINLINE void configure_flash(void) {
  #if (HCLK > 24)
    /* Configure flash to use 1 wait state and enable prefetch buffer */
    FLASH->ACR = FLASH_ACR_LATENCY | FLASH_ACR_PRFTBE;
  #endif
}

__STATIC_FORCEINLINE void wait_for_clock_stable(void) {
  #if R
    while(RCC_CFGR_SWS_PLL != (RCC->CFGR & RCC_CFGR_SWS_PLL)) {}
  #endif
} /* wait_for_clock_stable() */

#undef A
#undef B
#undef C
#undef D
#undef R


////////////////////////////////////////////////////////////////////////////////////////
//  This code was generated for the stm32f030x6 microcontroller by "stm32cgen" tool.
//                          https://github.com/a5021/stm32codegen                          
//  Arguments used:
//    -l 030f4 -p RCC -m rcc -f init_rcc -D R "(HCLK >= 12)" XMUL "(HCLK / 4 - 2)
//    /* Calculate PLL multiplication factor      */" A "((XMUL >> 0) & 1)  /* LSB or
//    BIT0 of PLL multiplication factor */" B "((XMUL >> 1) & 1)  /*        BIT1 of
//    PLL multiplication factor */" C "((XMUL >> 2) & 1)  /*        BIT2 of PLL
//    multiplication factor */" D "((XMUL >> 3) & 1)  /* MSB or BIT3 of PLL
//    multiplication factor */" --tag-bit R SW_PLL PLLON HSION HSITRIM_4 --tag-bit A
//    PLLMUL_0 --tag-bit B PLLMUL_1 --tag-bit C PLLMUL_2 --tag-bit D PLLMUL_3 --force-
//    inline --pre-init configure_flash --post-init wait_for_clock_stable -F
//    "__STATIC_FORCEINLINE void configure_flash(void) {" -F "  #if (HCLK > 24)" -F "
//    /* Configure flash to use 1 wait state and enable prefetch buffer */" -F "
//    FLASH->ACR = FLASH_ACR_LATENCY | FLASH_ACR_PRFTBE;" -F "  #endif" -F } -F "" -F
//    "__STATIC_FORCEINLINE void wait_for_clock_stable(void) {" -F "  #if R" -F "
//    while(RCC_CFGR_SWS_PLL != (RCC->CFGR & RCC_CFGR_SWS_PLL)) {}" -F "  #endif" -F
//    "} /* wait_for_clock_stable() */" -F "" -F "#undef A" -F "#undef B" -F "#undef
//    C" -F "#undef D" -F "#undef R"
////////////////////////////////////////////////////////////////////////////////////////


#ifdef __cplusplus
  }
#endif /* __cplusplus */
#endif /* __RCC_H__ */

