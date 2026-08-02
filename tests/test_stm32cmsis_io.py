"""Tests for the CMSIS header I/O helpers in stm32cmsis.py.

These tests never hit the network: ``fetch=True`` paths are exercised with a
mocked ``requests.get`` and ``fetch=False`` paths read a local file.
"""

import os

import pytest

import stm32cmsis


class TestHeaderFileName:
    def test_f1_table_lookup(self):
        assert stm32cmsis.get_header_file_name("f1", 2) == "stm32f101x6.h"

    def test_l0_table_lookup(self):
        assert stm32cmsis.get_header_file_name("l0", 0) == "stm32l010x4.h"

    def test_bare_cpu_code(self):
        assert stm32cmsis.compose_cmsis_header_file_name("103c8") == "stm32f103xb.h"

    def test_full_name_known_suffix(self):
        # 'f411ce' resolves inside the F4 table (11ce is under the 11xe key)
        assert stm32cmsis.compose_cmsis_header_file_name("stm32f411ce") == "stm32f411xe.h"

    def test_full_name_unknown_suffix_passthrough(self):
        # an unrecognised suffix within a known family is echoed back
        assert stm32cmsis.compose_cmsis_header_file_name("stm32f1garbage") == "stm32f1garbage"

    def test_g0_family(self):
        assert stm32cmsis.compose_cmsis_header_file_name("g031f") == "stm32g031xx.h"

    def test_l4_family(self):
        assert stm32cmsis.compose_cmsis_header_file_name("l412re") == "stm32l412xx.h"

    def test_l1_numeric_collision(self):
        # bare '152re' must map to the L1 table, not the F1 fallback
        assert stm32cmsis.compose_cmsis_header_file_name("152re") == "stm32l152xe.h"

    def test_unknown_family_fallback(self):
        # unknown prefixes are echoed back verbatim
        assert stm32cmsis.compose_cmsis_header_file_name("zz99zz") == "stm32zz99zz.h"


class TestHeaderFileUrl:
    def test_cmsis_device_url(self):
        url = stm32cmsis.compose_cmsis_header_file_url("stm32f103xb.h")
        assert url == (
            "https://raw.githubusercontent.com/STMicroelectronics/"
            "cmsis_device_f1/master/Include/stm32f103xb.h"
        )

    def test_src_url(self):
        url = stm32cmsis.get_src_url("f1", "103xb")
        assert "STM32CubeF1" in url
        assert url.endswith("/Include/stm32f1103xb.h")


class TestReadCmsisHeaderFile:
    def test_fetch_false_existing_file(self, tmp_path, monkeypatch):
        monkeypatch.chdir(tmp_path)
        (tmp_path / "stm32f103xb.h").write_text("int foo;\n")
        assert stm32cmsis.read_cmsis_header_file("103c8", fetch=False) == "int foo;\n"

    def test_fetch_false_missing_file(self, tmp_path, monkeypatch):
        monkeypatch.chdir(tmp_path)
        assert stm32cmsis.read_cmsis_header_file("103c8", fetch=False) == ""

    def test_fetch_success_no_save(self, tmp_path, monkeypatch):
        monkeypatch.chdir(tmp_path)
        monkeypatch.setattr(
            stm32cmsis.requests, "get",
            lambda url: type("R", (), {"ok": True, "text": "int bar;\n"})(),
        )
        assert stm32cmsis.read_cmsis_header_file("103c8", fetch=True) == "int bar;\n"
        assert not (tmp_path / "stm32f103xb.h").exists()

    def test_fetch_success_save(self, tmp_path, monkeypatch):
        monkeypatch.chdir(tmp_path)
        monkeypatch.setattr(
            stm32cmsis.requests, "get",
            lambda url: type("R", (), {"ok": True, "text": "int bar;\n"})(),
        )
        assert stm32cmsis.read_cmsis_header_file("103c8", fetch=True, save=True) == "int bar;\n"
        saved = (tmp_path / "stm32f103xb.h").read_text()
        assert saved == "int bar;\n"

    def test_fetch_failure_returns_empty(self, tmp_path, monkeypatch):
        monkeypatch.chdir(tmp_path)
        monkeypatch.setattr(
            stm32cmsis.requests, "get",
            lambda url: type("R", (), {"ok": False, "text": ""})(),
        )
        assert stm32cmsis.read_cmsis_header_file("103c8", fetch=True) == ""

    def test_fetch_network_error_propagates(self, tmp_path, monkeypatch):
        # a hard transport error is not silently swallowed
        monkeypatch.chdir(tmp_path)
        monkeypatch.setattr(
            stm32cmsis.requests, "get",
            lambda url: (_ for _ in ()).throw(OSError("no network")),
        )
        with pytest.raises(OSError):
            stm32cmsis.read_cmsis_header_file("103c8", fetch=True)
