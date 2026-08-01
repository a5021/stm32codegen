"""Tests for ``safe_eval_int`` — the AST-based integer expression evaluator.

``safe_eval_int`` replaces the old ``eval()`` call in ``expand_macrodef``
and must safely evaluate CMSIS macro value expressions without executing
arbitrary Python code.  These tests verify both correctness and security.

Note: ``safe_eval_int`` is called *after* ``expand_macrodef`` strips C
suffixes (``U``, ``L``, ``UL``) from hex literals.  These tests therefore
use already-stripped expressions for correctness checks, and include
C-suffix forms in the rejection tests.
"""

import pytest

import stm32cgen as sc


# --------------------------------------------------------------------------- #
#  Correctness — expressions that should evaluate to known integers
# --------------------------------------------------------------------------- #

class TestSafeEvalCorrectness:

    @pytest.mark.parametrize("expr,expected", [
        # Simple integer literals
        ("0", 0),
        ("1", 1),
        ("42", 42),
        ("255", 255),

        # Hex literals (valid Python syntax, no C suffix)
        ("0x0", 0),
        ("0x1", 1),
        ("0xFF", 255),
        ("0xDEADBEEF", 0xDEADBEEF),
        ("0x1F", 31),
        ("0xC00", 0xC00),

        # Bit shifts — the most common CMSIS pattern
        ("(1 << 0)", 1),
        ("(1 << 1)", 2),
        ("(1 << 4)", 16),
        ("(1 << 17)", 0x20000),
        ("(0x1 << 0)", 1),
        ("(0x1 << 17)", 0x20000),
        ("(0xFF << 8)", 0xFF00),

        # Multi-bit shift masks
        ("(0x3 << 10)", 0xC00),
        ("(0x7 << 4)", 0x70),

        # Bitwise OR — combining bit fields
        ("(1 << 0) | (1 << 1)", 0x3),
        ("(1 << 0) | (1 << 1) | (1 << 2)", 0x7),
        ("(0x1 << 0) | (0x1 << 1)", 0x3),
        ("(0x3 << 4) | (0x1 << 0)", 0x31),

        # Bitwise AND
        ("0xFF & 0x0F", 0x0F),
        ("0xDEADBEEF & 0xFF", 0xEF),
        ("(1 << 0) & (1 << 1)", 0),

        # Bitwise XOR
        ("0xFF ^ 0x0F", 0xF0),
        ("(1 << 0) ^ (1 << 1)", 0x3),

        # Unary NOT
        ("~0", -1),
        ("~0xFFFFFFFF", -4294967296),  # Python arbitrary-precision: ~0xFFFFFFFF == -0x100000000
        ("~0x0", -1),

        # Unary minus
        ("-1", -1),
        ("-14", -14),
        ("-(1 << 4)", -16),

        # Unary plus
        ("+42", 42),
        ("+0xFF", 255),

        # Arithmetic (add, sub, mult — div is NOT supported)
        ("1 + 1", 2),
        ("10 - 3", 7),
        ("3 * 4", 12),

        # Complex nested expressions
        ("((1 << (2 + 3)) | (0xFF << 8))", (1 << 5) | (0xFF << 8)),
        ("((1 << 0) | (1 << 1)) & 0xFF", 0x3),

        # Expressions from real CMSIS headers (suffixes stripped by expand_macrodef)
        ("(0x1 << 0)", 1),
        ("(0x3 << 1)", 6),
        ("(0x7 << 0)", 7),
        ("(0x1 << 2) | (0x1 << 5)", 0x24),
        ("(0x3 << 24)", 0x3000000),
    ])
    def test_evaluates_correctly(self, expr, expected):
        assert sc.safe_eval_int(expr) == expected

    def test_all_single_bit_shifts(self):
        """All single-bit shifts 0–31 produce the correct power of two."""
        for bit in range(32):
            assert sc.safe_eval_int(f"(1 << {bit})") == (1 << bit)

    def test_all_multi_bit_masks(self):
        """All n-bit masks (0 to 2^n - 1) shifted by 0 produce correct values."""
        for n in range(1, 9):
            expr = f"(0x{(1 << n) - 1:X} << 0)"
            assert sc.safe_eval_int(expr) == (1 << n) - 1


# --------------------------------------------------------------------------- #
#  Security — expressions that must NOT execute code
# --------------------------------------------------------------------------- #

class TestSafeEvalSecurity:

    @pytest.mark.parametrize("expr", [
        # C-style suffixes not valid in Python (stripped by expand_macrodef before
        # safe_eval_int is called, but safe_eval must still reject them)
        "0x1FUL",
        "0x3UL",
        "0xFFUL",
        "0xDEADBEEFUL",

        # Division is not supported
        "100 / 2",
        "100 / 0",

        # Function calls — must never execute
        "system('ls')",
        "eval('1')",
        "exec('1')",
        "open('foo')",
        "print(1)",
        "__import__('os')",
        "__import__('os').system('ls')",

        # Attribute access
        "().__class__",
        "().__class__.__bases__[0].__subclasses__()",

        # Subscript access
        "()[0]",
        "['x'][0]",
        "{}[0]",

        # Name lookups (undefined names)
        "True",
        "False",
        "None",
        "x",
        "abc",

        # String literals
        "'hello'",
        '"hello"',

        # Lambda / comprehension
        "(lambda: 1)",
        "[x for x in range(1)]",

        # Comparison operators (not in the allowed set)
        "1 == 1",
        "1 < 2",
        "1 > 2",
        "1 <= 2",
        "1 >= 2",

        # Bool operators
        "True and False",
        "True or False",
        "not True",

        # Walrus operator
        "(x := 1)",
    ])
    def test_rejects_unsafe_expressions(self, expr):
        """Any expression containing calls, attribute access, name lookups,
        comparisons, or unsupported operators must return ``''``."""
        result = sc.safe_eval_int(expr)
        assert result == "", f"Expression {expr!r} was not rejected (got {result!r})"

    def test_rejects_code_injection(self):
        """A crafted expression that would be dangerous with eval()."""
        result = sc.safe_eval_int("__import__('os').system('echo pwned')")
        assert result == ""

    def test_rejects_syntax_error(self):
        """Malformed expressions must return empty, not raise."""
        assert sc.safe_eval_int("1 +") == ""
        assert sc.safe_eval_int("(1 <<") == ""
        assert sc.safe_eval_int(")1(") == ""

    def test_rejects_empty(self):
        assert sc.safe_eval_int("") == ""

    def test_rejects_float_literal(self):
        """Floats are not integer constants and must be rejected."""
        result = sc.safe_eval_int("3.14")
        assert result == ""

    def test_handles_complex_nested(self):
        """Deeply nested but safe expressions should work correctly."""
        result = sc.safe_eval_int("((1 << (2 + 3)) | (0xFF << 8))")
        assert result == (1 << 5) | (0xFF << 8)

    def test_large_bit_position(self):
        """Bit positions up to 31 should work (32-bit register width)."""
        assert sc.safe_eval_int("(1 << 31)") == 0x80000000

    def test_multiple_bit_shifts_combined(self):
        """Multiple shift + OR combinations should evaluate correctly."""
        result = sc.safe_eval_int("(1 << 0) | (1 << 3) | (1 << 5) | (1 << 7)")
        assert result == 0xA9  # (1<<0) + (1<<3) + (1<<5) + (1<<7) = 0xA9
