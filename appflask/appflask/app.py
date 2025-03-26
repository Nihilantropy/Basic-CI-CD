# appflask/app.py
"""Flask application main module.

This module contains the application factory and startup code for the Flask app,
providing endpoints with global rate limiting functionality.
"""

import logging

from flask import Flask

# Import our custom modules
from appflask.config import get_config
from appflask.errors import register_error_handlers
from appflask.limiter import RateLimiterFactory
from appflask.metrics import metrics
from appflask.routes import main_blueprint


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

    # Initialize metrics collection
    metrics.init_app(app)
    app.logger.debug("Metrics collection initialized")

    # Register blueprints
    app.register_blueprint(main_blueprint)

    return app

# Create the Flask application instance for import by other modules
app = create_app()
