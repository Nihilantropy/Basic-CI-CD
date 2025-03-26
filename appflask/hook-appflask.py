"""PyInstaller Hook for the appflask package.

This hook ensures that PyInstaller correctly includes all modules and data
within the appflask package when building the executable.
"""

from PyInstaller.utils.hooks import collect_submodules, collect_data_files

# This will collect all imports
hiddenimports = collect_submodules('appflask')

# This will collect all data files (non-Python files)
datas = collect_data_files('appflask')