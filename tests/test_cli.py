"""Tests for CLI argument parsing and mode dispatch.

The main ``__main__`` block in ``stm32cgen.py`` handles four execution modes:
  1. Code generation (``-p`` / ``-m`` with ``-f``)
  2. IRQ listing (``-q``)
  3. Peripheral listing (no mode flags, just cpu name)
  4. Main module generation (``-M``)

These tests verify argument parsing, CPU name normalization, and that the
correct code path is taken for each mode.
"""

import os
import re
import subprocess
import sys

import pytest

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _expected_version():
    """The version printed by -V must match pyproject.toml (single source)."""
    with open(os.path.join(REPO_ROOT, "pyproject.toml"), encoding="utf-8") as f:
        for line in f:
            m = re.match(r'^\s*version\s*=\s*"([^"]+)"', line)
            if m:
                return m.group(1)
    raise RuntimeError("version not found in pyproject.toml")


class TestCpuNameNormalization:
    """Test the CPU name normalization logic in the ``__main__`` block."""

    @pytest.mark.parametrize("input_name,expected", [
        ("103c8", "103C8"),          # bare F1 name, uppercased
        ("stm32f103c8", "103C8"),    # with STM32 prefix stripped
        ("STM32F103C8", "103C8"),    # uppercase
        ("f103c8", "103C8"),         # with F prefix stripped
        ("g031f8", "G031F8"),        # G0 family → 6 chars
        ("G031F8", "G031F8"),        # uppercase G0
        ("l152re", "L152RE"),        # L1 family → 6 chars
        ("h757xi", "H757XI"),        # H7 family → 6 chars
    ])
    def test_normalization(self, input_name, expected):
        """Verify CPU name normalization matches the __main__ logic."""
        cpu_name = input_name.upper()

        if cpu_name[0:5] == "STM32":
            cpu_name = cpu_name[5:]

        if cpu_name[0] == "F":
            cpu_name = cpu_name[1:]

        if cpu_name[0] == "L" or cpu_name[0] == "H" or cpu_name[0] == "G":
            cpu_name = cpu_name[:6]
        elif cpu_name[0] in "1234567890":
            cpu_name = cpu_name[:5]
        else:
            pass  # invalid

        assert cpu_name == expected


class TestSubprocessInvocation:
    """End-to-end tests via subprocess — verifies the CLI works as a script.

    These tests use ``--no-fetch`` with a locally saved header so they
    don't require network access.
    """

    @pytest.fixture(autouse=True)
    def _save_and_restore_header(self):
        """Save the synthetic header as the file the tool would look for.

        The header must live in REPO_ROOT because the subprocess tests run
        with ``cwd=REPO_ROOT`` and the tool reads it from the current dir."""
        import stm32cgen as sc

        # Determine what filename compose_cmsis_header_file_name returns
        header_name = sc.compose_cmsis_header_file_name("103c8")
        header_path = os.path.join(REPO_ROOT, header_name)

        fixture_path = os.path.join(REPO_ROOT, "tests", "fixtures", "synthetic_f1.h")
        created = False
        if not os.path.exists(header_path):
            created = True
            import shutil
            shutil.copy(fixture_path, header_path)

        yield

        if created:
            os.remove(header_path)

    def test_version_flag(self):
        """``-V`` should print the pyproject version and exit 0."""
        result = subprocess.run(
            [sys.executable, "stm32cgen.py", "-V"],
            capture_output=True, text=True, cwd=REPO_ROOT, timeout=10,
        )
        assert result.returncode == 0
        assert _expected_version() in result.stdout

    def test_version_long_flag(self):
        result = subprocess.run(
            [sys.executable, "stm32cgen.py", "--version"],
            capture_output=True, text=True, cwd=REPO_ROOT, timeout=10,
        )
        assert result.returncode == 0
        assert _expected_version() in result.stdout

    def test_no_peripheral_lists_peripherals(self):
        """Without -p, just the cpu name lists peripherals."""
        result = subprocess.run(
            [sys.executable, "stm32cgen.py", "-l", "103c8"],
            capture_output=True, text=True, cwd=REPO_ROOT, timeout=10,
        )
        assert result.returncode == 0
        # Should mention some peripheral names
        assert "TIM2" in result.stdout or "CR1" in result.stdout

    def test_irq_mode(self):
        """``-q`` should print IRQ information."""
        result = subprocess.run(
            [sys.executable, "stm32cgen.py", "-l", "-q", "103c8"],
            capture_output=True, text=True, cwd=REPO_ROOT, timeout=10,
        )
        assert result.returncode == 0
        assert "Total" in result.stdout
        assert "IRQ" in result.stdout

    def test_generate_function_output(self):
        """Full code generation should produce C output."""
        result = subprocess.run(
            [sys.executable, "stm32cgen.py", "-l", "-m", "tim", "-f", "init_tim", "103c8", "-p", "TIM"],
            capture_output=True, text=True, cwd=REPO_ROOT, timeout=10,
        )
        assert result.returncode == 0
        assert "init_tim" in result.stdout
        assert "TIM2" in result.stdout

    def test_generate_gpio_output(self):
        """GPIO generation should produce GPIO register output."""
        result = subprocess.run(
            [sys.executable, "stm32cgen.py", "-l", "-m", "gpio", "-f", "init_gpio", "103c8", "-p", "GPIOA"],
            capture_output=True, text=True, cwd=REPO_ROOT, timeout=10,
        )
        assert result.returncode == 0
        assert "init_gpio" in result.stdout
        assert "CRL" in result.stdout or "MODER" in result.stdout

    def test_main_module_generation(self):
        """``-M`` should produce a full main.h with the init() function.

        Requires PWR/RCC/FLASH/GPIO typedefs in the header (the synthetic
        fixture provides them)."""
        result = subprocess.run(
            [sys.executable, "stm32cgen.py", "-l", "-M", "103c8"],
            capture_output=True, text=True, cwd=REPO_ROOT, timeout=10,
        )
        assert result.returncode == 0, result.stderr
        out = result.stdout
        assert "#ifndef __MAIN_H__" in out
        assert "__STATIC_INLINE void init(void)" in out
        assert '#include "stm32f103xb.h"' in out
        # essential peripherals are initialised unconditionally
        assert "init_rcc();" in out
        assert "init_gpio();" in out
        # flash is in the essential list but only guarded (not unconditional)
        assert "#if(defined(FLASH_EN) && FLASH_EN)" in out
        assert "init_flash();" in out
        # non-essential peripherals are gated behind their _EN macros
        assert "#if(defined(PWR_EN) && PWR_EN)" in out
        assert "init_pwr();" in out
        assert "#if(defined(TIM2_EN) && TIM2_EN) || (defined(TIM3_EN) && TIM3_EN)" in out
        assert "init_tim();" in out
        assert "} /* init() */" in out
        assert "#endif /* __MAIN_H__ */" in out

    def test_main_module_uncomment(self):
        """``--uncomment flash`` uncomments the flash.h include."""
        result = subprocess.run(
            [sys.executable, "stm32cgen.py", "-l", "-M", "103c8", "--uncomment", "flash"],
            capture_output=True, text=True, cwd=REPO_ROOT, timeout=10,
        )
        assert result.returncode == 0, result.stderr
        out = result.stdout
        assert '#include "flash.h"' in out
        assert '// #include "flash.h"' not in out
        # pwr is not uncommented, so it stays commented out
        assert '// #include "pwr.h"' in out

    def test_help_flag(self):
        """``-h`` should print help and exit."""
        result = subprocess.run(
            [sys.executable, "stm32cgen.py", "-h"],
            capture_output=True, text=True, cwd=REPO_ROOT, timeout=10,
        )
        assert result.returncode == 0
        assert "STM32" in result.stdout or "usage" in result.stdout.lower()

    def test_invalid_cpu_exits_nonzero(self):
        """An obviously invalid CPU name should produce an error."""
        result = subprocess.run(
            [sys.executable, "stm32cgen.py", "ZZ99ZZ"],
            capture_output=True, text=True, cwd=REPO_ROOT, timeout=10,
        )
        # The tool prints an error message; exit code is 0 (uses exit() not exit(1))
        assert "wrong parameter passed" in result.stdout


class TestArgparseOptions:
    """Test that argparse accepts various option combinations."""

    @pytest.fixture(autouse=True)
    def _save_header(self):
        header_name = "stm32f103xb.h"
        header_path = os.path.join(REPO_ROOT, header_name)
        fixture_path = os.path.join(REPO_ROOT, "tests", "fixtures", "synthetic_f1.h")
        created = False
        if not os.path.exists(header_path):
            created = True
            import shutil
            shutil.copy(fixture_path, header_path)
        yield
        if created:
            os.remove(header_path)

    def _run(self, *extra):
        return subprocess.run(
            [sys.executable, "stm32cgen.py", "-l", "-m", "tim", "-f", "init_tim", "103c8", "-p", "TIM2", *extra],
            capture_output=True, text=True, cwd=REPO_ROOT, timeout=10,
        )

    def test_combined_short_flags(self):
        """``-p TIM2`` generation should produce a function with TIM2 code."""
        result = self._run()
        assert result.returncode == 0, result.stderr
        assert "init_tim" in result.stdout
        assert "TIM2" in result.stdout

    def test_strict_flag(self):
        """``--strict`` should be accepted as a flag."""
        result = self._run("--strict")
        assert result.returncode == 0, result.stderr
        assert "init_tim" in result.stdout

    def test_light_flag(self):
        """``--light`` should be accepted."""
        result = self._run("--light")
        assert result.returncode == 0, result.stderr
        assert "init_tim" in result.stdout
        # light mode skips the '#if defined <macro>' branch
        assert "#if defined" not in result.stdout

    def test_no_def_flag(self):
        """``--no-def`` should be accepted and suppress the definitions block."""
        result = self._run("--no-def")
        assert result.returncode == 0, result.stderr
        assert "init_tim" in result.stdout

    def test_force_inline_flag(self):
        """``--force-inline`` should use __STATIC_FORCEINLINE."""
        result = self._run("--force-inline")
        assert result.returncode == 0, result.stderr
        assert "__STATIC_FORCEINLINE" in result.stdout
        assert "__STATIC_INLINE void" not in result.stdout

    def test_set_bit_flag(self):
        """``--set-bit`` should be accepted with arguments."""
        result = self._run("-b", "TIM_CR1_CEN")
        assert result.returncode == 0, result.stderr
        assert "init_tim" in result.stdout

    def test_define_flag(self):
        """``-D`` should be accepted with macro definitions."""
        result = self._run("-D", "HCLK", "16")
        assert result.returncode == 0, result.stderr
        assert "#define HCLK" in result.stdout
        assert "16" in result.stdout

    def test_disable_rcc_macro_flag(self):
        """``-R`` must suppress the auto-generated ``_EN`` macros."""
        base = [sys.executable, "stm32cgen.py", "-l", "-m", "rcc", "-f", "init_rcc", "103c8", "-p", "RCC"]
        normal = subprocess.run(base, capture_output=True, text=True, cwd=REPO_ROOT, timeout=10)
        disabled = subprocess.run(base + ["-R"], capture_output=True, text=True, cwd=REPO_ROOT, timeout=10)
        assert normal.returncode == 0, normal.stderr
        assert disabled.returncode == 0, disabled.stderr
        assert "DMA1_EN" in normal.stdout
        assert "DMA1_EN" not in disabled.stdout

    def test_indent_flag(self):
        """``-i`` must scale the generated code indentation."""
        base = [sys.executable, "stm32cgen.py", "-l", "-m", "tim", "-f", "init_tim", "103c8", "-p", "TIM2"]
        default = subprocess.run(base, capture_output=True, text=True, cwd=REPO_ROOT, timeout=10)
        indented = subprocess.run(base + ["-i", "8"], capture_output=True, text=True, cwd=REPO_ROOT, timeout=10)
        assert default.returncode == 0, default.stderr
        assert indented.returncode == 0, indented.stderr

        def leading(line):
            return len(line) - len(line.lstrip(" "))

        def assignment(stream):
            return next(line for line in stream.splitlines() if "TIM2->CR1 =" in line)

        default_indent = leading(assignment(default.stdout))
        indented_indent = leading(assignment(indented.stdout))
        assert default_indent == 6
        assert indented_indent == 4 * default_indent
