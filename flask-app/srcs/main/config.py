import os
from typing import Dict, Any

class Config:
    """Base configuration for Flask application."""
    
    # Flask configuration
    DEBUG = False
    TESTING = False
    
    # Rate limiting configuration
    RATE_LIMIT_REQUESTS_PER_MINUTE = 100
    RATE_LIMIT_CODE = 429
    RATE_LIMIT_DEFAULT_RETRY = 60  # Default fallback retry time in seconds
    RATE_LIMIT_MESSAGE = "Rate limit exceeded."
    
    RATELIMIT_ENABLED = True
    RATELIMIT_STORAGE_URI = "memory://"
    RATELIMIT_STRATEGY = "fixed-window"
    RATELIMIT_DEFAULT = f"{RATE_LIMIT_REQUESTS_PER_MINUTE} per minute"
    RATELIMIT_HEADERS_ENABLED = True
    
    # Version information
    VERSION_FILE_PATH = os.getenv("VERSION_FILE_PATH", "version.info")
    
    @classmethod
    def to_dict(cls) -> Dict[str, Any]:
        """Convert config to dictionary for Flask configuration."""
        return {key: getattr(cls, key) for key in dir(cls) 
                if key.isupper() and not key.startswith('_')}


class DevelopmentConfig(Config):
    """Development environment configuration."""
    DEBUG = True


class TestingConfig(Config):
    """Testing environment configuration."""
    TESTING = True
    RATELIMIT_ENABLED = True


class ProductionConfig(Config):
    """Production environment configuration."""
    # For production, we'll still use in-memory storage
    pass


# Configuration dictionary based on environment
config_by_name = {
    'development': DevelopmentConfig,
    'testing': TestingConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}

# Get active configuration
def get_config():
    """Get configuration based on environment variable."""
    env = os.getenv('FLASK_ENV', 'default')
    return config_by_name[env]