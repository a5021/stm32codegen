"""Tests for make_definition_block — the '-D name value' pairs block."""

import pytest

import stm32cgen as sc
from tests.conftest import make_mock_args


class TestMakeDefinitionBlock:

    def _block(self, define):
        sc.args = make_mock_args(define=define)
        return sc.make_definition_block()

    def test_single_pair(self, scm_globals):
        result = self._block(["HCLK", "16"])
        assert "#define HCLK" in result
        assert "16" in result

    def test_pair_aligns_name(self, scm_globals):
        """The macro name is left-justified to 31 columns before the value."""
        result = self._block(["HCLK", "16"])
        line = result.splitlines()[1]
        assert "#define HCLK" in line
        assert "16" in line
        # '#define HCLK' padded with spaces then indented value
        assert line.find("16") > line.find("HCLK") + 10

    def test_multiple_pairs(self, scm_globals):
        result = self._block(["HCLK", "16", "PLLM", "4"])
        assert "#define HCLK" in result and "16" in result
        assert "#define PLLM" in result and "4" in result

    def test_odd_number_of_arguments(self, scm_globals):
        """A trailing name without a value is emitted alone."""
        result = self._block(["A", "1", "B"])
        assert "#define B" in result
        assert "1" in result

    def test_empty_pair_produces_newline(self, scm_globals):
        result = self._block([""])
        assert result == "\n\n"

    def test_empty_value_in_middle(self, scm_globals):
        result = self._block(["A", "", "C"])
        assert "#define A" in result
        assert "#define C" in result
