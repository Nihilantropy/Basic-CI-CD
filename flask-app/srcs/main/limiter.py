from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import logging
from .config import get_config

# Get application configuration
config = get_config()

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
        # Use the constant from config to ensure consistency
        default_limit = f"{config.RATE_LIMIT_REQUESTS_PER_MINUTE} per minute"
        
        limiter = Limiter(
            key_func=get_remote_address,
            app=app,
            default_limits=[default_limit],
            storage_uri="memory://",
            strategy=app.config.get("RATELIMIT_STRATEGY", "fixed-window") if app else "fixed-window",
            headers_enabled=True,
            retry_after="http-date"  # This provides a timestamp for retry-after
        )
        
        # Configure custom filter for rate limiting
        @limiter.request_filter
        def health_check_filter():
            """Exclude health check endpoint from rate limiting."""
            from flask import request
            return request.path == "/health"
            
        # Apply rate limiting to our blueprint routes
        if app:
            from .routes import main_blueprint
            limiter.limit(default_limit)(main_blueprint)
        
        # Configure logging for rate limiter
        logger = logging.getLogger("flask-limiter")
        logger.setLevel(logging.INFO)
        
        return limiter