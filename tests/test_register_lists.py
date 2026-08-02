"""Tests for register address computation, sizes and peripheral lookup.

Covers get_register_list / get_register_property / get_register_size
(address accumulation across mixed register widths and array registers,
RESERVED filtering) and find_peripheral / get_peripheral_register_list
(strict vs. fuzzy matching, the USART->UART fallback).
"""

import pytest

import stm32cgen as sc
from tests.conftest import make_mock_args


class TestGetRegisterProperty:

    def test_plain_register(self, scm_globals):
        assert list(sc.get_register_property(['CR1', '4', ''])) == [('CR1', 4)]

    def test_array_register_expands_indices(self, scm_globals):
        """AFR[2] -> ('AFR[0]', 4), ('AFR[1]', 4)."""
        out = list(sc.get_register_property(['AFR[2]', '4', '']))
        assert out == [('AFR[0]', 4), ('AFR[1]', 4)]

    def test_symbolic_array_size(self, scm_globals):
        """Non-numeric array sizes pass through untouched."""
        out = list(sc.get_register_property(['EXTICR[IDX]', '4', '']))
        assert out == [('EXTICR[IDX]', 4)]


class TestGetRegisterSize:

    def test_recursive_struct_size(self, parsed_f1):
        """A struct with a 4-byte and a 2-byte member totals 6 bytes."""
        parsed_f1.register_dic['ZZ_TypeDef'] = [['A', '4', ''], ['B', '2', '']]
        assert sc.get_register_size('ZZ_TypeDef') == 6

    def test_numeric_size(self, parsed_f1):
        assert sc.get_register_size('4') == 4
        assert sc.get_register_size('2') == 2

    def test_and_special_case(self, parsed_f1):
        assert sc.get_register_size('AND') == 0

    def test_nested_struct(self, parsed_f1):
        parsed_f1.register_dic['INNER_TypeDef'] = [['X', '2', '']]
        parsed_f1.register_dic['OUTER_TypeDef'] = [['I', 'INNER_TypeDef', ''], ['Y', '4', '']]
        assert sc.get_register_size('OUTER_TypeDef') == 6


class TestGetRegisterList:
    """Address accumulation based on the synthetic header's TypeDef layout."""

    def test_tim2_registers(self, parsed_f1):
        """All TIM_TypeDef members are 4 bytes: CR1 at +0x00 ... OR at +0x50."""
        out = dict((r[0], r[2]) for r in sc.get_register_list(['TIM2', '0x40000000', 'TIM_TypeDef']))
        assert out['CR1'] == '0x40000000'
        assert out['CR2'] == '0x40000004'
        assert out['DIER'] == '0x4000000C'
        assert out['CNT'] == '0x40000024'
        assert out['ARR'] == '0x4000002C'
        assert out['OR'] == '0x40000050'

    def test_gpioa_mixed_widths_and_reserved(self, parsed_f1):
        """BSRR is 16-bit; RESERVED0 is skipped but still advances the offset."""
        out = dict((r[0], r[2]) for r in sc.get_register_list(['GPIOA', '0x40010800', 'GPIO_TypeDef']))
        assert 'RESERVED0' not in out
        assert out['CRL'] == '0x40010800'
        assert out['CRH'] == '0x40010804'
        assert out['IDR'] == '0x40010808'
        assert out['ODR'] == '0x4001080C'
        assert out['BSRR'] == '0x40010810'
        assert out['BRR'] == '0x40010814'
        assert out['LCKR'] == '0x40010818'

    def test_usart1_offsets(self, parsed_f1):
        out = dict((r[0], r[2]) for r in sc.get_register_list(['USART1', '0x40013800', 'USART_TypeDef']))
        assert out['SR'] == '0x40013800'
        assert out['DR'] == '0x40013804'
        assert out['BRR'] == '0x40013808'
        assert out['CR1'] == '0x4001380C'
        assert out['CR3'] == '0x40013814'
        assert out['GTPR'] == '0x40013818'


class TestFindPeripheral:

    def test_fuzzy_match_finds_all_instances(self, parsed_f1):
        """Without --strict 'TIM' matches TIM2/TIM3/TIM4."""
        names = [p[0] for p in sc.find_peripheral('TIM')]
        assert names == ['TIM2', 'TIM3', 'TIM4']

    def test_fuzzy_match_is_substring(self, parsed_f1):
        parsed_f1.args.strict = False
        assert [p[0] for p in sc.find_peripheral('USART')] == ['USART1']

    def test_strict_match_requires_exact(self, parsed_f1):
        parsed_f1.args.strict = True
        assert [p[0] for p in sc.find_peripheral('TIM2')] == ['TIM2']
        assert [p[0] for p in sc.find_peripheral('TIM')] == []

    def test_yields_name_address_typedef(self, parsed_f1):
        parsed_f1.args.strict = False
        entries = list(sc.find_peripheral('RCC'))
        assert entries == [('RCC', '0x40021000', 'RCC_TypeDef')]


class TestGetPeripheralRegisterList:

    def test_peripheral_registers(self, parsed_f1):
        """get_peripheral_register_list('GPIOA') yields (name, register_list)."""
        entries = list(sc.get_peripheral_register_list('GPIOA'))
        assert len(entries) == 1
        name, regs = entries[0]
        assert name == 'GPIOA'
        assert [r[0] for r in regs] == ['CRL', 'CRH', 'IDR', 'ODR', 'BSRR', 'BRR', 'LCKR']

    def test_usart_falls_back_to_uart(self, parsed_f1):
        """'USART' also picks up UART-style peripherals."""
        parsed_f1.peripheral_data.append(['0x40004400', 'UART4', 'USART_TypeDef*', 'Universal...'])
        names = [name for name, _ in sc.get_peripheral_register_list('USART')]
        assert 'USART1' in names
        assert 'UART4' in names
