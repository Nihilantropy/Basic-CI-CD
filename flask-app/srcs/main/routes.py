from flask import Blueprint, jsonify
from datetime import datetime
import os
import logging

# Import the global version variable
from .version import _version

# Create a blueprint for the routes
main_blueprint = Blueprint('main', __name__)
logger = logging.getLogger(__name__)

@main_blueprint.route('/')
def hello_world():
    """Main endpoint that returns a greeting with agent name, version and time."""
    agent_name = os.getenv("AGENT_NAME", "Unknown")
    time_now = datetime.now().strftime("%H:%M")
    
    # Use the global version variable
    logger.debug(f"Version: {_version}")
    version = _version if _version is not None else "unknown"
    
    logger.debug(f"Handling / request, agent: {agent_name}, time: {time_now}, version: {version}")
    
    return jsonify({
        "message": f"Hello, my name is {agent_name} version {version} the time is {time_now}"
    })

@main_blueprint.route('/health')
def health_check():
    """Health check endpoint for monitoring."""
    logger.debug("Health check request received")
    return jsonify({"status": "healthy"}), 200