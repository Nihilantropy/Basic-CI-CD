from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import logging
import time
from .config import get_config

# Get application configuration
config = get_config()

# Define a global key function that returns the same value for all requests
def global_key_func():
    """Return a static key for all requests to create a truly global rate limit."""
    return "global"

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
        rate_limit_default_retry = config.RATE_LIMIT_DEFAULT_RETRY
        # Create a true 60-second window
        default_limit = f"{requests_per_minute} per {rate_limit_default_retry} seconds"
        
        # Create the limiter with global application defaults
        # Using global_key_func instead of get_remote_address
        limiter = Limiter(
            key_func=global_key_func,  # This is the key change - using our static key function
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