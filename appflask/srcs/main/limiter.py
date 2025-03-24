"""Rate limiting module for the Flask application.

This module provides a factory for creating rate limiters and a global key function
for implementing application-wide rate limiting.
"""
from __future__ import annotations

import logging
from typing import TYPE_CHECKING

from flask_limiter import Limiter

from .config import get_config

if TYPE_CHECKING:
    from flask import Flask

# Get application configuration
config = get_config()

def global_key_func() -> str:
    """Return a static key for all requests to create a global rate limit.

    Returns:
        str: A static key that's the same for all requests

    """
    return "global"

class RateLimiterFactory:
    """Factory for creating and configuring rate limiters."""

    @staticmethod
    def create_limiter(app: Flask | None = None) -> Limiter:
        """Create and configure a Flask-Limiter instance with global rate limiting.

        Args:
            app: Flask application instance. Defaults to None.

        Returns:
            Limiter: Configured limiter instance

        """
        # Use the constant from config to ensure consistency
        requests_per_minute = config.RATE_LIMIT_REQUESTS_PER_MINUTE
        rate_limit_default_retry = config.RATE_LIMIT_DEFAULT_RETRY

        # Create a true 60-second window
        default_limit = (
            f"{requests_per_minute} per {rate_limit_default_retry} seconds"
        )

        # Create the limiter with global application defaults
        limiter = Limiter(
            # Using our static key function for global rate limiting
            key_func=global_key_func,
            app=app,
            default_limits=[default_limit],
            application_limits=[default_limit],  # This applies globally
            storage_uri="memory://",
            strategy="moving-window",
            headers_enabled=True,
            retry_after="delta-seconds",
        )

        # Configure logging for rate limiter
        logger = logging.getLogger("flask-limiter")
        logger.setLevel(logging.DEBUG)

        return limiter
