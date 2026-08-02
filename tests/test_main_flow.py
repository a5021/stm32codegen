"""In-process tests for ``main()``.

Calling ``stm32cgen.main()`` directly (with a mocked header reader) lets the
coverage report measure the CLI entry point, which subprocess-based tests
cannot see.  Each test resets the module globals via the ``scm_globals``
fixture.
"""

import os
import sys

import pytest

import stm32cgen as sc

FIXTURES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fixtures")


def _synthetic():
    with open(os.path.join(FIXTURES_DIR, "synthetic_f1.h"), encoding="utf-8") as f:
        return f.read()


def _run(scm_globals, monkeypatch, capsys, args, header_text=None):
    monkeypatch.setattr(sys, "argv", ["stm32cgen.py", *args])
    if header_text is not None:
        monkeypatch.setattr(sc, "read_cmsis_header_file",
                            lambda hdr, fetch=True, save=False: header_text)
    sc.main()
    return capsys.readouterr()


class TestMainFlow:
    def test_version_flag_exits(self, scm_globals, monkeypatch, capsys):
        with pytest.raises(SystemExit) as exc:
            _run(scm_globals, monkeypatch, capsys, ["-V"])
        assert exc.value.code is None or exc.value.code == 0
        assert "0.086" in capsys.readouterr().out

    def test_version_long_flag_exits(self, scm_globals, monkeypatch, capsys):
        with pytest.raises(SystemExit):
            _run(scm_globals, monkeypatch, capsys, ["--version"])

    def test_generate_module_function(self, scm_globals, monkeypatch, capsys):
        out = _run(scm_globals, monkeypatch, capsys,
                   ["-l", "-m", "tim", "-f", "init_tim", "103c8", "-p", "TIM2"],
                   header_text=_synthetic()).out
        assert "void init_tim(void)" in out
        assert "TIM2->CR1" in out

    def test_bare_cpu_listing(self, scm_globals, monkeypatch, capsys):
        out = _run(scm_globals, monkeypatch, capsys, ["-l", "103c8"],
                   header_text=_synthetic()).out
        assert "Peripheral count:" in out

    def test_irq_listing(self, scm_globals, monkeypatch, capsys):
        out = _run(scm_globals, monkeypatch, capsys, ["-l", "-q", "103c8"],
                   header_text=_synthetic()).out
        assert "Total" in out
        assert "IRQs." in out

    def test_main_module(self, scm_globals, monkeypatch, capsys):
        out = _run(scm_globals, monkeypatch, capsys, ["-l", "-M", "103c8"],
                   header_text=_synthetic()).out
        assert "__MAIN_H__" in out
        assert "init(void)" in out

    def test_main_module_uncomment(self, scm_globals, monkeypatch, capsys):
        out = _run(scm_globals, monkeypatch, capsys,
                   ["-l", "-M", "103c8", "--uncomment", "flash"],
                   header_text=_synthetic()).out
        assert '#include "flash.h"' in out

    def test_main_module_pre_post_init(self, scm_globals, monkeypatch, capsys):
        out = _run(scm_globals, monkeypatch, capsys,
                   ["-l", "-M", "103c8", "--pre-init", "pre", "--post-init", "post"],
                   header_text=_synthetic()).out
        assert "void pre(void);" in out
        assert "void post(void);" in out

    def test_test_mode_builds_model(self, scm_globals, monkeypatch, capsys):
        # --test builds the object model and (with these args) prints nothing
        out = _run(scm_globals, monkeypatch, capsys, ["-l", "--test", "103c8"],
                   header_text=_synthetic()).out
        assert out == ""

    def test_wrong_cpu_exits(self, scm_globals, monkeypatch, capsys):
        with pytest.raises(SystemExit):
            _run(scm_globals, monkeypatch, capsys, ["zz"])
        assert "wrong parameter passed" in capsys.readouterr().out

    def test_no_data_exits(self, scm_globals, monkeypatch, capsys):
        with pytest.raises(SystemExit):
            _run(scm_globals, monkeypatch, capsys, ["-l", "103c8"], header_text="")
        assert "unable to get data" in capsys.readouterr().out

    def test_peripheral_enable_flag(self, scm_globals, monkeypatch, capsys):
        out = _run(scm_globals, monkeypatch, capsys,
                   ["-l", "-m", "tim", "-f", "init_tim", "103c8", "-p", "TIM2", "-E", "TIM2"],
                   header_text=_synthetic()).out
        assert "TIM2_EN" in out

    def test_header_footer_flags(self, scm_globals, monkeypatch, capsys):
        out = _run(scm_globals, monkeypatch, capsys,
                   ["-l", "-m", "tim", "-f", "init_tim", "103c8", "-p", "TIM2",
                    "-H", "/* hdr */", "-F", "/* ftr */"],
                   header_text=_synthetic()).out
        assert "/* hdr */" in out
        assert "/* ftr */" in out

    def test_disable_rcc_macro_in_process(self, scm_globals, monkeypatch, capsys):
        args = ["-l", "-m", "rcc", "-f", "init_rcc", "103c8", "-p", "RCC"]
        default = _run(scm_globals, monkeypatch, capsys, args, header_text=_synthetic()).out
        assert "DMA1_EN" in default
        disabled = _run(scm_globals, monkeypatch, capsys, args + ["-R"],
                        header_text=_synthetic()).out
        assert "DMA1_EN" not in disabled

    def test_indent_in_process(self, scm_globals, monkeypatch, capsys):
        args = ["-l", "-m", "tim", "-f", "init_tim", "103c8", "-p", "TIM2"]
        default = _run(scm_globals, monkeypatch, capsys, args, header_text=_synthetic()).out
        indented = _run(scm_globals, monkeypatch, capsys, args + ["-i", "8"],
                        header_text=_synthetic()).out

        def leading(line):
            return len(line) - len(line.lstrip(" "))

        def assignment(stream):
            return next(x for x in stream.splitlines() if "TIM2->CR1 =" in x)

        assert leading(assignment(indented)) == 4 * leading(assignment(default))

    def test_undef_flag(self, scm_globals, monkeypatch, capsys):
        out = _run(scm_globals, monkeypatch, capsys,
                   ["-l", "-m", "tim", "-f", "init_tim", "103c8", "-p", "TIM2", "-u"],
                   header_text=_synthetic()).out
        assert "#undef" in out

    def test_light_flag_in_process(self, scm_globals, monkeypatch, capsys):
        out = _run(scm_globals, monkeypatch, capsys,
                   ["-l", "--light", "-m", "tim", "-f", "init_tim", "103c8", "-p", "TIM2"],
                   header_text=_synthetic()).out
        assert "#if defined" not in out

    def test_mix_flag(self, scm_globals, monkeypatch, capsys):
        out = _run(scm_globals, monkeypatch, capsys,
                   ["-l", "--mix", "-m", "tim", "-f", "init_tim", "103c8", "-p", "TIM2"],
                   header_text=_synthetic()).out
        assert "init_tim" in out

    def test_no_def_flag(self, scm_globals, monkeypatch, capsys):
        out = _run(scm_globals, monkeypatch, capsys,
                   ["-l", "--no-def", "-m", "tim", "-f", "init_tim", "103c8", "-p", "TIM2"],
                   header_text=_synthetic()).out
        assert "init_tim" in out
