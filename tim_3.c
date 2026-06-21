void tim3_init(void) {
    // 1. Enable clocks
    R.APB1ENR |= RCC_APB1ENR(TIM3EN);     // Enable TIM3 clock
    R.APB2ENR |= RCC_APB2ENR(IOPAEN);     // Enable GPIOA clock
    A.MAPR    &= ~AFIO_MAPR(TIM3_REMAP);  // No remap → CH1 = PA6, CH2 = PA7

    // 2. Configure PA6 as alternate function open-drain output (CH1)
    PA.CRL &= ~GPIO_CRL(MODE6, CNF6);
    PA.CRL |=  GPIO_CRL(MODE6_1, MODE6_0);// Output mode: 50 MHz
    PA.CRL |=  GPIO_CRL(CNF6_1);          // CNF = 10 → AF Open-Drain

    // 3. Configure TIM3 Channel 1 for PWM Mode 1
    T3.CR1  = TIM_CR1(OPM, ARPE);         // One pulse mode, ARR preload
    T3.PSC  = 0;                          // Prescaler = 0 → 72 MHz
    T3.ARR  = 4319;                       // 60 µs → ARR = 72 * 60 - 1
    T3.CCR1 = 72;                         // 1 µs low → CCR1 = 72 * 1

    T3.CCMR1 &= ~TIM_CCMR1(OC1M);
    T3.CCMR1 |= TIM_CCMR1(OC1M_1, OC1M_2); // PWM Mode 1 (OC1M = 110)
    T3.CCMR1 |= TIM_CCMR1(OC1PE);          // Enable preload for CCR1
                                          
    T3.CCER |= TIM_CCER(CC1E);             // Enable output on CH1
    T3.EGR  |= TIM_EGR(UG);                // Force update to load registers

    // Timer is now ready. Start with: TIM3->CR1 |= TIM_CR1_CEN;
}
