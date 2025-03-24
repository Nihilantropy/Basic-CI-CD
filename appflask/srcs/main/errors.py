"""Error handling module for the Flask application.

This module defines custom error handlers for rate limiting and other errors.
"""
from __future__ import annotations

import logging
import time
from typing import TypeVar

from flask import Flask, Response, jsonify, make_response

from .config import get_config

# Get application configuration
config = get_config()

# Access constants from config
RATE_LIMIT_CODE = config.RATE_LIMIT_CODE
RATE_LIMIT_DEFAULT_RETRY = config.RATE_LIMIT_DEFAULT_RETRY
RATE_LIMIT_MESSAGE = config.RATE_LIMIT_MESSAGE
RATE_LIMIT_REQUESTS_PER_MINUTE = config.RATE_LIMIT_REQUESTS_PER_MINUTE

logger = logging.getLogger(__name__)

# Define a type for rate limit exceptions
ExceptionType = TypeVar("ExceptionType")

# A single global timestamp to track when the rate limit was first hit
global_rate_limit_timestamp = None

# Define a constant for seconds in a minute
SECONDS_IN_MINUTE = 60

def format_retry_time(retry_after: str | int) -> str:
    """Format retry time into a human-readable string.

    Args:
        retry_after: Retry time in seconds or timestamp

    Returns:
        str: Human-readable retry time message

    """
    if isinstance(retry_after, int) or (isinstance(retry_after, str) and
                                        retry_after.isdigit()):
        # If it's seconds
        seconds = int(retry_after)
        if seconds < SECONDS_IN_MINUTE:
            return f"{seconds} second{'s' if seconds != 1 else ''}"

        minutes = seconds // SECONDS_IN_MINUTE
        remaining_seconds = seconds % SECONDS_IN_MINUTE
        time_msg = f"{minutes} minute{'s' if minutes != 1 else ''}"

        if remaining_seconds > 0:
            time_msg += (f" and {remaining_seconds} "
                        f"second{'s' if remaining_seconds != 1 else ''}")
        return time_msg
    # If it's a timestamp or unparseable
    return "some time"

def ratelimit_handler(e: ExceptionType) -> Response:
    """Handle rate limiting errors with a global 60-second window from first hit.

    Args:
        e: The exception that was raised

    Returns:
        Response: A properly formatted error response with accurate time remaining

    """
    # We need to use a module-level variable to track the rate limit timestamp
    # ruff: noqa: PLW0603
    global global_rate_limit_timestamp
    current_time = int(time.time())

    # Log the rate limit event
    logger.warning("Global rate limit exceeded: %s", e)

    # If this is the first time the global rate limit has been hit, store the timestamp
    if global_rate_limit_timestamp is None:
        global_rate_limit_timestamp = current_time
        logger.debug("New global rate limit at timestamp %s", current_time)

    # Calculate how much time remains in the 60-second window
    start_time = global_rate_limit_timestamp
    elapsed_seconds = current_time - start_time
    window_seconds = RATE_LIMIT_DEFAULT_RETRY  # The total window size in seconds

    # Calculate remaining time in the window
    retry_seconds = max(1, window_seconds - elapsed_seconds)

    logger.debug(
        "Rate limit: started at %s, elapsed %ss, remaining %ss",
        start_time,
        elapsed_seconds,
        retry_seconds,
    )

    # If the window has expired, this shouldn't happen but just in case
    if retry_seconds <= 0:
        # Reset the timestamp and allow the request
        logger.debug("Window expired, but still hitting handler. Resetting.")
        global_rate_limit_timestamp = None
        retry_seconds = 1  # Minimal fallback

    # Format retry time for user-friendly message
    time_msg = format_retry_time(retry_seconds)

    # Create the message with string concatenation to avoid f-string with long line
    message = (
        f"The API has exceeded the allowed {RATE_LIMIT_REQUESTS_PER_MINUTE} "
        f"requests per 60 seconds. Please try again in {time_msg}."
    )

    # Create and return the response
    response = make_response(
        jsonify(
            code=RATE_LIMIT_CODE,
            error=RATE_LIMIT_MESSAGE,
            message=message,
            retry_after=retry_seconds,
        ),
        RATE_LIMIT_CODE,
    )

    # Ensure we set the Retry-After header ourselves
    response.headers["Retry-After"] = str(retry_seconds)

    # Reset the global rate limit timestamp if it's been more than double the window
    # This prevents issues if the handler logic has flaws
    double_window = 2 * RATE_LIMIT_DEFAULT_RETRY
    if (global_rate_limit_timestamp is not None and
            (current_time - global_rate_limit_timestamp) > double_window):
        global_rate_limit_timestamp = None

    return response

def register_error_handlers(app: Flask) -> None:
    """Register all error handlers for the application.

    Args:
        app: Flask application instance

    """
    # Register rate limit error handler
    app.errorhandler(RATE_LIMIT_CODE)(ratelimit_handler)

    # Add more error handlers here as needed
    logger.debug("Error handlers registered successfully")
