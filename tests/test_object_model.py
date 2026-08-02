"""Tests for the in-memory object model (Bit / Register / Peripheral /
Microcontroller) and the ``--test`` CLI smoke mode.
"""

import os
import subprocess
import sys

import pytest

import stm32cgen as sc

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


class TestBit:
    def test_empty(self):
        b = sc.Bit([])
        assert b.mask1 == '' and b.mask2 == '' and b.descr == '' and b.value == ''

    def test_full(self):
        b = sc.Bit(['m1', 'm2', 'd', 'v'])
        assert b.mask1 == 'm1'
        assert b.mask2 == 'm2'
        assert b.descr == 'd'
        assert b.value == 'v'

    def test_partial(self):
        b = sc.Bit(['m1', 'm2'])
        assert b.mask1 == 'm1'
        assert b.mask2 == 'm2'
        assert b.descr == '' and b.value == ''

    def test_set_value_chains(self):
        b = sc.Bit(['m1'])
        assert b.set_value(5) is b
        assert b.value == 5


class TestRegister:
    def test_construction(self):
        r = sc.Register(['0x40000000', 'R32', 'Control', [sc.Bit(['CEN'])]])
        assert r.address == '0x40000000'
        assert r.size == 'R32'
        assert r.description == 'Control'
        assert r.value == '0'  # default when 5th element is missing

    def test_default_value(self):
        r = sc.Register(['addr', 'size', 'desc', [sc.Bit([])], '7'])
        assert r.value == '7'

    def test_set_get_data(self):
        r = sc.Register(['addr', 'size', 'desc', []])
        new_bits = [sc.Bit(['A']), sc.Bit(['B'])]
        assert r.set_data(new_bits) is r
        assert r.get_data() is new_bits

    def test_set_value_chains(self):
        r = sc.Register(['addr', 'size', 'desc', []])
        assert r.set_value(9) is r
        assert r.value == 9


class TestPeripheral:
    def test_construction(self):
        p = sc.Peripheral(['0x40000000', 'TIM2_TypeDef', 'Timer peripheral', []])
        assert p.address == '0x40000000'
        assert p.typedef == 'TIM2_TypeDef'
        assert p.description == 'Timer peripheral'
        assert p.register == []

    def test_set_get_data(self):
        p = sc.Peripheral(['a', 't', 'd', []])
        regs = [sc.Register(['0x40000000', 'R32', 'Control', []])]
        p.set_data(regs)
        assert p.get_data() is regs


class TestMicrocontroller:
    def test_construction(self):
        mcu = sc.Microcontroller('STM32F103C8', 'Medium-density', [])
        assert mcu.name == 'STM32F103C8'
        assert mcu.description == 'Medium-density'
        assert mcu.peripheral == []

    def test_set_get_data(self):
        mcu = sc.Microcontroller('a', 'b', [])
        data = ['STM32F103C8', 'Medium-density', ['TIM2']]
        mcu.set_data(data)
        assert mcu.get_data() == data


class TestCliTestMode:
    def test_test_mode_smoke(self):
        """``--test`` must build the whole object model without crashing."""
        header_name = "stm32f103xb.h"
        header_path = os.path.join(REPO_ROOT, header_name)
        fixture_path = os.path.join(REPO_ROOT, "tests", "fixtures", "synthetic_f1.h")
        import shutil
        created = not os.path.exists(header_path)
        if created:
            shutil.copy(fixture_path, header_path)
        try:
            result = subprocess.run(
                [sys.executable, "stm32cgen.py", "-l", "--test", "103c8"],
                capture_output=True, text=True, cwd=REPO_ROOT, timeout=10,
            )
        finally:
            if created and os.path.exists(header_path):
                os.remove(header_path)
        assert result.returncode == 0, result.stderr
