"""Robustness tests: the parser must never crash on degenerate input.

These lock in graceful behaviour for empty/garbage headers, malformed
``#define`` lines and unusual macro shapes.  Where the behaviour is a known
limitation (multi-line defines), the test documents it explicitly.
"""

import pytest

import stm32cgen


class TestEmptyInput:
    def test_parse_macro_def_empty(self):
        assert stm32cgen.parse_macro_def("") == []

    def test_parse_macro_def_no_defines(self):
        assert stm32cgen.parse_macro_def("typedef struct { int x; } X;\n") == []

    def test_get_peripheral_description_empty(self):
        assert list(stm32cgen.get_peripheral_description("")) == []

    def test_get_peripheral_description_garbage(self):
        assert list(stm32cgen.get_peripheral_description("no markers here")) == []

    def test_get_cmsis_header_file_empty_text(self, scm_globals):
        sc = scm_globals
        sc.read_cmsis_header_file = lambda hdr, fetch=True, save=False: ""
        assert sc.get_cmsis_header_file("103c8", fetch=False) == ""

    def test_get_cmsis_header_file_garbage(self, scm_globals):
        sc = scm_globals
        sc.read_cmsis_header_file = lambda hdr, fetch=True, save=False: "not a real header\n"
        txt = sc.get_cmsis_header_file("103c8", fetch=False)
        assert txt == "not a real header\n"
        assert sc.macro_definition == []
        assert sc.peripheral_data == []
        assert sc.typedef_list == []
        assert sc.irq_list == []


class TestWeirdDefines:
    def test_comment_only_define_skipped(self):
        # a define with no value is dropped entirely
        result = stm32cgen.parse_macro_def("#define X /* comment */\n")
        assert all(entry[0] != "X" for entry in result)

    def test_trailing_comment_split(self):
        result = stm32cgen.parse_macro_def("#define X 1 /* trailing */\n")
        x = [entry for entry in result if entry[0] == "X"]
        assert len(x) == 1
        # value is normalised to hex; the trailing comment is preserved
        assert x[0][1] == "0x00000001"
        assert "trailing" in x[0][2]

    def test_function_like_macro(self):
        # the macro *name* keeps its argument list verbatim
        result = stm32cgen.parse_macro_def("#define FOO(x) ((x) << 1)\n")
        foo = [entry for entry in result if entry[0].startswith("FOO")]
        assert len(foo) == 1
        assert foo[0][0] == "FOO(x)"

    def test_multi_line_define_is_not_joined(self):
        # known limitation: continuations are not merged, so the value is
        # just the dangling backslash (documented, not silently mis-evaluated)
        result = stm32cgen.parse_macro_def("#define FOO \\\n    1\n")
        foo = [entry for entry in result if entry[0] == "FOO"]
        assert len(foo) == 1
        assert foo[0][1] == "\\"

    def test_define_with_spaced_ops(self):
        result = stm32cgen.parse_macro_def("#define MASK (1 << 3)\n")
        m = [entry for entry in result if entry[0] == "MASK"]
        assert len(m) == 1
        assert m[0][1] == "(1 << 3)"
