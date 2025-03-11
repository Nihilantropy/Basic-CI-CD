from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import logging


class RateLimiterFactory:
    """Factory for creating and configuring rate limiters."""
    
    @staticmethod
    def create_limiter(app=None):
        """Create and configure a Flask-Limiter instance.
        
        Args:
            app (Flask, optional): Flask application instance. Defaults to None.
            
        Returns:
            Limiter: Configured limiter instance
        """
        limiter = Limiter(
            key_func=get_remote_address,
            app=app,
            default_limits=["100 per minute"],
            storage_uri="memory://",
            strategy=app.config.get("RATELIMIT_STRATEGY", "fixed-window") if app else "fixed-window",
            headers_enabled=True,
            retry_after="http-date"  # This provides a timestamp for retry-after
        )
        
        # Configure custom error handler for rate limiting
        @limiter.request_filter
        def health_check_filter():
            """Exclude health check endpoint from rate limiting."""
            from flask import request
            return request.path == "/health"
        
        # Configure logging for rate limiter
        logger = logging.getLogger("flask-limiter")
        logger.setLevel(logging.INFO)
        
        return limiter