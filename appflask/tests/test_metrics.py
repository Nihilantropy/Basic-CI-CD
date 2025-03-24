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
    
    # Check for specific metrics
    metric_names = [family.name for family in families]
    expected_metrics = [
        'http_requests_total',
        'http_request_duration_seconds',
        'app_info',
        'app_uptime_seconds',
        'app_start_time_seconds'
    ]
    
    for metric in expected_metrics:
        assert metric in metric_names, f"Expected metric {metric} not found"

def test_request_metrics_increment(client):
    """Test that request metrics increment when endpoints are called."""
    # Get initial metrics
    response = client.get("/metrics")
    initial_metrics = response.data.decode('utf-8')
    
    # Make requests to different endpoints
    client.get("/")
    client.get("/health")
    
    # Get updated metrics
    response = client.get("/metrics")
    updated_metrics = response.data.decode('utf-8')
    
    # Verify metrics have changed (simple length check for brevity)
    assert len(updated_metrics) > len(initial_metrics)

def test_app_version_in_metrics(client):
    """Test that app version information is included in metrics."""
    from appflask.version import get_version
    
    response = client.get("/metrics")
    metrics_data = response.data.decode('utf-8')
    
    # Check that version is in metrics
    assert f'app_info{{version="{get_version()}"}}' in metrics_data

def test_uptime_metric_increases(client):
    """Test that uptime metric increases over time."""
    # Get initial metrics
    response = client.get("/metrics")
    initial_metrics = response.data.decode('utf-8')
    
    # Wait a short time
    time.sleep(0.5)
    
    # Get updated metrics
    response = client.get("/metrics")
    updated_metrics = response.data.decode('utf-8')
    
    # Extract uptime values (simplified approach)
    # In a real test, we would use the parser for more robust extraction
    initial_uptime_line = [line for line in initial_metrics.split('\n') 
                         if line.startswith('app_uptime_seconds')][0]
    updated_uptime_line = [line for line in updated_metrics.split('\n') 
                         if line.startswith('app_uptime_seconds')][0]
    
    # Extract numeric values (this is a simplification)
    initial_uptime = float(initial_uptime_line.split()[1])
    updated_uptime = float(updated_uptime_line.split()[1])
    
    # Uptime should increase
    assert updated_uptime > initial_uptime