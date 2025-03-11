from flask import jsonify, request, make_response
import logging
import time
from datetime import datetime
from .config import get_config

# Get application configuration
config = get_config()

# Access constants from config
RATE_LIMIT_CODE = config.RATE_LIMIT_CODE
RATE_LIMIT_DEFAULT_RETRY = config.RATE_LIMIT_DEFAULT_RETRY
RATE_LIMIT_MESSAGE = config.RATE_LIMIT_MESSAGE
RATE_LIMIT_REQUESTS_PER_MINUTE = config.RATE_LIMIT_REQUESTS_PER_MINUTE

logger = logging.getLogger(__name__)

# A single global timestamp to track when the rate limit was first hit
global_rate_limit_timestamp = None

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
    """Handle rate limiting errors with a global 60-second window from first hit.
    
    Args:
        e: The exception that was raised
        
    Returns:
        Response: A properly formatted error response with accurate time remaining
    """
    global global_rate_limit_timestamp
    current_time = int(time.time())
    
    # Log the rate limit event
    logger.warning("Global rate limit exceeded")
    
    # If this is the first time the global rate limit has been hit, store the timestamp
    if global_rate_limit_timestamp is None:
        global_rate_limit_timestamp = current_time
        logger.debug(f"New global rate limit at timestamp {current_time}")
    
    # Calculate how much time remains in the 60-second window
    start_time = global_rate_limit_timestamp
    elapsed_seconds = current_time - start_time
    window_seconds = RATE_LIMIT_DEFAULT_RETRY  # The total window size in seconds
    
    # Calculate remaining time in the window
    retry_seconds = max(1, window_seconds - elapsed_seconds)
    
    logger.debug(f"Rate limit: started at {start_time}, elapsed {elapsed_seconds}s, remaining {retry_seconds}s")
    
    # If the window has expired, this shouldn't happen but just in case
    if retry_seconds <= 0:
        # Reset the timestamp and allow the request
        logger.debug("Window expired, but still hitting handler. Resetting.")
        global_rate_limit_timestamp = None
        retry_seconds = 1  # Minimal fallback
    
    # Format retry time for user-friendly message
    time_msg = format_retry_time(retry_seconds)
    
    # Create and return the response
    response = make_response(
        jsonify(
            code=RATE_LIMIT_CODE,
            error=RATE_LIMIT_MESSAGE,
            message=f"The API has exceeded the allowed {RATE_LIMIT_REQUESTS_PER_MINUTE} requests per 60 seconds. Please try again in {time_msg}.",
            retry_after=retry_seconds
        ), 
        RATE_LIMIT_CODE
    )
    
    # Ensure we set the Retry-After header ourselves
    response.headers['Retry-After'] = str(retry_seconds)
    
    # Reset the global rate limit timestamp if it's been more than double the window time
    # This prevents issues if the handler logic has flaws
    if global_rate_limit_timestamp is not None and (current_time - global_rate_limit_timestamp) > (2 * RATE_LIMIT_DEFAULT_RETRY):
        global_rate_limit_timestamp = None
    
    return response

def register_error_handlers(app):
    """Register all error handlers for the application.
    
    Args:
        app: Flask application instance
    """
    # Register rate limit error handler
    app.errorhandler(RATE_LIMIT_CODE)(ratelimit_handler)
    
    # Add more error handlers here as needed
    logger.debug("Error handlers registered successfully")