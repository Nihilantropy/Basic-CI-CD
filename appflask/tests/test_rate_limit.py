import os
import time

import pytest


# Configuration for the tests
class TestConfig:
    # Update these to match your actual endpoints
    ENDPOINTS = [
        "/health",
        "/",  # Add your actual endpoints here
    ]
    # Maximum allowed difference in rate limit counters to consider them global
    MAX_DIFF = 3

@pytest.fixture
def client():
    """Create and return a test client for the Flask app."""
    # Set test environment
    os.environ["FLASK_ENV"] = "testing"

    # Import the app factory function
    from appflask.app import create_app

    # Create app with test configuration
    app = create_app()

    # Set up a test client for the Flask app
    with app.test_client() as client:
        yield client  # This is where the testing happens

@pytest.fixture
def rate_limit_info(client):
    """Fixture to get rate limit information from the application."""
    response = client.get(TestConfig.ENDPOINTS[0])

    # Check if rate limiting headers are present
    if "X-RateLimit-Limit" not in response.headers:
        pytest.skip("Rate limit headers not found. Ensure rate limiting is enabled.")

    limit = int(response.headers.get("X-RateLimit-Limit", 0))
    remaining = int(response.headers.get("X-RateLimit-Remaining", 0))

    # If we're already at the limit, we should check if there's a reset header
    if remaining == 0 and ("X-RateLimit-Reset" in response.headers or "Retry-After" in response.headers):
        reset_seconds = None
        if "X-RateLimit-Reset" in response.headers:
            reset_time = int(response.headers["X-RateLimit-Reset"])
            current_time = int(time.time())
            reset_seconds = max(0, reset_time - current_time)
        elif "Retry-After" in response.headers:
            reset_seconds = int(response.headers["Retry-After"])

        if reset_seconds and reset_seconds < 30:
            print(f"Rate limit exhausted. Waiting {reset_seconds + 1} seconds for reset...")
            time.sleep(reset_seconds + 1)  # Wait for reset
            response = client.get(TestConfig.ENDPOINTS[0])
            remaining = int(response.headers.get("X-RateLimit-Remaining", 0))

    return {
        "limit": limit,
        "remaining": remaining,
    }

def test_global_rate_limit(client, rate_limit_info):
    """Test if rate limit is global across all endpoints."""
    print(f"\nRate limit: {rate_limit_info['limit']} requests per window")
    print(f"Initial remaining: {rate_limit_info['remaining']}")

    # Calculate how many requests to make (75% of the limit to avoid test flakiness)
    requests_to_make = min(rate_limit_info["remaining"], int(rate_limit_info["limit"] * 0.75))

    if requests_to_make < 5:
        pytest.skip("Rate limit too low for effective testing")

    # Make requests to different endpoints - avoid using ThreadPoolExecutor
    # to prevent Flask context issues
    for i in range(requests_to_make):
        endpoint = TestConfig.ENDPOINTS[i % len(TestConfig.ENDPOINTS)]
        client.get(endpoint)

    # Check final remaining count on all endpoints
    results = {}
    for endpoint in TestConfig.ENDPOINTS:
        response = client.get(endpoint)
        remaining = int(response.headers.get("X-RateLimit-Remaining", 0))
        results[endpoint] = remaining
        print(f"Endpoint {endpoint}: {remaining} requests remaining")

    # If rate limit is global, all endpoints should have similar remaining count
    # (with small differences possible due to test execution timing)
    max_difference = max(results.values()) - min(results.values())
    print(f"Maximum difference in remaining counts: {max_difference}")

    # Assert that the difference is within acceptable range
    assert max_difference <= TestConfig.MAX_DIFF, "Rate limits appear to be separate per endpoint"
    print("RESULT: Rate limit appears to be global across endpoints")

def test_rate_limit_enforcement(client):
    """Test if rate limit is properly enforced by reaching the limit."""
    endpoint = TestConfig.ENDPOINTS[0]
    count = 0

    while True:
        response = client.get(endpoint)
        count += 1

        if response.status_code == 429:  # Too Many Requests
            print(f"Hit rate limit after {count} requests")
            break

        remaining = int(response.headers.get("X-RateLimit-Remaining", 0))
        if remaining <= 1:
            print(f"About to hit rate limit after {count} requests")
            response = client.get(endpoint)
            if response.status_code == 429:
                print(f"Confirmed rate limit hit after {count + 1} requests")
                break

        # Safety check to avoid infinite loop
        if count >= 1000:
            pytest.fail("Made 1000 requests without hitting rate limit")
            break

    # Verify we hit the rate limit
    assert response.status_code == 429, "Failed to hit rate limit"
    print("Rate limit enforcement confirmed")

def test_rate_limit_reset(client):
    """Test if rate limit resets after the configured time window.
    
    Note: This test might take several minutes if your rate limit window is long.
    """
    # Get the rate limit reset time from headers
    response = client.get(TestConfig.ENDPOINTS[0])

    # Skip if we're already rate limited
    if response.status_code == 429:
        pytest.skip("Already rate limited. Wait for reset before running this test.")

    # Check for the reset header (might be X-RateLimit-Reset or Retry-After)
    reset_seconds = None

    if "X-RateLimit-Reset" in response.headers:
        reset_time = int(response.headers["X-RateLimit-Reset"])
        current_time = int(time.time())
        reset_seconds = reset_time - current_time
        print(f"Rate limit will reset in approximately {reset_seconds} seconds")
    elif "Retry-After" in response.headers:
        reset_seconds = int(response.headers["Retry-After"])
        print(f"Retry after: {reset_seconds} seconds")

    if reset_seconds and reset_seconds > 120:
        pytest.skip(f"Reset time too long for test: {reset_seconds} seconds")

    # Make enough requests to hit the rate limit
    endpoint = TestConfig.ENDPOINTS[0]
    count = 0

    while True:
        response = client.get(endpoint)
        count += 1

        if response.status_code == 429:  # Too Many Requests
            print(f"Hit rate limit after {count} requests")
            break

        # Safety check to avoid infinite loop
        if count >= 1000:
            pytest.fail("Made 1000 requests without hitting rate limit")
            break

    # Verify we hit the rate limit
    assert response.status_code == 429, "Failed to hit rate limit"

    # Wait a small portion of the reset time to verify we're still rate limited
    if reset_seconds:
        wait_time = min(5, reset_seconds * 0.25)
        print(f"Waiting {wait_time} seconds to check if still rate limited...")
        time.sleep(wait_time)

        response = client.get(endpoint)
        assert response.status_code == 429, "Rate limit should still be in effect"

    # If reset time is short enough, wait for reset and verify
    if reset_seconds and reset_seconds < 30:
        print(f"Waiting {reset_seconds} seconds for rate limit to reset...")
        time.sleep(reset_seconds + 1)  # Add 1 second buffer

        response = client.get(endpoint)
        assert response.status_code != 429, "Rate limit should have reset"
        print("Rate limit reset confirmed")
    else:
        print("Reset time too long to wait. Test skipped.")
