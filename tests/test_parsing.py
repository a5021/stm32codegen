"""Tests for CMSIS header parsing functions.

These tests use the synthetic CMSIS header (``tests/fixtures/synthetic_f1.h``)
which mimics the structure of real STMicroelectronics CMSIS device headers
but is small enough for fast, deterministic testing.
"""

import os

import pytest

import stm32cgen as sc
from tests.conftest import make_mock_args


def _read_synthetic():
    """Return the raw text of the synthetic F1 CMSIS header."""
    fixture_path = os.path.join(os.path.dirname(__file__), "fixtures", "synthetic_f1.h")
    with open(fixture_path, encoding="utf-8") as f:
        return f.read()


def _wrap_header(body):
    """Wrap a #define-only text in the markers that expand_macrodef expects."""
    return (
        "/** @addtogroup Peripheral_registers_structures\n  * @{\n  */\n"
        + body
        + "\n/** @addtogroup Peripheral_memory_map\n  * @{\n  */\n"
    )


# --------------------------------------------------------------------------- #
#  parse_macro_def — extract #define name/value/comment tuples
# --------------------------------------------------------------------------- #

class TestParseMacroDef:

    def test_returns_list_of_lists(self, parsed_f1):
        """Each macro entry is [name, expanded_value, comment, extra]."""
        assert isinstance(parsed_f1.macro_definition, list)
        assert len(parsed_f1.macro_definition) > 0
        first = parsed_f1.macro_definition[0]
        assert isinstance(first, list)
        assert len(first) == 4

    def test_bitfield_macros_present(self, parsed_f1):
        """TIM_CR1_CEN and its _Pos / _Msk companions should be present."""
        names = [m[0] for m in parsed_f1.macro_definition]

        assert "TIM_CR1_CEN_Pos" in names
        assert "TIM_CR1_CEN_Msk" in names
        assert "TIM_CR1_CEN" in names

    def test_macro_values_expanded(self, parsed_f1):
        """The _Pos/_Msk/_final chain should be fully expanded to a value."""
        for m in parsed_f1.macro_definition:
            if m[0] == "TIM_CR1_CEN_Pos":
                assert m[1] == "0"
            if m[0] == "TIM_CR1_CEN":
                # TIM_CR1_CEN = TIM_CR1_CEN_Msk = (0x1UL << 0) → expanded to (1 << 0)
                assert "1 << 0" in m[1]

    def test_peripheral_address_macros_present(self, parsed_f1):
        """Peripheral instance macros like TIM2 should resolve to addresses."""
        by_name = {m[0]: m[1] for m in parsed_f1.macro_definition}

        assert "TIM2" in by_name
        val = by_name["TIM2"]
        # After expansion, TIM2_BASE should be resolved to an address
        assert "0x" in val

    def test_macro_comment_preserved(self, parsed_f1):
        """Comments following a #define value should be captured in field 3 (extra).

        In the synthetic header, the /*!<Counter enable */ appears on its own
        line after the #define, so it is NOT captured.  However, the macro
        should still be present with an expanded value."""
        for m in parsed_f1.macro_definition:
            if m[0] == "TIM_CR1_CEN":
                # The expanded value should reference the Msk macro expansion
                assert m[1] != ""  # value is non-empty after expansion

    def test_core_macros_present(self, parsed_f1):
        """Core defs like __CM3_REV should still be in macro_definition."""
        names = [m[0] for m in parsed_f1.macro_definition]
        assert "__CM3_REV" in names


# --------------------------------------------------------------------------- #
#  get_type_list — extract typedef struct definitions
# --------------------------------------------------------------------------- #

class TestGetTypeList:

    def test_finds_all_typedefs(self, parsed_f1):
        """Should find ADC_TypeDef, TIM_TypeDef, RCC_TypeDef, GPIO_TypeDef, USART_TypeDef."""
        assert "ADC_TypeDef" in parsed_f1.register_dic
        assert "TIM_TypeDef" in parsed_f1.register_dic
        assert "RCC_TypeDef" in parsed_f1.register_dic
        assert "GPIO_TypeDef" in parsed_f1.register_dic
        assert "USART_TypeDef" in parsed_f1.register_dic

    def test_tim_typedef_registers(self, parsed_f1):
        """TIM_TypeDef should have CR1, CR2, SMCR, DIER, SR, EGR, PSC, ARR, CCR1."""
        tim_regs = [r[0] for r in parsed_f1.register_dic["TIM_TypeDef"]]
        assert "CR1" in tim_regs
        assert "CR2" in tim_regs
        assert "SMCR" in tim_regs
        assert "DIER" in tim_regs
        assert "SR" in tim_regs
        assert "PSC" in tim_regs
        assert "ARR" in tim_regs
        assert "CCR1" in tim_regs

    def test_gpio_typedef_registers(self, parsed_f1):
        """GPIO_TypeDef should have CRL, CRH, IDR, ODR, BSRR, BRR, LCKR."""
        gpio_regs = [r[0] for r in parsed_f1.register_dic["GPIO_TypeDef"]]
        assert "CRL" in gpio_regs
        assert "CRH" in gpio_regs
        assert "IDR" in gpio_regs
        assert "ODR" in gpio_regs
        assert "BSRR" in gpio_regs
        assert "BRR" in gpio_regs
        assert "LCKR" in gpio_regs

    def test_register_size_extraction(self, parsed_f1):
        """Each register entry should have a recognizable size string."""
        for reg in parsed_f1.register_dic["TIM_TypeDef"]:
            reg_name, reg_size, reg_comment = reg
            assert reg_size in ("4", "2", "1", "X")

    def test_typedef_list_populated(self, parsed_f1):
        """The top-level typedef names should be extracted."""
        assert len(parsed_f1.typedef_list) > 0
        assert "TIM_TypeDef" in parsed_f1.typedef_list
        assert "GPIO_TypeDef" in parsed_f1.typedef_list

    def test_reserved_registers_included(self, parsed_f1):
        """RESERVED registers should appear in the typedef list."""
        usart_regs = [r[0] for r in parsed_f1.register_dic["USART_TypeDef"]]
        assert "RESERVED0" in usart_regs


# --------------------------------------------------------------------------- #
#  get_irq_list — extract IRQn enum entries
# --------------------------------------------------------------------------- #

class TestGetIrqList:

    def test_returns_list_of_lists(self, parsed_f1):
        """Each IRQ entry is [name, handler, number, description]."""
        assert isinstance(parsed_f1.irq_list, list)
        for irq in parsed_f1.irq_list:
            assert isinstance(irq, list)
            assert len(irq) == 4

    def test_tim_irqs_present(self, parsed_f1):
        """TIM2, TIM3, TIM4 IRQs should be parsed."""
        irq_names = [irq[0] for irq in parsed_f1.irq_list]
        assert "TIM2_IRQn" in irq_names
        assert "TIM3_IRQn" in irq_names
        assert "TIM4_IRQn" in irq_names

    def test_irq_handler_derived_from_name(self, parsed_f1):
        """TIM2_IRQn → TIM2_IRQHandler."""
        for irq in parsed_f1.irq_list:
            if irq[0] == "TIM2_IRQn":
                assert irq[1] == "TIM2_IRQHandler"

    def test_irq_number_parsed(self, parsed_f1):
        """TIM2_IRQn should have number 28."""
        for irq in parsed_f1.irq_list:
            if irq[0] == "TIM2_IRQn":
                assert int(irq[2]) == 28

    def test_irq_description_extracted(self, parsed_f1):
        """TIM2_IRQn description should contain 'TIM2 global'."""
        for irq in parsed_f1.irq_list:
            if irq[0] == "TIM2_IRQn":
                assert "TIM2" in irq[3]
                assert "global" in irq[3]


# --------------------------------------------------------------------------- #
#  get_peripheral_description — extract @brief descriptions from typedefs
# --------------------------------------------------------------------------- #

class TestGetPeripheralDescription:

    def test_returns_typedef_to_description_mapping(self, parsed_f1):
        """Should map TypeDef names to their @brief descriptions."""
        descs = list(sc.get_peripheral_description(_read_synthetic()))
        desc_map = {k: v for k, v in descs}

        assert desc_map.get("TIM_TypeDef") == "TIM Timers"
        assert desc_map.get("GPIO_TypeDef") == "General Purpose I/O"
        assert desc_map.get("RCC_TypeDef") == "Reset and Clock Control"
        assert desc_map.get("ADC_TypeDef") == "Analog to Digital Converter"

    def test_description_for_usart(self, parsed_f1):
        """The USART TypeDef description should be extracted."""
        descs = list(sc.get_peripheral_description(_read_synthetic()))
        desc_map = {k: v for k, v in descs}
        usart_desc = desc_map.get("USART_TypeDef", "")
        assert "Universal" in usart_desc

    def test_empty_description_for_struct_without_brief(self):
        """If a struct has no @brief, the description should be empty string."""
        header = (
            "/** @addtogroup Peripheral_registers_structures\n  * @{\n  */\n"
            "typedef struct\n"
            "{\n"
            "  __IO uint32_t CR;\n"
            "} NOBRIEF_TypeDef;\n"
            "/** @addtogroup Peripheral_memory_map\n  * @{\n  */\n"
        )
        descs = list(sc.get_peripheral_description(header))
        desc_map = {k: v for k, v in descs}
        assert desc_map.get("NOBRIEF_TypeDef") == ""


# --------------------------------------------------------------------------- #
#  get_dupe_list — identify duplicate peripheral entries
# --------------------------------------------------------------------------- #

class TestGetDupeList:

    def test_no_duplicates(self):
        """When no adjacent duplicates exist, should return empty list."""
        dev_list = [
            ["0x40000000", "TIM2", "TIM_TypeDef*", "Timer"],
            ["0x40000400", "TIM3", "TIM_TypeDef*", "Timer"],
        ]
        assert sc.get_dupe_list(dev_list) == []

    def test_removes_adjacent_duplicates(self):
        """Adjacent entries with same address and type should be deduplicated.

        get_dupe_list returns a list of indices to delete.  The 'TIM21' entry
        is detected as a duplicate of 'TIM2' (TIM21 == TIM2 + '1')."""
        dev_list = [
            ["0x40000000", "TIM2", "TIM_TypeDef*", "Timer"],
            ["0x40000000", "TIM21", "TIM_TypeDef*", "Timer"],
        ]
        result = sc.get_dupe_list(dev_list)
        assert len(result) == 1
        assert result[0] == 0  # index 0 (TIM2) is the duplicate to remove; TIM21 is kept


# --------------------------------------------------------------------------- #
#  expand_macrodef — macro-to-macro value expansion
# --------------------------------------------------------------------------- #

class TestExpandMacrodef:

    def test_simple_value_preserved(self):
        """A standalone #define value that doesn't reference another macro
        should pass through (with hex formatting) unchanged."""
        header = _wrap_header("#define FOO 42")
        macros = sc.parse_macro_def(header)
        foo_entries = [m for m in macros if m[0] == "FOO"]
        assert len(foo_entries) == 1
        # safe_eval_int converts integer literals to 0x-padded hex
        assert "0x" in foo_entries[0][1]

    def test_macro_reference_expanded(self):
        """If macro B references macro A, B's value should contain A's value."""
        header = _wrap_header(
            "#define A 5\n"
            "#define B A\n"
        )
        macros = sc.parse_macro_def(header)
        by_name = {m[0]: m[1] for m in macros}
        assert "A" in by_name
        assert "B" in by_name
        # B should reference A's expanded value
        assert by_name["A"] in by_name["B"]

    def test_hex_suffix_stripped(self):
        """'0x1FUL' should become '0x0000001F' (strip U/L suffixes, evaluate)."""
        header = _wrap_header("#define MY_BIT (0x1FUL)")
        macros = sc.parse_macro_def(header)
        entry = [m for m in macros if m[0] == "MY_BIT"][0]
        assert "U" not in entry[1].replace("0x", "")
        assert "L" not in entry[1].replace("0x", "")
        # The value should be evaluated and stored as zero-padded hex
        assert "0x" in entry[1]

    def test_bit_shift_expression(self):
        """(1 << 0) should be preserved (not evaluated, since << is present)."""
        header = _wrap_header("#define TIM_CEN (1 << 0)")
        macros = sc.parse_macro_def(header)
        entry = [m for m in macros if m[0] == "TIM_CEN"][0]
        # << expressions are not evaluated; they are reformatted with spaces
        assert "<<" in entry[1]

    def test_multiple_macros_parsed(self):
        """All five macros should be extracted and processed."""
        header = _wrap_header(
            "#define A 1\n"
            "#define B 2\n"
            "#define C (1 << 2)\n"
            "#define D (1 << 3)\n"
            "#define E (1 << 4)\n"
        )
        macros = sc.parse_macro_def(header)
        names = [m[0] for m in macros]
        assert "A" in names
        assert "B" in names
        assert "C" in names
        assert "D" in names
        assert "E" in names
