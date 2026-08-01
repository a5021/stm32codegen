"""Tests for pure helper functions in stm32cgen.py and stm32cmsis.py.

These functions take simple inputs and produce deterministic outputs with no
side effects — ideal unit-test targets.
"""

import pytest

import stm32cgen as sc
import stm32cmsis
from tests.conftest import make_mock_args


# --------------------------------------------------------------------------- #
#  strip_suffix — remove trailing digits from peripheral names
# --------------------------------------------------------------------------- #

class TestStripSuffix:
    @pytest.mark.parametrize("name,expected", [
        ("TIM2", "TIM"),
        ("TIM10", "TIM"),
        ("TIM101", "TIM"),
        ("GPIOC", "GPIO"),
        ("GPIOA", "GPIO"),
        ("USART1", "USART"),
        ("USART3", "USART"),
        ("ADC1", "ADC"),
        ("SPI2", "SPI"),
        ("I2C1", "I2C"),
        ("RCC", "RCC"),         # no digits → unchanged
        ("GPIO", "GPIO"),       # stops at GPIO to avoid stripping below
        ("TIM", "TIM"),         # no trailing digits → unchanged
        ("USB_OTG_FS", "USB_OTG_FS"),  # no trailing digits, not GPIO → unchanged
    ])
    def test_strip_suffix(self, name, expected):
        assert sc.strip_suffix(name) == expected

    def test_gpio_stops_correctly(self):
        """'GPIO' should not be stripped to just 'G' — the while loop checks
        ``pn[:-1] == 'GPIO'``."""
        assert sc.strip_suffix("GPIOC") == "GPIO"


# --------------------------------------------------------------------------- #
#  is_hex
# --------------------------------------------------------------------------- #

class TestIsHex:
    @pytest.mark.parametrize("s,expected", [
        ("0x40000000", True),
        ("0x40010000", True),
        ("0xDEADBEEF", True),
        ("0x0", True),
        ("0xFF", True),
        ("0x08000000", True),
        ("TIM2", False),
        ("0x", False),         # not valid hex
        ("123", True),         # 123 is valid hex (0x123)
        ("", False),
        ("GGGG", False),
    ])
    def test_is_hex(self, s, expected):
        assert sc.is_hex(s) == expected


# --------------------------------------------------------------------------- #
#  is_num_ended
# --------------------------------------------------------------------------- #

class TestIsNumEnded:
    @pytest.mark.parametrize("s,expected", [
        ("TIM_CR1_CEN_1", ("TIM_CR1_CEN_", "1")),
        ("GPIOA_MODER_MODE0", ("GPIOA_MODER_MODE", "0")),
        ("TIM2", ("TIM", "2")),
        ("NO_DIGITS", ("NO_DIGITS", "")),
        ("123", ("", "123")),
        ("", ("", "")),
        ("_12", ("_", "12")),
    ])
    def test_is_num_ended(self, s, expected):
        assert sc.is_num_ended(s) == expected


# --------------------------------------------------------------------------- #
#  ch_def_name — register definition name adjustments
# --------------------------------------------------------------------------- #

class TestChDefName:
    @pytest.mark.parametrize("name,expected", [
        ("RTC_BKP", "RTC_BKUP"),
        ("USB_EP0", "USB_ENP0"),
        ("USB_CNTR", "USB_CTLR"),
        ("USB_ISTR", "USB_INTSTR"),
        ("USB_FNR", "USB_FRNR"),
        ("USB_DADR", "USB_DEVADDR"),
        ("USB_BTABLE", "USB_BUFTABLE"),
        ("TIM2", "TIM2"),       # unchanged
        ("RCC_CR", "RCC_CR"),   # unchanged
    ])
    def test_ch_def_name(self, name, expected):
        assert sc.ch_def_name(name) == expected


# --------------------------------------------------------------------------- #
#  get_reg_size
# --------------------------------------------------------------------------- #

class TestGetRegSize:
    @pytest.mark.parametrize("sz,expected", [
        ("__IO uint32_t CR1", "4"),
        ("__IO uint16_t DR", "2"),
        ("__IO uint8_t SR", "1"),
        ("uint32_t", "4"),
        ("uint16_t", "2"),
        ("uint8_t", "1"),
        ("somestring", "X"),
        ("__IO uint64_t", "X"),  # not handled → 'X'
    ])
    def test_get_reg_size(self, sz, expected):
        assert sc.get_reg_size(sz) == expected


# --------------------------------------------------------------------------- #
#  make_h_module — wrapper for generated header files
# --------------------------------------------------------------------------- #

class TestMakeHModule:
    def test_basic_wrapper(self):
        body = "void foo(void);"
        result = sc.make_h_module("gpio", body)
        assert result.startswith("#ifndef __GPIO_H__")
        assert "#define __GPIO_H__" in result
        assert "extern \"C\"" in result
        assert "void foo(void);" in result
        assert "#endif /* __GPIO_H__ */" in result

    def test_includes_cplusplus_guard(self):
        result = sc.make_h_module("test", "int x;")
        assert "#ifdef __cplusplus" in result
        assert "extern \"C\" {" in result
        assert "}" in result

    def test_empty_body(self):
        result = sc.make_h_module("empty", "")
        assert "__EMPTY_H__" in result


# --------------------------------------------------------------------------- #
#  compose_cmsis_header_file_name (in stm32cmsis.py)
# --------------------------------------------------------------------------- #

class TestComposeCmsisHeaderFileName:
    # Already partially tested in test_stm32cmsis.py, but we add more cases
    @pytest.mark.parametrize("name,expected", [
        # F1 family
        ("103c8", "stm32f103xb.h"),
        ("103rc", "stm32f103xe.h"),
        ("103xe", "stm32f103xe.h"),
        ("107rc", "stm32f107xc.h"),
        ("f103c8", "stm32f103xb.h"),
        ("stm32f103c8", "stm32f103xb.h"),

        # F0 family
        ("030f4", "stm32f030x6.h"),
        ("030c8", "stm32f030x8.h"),  # '30c8' maps to f0 '30x8' variant

        # G0 family
        ("g031f8", "stm32g031xx.h"),
        ("g031f6", "stm32g031xx.h"),

        # L4 family
        ("l412kb", "stm32l412xx.h"),

        # F4 family
        ("f407vg", "stm32f407xx.h"),
        ("407vg", "stm32f407xx.h"),
    ])
    def test_name_resolution(self, name, expected):
        assert stm32cmsis.compose_cmsis_header_file_name(name) == expected

    def test_strips_stm32_prefix(self):
        assert stm32cmsis.compose_cmsis_header_file_name("stm32f103c8") == "stm32f103xb.h"

    def test_lowercase_input(self):
        assert stm32cmsis.compose_cmsis_header_file_name("g031f8") == "stm32g031xx.h"
        assert stm32cmsis.compose_cmsis_header_file_name("f103c8") == "stm32f103xb.h"
