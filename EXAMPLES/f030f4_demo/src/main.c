#include "main.h"
#include "stdint.h"

//#include "stm32f0xx.h"  // STM32F0xx header

/**
  * @brief TIM1 Control Register 1 (TIM1_CR1) structure definition
  * @details This union provides type-safe access to the TIM1 control register bits.
  *          It exactly mirrors the hardware register layout described in the STM32
  *          reference manual (RM0360 section 13.4.1 for STM32F030xx timers).
  *          
  *          Using uint32_t ensures proper memory alignment despite the register
  *          being 16-bit, which is critical for atomic operations on Cortex-M0.
  * 
  * @note Register characteristics:
  *       - Physical size: 16 bits (using 32-bit storage for compatibility)
  *       - Bit order: Little-endian (LSB at bit position 0)
  *       - Reset state: 0x0000 (all bits cleared)
  *       - Access: Read/write (except reserved bits)
  */
typedef union {
  uint32_t r; // Combined register access for atomic operations
  struct {
    /* Bitfield layout matches hardware exactly - do not reorder */
    uint32_t CEN  : 1;  // [0]     Counter enable control
                        //         0: Timer disabled
                        //         1: Timer enabled
    uint32_t UDIS : 1;  // [1]     Update event disable
                        //         0: Update events enabled
                        //         1: Update events disabled
    uint32_t URS  : 1;  // [2]     Update request source selector
                        //         0: Any of: Counter overflow/underflow, setting UG bit, trigger event
                        //         1: Only counter overflow/underflow
    uint32_t OPM  : 1;  // [3]     One-pulse mode control
                        //         0: Continuous mode
                        //         1: One-pulse mode (stops after next update)
    uint32_t DIR  : 1;  // [4]     Counting direction
                        //         0: Upcounter (incrementing)
                        //         1: Downcounter (decrementing)
    uint32_t CMS  : 2;  // [6:5]   Counter alignment mode
                        //         00: Edge-aligned mode
                        //         01: Center-aligned mode 1
                        //         10: Center-aligned mode 2
                        //         11: Center-aligned mode 3
    uint32_t ARPE : 1;  // [7]     Auto-reload preload enable
                        //         0: ARR register not buffered
                        //         1: ARR register buffered
    uint32_t CKD  : 2;  // [9:8]   Clock division factor
                        //         00: tDTS = tCK_INT (no division)
                        //         01: tDTS = 2 × tCK_INT
                        //         10: tDTS = 4 × tCK_INT
                        //         11: Reserved
    uint32_t      : 22; // [31:10] Reserved bits - must maintain reset value
  };
} TIM1_CR1_t;


/**
  * @brief Timer instance dereference macro
  * @note Provides cleaner syntax when accessing registers through pointers
  *       Example: T1.CR1 instead of (*TIM1).CR1
  */
#define T1  (*TIM1)

/**
  * @brief Peripheral type mapping system
  * @details Creates a lookup system for peripheral base types, enabling generic
  *          register access macros to work across all TIM instances uniformly.
  *          This abstraction layer supports code reuse across the timer family.
  */
#define _PERIPHERAL_TIM1    TIM
/* [...] Additional timer instance mappings follow same pattern [...] */
#define _PERIPHERAL(NAME)   _PERIPHERAL_##NAME  // Macro concatenation helper


/**
  * @brief Type-safe register access macro
  * @note This performs a controlled cast that:
  *       - Ensures volatile access (critical for hardware registers)
  *       - Provides bitfield access through TIM1_CR1_t structure
  *       - Maintains strict type checking
  *       - Generates optimal machine code
  */
#define TIM1_CR1  (*(volatile TIM1_CR1_t*)&TIM1->CR1)


/**
  * @brief Bitfield initialization utilities
  * @{
  */
#define BIT_INIT(type, ...)        ((type){__VA_ARGS__}.r)  // Creates initialized register value from struct
#define REG_INIT(periph, reg, ...) (periph->reg = ((periph##_##reg##_t){__VA_ARGS__}.r))  // Direct register initialization
/** @} */


/**
  * @brief Initializes TIMx CR1 register through type-safe function
  * @param TIMx: Target timer peripheral (TIM1, TIM2, etc.)
  * @param config: Fully populated configuration structure
  * 
  * @note Benefits of this approach:
  *       - Atomic register update
  *       - Runtime configurability
  *       - Type safety through structure parameter
  *       - Reusable across all TIMx instances
  *       - Readable self-documenting code
  *       - Compile-time checking of valid values
  */
void init_tim_cr1(TIM_TypeDef* TIMx, TIM1_CR1_t config) {
  *(volatile TIM1_CR1_t*)&TIMx->CR1 = config;
}


// static inline void write_TIM1_CR1(uint32_t value) {
//     __asm__ volatile (
//         "LDR R1, =0x40012C00\n"  // Load TIM1_CR1 address
//         "STR %0, [R1]\n"         // Store value in TIM1->CR1
//         :                        // No output operands
//         : "r" (value)            // Input operand (%0) is 'value'
//         : "r1", "memory"         // Clobber list (R1 register is modified)
//     );
// }



static inline void write_reg(volatile uint32_t *reg, uint32_t value) {
  __asm__ volatile (
      "STR %1, [%0]\n"  // Store value (%1) at address in reg (%0)
      :                 // No output operands
      : "r" (reg), "r" (value)  // Inputs: reg (R0), value (R1)
      : "memory"        // Clobber: memory barrier (prevents optimization)
  );
}

/**
  * @brief TIM1 Configuration Demonstration
  * @details This function showcases 10 distinct methods for peripheral configuration,
  *          each demonstrating different approaches to the same task. In production,
  *          choose one consistent method based on:
  *          - Team preference
  *          - Code maintainability needs
  *          - Performance requirements
  *          - Compiler capabilities
  */
void TIM_Configuration(void) {
  
  T14.CR1 = (T14_CR1_t){
    .CEN  = 1,  // Enable timer
    .URS  = 1,  // Only overflow updates
    .UDIS = 1,  // Update Disable
    .ARPE = 1   // Buffered reload
  };  
  
  write_reg(&TIM1->CR1, (TIM1_CR1_t){.DIR=1, .CEN=1, .OPM=1}.r);  // Write 0x81 to TIM1_CR1
  
  /* METHOD 1: Traditional bitmask OR (STD Peripheral Library style)
   * Advantages:
   * - Most compact code size
   * - Minimal runtime overhead
   * - Familiar to experienced STM32 developers
   * 
   * Disadvantages:
   * - Magic numbers reduce readability
   * - Harder to maintain
   * - No compile-time checking
   */
  TIM1->CR1 = TIM_CR1_CEN | TIM_CR1_OPM;

  /* METHOD 2: Explicit bit-weighted initialization
   * Advantages:
   * - Self-documenting through comments
   * - Explicit about each bit's value
   * 
   * Disadvantages:
   * - Verbose syntax
   */
  TIM1->CR1 = (
    1 * TIM_CR1_CEN      |   /* Enable counter */
    0 * TIM_CR1_UDIS     |   /* Allow update events */
    1 * TIM_CR1_URS      |   /* Only overflow triggers update */
    0 * TIM_CR1_OPM      |   /* Continuous counting mode */
    0 * TIM_CR1_DIR      |   /* Up-counting direction */
    1 * TIM_CR1_CMS_0    |   /* Center-aligned mode 1 */
    0 * TIM_CR1_CMS_1    |
    1 * TIM_CR1_ARPE     |   /* Enable auto-reload buffering */
    1 * TIM_CR1_CKD_0    |   /* Clock division = 2 */
    0 * TIM_CR1_CKD_1
  );
  

  /* METHOD 3: Compile-time configuration macro
   * Advantages:
   * - Configuration separated from code
   * - Conditional compilation possible
   * 
   * Disadvantages:
   * - Complex preprocessor usage
   * - Harder to debug
   */
  #define TIM1_CR1_INIT  (                                                      \
    0 * TIM_CR1_CEN      |   /* Counter enable                                */\
    0 * TIM_CR1_UDIS     |   /* Update disable                                */\
    0 * TIM_CR1_URS      |   /* Update request source                         */\
    0 * TIM_CR1_OPM      |   /* One pulse mode                                */\
    0 * TIM_CR1_DIR      |   /* Direction                                     */\
                                                                                \
    0 * TIM_CR1_CMS      |   /* CMS[1:0] bits (Center-aligned mode selection) */\
    0 * TIM_CR1_CMS_0    |   /*  0x00000020                                   */\
    0 * TIM_CR1_CMS_1    |   /*  0x00000040                                   */\
                                                                                \
    0 * TIM_CR1_ARPE     |   /* Auto-reload preload enable                    */\
                                                                                \
    0 * TIM_CR1_CKD      |   /* CKD[1:0] bits (clock division)                */\
    0 * TIM_CR1_CKD_0    |   /*  0x00000100                                   */\
    0 * TIM_CR1_CKD_1        /*  0x00000200                                   */\
  )
  #if 0 != TIM1_CR1_INIT
    TIM1->CR1 = TIM1_CR1_INIT
  #endif
 
  
  /* METHOD 4: Direct bitfield member access
   * Advantages:
   * - Most explicit syntax
   * - No bitmask knowledge required
   * - Field names self-document
   * 
   * Disadvantages:
   * - Non-atomic access (multiple instructions)
   * - Larger code size
   */
  TIM1_CR1.CEN   = 1;  // Enable counter
  TIM1_CR1.UDIS  = 0;  // Allow update events
  TIM1_CR1.URS   = 1;  // Only overflow triggers update
  TIM1_CR1.OPM   = 0;  // Continuous counting mode
  TIM1_CR1.DIR   = 0;  // Up-counting direction
  TIM1_CR1.CMS   = 0;  // Edge-aligned mode
  TIM1_CR1.ARPE  = 1;  // Buffer reload register
  TIM1_CR1.CKD   = 0;  // No clock division


  /* METHOD 5: Direct structure assignment (Recommended for clarity)
   * Advantages:
   * - Clean, readable syntax
   * - Atomic register update
   * - Partial initialization supported
   * 
   * Disadvantages:
   * - Requires C99 or later
   */
  TIM1_CR1 = (TIM1_CR1_t){
    .CEN  = 1,  // Enable timer
    .URS  = 1,  // Only overflow updates
    .CMS  = 1,  // Center-aligned mode 1
    .ARPE = 1   // Buffered reload
  };  

  /* METHOD 6: Compound literal with field designators
   * Advantages:
   * - Explicit about initialized fields
   * - Good for partial configurations
   * 
   * Disadvantages:
   * - Slightly more verbose
   */
  TIM1->CR1 = (TIM1_CR1_t){
    .CEN  = 1,  // Enable counter
    .ARPE = 1,  // Enable auto-reload
    .CKD  = 1   // Clock division = 2
  }.r;
  
  
  /* METHOD 7: Full structure initialization
   * Advantages:
   * - Most explicit configuration
   * - All fields documented
   * 
   * Disadvantages:
   * - Verbose for simple cases
   */
  T1.CR1 = (TIM1_CR1_t){
    .CEN  = 1,  // Counter enabled
    .UDIS = 0,  // Update events enabled
    .URS  = 1,  // Only overflow triggers update
    .OPM  = 0,  // Continuous mode
    .DIR  = 0,  // Up-counting
    .CMS  = 2,  // Center-aligned mode 2
    .ARPE = 1,  // Auto-reload enabled
    .CKD  = 1   // Clock division = 2
  }.r;

  
  /* METHOD 8: BIT_INIT helper macro
   * Advantages:
   * - Compact yet readable
   * - Type-safe initialization
   * 
   * Disadvantages:
   * - Hidden macro complexity
   */
  TIM1->CR1 = BIT_INIT(TIM1_CR1_t,
    .CEN  = 1,  // Counter enabled
    .UDIS = 0,  // Update events enabled
    .URS  = 0,  // Any event triggers update
    .OPM  = 0,  // Continuous mode
    .DIR  = 0,  // Up-counting
    .CMS  = 1,  // Center-aligned mode 1
    .ARPE = 1,  // Auto-reload enabled
    .CKD  = 0   // No clock division
  );
  

  /* METHOD 9: Configuration macro for production
   * Advantages:
   * - Centralized configuration
   * - Easy to modify
   * 
   * Disadvantages:
   * - Requires consistent style
   */
  #define TIM1_CR1_INIT_VAL (TIM1_CR1_t){ .CEN=1, .ARPE=1, .CMS=1 }.r
  TIM1->CR1 = TIM1_CR1_INIT_VAL;
  
  
  /* METHOD 10: REG_INIT macro (Most concise)
   * Advantages:
   * - Very compact syntax
   * - Maintains type safety
   * 
   * Disadvantages:
   * - Obfuscates the actual operation
   */
  REG_INIT(TIM1, CR1,
    .CEN  = 1,  // Counter enabled
    .UDIS = 0,  // Update events enabled
    .URS  = 0,  // Any event triggers update
    .OPM  = 0,  // Continuous mode
    .DIR  = 1,  // Down-counting
    .CMS  = 3,  // Center-aligned mode 3
    .ARPE = 1,  // Auto-reload enabled
    .CKD  = 2   // Clock division = 4
  );
  
  // __asm__ volatile (
  //     "LDR r1, =0x40012C00\n"  // Load TIM1_CR1 address
  //     "MOV r0, #0x81\n"        // CEN (bit 0) and ARPE (bit 7)
  //     "STR r0, [r1]\n"         // Store in TIM1->CR1
  // );

  // write_TIM1_CR1(0x81);
  
}

int main(void) {

  // R_INIT(TIM1, CR1, .CEN=1, .OPM=1);
  TIM_Configuration();
  //configure_timer();

  for (init(); process(); idle());

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
  GPIOA->BSRR = ++*uptime() & (1 << 9) ? GPIO_BSRR_BS_4 : GPIO_BSRR_BR_4;

}


__STATIC_FORCEINLINE void idle(void) {
  /* Routine to handle idle state (waiting for an event) */
  
  process_systick_event();
  
} /* idle() */


__STATIC_FORCEINLINE unsigned process(void) {
  /* Routine to perform main loop operations */
  
  return !0;
  
} /* process() */


__SYSTICK_VOLATILE uint64_t system_uptime = 0;

