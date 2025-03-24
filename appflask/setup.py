from setuptools import setup, find_packages

# Read version from file
with open('version.info', 'r') as f:
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