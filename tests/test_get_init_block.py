"""Tests for get_init_block — register name normalisation, filtering and
the empty-comment field shift.

get_init_block(src, target) walks each ``PERIPH->REG`` reference, normalises
the peripheral/register names (AFR[0] -> AFRL, OSPEEDR -> OSPEEDER on
F3/L0/L1, LPUART/UART -> USART, ...), honours ``--exclude-register`` and
finally yields the per-register bitfield list.
"""

import pytest

import stm32cgen as sc
from tests.conftest import make_mock_args


def _capture_reg_str(monkeypatch, cpu, target):
    """Patch get_reg_set to record the reg_str it is called with and return
    an empty list.  Returns the list of captured ``reg_str`` values."""
    seen = []
    monkeypatch.setattr(sc, 'get_reg_set', lambda reg_str, md: seen.append(reg_str) or [])
    sc.args = make_mock_args(cpu=cpu)
    sc.max_field_len = [0, 0, 0]
    sc.macro_definition = [['X', '1', '', '']]  # non-empty: skip parse of src
    list(sc.get_init_block('', [target]))
    return seen


class TestGetInitBlockRegisterRenames:
    """Normalisation of register and peripheral names before lookup."""

    @pytest.mark.parametrize("target,expected", [
        ("TIM2->CR1", "TIM_CR1_"),
        ("TIM2->AFR[0]", "TIM_AFRL_"),
        ("TIM2->AFR[1]", "TIM_AFRH_"),
        ("EXTI->EXTICR[0]", "EXTI_EXTICR1_"),
        ("EXTI->EXTICR[1]", "EXTI_EXTICR2_"),
        ("EXTI->EXTICR[2]", "EXTI_EXTICR3_"),
        ("EXTI->EXTICR[3]", "EXTI_EXTICR4_"),
        ("UART4->SR", "USART_SR_"),
        ("LPUART1->SR", "USART_SR_"),
        ("FIREWALL->CR", "FW_CR_"),
        ("DMA1_Channel1->CCR", "DMA_CCR_"),
        ("DMA2_Stream0->CR", "DMA_SxCR_"),
        ("DMA2_Stream7->M0AR", "DMA_SxM0AR_"),
    ])
    def test_lookup_key(self, monkeypatch, scm_globals, target, expected):
        assert _capture_reg_str(monkeypatch, '103C8', target) == [expected]

    @pytest.mark.parametrize("cpu,target,expected", [
        ("103C8", "GPIOA->OSPEEDR", "GPIO_OSPEEDR_"),
        ("303VC", "GPIOA->OSPEEDR", "GPIO_OSPEEDER_"),
        ("L052K8", "GPIOA->OSPEEDR", "GPIO_OSPEEDER_"),
        ("L152RE", "GPIOA->OSPEEDR", "GPIO_OSPEEDER_"),
        ("G031F8", "GPIOA->OSPEEDR", "GPIO_OSPEEDR_"),
    ])
    def test_ospeedr_variant(self, monkeypatch, scm_globals, cpu, target, expected):
        assert _capture_reg_str(monkeypatch, cpu, target) == [expected]


class TestGetInitBlockExcludeRegister:

    def test_excluded_register_skipped(self, monkeypatch, scm_globals):
        sc.args = make_mock_args(cpu='103C8', exclude_register=['CR1'])
        sc.max_field_len = [0, 0, 0]
        sc.macro_definition = [['X', '1', '', '']]
        monkeypatch.setattr(sc, 'get_reg_set', lambda reg_str, md: [])
        assert list(sc.get_init_block('', ["TIM2->CR1"])) == []

    def test_nonexcluded_register_kept(self, monkeypatch, scm_globals):
        sc.args = make_mock_args(cpu='103C8', exclude_register=['PSC'])
        sc.max_field_len = [0, 0, 0]
        sc.macro_definition = [['X', '1', '', '']]
        monkeypatch.setattr(sc, 'get_reg_set', lambda reg_str, md: [])
        assert list(sc.get_init_block('', ["TIM2->CR1"])) == [[]]


class TestGetInitBlockFieldShift:

    def test_empty_comment_shifts_extra_value(self, scm_globals):
        """When the descriptive comment is empty the extra value column is
        promoted into field 2 so the code generator can render it."""
        sc.args = make_mock_args(cpu='103C8')
        sc.max_field_len = [0, 0, 0]
        sc.macro_definition = [['TIM_CR1_FOO', '(1 << 0)', '', '0x00000001']]

        result = list(sc.get_init_block('', ["TIM2->CR1"]))
        assert len(result) == 1
        entry = result[0][0]
        assert entry[2] == '0x00000001'
        assert entry[3] == ''

    def test_existing_comment_untouched(self, scm_globals):
        sc.args = make_mock_args(cpu='103C8')
        sc.max_field_len = [0, 0, 0]
        sc.macro_definition = [['TIM_CR1_FOO', '(1 << 0)', 'Keep me', '0x00000001']]

        result = list(sc.get_init_block('', ["TIM2->CR1"]))
        entry = result[0][0]
        assert entry[2] == 'Keep me'
        assert entry[3] == '0x00000001'
