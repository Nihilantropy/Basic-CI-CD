"""Application tests.

This module contains tests for the main Flask application.
"""
import logging
import os
import pytest

from appflask.app import create_app

logger = logging.getLogger(__name__)

@pytest.fixture
def client():
    """Create and return a test client for the Flask app."""
    # Set test environment
    os.environ["FLASK_ENV"] = "testing"

    # Create app with test configuration
    app = create_app()

    # Set up a test client for the Flask app
    with app.test_client() as client:
        yield client  # This is where the testing happens

def test_health(client):
    """Test the health check endpoint."""
    # Test the /health endpoint
    response = client.get("/health")
    assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}"
    assert response.json["status"] == "healthy", f"Expected 'healthy' status, got {response.json}"

def test_hello_world(client):
    """Test the main endpoint."""
    # Test the main endpoint
    response = client.get("/")
    assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}"

    # Check response structure
    assert "message" in response.json, f"Expected 'message' key in response: {response.json}"
    message = response.json["message"]

    # Check each component of the message
    assert "Hello, my name is" in message, f"Missing greeting in message: {message}"
    assert "version" in message, f"Missing version in message: {message}"
    assert "the time is" in message, f"Missing time in message: {message}"