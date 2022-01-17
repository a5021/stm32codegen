#ifndef __USART_H__
#define __USART_H__

#ifdef __cplusplus
  extern "C" {
#endif

#define BUS_CLOCK 8000000
#define BAUDRATE 115200

__STATIC_INLINE void init_usart(void) {

  USART1->BRR = (                 /* 0x4001380C: USART Baud rate register, Address offset: 0x0C                */
    (BUS_CLOCK + BAUDRATE / 2) / BAUDRATE
  );

  USART1->RTOR = (                /* 0x40013814: USART Receiver Time Out register, Address offset: 0x14           */
    202  /* 0.00175 * 115200 + 1 = 202.6 */
  );

  USART1->CR2 = (              /* 0x40013804: USART Control register 2, Address offset: 0x04                */
    0 * USART_CR2_ADDM7     |  /* (1 << 4)      7-bit or 4-bit Address Detection                0x00000010  */
    0 * USART_CR2_LBCL      |  /* (1 << 8)      Last Bit Clock pulse                            0x00000100  */
    0 * USART_CR2_CPHA      |  /* (1 << 9)      Clock Phase                                     0x00000200  */
    0 * USART_CR2_CPOL      |  /* (1 << 10)     Clock Polarity                                  0x00000400  */
    0 * USART_CR2_CLKEN     |  /* (1 << 11)     Clock Enable                                    0x00000800  */
    0 * USART_CR2_STOP      |  /* (3 << 12)     STOP[1:0] bits (STOP bits)                      0x00003000  */
    0 * USART_CR2_STOP_0    |  /* (1 << 12)       0x00001000                                                */
    0 * USART_CR2_STOP_1    |  /* (2 << 12)       0x00002000                                                */
    0 * USART_CR2_SWAP      |  /* (1 << 15)     SWAP TX/RX pins                                 0x00008000  */
    0 * USART_CR2_RXINV     |  /* (1 << 16)     RX pin active level inversion                   0x00010000  */
    0 * USART_CR2_TXINV     |  /* (1 << 17)     TX pin active level inversion                   0x00020000  */
    0 * USART_CR2_DATAINV   |  /* (1 << 18)     Binary data inversion                           0x00040000  */
    0 * USART_CR2_MSBFIRST  |  /* (1 << 19)     Most Significant Bit First                      0x00080000  */
    0 * USART_CR2_ABREN     |  /* (1 << 20)     Auto Baud-Rate Enable                           0x00100000  */
    0 * USART_CR2_ABRMODE   |  /* (3 << 21)     ABRMOD[1:0] bits (Auto Baud-Rate Mode)          0x00600000  */
    0 * USART_CR2_ABRMODE_0 |  /* (1 << 21)       0x00200000                                                */
    0 * USART_CR2_ABRMODE_1 |  /* (2 << 21)       0x00400000                                                */
    0 * USART_CR2_RTOEN     |  /* (1 << 23)     Receiver Time-Out enable                        0x00800000  */
    0 * USART_CR2_ADD          /* (0xFF << 24)  Address of the USART node                       0xFF000000  */
  );

  USART1->CR3 = (              /* 0x40013808: USART Control register 3, Address offset: 0x08                */
    0 * USART_CR3_EIE       |  /* (1 << 0)      Error Interrupt Enable                          0x00000001  */
    0 * USART_CR3_HDSEL     |  /* (1 << 3)      Half-Duplex Selection                           0x00000008  */
    1 * USART_CR3_DMAR      |  /* (1 << 6)      DMA Enable Receiver                             0x00000040  */
    1 * USART_CR3_DMAT      |  /* (1 << 7)      DMA Enable Transmitter                          0x00000080  */
    0 * USART_CR3_RTSE      |  /* (1 << 8)      RTS Enable                                      0x00000100  */
    0 * USART_CR3_CTSE      |  /* (1 << 9)      CTS Enable                                      0x00000200  */
    0 * USART_CR3_CTSIE     |  /* (1 << 10)     CTS Interrupt Enable                            0x00000400  */
    0 * USART_CR3_ONEBIT    |  /* (1 << 11)     One sample bit method enable                    0x00000800  */
    0 * USART_CR3_OVRDIS    |  /* (1 << 12)     Overrun Disable                                 0x00001000  */
    0 * USART_CR3_DDRE      |  /* (1 << 13)     DMA Disable on Reception Error                  0x00002000  */
    1 * USART_CR3_DEM       |  /* (1 << 14)     Driver Enable Mode                              0x00004000  */
    0 * USART_CR3_DEP          /* (1 << 15)     Driver Enable Polarity Selection                0x00008000  */
  );

  USART1->CR1 = (           /* 0x40013800: USART Control register 1, Address offset: 0x00                */
    1 * USART_CR1_UE     |  /* (1 << 0)      USART Enable                                    0x00000001  */
    1 * USART_CR1_RE     |  /* (1 << 2)      Receiver Enable                                 0x00000004  */
    1 * USART_CR1_TE     |  /* (1 << 3)      Transmitter Enable                              0x00000008  */
    0 * USART_CR1_IDLEIE |  /* (1 << 4)      IDLE Interrupt Enable                           0x00000010  */
    0 * USART_CR1_RXNEIE |  /* (1 << 5)      RXNE Interrupt Enable                           0x00000020  */
    0 * USART_CR1_TCIE   |  /* (1 << 6)      Transmission Complete Interrupt Enable          0x00000040  */
    0 * USART_CR1_TXEIE  |  /* (1 << 7)      TXE Interrupt Enable                            0x00000080  */
    0 * USART_CR1_PEIE   |  /* (1 << 8)      PE Interrupt Enable                             0x00000100  */
    0 * USART_CR1_PS     |  /* (1 << 9)      Parity Selection                                0x00000200  */
    0 * USART_CR1_PCE    |  /* (1 << 10)     Parity Control Enable                           0x00000400  */
    0 * USART_CR1_WAKE   |  /* (1 << 11)     Receiver Wakeup method                          0x00000800  */
    0 * USART_CR1_M      |  /* (1 << 12)     Word Length                                     0x00001000  */
    0 * USART_CR1_MME    |  /* (1 << 13)     Mute Mode Enable                                0x00002000  */
    0 * USART_CR1_CMIE   |  /* (1 << 14)     Character match interrupt enable                0x00004000  */
    0 * USART_CR1_OVER8  |  /* (1 << 15)     Oversampling by 8-bit or 16-bit mode            0x00008000  */
    0 * USART_CR1_DEDT   |  /* (0x1F << 16)  DEDT[4:0] bits (Driver Enable Deassertion Time) 0x001F0000  */
    0 * USART_CR1_DEDT_0 |  /* (0x01 << 16)    0x00010000                                                */
    0 * USART_CR1_DEDT_1 |  /* (0x02 << 16)    0x00020000                                                */
    0 * USART_CR1_DEDT_2 |  /* (0x04 << 16)    0x00040000                                                */
    0 * USART_CR1_DEDT_3 |  /* (0x08 << 16)    0x00080000                                                */
    0 * USART_CR1_DEDT_4 |  /* (0x10 << 16)    0x00100000                                                */
    0 * USART_CR1_DEAT   |  /* (0x1F << 21)  DEAT[4:0] bits (Driver Enable Assertion Time)   0x03E00000  */
    0 * USART_CR1_DEAT_0 |  /* (0x01 << 21)    0x00200000                                                */
    0 * USART_CR1_DEAT_1 |  /* (0x02 << 21)    0x00400000                                                */
    0 * USART_CR1_DEAT_2 |  /* (0x04 << 21)    0x00800000                                                */
    0 * USART_CR1_DEAT_3 |  /* (0x08 << 21)    0x01000000                                                */
    0 * USART_CR1_DEAT_4 |  /* (0x10 << 21)    0x02000000                                                */
    0 * USART_CR1_RTOIE  |  /* (1 << 26)     Receive Time Out interrupt enable               0x04000000  */
    0 * USART_CR1_EOBIE     /* (1 << 27)     End of Block interrupt enable                   0x08000000  */
  );

      /* polling idle frame Transmission                      */
    while((USART1->ISR & USART_ISR_TC) != USART_ISR_TC) { 
      /* add time out here for a robust application           */
    }                                                         
    
    USART1->ICR = USART_ICR_TCCF;    /* clear TC flag         */
  
    NVIC_SetPriority(USART1_IRQn, 0);
    NVIC_EnableIRQ(USART1_IRQn);

}

#define USART1_EN        YES
#define USART2_EN        NO

#ifdef __cplusplus
  }
#endif /* __cplusplus */
#endif /* __USART_H__ */

