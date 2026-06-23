# CLI Reference

## Overview

```
stm32cgen.py [options] cpu_name
```

The only positional argument is the target MCU name, given in abbreviated form (e.g. `g031f8`, `030f4`, `103c8`).

---

## Peripheral Selection

### `-m`, `--module MODULE`

Peripheral module to generate code for. Typical values: `gpio`, `rcc`, `tim`, `usart`, `adc`, `i2c`, `spi`, `exti`, `dma`, etc.

```
python stm32cgen.py g031f8 -m gpio -f init_gpio -p GPIOA
```

### `-p`, `--peripheral PERIPHERAL [PERIPHERAL ...]`

Specific peripheral instance(s) to include. Multiple values are space-separated.

```
python stm32cgen.py g031f8 -m gpio -f init_gpio -p GPIOA GPIOB
```

### `-f`, `--function FUNCTION`

Name of the generated initialization function.

```
python stm32cgen.py g031f8 -m rcc -f init_rcc -p RCC
```

### `-M`, `--main-module`

Generate a `main.h` file containing an `init()` function that calls all peripheral init functions in the correct order. Use with `-D` to define project-specific macros and `-F` to add custom footer code.

```
python stm32cgen.py g031f8 -M \
    -D HCLK 16 \
    -D SYSTICK_CLOCK_SOURCE 0 \
    --post-init init_systick \
    -F "..." > inc/main.h
```

---

## Code Generation Control

### `--force-inline`

Generate `__STATIC_FORCEINLINE` functions instead of regular `void` functions. Used in all demo scripts.

### `--no-def`

Skip the definitions block. Useful when custom mode/af macros are defined manually via `-D`.

```
python stm32cgen.py g031f8 -m gpio -f init_gpio -p GPIOA --no-def
```

### `--light`

Use lightweight initialization blocks (minimal register writes).

### `--mix`

Interleave definition and initialization blocks instead of separating them.

### `-u`, `--undef`

Add `#undef` for each initialization definition at the end of the generated file.

### `-n`, `--no-macro`

Disable peripheral-specific macro generation.

### `-i`, `--indent INDENT`

Set indentation width in spaces (default: 2).

```
python stm32cgen.py g031f8 -m gpio -f init_gpio -p GPIOA -i 4
```

### `-d`, `--direct`

No predefined macros. Start from an empty macro set.

### `--strict`

Strict matching only — fail if any peripheral/register is not found in the CMSIS header.

---

## Register and Bit Control

### `-r`, `--register REGISTER [REGISTER ...]`

Process only the specified register(s). All other registers in the peripheral are skipped.

### `-x`, `--exclude-register EXCLUDE_REGISTER [EXCLUDE_REGISTER ...]`

Exclude specific register(s) from initialization. Common use: exclude read-only or lock registers.

```
python stm32cgen.py g031f8 -m gpio -f init_gpio -p GPIOA --exclude-register IDR LCKR
```

### `-I`, `--direct-init DIRECT_INIT [DIRECT_INIT ...]`

Initialize registers with literal values. Format: `REG=VALUE`.

```
python stm32cgen.py g031f8 -m gpio -f init_gpio -p GPIOA -I MODER=0xABFFFFFF
```

### `-b`, `--set-bit SET_BIT [SET_BIT ...]`

Force specific bit(s) ON in the generated initialization. Format: `REG.BIT`.

### `-t`, `--tag-bit TAG_BIT [TAG_BIT ...]`

Tag a bit with a conditional mark. The bit is only set when the corresponding mark macro is non-zero.

```
--tag-bit R PLLON HSION
```

### `-E`, `--peripheral-enable PERIPHERAL_ENABLE [PERIPHERAL_ENABLE ...]`

Add `_EN` enable macros to the generated footer. Format: `PERIPHERAL=VALUE`.

---

## Custom Content

### `-D`, `--define DEFINE [DEFINE ...]`

Add a macro definition to the generated header. Each entry is `NAME VALUE`. The value is inserted verbatim — use `\(...)` for escaped parentheses and `"..."` for strings.

```
-D HCLK "16   /* MHz */"
-D SYSTICK_CLOCK_SOURCE "0    /* 0 = HCLK/8 */"
-D "PIN_CFG(PIN, MODE)" "((MODE) << ((PIN) * 2))"
-D YES "(!NO)"
```

An empty string (`""`) as NAME inserts a blank line, useful for grouping related defines.

### `-H`, `--header HEADER`

Add raw line(s) to the header section of the generated file (before includes). Each `-H` adds one line. Use `\#` for literal `#` preprocessor directives.

```
-H "#if HCLK < 16 || HCLK > 64 || (HCLK % 4 != 0)"
-H "  #error \"Invalid HCLK\""
-H \#endif
```

### `-F`, `--footer FOOTER`

Add raw line(s) to the footer section (after the generated init block). Use `""` for blank lines.

```
-F ""
-F "__STATIC_FORCEINLINE void init_systick(void) {"
-F "  SysTick->LOAD = HCLK * 1000 / 8 - 1;"
-F "}"
```

### `--function-header FUNCTION_HEADER [FUNCTION_HEADER ...]`

Add line(s) at the top of the generated function body.

### `--function-footer FUNCTION_FOOTER [FUNCTION_FOOTER ...]`

Add line(s) at the bottom of the generated function body.

### `--pre-init PRE_INIT`

Insert a call to `PRE_INIT()` before the generated init block. The function must be defined elsewhere.

```
--pre-init configure_flash
```

### `--post-init POST_INIT`

Insert a call to `POST_INIT()` after the generated init block.

```
--post-init init_systick
```

### `--uncomment UNCOMMENT [UNCOMMENT ...]`

Enable a commented-out `#include` directive by removing its `// ` prefix. Matches by peripheral name.

```
--uncomment USART SPI
```

---

## Device Header Handling

### `-l`, `--no-fetch`

Do not fetch the CMSIS header. Use a previously saved local copy. Speeds up repeated runs.

### `-s`, `--save-header-file`

Save the fetched CMSIS header to disk for future use with `-l`.

```
python stm32cgen.py g031f8 -s -M ... > inc/main.h
python stm32cgen.py g031f8 -l -m gpio -f init_gpio -p GPIOA > inc/gpio.h
```

### `-R`, `--disable-rcc-macro`

Disable RCC-specific clock macro generation.

---

## Other

### `-h`, `--help`

Print usage message and exit.

### `-V`, `--version`

Print version and exit.

### `-v`, `--verbose`

Verbose output — print parsed registers and generated code structure to stderr.

### `-q`, `--irq`

Generate IRQ-related register initialization.

### `--dummy DUMMY [DUMMY ...]`

Dummy parameter(s) — ignored, for compatibility with wrapper scripts.

### `--test`

Enable experimental features (use at your own risk).

---

## Typical Workflow

This is the pattern used by the demo scripts in `EXAMPLES/`:

```bash
# 1. Generate main module (always first)
python stm32cgen.py g031f8 -M \
    -D HCLK 16 \
    -D SYSTICK_CLOCK_SOURCE 0 \
    --post-init init_systick \
    -F "..." \
    > inc/main.h

# 2. Generate RCC header
python stm32cgen.py g031f8 -l \
    -p RCC -m rcc -f init_rcc \
    --pre-init configure_flash \
    --post-init wait_for_clock_stable \
    -D "..." \
    > inc/rcc.h

# 3. Generate GPIO header
python stm32cgen.py g031f8 -l \
    -p GPIOA -m gpio -f init_gpio \
    --exclude-register IDR LCKR \
    --no-def \
    -D "..." \
    > inc/gpio.h
```

The generated headers are then compiled together with a `main.c` that includes `main.h` and calls `init()`.
