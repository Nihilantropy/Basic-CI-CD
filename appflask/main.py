#!/usr/bin/env python3
"""Flask Application Entry Point.

This file serves as the main entry point for the Flask application,
designed to work correctly with PyInstaller packaging.
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

    except ImportError:
        logger.exception("Import error")
        logger.exception("This may be due to incorrect package structure or missing dependencies")
        sys.exit(1)
    except Exception:
        logger.exception("Application failed to start")
        sys.exit(1)


if __name__ == "__main__":
    main()
