#ifndef __TIM_H__
#define __TIM_H__

#ifdef __cplusplus
  extern "C" {
#endif

__STATIC_INLINE void init_tim(void) {

  TIM1->ARR = (               /* 0x40012C2C: TIM auto-reload register, Address offset: 0x2C                     */
    10000 - 1
  );

  TIM1->CCMR1 = (             /* 0x40012C18: TIM capture/compare mode register 1, Address offset: 0x18  */
    0 * TIM_CCMR1_CC1S     |  /* (3 << 0)     CC1S[1:0] bits (Capture/Compare 1 Selection)  0x00000003  */
    0 * TIM_CCMR1_CC1S_0   |  /* (1 << 0)       0x00000001                                              */
    0 * TIM_CCMR1_CC1S_1   |  /* (2 << 0)       0x00000002                                              */
    0 * TIM_CCMR1_OC1FE    |  /* (1 << 2)     Output Compare 1 Fast enable                  0x00000004  */
    0 * TIM_CCMR1_OC1PE    |  /* (1 << 3)     Output Compare 1 Preload enable               0x00000008  */
    0 * TIM_CCMR1_OC1M     |  /* (7 << 4)     OC1M[2:0] bits (Output Compare 1 Mode)        0x00000070  */
    0 * TIM_CCMR1_OC1M_0   |  /* (1 << 4)       0x00000010                                              */
    1 * TIM_CCMR1_OC1M_1   |  /* (2 << 4)       0x00000020                                              */
    1 * TIM_CCMR1_OC1M_2   |  /* (4 << 4)       0x00000040                                              */
    0 * TIM_CCMR1_OC1CE    |  /* (1 << 7)     Output Compare 1Clear Enable                  0x00000080  */
    0 * TIM_CCMR1_CC2S     |  /* (3 << 8)     CC2S[1:0] bits (Capture/Compare 2 Selection)  0x00000300  */
    0 * TIM_CCMR1_CC2S_0   |  /* (1 << 8)       0x00000100                                              */
    0 * TIM_CCMR1_CC2S_1   |  /* (2 << 8)       0x00000200                                              */
    0 * TIM_CCMR1_OC2FE    |  /* (1 << 10)    Output Compare 2 Fast enable                  0x00000400  */
    0 * TIM_CCMR1_OC2PE    |  /* (1 << 11)    Output Compare 2 Preload enable               0x00000800  */
    0 * TIM_CCMR1_OC2M     |  /* (7 << 12)    OC2M[2:0] bits (Output Compare 2 Mode)        0x00007000  */
    0 * TIM_CCMR1_OC2M_0   |  /* (1 << 12)      0x00001000                                              */
    0 * TIM_CCMR1_OC2M_1   |  /* (2 << 12)      0x00002000                                              */
    0 * TIM_CCMR1_OC2M_2   |  /* (4 << 12)      0x00004000                                              */
    0 * TIM_CCMR1_OC2CE    |  /* (1 << 15)    Output Compare 2 Clear Enable                 0x00008000  */
    0 * TIM_CCMR1_IC1PSC   |  /* (3 << 2)     IC1PSC[1:0] bits (Input Capture 1 Prescaler)  0x0000000C  */
    0 * TIM_CCMR1_IC1PSC_0 |  /* (1 << 2)       0x00000004                                              */
    0 * TIM_CCMR1_IC1PSC_1 |  /* (2 << 2)       0x00000008                                              */
    0 * TIM_CCMR1_IC1F     |  /* (0xF << 4)   IC1F[3:0] bits (Input Capture 1 Filter)       0x000000F0  */
    0 * TIM_CCMR1_IC1F_0   |  /* (1 << 4)       0x00000010                                              */
    0 * TIM_CCMR1_IC1F_1   |  /* (2 << 4)       0x00000020                                              */
    0 * TIM_CCMR1_IC1F_2   |  /* (4 << 4)       0x00000040                                              */
    0 * TIM_CCMR1_IC1F_3   |  /* (8 << 4)       0x00000080                                              */
    0 * TIM_CCMR1_IC2PSC   |  /* (3 << 10)    IC2PSC[1:0] bits (Input Capture 2 Prescaler)  0x00000C00  */
    0 * TIM_CCMR1_IC2PSC_0 |  /* (1 << 10)      0x00000400                                              */
    0 * TIM_CCMR1_IC2PSC_1 |  /* (2 << 10)      0x00000800                                              */
    0 * TIM_CCMR1_IC2F     |  /* (0xF << 12)  IC2F[3:0] bits (Input Capture 2 Filter)       0x0000F000  */
    0 * TIM_CCMR1_IC2F_0   |  /* (1 << 12)      0x00001000                                              */
    0 * TIM_CCMR1_IC2F_1   |  /* (2 << 12)      0x00002000                                              */
    0 * TIM_CCMR1_IC2F_2   |  /* (4 << 12)      0x00004000                                              */
    0 * TIM_CCMR1_IC2F_3      /* (8 << 12)      0x00008000                                              */
  );

  TIM1->CCMR2 = (             /* 0x40012C1C: TIM capture/compare mode register 2, Address offset: 0x1C  */
    0 * TIM_CCMR2_CC3S     |  /* (3 << 0)     CC3S[1:0] bits (Capture/Compare 3 Selection)  0x00000003  */
    0 * TIM_CCMR2_CC3S_0   |  /* (1 << 0)       0x00000001                                              */
    0 * TIM_CCMR2_CC3S_1   |  /* (2 << 0)       0x00000002                                              */
    0 * TIM_CCMR2_OC3FE    |  /* (1 << 2)     Output Compare 3 Fast enable                  0x00000004  */
    0 * TIM_CCMR2_OC3PE    |  /* (1 << 3)     Output Compare 3 Preload enable               0x00000008  */
    0 * TIM_CCMR2_OC3M     |  /* (7 << 4)     OC3M[2:0] bits (Output Compare 3 Mode)        0x00000070  */
    0 * TIM_CCMR2_OC3M_0   |  /* (1 << 4)       0x00000010                                              */
    0 * TIM_CCMR2_OC3M_1   |  /* (2 << 4)       0x00000020                                              */
    0 * TIM_CCMR2_OC3M_2   |  /* (4 << 4)       0x00000040                                              */
    0 * TIM_CCMR2_OC3CE    |  /* (1 << 7)     Output Compare 3 Clear Enable                 0x00000080  */
    0 * TIM_CCMR2_CC4S     |  /* (3 << 8)     CC4S[1:0] bits (Capture/Compare 4 Selection)  0x00000300  */
    0 * TIM_CCMR2_CC4S_0   |  /* (1 << 8)       0x00000100                                              */
    0 * TIM_CCMR2_CC4S_1   |  /* (2 << 8)       0x00000200                                              */
    0 * TIM_CCMR2_OC4FE    |  /* (1 << 10)    Output Compare 4 Fast enable                  0x00000400  */
    0 * TIM_CCMR2_OC4PE    |  /* (1 << 11)    Output Compare 4 Preload enable               0x00000800  */
    0 * TIM_CCMR2_OC4M     |  /* (7 << 12)    OC4M[2:0] bits (Output Compare 4 Mode)        0x00007000  */
    0 * TIM_CCMR2_OC4M_0   |  /* (1 << 12)      0x00001000                                              */
    1 * TIM_CCMR2_OC4M_1   |  /* (2 << 12)      0x00002000                                              */
    1 * TIM_CCMR2_OC4M_2   |  /* (4 << 12)      0x00004000                                              */
    0 * TIM_CCMR2_OC4CE    |  /* (1 << 15)    Output Compare 4 Clear Enable                 0x00008000  */
    0 * TIM_CCMR2_IC3PSC   |  /* (3 << 2)     IC3PSC[1:0] bits (Input Capture 3 Prescaler)  0x0000000C  */
    0 * TIM_CCMR2_IC3PSC_0 |  /* (1 << 2)       0x00000004                                              */
    0 * TIM_CCMR2_IC3PSC_1 |  /* (2 << 2)       0x00000008                                              */
    0 * TIM_CCMR2_IC3F     |  /* (0xF << 4)   IC3F[3:0] bits (Input Capture 3 Filter)       0x000000F0  */
    0 * TIM_CCMR2_IC3F_0   |  /* (1 << 4)       0x00000010                                              */
    0 * TIM_CCMR2_IC3F_1   |  /* (2 << 4)       0x00000020                                              */
    0 * TIM_CCMR2_IC3F_2   |  /* (4 << 4)       0x00000040                                              */
    0 * TIM_CCMR2_IC3F_3   |  /* (8 << 4)       0x00000080                                              */
    0 * TIM_CCMR2_IC4PSC   |  /* (3 << 10)    IC4PSC[1:0] bits (Input Capture 4 Prescaler)  0x00000C00  */
    0 * TIM_CCMR2_IC4PSC_0 |  /* (1 << 10)      0x00000400                                              */
    0 * TIM_CCMR2_IC4PSC_1 |  /* (2 << 10)      0x00000800                                              */
    0 * TIM_CCMR2_IC4F     |  /* (0xF << 12)  IC4F[3:0] bits (Input Capture 4 Filter)       0x0000F000  */
    0 * TIM_CCMR2_IC4F_0   |  /* (1 << 12)      0x00001000                                              */
    0 * TIM_CCMR2_IC4F_1   |  /* (2 << 12)      0x00002000                                              */
    0 * TIM_CCMR2_IC4F_2   |  /* (4 << 12)      0x00004000                                              */
    0 * TIM_CCMR2_IC4F_3      /* (8 << 12)      0x00008000                                              */
  );

  TIM1->CCR1 = (              /* 0x40012C34: TIM capture/compare register 1, Address offset: 0x34               */
    1
  );

  TIM1->CCR4 = (              /* 0x40012C40: TIM capture/compare register 4, Address offset: 0x40               */
    180
  );

  TIM1->CCER = (              /* 0x40012C20: TIM capture/compare enable register, Address offset: 0x20    */
    1 * TIM_CCER_CC1E      |  /* (1 << 0)     Capture/Compare 1 output enable                 0x00000001  */
    0 * TIM_CCER_CC1P      |  /* (1 << 1)     Capture/Compare 1 output Polarity               0x00000002  */
    0 * TIM_CCER_CC1NE     |  /* (1 << 2)     Capture/Compare 1 Complementary output enable   0x00000004  */
    0 * TIM_CCER_CC1NP     |  /* (1 << 3)     Capture/Compare 1 Complementary output Polarity 0x00000008  */
    0 * TIM_CCER_CC2E      |  /* (1 << 4)     Capture/Compare 2 output enable                 0x00000010  */
    0 * TIM_CCER_CC2P      |  /* (1 << 5)     Capture/Compare 2 output Polarity               0x00000020  */
    0 * TIM_CCER_CC2NE     |  /* (1 << 6)     Capture/Compare 2 Complementary output enable   0x00000040  */
    0 * TIM_CCER_CC2NP     |  /* (1 << 7)     Capture/Compare 2 Complementary output Polarity 0x00000080  */
    0 * TIM_CCER_CC3E      |  /* (1 << 8)     Capture/Compare 3 output enable                 0x00000100  */
    0 * TIM_CCER_CC3P      |  /* (1 << 9)     Capture/Compare 3 output Polarity               0x00000200  */
    0 * TIM_CCER_CC3NE     |  /* (1 << 10)    Capture/Compare 3 Complementary output enable   0x00000400  */
    0 * TIM_CCER_CC3NP     |  /* (1 << 11)    Capture/Compare 3 Complementary output Polarity 0x00000800  */
    1 * TIM_CCER_CC4E      |  /* (1 << 12)    Capture/Compare 4 output enable                 0x00001000  */
    0 * TIM_CCER_CC4P      |  /* (1 << 13)    Capture/Compare 4 output Polarity               0x00002000  */
    0 * TIM_CCER_CC4NP        /* (1 << 15)    Capture/Compare 4 Complementary output Polarity 0x00008000  */
  );

  TIM1->DIER = (          /* 0x40012C0C: TIM DMA/interrupt enable register, Address offset: 0x0C  */
    0 * TIM_DIER_UIE   |  /* (1 << 0)   Update interrupt enable                       0x00000001  */
    0 * TIM_DIER_CC1IE |  /* (1 << 1)   Capture/Compare 1 interrupt enable            0x00000002  */
    0 * TIM_DIER_CC2IE |  /* (1 << 2)   Capture/Compare 2 interrupt enable            0x00000004  */
    0 * TIM_DIER_CC3IE |  /* (1 << 3)   Capture/Compare 3 interrupt enable            0x00000008  */
    0 * TIM_DIER_CC4IE |  /* (1 << 4)   Capture/Compare 4 interrupt enable            0x00000010  */
    0 * TIM_DIER_COMIE |  /* (1 << 5)   COM interrupt enable                          0x00000020  */
    0 * TIM_DIER_TIE   |  /* (1 << 6)   Trigger interrupt enable                      0x00000040  */
    0 * TIM_DIER_BIE   |  /* (1 << 7)   Break interrupt enable                        0x00000080  */
    1 * TIM_DIER_UDE   |  /* (1 << 8)   Update DMA request enable                     0x00000100  */
    0 * TIM_DIER_CC1DE |  /* (1 << 9)   Capture/Compare 1 DMA request enable          0x00000200  */
    0 * TIM_DIER_CC2DE |  /* (1 << 10)  Capture/Compare 2 DMA request enable          0x00000400  */
    0 * TIM_DIER_CC3DE |  /* (1 << 11)  Capture/Compare 3 DMA request enable          0x00000800  */
    0 * TIM_DIER_CC4DE |  /* (1 << 12)  Capture/Compare 4 DMA request enable          0x00001000  */
    0 * TIM_DIER_COMDE |  /* (1 << 13)  COM DMA request enable                        0x00002000  */
    0 * TIM_DIER_TDE      /* (1 << 14)  Trigger DMA request enable                    0x00004000  */
  );

  TIM1->RCR = (               /* 0x40012C30: TIM repetition counter register, Address offset: 0x30              */
    1
  );

  TIM1->BDTR = (              /* 0x40012C44: TIM break and dead-time register, Address offset: 0x44             */
    0 * TIM_BDTR_DTG       |  /* (0xFF << 0)        DTG[0:7] bits (Dead-Time Generator set-up)      0x000000FF  */
    0 * TIM_BDTR_DTG_0     |  /* (0x01 << 0)          0x00000001                                                */
    0 * TIM_BDTR_DTG_1     |  /* (0x02 << 0)          0x00000002                                                */
    0 * TIM_BDTR_DTG_2     |  /* (0x04 << 0)          0x00000004                                                */
    0 * TIM_BDTR_DTG_3     |  /* (0x08 << 0)          0x00000008                                                */
    0 * TIM_BDTR_DTG_4     |  /* (0x10 << 0)          0x00000010                                                */
    0 * TIM_BDTR_DTG_5     |  /* (0x20 << 0)          0x00000020                                                */
    0 * TIM_BDTR_DTG_6     |  /* (0x40 << 0)          0x00000040                                                */
    0 * TIM_BDTR_DTG_7     |  /* (0x80 << 0)          0x00000080                                                */
    0 * TIM_BDTR_LOCK      |  /* (3 << 8)           LOCK[1:0] bits (Lock Configuration)             0x00000300  */
    0 * TIM_BDTR_LOCK_0    |  /* (1 << 8)             0x00000100                                                */
    0 * TIM_BDTR_LOCK_1    |  /* (2 << 8)             0x00000200                                                */
    0 * TIM_BDTR_OSSI      |  /* (1 << 10)          Off-State Selection for Idle mode               0x00000400  */
    0 * TIM_BDTR_OSSR      |  /* (1 << 11)          Off-State Selection for Run mode                0x00000800  */
    0 * TIM_BDTR_BKE       |  /* (1 << 12)          Break enable                                    0x00001000  */
    0 * TIM_BDTR_BKP       |  /* (1 << 13)          Break Polarity                                  0x00002000  */
    0 * TIM_BDTR_AOE       |  /* (1 << 14)          Automatic Output enable                         0x00004000  */
    1 * TIM_BDTR_MOE          /* (1 << 15)          Main Output enable                              0x00008000  */
  );

  TIM1->CR1 = (          /* 0x40012C00: TIM control register 1, Address offset: 0x00            */
    1 * TIM_CR1_CEN   |  /* (1 << 0)  Counter enable                                0x00000001  */
    0 * TIM_CR1_UDIS  |  /* (1 << 1)  Update disable                                0x00000002  */
    0 * TIM_CR1_URS   |  /* (1 << 2)  Update request source                         0x00000004  */
    0 * TIM_CR1_OPM   |  /* (1 << 3)  One pulse mode                                0x00000008  */
    0 * TIM_CR1_DIR   |  /* (1 << 4)  Direction                                     0x00000010  */
    0 * TIM_CR1_CMS   |  /* (3 << 5)  CMS[1:0] bits (Center-aligned mode selection) 0x00000060  */
    1 * TIM_CR1_CMS_0 |  /* (1 << 5)    0x00000020                                              */
    0 * TIM_CR1_CMS_1 |  /* (2 << 5)    0x00000040                                              */
    0 * TIM_CR1_ARPE  |  /* (1 << 7)  Auto-reload preload enable                    0x00000080  */
    0 * TIM_CR1_CKD   |  /* (3 << 8)  CKD[1:0] bits (clock division)                0x00000300  */
    0 * TIM_CR1_CKD_0 |  /* (1 << 8)    0x00000100                                              */
    0 * TIM_CR1_CKD_1    /* (2 << 8)    0x00000200                                              */
  );

  TIM14->ARR = (              /* 0x4000202C: TIM auto-reload register, Address offset: 0x2C                     */
    2000 - 1
  );

  TIM14->CCMR1 = (            /* 0x40002018: TIM capture/compare mode register 1, Address offset: 0x18 */
    TIM_CCMR1_OC1M_1 | TIM_CCMR1_OC1M_2
  );

  TIM14->CCR1 = (             /* 0x40002034: TIM capture/compare register 1, Address offset: 0x34               */
    1000 - 1
  );

  TIM14->CCER = (             /* 0x40002020: TIM capture/compare enable register, Address offset: 0x20    */
    TIM_CCER_CC1E
  );

}

#define TIM1_EN        YES
#define TIM3_EN        NO
#define TIM6_EN        NO
#define TIM14_EN        YES
#define TIM15_EN        NO
#define TIM16_EN        NO
#define TIM17_EN        NO

#ifdef __cplusplus
  }
#endif /* __cplusplus */
#endif /* __TIM_H__ */

