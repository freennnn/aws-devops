"""
pytest configuration file for Flask Hello World application tests.

This file contains shared fixtures and configuration for all test modules.
"""

import pytest
import sys
import os

# Add the parent directory to the path so we can import the main module
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app


@pytest.fixture(scope='session')
def test_app():
    """Create a Flask application configured for testing."""
    app.config['TESTING'] = True
    app.config['WTF_CSRF_ENABLED'] = False
    app.config['DEBUG'] = False
    
    return app


@pytest.fixture(scope='function')
def client(test_app):
    """Create a test client for the Flask application."""
    with test_app.test_client() as client:
        with test_app.app_context():
            yield client


@pytest.fixture(scope='function')
def runner(test_app):
    """Create a test CLI runner for the Flask application."""
    return test_app.test_cli_runner()


# Pytest configuration
def pytest_configure(config):
    """Configure pytest settings."""
    config.addinivalue_line(
        "markers", "slow: marks tests as slow (deselect with '-m \"not slow\"')"
    )
    config.addinivalue_line(
        "markers", "integration: marks tests as integration tests"
    )
    config.addinivalue_line(
        "markers", "unit: marks tests as unit tests"
    )


def pytest_collection_modifyitems(config, items):
    """Modify test collection to add markers automatically."""
    for item in items:
        # Add 'unit' marker to all tests by default
        if not any(marker.name in ['integration', 'slow'] for marker in item.iter_markers()):
            item.add_marker(pytest.mark.unit) 