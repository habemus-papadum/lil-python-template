"""Example tests for test-check."""

import test_check


def test_version():
    """Test that the package has a version."""
    assert hasattr(test_check, "__version__")
    assert isinstance(test_check.__version__, str)
    assert len(test_check.__version__) > 0


def test_import():
    """Test that the package can be imported."""
    assert test_check is not None
