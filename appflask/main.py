#!/usr/bin/env python3
"""Flask Application Entry Point.

This file serves as the main entry point for the Flask application,
designed to work correctly with PyInstaller packaging. It properly
imports the application module and runs the server.
"""

import logging
import os
import sys

# Configure root logger
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


def main() -> None:
    """Initialize and run the Flask application."""
    try:
        # Import the application factory
        from srcs.main.app import create_app

        # Create the Flask application
        app = create_app()

        # Log configuration details
        flask_env = os.getenv("FLASK_ENV", "development")
        agent_name = os.getenv("AGENT_NAME", "Unknown")
        logger.info("Starting Flask application: env=%s, agent=%s", flask_env, agent_name)

        # Run the application - S104 issue can be ignored for development
        # In production, this would be handled by a WSGI server
        app.run(host="0.0.0.0", port=5000)  # noqa: S104

    except ImportError:
        logger.exception("Import error")
        logger.error("This may be due to incorrect package structure or missing dependencies")
        sys.exit(1)
    except Exception:
        logger.exception("Application failed to start")
        sys.exit(1)


if __name__ == "__main__":
    main()