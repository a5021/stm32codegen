#ifndef __RCC_H__
#define __RCC_H__

#ifdef __cplusplus
  extern "C" {
#endif


#define R                              (HCLK >= 32)

#define PLLN_VAL                       (HCLK / 4)        /* PLLN: HSI16/1*PLLN/4 = HCLK */
#define PLLN_0                         ((PLLN_VAL >> 0) & 1)
#define PLLN_1                         ((PLLN_VAL >> 1) & 1)
#define PLLN_2                         ((PLLN_VAL >> 2) & 1)
#define PLLN_3                         ((PLLN_VAL >> 3) & 1)
#define PLLN_4                         ((PLLN_VAL >> 4) & 1)
#define PLLN_5                         ((PLLN_VAL >> 5) & 1)
#define PLLN_6                         ((PLLN_VAL >> 6) & 1)


__STATIC_FORCEINLINE void configure_flash(void);
__STATIC_FORCEINLINE void wait_for_clock_stable(void);


#define RCC_CFGR (         \
  0 * RCC_CFGR_SW          |  /* (7 << 0)     SW[2:0] bits (System clock Switch)                      0x00000007  */\
  0 * RCC_CFGR_SW_0        |  /* (1 << 0)       0x00000001                                                        */\
  0 * RCC_CFGR_SW_1        |  /* (2 << 0)       0x00000002                                                        */\
  0 * RCC_CFGR_SW_2        |  /* (4 << 0)       0x00000004                                                        */\
  0 * RCC_CFGR_SW_HSISYS   |  /* 0x00000000   HSISYS oscillator selection as system clock                         */\
  0 * RCC_CFGR_SW_HSE      |  /* 0x00000001   HSE oscillator selection as system clock                            */\
  0 * RCC_CFGR_SW_PLLRCLK  |  /* 0x00000002   PLLRCLK selection as system clock                                   */\
  0 * RCC_CFGR_SW_LSI      |  /* 0x00000003   LSI oscillator selection as system clock                            */\
  0 * RCC_CFGR_SW_LSE      |  /* 0x00000004   LSE oscillator selection as system clock                            */\
  0 * RCC_CFGR_SWS         |  /* (7 << 3)     SWS[2:0] bits (System Clock Switch Status)              0x00000038  */\
  0 * RCC_CFGR_SWS_0       |  /* (1 << 3)       0x00000008                                                        */\
  0 * RCC_CFGR_SWS_1       |  /* (2 << 3)       0x00000010                                                        */\
  0 * RCC_CFGR_SWS_2       |  /* (4 << 3)       0x00000020                                                        */\
  0 * RCC_CFGR_SWS_HSISYS  |  /* 0x00000000   HSISYS used as system clock                                         */\
  0 * RCC_CFGR_SWS_HSE     |  /* 0x00000008   HSE used as system clock                                            */\
  0 * RCC_CFGR_SWS_PLLRCLK |  /* 0x00000010   PLLRCLK used as system clock                                        */\
  0 * RCC_CFGR_SWS_LSI     |  /* 0x00000018   LSI used as system clock                                            */\
  0 * RCC_CFGR_SWS_LSE     |  /* 0x00000100   LSE used as system clock                                            */\
  0 * RCC_CFGR_HPRE        |  /* (0xF << 8)   HPRE[3:0] bits (AHB prescaler)                          0x00000F00  */\
  0 * RCC_CFGR_HPRE_0      |  /* (1 << 8)       0x00000100                                                        */\
  0 * RCC_CFGR_HPRE_1      |  /* (2 << 8)       0x00000200                                                        */\
  0 * RCC_CFGR_HPRE_2      |  /* (4 << 8)       0x00000400                                                        */\
  0 * RCC_CFGR_HPRE_3      |  /* (8 << 8)       0x00000800                                                        */\
  0 * RCC_CFGR_PPRE        |  /* (7 << 12)    PRE1[2:0] bits (APB prescaler)                          0x00007000  */\
  0 * RCC_CFGR_PPRE_0      |  /* (1 << 12)      0x00001000                                                        */\
  0 * RCC_CFGR_PPRE_1      |  /* (2 << 12)      0x00002000                                                        */\
  0 * RCC_CFGR_PPRE_2      |  /* (4 << 12)      0x00004000                                                        */\
  0 * RCC_CFGR_MCOSEL      |  /* (7 << 24)    MCOSEL [2:0] bits (Clock output selection)              0x07000000  */\
  0 * RCC_CFGR_MCOSEL_0    |  /* (1 << 24)      0x01000000                                                        */\
  0 * RCC_CFGR_MCOSEL_1    |  /* (2 << 24)      0x02000000                                                        */\
  0 * RCC_CFGR_MCOSEL_2    |  /* (4 << 24)      0x04000000                                                        */\
  0 * RCC_CFGR_MCOPRE      |  /* (7 << 28)    MCO prescaler [2:0]                                     0x70000000  */\
  0 * RCC_CFGR_MCOPRE_0    |  /* (1 << 28)      0x10000000                                                        */\
  0 * RCC_CFGR_MCOPRE_1    |  /* (2 << 28)      0x20000000                                                        */\
  0 * RCC_CFGR_MCOPRE_2       /* (4 << 28)      0x40000000                                                        */\
)


#define RCC_CSR (               \
  0 * RCC_CSR_LSION             |  /* (1 << 0)      0x00000001                                                          */\
  0 * RCC_CSR_LSIRDY            |  /* (1 << 1)      0x00000002                                                          */\
  0 * RCC_CSR_RMVF              |  /* (1 << 23)     0x00800000                                                          */\
  0 * RCC_CSR_OBLRSTF           |  /* (1 << 25)     0x02000000                                                          */\
  0 * RCC_CSR_PINRSTF           |  /* (1 << 26)     0x04000000                                                          */\
  0 * RCC_CSR_PWRRSTF           |  /* (1 << 27)     0x08000000                                                          */\
  0 * RCC_CSR_SFTRSTF           |  /* (1 << 28)     0x10000000                                                          */\
  0 * RCC_CSR_IWDGRSTF          |  /* (1 << 29)     0x20000000                                                          */\
  0 * RCC_CSR_WWDGRSTF          |  /* (1 << 30)     0x40000000                                                          */\
  0 * RCC_CSR_LPWRRSTF             /* (1 << 31)     0x80000000                                                          */\
)


#define RCC_AHBRSTR (         \
  0 * RCC_AHBRSTR_DMA1RST     |  /* (1 << 0)      0x00000001                                                          */\
  0 * RCC_AHBRSTR_FLASHRST    |  /* (1 << 8)      0x00000100                                                          */\
  0 * RCC_AHBRSTR_CRCRST         /* (1 << 12)     0x00001000                                                          */\
)


#define RCC_AHBSMENR (        \
  0 * RCC_AHBSMENR_DMA1SMEN   |  /* (1 << 0)      0x00000001                                                          */\
  0 * RCC_AHBSMENR_FLASHSMEN  |  /* (1 << 8)      0x00000100                                                          */\
  0 * RCC_AHBSMENR_SRAMSMEN   |  /* (1 << 9)      0x00000200                                                          */\
  0 * RCC_AHBSMENR_CRCSMEN       /* (1 << 12)     0x00001000                                                          */\
)


#define RCC_APBRSTR1 (        \
  0 * RCC_APBRSTR1_TIM2RST    |  /* (1 << 0)      0x00000001                                                          */\
  0 * RCC_APBRSTR1_TIM3RST    |  /* (1 << 1)      0x00000002                                                          */\
  0 * RCC_APBRSTR1_SPI2RST    |  /* (1 << 14)     0x00004000                                                          */\
  0 * RCC_APBRSTR1_USART2RST  |  /* (1 << 17)     0x00020000                                                          */\
  0 * RCC_APBRSTR1_LPUART1RST |  /* (1 << 20)     0x00100000                                                          */\
  0 * RCC_APBRSTR1_I2C1RST    |  /* (1 << 21)     0x00200000                                                          */\
  0 * RCC_APBRSTR1_I2C2RST    |  /* (1 << 22)     0x00400000                                                          */\
  0 * RCC_APBRSTR1_DBGRST     |  /* (1 << 27)     0x08000000                                                          */\
  0 * RCC_APBRSTR1_PWRRST     |  /* (1 << 28)     0x10000000                                                          */\
  0 * RCC_APBRSTR1_LPTIM2RST  |  /* (1 << 30)     0x40000000                                                          */\
  0 * RCC_APBRSTR1_LPTIM1RST     /* (1 << 31)     0x80000000                                                          */\
)


#define RCC_APBRSTR2 (        \
  0 * RCC_APBRSTR2_SYSCFGRST  |  /* (1 << 0)      0x00000001                                                          */\
  0 * RCC_APBRSTR2_TIM1RST    |  /* (1 << 11)     0x00000800                                                          */\
  0 * RCC_APBRSTR2_SPI1RST    |  /* (1 << 12)     0x00001000                                                          */\
  0 * RCC_APBRSTR2_USART1RST  |  /* (1 << 14)     0x00004000                                                          */\
  0 * RCC_APBRSTR2_TIM14RST   |  /* (1 << 15)     0x00008000                                                          */\
  0 * RCC_APBRSTR2_TIM16RST   |  /* (1 << 17)     0x00020000                                                          */\
  0 * RCC_APBRSTR2_TIM17RST   |  /* (1 << 18)     0x00040000                                                          */\
  0 * RCC_APBRSTR2_ADCRST        /* (1 << 20)     0x00100000                                                          */\
)


#define RCC_APBSMENR1 (         \
  0 * RCC_APBSMENR1_TIM2SMEN    |  /* (1 << 0)      0x00000001                                                          */\
  0 * RCC_APBSMENR1_TIM3SMEN    |  /* (1 << 1)      0x00000002                                                          */\
  0 * RCC_APBSMENR1_RTCAPBSMEN  |  /* (1 << 10)     0x00000400                                                          */\
  0 * RCC_APBSMENR1_WWDGSMEN    |  /* (1 << 11)     0x00000800                                                          */\
  0 * RCC_APBSMENR1_SPI2SMEN    |  /* (1 << 14)     0x00004000                                                          */\
  0 * RCC_APBSMENR1_USART2SMEN  |  /* (1 << 17)     0x00020000                                                          */\
  0 * RCC_APBSMENR1_LPUART1SMEN |  /* (1 << 20)     0x00100000                                                          */\
  0 * RCC_APBSMENR1_I2C1SMEN    |  /* (1 << 21)     0x00200000                                                          */\
  0 * RCC_APBSMENR1_I2C2SMEN    |  /* (1 << 22)     0x00400000                                                          */\
  0 * RCC_APBSMENR1_DBGSMEN     |  /* (1 << 27)     0x08000000                                                          */\
  0 * RCC_APBSMENR1_PWRSMEN     |  /* (1 << 28)     0x10000000                                                          */\
  0 * RCC_APBSMENR1_LPTIM2SMEN  |  /* (1 << 30)     0x40000000                                                          */\
  0 * RCC_APBSMENR1_LPTIM1SMEN     /* (1 << 31)     0x80000000                                                          */\
)


#define RCC_APBSMENR2 (         \
  0 * RCC_APBSMENR2_SYSCFGSMEN  |  /* (1 << 0)      0x00000001                                                          */\
  0 * RCC_APBSMENR2_TIM1SMEN    |  /* (1 << 11)     0x00000800                                                          */\
  0 * RCC_APBSMENR2_SPI1SMEN    |  /* (1 << 12)     0x00001000                                                          */\
  0 * RCC_APBSMENR2_USART1SMEN  |  /* (1 << 14)     0x00004000                                                          */\
  0 * RCC_APBSMENR2_TIM14SMEN   |  /* (1 << 15)     0x00008000                                                          */\
  0 * RCC_APBSMENR2_TIM16SMEN   |  /* (1 << 17)     0x00020000                                                          */\
  0 * RCC_APBSMENR2_TIM17SMEN   |  /* (1 << 18)     0x00040000                                                          */\
  0 * RCC_APBSMENR2_ADCSMEN        /* (1 << 20)     0x00100000                                                          */\
)


#define RCC_BDCR (              \
  0 * RCC_BDCR_LSEON            |  /* (1 << 0)      0x00000001                                                          */\
  0 * RCC_BDCR_LSERDY           |  /* (1 << 1)      0x00000002                                                          */\
  0 * RCC_BDCR_LSEBYP           |  /* (1 << 2)      0x00000004                                                          */\
  0 * RCC_BDCR_LSEDRV           |  /* (3 << 3)      0x00000018                                                          */\
  0 * RCC_BDCR_LSEDRV_0         |  /* (1 << 3)        0x00000008                                                        */\
  0 * RCC_BDCR_LSEDRV_1         |  /* (2 << 3)        0x00000010                                                        */\
  0 * RCC_BDCR_LSECSSON         |  /* (1 << 5)      0x00000020                                                          */\
  0 * RCC_BDCR_LSECSSD          |  /* (1 << 6)      0x00000040                                                          */\
  0 * RCC_BDCR_RTCSEL           |  /* (3 << 8)      0x00000300                                                          */\
  0 * RCC_BDCR_RTCSEL_0         |  /* (1 << 8)        0x00000100                                                        */\
  0 * RCC_BDCR_RTCSEL_1         |  /* (2 << 8)        0x00000200                                                        */\
  0 * RCC_BDCR_RTCEN            |  /* (1 << 15)     0x00008000                                                          */\
  0 * RCC_BDCR_BDRST            |  /* (1 << 16)     0x00010000                                                          */\
  0 * RCC_BDCR_LSCOEN           |  /* (1 << 24)     0x01000000                                                          */\
  0 * RCC_BDCR_LSCOSEL             /* (1 << 25)     0x02000000                                                          */\
)


#define RCC_CR (      \
  R * RCC_CR_HSION    |  /* (1 << 8)   Internal High Speed clock enable                        0x00000100  */\
  0 * RCC_CR_HSIKERON |  /* (1 << 9)   Internal High Speed clock enable for some IPs Kernel    0x00000200  */\
  0 * RCC_CR_HSIRDY   |  /* (1 << 10)  Internal High Speed clock ready flag                    0x00000400  */\
  0 * RCC_CR_HSIDIV   |  /* (7 << 11)  HSIDIV[13:11] Internal High Speed clock division factor 0x00003800  */\
  0 * RCC_CR_HSIDIV_0 |  /* (1 << 11)    0x00000800                                                        */\
  0 * RCC_CR_HSIDIV_1 |  /* (2 << 11)    0x00001000                                                        */\
  0 * RCC_CR_HSIDIV_2 |  /* (4 << 11)    0x00002000                                                        */\
  0 * RCC_CR_HSEON    |  /* (1 << 16)  External High Speed clock enable                        0x00010000  */\
  0 * RCC_CR_HSERDY   |  /* (1 << 17)  External High Speed clock ready                         0x00020000  */\
  0 * RCC_CR_HSEBYP   |  /* (1 << 18)  External High Speed clock Bypass                        0x00040000  */\
  0 * RCC_CR_CSSON    |  /* (1 << 19)  HSE Clock Security System enable                        0x00080000  */\
  R * RCC_CR_PLLON    |  /* (1 << 24)  System PLL clock enable                                 0x01000000  */\
  0 * RCC_CR_PLLRDY      /* (1 << 25)  System PLL clock ready                                  0x02000000  */\
)


#define RCC_CIER (            \
  0 * RCC_CIER_LSIRDYIE       |  /* (1 << 0)      0x00000001                                                          */\
  0 * RCC_CIER_LSERDYIE       |  /* (1 << 1)      0x00000002                                                          */\
  0 * RCC_CIER_HSIRDYIE       |  /* (1 << 3)      0x00000008                                                          */\
  0 * RCC_CIER_HSERDYIE       |  /* (1 << 4)      0x00000010                                                          */\
  0 * RCC_CIER_PLLRDYIE          /* (1 << 5)      0x00000020                                                          */\
)


#define RCC_CCIPR (             \
  0 * RCC_CCIPR_USART1SEL       |  /* (3 << 0)      0x00000003                                                          */\
  0 * RCC_CCIPR_USART1SEL_0     |  /* (1 << 0)        0x00000001                                                        */\
  0 * RCC_CCIPR_USART1SEL_1     |  /* (2 << 0)        0x00000002                                                        */\
  0 * RCC_CCIPR_LPUART1SEL      |  /* (3 << 10)     0x00000C00                                                          */\
  0 * RCC_CCIPR_LPUART1SEL_0    |  /* (1 << 10)       0x00000400                                                        */\
  0 * RCC_CCIPR_LPUART1SEL_1    |  /* (2 << 10)       0x00000800                                                        */\
  0 * RCC_CCIPR_I2C1SEL         |  /* (3 << 12)     0x00003000                                                          */\
  0 * RCC_CCIPR_I2C1SEL_0       |  /* (1 << 12)       0x00001000                                                        */\
  0 * RCC_CCIPR_I2C1SEL_1       |  /* (2 << 12)       0x00002000                                                        */\
  0 * RCC_CCIPR_I2S1SEL         |  /* (3 << 14)     0x0000C000                                                          */\
  0 * RCC_CCIPR_I2S1SEL_0       |  /* (1 << 14)       0x00004000                                                        */\
  0 * RCC_CCIPR_I2S1SEL_1       |  /* (2 << 14)       0x00008000                                                        */\
  0 * RCC_CCIPR_LPTIM1SEL       |  /* (3 << 18)     0x000C0000                                                          */\
  0 * RCC_CCIPR_LPTIM1SEL_0     |  /* (1 << 18)       0x00040000                                                        */\
  0 * RCC_CCIPR_LPTIM1SEL_1     |  /* (2 << 18)       0x00080000                                                        */\
  0 * RCC_CCIPR_LPTIM2SEL       |  /* (3 << 20)     0x00300000                                                          */\
  0 * RCC_CCIPR_LPTIM2SEL_0     |  /* (1 << 20)       0x00100000                                                        */\
  0 * RCC_CCIPR_LPTIM2SEL_1     |  /* (2 << 20)       0x00200000                                                        */\
  0 * RCC_CCIPR_TIM1SEL         |  /* (1 << 22)     0x00400000                                                          */\
  0 * RCC_CCIPR_ADCSEL          |  /* (3 << 30)     0xC0000000                                                          */\
  0 * RCC_CCIPR_ADCSEL_0        |  /* (1 << 30)       0x40000000                                                        */\
  0 * RCC_CCIPR_ADCSEL_1           /* (2 << 30)       0x80000000                                                        */\
)


#define RCC_CIFR (            \
  0 * RCC_CIFR_LSIRDYF        |  /* (1 << 0)      0x00000001                                                          */\
  0 * RCC_CIFR_LSERDYF        |  /* (1 << 1)      0x00000002                                                          */\
  0 * RCC_CIFR_HSIRDYF        |  /* (1 << 3)      0x00000008                                                          */\
  0 * RCC_CIFR_HSERDYF        |  /* (1 << 4)      0x00000010                                                          */\
  0 * RCC_CIFR_PLLRDYF        |  /* (1 << 5)      0x00000020                                                          */\
  0 * RCC_CIFR_CSSF           |  /* (1 << 8)      0x00000100                                                          */\
  0 * RCC_CIFR_LSECSSF           /* (1 << 9)      0x00000200                                                          */\
)


#define RCC_CICR (            \
  0 * RCC_CICR_LSIRDYC        |  /* (1 << 0)      0x00000001                                                          */\
  0 * RCC_CICR_LSERDYC        |  /* (1 << 1)      0x00000002                                                          */\
  0 * RCC_CICR_HSIRDYC        |  /* (1 << 3)      0x00000008                                                          */\
  0 * RCC_CICR_HSERDYC        |  /* (1 << 4)      0x00000010                                                          */\
  0 * RCC_CICR_PLLRDYC        |  /* (1 << 5)      0x00000020                                                          */\
  0 * RCC_CICR_CSSC           |  /* (1 << 8)      0x00000100                                                          */\
  0 * RCC_CICR_LSECSSC           /* (1 << 9)      0x00000200                                                          */\
)


#define RCC_ICSCR (       \
  0 * RCC_ICSCR_HSICAL    |  /* (0xFF << 0)  HSICAL[7:0] bits                                        0x000000FF  */\
  0 * RCC_ICSCR_HSICAL_0  |  /* (0x01 << 0)    0x00000001                                                        */\
  0 * RCC_ICSCR_HSICAL_1  |  /* (0x02 << 0)    0x00000002                                                        */\
  0 * RCC_ICSCR_HSICAL_2  |  /* (0x04 << 0)    0x00000004                                                        */\
  0 * RCC_ICSCR_HSICAL_3  |  /* (0x08 << 0)    0x00000008                                                        */\
  0 * RCC_ICSCR_HSICAL_4  |  /* (0x10 << 0)    0x00000010                                                        */\
  0 * RCC_ICSCR_HSICAL_5  |  /* (0x20 << 0)    0x00000020                                                        */\
  0 * RCC_ICSCR_HSICAL_6  |  /* (0x40 << 0)    0x00000040                                                        */\
  0 * RCC_ICSCR_HSICAL_7  |  /* (0x80 << 0)    0x00000080                                                        */\
  0 * RCC_ICSCR_HSITRIM   |  /* (0x7F << 8)  HSITRIM[14:8] bits                                      0x00007F00  */\
  0 * RCC_ICSCR_HSITRIM_0 |  /* (0x01 << 8)    0x00000100                                                        */\
  0 * RCC_ICSCR_HSITRIM_1 |  /* (0x02 << 8)    0x00000200                                                        */\
  0 * RCC_ICSCR_HSITRIM_2 |  /* (0x04 << 8)    0x00000400                                                        */\
  0 * RCC_ICSCR_HSITRIM_3 |  /* (0x08 << 8)    0x00000800                                                        */\
  0 * RCC_ICSCR_HSITRIM_4 |  /* (0x10 << 8)    0x00001000                                                        */\
  0 * RCC_ICSCR_HSITRIM_5 |  /* (0x20 << 8)    0x00002000                                                        */\
  0 * RCC_ICSCR_HSITRIM_6    /* (0x40 << 8)    0x00004000                                                        */\
)


#define RCC_IOPRSTR (         \
  0 * RCC_IOPRSTR_GPIOARST    |  /* (1 << 0)      0x00000001                                                          */\
  0 * RCC_IOPRSTR_GPIOBRST    |  /* (1 << 1)      0x00000002                                                          */\
  0 * RCC_IOPRSTR_GPIOCRST    |  /* (1 << 2)      0x00000004                                                          */\
  0 * RCC_IOPRSTR_GPIODRST    |  /* (1 << 3)      0x00000008                                                          */\
  0 * RCC_IOPRSTR_GPIOFRST       /* (1 << 5)      0x00000020                                                          */\
)


#define RCC_IOPSMENR (        \
  0 * RCC_IOPSMENR_GPIOASMEN  |  /* (1 << 0)      0x00000001                                                          */\
  0 * RCC_IOPSMENR_GPIOBSMEN  |  /* (1 << 1)      0x00000002                                                          */\
  0 * RCC_IOPSMENR_GPIOCSMEN  |  /* (1 << 2)      0x00000004                                                          */\
  0 * RCC_IOPSMENR_GPIODSMEN  |  /* (1 << 3)      0x00000008                                                          */\
  0 * RCC_IOPSMENR_GPIOFSMEN     /* (1 << 5)      0x00000020                                                          */\
)


#define RCC_PLLCFGR (         \
  0 * RCC_PLLCFGR_PLLSRC      |  /* (3 << 0)      0x00000003                                                          */\
  0 * RCC_PLLCFGR_PLLSRC_0    |  /* (1 << 0)        0x00000001                                                        */\
  0 * RCC_PLLCFGR_PLLSRC_1    |  /* (2 << 0)        0x00000002                                                        */\
  0 * RCC_PLLCFGR_PLLSRC_NONE |  /* 0x00000000    No clock sent to PLL                                                */\
  0 * RCC_PLLCFGR_PLLSRC_HSI  |  /* (1 << 1)      HSI source clock selected                               0x00000002  */\
  0 * RCC_PLLCFGR_PLLSRC_HSE  |  /* (3 << 0)      HSE source clock selected                               0x00000003  */\
  0 * RCC_PLLCFGR_PLLM        |  /* (7 << 4)      0x00000070                                                          */\
  0 * RCC_PLLCFGR_PLLM_0      |  /* (1 << 4)        0x00000010                                                        */\
  0 * RCC_PLLCFGR_PLLM_1      |  /* (2 << 4)        0x00000020                                                        */\
  0 * RCC_PLLCFGR_PLLM_2      |  /* (4 << 4)        0x00000040                                                        */\
  0 * RCC_PLLCFGR_PLLN        |  /* (0x7F << 8)   0x00007F00                                                          */\
  PLLN_0 * RCC_PLLCFGR_PLLN_0      |  /* (0x01 << 8)     0x00000100                                                        */\
  PLLN_1 * RCC_PLLCFGR_PLLN_1      |  /* (0x02 << 8)     0x00000200                                                        */\
  PLLN_2 * RCC_PLLCFGR_PLLN_2      |  /* (0x04 << 8)     0x00000400                                                        */\
  PLLN_3 * RCC_PLLCFGR_PLLN_3      |  /* (0x08 << 8)     0x00000800                                                        */\
  PLLN_4 * RCC_PLLCFGR_PLLN_4      |  /* (0x10 << 8)     0x00001000                                                        */\
  PLLN_5 * RCC_PLLCFGR_PLLN_5      |  /* (0x20 << 8)     0x00002000                                                        */\
  PLLN_6 * RCC_PLLCFGR_PLLN_6      |  /* (0x40 << 8)     0x00004000                                                        */\
  0 * RCC_PLLCFGR_PLLPEN      |  /* (1 << 16)     0x00010000                                                          */\
  0 * RCC_PLLCFGR_PLLP        |  /* (0x1F << 17)  0x003E0000                                                          */\
  0 * RCC_PLLCFGR_PLLP_0      |  /* (0x01 << 17)    0x00020000                                                        */\
  0 * RCC_PLLCFGR_PLLP_1      |  /* (0x02 << 17)    0x00040000                                                        */\
  0 * RCC_PLLCFGR_PLLP_2      |  /* (0x04 << 17)    0x00080000                                                        */\
  0 * RCC_PLLCFGR_PLLP_3      |  /* (0x08 << 17)    0x00100000                                                        */\
  0 * RCC_PLLCFGR_PLLP_4      |  /* (0x10 << 17)    0x00200000                                                        */\
  0 * RCC_PLLCFGR_PLLQEN      |  /* (1 << 24)     0x01000000                                                          */\
  0 * RCC_PLLCFGR_PLLQ        |  /* (7 << 25)     0x0E000000                                                          */\
  0 * RCC_PLLCFGR_PLLQ_0      |  /* (1 << 25)       0x02000000                                                        */\
  0 * RCC_PLLCFGR_PLLQ_1      |  /* (2 << 25)       0x04000000                                                        */\
  0 * RCC_PLLCFGR_PLLQ_2      |  /* (4 << 25)       0x08000000                                                        */\
  0 * RCC_PLLCFGR_PLLREN      |  /* (1 << 28)     0x10000000                                                          */\
  0 * RCC_PLLCFGR_PLLR        |  /* (7 << 29)     0xE0000000                                                          */\
  0 * RCC_PLLCFGR_PLLR_0      |  /* (1 << 29)       0x20000000                                                        */\
  0 * RCC_PLLCFGR_PLLR_1      |  /* (2 << 29)       0x40000000                                                        */\
  0 * RCC_PLLCFGR_PLLR_2         /* (4 << 29)       0x80000000                                                        */\
)

#if !defined(DMA1_EN)
  #define DMA1_EN 0
#endif

#if !defined(FLASH_EN)
  #define FLASH_EN 0
#endif

#if !defined(CRC_EN)
  #define CRC_EN 0
#endif


#define RCC_AHBENR (                      \
  DMA1_EN       * RCC_AHBENR_DMA1EN       |  /* (1 << 0)      0x00000001                                                          */\
  FLASH_EN      * RCC_AHBENR_FLASHEN      |  /* (1 << 8)      0x00000100                                                          */\
  CRC_EN        * RCC_AHBENR_CRCEN           /* (1 << 12)     0x00001000                                                          */\
)

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


#define RCC_IOPENR (                      \
  GPIOA_EN      * RCC_IOPENR_GPIOAEN      |  /* (1 << 0)      0x00000001                                                          */\
  GPIOB_EN      * RCC_IOPENR_GPIOBEN      |  /* (1 << 1)      0x00000002                                                          */\
  GPIOC_EN      * RCC_IOPENR_GPIOCEN      |  /* (1 << 2)      0x00000004                                                          */\
  GPIOD_EN      * RCC_IOPENR_GPIODEN      |  /* (1 << 3)      0x00000008                                                          */\
  GPIOF_EN      * RCC_IOPENR_GPIOFEN         /* (1 << 5)      0x00000020                                                          */\
)

#if !defined(SYSCFG_EN)
  #define SYSCFG_EN 0
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

#if !defined(TIM14_EN)
  #define TIM14_EN 0
#endif

#if !defined(TIM16_EN)
  #define TIM16_EN 0
#endif

#if !defined(TIM17_EN)
  #define TIM17_EN 0
#endif

#if !defined(ADC_EN)
  #define ADC_EN 0
#endif


#define RCC_APBENR2 (                     \
  SYSCFG_EN     * RCC_APBENR2_SYSCFGEN    |  /* (1 << 0)      0x00000001                                                          */\
  TIM1_EN       * RCC_APBENR2_TIM1EN      |  /* (1 << 11)     0x00000800                                                          */\
  SPI1_EN       * RCC_APBENR2_SPI1EN      |  /* (1 << 12)     0x00001000                                                          */\
  USART1_EN     * RCC_APBENR2_USART1EN    |  /* (1 << 14)     0x00004000                                                          */\
  TIM14_EN      * RCC_APBENR2_TIM14EN     |  /* (1 << 15)     0x00008000                                                          */\
  TIM16_EN      * RCC_APBENR2_TIM16EN     |  /* (1 << 17)     0x00020000                                                          */\
  TIM17_EN      * RCC_APBENR2_TIM17EN     |  /* (1 << 18)     0x00040000                                                          */\
  ADC_EN        * RCC_APBENR2_ADCEN          /* (1 << 20)     0x00100000                                                          */\
)

#if !defined(TIM2_EN)
  #define TIM2_EN 0
#endif

#if !defined(TIM3_EN)
  #define TIM3_EN 0
#endif

#if !defined(RTCAPB_EN)
  #define RTCAPB_EN 0
#endif

#if !defined(WWDG_EN)
  #define WWDG_EN 0
#endif

#if !defined(SPI2_EN)
  #define SPI2_EN 0
#endif

#if !defined(USART2_EN)
  #define USART2_EN 0
#endif

#if !defined(LPUART1_EN)
  #define LPUART1_EN 0
#endif

#if !defined(I2C1_EN)
  #define I2C1_EN 0
#endif

#if !defined(I2C2_EN)
  #define I2C2_EN 0
#endif

#if !defined(DBG_EN)
  #define DBG_EN 0
#endif

#if !defined(PWR_EN)
  #define PWR_EN 0
#endif

#if !defined(LPTIM2_EN)
  #define LPTIM2_EN 0
#endif

#if !defined(LPTIM1_EN)
  #define LPTIM1_EN 0
#endif


#define RCC_APBENR1 (                     \
  TIM2_EN       * RCC_APBENR1_TIM2EN      |  /* (1 << 0)      0x00000001                                                          */\
  TIM3_EN       * RCC_APBENR1_TIM3EN      |  /* (1 << 1)      0x00000002                                                          */\
  RTCAPB_EN     * RCC_APBENR1_RTCAPBEN    |  /* (1 << 10)     0x00000400                                                          */\
  WWDG_EN       * RCC_APBENR1_WWDGEN      |  /* (1 << 11)     0x00000800                                                          */\
  SPI2_EN       * RCC_APBENR1_SPI2EN      |  /* (1 << 14)     0x00004000                                                          */\
  USART2_EN     * RCC_APBENR1_USART2EN    |  /* (1 << 17)     0x00020000                                                          */\
  LPUART1_EN    * RCC_APBENR1_LPUART1EN   |  /* (1 << 20)     0x00100000                                                          */\
  I2C1_EN       * RCC_APBENR1_I2C1EN      |  /* (1 << 21)     0x00200000                                                          */\
  I2C2_EN       * RCC_APBENR1_I2C2EN      |  /* (1 << 22)     0x00400000                                                          */\
  DBG_EN        * RCC_APBENR1_DBGEN       |  /* (1 << 27)     0x08000000                                                          */\
  PWR_EN        * RCC_APBENR1_PWREN       |  /* (1 << 28)     0x10000000                                                          */\
  LPTIM2_EN     * RCC_APBENR1_LPTIM2EN    |  /* (1 << 30)     0x40000000                                                          */\
  LPTIM1_EN     * RCC_APBENR1_LPTIM1EN       /* (1 << 31)     0x80000000                                                          */\
)


__STATIC_FORCEINLINE void init_rcc(void) {

  /* Perform pre-configuration of the hardware */
  configure_flash();

  #if defined RCC_AHBENR
    #if RCC_AHBENR != 0
      RCC->AHBENR = RCC_AHBENR; /* 0x40021038: RCC AHB peripherals clock enable register, Address offset: 0x38                      */
    #endif
  #else
    #define RCC_AHBENR 0
  #endif

  #if defined RCC_CFGR
    #if RCC_CFGR != 0
      RCC->CFGR = RCC_CFGR; /* 0x40021008: RCC Regulated Domain Clocks Configuration Register, Address offset: 0x08            */
    #endif
  #else
    #define RCC_CFGR 0
  #endif

  #if defined RCC_CSR
    #if RCC_CSR != 0
      RCC->CSR = RCC_CSR; /* 0x40021060: RCC Unregulated Domain Clock Control and Status Register, Address offset: 0x60       */
    #endif
  #else
    #define RCC_CSR 0
  #endif

  #if defined RCC_AHBRSTR
    #if RCC_AHBRSTR != 0
      RCC->AHBRSTR = RCC_AHBRSTR; /* 0x40021028: RCC AHB peripherals reset register, Address offset: 0x28                             */
    #endif
  #else
    #define RCC_AHBRSTR 0
  #endif

  #if defined RCC_AHBSMENR
    #if RCC_AHBSMENR != 0
      RCC->AHBSMENR = RCC_AHBSMENR; /* 0x40021048: RCC AHB peripheral clocks enable in sleep mode register, Address offset: 0x48        */
    #endif
  #else
    #define RCC_AHBSMENR 0
  #endif

  #if defined RCC_APBENR1
    #if RCC_APBENR1 != 0
      RCC->APBENR1 = RCC_APBENR1; /* 0x4002103C: RCC APB peripherals clock enable register1, Address offset: 0x3C                     */
    #endif
  #else
    #define RCC_APBENR1 0
  #endif

  #if defined RCC_APBENR2
    #if RCC_APBENR2 != 0
      RCC->APBENR2 = RCC_APBENR2; /* 0x40021040: RCC APB peripherals clock enable register2, Address offset: 0x40                     */
    #endif
  #else
    #define RCC_APBENR2 0
  #endif

  #if defined RCC_APBRSTR1
    #if RCC_APBRSTR1 != 0
      RCC->APBRSTR1 = RCC_APBRSTR1; /* 0x4002102C: RCC APB peripherals reset register 1, Address offset: 0x2C                           */
    #endif
  #else
    #define RCC_APBRSTR1 0
  #endif

  #if defined RCC_APBRSTR2
    #if RCC_APBRSTR2 != 0
      RCC->APBRSTR2 = RCC_APBRSTR2; /* 0x40021030: RCC APB peripherals reset register 2, Address offset: 0x30                           */
    #endif
  #else
    #define RCC_APBRSTR2 0
  #endif

  #if defined RCC_APBSMENR1
    #if RCC_APBSMENR1 != 0
      RCC->APBSMENR1 = RCC_APBSMENR1; /* 0x4002104C: RCC APB peripheral clocks enable in sleep mode register1, Address offset: 0x4C       */
    #endif
  #else
    #define RCC_APBSMENR1 0
  #endif

  #if defined RCC_APBSMENR2
    #if RCC_APBSMENR2 != 0
      RCC->APBSMENR2 = RCC_APBSMENR2; /* 0x40021050: RCC APB peripheral clocks enable in sleep mode register2, Address offset: 0x50       */
    #endif
  #else
    #define RCC_APBSMENR2 0
  #endif

  #if defined RCC_BDCR
    #if RCC_BDCR != 0
      RCC->BDCR = RCC_BDCR; /* 0x4002105C: RCC Backup Domain Control Register, Address offset: 0x5C                             */
    #endif
  #else
    #define RCC_BDCR 0
  #endif

  #if defined RCC_CCIPR
    #if RCC_CCIPR != 0
      RCC->CCIPR = RCC_CCIPR; /* 0x40021054: RCC Peripherals Independent Clocks Configuration Register, Address offset: 0x54      */
    #endif
  #else
    #define RCC_CCIPR 0
  #endif

  #if defined RCC_CIER
    #if RCC_CIER != 0
      RCC->CIER = RCC_CIER; /* 0x40021018: RCC Clock Interrupt Enable Register, Address offset: 0x18                            */
    #endif
  #else
    #define RCC_CIER 0
  #endif

  #if defined RCC_CIFR
    #if RCC_CIFR != 0
      RCC->CIFR = RCC_CIFR; /* 0x4002101C: RCC Clock Interrupt Flag Register, Address offset: 0x1C                              */
    #endif
  #else
    #define RCC_CIFR 0
  #endif

  #if defined RCC_CICR
    #if RCC_CICR != 0
      RCC->CICR = RCC_CICR; /* 0x40021020: RCC Clock Interrupt Clear Register, Address offset: 0x20                             */
    #endif
  #else
    #define RCC_CICR 0
  #endif

  #if defined RCC_ICSCR
    #if RCC_ICSCR != 0
      RCC->ICSCR = RCC_ICSCR; /* 0x40021004: RCC Internal Clock Sources Calibration Register, Address offset: 0x04               */
    #endif
  #else
    #define RCC_ICSCR 0
  #endif

  #if defined RCC_IOPENR
    #if RCC_IOPENR != 0
      RCC->IOPENR = RCC_IOPENR; /* 0x40021034: RCC IO port enable register, Address offset: 0x34                                    */
    #endif
  #else
    #define RCC_IOPENR 0
  #endif

  #if defined RCC_IOPRSTR
    #if RCC_IOPRSTR != 0
      RCC->IOPRSTR = RCC_IOPRSTR; /* 0x40021024: RCC IO port reset register, Address offset: 0x24                                     */
    #endif
  #else
    #define RCC_IOPRSTR 0
  #endif

  #if defined RCC_IOPSMENR
    #if RCC_IOPSMENR != 0
      RCC->IOPSMENR = RCC_IOPSMENR; /* 0x40021044: RCC IO port clocks enable in sleep mode register, Address offset: 0x44               */
    #endif
  #else
    #define RCC_IOPSMENR 0
  #endif

  #if defined RCC_PLLCFGR
    #if RCC_PLLCFGR != 0
      RCC->PLLCFGR = RCC_PLLCFGR; /* 0x4002100C: RCC System PLL configuration Register, Address offset: 0x0C                          */
    #endif
  #else
    #define RCC_PLLCFGR 0
  #endif

  #if defined RCC_CR
    #if RCC_CR != 0
      RCC->CR = RCC_CR; /* 0x40021000: RCC Clock Sources Control Register, Address offset: 0x00                          */
    #endif
  #else
    #define RCC_CR 0
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
  #if (HCLK > 48)
    /* G0: 2 wait states for >48MHz */
    FLASH->ACR = FLASH_ACR_LATENCY_2;
  #elif (HCLK > 24)
    /* G0: 1 wait state for 24-48MHz */
    FLASH->ACR = FLASH_ACR_LATENCY_1;
  #endif
}

__STATIC_FORCEINLINE void wait_for_clock_stable(void) {
  #if R
    /* PLLM=1, PLLR=4 => PLL output = HSI16 * PLLN / 4 = HCLK */
    RCC->PLLCFGR = (
      RCC_PLLCFGR_PLLSRC_HSI
    | RCC_PLLCFGR_PLLM_0
    | RCC_PLLCFGR_PLLR_1
    | RCC_PLLCFGR_PLLREN
    | (PLLN_VAL << RCC_PLLCFGR_PLLN_Pos)
    );
    while(RCC_CFGR_SWS_PLLRCLK != (RCC->CFGR & RCC_CFGR_SWS)) {}
  #endif
} /* wait_for_clock_stable() */

#undef PLLN_0
#undef PLLN_1
#undef PLLN_2
#undef PLLN_3
#undef PLLN_4
#undef PLLN_5
#undef PLLN_6
#undef R


////////////////////////////////////////////////////////////////////////////////////////
//  This code was generated for the stm32g031xx microcontroller by "stm32cgen" tool.
//                          https://github.com/a5021/stm32codegen                          
//  Arguments used:
//    -l g031f8 -p RCC -m rcc -f init_rcc -D R "(HCLK >= 32)" "" PLLN_VAL "(HCLK / 4)
//    /* PLLN: HSI16/1*PLLN/4 = HCLK */" PLLN_0 "((PLLN_VAL >> 0) & 1)" PLLN_1
//    "((PLLN_VAL >> 1) & 1)" PLLN_2 "((PLLN_VAL >> 2) & 1)" PLLN_3 "((PLLN_VAL >> 3)
//    & 1)" PLLN_4 "((PLLN_VAL >> 4) & 1)" PLLN_5 "((PLLN_VAL >> 5) & 1)" PLLN_6
//    "((PLLN_VAL >> 6) & 1)" --tag-bit R PLLON HSION --tag-bit PLLN_0 PLLN_0 --tag-
//    bit PLLN_1 PLLN_1 --tag-bit PLLN_2 PLLN_2 --tag-bit PLLN_3 PLLN_3 --tag-bit
//    PLLN_4 PLLN_4 --tag-bit PLLN_5 PLLN_5 --tag-bit PLLN_6 PLLN_6 --force-inline
//    --pre-init configure_flash --post-init wait_for_clock_stable -F
//    "__STATIC_FORCEINLINE void configure_flash(void) {" -F "  #if (HCLK > 48)" -F "
//    /* G0: 2 wait states for >48MHz */" -F "    FLASH->ACR = FLASH_ACR_LATENCY_2;"
//    -F "  #elif (HCLK > 24)" -F "    /* G0: 1 wait state for 24-48MHz */" -F "
//    FLASH->ACR = FLASH_ACR_LATENCY_1;" -F "  #endif" -F } -F "" -F
//    "__STATIC_FORCEINLINE void wait_for_clock_stable(void) {" -F "  #if R" -F "
//    /* PLLM=1, PLLR=4 => PLL output = HSI16 * PLLN / 4 = HCLK */" -F "
//    RCC->PLLCFGR = (" -F "      RCC_PLLCFGR_PLLSRC_HSI" -F "    |
//    RCC_PLLCFGR_PLLM_0" -F "    | RCC_PLLCFGR_PLLR_1" -F "    | RCC_PLLCFGR_PLLREN"
//    -F "    | (PLLN_VAL << RCC_PLLCFGR_PLLN_Pos)" -F "    );" -F "
//    while(RCC_CFGR_SWS_PLLRCLK != (RCC->CFGR & RCC_CFGR_SWS)) {}" -F "  #endif" -F
//    "} /* wait_for_clock_stable() */" -F "" -F "#undef PLLN_0" -F "#undef PLLN_1" -F
//    "#undef PLLN_2" -F "#undef PLLN_3" -F "#undef PLLN_4" -F "#undef PLLN_5" -F
//    "#undef PLLN_6" -F "#undef R"
////////////////////////////////////////////////////////////////////////////////////////


#ifdef __cplusplus
  }
#endif /* __cplusplus */
#endif /* __RCC_H__ */

