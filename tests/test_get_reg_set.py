"""Tests for get_reg_set — the family-dependent bitfield filtering.

get_reg_set filters the flat macro list for a single register based on the
MCU family (``args.cpu``).  These tests document the exact behaviour for
every filter branch across the families that matter (F0/F1/F3/F4/G0/L0/L1/H7).

Note on naming: the family filters match the ``_X_NN`` style macro names
(underscore before the pin number), e.g. ``GPIOA_OTYPER_OT_0``.  Standard ST
CMSIS headers use ``GPIOA_OTYPER_OT0`` (no underscore), which is *not*
matched by the filter and therefore passes through everywhere; that behaviour
is also documented below.
"""

import pytest

import stm32cgen as sc
from tests.conftest import make_mock_args


def _regset(cpu, reg_str, names):
    sc.args = make_mock_args(cpu=cpu)
    macro_def_list = [[n, 'v', 'd', ''] for n in names]
    return [g[0] for g in sc.get_reg_set(reg_str, macro_def_list)]


class TestPosMskExcluded:

    def test_pos_msk_never_yielded(self, scm_globals):
        names = ['TIM_CR1_CEN_Pos', 'TIM_CR1_CEN_Msk', 'TIM_CR1_CEN']
        assert _regset('103C8', 'TIM_CR1_', names) == ['TIM_CR1_CEN']

    def test_plain_name_without_suffix_yielded(self, scm_globals):
        assert _regset('103C8', 'TIM_CR1_', ['TIM_CR1_CEN']) == ['TIM_CR1_CEN']


class TestAfrlAfrh:

    @pytest.mark.parametrize("cpu,kept", [
        ("103C8", False),   # F1 -> filtered
        ("G031F8", False),  # G0 -> filtered
        ("401CC", False),   # F4 -> filtered
        ("303VC", True),    # F3 -> kept
        ("745", True),      # F7 -> kept
    ])
    def test_filter(self, scm_globals, cpu, kept):
        out = _regset(cpu, 'GPIOA_', ['GPIOA_AFRL_AFRL0'])
        assert ('GPIOA_AFRL_AFRL0' in out) == kept


class TestModerMode:

    def test_real_length_name_never_filtered(self, scm_globals):
        """GPIOA_MODER_MODE0 is 17 chars; char index 15 is 'E', so the
        ``gx[0][15] in '0123456789'`` guard never fires for real macros."""
        for cpu in ('103C8', 'G031F8', 'H757XI', 'L052K8', 'L152RE'):
            assert _regset(cpu, 'GPIOA_', ['GPIOA_MODER_MODE0']) == ['GPIOA_MODER_MODE0']

    @pytest.mark.parametrize("cpu,kept", [
        ("103C8", False),   # filtered
        ("G031F8", False),  # filtered
        ("401CC", False),   # filtered
        ("L152RE", False),  # L1 -> filtered
        ("L052K8", True),   # L0 -> kept
        ("H757XI", True),   # H7 -> kept
    ])
    def test_digit_at_index15(self, scm_globals, cpu, kept):
        """FOO_MODER_MODE00 has a digit at index 15 and matches '_MODER_MODE';
        it is filtered everywhere except L0 and H7."""
        out = _regset(cpu, 'FOO_', ['FOO_MODER_MODE00'])
        assert ('FOO_MODER_MODE00' in out) == kept


class TestOtyper:

    @pytest.mark.parametrize("cpu,kept", [
        ("103C8", False),
        ("401CC", False),
        ("G031F8", False),
        ("H757XI", False),
        ("030F4", True),   # F0
        ("303VC", True),   # F3
        ("L052K8", True),  # L0
        ("L152RE", True),  # L1
    ])
    def test_filter(self, scm_globals, cpu, kept):
        out = _regset(cpu, 'GPIOA_', ['GPIOA_OTYPER_OT_0'])
        assert ('GPIOA_OTYPER_OT_0' in out) == kept

    def test_standard_st_naming_passes_through(self, scm_globals):
        """GPIOA_OTYPER_OT0 (no underscore) does not match '_OTYPER_OT_'."""
        assert _regset('103C8', 'GPIOA_', ['GPIOA_OTYPER_OT0']) == ['GPIOA_OTYPER_OT0']


class TestPupdr:

    @pytest.mark.parametrize("cpu,kept", [
        ("103C8", False),
        ("401CC", False),
        ("G031F8", False),
        ("L052K8", False),  # L0 -> filtered
        ("030F4", True),    # F0
        ("303VC", True),    # F3
        ("745", True),      # F7
        ("L152RE", True),   # L1
    ])
    def test_filter(self, scm_globals, cpu, kept):
        out = _regset(cpu, 'GPIOA_', ['GPIOA_PUPDR_PUPDR0'])
        assert ('GPIOA_PUPDR_PUPDR0' in out) == kept


class TestIdrOdr:

    @pytest.mark.parametrize("cpu,kept", [
        ("103C8", False),
        ("G031F8", False),
        ("L052K8", False),
        ("L152RE", True),  # only L1 keeps them
    ])
    def test_idr_filter(self, scm_globals, cpu, kept):
        out = _regset(cpu, 'GPIOA_', ['GPIOA_IDR_IDR_0'])
        assert ('GPIOA_IDR_IDR_0' in out) == kept

    def test_odr_filter(self, scm_globals):
        assert _regset('103C8', 'GPIOA_', ['GPIOA_ODR_ODR_0']) == []
        assert _regset('L152RE', 'GPIOA_', ['GPIOA_ODR_ODR_0']) == ['GPIOA_ODR_ODR_0']

    def test_standard_st_naming_passes_through(self, scm_globals):
        assert _regset('103C8', 'GPIOA_', ['GPIOA_IDR_IDR0', 'GPIOA_ODR_ODR0']) == \
            ['GPIOA_IDR_IDR0', 'GPIOA_ODR_ODR0']


class TestTsEn:

    def test_rcc_ahbenr_tsen_always_filtered(self, scm_globals):
        for cpu in ('103C8', '030F4', 'L152RE', 'H757XI'):
            assert _regset(cpu, 'RCC_AHBENR_', ['RCC_AHBENR_TSEN']) == []


class TestBsrr:

    @pytest.mark.parametrize("cpu,kept", [
        ("103C8", False),
        ("401CC", False),
        ("G031F8", False),
        ("H757XI", False),
        ("030F4", True),   # F0
        ("303VC", True),   # F3
        ("L052K8", True),  # L0
        ("L152RE", True),  # L1
    ])
    def test_bs_filter(self, scm_globals, cpu, kept):
        out = _regset(cpu, 'GPIOA_', ['GPIOA_BSRR_BS_0'])
        assert ('GPIOA_BSRR_BS_0' in out) == kept

    def test_br_filter(self, scm_globals):
        assert _regset('103C8', 'GPIOA_', ['GPIOA_BSRR_BR_0']) == []
        assert _regset('303VC', 'GPIOA_', ['GPIOA_BSRR_BR_0']) == ['GPIOA_BSRR_BR_0']

    def test_standard_st_naming_passes_through(self, scm_globals):
        assert _regset('103C8', 'GPIOA_', ['GPIOA_BSRR_BS0', 'GPIOA_BSRR_BR0']) == \
            ['GPIOA_BSRR_BS0', 'GPIOA_BSRR_BR0']


class TestTrailingUnderscoreDigits:

    def test_comment_indented(self, scm_globals):
        """A macro ending in '_<digits>' gets its comment indented by two
        spaces (used for per-pin bit names)."""
        sc.args = make_mock_args(cpu='103C8')
        md = [['X_FOO_1', '(1 << 0)', 'desc', '']]
        out = list(sc.get_reg_set('X_', md))
        assert out[0][2] == '  desc'

    def test_no_digits_leaves_comment(self, scm_globals):
        sc.args = make_mock_args(cpu='103C8')
        md = [['X_FOO', '(1 << 0)', 'desc', '']]
        out = list(sc.get_reg_set('X_', md))
        assert out[0][2] == 'desc'
