"""Flask application main module.

This module contains the application factory and startup code for the Flask app,
providing endpoints with global rate limiting functionality.
"""

import logging

from flask import Flask

# Import our custom modules
from .config import get_config
from .errors import register_error_handlers
from .limiter import RateLimiterFactory
from .routes import main_blueprint


def create_app() -> Flask:
    """Application factory function.

    Returns:
        Flask: Configured Flask application

    """
    app = Flask(__name__)

    # Load configuration
    app_config = get_config()
    app.config.from_mapping(app_config.to_dict())

    # Configure logging
    log_level = logging.DEBUG if app.config.get("DEBUG") else logging.INFO
    logging.basicConfig(level=log_level)
    app.logger.info("Starting Flask application...")

    # Initialize the rate limiter
    app.limiter = RateLimiterFactory.create_limiter(app)
    app.logger.debug("Rate limiter initialized")

    # Register error handlers
    register_error_handlers(app)

    # Register blueprints
    app.register_blueprint(main_blueprint)

    return app

# Create the Flask application instance
app = create_app()

if __name__ == "__main__":
    # Use logger instead of print
    app.logger.info("We are live!")
    app.logger.info("Flask application is starting...")
    # For local development only; in production, use a proper WSGI server
    # S104 issue can be ignored for development, but address in production
    app.run(host="0.0.0.0", port=5000)  # noqa: S104
