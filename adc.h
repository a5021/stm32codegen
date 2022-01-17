#ifndef __ADC_H__
#define __ADC_H__

#ifdef __cplusplus
  extern "C" {
#endif

#define ADC1_CR (     \
  0 * ADC_CR_ADEN     |  /* (1 << 0)    ADC enable                                              0x00000001  */\
  0 * ADC_CR_ADDIS    |  /* (1 << 1)    ADC disable                                             0x00000002  */\
  0 * ADC_CR_ADSTART  |  /* (1 << 2)    ADC group regular conversion start                      0x00000004  */\
  0 * ADC_CR_ADSTP    |  /* (1 << 4)    ADC group regular conversion stop                       0x00000010  */\
  0 * ADC_CR_ADCAL       /* (1 << 31)   ADC calibration                                         0x80000000  */\
)

#define ADC1_CFGR1 (     \
  0 * ADC_CFGR1_DMAEN    |  /* (1 << 0)        ADC DMA transfer enable                                           0x00000001  */\
  0 * ADC_CFGR1_DMACFG   |  /* (1 << 1)        ADC DMA transfer configuration                                    0x00000002  */\
  0 * ADC_CFGR1_SCANDIR  |  /* (1 << 2)        ADC group regular sequencer scan direction                        0x00000004  */\
  0 * ADC_CFGR1_RES      |  /* (3 << 3)        ADC data resolution                                               0x00000018  */\
  0 * ADC_CFGR1_RES_0    |  /* (1 << 3)          0x00000008                                                                  */\
  0 * ADC_CFGR1_RES_1    |  /* (2 << 3)          0x00000010                                                                  */\
  0 * ADC_CFGR1_ALIGN    |  /* (1 << 5)        ADC data alignement                                               0x00000020  */\
  0 * ADC_CFGR1_EXTSEL   |  /* (7 << 6)        ADC group regular external trigger source                         0x000001C0  */\
  0 * ADC_CFGR1_EXTSEL_0 |  /* (1 << 6)          0x00000040                                                                  */\
  0 * ADC_CFGR1_EXTSEL_1 |  /* (2 << 6)          0x00000080                                                                  */\
  0 * ADC_CFGR1_EXTSEL_2 |  /* (4 << 6)          0x00000100                                                                  */\
  0 * ADC_CFGR1_EXTEN    |  /* (3 << 10)       ADC group regular external trigger polarity                       0x00000C00  */\
  0 * ADC_CFGR1_EXTEN_0  |  /* (1 << 10)         0x00000400                                                                  */\
  0 * ADC_CFGR1_EXTEN_1  |  /* (2 << 10)         0x00000800                                                                  */\
  0 * ADC_CFGR1_OVRMOD   |  /* (1 << 12)       ADC group regular overrun configuration                           0x00001000  */\
  0 * ADC_CFGR1_CONT     |  /* (1 << 13)       ADC group regular continuous conversion mode                      0x00002000  */\
  0 * ADC_CFGR1_WAIT     |  /* (1 << 14)       ADC low power auto wait                                           0x00004000  */\
  0 * ADC_CFGR1_AUTOFF   |  /* (1 << 15)       ADC low power auto power off                                      0x00008000  */\
  0 * ADC_CFGR1_DISCEN   |  /* (1 << 16)       ADC group regular sequencer discontinuous mode                    0x00010000  */\
  0 * ADC_CFGR1_AWD1SGL  |  /* (1 << 22)       ADC analog watchdog 1 monitoring a single channel or all channels 0x00400000  */\
  0 * ADC_CFGR1_AWD1EN   |  /* (1 << 23)       ADC analog watchdog 1 enable on scope ADC group regular           0x00800000  */\
  0 * ADC_CFGR1_AWD1CH   |  /* (0x1F << 26)    ADC analog watchdog 1 monitored channel selection                 0x7C000000  */\
  0 * ADC_CFGR1_AWD1CH_0 |  /* (0x01 << 26)      0x04000000                                                                  */\
  0 * ADC_CFGR1_AWD1CH_1 |  /* (0x02 << 26)      0x08000000                                                                  */\
  0 * ADC_CFGR1_AWD1CH_2 |  /* (0x04 << 26)      0x10000000                                                                  */\
  0 * ADC_CFGR1_AWD1CH_3 |  /* (0x08 << 26)      0x20000000                                                                  */\
  0 * ADC_CFGR1_AWD1CH_4 |  /* (0x10 << 26)      0x40000000                                                                  */\
  0 * ADC_CFGR1_AUTDLY   |  /* ((1 << 14))     0x00004000                                                                    */\
  0 * ADC_CFGR1_AWDSGL   |  /* ((1 << 22))     0x00400000                                                                    */\
  0 * ADC_CFGR1_AWDEN    |  /* ((1 << 23))     0x00800000                                                                    */\
  0 * ADC_CFGR1_AWDCH    |  /* ((0x1F << 26))  0x7C000000                                                                    */\
  0 * ADC_CFGR1_AWDCH_0  |  /* ((0x01 << 26))  0x04000000                                                                    */\
  0 * ADC_CFGR1_AWDCH_1  |  /* ((0x02 << 26))  0x08000000                                                                    */\
  0 * ADC_CFGR1_AWDCH_2  |  /* ((0x04 << 26))  0x10000000                                                                    */\
  0 * ADC_CFGR1_AWDCH_3  |  /* ((0x08 << 26))  0x20000000                                                                    */\
  0 * ADC_CFGR1_AWDCH_4     /* ((0x10 << 26))  0x40000000                                                                    */\
)

#define ADC1_CFGR2 (       \
  0 * ADC_CFGR2_CKMODE     |  /* (3 << 30)       ADC clock source and prescaler (prescaler only for clock source synchronous) 0xC0000000  */\
  0 * ADC_CFGR2_CKMODE_1   |  /* (2 << 30)         0x80000000                                                                             */\
  0 * ADC_CFGR2_CKMODE_0   |  /* (1 << 30)         0x40000000                                                                             */\
  0 * ADC_CFGR2_JITOFFDIV4 |  /* ((2 << 30))     ADC clocked by PCLK div4                                                     0x80000000  */\
  0 * ADC_CFGR2_JITOFFDIV2    /* ((1 << 30))     ADC clocked by PCLK div2                                                     0x40000000  */\
)

#define ADC1_CHSELR (      \
  0 * ADC_CHSELR_CHSEL     |  /* (0x7FFFF << 0)   ADC group regular sequencer channels, available when ADC_CFGR1_CHSELRMOD is reset   0x0007FFFF  */\
  0 * ADC_CHSELR_CHSEL18   |  /* (1 << 18)        ADC group regular sequencer channel 18, available when ADC_CFGR1_CHSELRMOD is reset 0x00040000  */\
  0 * ADC_CHSELR_CHSEL17   |  /* (1 << 17)        ADC group regular sequencer channel 17, available when ADC_CFGR1_CHSELRMOD is reset 0x00020000  */\
  0 * ADC_CHSELR_CHSEL16   |  /* (1 << 16)        ADC group regular sequencer channel 16, available when ADC_CFGR1_CHSELRMOD is reset 0x00010000  */\
  0 * ADC_CHSELR_CHSEL15   |  /* (1 << 15)        ADC group regular sequencer channel 15, available when ADC_CFGR1_CHSELRMOD is reset 0x00008000  */\
  0 * ADC_CHSELR_CHSEL14   |  /* (1 << 14)        ADC group regular sequencer channel 14, available when ADC_CFGR1_CHSELRMOD is reset 0x00004000  */\
  0 * ADC_CHSELR_CHSEL13   |  /* (1 << 13)        ADC group regular sequencer channel 13, available when ADC_CFGR1_CHSELRMOD is reset 0x00002000  */\
  0 * ADC_CHSELR_CHSEL12   |  /* (1 << 12)        ADC group regular sequencer channel 12, available when ADC_CFGR1_CHSELRMOD is reset 0x00001000  */\
  0 * ADC_CHSELR_CHSEL11   |  /* (1 << 11)        ADC group regular sequencer channel 11, available when ADC_CFGR1_CHSELRMOD is reset 0x00000800  */\
  0 * ADC_CHSELR_CHSEL10   |  /* (1 << 10)        ADC group regular sequencer channel 10, available when ADC_CFGR1_CHSELRMOD is reset 0x00000400  */\
  0 * ADC_CHSELR_CHSEL9    |  /* (1 << 9)         ADC group regular sequencer channel 9, available when ADC_CFGR1_CHSELRMOD is reset  0x00000200  */\
  0 * ADC_CHSELR_CHSEL8    |  /* (1 << 8)         ADC group regular sequencer channel 8, available when ADC_CFGR1_CHSELRMOD is reset  0x00000100  */\
  0 * ADC_CHSELR_CHSEL7    |  /* (1 << 7)         ADC group regular sequencer channel 7, available when ADC_CFGR1_CHSELRMOD is reset  0x00000080  */\
  0 * ADC_CHSELR_CHSEL6    |  /* (1 << 6)         ADC group regular sequencer channel 6, available when ADC_CFGR1_CHSELRMOD is reset  0x00000040  */\
  0 * ADC_CHSELR_CHSEL5    |  /* (1 << 5)         ADC group regular sequencer channel 5, available when ADC_CFGR1_CHSELRMOD is reset  0x00000020  */\
  0 * ADC_CHSELR_CHSEL4    |  /* (1 << 4)         ADC group regular sequencer channel 4, available when ADC_CFGR1_CHSELRMOD is reset  0x00000010  */\
  0 * ADC_CHSELR_CHSEL3    |  /* (1 << 3)         ADC group regular sequencer channel 3, available when ADC_CFGR1_CHSELRMOD is reset  0x00000008  */\
  0 * ADC_CHSELR_CHSEL2    |  /* (1 << 2)         ADC group regular sequencer channel 2, available when ADC_CFGR1_CHSELRMOD is reset  0x00000004  */\
  0 * ADC_CHSELR_CHSEL1    |  /* (1 << 1)         ADC group regular sequencer channel 1, available when ADC_CFGR1_CHSELRMOD is reset  0x00000002  */\
  0 * ADC_CHSELR_CHSEL0       /* (1 << 0)         ADC group regular sequencer channel 0, available when ADC_CFGR1_CHSELRMOD is reset  0x00000001  */\
)

#define ADC1_COMMON_CCR 0000

#define ADC1_DR (          \
  0 * ADC_DR_DATA          |  /* (0xFFFF << 0)    ADC group regular conversion data                                                   0x0000FFFF  */\
  0 * ADC_DR_DATA_0        |  /* (0x0001 << 0)      0x00000001                                                                                    */\
  0 * ADC_DR_DATA_1        |  /* (0x0002 << 0)      0x00000002                                                                                    */\
  0 * ADC_DR_DATA_2        |  /* (0x0004 << 0)      0x00000004                                                                                    */\
  0 * ADC_DR_DATA_3        |  /* (0x0008 << 0)      0x00000008                                                                                    */\
  0 * ADC_DR_DATA_4        |  /* (0x0010 << 0)      0x00000010                                                                                    */\
  0 * ADC_DR_DATA_5        |  /* (0x0020 << 0)      0x00000020                                                                                    */\
  0 * ADC_DR_DATA_6        |  /* (0x0040 << 0)      0x00000040                                                                                    */\
  0 * ADC_DR_DATA_7        |  /* (0x0080 << 0)      0x00000080                                                                                    */\
  0 * ADC_DR_DATA_8        |  /* (0x0100 << 0)      0x00000100                                                                                    */\
  0 * ADC_DR_DATA_9        |  /* (0x0200 << 0)      0x00000200                                                                                    */\
  0 * ADC_DR_DATA_10       |  /* (0x0400 << 0)    0x00000400                                                                                      */\
  0 * ADC_DR_DATA_11       |  /* (0x0800 << 0)    0x00000800                                                                                      */\
  0 * ADC_DR_DATA_12       |  /* (0x1000 << 0)    0x00001000                                                                                      */\
  0 * ADC_DR_DATA_13       |  /* (0x2000 << 0)    0x00002000                                                                                      */\
  0 * ADC_DR_DATA_14       |  /* (0x4000 << 0)    0x00004000                                                                                      */\
  0 * ADC_DR_DATA_15          /* (0x8000 << 0)    0x00008000                                                                                      */\
)

#define ADC1_IER (    \
  0 * ADC_IER_ADRDYIE |  /* (1 << 0)    ADC ready interrupt                                     0x00000001  */\
  0 * ADC_IER_EOSMPIE |  /* (1 << 1)    ADC group regular end of sampling interrupt             0x00000002  */\
  0 * ADC_IER_EOCIE   |  /* (1 << 2)    ADC group regular end of unitary conversion interrupt   0x00000004  */\
  0 * ADC_IER_EOSIE   |  /* (1 << 3)    ADC group regular end of sequence conversions interrupt 0x00000008  */\
  0 * ADC_IER_OVRIE   |  /* (1 << 4)    ADC group regular overrun interrupt                     0x00000010  */\
  0 * ADC_IER_AWD1IE  |  /* (1 << 7)    ADC analog watchdog 1 interrupt                         0x00000080  */\
  0 * ADC_IER_AWDIE   |  /* ((1 << 7))  0x00000080                                                          */\
  0 * ADC_IER_EOSEQIE    /* ((1 << 3))  0x00000008                                                          */\
)

#define ADC1_SMPR (        \
  0 * ADC_SMPR_SMP         |  /* (7 << 0)        ADC group of channels sampling time 2                                        0x00000007  */\
  0 * ADC_SMPR_SMP_0       |  /* (1 << 0)          0x00000001                                                                             */\
  0 * ADC_SMPR_SMP_1       |  /* (2 << 0)          0x00000002                                                                             */\
  0 * ADC_SMPR_SMP_2          /* (4 << 0)          0x00000004                                                                             */\
)

#define ADC1_TR (          \
  0 * ADC_TR_HT            |  /* ((0xFFF << 16))  0x0FFF0000                                                                               */\
  0 * ADC_TR_LT               /* ((0xFFF << 0))   0x00000FFF                                                                               */\
)

#define ADC1_ISR (  \
  0 * ADC_ISR_ADRDY |  /* (1 << 0)    ADC ready flag                                     0x00000001  */\
  0 * ADC_ISR_EOSMP |  /* (1 << 1)    ADC group regular end of sampling flag             0x00000002  */\
  0 * ADC_ISR_EOC   |  /* (1 << 2)    ADC group regular end of unitary conversion flag   0x00000004  */\
  0 * ADC_ISR_EOS   |  /* (1 << 3)    ADC group regular end of sequence conversions flag 0x00000008  */\
  0 * ADC_ISR_OVR   |  /* (1 << 4)    ADC group regular overrun flag                     0x00000010  */\
  0 * ADC_ISR_AWD1  |  /* (1 << 7)    ADC analog watchdog 1 flag                         0x00000080  */\
  0 * ADC_ISR_AWD   |  /* ((1 << 7))  0x00000080                                                     */\
  0 * ADC_ISR_EOSEQ    /* ((1 << 3))  0x00000008                                                     */\
)


__STATIC_INLINE void init_adc(void) {

  #if defined ADC1_CFGR1
    #if ADC1_CFGR1 != 0
      ADC1->CFGR1 = ADC1_CFGR1; /* 0x4001240C: ADC configuration register 1, Address offset: 0x0C                                */
    #endif
  #else
    #define ADC1_CFGR1 0
  #endif

  #if defined ADC1_CFGR2
    #if ADC1_CFGR2 != 0
      ADC1->CFGR2 = ADC1_CFGR2;  /* 0x40012410: ADC configuration register 2, Address offset: 0x10                                           */
    #endif
  #else
    #define ADC1_CFGR2 0
  #endif

  #if defined ADC1_CHSELR
    #if ADC1_CHSELR != 0
      ADC1->CHSELR = ADC1_CHSELR; /* 0x40012428: ADC group regular sequencer register, Address offset: 0x28                                           */
    #endif
  #else
    #define ADC1_CHSELR 0
  #endif

  #if defined ADC1_COMMON_CCR
    #if ADC1_COMMON_CCR != 0
      ADC1_COMMON->CCR = ADC1_COMMON_CCR; /* 0x40012708: ADC common configuration register, Address offset: ADC1 base address + 0x308 */
    #endif
  #else
    #define ADC1_COMMON_CCR 0
  #endif

  #if defined ADC1_DR
    #if ADC1_DR != 0
      ADC1->DR = ADC1_DR;        /* 0x40012440: ADC group regular data register, Address offset: 0x40                                                */
    #endif
  #else
    #define ADC1_DR 0
  #endif

  #if defined ADC1_IER
    #if ADC1_IER != 0
      ADC1->IER = ADC1_IER; /* 0x40012404: ADC interrupt enable register, Address offset: 0x04                 */
    #endif
  #else
    #define ADC1_IER 0
  #endif

  #if defined ADC1_SMPR
    #if ADC1_SMPR != 0
      ADC1->SMPR = ADC1_SMPR;    /* 0x40012414: ADC sampling time register, Address offset: 0x14                                             */
    #endif
  #else
    #define ADC1_SMPR 0
  #endif

  #if defined ADC1_TR
    #if ADC1_TR != 0
      ADC1->TR = ADC1_TR;        /* 0x40012420: ADC analog watchdog 1 threshold register, Address offset: 0x20                                */
    #endif
  #else
    #define ADC1_TR 0
  #endif

  #if defined ADC1_ISR
    #if ADC1_ISR != 0
      ADC1->ISR = ADC1_ISR; /* 0x40012400: ADC interrupt and status register, Address offset: 0x00        */
    #endif
  #else
    #define ADC1_ISR 0
  #endif

  #if defined ADC1_CR
    #if ADC1_CR != 0
      ADC1->CR = ADC1_CR;   /* 0x40012408: ADC control register, Address offset: 0x08                          */
    #endif
  #else
    #define ADC1_CR 0
  #endif

}


#define ADC1_COMMON_EN ( \
  (ADC1_COMMON_CCR != 0) \
)

#define ADC1_EN ( \
  (ADC1_CFGR1 != 0) || (ADC1_CFGR2 != 0) || (ADC1_CHSELR != 0) || (ADC1_CR != 0) || (ADC1_DR != 0) || \
  (ADC1_IER != 0) || (ADC1_ISR != 0) || (ADC1_SMPR != 0) || (ADC1_TR != 0) \
)


#if 0
  #if (ADC1_COMMON_EN != 0) || (ADC1_EN != 0) 
    init_adc();
  #endif
#endif

#ifdef __cplusplus
  }
#endif /* __cplusplus */
#endif /* __ADC_H__ */

