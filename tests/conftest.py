"""Pytest fixtures shared across the stm32codegen test suite."""

import os
import sys
import types

import pytest

# Ensure the repo root is on sys.path so we can import the module
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if REPO_ROOT not in sys.path:
    sys.path.insert(0, REPO_ROOT)

import stm32cgen as sc  # noqa: E402
import stm32cmsis  # noqa: E402

FIXTURES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fixtures")


# --------------------------------------------------------------------------- #
#  Synthetic CMSIS header fixture
# --------------------------------------------------------------------------- #

@pytest.fixture
def synthetic_header_text():
    """Load the synthetic F1 CMSIS header used by parsing / codegen tests."""
    path = os.path.join(FIXTURES_DIR, "synthetic_f1.h")
    with open(path, encoding="utf-8") as f:
        return f.read()


@pytest.fixture
def synthetic_header_file(synthetic_header_text, tmp_path):
    """Write the synthetic header to a temp file so read-based code paths work."""
    p = tmp_path / "stm32f103xb.h"
    p.write_text(synthetic_header_text)
    return str(p)


# --------------------------------------------------------------------------- #
#  Mock ``args`` object
# --------------------------------------------------------------------------- #

def make_mock_args(**overrides):
    """Build an argparse.Namespace-like object with sensible defaults.

    Tests can override individual fields via keyword arguments.
    """
    defaults = {
        "cpu": "103c8",
        "direct": False,
        "define": [],
        "header": [],
        "peripheral_enable": None,
        "footer": [],
        "disable_rcc_macro": False,
        "no_fetch": True,
        "save_header_file": False,
        "no_def": False,
        "undef": False,
        "mix": False,
        "light": False,
        "force_inline": False,
        "strict": False,
        "indent": 2,
        "direct_init": None,
        "module": None,
        "main_module": False,
        "pre_init": None,
        "post_init": None,
        "uncomment": None,
        "no_macro": False,
        "function": None,
        "function_header": [],
        "function_footer": [],
        "peripheral": None,
        "irq": False,
        "register": None,
        "test": False,
        "set_bit": None,
        "tag_bit": None,
        "verbose": False,
        "exclude_register": None,
    }
    defaults.update(overrides)
    ns = types.SimpleNamespace(**defaults)
    # Ensure list-typed fields are lists, not None
    for key in ("define", "header", "footer", "function_header", "function_footer"):
        if ns.__dict__.get(key) is None:
            ns.__dict__[key] = []
    return ns


@pytest.fixture
def default_args():
    """A fresh mock args object with default values."""
    return make_mock_args()


@pytest.fixture
def f1_args():
    """Mock args configured for STM32F1 (cpu code '103c8')."""
    return make_mock_args(cpu="103c8")


@pytest.fixture
def g0_args():
    """Mock args configured for STM32G0 (cpu code 'G031F')."""
    return make_mock_args(cpu="G031F")


# --------------------------------------------------------------------------- #
#  Global-state sandbox: save / restore module-level globals
# --------------------------------------------------------------------------- #

_GLOBAL_NAMES = (
    "macro_definition",
    "typedef_list",
    "peripheral_data",
    "register_dic",
    "uniq_type",
    "uniq_addr",
    "bits",
    "modifier",
    "max_field_len",
    "init_macro_name",
    "irq_list",
    "args",
)


@pytest.fixture
def scm_globals():
    """Save and restore all module-level globals used by stm32cgen.

    Yields the stm32cgen module (with globals reset to clean defaults).
    After the test, originals are restored so no state leaks.
    """
    saved = {name: getattr(sc, name, None) for name in _GLOBAL_NAMES}

    sc.args = make_mock_args()
    sc.macro_definition = []
    sc.typedef_list = []
    sc.peripheral_data = []
    sc.register_dic = {}
    sc.uniq_type = set()
    sc.uniq_addr = set()
    sc.bits = []
    sc.modifier = "__STATIC_INLINE"
    sc.max_field_len = [0, 0, 0]
    sc.init_macro_name = set()
    sc.irq_list = []

    yield sc

    for name, val in saved.items():
        setattr(sc, name, val)


# --------------------------------------------------------------------------- #
#  Parsed header fixture: populates globals from the synthetic header
# --------------------------------------------------------------------------- #

@pytest.fixture
def parsed_f1(scm_globals, synthetic_header_text):
    """Populate all module globals from the synthetic F1 header.

    This mocks ``read_cmsis_header_file`` to return the synthetic text,
    then calls ``get_cmsis_header_file`` so all globals (``macro_definition``,
    ``peripheral_data``, ``register_dic``, ``irq_list``, etc.) are set up
    exactly as they would be after fetching a real CMSIS header.

    The ``read_cmsis_header_file`` mock is automatically restored.
    """
    sc.args = make_mock_args(cpu="103c8")
    original_read = sc.read_cmsis_header_file
    sc.read_cmsis_header_file = lambda hdr_name, fetch=True, save=False: synthetic_header_text
    try:
        sc.get_cmsis_header_file("103c8", fetch=False, save=False)
    finally:
        sc.read_cmsis_header_file = original_read

    return sc


@pytest.fixture
def parsed_g0(scm_globals):
    """Parsed state for a G0-family MCU.

    Reuses the F1 synthetic header (the parsing logic is family-agnostic
    for the patterns we test).  Sets ``args.cpu`` to ``G031F`` so that
    family-specific filters in ``get_reg_set`` are exercised.
    """
    synthetic = (
        FIXTURES_DIR + "/synthetic_f1.h"
    )
    with open(synthetic, encoding="utf-8") as f:
        text = f.read()

    sc.args = make_mock_args(cpu="G031F")
    original_read = sc.read_cmsis_header_file
    sc.read_cmsis_header_file = lambda hdr_name, fetch=True, save=False: text
    try:
        sc.get_cmsis_header_file("G031F", fetch=False, save=False)
    finally:
        sc.read_cmsis_header_file = original_read

    return sc
