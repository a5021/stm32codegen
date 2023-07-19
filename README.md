# STM32 Bare-Metal Code Generator

`stm32cgen.py` is a Python script for generating C code for STM32 microcontrollers from CMSIS header files.

The generated code can be used to initialize various peripherals such as timers, UARTs, and ADCs, among others. 

By running the stm32cgen.py script with specific options, you can generate different blocks of C code, functions or complete header files. 

Just try

`stm32cgen.py stm32f103c8 -m tim -f init_tim -p TIM`

to generate code that initializes all timers on an STM32F103C8 microcontroller.
