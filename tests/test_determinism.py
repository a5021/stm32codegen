"""Determinism tests: identical inputs must produce byte-identical output.

Code generators must be reproducible; running the same command twice must
give exactly the same bytes (which keeps committed goldens stable).
"""

import os
import subprocess
import sys

import pytest

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _run(*args):
    return subprocess.run(
        [sys.executable, "stm32cgen.py", *args],
        capture_output=True, cwd=REPO_ROOT, timeout=15,
    )


@pytest.fixture(scope="module", autouse=True)
def _save_header():
    header_path = os.path.join(REPO_ROOT, "stm32f103xb.h")
    fixture_path = os.path.join(REPO_ROOT, "tests", "fixtures", "synthetic_f1.h")
    import shutil
    created = not os.path.exists(header_path)
    if created:
        shutil.copy(fixture_path, header_path)
    yield
    if created and os.path.exists(header_path):
        os.remove(header_path)


ARGS_SETS = [
    ("-l", "-m", "tim", "-f", "init_tim", "103c8", "-p", "TIM2"),
    ("-l", "-m", "gpio", "-f", "init_gpio", "103c8", "-p", "GPIOA", "GPIOC"),
    ("103c8", "-l", "-b", "TIM_CR1_CEN", "-D", "HCLK", "16", "-p", "TIM2"),
    ("-l", "--no-def", "-m", "adc", "103c8", "-p", "ADC1", "RCC"),
]


class TestDeterminism:
    @pytest.mark.parametrize("args", ARGS_SETS, ids=["tim", "gpio", "bits", "nodef"])
    def test_repeatable_output(self, args):
        first = _run(*args)
        second = _run(*args)
        assert first.returncode == 0, first.stderr.decode()
        assert second.returncode == 0, second.stderr.decode()
        assert first.stdout == second.stdout

    def test_no_crash_across_argument_sets(self):
        """every argument set must actually produce output."""
        for args in ARGS_SETS:
            result = _run(*args)
            assert result.returncode == 0, result.stderr.decode()
            assert result.stdout
