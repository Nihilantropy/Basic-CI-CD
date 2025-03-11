from flask import Flask
import logging

# Import our custom modules
from .config import get_config
from .limiter import RateLimiterFactory
from .version import VersionManager
from .errors import register_error_handlers
from .routes import main_blueprint

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
    version_file_path = app.config.get('VERSION_FILE_PATH', 'version.info')
    app.logger.debug(f"Using version file path from config: {version_file_path}")
    version_manager = VersionManager(version_file_path)
    
    # Initialize rate limiter
    limiter = RateLimiterFactory.create_limiter(app)
    
    # Register error handlers
    register_error_handlers(app)
    
    # Register blueprints
    app.register_blueprint(main_blueprint)
    
    return app


# Create the Flask application instance
app = create_app()

if __name__ == '__main__':
    # Print a message indicating that the app is starting
    print("We are live!")
    app.logger.info("Flask application is starting...")
    app.run(host='0.0.0.0', port=5000)