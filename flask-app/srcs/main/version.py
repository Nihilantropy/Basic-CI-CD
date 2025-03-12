# Simple version module for Flask app
# This placeholder will be replaced by the Jenkins pipeline

# Version placeholder that will be replaced during CI/CD pipeline
VERSION = "${PLACEHOLDER_VERSION}"

def get_version():
    """Get the application version.
    
    Returns:
        str: The version string
    """
    return VERSION