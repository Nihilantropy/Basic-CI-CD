"""Routes module for the Flask application.

This module defines the endpoints available in the application.
"""
import logging
import os
from datetime import datetime, timezone

from flask import Blueprint, Response, jsonify

# Import the global version variable
from appflask.version import get_version

# Create a blueprint for the routes
main_blueprint = Blueprint("main", __name__)
logger = logging.getLogger(__name__)

@main_blueprint.route("/")
def hello_world() -> Response:
    """Return a greeting with agent name, version and time.

    Returns:
        Response: JSON response with greeting message

    """
    agent_name = os.getenv("AGENT_NAME", "Unknown")
    # Use timezone to avoid DTZ005 warning
    time_now = datetime.now(tz=timezone.utc).strftime("%H:%M")

    # Use the global version variable
    version = get_version() if get_version() is not None else "unknown"

    # Use string formatting that doesn't require f-strings for logging
    logger.debug(
        "Handling / request, agent: %s, time: %s, version: %s",
        agent_name,
        time_now,
        version,
    )

    # Break the long f-string into parts for return
    message = (
        f"Hello, my name is {agent_name} version {version} "
        f"the time is {time_now}"
    )

    return jsonify({"message": message})

@main_blueprint.route("/health")
def health_check() -> tuple[Response, int]:
    """Health check endpoint for monitoring.

    Returns:
        tuple: JSON response and HTTP status code

    """
    logger.debug("Health check request received")
    return jsonify({"status": "healthy"}), 200
