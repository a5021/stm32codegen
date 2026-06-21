#define CAPTURE_BUF_LEN 72
uint16_t capture_buf[CAPTURE_BUF_LEN];

#define TIM1_PSC_VALUE 0        // No prescaler, timer runs at 72 MHz
#define TIM1_ARR_VALUE 4320     // 60 us period = 4320 ticks @72 MHz
#define TIM1_RCR_VALUE 71       // 72 pulses total
#define TIM1_CCR1_PULSE 72      // 1 us pulse width = 72 ticks

int main(void) {

  // 1. Enable DMA1 clock
  RCC->AHBENR |= RCC_AHBENR_DMA1EN;

  // 2. Disable channel before configuring
  DMA1_Channel2->CCR &= ~DMA_CCR_EN;

  // 3. Peripheral address: TIM1->CCR1
  DMA1_Channel2->CPAR = (uint32_t)&TIM1->CCR1;

  // 4. Memory address
  DMA1_Channel2->CMAR = (uint32_t)capture_buf;

  // 5. Number of transfers
  DMA1_Channel2->CNDTR = CAPTURE_BUF_LEN;

  // 6. Configure DMA channel:
  //    - Memory increment
  //    - Peripheral to memory
  //    - 16-bit transfers
  //    - No interrupts, no circular mode
  DMA1_Channel2->CCR =
      DMA_CCR_MINC     |       // Memory increment
      DMA_CCR_PSIZE_0  |       // Peripheral size: 16-bit
      DMA_CCR_MSIZE_0;         // Memory size: 16-bit

  // 7. Enable DMA request from TIM1_CH1 (capture event)
  TIM1->DIER |= TIM_DIER_CC1DE;

  // 8. Enable the DMA channel
  DMA1_Channel2->CCR |= DMA_CCR_EN;

  // Enable GPIOA and TIM1
  RCC->APB2ENR |= RCC_APB2ENR_IOPAEN | RCC_APB2ENR_TIM1EN;

  // --- Configure PA11 (CH4) as Alternate Function Push-Pull ---
  // TIM1_CH4 → PA11 → AF PP (2 MHz or more)
  GPIOA->CRH &= ~(GPIO_CRH_CNF11 | GPIO_CRH_MODE11);
  GPIOA->CRH |=  (GPIO_CRH_CNF11_1 | GPIO_CRH_MODE11_1); // AF PP, Output 2 MHz

  // --- Configure PA8 (CH1) as Floating Input (input capture) ---
  GPIOA->CRH &= ~(GPIO_CRH_CNF8 | GPIO_CRH_MODE8);
  GPIOA->CRH |=  (GPIO_CRH_CNF8_0);  // Floating input

  // --- Basic TIM1 Setup ---
  TIM1->PSC = 0;             // No prescaler: 72 MHz
  TIM1->ARR = 4320 - 1;      // 60 us period (72 MHz / 1 * 60e-6 = 4320)
  TIM1->RCR = 72 - 1;        // 72 pulses

  // --- Channel 4: PWM mode 1, active for 1 us ---
  TIM1->CCR4 = 72;           // 1 us pulse width
  TIM1->CCMR2 &= ~TIM_CCMR2_OC4M;
  TIM1->CCMR2 |= TIM_CCMR2_OC4M_1 | TIM_CCMR2_OC4M_2; // PWM mode 1
  TIM1->CCER |= TIM_CCER_CC4E;     // Enable output
  TIM1->BDTR |= TIM_BDTR_MOE;      // Main output enable

  // --- Channel 1: Input capture on rising edge ---
  TIM1->CCMR1 &= ~TIM_CCMR1_CC1S;
  TIM1->CCMR1 |= TIM_CCMR1_CC1S_0; // CC1 mapped on TI1
  TIM1->CCER &= ~(TIM_CCER_CC1P | TIM_CCER_CC1NP); // Rising edge
  TIM1->CCER |= TIM_CCER_CC1E;     // Enable input capture

  // --- Enable DMA request on Capture Compare 1 (for DMA1_CH2) ---
  TIM1->DIER |= TIM_DIER_CC1DE;

  // --- One Pulse Mode ---
  TIM1->CR1 |= TIM_CR1_OPM;

  // --- Enable counter when ready ---
  // TIM1->CR1 |= TIM_CR1_CEN; // Call this later to start}


__STATIC_FORCEINLINE unsigned read_bit(ctx *c) {

  unsigned result = 0;

  if (TIM3->SR & TIM_SR_CC2IF) {
    TIM3->SR &= ~TIM_SR_CC2IF;
    if (TIM3->CCR2 > BIT_TRESHOLD) {
      SET_MEM_BIT(c->value, c->bitcount);
    } else {
      CLEAR_MEM_BIT(c->value, c->bitcount);
    }
    c->bitcount++;
    result = !0;
  }

  return result;

}

char sp[9] = {0};
char shift_count = 0, sp_idx = 0;

__STATIC_FORCEINLINE unsigned read_bit(unsigned *c) {

    // Check if the capture flag is set
    if (TIM3->SR & TIM_SR_CC2IF) {

      // Clear the capture flag
      TIM3->SR &= ~TIM_SR_CC2IF;

      // Set or clear the corresponding bit based on the capture value
      sp[sp_idx] >>= 1;
      if(TIM3->CCR2 > BIT_THRESHOLD) sp[sp_idx] |= 0x80;

      if (++shift_count >= 8) {  
        shift_count = 0;
        if (++sp_idx >= 9) {
          

    



    return !0;
