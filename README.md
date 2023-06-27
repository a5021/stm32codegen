# STM32 Code Generator

`stm32cgen.py` is a Python script for generating C code for STM32 microcontrollers from CMSIS header files.

The generated code can be used to initialize various peripherals such as timers, UARTs, and ADCs, among others. 

By running the stm32cgen.py script with specific options, you can generate different blocks of C code or complete header files quickly and easily. 

For example, you could use the command 

`stm32cgen.py stm32f103c8 -m tim -f init_tim -p TIM`

to generate code that initializes all timers on an STM32F103C8 microcontroller.
