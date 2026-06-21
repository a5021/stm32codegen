
#define TIM3_ARR (\
  (72 * 500)         /* (0xFFFFFFFF << 0)  actual auto-reload Value                        0xFFFFFFFF  */\
)


#define TIM3_EGR (    \
  0 * TIM_EGR_UG      |  /* (1 << 0)    Update Generation                             0x00000001  */\
  0 * TIM_EGR_CC1G    |  /* (1 << 1)    Capture/Compare 1 Generation                  0x00000002  */\
  0 * TIM_EGR_CC2G    |  /* (1 << 2)    Capture/Compare 2 Generation                  0x00000004  */\
  0 * TIM_EGR_CC3G    |  /* (1 << 3)    Capture/Compare 3 Generation                  0x00000008  */\
  0 * TIM_EGR_CC4G    |  /* (1 << 4)    Capture/Compare 4 Generation                  0x00000010  */\
  0 * TIM_EGR_COMG    |  /* (1 << 5)    Capture/Compare Control Update Generation     0x00000020  */\
  0 * TIM_EGR_TG      |  /* (1 << 6)    Trigger Generation                            0x00000040  */\
  0 * TIM_EGR_BG         /* (1 << 7)    Break Generation                              0x00000080  */\
)


#define TIM3_CR1 (  \
  1 * TIM_CR1_CEN   |  /* (1 << 0)  Counter enable                                0x00000001  */\
  0 * TIM_CR1_UDIS  |  /* (1 << 1)  Update disable                                0x00000002  */\
  0 * TIM_CR1_URS   |  /* (1 << 2)  Update request source                         0x00000004  */\
  1 * TIM_CR1_OPM   |  /* (1 << 3)  One pulse mode                                0x00000008  */\
  0 * TIM_CR1_DIR   |  /* (1 << 4)  Direction                                     0x00000010  */\
  0 * TIM_CR1_CMS   |  /* (3 << 5)  CMS[1:0] bits (Center-aligned mode selection) 0x00000060  */\
  0 * TIM_CR1_CMS_0 |  /* (1 << 5)    0x00000020                                              */\
  0 * TIM_CR1_CMS_1 |  /* (2 << 5)    0x00000040                                              */\
  0 * TIM_CR1_ARPE  |  /* (1 << 7)  Auto-reload preload enable                    0x00000080  */\
  0 * TIM_CR1_CKD   |  /* (3 << 8)  CKD[1:0] bits (clock division)                0x00000300  */\
  0 * TIM_CR1_CKD_0 |  /* (1 << 8)    0x00000100                                              */\
  0 * TIM_CR1_CKD_1    /* (2 << 8)    0x00000200                                              */\
)


#define TIM3_CCMR1 (     \
  0 * TIM_CCMR1_CC1S     |  /* (3 << 0)     CC1S[1:0] bits (Capture/Compare 1 Selection)  0x00000003  */\
  0 * TIM_CCMR1_CC1S_0   |  /* (1 << 0)       0x00000001                                              */\
  0 * TIM_CCMR1_CC1S_1   |  /* (2 << 0)       0x00000002                                              */\
  0 * TIM_CCMR1_OC1FE    |  /* (1 << 2)     Output Compare 1 Fast enable                  0x00000004  */\
  1 * TIM_CCMR1_OC1PE    |  /* (1 << 3)     Output Compare 1 Preload enable               0x00000008  */\
  0 * TIM_CCMR1_OC1M     |  /* (7 << 4)     OC1M[2:0] bits (Output Compare 1 Mode)        0x00000070  */\
  0 * TIM_CCMR1_OC1M_0   |  /* (1 << 4)       0x00000010                                              */\
  1 * TIM_CCMR1_OC1M_1   |  /* (2 << 4)       0x00000020                                              */\
  1 * TIM_CCMR1_OC1M_2   |  /* (4 << 4)       0x00000040                                              */\
  0 * TIM_CCMR1_OC1CE    |  /* (1 << 7)     Output Compare 1Clear Enable                  0x00000080  */\
  0 * TIM_CCMR1_CC2S     |  /* (3 << 8)     CC2S[1:0] bits (Capture/Compare 2 Selection)  0x00000300  */\
  1 * TIM_CCMR1_CC2S_0   |  /* (1 << 8)       0x00000100                                              */\
  0 * TIM_CCMR1_CC2S_1   |  /* (2 << 8)       0x00000200                                              */\
  0 * TIM_CCMR1_OC2FE    |  /* (1 << 10)    Output Compare 2 Fast enable                  0x00000400  */\
  0 * TIM_CCMR1_OC2PE    |  /* (1 << 11)    Output Compare 2 Preload enable               0x00000800  */\
  0 * TIM_CCMR1_OC2M     |  /* (7 << 12)    OC2M[2:0] bits (Output Compare 2 Mode)        0x00007000  */\
  0 * TIM_CCMR1_OC2M_0   |  /* (1 << 12)      0x00001000                                              */\
  0 * TIM_CCMR1_OC2M_1   |  /* (2 << 12)      0x00002000                                              */\
  0 * TIM_CCMR1_OC2M_2   |  /* (4 << 12)      0x00004000                                              */\
  0 * TIM_CCMR1_OC2CE    |  /* (1 << 15)    Output Compare 2 Clear Enable                 0x00008000  */\
  0 * TIM_CCMR1_IC1PSC   |  /* (3 << 2)     IC1PSC[1:0] bits (Input Capture 1 Prescaler)  0x0000000C  */\
  0 * TIM_CCMR1_IC1PSC_0 |  /* (1 << 2)       0x00000004                                              */\
  0 * TIM_CCMR1_IC1PSC_1 |  /* (2 << 2)       0x00000008                                              */\
  0 * TIM_CCMR1_IC1F     |  /* (0xF << 4)   IC1F[3:0] bits (Input Capture 1 Filter)       0x000000F0  */\
  0 * TIM_CCMR1_IC1F_0   |  /* (1 << 4)       0x00000010                                              */\
  0 * TIM_CCMR1_IC1F_1   |  /* (2 << 4)       0x00000020                                              */\
  0 * TIM_CCMR1_IC1F_2   |  /* (4 << 4)       0x00000040                                              */\
  0 * TIM_CCMR1_IC1F_3   |  /* (8 << 4)       0x00000080                                              */\
  0 * TIM_CCMR1_IC2PSC   |  /* (3 << 10)    IC2PSC[1:0] bits (Input Capture 2 Prescaler)  0x00000C00  */\
  0 * TIM_CCMR1_IC2PSC_0 |  /* (1 << 10)      0x00000400                                              */\
  0 * TIM_CCMR1_IC2PSC_1 |  /* (2 << 10)      0x00000800                                              */\
  0 * TIM_CCMR1_IC2F     |  /* (0xF << 12)  IC2F[3:0] bits (Input Capture 2 Filter)       0x0000F000  */\
  0 * TIM_CCMR1_IC2F_0   |  /* (1 << 12)      0x00001000                                              */\
  0 * TIM_CCMR1_IC2F_1   |  /* (2 << 12)      0x00002000                                              */\
  0 * TIM_CCMR1_IC2F_2   |  /* (4 << 12)      0x00004000                                              */\
  0 * TIM_CCMR1_IC2F_3      /* (8 << 12)      0x00008000                                              */\
)


#define TIM3_CCMR2 (     \
  0 * TIM_CCMR2_CC3S     |  /* (3 << 0)     CC3S[1:0] bits (Capture/Compare 3 Selection)  0x00000003  */\
  0 * TIM_CCMR2_CC3S_0   |  /* (1 << 0)       0x00000001                                              */\
  0 * TIM_CCMR2_CC3S_1   |  /* (2 << 0)       0x00000002                                              */\
  0 * TIM_CCMR2_OC3FE    |  /* (1 << 2)     Output Compare 3 Fast enable                  0x00000004  */\
  0 * TIM_CCMR2_OC3PE    |  /* (1 << 3)     Output Compare 3 Preload enable               0x00000008  */\
  0 * TIM_CCMR2_OC3M     |  /* (7 << 4)     OC3M[2:0] bits (Output Compare 3 Mode)        0x00000070  */\
  0 * TIM_CCMR2_OC3M_0   |  /* (1 << 4)       0x00000010                                              */\
  0 * TIM_CCMR2_OC3M_1   |  /* (2 << 4)       0x00000020                                              */\
  0 * TIM_CCMR2_OC3M_2   |  /* (4 << 4)       0x00000040                                              */\
  0 * TIM_CCMR2_OC3CE    |  /* (1 << 7)     Output Compare 3 Clear Enable                 0x00000080  */\
  0 * TIM_CCMR2_CC4S     |  /* (3 << 8)     CC4S[1:0] bits (Capture/Compare 4 Selection)  0x00000300  */\
  0 * TIM_CCMR2_CC4S_0   |  /* (1 << 8)       0x00000100                                              */\
  0 * TIM_CCMR2_CC4S_1   |  /* (2 << 8)       0x00000200                                              */\
  0 * TIM_CCMR2_OC4FE    |  /* (1 << 10)    Output Compare 4 Fast enable                  0x00000400  */\
  0 * TIM_CCMR2_OC4PE    |  /* (1 << 11)    Output Compare 4 Preload enable               0x00000800  */\
  0 * TIM_CCMR2_OC4M     |  /* (7 << 12)    OC4M[2:0] bits (Output Compare 4 Mode)        0x00007000  */\
  0 * TIM_CCMR2_OC4M_0   |  /* (1 << 12)      0x00001000                                              */\
  0 * TIM_CCMR2_OC4M_1   |  /* (2 << 12)      0x00002000                                              */\
  0 * TIM_CCMR2_OC4M_2   |  /* (4 << 12)      0x00004000                                              */\
  0 * TIM_CCMR2_OC4CE    |  /* (1 << 15)    Output Compare 4 Clear Enable                 0x00008000  */\
  0 * TIM_CCMR2_IC3PSC   |  /* (3 << 2)     IC3PSC[1:0] bits (Input Capture 3 Prescaler)  0x0000000C  */\
  0 * TIM_CCMR2_IC3PSC_0 |  /* (1 << 2)       0x00000004                                              */\
  0 * TIM_CCMR2_IC3PSC_1 |  /* (2 << 2)       0x00000008                                              */\
  0 * TIM_CCMR2_IC3F     |  /* (0xF << 4)   IC3F[3:0] bits (Input Capture 3 Filter)       0x000000F0  */\
  0 * TIM_CCMR2_IC3F_0   |  /* (1 << 4)       0x00000010                                              */\
  0 * TIM_CCMR2_IC3F_1   |  /* (2 << 4)       0x00000020                                              */\
  0 * TIM_CCMR2_IC3F_2   |  /* (4 << 4)       0x00000040                                              */\
  0 * TIM_CCMR2_IC3F_3   |  /* (8 << 4)       0x00000080                                              */\
  0 * TIM_CCMR2_IC4PSC   |  /* (3 << 10)    IC4PSC[1:0] bits (Input Capture 4 Prescaler)  0x00000C00  */\
  0 * TIM_CCMR2_IC4PSC_0 |  /* (1 << 10)      0x00000400                                              */\
  0 * TIM_CCMR2_IC4PSC_1 |  /* (2 << 10)      0x00000800                                              */\
  0 * TIM_CCMR2_IC4F     |  /* (0xF << 12)  IC4F[3:0] bits (Input Capture 4 Filter)       0x0000F000  */\
  0 * TIM_CCMR2_IC4F_0   |  /* (1 << 12)      0x00001000                                              */\
  0 * TIM_CCMR2_IC4F_1   |  /* (2 << 12)      0x00002000                                              */\
  0 * TIM_CCMR2_IC4F_2   |  /* (4 << 12)      0x00004000                                              */\
  0 * TIM_CCMR2_IC4F_3      /* (8 << 12)      0x00008000                                              */\
)


#define TIM3_CCER (      \
  1 * TIM_CCER_CC1E      |  /* (1 << 0)     Capture/Compare 1 output enable                 0x00000001  */\
  0 * TIM_CCER_CC1P      |  /* (1 << 1)     Capture/Compare 1 output Polarity               0x00000002  */\
  0 * TIM_CCER_CC1NE     |  /* (1 << 2)     Capture/Compare 1 Complementary output enable   0x00000004  */\
  0 * TIM_CCER_CC1NP     |  /* (1 << 3)     Capture/Compare 1 Complementary output Polarity 0x00000008  */\
  1 * TIM_CCER_CC2E      |  /* (1 << 4)     Capture/Compare 2 output enable                 0x00000010  */\
  0 * TIM_CCER_CC2P      |  /* (1 << 5)     Capture/Compare 2 output Polarity               0x00000020  */\
  0 * TIM_CCER_CC2NE     |  /* (1 << 6)     Capture/Compare 2 Complementary output enable   0x00000040  */\
  0 * TIM_CCER_CC2NP     |  /* (1 << 7)     Capture/Compare 2 Complementary output Polarity 0x00000080  */\
  0 * TIM_CCER_CC3E      |  /* (1 << 8)     Capture/Compare 3 output enable                 0x00000100  */\
  0 * TIM_CCER_CC3P      |  /* (1 << 9)     Capture/Compare 3 output Polarity               0x00000200  */\
  0 * TIM_CCER_CC3NE     |  /* (1 << 10)    Capture/Compare 3 Complementary output enable   0x00000400  */\
  0 * TIM_CCER_CC3NP     |  /* (1 << 11)    Capture/Compare 3 Complementary output Polarity 0x00000800  */\
  0 * TIM_CCER_CC4E      |  /* (1 << 12)    Capture/Compare 4 output enable                 0x00001000  */\
  0 * TIM_CCER_CC4P         /* (1 << 13)    Capture/Compare 4 output Polarity               0x00002000  */\
)


#define TIM3_SMCR (   \
  0 * TIM_SMCR_SMS    |  /* (7 << 0)    SMS[2:0] bits (Slave mode selection)          0x00000007  */\
  0 * TIM_SMCR_SMS_0  |  /* (1 << 0)      0x00000001                                              */\
  0 * TIM_SMCR_SMS_1  |  /* (2 << 0)      0x00000002                                              */\
  0 * TIM_SMCR_SMS_2  |  /* (4 << 0)      0x00000004                                              */\
  0 * TIM_SMCR_TS     |  /* (7 << 4)    TS[2:0] bits (Trigger selection)              0x00000070  */\
  0 * TIM_SMCR_TS_0   |  /* (1 << 4)      0x00000010                                              */\
  0 * TIM_SMCR_TS_1   |  /* (2 << 4)      0x00000020                                              */\
  0 * TIM_SMCR_TS_2   |  /* (4 << 4)      0x00000040                                              */\
  0 * TIM_SMCR_MSM    |  /* (1 << 7)    Master/slave mode                             0x00000080  */\
  0 * TIM_SMCR_ETF    |  /* (0xF << 8)  ETF[3:0] bits (External trigger filter)       0x00000F00  */\
  0 * TIM_SMCR_ETF_0  |  /* (1 << 8)      0x00000100                                              */\
  0 * TIM_SMCR_ETF_1  |  /* (2 << 8)      0x00000200                                              */\
  0 * TIM_SMCR_ETF_2  |  /* (4 << 8)      0x00000400                                              */\
  0 * TIM_SMCR_ETF_3  |  /* (8 << 8)      0x00000800                                              */\
  0 * TIM_SMCR_ETPS   |  /* (3 << 12)   ETPS[1:0] bits (External trigger prescaler)   0x00003000  */\
  0 * TIM_SMCR_ETPS_0 |  /* (1 << 12)     0x00001000                                              */\
  0 * TIM_SMCR_ETPS_1 |  /* (2 << 12)     0x00002000                                              */\
  0 * TIM_SMCR_ECE    |  /* (1 << 14)   External clock enable                         0x00004000  */\
  0 * TIM_SMCR_ETP       /* (1 << 15)   External trigger polarity                     0x00008000  */\
)


#define TIM3_CCR1 (\
  72                     /* (0xFFFF << 0)      Capture/Compare 1 Value                0x0000FFFF  */\
)


#define TIM3_CCR2 (\
  0 * TIM_CCR2_CCR2         /* (0xFFFF << 0)      Capture/Compare 2 Value                         0x0000FFFF  */\
)


#define TIM3_CCR3 (\
  0 * TIM_CCR3_CCR3         /* (0xFFFF << 0)      Capture/Compare 3 Value                         0x0000FFFF  */\
)


#define TIM3_CCR4 (\
  0 * TIM_CCR4_CCR4         /* (0xFFFF << 0)      Capture/Compare 4 Value                         0x0000FFFF  */\
)


#define TIM3_DCR (       \
  0 * TIM_DCR_DBA        |  /* (0x1F << 0)        DBA[4:0] bits (DMA Base Address)                0x0000001F  */\
  0 * TIM_DCR_DBA_0      |  /* (0x01 << 0)          0x00000001                                                */\
  0 * TIM_DCR_DBA_1      |  /* (0x02 << 0)          0x00000002                                                */\
  0 * TIM_DCR_DBA_2      |  /* (0x04 << 0)          0x00000004                                                */\
  0 * TIM_DCR_DBA_3      |  /* (0x08 << 0)          0x00000008                                                */\
  0 * TIM_DCR_DBA_4      |  /* (0x10 << 0)          0x00000010                                                */\
  0 * TIM_DCR_DBL        |  /* (0x1F << 8)        DBL[4:0] bits (DMA Burst Length)                0x00001F00  */\
  0 * TIM_DCR_DBL_0      |  /* (0x01 << 8)          0x00000100                                                */\
  0 * TIM_DCR_DBL_1      |  /* (0x02 << 8)          0x00000200                                                */\
  0 * TIM_DCR_DBL_2      |  /* (0x04 << 8)          0x00000400                                                */\
  0 * TIM_DCR_DBL_3      |  /* (0x08 << 8)          0x00000800                                                */\
  0 * TIM_DCR_DBL_4         /* (0x10 << 8)          0x00001000                                                */\
)


#define TIM3_DMAR (\
  0 * TIM_DMAR_DMAB         /* (0xFFFF << 0)      DMA register for burst accesses                 0x0000FFFF  */\
)


#define TIM3_OR          0000


#define TIM3_BDTR (      \
  0 * TIM_BDTR_DTG       |  /* (0xFF << 0)        DTG[0:7] bits (Dead-Time Generator set-up)      0x000000FF  */\
  0 * TIM_BDTR_DTG_0     |  /* (0x01 << 0)          0x00000001                                                */\
  0 * TIM_BDTR_DTG_1     |  /* (0x02 << 0)          0x00000002                                                */\
  0 * TIM_BDTR_DTG_2     |  /* (0x04 << 0)          0x00000004                                                */\
  0 * TIM_BDTR_DTG_3     |  /* (0x08 << 0)          0x00000008                                                */\
  0 * TIM_BDTR_DTG_4     |  /* (0x10 << 0)          0x00000010                                                */\
  0 * TIM_BDTR_DTG_5     |  /* (0x20 << 0)          0x00000020                                                */\
  0 * TIM_BDTR_DTG_6     |  /* (0x40 << 0)          0x00000040                                                */\
  0 * TIM_BDTR_DTG_7     |  /* (0x80 << 0)          0x00000080                                                */\
  0 * TIM_BDTR_LOCK      |  /* (3 << 8)           LOCK[1:0] bits (Lock Configuration)             0x00000300  */\
  0 * TIM_BDTR_LOCK_0    |  /* (1 << 8)             0x00000100                                                */\
  0 * TIM_BDTR_LOCK_1    |  /* (2 << 8)             0x00000200                                                */\
  0 * TIM_BDTR_OSSI      |  /* (1 << 10)          Off-State Selection for Idle mode               0x00000400  */\
  0 * TIM_BDTR_OSSR      |  /* (1 << 11)          Off-State Selection for Run mode                0x00000800  */\
  0 * TIM_BDTR_BKE       |  /* (1 << 12)          Break enable                                    0x00001000  */\
  0 * TIM_BDTR_BKP       |  /* (1 << 13)          Break Polarity                                  0x00002000  */\
  0 * TIM_BDTR_AOE       |  /* (1 << 14)          Automatic Output enable                         0x00004000  */\
  0 * TIM_BDTR_MOE          /* (1 << 15)          Main Output enable                              0x00008000  */\
)


#define TIM3_SR (     \
  0 * TIM_SR_UIF      |  /* (1 << 0)    Update interrupt Flag                         0x00000001  */\
  0 * TIM_SR_CC1IF    |  /* (1 << 1)    Capture/Compare 1 interrupt Flag              0x00000002  */\
  0 * TIM_SR_CC2IF    |  /* (1 << 2)    Capture/Compare 2 interrupt Flag              0x00000004  */\
  0 * TIM_SR_CC3IF    |  /* (1 << 3)    Capture/Compare 3 interrupt Flag              0x00000008  */\
  0 * TIM_SR_CC4IF    |  /* (1 << 4)    Capture/Compare 4 interrupt Flag              0x00000010  */\
  0 * TIM_SR_COMIF    |  /* (1 << 5)    COM interrupt Flag                            0x00000020  */\
  0 * TIM_SR_TIF      |  /* (1 << 6)    Trigger interrupt Flag                        0x00000040  */\
  0 * TIM_SR_BIF      |  /* (1 << 7)    Break interrupt Flag                          0x00000080  */\
  0 * TIM_SR_CC1OF    |  /* (1 << 9)    Capture/Compare 1 Overcapture Flag            0x00000200  */\
  0 * TIM_SR_CC2OF    |  /* (1 << 10)   Capture/Compare 2 Overcapture Flag            0x00000400  */\
  0 * TIM_SR_CC3OF    |  /* (1 << 11)   Capture/Compare 3 Overcapture Flag            0x00000800  */\
  0 * TIM_SR_CC4OF       /* (1 << 12)   Capture/Compare 4 Overcapture Flag            0x00001000  */\
)


#define TIM3_CNT (\
  0 * TIM_CNT_CNT           /* (0xFFFFFFFF << 0)  Counter Value                                   0xFFFFFFFF  */\
)

  #if defined TIM3_PSC
    #if TIM3_PSC != 0
      TIM3->PSC = TIM3_PSC; /* 0x40000428: TIM prescaler register, Address offset: 0x28                                      */
    #endif
  #else
    #define TIM3_PSC 0
  #endif

  #if defined TIM3_ARR
    #if TIM3_ARR != 0
      TIM3->ARR = TIM3_ARR; /* 0x4000042C: TIM auto-reload register, Address offset: 0x2C                                    */
    #endif
  #else
    #define TIM3_ARR 0
  #endif

  #if defined TIM3_EGR
    #if TIM3_EGR != 0
      TIM3->EGR = TIM3_EGR; /* 0x40000414: TIM event generation register, Address offset: 0x14                      */
    #endif
  #else
    #define TIM3_EGR 0
  #endif

  #if defined TIM3_CCMR1
    #if TIM3_CCMR1 != 0
      TIM3->CCMR1 = TIM3_CCMR1; /* 0x40000418: TIM capture/compare mode register 1, Address offset: 0x18                 */
    #endif
  #else
    #define TIM3_CCMR1 0
  #endif

  #if defined TIM3_CCMR2
    #if TIM3_CCMR2 != 0
      TIM3->CCMR2 = TIM3_CCMR2; /* 0x4000041C: TIM capture/compare mode register 2, Address offset: 0x1C                 */
    #endif
  #else
    #define TIM3_CCMR2 0
  #endif

  #if defined TIM3_CNT
    #if TIM3_CNT != 0
      TIM3->CNT = TIM3_CNT; /* 0x40000424: TIM counter register, Address offset: 0x24                                        */
    #endif
  #else
    #define TIM3_CNT 0
  #endif

  #if defined TIM3_CCR1
    #if TIM3_CCR1 != 0
      TIM3->CCR1 = TIM3_CCR1; /* 0x40000434: TIM capture/compare register 1, Address offset: 0x34                              */
    #endif
  #else
    #define TIM3_CCR1 0
  #endif

  #if defined TIM3_CCR2
    #if TIM3_CCR2 != 0
      TIM3->CCR2 = TIM3_CCR2; /* 0x40000438: TIM capture/compare register 2, Address offset: 0x38                              */
    #endif
  #else
    #define TIM3_CCR2 0
  #endif

  #if defined TIM3_CCR3
    #if TIM3_CCR3 != 0
      TIM3->CCR3 = TIM3_CCR3; /* 0x4000043C: TIM capture/compare register 3, Address offset: 0x3C                              */
    #endif
  #else
    #define TIM3_CCR3 0
  #endif

  #if defined TIM3_CCR4
    #if TIM3_CCR4 != 0
      TIM3->CCR4 = TIM3_CCR4; /* 0x40000440: TIM capture/compare register 4, Address offset: 0x40                              */
    #endif
  #else
    #define TIM3_CCR4 0
  #endif

  #if defined TIM3_CCER
    #if TIM3_CCER != 0
      TIM3->CCER = TIM3_CCER; /* 0x40000420: TIM capture/compare enable register, Address offset: 0x20                   */
    #endif
  #else
    #define TIM3_CCER 0
  #endif

  #if defined TIM3_DIER
    #if TIM3_DIER != 0
      TIM3->DIER = TIM3_DIER; /* 0x4000040C: TIM DMA/interrupt enable register, Address offset: 0x0C                  */
    #endif
  #else
    #define TIM3_DIER 0
  #endif

  #if defined TIM3_RCR
    #if TIM3_RCR != 0
      TIM3->RCR = TIM3_RCR; /* 0x40000430: TIM repetition counter register, Address offset: 0x30                             */
    #endif
  #else
    #define TIM3_RCR 0
  #endif

  #if defined TIM3_SMCR
    #if TIM3_SMCR != 0
      TIM3->SMCR = TIM3_SMCR; /* 0x40000408: TIM slave Mode Control register, Address offset: 0x08                    */
    #endif
  #else
    #define TIM3_SMCR 0
  #endif

  #if defined TIM3_SR
    #if TIM3_SR != 0
      TIM3->SR = TIM3_SR; /* 0x40000410: TIM status register, Address offset: 0x10                                */
    #endif
  #else
    #define TIM3_SR 0
  #endif

  #if defined TIM3_DCR
    #if TIM3_DCR != 0
      TIM3->DCR = TIM3_DCR; /* 0x40000448: TIM DMA control register, Address offset: 0x48                                    */
    #endif
  #else
    #define TIM3_DCR 0
  #endif

  #if defined TIM3_DMAR
    #if TIM3_DMAR != 0
      TIM3->DMAR = TIM3_DMAR; /* 0x4000044C: TIM DMA address for full transfer register, Address offset: 0x4C                  */
    #endif
  #else
    #define TIM3_DMAR 0
  #endif

  #if defined TIM3_BDTR
    #if TIM3_BDTR != 0
      TIM3->BDTR = TIM3_BDTR; /* 0x40000444: TIM break and dead-time register, Address offset: 0x44                            */
    #endif
  #else
    #define TIM3_BDTR 0
  #endif

  #if defined TIM3_OR
    #if TIM3_OR != 0
      TIM3->OR = TIM3_OR; /* 0x40000450: TIM option register, Address offset: 0x50                                         */
    #endif
  #else
    #define TIM3_OR 0
  #endif

  #if defined TIM3_CR2
    #if TIM3_CR2 != 0
      TIM3->CR2 = TIM3_CR2; /* 0x40000404: TIM control register 2, Address offset: 0x04                            */
    #endif
  #else
    #define TIM3_CR2 0
  #endif

  #if defined TIM3_CR1
    #if TIM3_CR1 != 0
      TIM3->CR1 = TIM3_CR1; /* 0x40000400: TIM control register 1, Address offset: 0x00                           */
    #endif
  #else
    #define TIM3_CR1 0
  #endif

#if 0
  NVIC_SetPriority(TIM3_IRQn, NVIC_EncodePriority(NVIC_GetPriorityGrouping(), 0, 0));
  NVIC_ClearPendingIRQ(TIM3_IRQn);
  NVIC_EnableIRQ(TIM3_IRQn);
#endif


#if (TIM3_ARR != 0) || (TIM3_BDTR != 0) || (TIM3_CCER != 0) || (TIM3_CCMR1 != 0) || (TIM3_CCMR2 != 0) || \
    (TIM3_CCR1 != 0) || (TIM3_CCR2 != 0) || (TIM3_CCR3 != 0) || (TIM3_CCR4 != 0) || (TIM3_CNT != 0) || \
    (TIM3_CR1 != 0) || (TIM3_CR2 != 0) || (TIM3_DCR != 0) || (TIM3_DIER != 0) || (TIM3_DMAR != 0) || \
    (TIM3_EGR != 0) || (TIM3_OR != 0) || (TIM3_PSC != 0) || (TIM3_RCR != 0) || (TIM3_SMCR != 0) || \
    (TIM3_SR != 0)

  #define TIM3_EN (!0)
#else
  #define TIM3_EN 0
#endif


////////////////////////////////////////////////////////////////////////////////////////
//  This code was generated for the stm32f103xb microcontroller by "stm32cgen" tool.
//                          https://github.com/a5021/stm32codegen                          
//  Arguments used: -l 103c8 -p TIM3
////////////////////////////////////////////////////////////////////////////////////////


