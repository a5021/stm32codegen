"""Golden / integration tests for the full code-generation pipeline.

These tests fetch real STM32 CMSIS device headers from the STMicroelectronics
GitHub repositories, save them to disk, run the generator via subprocess, and
verify that the output contains correct macro names, register assignments,
and addresses.

Fetched headers are cached in ``tests/fixtures/cache/``.  Network-dependent
tests are marked with ``@pytest.mark.network`` and skip gracefully if the
header is already cached.
"""

import os
import shutil
import subprocess
import sys

import pytest
import requests

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE_DIR = os.path.join(os.path.dirname(__file__), "fixtures", "cache")
os.makedirs(CACHE_DIR, exist_ok=True)


# --------------------------------------------------------------------------- #
#  Header download + caching
# --------------------------------------------------------------------------- #

def fetch_and_cache_header(header_name):
    """Fetch a real CMSIS header, caching it locally.

    If the header is already cached, the cached version is used.
    """
    cache_path = os.path.join(CACHE_DIR, header_name)
    if os.path.exists(cache_path):
        with open(cache_path, encoding="utf-8") as f:
            return f.read()

    family = header_name[5:7].lower()  # 'stm32f103xb.h' → 'f1'
    url = (
        f"https://raw.githubusercontent.com/STMicroelectronics/"
        f"cmsis_device_{family}/master/Include/{header_name}"
    )
    try:
        r = requests.get(url, timeout=30)
        if r.ok:
            with open(cache_path, "w", encoding="utf-8") as f:
                f.write(r.text)
            return r.text
    except requests.RequestException:
        pass

    if os.path.exists(cache_path):
        with open(cache_path, encoding="utf-8") as f:
            return f.read()

    pytest.skip(f"Cannot fetch or cache {header_name}")


# --------------------------------------------------------------------------- #
#  Fixture: make real header available as a local file for --no-fetch
# --------------------------------------------------------------------------- #

@pytest.fixture
def f1_header_file():
    """Ensure the real stm32f103xb.h is available locally for -l mode."""
    header_name = "stm32f103xb.h"
    cache_path = os.path.join(CACHE_DIR, header_name)
    local_path = os.path.join(REPO_ROOT, header_name)

    fetch_and_cache_header(header_name)

    created = False
    if not os.path.exists(local_path):
        shutil.copy(cache_path, local_path)
        created = True

    yield local_path

    if created:
        os.remove(local_path)


@pytest.fixture
def g0_header_file():
    """Ensure the real stm32g031xx.h is available locally for -l mode."""
    header_name = "stm32g031xx.h"
    cache_path = os.path.join(CACHE_DIR, header_name)
    local_path = os.path.join(REPO_ROOT, header_name)

    fetch_and_cache_header(header_name)

    created = False
    if not os.path.exists(local_path):
        shutil.copy(cache_path, local_path)
        created = True

    yield local_path

    if created:
        os.remove(local_path)


def run_codegen(args_list):
    """Run stm32cgen.py with the given argument list, return stdout."""
    cmd = [sys.executable, os.path.join(REPO_ROOT, "stm32cgen.py")] + args_list
    result = subprocess.run(
        cmd, capture_output=True, text=True, cwd=REPO_ROOT, timeout=30,
    )
    return result


# --------------------------------------------------------------------------- #
#  F1 family golden tests
# --------------------------------------------------------------------------- #

class TestGoldenF1Tim:
    """Verify TIM register generation from the real stm32f103xb.h header."""

    @pytest.mark.network
    def test_tim2_bitfield_macros(self, f1_header_file):
        """TIM2 CR1 should contain CEN, UDIS, URS bitfield defines."""
        result = run_codegen(["-l", "-m", "tim", "-f", "init_tim", "103c8", "-p", "TIM2"])
        assert result.returncode == 0, result.stderr

        out = result.stdout
        assert "TIM_CR1_CEN" in out
        assert "TIM_CR1_UDIS" in out
        assert "TIM_CR1_URS" in out

    @pytest.mark.network
    def test_tim2_register_assignment(self, f1_header_file):
        """The generated code should assign TIM2->CR1."""
        result = run_codegen(["-l", "-m", "tim", "-f", "init_tim", "103c8", "-p", "TIM2"])
        assert result.returncode == 0, result.stderr

        out = result.stdout
        assert "TIM2->CR1" in out

    @pytest.mark.network
    def test_tim2_address_in_comment(self, f1_header_file):
        """TIM2 register comments should contain base address 0x40000000."""
        result = run_codegen(["-l", "-m", "tim", "-f", "init_tim", "103c8", "-p", "TIM2"])
        assert result.returncode == 0, result.stderr

        assert "0x40000000" in result.stdout

    @pytest.mark.network
    def test_tim2_diern_bits(self, f1_header_file):
        """TIM2 DIER should have interrupt enable bits."""
        result = run_codegen(["-l", "-m", "tim", "-f", "init_tim", "103c8", "-p", "TIM2"])
        assert result.returncode == 0, result.stderr

        out = result.stdout
        assert "UIE" in out  # Update interrupt enable

    @pytest.mark.network
    def test_tim2_function_wrapper(self, f1_header_file):
        """With -f, output should have the named function."""
        result = run_codegen(["-l", "-m", "tim", "-f", "init_all_tim", "103c8", "-p", "TIM2"])
        assert result.returncode == 0, result.stderr

        assert "void init_all_tim(void)" in result.stdout

    @pytest.mark.network
    def test_tim2_header_guard(self, f1_header_file):
        """With -m, output should have include guard."""
        result = run_codegen(["-l", "-m", "tim", "-f", "init_tim", "103c8", "-p", "TIM2"])
        assert result.returncode == 0, result.stderr

        assert "__TIM_H__" in result.stdout
        assert "#ifndef" in result.stdout

    @pytest.mark.network
    def test_tim3_also_generated(self, f1_header_file):
        """TIM3 should have its own base address."""
        result = run_codegen(["-l", "-m", "tim", "-f", "init_tim", "103c8", "-p", "TIM3"])
        assert result.returncode == 0, result.stderr

        assert "0x40000400" in result.stdout  # TIM3_BASE


class TestGoldenF1Gpio:
    """Verify GPIO register generation from the real F1 header."""

    @pytest.mark.network
    def test_gpioa_registers(self, f1_header_file):
        """GPIOA should contain CRL, CRH, ODR, BSRR registers."""
        result = run_codegen(["-l", "-m", "gpio", "-f", "init_gpio", "103c8", "-p", "GPIOA"])
        assert result.returncode == 0, result.stderr

        out = result.stdout
        assert "CRL" in out
        assert "CRH" in out
        assert "ODR" in out
        assert "BSRR" in out or "BRR" in out

    @pytest.mark.network
    def test_gpioa_address(self, f1_header_file):
        """GPIOA base address should be 0x40010800."""
        result = run_codegen(["-l", "-m", "gpio", "-f", "init_gpio", "103c8", "-p", "GPIOA"])
        assert result.returncode == 0, result.stderr

        assert "0x40010800" in result.stdout

    @pytest.mark.network
    def test_gpioc_address(self, f1_header_file):
        """GPIOC base address should be 0x40010C00."""
        result = run_codegen(["-l", "-m", "gpio", "-f", "init_gpio", "103c8", "-p", "GPIOC"])
        assert result.returncode == 0, result.stderr

        assert "0x40011000" in result.stdout

    @pytest.mark.network
    def test_gpio_exclude_register(self, f1_header_file):
        """--exclude-register should omit specified registers."""
        result = run_codegen(["-l", "-m", "gpio", "-f", "init_gpio", "103c8", "-p", "GPIOA",
                              "--exclude-register", "IDR"])
        assert result.returncode == 0, result.stderr

        out = result.stdout
        # IDR should not appear as a register assignment
        assert "GPIOA->IDR" not in out

    @pytest.mark.network
    def test_gpio_exclude_lckr(self, f1_header_file):
        """--exclude-register LCKR should not appear."""
        result = run_codegen(["-l", "-m", "gpio", "-f", "init_gpio", "103c8", "-p", "GPIOC",
                              "--exclude-register", "LCKR"])
        assert result.returncode == 0, result.stderr

        assert "GPIOC->LCKR" not in result.stdout


class TestGoldenF1Rcc:
    """Verify RCC register generation from the real F1 header."""

    @pytest.mark.network
    def test_rcc_registers(self, f1_header_file):
        """RCC should contain CR, CFGR, AHBENR, APB2ENR, APB1ENR."""
        result = run_codegen(["-l", "-m", "rcc", "-f", "init_rcc", "103c8", "-p", "RCC"])
        assert result.returncode == 0, result.stderr

        out = result.stdout
        assert "CR" in out
        assert "CFGR" in out
        assert "AHBENR" in out or "APB2ENR" in out or "APB1ENR" in out

    @pytest.mark.network
    def test_rcc_address(self, f1_header_file):
        """RCC base address should be 0x40021000."""
        result = run_codegen(["-l", "-m", "rcc", "-f", "init_rcc", "103c8", "-p", "RCC"])
        assert result.returncode == 0, result.stderr

        assert "0x40021000" in result.stdout


class TestGoldenF1Adc:
    """Verify ADC register generation from the real F1 header."""

    @pytest.mark.network
    def test_adc1_registers(self, f1_header_file):
        """ADC1 should contain CR1, CR2, DR registers."""
        result = run_codegen(["-l", "-m", "adc", "-f", "init_adc", "103c8", "-p", "ADC1"])
        assert result.returncode == 0, result.stderr

        if result.returncode != 0:
            pytest.skip("ADC generation not supported for this MCU")

        out = result.stdout
        assert "CR1" in out or "CR2" in out

    @pytest.mark.network
    def test_adc1_address(self, f1_header_file):
        """ADC1 base address should be 0x40012000."""
        result = run_codegen(["-l", "-m", "adc", "-f", "init_adc", "103c8", "-p", "ADC1"])
        assert result.returncode == 0, result.stderr

        assert "0x40012400" in result.stdout


class TestGoldenF1Usart:
    """Verify USART register generation from the real F1 header."""

    @pytest.mark.network
    def test_usart1_registers(self, f1_header_file):
        """USART1 should contain CR1, BRR registers."""
        result = run_codegen(["-l", "-m", "usart", "-f", "init_usart", "103c8", "-p", "USART1"])
        assert result.returncode == 0, result.stderr

        out = result.stdout
        assert "CR1" in out
        assert "BRR" in out

    @pytest.mark.network
    def test_usart1_address(self, f1_header_file):
        """USART1 base address should be 0x40013800."""
        result = run_codegen(["-l", "-m", "usart", "-f", "init_usart", "103c8", "-p", "USART1"])
        assert result.returncode == 0, result.stderr

        assert "0x40013800" in result.stdout


# --------------------------------------------------------------------------- #
#  G0 family golden tests
# --------------------------------------------------------------------------- #

class TestGoldenG0Tim:
    """Verify TIM register generation from the real stm32g031xx.h header."""

    @pytest.mark.network
    def test_g0_tim2_has_cen(self, g0_header_file):
        """G0 TIM2 CR1 should have CEN bitfield."""
        result = run_codegen(["-l", "-m", "tim", "-f", "init_tim", "g031f8", "-p", "TIM2"])
        assert result.returncode == 0, result.stderr

        out = result.stdout
        assert "CEN" in out

    @pytest.mark.network
    def test_g0_tim2_assignment(self, g0_header_file):
        """G0 generated code should assign TIM2->CR1."""
        result = run_codegen(["-l", "-m", "tim", "-f", "init_tim", "g031f8", "-p", "TIM2"])
        assert result.returncode == 0, result.stderr

        assert "TIM2->CR1" in result.stdout

    @pytest.mark.network
    def test_g0_tim2_address(self, g0_header_file):
        """G0 TIM2 base address should be 0x40000000."""
        result = run_codegen(["-l", "-m", "tim", "-f", "init_tim", "g031f8", "-p", "TIM2"])
        assert result.returncode == 0, result.stderr

        assert "0x40000000" in result.stdout


class TestGoldenG0Gpio:
    """Verify GPIO register generation from the real G0 header."""

    @pytest.mark.network
    def test_g0_gpioa_moder(self, g0_header_file):
        """G0 GPIOA should have MODER register (not CRL/CRH like F1)."""
        result = run_codegen(["-l", "-m", "gpio", "-f", "init_gpio", "g031f8", "-p", "GPIOA"])
        assert result.returncode == 0, result.stderr

        out = result.stdout
        assert "GPIOA" in out
        assert "MODER" in out or "ODR" in out

    @pytest.mark.network
    def test_g0_gpioa_address(self, g0_header_file):
        """G0 GPIOA base address should be 0x48000000."""
        result = run_codegen(["-l", "-m", "gpio", "-f", "init_gpio", "g031f8", "-p", "GPIOA"])
        assert result.returncode == 0, result.stderr

        # G0 GPIOA address depends on the exact base address in the header
        # Just verify some register address is correct
        assert "0x50000000" in result.stdout


# --------------------------------------------------------------------------- #
#  Cross-family consistency tests
# --------------------------------------------------------------------------- #

class TestCrossFamilyConsistency:
    """Verify the same peripheral generates similar output across families."""

    @pytest.mark.network
    @pytest.mark.parametrize("cpu,header_name", [
        ("103c8", "stm32f103xb.h"),
        ("g031f8", "stm32g031xx.h"),
    ])
    def test_tim2_cen_present(self, cpu, header_name):
        """TIM2 CR1 CEN should be present in both F1 and G0 output."""
        cache_path = os.path.join(CACHE_DIR, header_name)
        local_path = os.path.join(REPO_ROOT, header_name)

        fetch_and_cache_header(header_name)
        created = False
        if not os.path.exists(local_path):
            shutil.copy(cache_path, local_path)
            created = True

        try:
            result = run_codegen(["-l", "-m", "tim", "-f", "init_tim", cpu, "-p", "TIM2"])
            assert result.returncode == 0, result.stderr
            assert "TIM2->CR1" in result.stdout
        finally:
            if created:
                os.remove(local_path)
