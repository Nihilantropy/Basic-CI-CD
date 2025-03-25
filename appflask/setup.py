"""Setup script for the appflask package.

This script installs the appflask package and its dependencies.
"""
from pathlib import Path

from setuptools import find_packages, setup

# Read version from file
with Path("version.info").open() as f:
    version = f.read().strip()

setup(
    name="appflask",
    version=version,
    packages=find_packages(),
    include_package_data=True,
    install_requires=[
        "Flask==3.1.0",
        "flask-limiter==3.10.0",
        "prometheus-client==0.17.1",
    ],
    python_requires=">=3.9",
)
