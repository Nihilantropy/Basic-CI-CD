"""Tests for the metrics module.

This module contains tests for the Prometheus metrics functionality.
"""
import logging
import time

import pytest
from prometheus_client.parser import text_string_to_metric_families

from appflask.app import create_app

logger = logging.getLogger(__name__)

@pytest.fixture
def client():
    """Create and return a test client for the Flask app."""
    # Set test environment
    app = create_app()
    with app.test_client() as client:
        yield client

def test_metrics_endpoint_exists(client):
    """Test that the /metrics endpoint exists and returns a valid response."""
    response = client.get("/metrics")
    assert response.status_code == 200
    assert response.content_type == 'text/plain; version=0.0.4; charset=utf-8'

def test_metrics_content(client):
    """Test that the metrics endpoint returns valid Prometheus metrics."""
    # First make a request to generate some metrics
    client.get("/")
    
    # Then check metrics
    response = client.get("/metrics")
    metrics_data = response.data.decode('utf-8')
    
    # Use prometheus_client parser to validate metrics format
    families = list(text_string_to_metric_families(metrics_data))
    
    # Check that we have metrics
    assert len(families) > 0
    
    # Check for specific metrics - using the family names
    metric_names = [family.name for family in families]
    expected_metrics = [
        'http_requests',  # This is the family name, not the sample name
        'http_request_duration_seconds',
        'app_info',
        'app_uptime_seconds',
        'app_start_time_seconds'
    ]
    
    for metric in expected_metrics:
        assert metric in metric_names, f"Expected metric {metric} not found"
        
    # Also check that the _total suffix exists in the raw output for counters
    assert 'http_requests_total{' in metrics_data

def test_request_metrics_increment(client):
    """Test that request metrics increment when endpoints are called."""
    # Get initial metrics
    response = client.get("/metrics")
    initial_metrics = response.data.decode('utf-8')
    
    # Parse initial metrics to get counter values
    from prometheus_client.parser import text_string_to_metric_families
    initial_values = {}
    for family in text_string_to_metric_families(initial_metrics):
        if family.name == 'http_requests':
            for sample in family.samples:
                if sample.name == 'http_requests_total':
                    key = (sample.labels['endpoint'], sample.labels['method'], sample.labels['status'])
                    initial_values[key] = sample.value
    
    # Make requests to different endpoints
    client.get("/")
    client.get("/health")
    
    # Get updated metrics
    response = client.get("/metrics")
    updated_metrics = response.data.decode('utf-8')
    
    # Parse updated metrics
    updated_values = {}
    for family in text_string_to_metric_families(updated_metrics):
        if family.name == 'http_requests':
            for sample in family.samples:
                if sample.name == 'http_requests_total':
                    key = (sample.labels['endpoint'], sample.labels['method'], sample.labels['status'])
                    updated_values[key] = sample.value
    
    # Verify at least one metric increased
    increases_found = False
    for key in updated_values:
        if key in initial_values and updated_values[key] > initial_values[key]:
            increases_found = True
            break
    
    assert increases_found, "No metrics increased after making HTTP requests"

def test_raw_metrics_output(client):
    """Test the raw output of the metrics endpoint."""
    client.get("/")  # Generate some metrics
    response = client.get("/metrics")
    metrics_text = response.data.decode('utf-8')
    print(f"METRICS OUTPUT:\n{metrics_text}")
    assert 'http_requests' in metrics_text