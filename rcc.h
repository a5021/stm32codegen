#ifndef __RCC_H__
#define __RCC_H__

#ifdef __cplusplus
  extern "C" {
#endif

#define RCC_APB1ENR1 (           \
  0 * RCC_APB1ENR1_TIM2EN        |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_APB1ENR1_TIM3EN        |  /* (1 << 1)      0x00000002                                                                          */\
  0 * RCC_APB1ENR1_TIM4EN        |  /* (1 << 2)      0x00000004                                                                          */\
  0 * RCC_APB1ENR1_TIM5EN        |  /* (1 << 3)      0x00000008                                                                          */\
  0 * RCC_APB1ENR1_TIM6EN        |  /* (1 << 4)      0x00000010                                                                          */\
  0 * RCC_APB1ENR1_TIM7EN        |  /* (1 << 5)      0x00000020                                                                          */\
  0 * RCC_APB1ENR1_LCDEN         |  /* (1 << 9)      0x00000200                                                                          */\
  0 * RCC_APB1ENR1_WWDGEN        |  /* (1 << 11)     0x00000800                                                                          */\
  0 * RCC_APB1ENR1_SPI2EN        |  /* (1 << 14)     0x00004000                                                                          */\
  0 * RCC_APB1ENR1_SPI3EN        |  /* (1 << 15)     0x00008000                                                                          */\
  0 * RCC_APB1ENR1_USART2EN      |  /* (1 << 17)     0x00020000                                                                          */\
  0 * RCC_APB1ENR1_USART3EN      |  /* (1 << 18)     0x00040000                                                                          */\
  0 * RCC_APB1ENR1_UART4EN       |  /* (1 << 19)     0x00080000                                                                          */\
  0 * RCC_APB1ENR1_UART5EN       |  /* (1 << 20)     0x00100000                                                                          */\
  0 * RCC_APB1ENR1_I2C1EN        |  /* (1 << 21)     0x00200000                                                                          */\
  0 * RCC_APB1ENR1_I2C2EN        |  /* (1 << 22)     0x00400000                                                                          */\
  0 * RCC_APB1ENR1_I2C3EN        |  /* (1 << 23)     0x00800000                                                                          */\
  0 * RCC_APB1ENR1_CAN1EN        |  /* (1 << 25)     0x02000000                                                                          */\
  0 * RCC_APB1ENR1_PWREN         |  /* (1 << 28)     0x10000000                                                                          */\
  0 * RCC_APB1ENR1_DAC1EN        |  /* (1 << 29)     0x20000000                                                                          */\
  0 * RCC_APB1ENR1_OPAMPEN       |  /* (1 << 30)     0x40000000                                                                          */\
  0 * RCC_APB1ENR1_LPTIM1EN         /* (1 << 31)     0x80000000                                                                          */\
)

#define RCC_APB1ENR2 (           \
  0 * RCC_APB1ENR2_LPUART1EN     |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_APB1ENR2_SWPMI1EN      |  /* (1 << 2)      0x00000004                                                                          */\
  0 * RCC_APB1ENR2_LPTIM2EN         /* (1 << 5)      0x00000020                                                                          */\
)

#define RCC_APB2ENR (            \
  0 * RCC_APB2ENR_SYSCFGEN       |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_APB2ENR_FWEN           |  /* (1 << 7)      0x00000080                                                                          */\
  0 * RCC_APB2ENR_SDMMC1EN       |  /* (1 << 10)     0x00000400                                                                          */\
  0 * RCC_APB2ENR_TIM1EN         |  /* (1 << 11)     0x00000800                                                                          */\
  0 * RCC_APB2ENR_SPI1EN         |  /* (1 << 12)     0x00001000                                                                          */\
  0 * RCC_APB2ENR_TIM8EN         |  /* (1 << 13)     0x00002000                                                                          */\
  0 * RCC_APB2ENR_USART1EN       |  /* (1 << 14)     0x00004000                                                                          */\
  0 * RCC_APB2ENR_TIM15EN        |  /* (1 << 16)     0x00010000                                                                          */\
  0 * RCC_APB2ENR_TIM16EN        |  /* (1 << 17)     0x00020000                                                                          */\
  0 * RCC_APB2ENR_TIM17EN        |  /* (1 << 18)     0x00040000                                                                          */\
  0 * RCC_APB2ENR_SAI1EN         |  /* (1 << 21)     0x00200000                                                                          */\
  0 * RCC_APB2ENR_SAI2EN         |  /* (1 << 22)     0x00400000                                                                          */\
  0 * RCC_APB2ENR_DFSDM1EN          /* (1 << 24)     0x01000000                                                                          */\
)

#define RCC_CFGR (          \
  0 * RCC_CFGR_SW           |  /* (3 << 0)      SW[1:0] bits (System clock Switch)                                      0x00000003  */\
  0 * RCC_CFGR_SW_0         |  /* (1 << 0)        0x00000001                                                                        */\
  0 * RCC_CFGR_SW_1         |  /* (2 << 0)        0x00000002                                                                        */\
  0 * RCC_CFGR_SW_MSI       |  /* 0x00000000    MSI oscillator selection as system clock                                            */\
  0 * RCC_CFGR_SW_HSI       |  /* 0x00000001    HSI16 oscillator selection as system clock                                          */\
  0 * RCC_CFGR_SW_HSE       |  /* 0x00000002    HSE oscillator selection as system clock                                            */\
  0 * RCC_CFGR_SW_PLL       |  /* 0x00000003    PLL selection as system clock                                                       */\
  0 * RCC_CFGR_SWS          |  /* (3 << 2)      SWS[1:0] bits (System Clock Switch Status)                              0x0000000C  */\
  0 * RCC_CFGR_SWS_0        |  /* (1 << 2)        0x00000004                                                                        */\
  0 * RCC_CFGR_SWS_1        |  /* (2 << 2)        0x00000008                                                                        */\
  0 * RCC_CFGR_SWS_MSI      |  /* 0x00000000    MSI oscillator used as system clock                                                 */\
  0 * RCC_CFGR_SWS_HSI      |  /* 0x00000004    HSI16 oscillator used as system clock                                               */\
  0 * RCC_CFGR_SWS_HSE      |  /* 0x00000008    HSE oscillator used as system clock                                                 */\
  0 * RCC_CFGR_SWS_PLL      |  /* 0x0000000C    PLL used as system clock                                                            */\
  0 * RCC_CFGR_HPRE         |  /* (0xF << 4)    HPRE[3:0] bits (AHB prescaler)                                          0x000000F0  */\
  0 * RCC_CFGR_HPRE_0       |  /* (1 << 4)        0x00000010                                                                        */\
  0 * RCC_CFGR_HPRE_1       |  /* (2 << 4)        0x00000020                                                                        */\
  0 * RCC_CFGR_HPRE_2       |  /* (4 << 4)        0x00000040                                                                        */\
  0 * RCC_CFGR_HPRE_3       |  /* (8 << 4)        0x00000080                                                                        */\
  0 * RCC_CFGR_HPRE_DIV1    |  /* 0x00000000    SYSCLK not divided                                                                  */\
  0 * RCC_CFGR_HPRE_DIV2    |  /* 0x00000080    SYSCLK divided by 2                                                                 */\
  0 * RCC_CFGR_HPRE_DIV4    |  /* 0x00000090    SYSCLK divided by 4                                                                 */\
  0 * RCC_CFGR_HPRE_DIV8    |  /* 0x000000A0    SYSCLK divided by 8                                                                 */\
  0 * RCC_CFGR_HPRE_DIV16   |  /* 0x000000B0    SYSCLK divided by 16                                                                */\
  0 * RCC_CFGR_HPRE_DIV64   |  /* 0x000000C0    SYSCLK divided by 64                                                                */\
  0 * RCC_CFGR_HPRE_DIV128  |  /* 0x000000D0    SYSCLK divided by 128                                                               */\
  0 * RCC_CFGR_HPRE_DIV256  |  /* 0x000000E0    SYSCLK divided by 256                                                               */\
  0 * RCC_CFGR_HPRE_DIV512  |  /* 0x000000F0    SYSCLK divided by 512                                                               */\
  0 * RCC_CFGR_PPRE1        |  /* (7 << 8)      PRE1[2:0] bits (APB2 prescaler)                                         0x00000700  */\
  0 * RCC_CFGR_PPRE1_0      |  /* (1 << 8)        0x00000100                                                                        */\
  0 * RCC_CFGR_PPRE1_1      |  /* (2 << 8)        0x00000200                                                                        */\
  0 * RCC_CFGR_PPRE1_2      |  /* (4 << 8)        0x00000400                                                                        */\
  0 * RCC_CFGR_PPRE1_DIV1   |  /* 0x00000000    HCLK not divided                                                                    */\
  0 * RCC_CFGR_PPRE1_DIV2   |  /* 0x00000400    HCLK divided by 2                                                                   */\
  0 * RCC_CFGR_PPRE1_DIV4   |  /* 0x00000500    HCLK divided by 4                                                                   */\
  0 * RCC_CFGR_PPRE1_DIV8   |  /* 0x00000600    HCLK divided by 8                                                                   */\
  0 * RCC_CFGR_PPRE1_DIV16  |  /* 0x00000700    HCLK divided by 16                                                                  */\
  0 * RCC_CFGR_PPRE2        |  /* (7 << 11)     PRE2[2:0] bits (APB2 prescaler)                                         0x00003800  */\
  0 * RCC_CFGR_PPRE2_0      |  /* (1 << 11)       0x00000800                                                                        */\
  0 * RCC_CFGR_PPRE2_1      |  /* (2 << 11)       0x00001000                                                                        */\
  0 * RCC_CFGR_PPRE2_2      |  /* (4 << 11)       0x00002000                                                                        */\
  0 * RCC_CFGR_PPRE2_DIV1   |  /* 0x00000000    HCLK not divided                                                                    */\
  0 * RCC_CFGR_PPRE2_DIV2   |  /* 0x00002000    HCLK divided by 2                                                                   */\
  0 * RCC_CFGR_PPRE2_DIV4   |  /* 0x00002800    HCLK divided by 4                                                                   */\
  0 * RCC_CFGR_PPRE2_DIV8   |  /* 0x00003000    HCLK divided by 8                                                                   */\
  0 * RCC_CFGR_PPRE2_DIV16  |  /* 0x00003800    HCLK divided by 16                                                                  */\
  0 * RCC_CFGR_STOPWUCK     |  /* (1 << 15)     Wake Up from stop and CSS backup clock selection                        0x00008000  */\
  0 * RCC_CFGR_MCOSEL       |  /* (7 << 24)     MCOSEL [2:0] bits (Clock output selection)                              0x07000000  */\
  0 * RCC_CFGR_MCOSEL_0     |  /* (1 << 24)       0x01000000                                                                        */\
  0 * RCC_CFGR_MCOSEL_1     |  /* (2 << 24)       0x02000000                                                                        */\
  0 * RCC_CFGR_MCOSEL_2     |  /* (4 << 24)       0x04000000                                                                        */\
  0 * RCC_CFGR_MCOPRE       |  /* (7 << 28)     MCO prescaler                                                           0x70000000  */\
  0 * RCC_CFGR_MCOPRE_0     |  /* (1 << 28)       0x10000000                                                                        */\
  0 * RCC_CFGR_MCOPRE_1     |  /* (2 << 28)       0x20000000                                                                        */\
  0 * RCC_CFGR_MCOPRE_2     |  /* (4 << 28)       0x40000000                                                                        */\
  0 * RCC_CFGR_MCOPRE_DIV1  |  /* 0x00000000    MCO is divided by 1                                                                 */\
  0 * RCC_CFGR_MCOPRE_DIV2  |  /* 0x10000000    MCO is divided by 2                                                                 */\
  0 * RCC_CFGR_MCOPRE_DIV4  |  /* 0x20000000    MCO is divided by 4                                                                 */\
  0 * RCC_CFGR_MCOPRE_DIV8  |  /* 0x30000000    MCO is divided by 8                                                                 */\
  0 * RCC_CFGR_MCOPRE_DIV16 |  /* 0x40000000    MCO is divided by 16                                                                */\
  0 * RCC_CFGR_MCO_PRE      |  /* (7 << 28)     0x70000000                                                                          */\
  0 * RCC_CFGR_MCO_PRE_1    |  /* 0x00000000    MCO is divided by 1                                                                 */\
  0 * RCC_CFGR_MCO_PRE_2    |  /* 0x10000000    MCO is divided by 2                                                                 */\
  0 * RCC_CFGR_MCO_PRE_4    |  /* 0x20000000    MCO is divided by 4                                                                 */\
  0 * RCC_CFGR_MCO_PRE_8    |  /* 0x30000000    MCO is divided by 8                                                                 */\
  0 * RCC_CFGR_MCO_PRE_16      /* 0x40000000    MCO is divided by 16                                                                */\
)

#define RCC_CR (         \
  0 * RCC_CR_MSION       |  /* (1 << 0)    Internal Multi Speed oscillator (MSI) clock enable                      0x00000001  */\
  0 * RCC_CR_MSIRDY      |  /* (1 << 1)    Internal Multi Speed oscillator (MSI) clock ready flag                  0x00000002  */\
  0 * RCC_CR_MSIPLLEN    |  /* (1 << 2)    Internal Multi Speed oscillator (MSI) PLL enable                        0x00000004  */\
  0 * RCC_CR_MSIRGSEL    |  /* (1 << 3)    Internal Multi Speed oscillator (MSI) range selection                   0x00000008  */\
  0 * RCC_CR_MSIRANGE    |  /* (0xF << 4)  Internal Multi Speed oscillator (MSI) clock Range                       0x000000F0  */\
  0 * RCC_CR_MSIRANGE_0  |  /* (0 << 4)      0x00000000                                                                        */\
  0 * RCC_CR_MSIRANGE_1  |  /* (1 << 4)      0x00000010                                                                        */\
  0 * RCC_CR_MSIRANGE_2  |  /* (2 << 4)      0x00000020                                                                        */\
  0 * RCC_CR_MSIRANGE_3  |  /* (3 << 4)      0x00000030                                                                        */\
  0 * RCC_CR_MSIRANGE_4  |  /* (4 << 4)      0x00000040                                                                        */\
  0 * RCC_CR_MSIRANGE_5  |  /* (5 << 4)      0x00000050                                                                        */\
  0 * RCC_CR_MSIRANGE_6  |  /* (6 << 4)      0x00000060                                                                        */\
  0 * RCC_CR_MSIRANGE_7  |  /* (7 << 4)      0x00000070                                                                        */\
  0 * RCC_CR_MSIRANGE_8  |  /* (8 << 4)      0x00000080                                                                        */\
  0 * RCC_CR_MSIRANGE_9  |  /* (9 << 4)      0x00000090                                                                        */\
  0 * RCC_CR_MSIRANGE_10 |  /* (0xA << 4)  0x000000A0                                                                          */\
  0 * RCC_CR_MSIRANGE_11 |  /* (0xB << 4)  0x000000B0                                                                          */\
  0 * RCC_CR_HSION       |  /* (1 << 8)    Internal High Speed oscillator (HSI16) clock enable                     0x00000100  */\
  0 * RCC_CR_HSIKERON    |  /* (1 << 9)    Internal High Speed oscillator (HSI16) clock enable for some IPs Kernel 0x00000200  */\
  0 * RCC_CR_HSIRDY      |  /* (1 << 10)   Internal High Speed oscillator (HSI16) clock ready flag                 0x00000400  */\
  0 * RCC_CR_HSIASFS     |  /* (1 << 11)   HSI16 Automatic Start from Stop                                         0x00000800  */\
  0 * RCC_CR_HSEON       |  /* (1 << 16)   External High Speed oscillator (HSE) clock enable                       0x00010000  */\
  0 * RCC_CR_HSERDY      |  /* (1 << 17)   External High Speed oscillator (HSE) clock ready                        0x00020000  */\
  0 * RCC_CR_HSEBYP      |  /* (1 << 18)   External High Speed oscillator (HSE) clock bypass                       0x00040000  */\
  0 * RCC_CR_CSSON       |  /* (1 << 19)   HSE Clock Security System enable                                        0x00080000  */\
  0 * RCC_CR_PLLON       |  /* (1 << 24)   System PLL clock enable                                                 0x01000000  */\
  0 * RCC_CR_PLLRDY      |  /* (1 << 25)   System PLL clock ready                                                  0x02000000  */\
  0 * RCC_CR_PLLSAI1ON   |  /* (1 << 26)   SAI1 PLL enable                                                         0x04000000  */\
  0 * RCC_CR_PLLSAI1RDY  |  /* (1 << 27)   SAI1 PLL ready                                                          0x08000000  */\
  0 * RCC_CR_PLLSAI2ON   |  /* (1 << 28)   SAI2 PLL enable                                                         0x10000000  */\
  0 * RCC_CR_PLLSAI2RDY     /* (1 << 29)   SAI2 PLL ready                                                          0x20000000  */\
)

#define RCC_CSR (                \
  0 * RCC_CSR_LSION              |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_CSR_LSIRDY             |  /* (1 << 1)      0x00000002                                                                          */\
  0 * RCC_CSR_MSISRANGE          |  /* (0xF << 8)    0x00000F00                                                                          */\
  0 * RCC_CSR_MSISRANGE_1        |  /* (4 << 8)        0x00000400                                                                        */\
  0 * RCC_CSR_MSISRANGE_2        |  /* (5 << 8)        0x00000500                                                                        */\
  0 * RCC_CSR_MSISRANGE_4        |  /* (6 << 8)        0x00000600                                                                        */\
  0 * RCC_CSR_MSISRANGE_8        |  /* (7 << 8)        0x00000700                                                                        */\
  0 * RCC_CSR_RMVF               |  /* (1 << 23)     0x00800000                                                                          */\
  0 * RCC_CSR_FWRSTF             |  /* (1 << 24)     0x01000000                                                                          */\
  0 * RCC_CSR_OBLRSTF            |  /* (1 << 25)     0x02000000                                                                          */\
  0 * RCC_CSR_PINRSTF            |  /* (1 << 26)     0x04000000                                                                          */\
  0 * RCC_CSR_BORRSTF            |  /* (1 << 27)     0x08000000                                                                          */\
  0 * RCC_CSR_SFTRSTF            |  /* (1 << 28)     0x10000000                                                                          */\
  0 * RCC_CSR_IWDGRSTF           |  /* (1 << 29)     0x20000000                                                                          */\
  0 * RCC_CSR_WWDGRSTF           |  /* (1 << 30)     0x40000000                                                                          */\
  0 * RCC_CSR_LPWRRSTF              /* (1 << 31)     0x80000000                                                                          */\
)

#define RCC_AHB1ENR (            \
  0 * RCC_AHB1ENR_DMA1EN         |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_AHB1ENR_DMA2EN         |  /* (1 << 1)      0x00000002                                                                          */\
  0 * RCC_AHB1ENR_FLASHEN        |  /* (1 << 8)      0x00000100                                                                          */\
  0 * RCC_AHB1ENR_CRCEN          |  /* (1 << 12)     0x00001000                                                                          */\
  0 * RCC_AHB1ENR_TSCEN             /* (1 << 16)     0x00010000                                                                          */\
)

#define RCC_AHB1RSTR (           \
  0 * RCC_AHB1RSTR_DMA1RST       |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_AHB1RSTR_DMA2RST       |  /* (1 << 1)      0x00000002                                                                          */\
  0 * RCC_AHB1RSTR_FLASHRST      |  /* (1 << 8)      0x00000100                                                                          */\
  0 * RCC_AHB1RSTR_CRCRST        |  /* (1 << 12)     0x00001000                                                                          */\
  0 * RCC_AHB1RSTR_TSCRST           /* (1 << 16)     0x00010000                                                                          */\
)

#define RCC_AHB1SMENR (          \
  0 * RCC_AHB1SMENR_DMA1SMEN     |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_AHB1SMENR_DMA2SMEN     |  /* (1 << 1)      0x00000002                                                                          */\
  0 * RCC_AHB1SMENR_FLASHSMEN    |  /* (1 << 8)      0x00000100                                                                          */\
  0 * RCC_AHB1SMENR_SRAM1SMEN    |  /* (1 << 9)      0x00000200                                                                          */\
  0 * RCC_AHB1SMENR_CRCSMEN      |  /* (1 << 12)     0x00001000                                                                          */\
  0 * RCC_AHB1SMENR_TSCSMEN         /* (1 << 16)     0x00010000                                                                          */\
)

#define RCC_AHB2ENR (            \
  0 * RCC_AHB2ENR_GPIOAEN        |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_AHB2ENR_GPIOBEN        |  /* (1 << 1)      0x00000002                                                                          */\
  0 * RCC_AHB2ENR_GPIOCEN        |  /* (1 << 2)      0x00000004                                                                          */\
  0 * RCC_AHB2ENR_GPIODEN        |  /* (1 << 3)      0x00000008                                                                          */\
  0 * RCC_AHB2ENR_GPIOEEN        |  /* (1 << 4)      0x00000010                                                                          */\
  0 * RCC_AHB2ENR_GPIOFEN        |  /* (1 << 5)      0x00000020                                                                          */\
  0 * RCC_AHB2ENR_GPIOGEN        |  /* (1 << 6)      0x00000040                                                                          */\
  0 * RCC_AHB2ENR_GPIOHEN        |  /* (1 << 7)      0x00000080                                                                          */\
  0 * RCC_AHB2ENR_OTGFSEN        |  /* (1 << 12)     0x00001000                                                                          */\
  0 * RCC_AHB2ENR_ADCEN          |  /* (1 << 13)     0x00002000                                                                          */\
  0 * RCC_AHB2ENR_RNGEN             /* (1 << 18)     0x00040000                                                                          */\
)

#define RCC_AHB2RSTR (           \
  0 * RCC_AHB2RSTR_GPIOARST      |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_AHB2RSTR_GPIOBRST      |  /* (1 << 1)      0x00000002                                                                          */\
  0 * RCC_AHB2RSTR_GPIOCRST      |  /* (1 << 2)      0x00000004                                                                          */\
  0 * RCC_AHB2RSTR_GPIODRST      |  /* (1 << 3)      0x00000008                                                                          */\
  0 * RCC_AHB2RSTR_GPIOERST      |  /* (1 << 4)      0x00000010                                                                          */\
  0 * RCC_AHB2RSTR_GPIOFRST      |  /* (1 << 5)      0x00000020                                                                          */\
  0 * RCC_AHB2RSTR_GPIOGRST      |  /* (1 << 6)      0x00000040                                                                          */\
  0 * RCC_AHB2RSTR_GPIOHRST      |  /* (1 << 7)      0x00000080                                                                          */\
  0 * RCC_AHB2RSTR_OTGFSRST      |  /* (1 << 12)     0x00001000                                                                          */\
  0 * RCC_AHB2RSTR_ADCRST        |  /* (1 << 13)     0x00002000                                                                          */\
  0 * RCC_AHB2RSTR_RNGRST           /* (1 << 18)     0x00040000                                                                          */\
)

#define RCC_AHB2SMENR (          \
  0 * RCC_AHB2SMENR_GPIOASMEN    |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_AHB2SMENR_GPIOBSMEN    |  /* (1 << 1)      0x00000002                                                                          */\
  0 * RCC_AHB2SMENR_GPIOCSMEN    |  /* (1 << 2)      0x00000004                                                                          */\
  0 * RCC_AHB2SMENR_GPIODSMEN    |  /* (1 << 3)      0x00000008                                                                          */\
  0 * RCC_AHB2SMENR_GPIOESMEN    |  /* (1 << 4)      0x00000010                                                                          */\
  0 * RCC_AHB2SMENR_GPIOFSMEN    |  /* (1 << 5)      0x00000020                                                                          */\
  0 * RCC_AHB2SMENR_GPIOGSMEN    |  /* (1 << 6)      0x00000040                                                                          */\
  0 * RCC_AHB2SMENR_GPIOHSMEN    |  /* (1 << 7)      0x00000080                                                                          */\
  0 * RCC_AHB2SMENR_SRAM2SMEN    |  /* (1 << 9)      0x00000200                                                                          */\
  0 * RCC_AHB2SMENR_OTGFSSMEN    |  /* (1 << 12)     0x00001000                                                                          */\
  0 * RCC_AHB2SMENR_ADCSMEN      |  /* (1 << 13)     0x00002000                                                                          */\
  0 * RCC_AHB2SMENR_RNGSMEN         /* (1 << 18)     0x00040000                                                                          */\
)

#define RCC_AHB3ENR (            \
  0 * RCC_AHB3ENR_FMCEN          |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_AHB3ENR_QSPIEN            /* (1 << 8)      0x00000100                                                                          */\
)

#define RCC_AHB3RSTR (           \
  0 * RCC_AHB3RSTR_FMCRST        |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_AHB3RSTR_QSPIRST          /* (1 << 8)      0x00000100                                                                          */\
)

#define RCC_AHB3SMENR (          \
  0 * RCC_AHB3SMENR_FMCSMEN      |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_AHB3SMENR_QSPISMEN        /* (1 << 8)      0x00000100                                                                          */\
)

#define RCC_APB1SMENR1 (         \
  0 * RCC_APB1SMENR1_TIM2SMEN    |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_APB1SMENR1_TIM3SMEN    |  /* (1 << 1)      0x00000002                                                                          */\
  0 * RCC_APB1SMENR1_TIM4SMEN    |  /* (1 << 2)      0x00000004                                                                          */\
  0 * RCC_APB1SMENR1_TIM5SMEN    |  /* (1 << 3)      0x00000008                                                                          */\
  0 * RCC_APB1SMENR1_TIM6SMEN    |  /* (1 << 4)      0x00000010                                                                          */\
  0 * RCC_APB1SMENR1_TIM7SMEN    |  /* (1 << 5)      0x00000020                                                                          */\
  0 * RCC_APB1SMENR1_LCDSMEN     |  /* (1 << 9)      0x00000200                                                                          */\
  0 * RCC_APB1SMENR1_WWDGSMEN    |  /* (1 << 11)     0x00000800                                                                          */\
  0 * RCC_APB1SMENR1_SPI2SMEN    |  /* (1 << 14)     0x00004000                                                                          */\
  0 * RCC_APB1SMENR1_SPI3SMEN    |  /* (1 << 15)     0x00008000                                                                          */\
  0 * RCC_APB1SMENR1_USART2SMEN  |  /* (1 << 17)     0x00020000                                                                          */\
  0 * RCC_APB1SMENR1_USART3SMEN  |  /* (1 << 18)     0x00040000                                                                          */\
  0 * RCC_APB1SMENR1_UART4SMEN   |  /* (1 << 19)     0x00080000                                                                          */\
  0 * RCC_APB1SMENR1_UART5SMEN   |  /* (1 << 20)     0x00100000                                                                          */\
  0 * RCC_APB1SMENR1_I2C1SMEN    |  /* (1 << 21)     0x00200000                                                                          */\
  0 * RCC_APB1SMENR1_I2C2SMEN    |  /* (1 << 22)     0x00400000                                                                          */\
  0 * RCC_APB1SMENR1_I2C3SMEN    |  /* (1 << 23)     0x00800000                                                                          */\
  0 * RCC_APB1SMENR1_CAN1SMEN    |  /* (1 << 25)     0x02000000                                                                          */\
  0 * RCC_APB1SMENR1_PWRSMEN     |  /* (1 << 28)     0x10000000                                                                          */\
  0 * RCC_APB1SMENR1_DAC1SMEN    |  /* (1 << 29)     0x20000000                                                                          */\
  0 * RCC_APB1SMENR1_OPAMPSMEN   |  /* (1 << 30)     0x40000000                                                                          */\
  0 * RCC_APB1SMENR1_LPTIM1SMEN     /* (1 << 31)     0x80000000                                                                          */\
)

#define RCC_APB1SMENR2 (         \
  0 * RCC_APB1SMENR2_LPUART1SMEN |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_APB1SMENR2_SWPMI1SMEN  |  /* (1 << 2)      0x00000004                                                                          */\
  0 * RCC_APB1SMENR2_LPTIM2SMEN     /* (1 << 5)      0x00000020                                                                          */\
)

#define RCC_APB2SMENR (          \
  0 * RCC_APB2SMENR_SYSCFGSMEN   |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_APB2SMENR_SDMMC1SMEN   |  /* (1 << 10)     0x00000400                                                                          */\
  0 * RCC_APB2SMENR_TIM1SMEN     |  /* (1 << 11)     0x00000800                                                                          */\
  0 * RCC_APB2SMENR_SPI1SMEN     |  /* (1 << 12)     0x00001000                                                                          */\
  0 * RCC_APB2SMENR_TIM8SMEN     |  /* (1 << 13)     0x00002000                                                                          */\
  0 * RCC_APB2SMENR_USART1SMEN   |  /* (1 << 14)     0x00004000                                                                          */\
  0 * RCC_APB2SMENR_TIM15SMEN    |  /* (1 << 16)     0x00010000                                                                          */\
  0 * RCC_APB2SMENR_TIM16SMEN    |  /* (1 << 17)     0x00020000                                                                          */\
  0 * RCC_APB2SMENR_TIM17SMEN    |  /* (1 << 18)     0x00040000                                                                          */\
  0 * RCC_APB2SMENR_SAI1SMEN     |  /* (1 << 21)     0x00200000                                                                          */\
  0 * RCC_APB2SMENR_SAI2SMEN     |  /* (1 << 22)     0x00400000                                                                          */\
  0 * RCC_APB2SMENR_DFSDM1SMEN      /* (1 << 24)     0x01000000                                                                          */\
)

#define RCC_BDCR (               \
  0 * RCC_BDCR_LSEON             |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_BDCR_LSERDY            |  /* (1 << 1)      0x00000002                                                                          */\
  0 * RCC_BDCR_LSEBYP            |  /* (1 << 2)      0x00000004                                                                          */\
  0 * RCC_BDCR_LSEDRV            |  /* (3 << 3)      0x00000018                                                                          */\
  0 * RCC_BDCR_LSEDRV_0          |  /* (1 << 3)        0x00000008                                                                        */\
  0 * RCC_BDCR_LSEDRV_1          |  /* (2 << 3)        0x00000010                                                                        */\
  0 * RCC_BDCR_LSECSSON          |  /* (1 << 5)      0x00000020                                                                          */\
  0 * RCC_BDCR_LSECSSD           |  /* (1 << 6)      0x00000040                                                                          */\
  0 * RCC_BDCR_RTCSEL            |  /* (3 << 8)      0x00000300                                                                          */\
  0 * RCC_BDCR_RTCSEL_0          |  /* (1 << 8)        0x00000100                                                                        */\
  0 * RCC_BDCR_RTCSEL_1          |  /* (2 << 8)        0x00000200                                                                        */\
  0 * RCC_BDCR_RTCEN             |  /* (1 << 15)     0x00008000                                                                          */\
  0 * RCC_BDCR_BDRST             |  /* (1 << 16)     0x00010000                                                                          */\
  0 * RCC_BDCR_LSCOEN            |  /* (1 << 24)     0x01000000                                                                          */\
  0 * RCC_BDCR_LSCOSEL              /* (1 << 25)     0x02000000                                                                          */\
)

#define RCC_CCIPR (              \
  0 * RCC_CCIPR_USART1SEL        |  /* (3 << 0)      0x00000003                                                                          */\
  0 * RCC_CCIPR_USART1SEL_0      |  /* (1 << 0)        0x00000001                                                                        */\
  0 * RCC_CCIPR_USART1SEL_1      |  /* (2 << 0)        0x00000002                                                                        */\
  0 * RCC_CCIPR_USART2SEL        |  /* (3 << 2)      0x0000000C                                                                          */\
  0 * RCC_CCIPR_USART2SEL_0      |  /* (1 << 2)        0x00000004                                                                        */\
  0 * RCC_CCIPR_USART2SEL_1      |  /* (2 << 2)        0x00000008                                                                        */\
  0 * RCC_CCIPR_USART3SEL        |  /* (3 << 4)      0x00000030                                                                          */\
  0 * RCC_CCIPR_USART3SEL_0      |  /* (1 << 4)        0x00000010                                                                        */\
  0 * RCC_CCIPR_USART3SEL_1      |  /* (2 << 4)        0x00000020                                                                        */\
  0 * RCC_CCIPR_UART4SEL         |  /* (3 << 6)      0x000000C0                                                                          */\
  0 * RCC_CCIPR_UART4SEL_0       |  /* (1 << 6)        0x00000040                                                                        */\
  0 * RCC_CCIPR_UART4SEL_1       |  /* (2 << 6)        0x00000080                                                                        */\
  0 * RCC_CCIPR_UART5SEL         |  /* (3 << 8)      0x00000300                                                                          */\
  0 * RCC_CCIPR_UART5SEL_0       |  /* (1 << 8)        0x00000100                                                                        */\
  0 * RCC_CCIPR_UART5SEL_1       |  /* (2 << 8)        0x00000200                                                                        */\
  0 * RCC_CCIPR_LPUART1SEL       |  /* (3 << 10)     0x00000C00                                                                          */\
  0 * RCC_CCIPR_LPUART1SEL_0     |  /* (1 << 10)       0x00000400                                                                        */\
  0 * RCC_CCIPR_LPUART1SEL_1     |  /* (2 << 10)       0x00000800                                                                        */\
  0 * RCC_CCIPR_I2C1SEL          |  /* (3 << 12)     0x00003000                                                                          */\
  0 * RCC_CCIPR_I2C1SEL_0        |  /* (1 << 12)       0x00001000                                                                        */\
  0 * RCC_CCIPR_I2C1SEL_1        |  /* (2 << 12)       0x00002000                                                                        */\
  0 * RCC_CCIPR_I2C2SEL          |  /* (3 << 14)     0x0000C000                                                                          */\
  0 * RCC_CCIPR_I2C2SEL_0        |  /* (1 << 14)       0x00004000                                                                        */\
  0 * RCC_CCIPR_I2C2SEL_1        |  /* (2 << 14)       0x00008000                                                                        */\
  0 * RCC_CCIPR_I2C3SEL          |  /* (3 << 16)     0x00030000                                                                          */\
  0 * RCC_CCIPR_I2C3SEL_0        |  /* (1 << 16)       0x00010000                                                                        */\
  0 * RCC_CCIPR_I2C3SEL_1        |  /* (2 << 16)       0x00020000                                                                        */\
  0 * RCC_CCIPR_LPTIM1SEL        |  /* (3 << 18)     0x000C0000                                                                          */\
  0 * RCC_CCIPR_LPTIM1SEL_0      |  /* (1 << 18)       0x00040000                                                                        */\
  0 * RCC_CCIPR_LPTIM1SEL_1      |  /* (2 << 18)       0x00080000                                                                        */\
  0 * RCC_CCIPR_LPTIM2SEL        |  /* (3 << 20)     0x00300000                                                                          */\
  0 * RCC_CCIPR_LPTIM2SEL_0      |  /* (1 << 20)       0x00100000                                                                        */\
  0 * RCC_CCIPR_LPTIM2SEL_1      |  /* (2 << 20)       0x00200000                                                                        */\
  0 * RCC_CCIPR_SAI1SEL          |  /* (3 << 22)     0x00C00000                                                                          */\
  0 * RCC_CCIPR_SAI1SEL_0        |  /* (1 << 22)       0x00400000                                                                        */\
  0 * RCC_CCIPR_SAI1SEL_1        |  /* (2 << 22)       0x00800000                                                                        */\
  0 * RCC_CCIPR_SAI2SEL          |  /* (3 << 24)     0x03000000                                                                          */\
  0 * RCC_CCIPR_SAI2SEL_0        |  /* (1 << 24)       0x01000000                                                                        */\
  0 * RCC_CCIPR_SAI2SEL_1        |  /* (2 << 24)       0x02000000                                                                        */\
  0 * RCC_CCIPR_CLK48SEL         |  /* (3 << 26)     0x0C000000                                                                          */\
  0 * RCC_CCIPR_CLK48SEL_0       |  /* (1 << 26)       0x04000000                                                                        */\
  0 * RCC_CCIPR_CLK48SEL_1       |  /* (2 << 26)       0x08000000                                                                        */\
  0 * RCC_CCIPR_ADCSEL           |  /* (3 << 28)     0x30000000                                                                          */\
  0 * RCC_CCIPR_ADCSEL_0         |  /* (1 << 28)       0x10000000                                                                        */\
  0 * RCC_CCIPR_ADCSEL_1         |  /* (2 << 28)       0x20000000                                                                        */\
  0 * RCC_CCIPR_SWPMI1SEL        |  /* (1 << 30)     0x40000000                                                                          */\
  0 * RCC_CCIPR_DFSDM1SEL           /* (1 << 31)     0x80000000                                                                          */\
)

#define RCC_CIER (               \
  0 * RCC_CIER_LSIRDYIE          |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_CIER_LSERDYIE          |  /* (1 << 1)      0x00000002                                                                          */\
  0 * RCC_CIER_MSIRDYIE          |  /* (1 << 2)      0x00000004                                                                          */\
  0 * RCC_CIER_HSIRDYIE          |  /* (1 << 3)      0x00000008                                                                          */\
  0 * RCC_CIER_HSERDYIE          |  /* (1 << 4)      0x00000010                                                                          */\
  0 * RCC_CIER_PLLRDYIE          |  /* (1 << 5)      0x00000020                                                                          */\
  0 * RCC_CIER_PLLSAI1RDYIE      |  /* (1 << 6)      0x00000040                                                                          */\
  0 * RCC_CIER_PLLSAI2RDYIE      |  /* (1 << 7)      0x00000080                                                                          */\
  0 * RCC_CIER_LSECSSIE             /* (1 << 9)      0x00000200                                                                          */\
)

#define RCC_CIFR (               \
  0 * RCC_CIFR_LSIRDYF           |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_CIFR_LSERDYF           |  /* (1 << 1)      0x00000002                                                                          */\
  0 * RCC_CIFR_MSIRDYF           |  /* (1 << 2)      0x00000004                                                                          */\
  0 * RCC_CIFR_HSIRDYF           |  /* (1 << 3)      0x00000008                                                                          */\
  0 * RCC_CIFR_HSERDYF           |  /* (1 << 4)      0x00000010                                                                          */\
  0 * RCC_CIFR_PLLRDYF           |  /* (1 << 5)      0x00000020                                                                          */\
  0 * RCC_CIFR_PLLSAI1RDYF       |  /* (1 << 6)      0x00000040                                                                          */\
  0 * RCC_CIFR_PLLSAI2RDYF       |  /* (1 << 7)      0x00000080                                                                          */\
  0 * RCC_CIFR_CSSF              |  /* (1 << 8)      0x00000100                                                                          */\
  0 * RCC_CIFR_LSECSSF              /* (1 << 9)      0x00000200                                                                          */\
)

#define RCC_CICR (               \
  0 * RCC_CICR_LSIRDYC           |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_CICR_LSERDYC           |  /* (1 << 1)      0x00000002                                                                          */\
  0 * RCC_CICR_MSIRDYC           |  /* (1 << 2)      0x00000004                                                                          */\
  0 * RCC_CICR_HSIRDYC           |  /* (1 << 3)      0x00000008                                                                          */\
  0 * RCC_CICR_HSERDYC           |  /* (1 << 4)      0x00000010                                                                          */\
  0 * RCC_CICR_PLLRDYC           |  /* (1 << 5)      0x00000020                                                                          */\
  0 * RCC_CICR_PLLSAI1RDYC       |  /* (1 << 6)      0x00000040                                                                          */\
  0 * RCC_CICR_PLLSAI2RDYC       |  /* (1 << 7)      0x00000080                                                                          */\
  0 * RCC_CICR_CSSC              |  /* (1 << 8)      0x00000100                                                                          */\
  0 * RCC_CICR_LSECSSC              /* (1 << 9)      0x00000200                                                                          */\
)

#define RCC_ICSCR (       \
  0 * RCC_ICSCR_MSICAL    |  /* (0xFF << 0)   MSICAL[7:0] bits                                                        0x000000FF  */\
  0 * RCC_ICSCR_MSICAL_0  |  /* (0x01 << 0)     0x00000001                                                                        */\
  0 * RCC_ICSCR_MSICAL_1  |  /* (0x02 << 0)     0x00000002                                                                        */\
  0 * RCC_ICSCR_MSICAL_2  |  /* (0x04 << 0)     0x00000004                                                                        */\
  0 * RCC_ICSCR_MSICAL_3  |  /* (0x08 << 0)     0x00000008                                                                        */\
  0 * RCC_ICSCR_MSICAL_4  |  /* (0x10 << 0)     0x00000010                                                                        */\
  0 * RCC_ICSCR_MSICAL_5  |  /* (0x20 << 0)     0x00000020                                                                        */\
  0 * RCC_ICSCR_MSICAL_6  |  /* (0x40 << 0)     0x00000040                                                                        */\
  0 * RCC_ICSCR_MSICAL_7  |  /* (0x80 << 0)     0x00000080                                                                        */\
  0 * RCC_ICSCR_MSITRIM   |  /* (0xFF << 8)   MSITRIM[7:0] bits                                                       0x0000FF00  */\
  0 * RCC_ICSCR_MSITRIM_0 |  /* (0x01 << 8)     0x00000100                                                                        */\
  0 * RCC_ICSCR_MSITRIM_1 |  /* (0x02 << 8)     0x00000200                                                                        */\
  0 * RCC_ICSCR_MSITRIM_2 |  /* (0x04 << 8)     0x00000400                                                                        */\
  0 * RCC_ICSCR_MSITRIM_3 |  /* (0x08 << 8)     0x00000800                                                                        */\
  0 * RCC_ICSCR_MSITRIM_4 |  /* (0x10 << 8)     0x00001000                                                                        */\
  0 * RCC_ICSCR_MSITRIM_5 |  /* (0x20 << 8)     0x00002000                                                                        */\
  0 * RCC_ICSCR_MSITRIM_6 |  /* (0x40 << 8)     0x00004000                                                                        */\
  0 * RCC_ICSCR_MSITRIM_7 |  /* (0x80 << 8)     0x00008000                                                                        */\
  0 * RCC_ICSCR_HSICAL    |  /* (0xFF << 16)  HSICAL[7:0] bits                                                        0x00FF0000  */\
  0 * RCC_ICSCR_HSICAL_0  |  /* (0x01 << 16)    0x00010000                                                                        */\
  0 * RCC_ICSCR_HSICAL_1  |  /* (0x02 << 16)    0x00020000                                                                        */\
  0 * RCC_ICSCR_HSICAL_2  |  /* (0x04 << 16)    0x00040000                                                                        */\
  0 * RCC_ICSCR_HSICAL_3  |  /* (0x08 << 16)    0x00080000                                                                        */\
  0 * RCC_ICSCR_HSICAL_4  |  /* (0x10 << 16)    0x00100000                                                                        */\
  0 * RCC_ICSCR_HSICAL_5  |  /* (0x20 << 16)    0x00200000                                                                        */\
  0 * RCC_ICSCR_HSICAL_6  |  /* (0x40 << 16)    0x00400000                                                                        */\
  0 * RCC_ICSCR_HSICAL_7  |  /* (0x80 << 16)    0x00800000                                                                        */\
  0 * RCC_ICSCR_HSITRIM   |  /* (0x1F << 24)  HSITRIM[4:0] bits                                                       0x1F000000  */\
  0 * RCC_ICSCR_HSITRIM_0 |  /* (0x01 << 24)    0x01000000                                                                        */\
  0 * RCC_ICSCR_HSITRIM_1 |  /* (0x02 << 24)    0x02000000                                                                        */\
  0 * RCC_ICSCR_HSITRIM_2 |  /* (0x04 << 24)    0x04000000                                                                        */\
  0 * RCC_ICSCR_HSITRIM_3 |  /* (0x08 << 24)    0x08000000                                                                        */\
  0 * RCC_ICSCR_HSITRIM_4    /* (0x10 << 24)    0x10000000                                                                        */\
)

#define RCC_PLLCFGR (        \
  0 * RCC_PLLCFGR_PLLSRC     |  /* (3 << 0)      0x00000003                                                                          */\
  0 * RCC_PLLCFGR_PLLSRC_MSI |  /* (1 << 0)      MSI oscillator source clock selected                                    0x00000001  */\
  0 * RCC_PLLCFGR_PLLSRC_HSI |  /* (1 << 1)      HSI16 oscillator source clock selected                                  0x00000002  */\
  0 * RCC_PLLCFGR_PLLSRC_HSE |  /* (3 << 0)      HSE oscillator source clock selected                                    0x00000003  */\
  0 * RCC_PLLCFGR_PLLM       |  /* (7 << 4)      0x00000070                                                                          */\
  0 * RCC_PLLCFGR_PLLM_0     |  /* (1 << 4)        0x00000010                                                                        */\
  0 * RCC_PLLCFGR_PLLM_1     |  /* (2 << 4)        0x00000020                                                                        */\
  0 * RCC_PLLCFGR_PLLM_2     |  /* (4 << 4)        0x00000040                                                                        */\
  0 * RCC_PLLCFGR_PLLN       |  /* (0x7F << 8)   0x00007F00                                                                          */\
  0 * RCC_PLLCFGR_PLLN_0     |  /* (0x01 << 8)     0x00000100                                                                        */\
  0 * RCC_PLLCFGR_PLLN_1     |  /* (0x02 << 8)     0x00000200                                                                        */\
  0 * RCC_PLLCFGR_PLLN_2     |  /* (0x04 << 8)     0x00000400                                                                        */\
  0 * RCC_PLLCFGR_PLLN_3     |  /* (0x08 << 8)     0x00000800                                                                        */\
  0 * RCC_PLLCFGR_PLLN_4     |  /* (0x10 << 8)     0x00001000                                                                        */\
  0 * RCC_PLLCFGR_PLLN_5     |  /* (0x20 << 8)     0x00002000                                                                        */\
  0 * RCC_PLLCFGR_PLLN_6     |  /* (0x40 << 8)     0x00004000                                                                        */\
  0 * RCC_PLLCFGR_PLLPEN     |  /* (1 << 16)     0x00010000                                                                          */\
  0 * RCC_PLLCFGR_PLLP       |  /* (1 << 17)     0x00020000                                                                          */\
  0 * RCC_PLLCFGR_PLLQEN     |  /* (1 << 20)     0x00100000                                                                          */\
  0 * RCC_PLLCFGR_PLLQ       |  /* (3 << 21)     0x00600000                                                                          */\
  0 * RCC_PLLCFGR_PLLQ_0     |  /* (1 << 21)       0x00200000                                                                        */\
  0 * RCC_PLLCFGR_PLLQ_1     |  /* (2 << 21)       0x00400000                                                                        */\
  0 * RCC_PLLCFGR_PLLREN     |  /* (1 << 24)     0x01000000                                                                          */\
  0 * RCC_PLLCFGR_PLLR       |  /* (3 << 25)     0x06000000                                                                          */\
  0 * RCC_PLLCFGR_PLLR_0     |  /* (1 << 25)       0x02000000                                                                        */\
  0 * RCC_PLLCFGR_PLLR_1        /* (2 << 25)       0x04000000                                                                        */\
)

#define RCC_PLLSAI1CFGR (        \
  0 * RCC_PLLSAI1CFGR_PLLSAI1N   |  /* (0x7F << 8)   0x00007F00                                                                          */\
  0 * RCC_PLLSAI1CFGR_PLLSAI1N_0 |  /* (0x01 << 8)     0x00000100                                                                        */\
  0 * RCC_PLLSAI1CFGR_PLLSAI1N_1 |  /* (0x02 << 8)     0x00000200                                                                        */\
  0 * RCC_PLLSAI1CFGR_PLLSAI1N_2 |  /* (0x04 << 8)     0x00000400                                                                        */\
  0 * RCC_PLLSAI1CFGR_PLLSAI1N_3 |  /* (0x08 << 8)     0x00000800                                                                        */\
  0 * RCC_PLLSAI1CFGR_PLLSAI1N_4 |  /* (0x10 << 8)     0x00001000                                                                        */\
  0 * RCC_PLLSAI1CFGR_PLLSAI1N_5 |  /* (0x20 << 8)     0x00002000                                                                        */\
  0 * RCC_PLLSAI1CFGR_PLLSAI1N_6 |  /* (0x40 << 8)     0x00004000                                                                        */\
  0 * RCC_PLLSAI1CFGR_PLLSAI1PEN |  /* (1 << 16)     0x00010000                                                                          */\
  0 * RCC_PLLSAI1CFGR_PLLSAI1P   |  /* (1 << 17)     0x00020000                                                                          */\
  0 * RCC_PLLSAI1CFGR_PLLSAI1QEN |  /* (1 << 20)     0x00100000                                                                          */\
  0 * RCC_PLLSAI1CFGR_PLLSAI1Q   |  /* (3 << 21)     0x00600000                                                                          */\
  0 * RCC_PLLSAI1CFGR_PLLSAI1Q_0 |  /* (1 << 21)       0x00200000                                                                        */\
  0 * RCC_PLLSAI1CFGR_PLLSAI1Q_1 |  /* (2 << 21)       0x00400000                                                                        */\
  0 * RCC_PLLSAI1CFGR_PLLSAI1REN |  /* (1 << 24)     0x01000000                                                                          */\
  0 * RCC_PLLSAI1CFGR_PLLSAI1R   |  /* (3 << 25)     0x06000000                                                                          */\
  0 * RCC_PLLSAI1CFGR_PLLSAI1R_0 |  /* (1 << 25)       0x02000000                                                                        */\
  0 * RCC_PLLSAI1CFGR_PLLSAI1R_1    /* (2 << 25)       0x04000000                                                                        */\
)

#define RCC_PLLSAI2CFGR (        \
  0 * RCC_PLLSAI2CFGR_PLLSAI2N   |  /* (0x7F << 8)   0x00007F00                                                                          */\
  0 * RCC_PLLSAI2CFGR_PLLSAI2N_0 |  /* (0x01 << 8)     0x00000100                                                                        */\
  0 * RCC_PLLSAI2CFGR_PLLSAI2N_1 |  /* (0x02 << 8)     0x00000200                                                                        */\
  0 * RCC_PLLSAI2CFGR_PLLSAI2N_2 |  /* (0x04 << 8)     0x00000400                                                                        */\
  0 * RCC_PLLSAI2CFGR_PLLSAI2N_3 |  /* (0x08 << 8)     0x00000800                                                                        */\
  0 * RCC_PLLSAI2CFGR_PLLSAI2N_4 |  /* (0x10 << 8)     0x00001000                                                                        */\
  0 * RCC_PLLSAI2CFGR_PLLSAI2N_5 |  /* (0x20 << 8)     0x00002000                                                                        */\
  0 * RCC_PLLSAI2CFGR_PLLSAI2N_6 |  /* (0x40 << 8)     0x00004000                                                                        */\
  0 * RCC_PLLSAI2CFGR_PLLSAI2PEN |  /* (1 << 16)     0x00010000                                                                          */\
  0 * RCC_PLLSAI2CFGR_PLLSAI2P   |  /* (1 << 17)     0x00020000                                                                          */\
  0 * RCC_PLLSAI2CFGR_PLLSAI2REN |  /* (1 << 24)     0x01000000                                                                          */\
  0 * RCC_PLLSAI2CFGR_PLLSAI2R   |  /* (3 << 25)     0x06000000                                                                          */\
  0 * RCC_PLLSAI2CFGR_PLLSAI2R_0 |  /* (1 << 25)       0x02000000                                                                        */\
  0 * RCC_PLLSAI2CFGR_PLLSAI2R_1    /* (2 << 25)       0x04000000                                                                        */\
)

#define RCC_APB1RSTR1 (          \
  0 * RCC_APB1RSTR1_TIM2RST      |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_APB1RSTR1_TIM3RST      |  /* (1 << 1)      0x00000002                                                                          */\
  0 * RCC_APB1RSTR1_TIM4RST      |  /* (1 << 2)      0x00000004                                                                          */\
  0 * RCC_APB1RSTR1_TIM5RST      |  /* (1 << 3)      0x00000008                                                                          */\
  0 * RCC_APB1RSTR1_TIM6RST      |  /* (1 << 4)      0x00000010                                                                          */\
  0 * RCC_APB1RSTR1_TIM7RST      |  /* (1 << 5)      0x00000020                                                                          */\
  0 * RCC_APB1RSTR1_LCDRST       |  /* (1 << 9)      0x00000200                                                                          */\
  0 * RCC_APB1RSTR1_SPI2RST      |  /* (1 << 14)     0x00004000                                                                          */\
  0 * RCC_APB1RSTR1_SPI3RST      |  /* (1 << 15)     0x00008000                                                                          */\
  0 * RCC_APB1RSTR1_USART2RST    |  /* (1 << 17)     0x00020000                                                                          */\
  0 * RCC_APB1RSTR1_USART3RST    |  /* (1 << 18)     0x00040000                                                                          */\
  0 * RCC_APB1RSTR1_UART4RST     |  /* (1 << 19)     0x00080000                                                                          */\
  0 * RCC_APB1RSTR1_UART5RST     |  /* (1 << 20)     0x00100000                                                                          */\
  0 * RCC_APB1RSTR1_I2C1RST      |  /* (1 << 21)     0x00200000                                                                          */\
  0 * RCC_APB1RSTR1_I2C2RST      |  /* (1 << 22)     0x00400000                                                                          */\
  0 * RCC_APB1RSTR1_I2C3RST      |  /* (1 << 23)     0x00800000                                                                          */\
  0 * RCC_APB1RSTR1_CAN1RST      |  /* (1 << 25)     0x02000000                                                                          */\
  0 * RCC_APB1RSTR1_PWRRST       |  /* (1 << 28)     0x10000000                                                                          */\
  0 * RCC_APB1RSTR1_DAC1RST      |  /* (1 << 29)     0x20000000                                                                          */\
  0 * RCC_APB1RSTR1_OPAMPRST     |  /* (1 << 30)     0x40000000                                                                          */\
  0 * RCC_APB1RSTR1_LPTIM1RST       /* (1 << 31)     0x80000000                                                                          */\
)

#define RCC_APB1RSTR2 (          \
  0 * RCC_APB1RSTR2_LPUART1RST   |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_APB1RSTR2_SWPMI1RST    |  /* (1 << 2)      0x00000004                                                                          */\
  0 * RCC_APB1RSTR2_LPTIM2RST       /* (1 << 5)      0x00000020                                                                          */\
)

#define RCC_APB2RSTR (           \
  0 * RCC_APB2RSTR_SYSCFGRST     |  /* (1 << 0)      0x00000001                                                                          */\
  0 * RCC_APB2RSTR_SDMMC1RST     |  /* (1 << 10)     0x00000400                                                                          */\
  0 * RCC_APB2RSTR_TIM1RST       |  /* (1 << 11)     0x00000800                                                                          */\
  0 * RCC_APB2RSTR_SPI1RST       |  /* (1 << 12)     0x00001000                                                                          */\
  0 * RCC_APB2RSTR_TIM8RST       |  /* (1 << 13)     0x00002000                                                                          */\
  0 * RCC_APB2RSTR_USART1RST     |  /* (1 << 14)     0x00004000                                                                          */\
  0 * RCC_APB2RSTR_TIM15RST      |  /* (1 << 16)     0x00010000                                                                          */\
  0 * RCC_APB2RSTR_TIM16RST      |  /* (1 << 17)     0x00020000                                                                          */\
  0 * RCC_APB2RSTR_TIM17RST      |  /* (1 << 18)     0x00040000                                                                          */\
  0 * RCC_APB2RSTR_SAI1RST       |  /* (1 << 21)     0x00200000                                                                          */\
  0 * RCC_APB2RSTR_SAI2RST       |  /* (1 << 22)     0x00400000                                                                          */\
  0 * RCC_APB2RSTR_DFSDM1RST        /* (1 << 24)     0x01000000                                                                          */\
)


__STATIC_INLINE void init_rcc(void) {

  #if defined RCC_AHB1ENR
    #if RCC_AHB1ENR != 0
      RCC->AHB1ENR = RCC_AHB1ENR;      /* 0x40021048: RCC AHB1 peripheral clocks enable register, Address offset: 0x48                      */
    #endif
  #else
    #define RCC_AHB1ENR 0
  #endif

  #if defined RCC_AHB1RSTR
    #if RCC_AHB1RSTR != 0
      RCC->AHB1RSTR = RCC_AHB1RSTR;    /* 0x40021028: RCC AHB1 peripheral reset register, Address offset: 0x28                              */
    #endif
  #else
    #define RCC_AHB1RSTR 0
  #endif

  #if defined RCC_AHB1SMENR
    #if RCC_AHB1SMENR != 0
      RCC->AHB1SMENR = RCC_AHB1SMENR;  /* 0x40021068: RCC AHB1 peripheral clocks enable in sleep and stop modes register, Address offset: 0x68 */
    #endif
  #else
    #define RCC_AHB1SMENR 0
  #endif

  #if defined RCC_AHB2ENR
    #if RCC_AHB2ENR != 0
      RCC->AHB2ENR = RCC_AHB2ENR;      /* 0x4002104C: RCC AHB2 peripheral clocks enable register, Address offset: 0x4C                      */
    #endif
  #else
    #define RCC_AHB2ENR 0
  #endif

  #if defined RCC_AHB2RSTR
    #if RCC_AHB2RSTR != 0
      RCC->AHB2RSTR = RCC_AHB2RSTR;    /* 0x4002102C: RCC AHB2 peripheral reset register, Address offset: 0x2C                              */
    #endif
  #else
    #define RCC_AHB2RSTR 0
  #endif

  #if defined RCC_AHB2SMENR
    #if RCC_AHB2SMENR != 0
      RCC->AHB2SMENR = RCC_AHB2SMENR;  /* 0x4002106C: RCC AHB2 peripheral clocks enable in sleep and stop modes register, Address offset: 0x6C */
    #endif
  #else
    #define RCC_AHB2SMENR 0
  #endif

  #if defined RCC_AHB3ENR
    #if RCC_AHB3ENR != 0
      RCC->AHB3ENR = RCC_AHB3ENR;      /* 0x40021050: RCC AHB3 peripheral clocks enable register, Address offset: 0x50                      */
    #endif
  #else
    #define RCC_AHB3ENR 0
  #endif

  #if defined RCC_AHB3RSTR
    #if RCC_AHB3RSTR != 0
      RCC->AHB3RSTR = RCC_AHB3RSTR;    /* 0x40021030: RCC AHB3 peripheral reset register, Address offset: 0x30                              */
    #endif
  #else
    #define RCC_AHB3RSTR 0
  #endif

  #if defined RCC_AHB3SMENR
    #if RCC_AHB3SMENR != 0
      RCC->AHB3SMENR = RCC_AHB3SMENR;  /* 0x40021070: RCC AHB3 peripheral clocks enable in sleep and stop modes register, Address offset: 0x70 */
    #endif
  #else
    #define RCC_AHB3SMENR 0
  #endif

  #if defined RCC_APB1ENR1
    #if RCC_APB1ENR1 != 0
      RCC->APB1ENR1 = RCC_APB1ENR1;    /* 0x40021058: RCC APB1 peripheral clocks enable register 1, Address offset: 0x58                    */
    #endif
  #else
    #define RCC_APB1ENR1 0
  #endif

  #if defined RCC_APB1ENR2
    #if RCC_APB1ENR2 != 0
      RCC->APB1ENR2 = RCC_APB1ENR2;    /* 0x4002105C: RCC APB1 peripheral clocks enable register 2, Address offset: 0x5C                    */
    #endif
  #else
    #define RCC_APB1ENR2 0
  #endif

  #if defined RCC_APB1RSTR1
    #if RCC_APB1RSTR1 != 0
      RCC->APB1RSTR1 = RCC_APB1RSTR1;  /* 0x40021038: RCC APB1 peripheral reset register 1, Address offset: 0x38                            */
    #endif
  #else
    #define RCC_APB1RSTR1 0
  #endif

  #if defined RCC_APB1RSTR2
    #if RCC_APB1RSTR2 != 0
      RCC->APB1RSTR2 = RCC_APB1RSTR2;  /* 0x4002103C: RCC APB1 peripheral reset register 2, Address offset: 0x3C                            */
    #endif
  #else
    #define RCC_APB1RSTR2 0
  #endif

  #if defined RCC_APB1SMENR1
    #if RCC_APB1SMENR1 != 0
      RCC->APB1SMENR1 = RCC_APB1SMENR1; /* 0x40021078: RCC APB1 peripheral clocks enable in sleep mode and stop modes register 1, Address offset: 0x78 */
    #endif
  #else
    #define RCC_APB1SMENR1 0
  #endif

  #if defined RCC_APB1SMENR2
    #if RCC_APB1SMENR2 != 0
      RCC->APB1SMENR2 = RCC_APB1SMENR2; /* 0x4002107C: RCC APB1 peripheral clocks enable in sleep mode and stop modes register 2, Address offset: 0x7C */
    #endif
  #else
    #define RCC_APB1SMENR2 0
  #endif

  #if defined RCC_APB2ENR
    #if RCC_APB2ENR != 0
      RCC->APB2ENR = RCC_APB2ENR;      /* 0x40021060: RCC APB2 peripheral clocks enable register, Address offset: 0x60                      */
    #endif
  #else
    #define RCC_APB2ENR 0
  #endif

  #if defined RCC_APB2RSTR
    #if RCC_APB2RSTR != 0
      RCC->APB2RSTR = RCC_APB2RSTR;    /* 0x40021040: RCC APB2 peripheral reset register, Address offset: 0x40                              */
    #endif
  #else
    #define RCC_APB2RSTR 0
  #endif

  #if defined RCC_APB2SMENR
    #if RCC_APB2SMENR != 0
      RCC->APB2SMENR = RCC_APB2SMENR;  /* 0x40021080: RCC APB2 peripheral clocks enable in sleep mode and stop modes register, Address offset: 0x80 */
    #endif
  #else
    #define RCC_APB2SMENR 0
  #endif

  #if defined RCC_BDCR
    #if RCC_BDCR != 0
      RCC->BDCR = RCC_BDCR;            /* 0x40021090: RCC backup domain control register, Address offset: 0x90                              */
    #endif
  #else
    #define RCC_BDCR 0
  #endif

  #if defined RCC_CCIPR
    #if RCC_CCIPR != 0
      RCC->CCIPR = RCC_CCIPR;          /* 0x40021088: RCC peripherals independent clock configuration register, Address offset: 0x88        */
    #endif
  #else
    #define RCC_CCIPR 0
  #endif

  #if defined RCC_CFGR
    #if RCC_CFGR != 0
      RCC->CFGR = RCC_CFGR;       /* 0x40021008: RCC clock configuration register, Address offset: 0x08                                */
    #endif
  #else
    #define RCC_CFGR 0
  #endif

  #if defined RCC_CIER
    #if RCC_CIER != 0
      RCC->CIER = RCC_CIER;            /* 0x40021018: RCC clock interrupt enable register, Address offset: 0x18                             */
    #endif
  #else
    #define RCC_CIER 0
  #endif

  #if defined RCC_CIFR
    #if RCC_CIFR != 0
      RCC->CIFR = RCC_CIFR;            /* 0x4002101C: RCC clock interrupt flag register, Address offset: 0x1C                               */
    #endif
  #else
    #define RCC_CIFR 0
  #endif

  #if defined RCC_CR
    #if RCC_CR != 0
      RCC->CR = RCC_CR;        /* 0x40021000: RCC clock control register, Address offset: 0x00                                    */
    #endif
  #else
    #define RCC_CR 0
  #endif

  #if defined RCC_CSR
    #if RCC_CSR != 0
      RCC->CSR = RCC_CSR;              /* 0x40021094: RCC clock control & status register, Address offset: 0x94                             */
    #endif
  #else
    #define RCC_CSR 0
  #endif

  #if defined RCC_CICR
    #if RCC_CICR != 0
      RCC->CICR = RCC_CICR;            /* 0x40021020: RCC clock interrupt clear register, Address offset: 0x20                              */
    #endif
  #else
    #define RCC_CICR 0
  #endif

  #if defined RCC_ICSCR
    #if RCC_ICSCR != 0
      RCC->ICSCR = RCC_ICSCR;   /* 0x40021004: RCC internal clock sources calibration register, Address offset: 0x04                 */
    #endif
  #else
    #define RCC_ICSCR 0
  #endif

  #if defined RCC_PLLCFGR
    #if RCC_PLLCFGR != 0
      RCC->PLLCFGR = RCC_PLLCFGR;  /* 0x4002100C: RCC system PLL configuration register, Address offset: 0x0C                           */
    #endif
  #else
    #define RCC_PLLCFGR 0
  #endif

  #if defined RCC_PLLSAI1CFGR
    #if RCC_PLLSAI1CFGR != 0
      RCC->PLLSAI1CFGR = RCC_PLLSAI1CFGR; /* 0x40021010: RCC PLL SAI1 configuration register, Address offset: 0x10                             */
    #endif
  #else
    #define RCC_PLLSAI1CFGR 0
  #endif

  #if defined RCC_PLLSAI2CFGR
    #if RCC_PLLSAI2CFGR != 0
      RCC->PLLSAI2CFGR = RCC_PLLSAI2CFGR; /* 0x40021014: RCC PLL SAI2 configuration register, Address offset: 0x14                             */
    #endif
  #else
    #define RCC_PLLSAI2CFGR 0
  #endif

}

#ifdef __cplusplus
  }
#endif /* __cplusplus */
#endif /* __RCC_H__ */

