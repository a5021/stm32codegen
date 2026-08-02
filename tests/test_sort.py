"""Tests for the sorting functions used to order generated register blocks.

``sort_code_block`` and its wrappers ``sort_ini_block`` / ``sort_def_block``
transform register definition strings into sort keys so that registers
appear in a consistent, hardware-safe order (e.g. GPIO MODER last to avoid
glitches).
"""

import pytest

import stm32cgen as sc
from tests.conftest import make_mock_args


class TestSortCodeBlock:
    """``sort_code_block`` applies character replacements from a rep_list
    to the first element of a code block (the register name line)."""

    def test_applies_replacements(self):
        block = ["TIM_CR1", "rest"]
        result = sc.sort_code_block(block, [("TIM", "XTIM")])
        assert result.startswith("XTIM")

    def test_empty_block_returns_empty(self):
        assert sc.sort_code_block([], [("A", "B")]) == ""

    def test_empty_first_element_returns_empty(self):
        assert sc.sort_code_block(["", "CR1"], [("A", "B")]) == ""

    def test_tim_number_to_letters(self):
        """TIM10 → TIMAB, TIM23 → TIMDC etc. (sort key transform)."""
        block = ["TIM10_CR1"]
        result = sc.sort_code_block(block, [])
        assert "TIMAB" in result

    def test_tim23_letters(self):
        # d1 = 23 % 10 = 3 -> 'D', d2 = 23 // 10 = 2 -> 'C'
        result = sc.sort_code_block(["TIM23_CR1"], [])
        assert result == "TIMDC_CR1"

    def test_tim100_untouched(self):
        # only 2-digit timers (10..98) are transformed; 3-digit names pass through
        result = sc.sort_code_block(["TIM100_CR1"], [])
        assert result == "TIM100_CR1"

    def test_multiple_replacements(self):
        block = ["LPUART1_SR"]
        result = sc.sort_code_block(block, [("LPUART", "XUART"), ("SR", "VV0")])
        # Both replacements applied
        assert "XUART" in result and "VV0" in result


class TestSortIniBlock:
    """``sort_ini_block`` is used to sort initialization blocks — it applies
    the GPIO sort list first, then the general ini sort list."""

    def test_gpio_ordering(self):
        """GPIO registers should sort in a specific hardware-safe order."""
        # ODR first, MODER last
        odr_key = sc.sort_ini_block(["GPIOC_ODR", "rest"])
        moder_key = sc.sort_ini_block(["GPIOC_MODER", "rest"])
        afr0_key = sc.sort_ini_block(["GPIOC_AFR_0", "rest"])
        afr1_key = sc.sort_ini_block(["GPIOC_AFR_1", "rest"])
        ospeedr_key = sc.sort_ini_block(["GPIOC_OSPEEDR", "rest"])

        # Verify MODER sorts after ODR
        assert moder_key > odr_key
        # Verify ODR is among the first
        assert odr_key < moder_key
        assert afr0_key < moder_key
        assert afr1_key < moder_key
        assert ospeedr_key < moder_key

    def test_lpuart_sorted_after_uart(self):
        lpuart_key = sc.sort_ini_block(["LPUART1_SR"])
        uart_key = sc.sort_ini_block(["UART1_SR"])
        # LPUART → XUSART, UART → USART; since 'X' > 'U', LPUART sorts AFTER UART
        assert lpuart_key > uart_key


class TestSortDefBlock:
    """``sort_def_block`` uses the def_sort_list for definition blocks."""

    def test_gpio_ordering(self):
        """Definition blocks: in def_sort_list, MODER → AA0 and DR → WR.
        Since 'AA0' < 'OWR', MODER sorts BEFORE ODR."""
        odr_key = sc.sort_def_block(["GPIOC_ODR", "rest"])
        moder_key = sc.sort_def_block(["GPIOC_MODER", "rest"])
        assert moder_key < odr_key


class TestSortPeripheralByNum:
    """``sort_peripheral_by_num`` extracts the trailing digits for sorting."""

    @pytest.mark.parametrize("name,expected", [
        ("TIM1", 1),
        ("TIM2", 2),
        ("TIM10", 10),
        ("TIM100", 100),
        ("GPIOA", 0),
        ("GPIOB", 0),
        ("RCC", 0),
        ("ADC1", 1),
        ("UART42", 42),
    ])
    def test_sort_key(self, name, expected):
        assert sc.sort_peripheral_by_num((name, [], [])) == expected

    def test_sorting_order(self):
        """TIM2 should sort before TIM10 (numeric, not lexicographic)."""
        items = [("TIM10", [], []), ("TIM2", [], []), ("TIM1", [], []), ("TIM3", [], [])]
        sorted_items = sorted(items, key=sc.sort_peripheral_by_num)
        names = [item[0] for item in sorted_items]
        assert names == ["TIM1", "TIM2", "TIM3", "TIM10"]


class TestSortPeripheralBySuffix:
    """``sort_peripheral_by_suffix`` extracts all digits from a name."""

    @pytest.mark.parametrize("name,expected", [
        ("TIM1", 1),
        ("TIM2", 2),
        ("TIM10", 10),
        ("GPIOA", 0),
        ("GPIOB", 0),
        ("RCC", 0),
        ("ADC12", 12),
    ])
    def test_suffix_key(self, name, expected):
        assert sc.sort_peripheral_by_suffix(name) == expected
