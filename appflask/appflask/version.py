"""Version module for the Flask application.

This module provides access to the application version information.
"""

# Version placeholder that will be replaced during CI/CD pipeline
VERSION = "${PLACEHOLDER_VERSION}"

def get_version() -> str:
    """Get the application version.

    Returns:
        str: The version string

    """
    return VERSION
