import pytest
from srcs.main.app import app

@pytest.fixture
def client():
    # Set up a test client for the Flask app
    with app.test_client() as client:
        yield client  # This is where the testing happens

def test_health(client):
    # Test the /health endpoint
    response = client.get('/health')
    assert response.status_code == 200
