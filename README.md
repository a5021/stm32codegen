# STM32 Bare-Metal Code Generator

[![Build](https://github.com/a5021/stm32codegen/actions/workflows/build.yml/badge.svg)](https://github.com/a5021/stm32codegen/actions/workflows/build.yml) [![Python](https://img.shields.io/badge/Python-3.x-00A9E0)]() [![License](https://img.shields.io/badge/License-MIT-yellow)]()

**CMSIS-based initialization code generator for STM32 microcontrollers**

`stm32cgen.py` automates the generation of bare-metal peripheral initialization code for STM32 microcontrollers directly from CMSIS header files. Eliminate manual register configuration and reduce initialization errors with auto-generated, CMSIS-compliant C code for timers, UARTs, ADCs, GPIO, and other peripherals.

## Features

- **CMSIS-native code generation** – generates code using CMSIS register definitions without HAL overhead
- **Multi-peripheral support** – timers, UARTs, ADCs, GPIO, and more
- **Flexible output modes** – generate code blocks, functions, or complete header files
- **Microcontroller-aware** – extracts peripheral configurations directly from device-specific CMSIS headers
- **Bare-metal optimization** – produces minimal, hardware-level initialization code

## Quick Start

### Prerequisites

- Python 3.6 or higher
- STM32 CMSIS device headers for your target microcontroller

### Installation

```
git clone https://github.com/a5021/stm32codegen.git
cd stm32codegen
```

### Basic Usage

Generate timer initialization code for STM32F103C8:

```
python stm32cgen.py stm32f103c8 -m tim -f init_tim -p TIM
```

This command generates an `init_tim()` function that initializes all TIM peripherals on the STM32F103C8 microcontroller

## Usage Examples

### Generate UART initialization code

```
python stm32cgen.py stm32f103c8 -m usart -f init_usart -p USART
```

### Generate ADC configuration header

```
python stm32cgen.py stm32f103c8 -m adc -o adc_config.h -p ADC
```

### Generate GPIO setup for specific ports

```
python stm32cgen.py stm32f103c8 -m gpio -f gpio_init -p GPIOA,GPIOB
```

## Command-Line Options

| Option | Description |
|--------|-------------|
| `device` | Target STM32 device (e.g., stm32f103c8, stm32f407vg) |
| `-m, --module` | Peripheral module to generate code for (tim, usart, adc, gpio, etc.) |
| `-f, --function` | Function name for generated initialization code |
| `-p, --peripheral` | Specific peripheral instances to include (e.g., TIM1, USART2) |
| `-o, --output` | Output file name (default: stdout) |
| `-h, --help` | Display help message |

## How It Works

The generator parses CMSIS device header files to extract peripheral register structures and base addresses. It then produces initialization code using direct register access patterns optimized for bare-metal embedded systems. The generated code follows CMSIS naming conventions and register access semantics.

## Supported Microcontrollers

The tool supports any STM32 family with CMSIS headers, including:

- STM32F0 series
- STM32F1 series (F103, F105, F107)
- STM32F2 series
- STM32F3 series
- STM32F4 series (F401, F407, F429, etc.)
- STM32F7 series
- STM32L0/L1/L4 series
- STM32H7 series

## Project Structure

```
stm32codegen/
├── stm32cmsis.py         # CMSIS module
├── stm32cgen.py          # Main code generator script
├── README.md             # This file
└── EXAMPLES/             # Usage examples
```

## Examples

`EXAMPLES/` contains shell scripts that generate complete demo projects. To set up an example:

```
cd EXAMPLES
bash <script_name>.sh
```

The script uses `stm32cgen.py` to generate initialization code, downloads CMSIS headers from the STM32 and ARM repositories, creates a Makefile, and builds the project. The only prerequisites are Python 3 and `arm-none-eabi-gcc`.

After a successful build, flash the target with:

```
make program    # ST-LINK
make jprogram   # J-Link
```

The scripts are safe to re-run: existing source files are not overwritten (only generated headers are recreated).

## Contributing

Contributions are welcome. When submitting pull requests:

- Follow Python PEP 8 style guidelines
- Add examples for new features
- Update documentation to reflect changes
- Test with multiple STM32 device families

## License

[MIT License](LICENSE)

## Related Projects

- [CMSIS Version 5](https://arm-software.github.io/CMSIS_5/) – ARM CMSIS specification
- [STM32 CMSIS Device Headers](https://github.com/STMicroelectronics/cmsis_device_f0) – Official STM32 F0 device headers
- [STM32 CMSIS Device Headers](https://github.com/STMicroelectronics/cmsis_device_f1) – Official STM32 F1 device headers
- [STM32 CMSIS Device Headers](https://github.com/STMicroelectronics/cmsis_device_f2) – Official STM32 F2 device headers
- [STM32 CMSIS Device Headers](https://github.com/STMicroelectronics/cmsis_device_f2) – Official STM32 F3 device headers
- [STM32 CMSIS Device Headers](https://github.com/STMicroelectronics/cmsis_device_f4) – Official STM32 F4 device headers
- [STM32 CMSIS Device Headers](https://github.com/STMicroelectronics/cmsis_device_f7) – Official STM32 F7 device headers
- [STM32 CMSIS Device Headers](https://github.com/STMicroelectronics/cmsis_device_g0) – Official STM32 G0 device headers
- [STM32 CMSIS Device Headers](https://github.com/STMicroelectronics/cmsis_device_g4) – Official STM32 G4 device headers
- [STM32 CMSIS Device Headers](https://github.com/STMicroelectronics/cmsis_device_h5) – Official STM32 H5 device headers
- [STM32 CMSIS Device Headers](https://github.com/STMicroelectronics/cmsis_device_h7) – Official STM32 H7 device headers
- [STM32 CMSIS Device Headers](https://github.com/STMicroelectronics/cmsis_device_l0) – Official STM32 L0 device headers
- [STM32 CMSIS Device Headers](https://github.com/STMicroelectronics/cmsis_device_l1) – Official STM32 L1 device headers
- [STM32 CMSIS Device Headers](https://github.com/STMicroelectronics/cmsis_device_l4) – Official STM32 L4 device headers
- [STM32 CMSIS Device Headers](https://github.com/STMicroelectronics/cmsis_device_l5) – Official STM32 L5 device headers
- [STM32 CMSIS Device Headers](https://github.com/STMicroelectronics/cmsis_device_u4) – Official STM32 U4 device headers
- [STM32 CMSIS Device Headers](https://github.com/STMicroelectronics/cmsis_device_u5) – Official STM32 U5 device headers

## Support

For issues, feature requests, or questions, please open an issue on the [GitHub repository](https://github.com/a5021/stm32codegen).

---

**Note:** This tool generates initialization templates. Always review and customize the generated code according to your specific application requirements and hardware configuration.
