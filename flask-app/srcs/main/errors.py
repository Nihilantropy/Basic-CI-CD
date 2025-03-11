from flask import jsonify, request, make_response
import logging
from .config import get_config

# Get application configuration
config = get_config()

# Access constants from config
RATE_LIMIT_CODE = config.RATE_LIMIT_CODE
RATE_LIMIT_DEFAULT_RETRY = config.RATE_LIMIT_DEFAULT_RETRY
RATE_LIMIT_MESSAGE = config.RATE_LIMIT_MESSAGE
RATE_LIMIT_REQUESTS_PER_MINUTE = config.RATE_LIMIT_REQUESTS_PER_MINUTE

logger = logging.getLogger(__name__)

def format_retry_time(retry_after):
    """Format retry time into a human-readable string.
    
    Args:
        retry_after (str or int): Retry time in seconds or timestamp
        
    Returns:
        str: Human-readable retry time message
    """
    if isinstance(retry_after, int) or (isinstance(retry_after, str) and retry_after.isdigit()):
        # If it's seconds
        seconds = int(retry_after)
        if seconds < 60:
            return f"{seconds} second{'s' if seconds != 1 else ''}"
        else:
            minutes = seconds // 60
            remaining_seconds = seconds % 60
            time_msg = f"{minutes} minute{'s' if minutes != 1 else ''}"
            if remaining_seconds > 0:
                time_msg += f" and {remaining_seconds} second{'s' if remaining_seconds != 1 else ''}"
            return time_msg
    else:
        # If it's a timestamp or unparseable
        return "some time"

def ratelimit_handler(e):
    """Handle rate limiting errors.
    
    Args:
        e: The exception that was raised
        
    Returns:
        Response: A properly formatted error response
    """
    logger.warning(f"Rate limit exceeded: {request.remote_addr}")
    
    # Get rate limit information from the limit that was hit
    retry_after = None
    if hasattr(e, 'description') and isinstance(e.description, dict):
        retry_after = e.description.get('retry-after')
    
    # Default retry time if not available
    if retry_after is None:
        if 'Retry-After' in request.headers:
            retry_after = request.headers.get('Retry-After')
        else:
            retry_after = RATE_LIMIT_DEFAULT_RETRY
    
    # Create user-friendly message
    time_msg = format_retry_time(retry_after)
    
    return make_response(
        jsonify(
            error=RATE_LIMIT_MESSAGE,
            message=f"You have exceeded the allowed {RATE_LIMIT_REQUESTS_PER_MINUTE} requests per minute. Please try again in {time_msg}.",
            retry_after=retry_after,
            code=RATE_LIMIT_CODE
        ), 
        RATE_LIMIT_CODE,
        # Set standard Retry-After header
        {'Retry-After': str(retry_after)}
    )

def register_error_handlers(app):
    """Register all error handlers for the application.
    
    Args:
        app: Flask application instance
    """
    # Register rate limit error handler
    app.errorhandler(RATE_LIMIT_CODE)(ratelimit_handler)
    
    # Add more error handlers here as needed
    logger.debug("Error handlers registered successfully")