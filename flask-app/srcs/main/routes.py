from flask import Blueprint, jsonify
from datetime import datetime
import os
import logging

# Create a blueprint for the routes
main_blueprint = Blueprint('main', __name__)
logger = logging.getLogger(__name__)

# Store version_manager as a global variable to be set later
version_manager = None

def init_version_manager(vm):
    """Initialize the version manager for use in routes.
    
    Args:
        vm: An initialized VersionManager instance
    """
    global version_manager
    version_manager = vm

@main_blueprint.route('/')
def hello_world():
    """Main endpoint that returns a greeting with agent name, version and time."""
    agent_name = os.getenv("AGENT_NAME", "Unknown")
    time_now = datetime.now().strftime("%H:%M")
    version = version_manager.get_version() if version_manager else "unknown"
    
    logger.debug(f"Handling / request, agent: {agent_name}, time: {time_now}, version: {version}")
    
    return jsonify({
        "message": f"Hello, my name is {agent_name} version {version} the time is {time_now}"
    })

@main_blueprint.route('/health')
def health_check():
    """Health check endpoint for monitoring."""
    logger.debug("Health check request received")
    return jsonify({"status": "healthy"}), 200