from flask import Flask, jsonify, request, make_response
from datetime import datetime
import os
import logging

# Import our custom modules
from .config import get_config
from .limiter import RateLimiterFactory
from .version import VersionManager


def create_app():
    """Application factory function.
    
    Returns:
        Flask: Configured Flask application
    """
    app = Flask(__name__)
    
    # Load configuration
    app_config = get_config()
    app.config.from_object(app_config.to_dict())
    
    # Configure logging
    logging.basicConfig(level=logging.DEBUG if app.config.get('DEBUG') else logging.INFO)
    app.logger.info("Starting Flask application...")
    
    # Initialize version manager
    version_manager = VersionManager(app.config.get('VERSION_FILE_PATH', 'version.info'))
    
    # Initialize rate limiter
    limiter = RateLimiterFactory.create_limiter(app)
    
    # Register error handler for rate limit exceeded
    @app.errorhandler(429)
    def ratelimit_handler(e):
        app.logger.warning(f"Rate limit exceeded: {request.remote_addr}")
        return make_response(
            jsonify(error="Rate limit exceeded. Please try again later.", 
                   code=429), 
            429
        )
    
    @app.route('/')
    def hello_world():
        agent_name = os.getenv("AGENT_NAME", "Unknown")
        time_now = datetime.now().strftime("%H:%M")
        version = version_manager.get_version()
        
        app.logger.debug(f"Handling / request, agent: {agent_name}, time: {time_now}, version: {version}")
        
        return jsonify({
            "message": f"Hello, my name is {agent_name} version {version} the time is {time_now}"
        })
    
    @app.route('/health')
    def health_check():
        app.logger.debug("Health check request received")
        return jsonify({"status": "healthy"}), 200
    
    return app


# Create the Flask application instance
app = create_app()

if __name__ == '__main__':
    # Print a message indicating that the app is starting
    app.logger.debug("We are live!")
    app.logger.info("Flask application is starting...")
    app.run(host='0.0.0.0', port=5000)