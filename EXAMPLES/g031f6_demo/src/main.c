#include "main.h"


int main(void) {

  for(init();;idle());

}


__STATIC_FORCEINLINE __SYSTICK_VOLATILE uint64_t * uptime(void) {
  extern __SYSTICK_VOLATILE uint64_t system_uptime;
  return &system_uptime;
}


/* a trick to use the same code in function and interrupt service routine */
#if YES == SYSTICK_IRQ_EN

__STATIC_FORCEINLINE void process_systick_event(void) {}
void SysTick_Handler(void);
void SysTick_Handler(void) {

#else

__STATIC_FORCEINLINE void process_systick_event(void) {
  if (0 == (SysTick->CTRL & SysTick_CTRL_COUNTFLAG_Msk)) {
    return;
  }
  
#endif

  /* ### Share code between a regular function and an interrupt service routine ### */

  /* This line implements a simple blink function + uptime counting */
  // GPIOB->BSRR = ++*uptime() & (1 << 9) ? GPIO_BSRR_BS0 : GPIO_BSRR_BR0;
  GPIOB->BSRR = ++*uptime() & (1 << 9) ? BS(0) : BR(0);

}


__STATIC_FORCEINLINE void idle(void) {
  /* The body of the main program loop follows here */
  
  process_systick_event();
  
} /* idle() */


__SYSTICK_VOLATILE uint64_t system_uptime = 0; /* System uptime in milliseconds */

