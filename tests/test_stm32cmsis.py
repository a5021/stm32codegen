import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import stm32cmsis
import stm32cgen


class TestComposeCmsisHeaderFileName(unittest.TestCase):
    # Cases that must keep working exactly as before the fix (regression guard).
    REGRESSION = {
        '103c8': 'stm32f103xb.h',
        '107rc': 'stm32f107xc.h',
        '103rc': 'stm32f103xe.h',
        '030f4': 'stm32f030x6.h',
        'l152re': 'stm32l152xe.h',
        'f407vg': 'stm32f407xx.h',
        'f746zg': 'stm32f746xx.h',
        'g031f6': 'stm32g031xx.h',
        'l412kb': 'stm32l412xx.h',
        'f401rc': 'stm32f401xc.h',
        'f413zh': 'stm32f413xx.h',
        'stm32f103c8': 'stm32f103xb.h',
        'stm32l151c8': 'stm32l151xb.h',
    }

    # Cases fixed by the bare-category / L-without-prefix / missing-line changes.
    FIXED = {
        '103xe': 'stm32f103xe.h',
        '107xc': 'stm32f107xc.h',
        '103xb': 'stm32f103xb.h',
        '103x6': 'stm32f103x6.h',
        'f103xe': 'stm32f103xe.h',
        '152re': 'stm32l152xe.h',
        'f412zg': 'stm32f412xx.h',
        'f412ve': 'stm32f412xx.h',
        'f479zi': 'stm32f479xx.h',
    }

    def test_regression(self):
        for name, expected in self.REGRESSION.items():
            with self.subTest(name=name):
                self.assertEqual(
                    stm32cmsis.compose_cmsis_header_file_name(name), expected)

    def test_fixed_cases(self):
        for name, expected in self.FIXED.items():
            with self.subTest(name=name):
                self.assertEqual(
                    stm32cmsis.compose_cmsis_header_file_name(name), expected)

    def test_all_results_are_valid_header_names(self):
        samples = list(self.REGRESSION) + list(self.FIXED)
        for name in samples:
            with self.subTest(name=name):
                out = stm32cmsis.compose_cmsis_header_file_name(name)
                self.assertTrue(out.startswith('stm32') and out.endswith('.h'),
                                f'unexpected output {out!r} for {name!r}')


class TestGetRegSetModerDefensive(unittest.TestCase):
    """Regression guard for the latent IndexError on gx[0][15] in get_reg_set.

    Real STM32 CMSIS headers never define a '_MODER_MODE*' macro shorter than
    16 chars, so the bug is not reproducible in practice. The check is still
    defensive: any short macro name containing '_MODER_MODE' must not raise.
    """

    def setUp(self):
        # get_reg_set reads args.cpu to decide which families skip MODER bits
        class _Args:
            cpu = 'g0'
        stm32cgen.args = _Args()

    def test_short_moder_mode_name_does_not_raise(self):
        # 12-char name: contains '_MODER_MODE', passes the 'X_' prefix filter,
        # but is far shorter than the index 15 the old code dereferenced.
        macro_def_list = [['X_MODER_MODE0', '', '0x1U', '']]
        try:
            result = list(stm32cgen.get_reg_set('X_', macro_def_list))
        except IndexError:
            self.fail('get_reg_set raised IndexError on a short _MODER_MODE name')
        self.assertEqual(result, macro_def_list)

    def test_real_length_moder_mode_still_filtered(self):
        # Standard-length GPIOx_MODER_MODEy must still be skipped on g0
        # (the original purpose of the check, unchanged by the fix).
        macro_def_list = [['GPIOA_MODER_MODE0', '', '0x0001U', ''],
                          ['GPIOA_MODER_MODE15', '', '0x4000U', '']]
        result = list(stm32cgen.get_reg_set('GPIO_MODER_', macro_def_list))
        yielded = [g[0] for g in result]
        self.assertNotIn('GPIOA_MODER_MODE0', yielded)
        self.assertNotIn('GPIOA_MODER_MODE15', yielded)


class TestStripTrailingOr(unittest.TestCase):
    """Regression guard for the dangling "|| \\" in generated peripheral _EN.

    stm32cgen appends a "\\n    " continuation every 5th register. When a
    peripheral's register count is a multiple of 5 that continuation lands
    after the last register, and only a plain trailing-char strip was used the
    result kept a dangling "|| \\" that broke the preprocessor
    ("operator '||' has no right operand"). STM32F1 GPIOA has exactly 5
    registers (BRR, BSRR, CRH, CRL, ODR) and hit this; STM32F0 GPIOA has 9 and
    did not. This guards the fix for register counts of 5, 10, 15, ...
    """

    def _join(self, regs, cont_every=5):
        out = '#if '
        for cnt, r in enumerate(regs, start=1):
            out += f'({r} != 0) || '
            if cnt % cont_every == 0:
                out += '\\\n    '
        return out

    def test_f1_gpioa_5_registers_no_dangling_or(self):
        regs = ['GPIOA_BRR', 'GPIOA_BSRR', 'GPIOA_CRH', 'GPIOA_CRL', 'GPIOA_ODR']
        out = stm32cgen.strip_trailing_or(self._join(regs))
        # 5 regs -> no line continuation at all, clean single-line condition
        self.assertEqual(
            out, '#if ' + ' || '.join(f'({r} != 0)' for r in regs))
        self.assertNotRegex(out, r'\|\|\s*\\?\s*$')

    def test_10_registers_keeps_interior_continuations(self):
        regs = [f'P_R{i}' for i in range(10)]
        out = stm32cgen.strip_trailing_or(self._join(regs))
        # interior "|| \" every 5 regs must survive; only trailing removed
        self.assertIn('(P_R4 != 0) || \\', out)
        self.assertIn('(P_R9 != 0)', out)
        self.assertNotRegex(out, r'\|\|\s*\\?\s*$')

    def test_normal_9_registers_unchanged(self):
        regs = [f'P_R{i}' for i in range(9)]
        out = stm32cgen.strip_trailing_or(self._join(regs))
        # 9 regs -> interior continuation at reg 5 (cnt % 5 == 0) is kept,
        # but the final register (cnt=9) ends with " || " which is stripped,
        # so there is no dangling separator (matches the prior correct output)
        self.assertIn('(P_R4 != 0) || \\', out)
        self.assertIn('(P_R8 != 0)', out)
        self.assertNotRegex(out, r'\|\|\s*\\?\s*$')

    def test_15_registers(self):
        regs = [f'P_R{i}' for i in range(15)]
        out = stm32cgen.strip_trailing_or(self._join(regs))
        # interior continuations survive, only the trailing one is removed
        self.assertIn('(P_R4 != 0) || \\', out)
        self.assertIn('(P_R9 != 0) || \\', out)
        self.assertIn('(P_R14 != 0)', out)
        self.assertNotRegex(out, r'\|\|\s*\\?\s*$')


if __name__ == '__main__':
    unittest.main()
