"""Metrics collection and exposure module for the Flask application."""
from __future__ import annotations

import logging
import time
from typing import Optional

from flask import Flask, Response, request
from prometheus_client import Counter, Gauge, Histogram, REGISTRY, CollectorRegistry
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST

# Initialize logger
logger = logging.getLogger(__name__)

# Create a custom registry for our metrics
CUSTOM_REGISTRY = CollectorRegistry(auto_describe=True)

# Define metrics with our custom registry
REQUEST_COUNT = Counter(
    'http_requests_total',
    'Total number of HTTP requests',
    ['method', 'endpoint', 'status'],
    registry=CUSTOM_REGISTRY
)

REQUEST_LATENCY = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency in seconds',
    ['method', 'endpoint'],
    registry=CUSTOM_REGISTRY
)

IN_FLIGHT = Gauge(
    'http_requests_in_flight',
    'Current number of HTTP requests in flight',
    registry=CUSTOM_REGISTRY
)

RATE_LIMIT_COUNT = Counter(
    'http_rate_limit_hits_total',
    'Total number of rate limit hits',
    registry=CUSTOM_REGISTRY
)

RATE_LIMIT_REMAINING = Gauge(
    'http_rate_limit_remaining',
    'Remaining requests in current rate limit window',
    registry=CUSTOM_REGISTRY
)

APP_INFO = Gauge(
    'app_info',
    'Application information',
    ['version'],
    registry=CUSTOM_REGISTRY
)

APP_START_TIME = Gauge(
    'app_start_time_seconds',
    'Unix timestamp of application start time',
    registry=CUSTOM_REGISTRY
)

APP_UPTIME = Gauge(
    'app_uptime_seconds',
    'Application uptime in seconds',
    registry=CUSTOM_REGISTRY
)


class MetricsCollector:
    """Collector for application metrics using Prometheus client."""

    def __init__(self, app: Optional[Flask] = None) -> None:
        """Initialize metrics collector with optional Flask app."""
        self.app = app
        self.start_time = time.time()
        APP_START_TIME.set(self.start_time)
        
        # Initialize with some default values to ensure metrics appear
        self._initialize_default_metrics()
        
        if app is not None:
            self.init_app(app)

    def _initialize_default_metrics(self) -> None:
        """Initialize metrics with default values to ensure they appear."""
        # Initialize http_requests_total with 0
        REQUEST_COUNT.labels(method='GET', endpoint='/', status=200).inc(0)
        
        # Initialize request latency with a sample
        REQUEST_LATENCY.labels(method='GET', endpoint='/').observe(0.001)
        
        # Initialize app_info with version
        from appflask.version import get_version
        APP_INFO.labels(version=get_version()).set(1)
        
        # Set uptime
        APP_UPTIME.set(0)
        
        logger.debug("Default metrics initialized")

    def init_app(self, app: Flask) -> None:
        """Initialize metrics collection for a Flask application."""
        self.app = app
        
        # Register metrics endpoint
        app.add_url_rule('/metrics', 'metrics', self.metrics)
        
        # Register before/after request handlers
        app.before_request(self.before_request)
        app.after_request(self.after_request)
        
        logger.debug("Metrics collection initialized")

    def before_request(self) -> None:
        """Handle tasks before each request, like tracking in-flight requests."""
        # Store start time for calculating request duration
        request.start_time = time.time()
        
        # Increment in-flight requests counter
        IN_FLIGHT.inc()

    def after_request(self, response: Response) -> Response:
        """Handle tasks after each request, like recording metrics."""
        # Skip metrics endpoint to avoid circular measurements
        if request.endpoint != 'metrics':
            # Record request latency
            latency = time.time() - getattr(request, 'start_time', time.time())
            REQUEST_LATENCY.labels(
                method=request.method,
                endpoint=request.endpoint or 'unknown'
            ).observe(latency)
            
            # Record request count
            REQUEST_COUNT.labels(
                method=request.method,
                endpoint=request.endpoint or 'unknown',
                status=response.status_code
            ).inc()
            
            # Record rate limit information if available
            if response.status_code == 429:
                RATE_LIMIT_COUNT.inc()
            
            # Capture rate limit headers if present
            remaining = response.headers.get('X-RateLimit-Remaining')
            if remaining and remaining.isdigit():
                RATE_LIMIT_REMAINING.set(int(remaining))
                
        # Decrement in-flight requests
        IN_FLIGHT.dec()
        
        return response

    def metrics(self) -> Response:
        """Generate Prometheus metrics page."""
        # Update uptime metric
        APP_UPTIME.set(time.time() - self.start_time)
        
        # Debug logging
        metric_names = [metric.name for metric in CUSTOM_REGISTRY.collect()]
        logger.debug("Available metrics: %s", metric_names)
        
        # Generate metrics from our custom registry
        metrics_data = generate_latest(CUSTOM_REGISTRY)
        
        # Create response with correct content type
        response = Response(metrics_data)
        response.headers['Content-Type'] = CONTENT_TYPE_LATEST
        
        for metric in CUSTOM_REGISTRY.collect():
            logger.debug("Registered metric: %s", metric.name)
        
        return response


# Create a global metrics collector instance
metrics = MetricsCollector()