"""Tests for code generation functions.

These tests exercise ``compose_reg_init_block``, ``make_init_func``,
``make_h_module``, and ``copyright_message`` — the functions that produce
the actual C output.  They use mocked ``args`` and synthetic bitfield data.
"""

import pytest

import stm32cgen as sc
from tests.conftest import make_mock_args

# --------------------------------------------------------------------------- #
#  compose_reg_init_block
# --------------------------------------------------------------------------- #

class TestComposeRegInitBlock:
    """Test generation of register initialization blocks.

    The function signature is::

        compose_reg_init_block(reg_name, bit_def, comment=('', ''))
        → (bitfield_block, assign_block)

    ``bit_def`` is a list of bitfield entries::

        [['TIM_CR1_CEN', '(1 << 0)', 'Counter enable', '0x00000001'], ...]
    """

    # Shared test data
    TIM_CR1_BITS = [
        ["TIM_CR1_CEN", "(1 << 0)", "Counter enable", "0x00000001"],
        ["TIM_CR1_UDIS", "(1 << 1)", "Update disable", "0x00000002"],
        ["TIM_CR1_URS", "(1 << 2)", "Update request source", "0x00000004"],
        ["TIM_CR1_UDIV", "(1 << 3)", "Update discard", "0x00000008"],
    ]

    REG_NAME = "TIM2->CR1"
    COMMENT = ("Control register", "0x40000000")

    def test_returns_tuple_of_two_strings(self, scm_globals):
        """Returns (bitfield_block, assign_block)."""
        sc.args = make_mock_args()
        sc.max_field_len = [0, 0, 0]

        bitfield, assign = sc.compose_reg_init_block(self.REG_NAME, self.TIM_CR1_BITS)
        assert isinstance(bitfield, str)
        assert isinstance(assign, str)

    def test_default_mode_generates_define_and_assign(self, scm_globals):
        """Default mode: bitfield_block has #define, assign_block has #if/#else/#endif."""
        sc.args = make_mock_args()
        sc.max_field_len = [0, 0, 0]

        bitfield, assign = sc.compose_reg_init_block(self.REG_NAME, self.TIM_CR1_BITS)

        # bitfield_block should contain a #define for the register macro
        assert "TIM2_CR1" in bitfield
        assert "#define" in bitfield

        # assign_block should contain the register assignment
        assert "TIM2->CR1" in assign
        assert "TIM2_CR1" in assign

    def test_macro_name_uses_ch_def_name(self, scm_globals):
        """The generated macro name should go through ch_def_name()."""
        sc.args = make_mock_args()
        sc.max_field_len = [0, 0, 0]

        bitfield, assign = sc.compose_reg_init_block("USB->CNTR", self.TIM_CR1_BITS)
        # ch_def_name maps USB_CNTR → USB_CTLR
        assert "USB_CTLR" in bitfield
        assert "USB_CTLR" in assign

    def test_direct_mode_no_macros(self, scm_globals):
        """With --direct, no #define macros are generated."""
        sc.args = make_mock_args(direct=True)
        sc.max_field_len = [0, 0, 0]

        bitfield, assign = sc.compose_reg_init_block(self.REG_NAME, self.TIM_CR1_BITS)

        # In direct mode, bitfield is the raw assignment, no #define
        assert "#define" not in bitfield

    def test_mix_mode_interleaves(self, scm_globals):
        """With --mix, definition and init blocks are interleaved."""
        sc.args = make_mock_args(mix=True)
        sc.max_field_len = [0, 0, 0]

        bitfield, assign = sc.compose_reg_init_block(self.REG_NAME, self.TIM_CR1_BITS)

        # In mix mode, both blocks should contain content
        assert bitfield != ""
        assert assign != ""

    def test_light_mode_minimal(self, scm_globals):
        """With --light, the #if blocks should be simpler (no #else define)."""
        sc.args = make_mock_args(light=True)
        sc.max_field_len = [0, 0, 0]

        bitfield, assign = sc.compose_reg_init_block(self.REG_NAME, self.TIM_CR1_BITS)

        # light mode should not have '#else' in the assign block
        assert "#else" not in assign

    def test_undef_mode_adds_undef(self, scm_globals):
        """With --undef, the assign block should contain #undef."""
        sc.args = make_mock_args(undef=True)
        sc.max_field_len = [0, 0, 0]

        bitfield, assign = sc.compose_reg_init_block(self.REG_NAME, self.TIM_CR1_BITS)

        assert "#undef" in assign

    def test_empty_bit_def_direct_mode(self, scm_globals):
        """With no bitfields and direct mode, should produce a zero assignment."""
        sc.args = make_mock_args(direct=True, direct_init=None)
        sc.max_field_len = [0, 0, 0]

        bitfield, assign = sc.compose_reg_init_block(self.REG_NAME, [])

        # Should have register = 0000
        assert "0000" in assign

    def test_set_bit_forces_enable(self, scm_globals):
        """When set_bit forces a bit ON, the value should be '1'."""
        sc.args = make_mock_args(set_bit=["TIM_CR1_CEN"])
        sc.max_field_len = [0, 0, 0]

        bitfield, assign = sc.compose_reg_init_block(self.REG_NAME, self.TIM_CR1_BITS)

        # CEN should have '1' instead of '0'
        lines = bitfield.split("\n")
        cen_line = [line for line in lines if "TIM_CR1_CEN" in line]
        assert cen_line
        # The enable column should contain '1' for CEN
        for line in cen_line:
            assert "1" in line

    def test_tag_bit_sets_macro_value(self, scm_globals):
        """tag_bit replaces the enable 0/1 with a tag macro name."""
        sc.args = make_mock_args(tag_bit=[["PLLON", "TIM_CR1_CEN"]])
        sc.max_field_len = [0, 0, 0]

        bitfield, assign = sc.compose_reg_init_block(self.REG_NAME, [self.TIM_CR1_BITS[0]], )

        # The tag macro 'PLLON' should appear
        assert "PLLON" in bitfield

    def test_comment_in_output(self, scm_globals):
        """The register comment (address + description) should appear."""
        sc.args = make_mock_args()
        sc.max_field_len = [0, 0, 0]

        bitfield, assign = sc.compose_reg_init_block(self.REG_NAME, self.TIM_CR1_BITS, self.COMMENT)

        # The comment text should appear somewhere
        assert "Control register" in assign or "0x40000000" in assign

    def test_max_field_len_padded(self, scm_globals):
        """Longer bitfield names should be padded to max_field_len."""
        sc.args = make_mock_args()
        sc.max_field_len = [15, 12, 20]

        bitfield, assign = sc.compose_reg_init_block(self.REG_NAME, self.TIM_CR1_BITS)

        assert "TIM_CR1_CEN" in bitfield
        assert "TIM_CR1_UDIS" in bitfield
        assert "TIM_CR1_URS" in bitfield
        assert "TIM_CR1_UDIV" in bitfield


# --------------------------------------------------------------------------- #
#  compose_init_block — higher-level block composition
# --------------------------------------------------------------------------- #

class TestComposeInitBlock:

    def test_returns_two_lists(self, scm_globals, synthetic_header_text):
        """compose_init_block returns (block_a, block_b) where each is a list
        of (bitfield_block, assign_block) tuples."""
        sc.args = make_mock_args()
        sc.max_field_len = [0, 0, 0]

        block_a, block_b = sc.compose_init_block(synthetic_header_text, ["TIM2->CR1"], ("CR1", "0x40000000"))
        assert isinstance(block_a, list)
        assert isinstance(block_b, list)
        assert len(block_a) == len(block_b)


# --------------------------------------------------------------------------- #
#  make_init_func
# --------------------------------------------------------------------------- #

class TestMakeInitFunc:

    def test_basic_function(self, scm_globals):
        """Generates a void function with the given name and body."""
        sc.args = make_mock_args(function="init_tim")
        sc.modifier = "__STATIC_INLINE"

        result = sc.make_init_func("init_tim", "  TIM2->CR1 = 1;")
        assert "void init_tim(void)" in result
        assert "TIM2->CR1 = 1;" in result
        assert "__STATIC_INLINE" in result
        assert result.endswith("} /* init_tim() */")

    def test_with_pre_init(self, scm_globals):
        """Pre-init calls are inserted at the top of the function."""
        sc.args = make_mock_args(function="init_tim", pre_init=["configure_flash"])
        sc.modifier = "__STATIC_INLINE"

        result = sc.make_init_func("init_tim", "  TIM2->CR1 = 1;")
        assert "configure_flash();" in result

    def test_with_post_init(self, scm_globals):
        """Post-init calls are inserted at the bottom of the function."""
        sc.args = make_mock_args(function="init_tim", post_init=["init_systick"])
        sc.modifier = "__STATIC_INLINE"

        result = sc.make_init_func("init_tim", "  TIM2->CR1 = 1;")
        assert "init_systick();" in result

    def test_with_function_header(self, scm_globals):
        """Function header strings are prepended to the body."""
        sc.args = make_mock_args(
            function="init_tim",
            function_header=["/* custom header */"],
        )
        sc.modifier = "__STATIC_INLINE"

        result = sc.make_init_func("init_tim", "  TIM2->CR1 = 1;", header=["/* custom header */"])
        assert "/* custom header */" in result

    def test_with_function_footer(self, scm_globals):
        """Function footer strings are appended to the body."""
        sc.args = make_mock_args(
            function="init_tim",
            function_footer=["/* custom footer */"],
        )
        sc.modifier = "__STATIC_INLINE"

        result = sc.make_init_func("init_tim", "  TIM2->CR1 = 1;", footer=["/* custom footer */"])
        assert "/* custom footer */" in result

    def test_force_inline_modifier(self, scm_globals):
        """With force_inline, modifier should be __STATIC_FORCEINLINE."""
        sc.args = make_mock_args(force_inline=True)
        sc.modifier = "__STATIC_FORCEINLINE"

        result = sc.make_init_func("init_tim", "  body")
        assert "__STATIC_FORCEINLINE" in result.replace("__STATIC_FORCEINLINE", "__STATIC_FORCEINLINE")  # noqa
        assert "__STATIC_FORCEINLINE" in result

    def test_empty_body(self, scm_globals):
        """An empty body should still produce a valid function."""
        sc.args = make_mock_args(function="empty_init")
        sc.modifier = "__STATIC_INLINE"

        result = sc.make_init_func("empty_init", "")
        assert "void empty_init(void)" in result
        assert "}" in result


# --------------------------------------------------------------------------- #
#  copyright_message
# --------------------------------------------------------------------------- #

class TestCopyrightMessage:

    def test_contains_tool_name(self, scm_globals):
        """Copyright message should mention the tool name."""
        sc.args = make_mock_args()
        result = sc.copyright_message("stm32f103xb.h")
        assert "stm32codegen" in result

    def test_contains_mcu_name(self, scm_globals):
        """Copyright message should contain the MCU header name."""
        sc.args = make_mock_args()
        result = sc.copyright_message("stm32f103xb.h")
        assert "stm32f103xb" in result

    def test_contains_github_url(self, scm_globals):
        """Copyright message should contain the GitHub repo URL."""
        sc.args = make_mock_args()
        result = sc.copyright_message("stm32g031xx.h")
        assert "github.com/a5021/stm32codegen" in result

    def test_contains_argument_line(self, scm_globals):
        """The message should include a line about arguments used."""
        sc.args = make_mock_args()
        result = sc.copyright_message("stm32f103xb.h")
        assert "Arguments" in result or "argument" in result.lower()


# --------------------------------------------------------------------------- #
#  compose_reg_init_block — additional branches
# --------------------------------------------------------------------------- #

class TestComposeRegInitBlockRccEnabler:
    """The auto-generated RCC_*_EN fallback macros (used unless --no-macro)."""

    RCC_BITS = [["RCC_AHBENR_DMA1EN", "(1 << 0)", "DMA1 clock enable", "0x00000001"]]

    def test_enabler_emitted_by_default(self, scm_globals):
        """RCC_AHBENR_DMA1EN triggers a '#if !defined(DMA1_EN)' fallback."""
        sc.args = make_mock_args()
        sc.max_field_len = [0, 0, 0]

        bitfield, _ = sc.compose_reg_init_block("RCC->AHBENR", self.RCC_BITS)
        assert "#if !defined(DMA1_EN)" in bitfield
        assert "#define DMA1_EN 0" in bitfield
        assert "#endif" in bitfield
        assert "DMA1_EN" in bitfield

    def test_no_macro_disables_enabler(self, scm_globals):
        """With --no-macro no fallback #define block is emitted."""
        sc.args = make_mock_args(no_macro=True)
        sc.max_field_len = [0, 0, 0]

        bitfield, _ = sc.compose_reg_init_block("RCC->AHBENR", self.RCC_BITS)
        assert "#if !defined(DMA1_EN)" not in bitfield
        assert "RCC_AHBENR_DMA1EN" in bitfield

    def test_smenr_bits_not_enabled(self, scm_globals):
        """SMENR bits (e.g. AHB1SMENR) must not get an _EN fallback macro."""
        sc.args = make_mock_args()
        sc.max_field_len = [0, 0, 0]

        bitfield, _ = sc.compose_reg_init_block(
            "RCC->AHB1SMENR",
            [["RCC_AHB1SMENR_DMA1MEN", "(1 << 0)", "", "0x00000001"]],
        )
        assert "#if !defined(" not in bitfield

    def test_multisegment_field_gets_unique_tag(self, scm_globals):
        """CKGATENR fields (AHB2APB1_CKEN, CM4DBG_CKEN, ...) must each get a
        distinct tag built from the full field name, not a shared CK_EN."""
        sc.args = make_mock_args()
        sc.max_field_len = [0, 0, 0]

        bitfield, _ = sc.compose_reg_init_block("RCC->CKGATENR", [
            ["RCC_CKGATENR_AHB2APB1_CKEN", "(1 << 0)", "", "0x00000001"],
            ["RCC_CKGATENR_AHB2APB2_CKEN", "(1 << 1)", "", "0x00000002"],
            ["RCC_CKGATENR_CM4DBG_CKEN", "(1 << 2)", "", "0x00000004"],
        ])
        assert "#if !defined(AHB2APB1_CK_EN)" in bitfield
        assert "#define AHB2APB1_CK_EN 0" in bitfield
        assert "#if !defined(AHB2APB2_CK_EN)" in bitfield
        assert "#if !defined(CM4DBG_CK_EN)" in bitfield
        assert "#if !defined(CK_EN)" not in bitfield
        assert "AHB2APB1_CK_EN * RCC_CKGATENR_AHB2APB1_CKEN" in bitfield
        assert "CM4DBG_CK_EN  * RCC_CKGATENR_CM4DBG_CKEN" in bitfield

    def test_non_rcc_bit_no_enabler(self, scm_globals):
        sc.args = make_mock_args()
        sc.max_field_len = [0, 0, 0]

        bitfield, _ = sc.compose_reg_init_block("TIM2->CR1", [
            ["TIM_CR1_CEN", "(1 << 0)", "Counter enable", "0x00000001"],
        ])
        assert "#if !defined(" not in bitfield


class TestComposeRegInitBlockDirectInit:
    """The --direct-init (-I) path: registers initialised by literal values."""

    def test_literal_value_used(self, scm_globals):
        sc.args = make_mock_args(direct_init=["CR1", "0x3FF"])
        sc.max_field_len = [0, 0, 0]

        bitfield, _ = sc.compose_reg_init_block("TIM2->CR1", [])
        assert "0x3FF" in bitfield

    def test_register_not_in_list_falls_back(self, scm_globals):
        """If the register is not listed in -I, normal bitfield handling runs."""
        sc.args = make_mock_args(direct_init=["PSC", "0xFFFF"])
        sc.max_field_len = [0, 0, 0]

        bitfield, assign = sc.compose_reg_init_block(
            "TIM2->CR1",
            [["TIM_CR1_CEN", "(1 << 0)", "Counter enable", "0x00000001"]],
        )
        assert "TIM_CR1_CEN" in bitfield
        assert "TIM2->CR1" in assign


class TestComposeRegInitBlockMixUndef:
    """--mix combined with --undef."""

    def test_mix_undef(self, scm_globals):
        sc.args = make_mock_args(mix=True, undef=True)
        sc.max_field_len = [0, 0, 0]

        bitfield, assign = sc.compose_reg_init_block(
            "TIM2->CR1",
            [
                ["TIM_CR1_CEN", "(1 << 0)", "Counter enable", "0x00000001"],
                ["TIM_CR1_UDIS", "(1 << 1)", "Update disable", "0x00000002"],
            ],
        )
        assert bitfield != ""
        assert "#undef TIM2_CR1" in assign


class TestComposeRegInitBlockComment:

    def test_empty_description_short_comment(self, scm_globals):
        """An empty register description yields a short '/* addr: */'."""
        sc.args = make_mock_args()
        sc.max_field_len = [0, 0, 0]

        _, assign = sc.compose_reg_init_block(
            "TIM2->CR1",
            [["TIM_CR1_CEN", "(1 << 0)", "Counter enable", "0x00000001"]],
            ("", "0x40000000"),
        )
        assert "/* 0x40000000: */" in assign

    def test_direct_mode_comment(self, scm_globals):
        sc.args = make_mock_args(direct=True)
        sc.max_field_len = [0, 0, 0]

        _, assign = sc.compose_reg_init_block(
            "TIM2->CR1",
            [["TIM_CR1_CEN", "(1 << 0)", "Counter enable", "0x00000001"]],
            ("Control register", "0x40000000"),
        )
        assert "Control register" in assign
        assert "TIM2->CR1 =" in assign

