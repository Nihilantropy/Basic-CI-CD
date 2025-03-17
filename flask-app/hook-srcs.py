"""PyInstaller Hook for the srcs package.

This hook ensures that PyInstaller correctly includes all modules and data
within the srcs package when building the executable.
"""

from PyInstaller.utils.hooks import collect_data_files, collect_submodules

# Collect all submodules in the srcs package
hiddenimports = collect_submodules("srcs")

# Collect all data files in the srcs package
datas = collect_data_files("srcs")