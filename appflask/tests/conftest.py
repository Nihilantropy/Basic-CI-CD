"""Configure pytest testing environment.

This module provides fixtures and configuration for pytest.
"""
import os
import sys
import pytest

# Add the parent directory to the path so we can import appflask
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# Now try importing from appflask
from appflask.app import create_app

@pytest.fixture
def app():
    """Create and return a test Flask app."""
    app = create_app()
    app.config.update({
        "TESTING": True,
    })
    return app

@pytest.fixture
def client(app):
    """Create and return a test client for the Flask app."""
    return app.test_client()