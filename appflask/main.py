#!/usr/bin/env python3
"""Flask Application Entry Point.

This file serves as the main entry point for the Flask application,
designed to work correctly with PyInstaller packaging.
"""
import logging
import os
import sys

# Add the current directory to the Python path to help with imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Configure root logger
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

def main() -> None:
    """Initialize and run the Flask application."""
    try:
        # Print current working directory and Python path for debugging
        logger.info("Current working directory: %s", os.getcwd())
        logger.info("Python path: %s", sys.path)
        
        # Try to import the appflask package
        from appflask.app import create_app
        app = create_app()

        flask_env = os.getenv("FLASK_ENV", "development")
        agent_name = os.getenv("AGENT_NAME", "Unknown")
        logger.info(
            "Starting Flask application: env=%s, agent=%s",
            flask_env,
            agent_name,
        )

        # Use an environment variable to configure host and port,
        # defaulting to safe values for non-development environments.
        host = os.getenv("FLASK_RUN_HOST", "0.0.0.0" if flask_env == "development" else "127.0.0.1")
        port = int(os.getenv("FLASK_RUN_PORT", "5000"))
        app.run(host=host, port=port)

    except ImportError as e:
        logger.exception("Import error: %s", e)
        logger.error("This may be due to incorrect package structure or missing dependencies")
        logger.error("Python path: %s", sys.path)
        sys.exit(1)
    except Exception as e:
        logger.exception("Application failed to start: %s", e)
        sys.exit(1)


if __name__ == "__main__":
    main()