import pytest
import os
from srcs.main.app import create_app
import time

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
    assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}"
    assert response.json['status'] == 'healthy', f"Expected 'healthy' status, got {response.json}"

def test_hello_world(client):
    # Test the main endpoint
    response = client.get('/')
    assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}"
    
    # Check response structure
    assert 'message' in response.json, f"Expected 'message' key in response: {response.json}"
    message = response.json['message']
    
    # Check each component of the message
    assert 'Hello, my name is' in message, f"Missing greeting in message: {message}"
    assert 'version' in message, f"Missing version in message: {message}"
    assert 'the time is' in message, f"Missing time in message: {message}"

def test_rate_limiting_works(client):
    """Comprehensive test for rate limiting functionality"""
    # Store metrics for detailed reporting
    response_times = []
    status_codes = []
    
    print("\nRunning rate limit test - sending 102 requests...")
    
    # Make 100 requests - these should all succeed
    for i in range(100):
        start_time = time.time()
        response = client.get('/')
        end_time = time.time()
        
        response_times.append(end_time - start_time)
        status_codes.append(response.status_code)
        
        # More detailed assertion with custom message
        assert response.status_code == 200, f"Request #{i+1}/100 failed with status {response.status_code}. Expected 200 OK."
        
        if i % 10 == 0:  # Print progress
            print(f"  Completed {i} requests...")
    
    # The 101st request should be rate limited
    print("  Sending request #101 (should be rate limited)...")
    response = client.get('/')
    assert response.status_code == 429, f"Request #101 should be rate limited with 429, got {response.status_code}"
    assert "error" in response.json, f"Error key missing in rate limited response: {response.json}"
    assert "Rate limit exceeded" in response.json.get("error", ""), f"Unexpected error message: {response.json.get('error')}"
    
    # Test new verbose fields
    assert "message" in response.json, f"Message field missing in rate limited response: {response.json}"
    assert "retry_after" in response.json, f"retry_after field missing in rate limited response: {response.json}"
    assert "Retry-After" in response.headers, f"Retry-After header missing in response headers: {response.headers}"
    
    # Print the actual error message for verification
    print(f"  Rate limit error message: {response.json.get('message')}")
    
    # Check one more to be sure
    print("  Sending request #102 (should also be rate limited)...")
    response = client.get('/')
    assert response.status_code == 429, f"Request #102 should be rate limited with 429, got {response.status_code}"
    
    # Print summary statistics
    successful_requests = status_codes.count(200)
    rate_limited_requests = status_codes.count(429)
    avg_response_time = sum(response_times) / len(response_times) if response_times else 0
    
    print(f"\nRate limiting test summary:")
    print(f"  Total requests sent: {len(status_codes)}")
    print(f"  Successful requests (200): {successful_requests}")
    print(f"  Rate limited requests (429): {rate_limited_requests}")
    print(f"  Average response time: {avg_response_time:.6f} seconds")