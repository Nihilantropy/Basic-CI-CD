"""PyInstaller Hook for the appflask package.

This hook ensures that PyInstaller correctly includes all modules and data
within the appflask package when building the executable.
"""

from PyInstaller.utils.hooks import collect_data_files, collect_submodules

# Collect all submodules in the appflask package
hiddenimports = collect_submodules("appflask")

# Collect all data files in the appflask package
datas = collect_data_files("appflask")