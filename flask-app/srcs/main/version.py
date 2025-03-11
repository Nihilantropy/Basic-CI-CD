import os
import logging


class VersionManager:
    """Manages application version information."""
    
    def __init__(self, version_file_path):
        """Initialize with the path to the version file.
        
        Args:
            version_file_path (str): Path to the version.info file
        """
        self.version_file_path = version_file_path
        self._version = None
        self.logger = logging.getLogger(__name__)
    
    def get_version(self):
        """Read and return the application version from file.
        
        Returns:
            str: The version string or "unknown" if not found
        """
        if self._version:
            return self._version
            
        try:
            if os.path.exists(self.version_file_path):
                with open(self.version_file_path, 'r') as f:
                    self._version = f.read().strip()
                return self._version
            else:
                self.logger.warning(f"Version file not found at {self.version_file_path}")
                return "unknown"
        except Exception as e:
            self.logger.error(f"Error reading version file: {e}")
            return "unknown"