from flask import Flask
import logging

# Import our custom modules
from .config import get_config
from .limiter import RateLimiterFactory
from .errors import register_error_handlers
from .routes import main_blueprint

# Create a global limiter that will be initialized with the app
limiter = None

def create_app():
    """Application factory function.
    
    Returns:
        Flask: Configured Flask application
    """
    global limiter
    
    app = Flask(__name__)
    
    # Load configuration
    app_config = get_config()
    app.config.from_mapping(app_config.to_dict())
    
    # Configure logging
    logging.basicConfig(level=logging.DEBUG if app.config.get('DEBUG') else logging.INFO)
    app.logger.info("Starting Flask application...")
    
    # Initialize the global rate limiter
    limiter = RateLimiterFactory.create_limiter(app)
    app.logger.debug("Global rate limiter initialized")
    
    # Register error handlers
    register_error_handlers(app)
    
    # Register blueprints
    app.register_blueprint(main_blueprint)
    
    return app


# Create the Flask application instance
app = create_app()

if __name__ == '__main__':
    # Print a message indicating that the app is starting
    app.logger.info("Flask application is starting...")
    app.run(host='0.0.0.0', port=5000)