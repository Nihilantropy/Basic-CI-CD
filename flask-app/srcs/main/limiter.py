from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import logging
import time
from .config import get_config

# Get application configuration
config = get_config()

class RateLimiterFactory:
    """Factory for creating and configuring rate limiters."""
    
    @staticmethod
    def create_limiter(app=None):
        """Create and configure a Flask-Limiter instance with global rate limiting.
        
        Args:
            app (Flask, optional): Flask application instance. Defaults to None.
            
        Returns:
            Limiter: Configured limiter instance
        """
        # Use the constant from config to ensure consistency
        requests_per_minute = config.RATE_LIMIT_REQUESTS_PER_MINUTE
        
        # Create a true 60-second window
        default_limit = f"{requests_per_minute} per 60 seconds"
        
        # Create the limiter with global application defaults
        limiter = Limiter(
            key_func=get_remote_address,
            app=app,
            default_limits=[default_limit],
            application_limits=[default_limit],  # This applies globally
            storage_uri="memory://",
            strategy="moving-window",
            headers_enabled=True,
            retry_after="delta-seconds"
        )

        # Configure logging for rate limiter
        logger = logging.getLogger("flask-limiter")
        logger.setLevel(logging.DEBUG)
        
        return limiter