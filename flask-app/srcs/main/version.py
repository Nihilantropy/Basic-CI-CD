import os
import logging

# Global version variable that will be accessible throughout the application
_version = None

class VersionManager:
    """Manages application version information."""
    
    def __init__(self, version_file_path):
        """Initialize with the path to the version file.
        
        Args:
            version_file_path (str): Path to the version.info file
        """
        self.version_file_path = version_file_path
        self.logger = logging.getLogger(__name__)
        
        # Initialize the global version variable
        self._initialize_version()
    
    def _initialize_version(self):
        """Read the version from file and set it as a global variable."""
        global _version
        
        try:
            if os.path.exists(self.version_file_path):
                with open(self.version_file_path, 'r') as f:
                    version_content = f.read().strip()
                    
                    if not version_content:
                        self.logger.error("Version file cannot be empty")
                        raise ValueError("Version file cannot be empty")
                    
                    # Optionally validate version length
                    if len(version_content) > 8:
                        self.logger.warning(f"Version string is longer than 8 characters: {version_content}")
                    
                    # Set the global version variable
                    _version = version_content
                    self.logger.info(f"Initialized version: {_version}")
            else:
                self.logger.error(f"Version file not found at {self.version_file_path}")
                raise FileNotFoundError(f"Version file not found at {self.version_file_path}")
        except Exception as e:
            self.logger.error(f"Error initializing version: {e}")
            raise

return _version