import pytest
import os
from srcs.main.app import create_app

@pytest.fixture
def client():
    # Set test environment
    os.environ['FLASK_ENV'] = 'testing'
    
    # Create app with test configuration
    app = create_app()
    
    # Set up a test client for the Flask app
    with app.test_client() as client:
        yield client  # This is where the testing happens

def test_health(client):
    # Test the /health endpoint
    response = client.get('/health')
    assert response.status_code == 200
    assert response.json['status'] == 'healthy'

def test_hello_world(client):
    # Test the main endpoint
    response = client.get('/')
    assert response.status_code == 200
    assert 'message' in response.json
    assert 'Hello, my name is' in response.json['message']
    assert 'the time is' in response.json['message']
    assert 'version' in response.json['message']

def test_rate_limiting_works(client):
    # Test that rate limiting is working properly
    # Make 100 requests - these should all succeed
    for i in range(100):
        response = client.get('/')
        assert response.status_code == 200, f"Request {i+1} should succeed but got {response.status_code}"
    
    # The 101st request should be rate limited
    response = client.get('/')
    assert response.status_code == 429, "Request #101 should be rate limited"
    assert "Rate limit exceeded" in response.json.get("error", "")