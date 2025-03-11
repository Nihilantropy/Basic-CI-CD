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
    app.config.from_mapping(app_config.to_dict())
    
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
        
        # Get rate limit information from the limit that was hit
        # The retry-after header is set by Flask-Limiter
        retry_after = None
        if hasattr(e, 'description') and isinstance(e.description, dict):
            retry_after = e.description.get('retry-after')
        
        # Default retry time if not available
        if retry_after is None:
            if 'Retry-After' in request.headers:
                retry_after = request.headers.get('Retry-After')
            else:
                retry_after = 60  # default fallback
        
        # Create user-friendly message
        if isinstance(retry_after, int) or retry_after.isdigit():
            # If it's seconds
            seconds = int(retry_after)
            if seconds < 60:
                time_msg = f"{seconds} second{'s' if seconds != 1 else ''}"
            else:
                minutes = seconds // 60
                remaining_seconds = seconds % 60
                time_msg = f"{minutes} minute{'s' if minutes != 1 else ''}"
                if remaining_seconds > 0:
                    time_msg += f" and {remaining_seconds} second{'s' if remaining_seconds != 1 else ''}"
        else:
            # If it's a timestamp or unparseable
            time_msg = "some time"
        
        return make_response(
            jsonify(
                error="Rate limit exceeded.",
                message=f"You have exceeded the allowed 100 requests per minute. Please try again in {time_msg}.",
                retry_after=retry_after,
                code=429
            ), 
            429,
            # Set standard Retry-After header
            {'Retry-After': str(retry_after)}
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
    print("We are live!")
    app.logger.info("Flask application is starting...")
    app.run(host='0.0.0.0', port=5000)