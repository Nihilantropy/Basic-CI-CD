# Flask App Documentation

## Table of Contents
1. [Introduction](#introduction)
2. [Application Structure](#application-structure)
3. [Configuration](#configuration)
4. [Rate Limiting](#rate-limiting)
5. [Version Management](#version-management)
6. [Endpoints](#endpoints)
7. [Error Handling](#error-handling)
8. [Testing](#testing)
9. [Containerization](#containerization)
10. [CI/CD Integration](#cicd-integration)

## Introduction

This Flask application serves as a simple HTTP service with two endpoints, featuring version tracking and global rate limiting. It's designed to be deployed in a Kubernetes environment via a CI/CD pipeline using Jenkins, GitLab, and Nexus.

The application exposes a customizable greeting endpoint and a health check endpoint. It implements rate limiting as a defense against DoS attacks by limiting the total number of requests to the application, regardless of source IP.

## Application Structure

The application follows a modular structure with clear separation of concerns:

```
flask-app/
├── Dockerfile                   # Container definition
├── Jenkinsfile                  # CI/CD pipeline definition
├── README.md                    # Project documentation
├── RequestRateLimits.md         # Rate limiting documentation
├── curl_test.sh                 # Testing script for rate limits
├── version.info                 # Contains application version
└── srcs/
    ├── __init__.py
    ├── main/
    │   ├── __init__.py
    │   ├── app.py               # Application factory
    │   ├── config.py            # Configuration management
    │   ├── errors.py            # Error handlers
    │   ├── limiter.py           # Rate limiting logic
    │   ├── routes.py            # HTTP endpoints
    │   └── version.py           # Version management
    ├── requirements.txt         # Dependencies
    └── tests/
        ├── __init__.py
        ├── test_app.py          # General application tests
        └── test_rate_limit.py   # Rate limiting tests
```

### Component Responsibilities

1. **app.py**: Contains the application factory function that initializes Flask, rate limiter, error handlers, and routes.
2. **config.py**: Configuration management for different environments (development, testing, production).
3. **errors.py**: Custom error handlers, particularly for rate limit errors.
4. **limiter.py**: Global rate limiting implementation.
5. **routes.py**: HTTP endpoint definitions.
6. **version.py**: Manages application version reading and access.

## Configuration

The application uses a flexible configuration system with environment-specific settings:

### Configuration Classes

1. **Config (Base)**: Contains default settings for all environments:
   - Rate limit settings (requests per minute, messages, etc.)
   - Flask settings (debug, testing)
   - Version file path

2. **Environment-specific configs**:
   - **DevelopmentConfig**: Enables debugging
   - **TestingConfig**: Enables testing mode
   - **ProductionConfig**: Production-specific settings

### Environment Variables

The application uses the following environment variables:

| Variable | Purpose | Default |
|----------|---------|---------|
| `FLASK_ENV` | Determines the configuration profile to use | `default` (DevelopmentConfig) |
| `AGENT_NAME` | Name displayed in the greeting message | `Unknown` |
| `VERSION_FILE_PATH` | Path to the version.info file | `version.info` |

### Configuration Selection

```python
def get_config():
    """Get configuration based on environment variable."""
    env = os.getenv('FLASK_ENV', 'default')
    return config_by_name[env]
```

## Rate Limiting

The application implements a global rate limiting strategy to protect against DoS attacks.

### Key Features

1. **Global Scope**: Unlike traditional per-IP rate limiting, this implementation uses a global counter shared across all incoming requests, regardless of source IP.

2. **Default Limit**: 100 requests per minute for the entire application.

3. **Configuration**: Limits can be modified in `config.py`:
   ```python
   RATE_LIMIT_REQUESTS_PER_MINUTE = 100
   RATE_LIMIT_DEFAULT_RETRY = 60  # Window in seconds
   ```

### Implementation

The rate limiter uses Flask-Limiter with a custom key function:

```python
def global_key_func():
    """Return a static key for all requests to create a truly global rate limit."""
    return "global"
```

This ensures all requests increment the same counter, regardless of client IP.

### Rate Limit Handler

When the rate limit is exceeded:

1. A timestamp is recorded when the limit is first hit
2. All subsequent requests receive a `429 Too Many Requests` response
3. A precise retry window is calculated and communicated to clients
4. After the window expires (60 seconds), the rate limit resets

### Response Headers

Rate limit information is included in response headers:

- `X-RateLimit-Limit`: Maximum requests allowed per window
- `X-RateLimit-Remaining`: Remaining requests in current window
- `X-RateLimit-Reset`: Unix timestamp when the rate limit resets
- `Retry-After`: Seconds until the client can retry

## Version Management

The application includes dynamic version information in its responses.

### Version Source

1. The version is read from a file (default: `version.info`) at application startup
2. The path to this file can be customized via the `VERSION_FILE_PATH` environment variable

### Version Module

The `version.py` module encapsulates version management:

1. **VersionManager class**: Reads from the version file and makes it available
2. **Global `_version` variable**: Stores the version information in memory
3. **`get_version()` function**: Public API to access the version from other modules

### Usage in Responses

The version is included in the greeting endpoint response:
```
"Hello, my name is {agent_name} version {version} the time is {time_now}"
```

## Endpoints

The application exposes two HTTP endpoints:

### 1. Root Endpoint (`/`)

- **Method**: GET
- **Purpose**: Returns a greeting message with agent name, version, and current time
- **Response Format**:
  ```json
  {
    "message": "Hello, my name is AgentName version 1.0.0 the time is 12:34"
  }
  ```
- **Customizable via**:
  - `AGENT_NAME` environment variable
  - Version from `version.info` file

### 2. Health Check Endpoint (`/health`)

- **Method**: GET
- **Purpose**: Simple health check for monitoring and liveness probes
- **Response Format**:
  ```json
  {
    "status": "healthy"
  }
  ```
- **Status Code**: Always returns 200 OK when the application is running

## Error Handling

The application includes custom error handling, particularly for rate limiting.

### Rate Limit Error (429)

When the rate limit is exceeded, the application returns:

- **Status Code**: 429 Too Many Requests
- **Headers**:
  - `Retry-After`: Seconds until rate limit expires
  - Standard rate limit headers (X-RateLimit-*)
- **Response Body**:
  ```json
  {
    "error": "Rate limit exceeded",
    "message": "The API has exceeded the allowed 100 requests per 60 seconds. Please try again in 42 seconds.",
    "retry_after": 42,
    "code": 429
  }
  ```

### Error Handler Registration

Error handlers are registered in the `register_error_handlers` function:
```python
def register_error_handlers(app):
    app.errorhandler(RATE_LIMIT_CODE)(ratelimit_handler)
    # Additional handlers can be added here
```

## Testing

The application includes comprehensive test suites to verify functionality.

### Test Files

1. **test_app.py**: Tests basic application functionality, including:
   - Health check endpoint
   - Main greeting endpoint
   - Version inclusion
   
2. **test_rate_limit.py**: Tests rate limiting functionality:
   - Global rate limit enforcement
   - Rate limit window timing
   - Rate limit reset behavior

### Test Commands

Tests are run using pytest and are integrated into the CI/CD pipeline:
```
pytest srcs/tests --maxfail=1 --disable-warnings -q
```

### Other tests

Other test can be performed using tools like *Gatling Open Source* or customized bash script that simulate DoS attacks

### Building and Running

In the CI/CD pipeline, PyInstaller packages the application as a standalone binary, which is then uploaded to Nexus and deployed to Kubernetes using a Helm chart.

## CI/CD Integration

The application integrates with a CI/CD pipeline defined in the `Jenkinsfile`.

### Pipeline Stages

1. **Build Docker Agent**: Setup a custom docker agent from a Dockerfile (inside agent folder)
2. **Install Dependencies**: Sets up the Python environment
3. **Run Tests**: Executes the test suite
4. **Build Executable**: Uses PyInstaller to create a standalone binary
5. **Archive Executable**: Stores the binary as a Jenkins artifact
6. **Upload to Nexus**: Uploads the binary to a Nexus repository for deployment

### Dockerfile

```dockerfile
FROM python:3.9-slim

RUN apt-get update && \
    apt-get install -y sudo binutils && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir -r srcs/requirements.txt && \
    pip install pytest pyinstaller requests

WORKDIR /usr/src/app
```

### Kubernetes Deployment

The application is deployed to Kubernetes using a Helm chart that:
- Downloads the binary from Nexus
- Configures the agent name via environment variables
- Sets up liveness probes using the health check endpoint
- Configures the specified number of replicas

### Notifications

The pipeline includes Telegram notifications at key stages to provide visibility into the build process.