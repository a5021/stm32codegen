#include "main.h"

int main(void) {

  for(init();;idle());

}

__STATIC_FORCEINLINE __SYSTICK_VOLATILE uint32_t * get_uptime(void) {
  extern __SYSTICK_VOLATILE uint32_t uptime;
  return &uptime;
}

__STATIC_FORCEINLINE void set_uptime(uint32_t t) {
  extern __SYSTICK_VOLATILE uint32_t uptime;
  uptime = t;
}

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
  {
    static uint32_t cnt;
  
    if (++cnt == 1000) {
      cnt = 0;
      set_uptime(*get_uptime() + 1);
    }
  }
}

__STATIC_FORCEINLINE void idle(void) {
  /* The body of the main program loop follows here */
  
  process_systick_event();
  
} /* idle() */

__SYSTICK_VOLATILE uint32_t uptime = 0;

