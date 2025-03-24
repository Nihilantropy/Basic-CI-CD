# Flask App Documentation

## Table of Contents

1. [Introduction](#introduction)
2. [Application Architecture](#application-architecture)
3. [Rate Limiting](#rate-limiting)
4. [Version Management](#version-management)
5. [Endpoints](#endpoints)
6. [Configuration](#configuration)
7. [Error Handling](#error-handling)
8. [Testing](#testing)
9. [CI/CD Pipeline](#cicd-pipeline)
   - [Jenkinsfile Structure](#jenkinsfile-structure)
   - [Pipeline Stages](#pipeline-stages)
   - [Code Quality and Security](#code-quality-and-security)
   - [Artifact Management](#artifact-management)
   - [Git Integration](#git-integration)
   - [Notifications](#notifications)
10. [Containerization](#containerization)
11. [Deployment](#deployment)
12. [Project Structure](#project-structure)

## Introduction

This Flask application serves as a simple HTTP service with two endpoints, featuring version tracking and global rate limiting. It's designed to be deployed in a Kubernetes environment via a CI/CD pipeline using Jenkins, GitLab, and Nexus.

The application exposes a customizable greeting endpoint and a health check endpoint. It implements rate limiting as a defense against DoS attacks by limiting the total number of requests to the application, regardless of source IP.

## Application Architecture

The application follows a modular architecture with clear separation of concerns, making it maintainable, testable, and extensible:

- **Application Factory Pattern**: Uses Flask's application factory pattern to create and configure the app instance
- **Blueprint-based Routing**: Organizes routes in a blueprint for better code organization
- **Modular Components**: Separate modules for configuration, rate limiting, error handling, and version management
- **Environment-specific Configuration**: Different configurations for development, testing, and production environments

### Key Components

- **app.py**: Application factory and entry point
- **config.py**: Environment-specific configuration management
- **limiter.py**: Global rate limiting implementation
- **routes.py**: HTTP endpoint definitions
- **errors.py**: Custom error handling, especially for rate limiting
- **version.py**: Version management and access

## Rate Limiting

The application implements a global rate limiting strategy to protect against DoS attacks.

### Key Features

1. **Global Scope**: Unlike traditional per-IP rate limiting, this implementation uses a global counter shared across all incoming requests, regardless of source IP.

2. **Default Limit**: 100 requests per minute for the entire application.

3. **Implementation**: Uses Flask-Limiter with a custom key function to create a truly global limit:

```python
def global_key_func():
    """Return a static key for all requests to create a global rate limit."""
    return "global"
```

### Rate Limit Behavior

- When the global limit is reached, all subsequent requests (regardless of source) receive a `429 Too Many Requests` response
- The rate limit window is 60 seconds from the first rejected request
- All requests count toward the same limit, including health check requests
- Detailed feedback is provided in response headers and the error message

### Rate Limit Response

When the rate limit is exceeded, the application returns:

- **Status Code**: 429 Too Many Requests
- **Headers**:
  - `Retry-After`: Seconds until rate limit expires
  - `X-RateLimit-Limit`: Maximum allowed requests per window
  - `X-RateLimit-Remaining`: Remaining requests in current window
  - `X-RateLimit-Reset`: Unix timestamp when the rate limit resets
- **Response Body**:
  ```json
  {
    "error": "Rate limit exceeded",
    "message": "The API has exceeded the allowed 100 requests per 60 seconds. Please try again in 42 seconds.",
    "retry_after": 42,
    "code": 429
  }
  ```

## Version Management

The application includes dynamic version information in its responses, sourced from a version file.

### Version Source

1. The version is read from a `version.info` file during the build process
2. The CI/CD pipeline updates this file with a timestamp (format: `YYYYMMDDhhmmss`)
3. The version is included in responses from the main endpoint

### Implementation Details

- The `version.py` module provides a clean API for accessing the version information
- During the CI/CD pipeline, the version placeholder is replaced with the actual version
- The version is displayed in the format: `"Hello, my name is {agent_name} version {version} the time is {time_now}"`

## Endpoints

The application exposes two HTTP endpoints:

### 1. Root Endpoint (`/`)

- **Method**: GET
- **Purpose**: Returns a greeting message with agent name, version, and current time
- **Response Format**:
  ```json
  {
    "message": "Hello, my name is AgentName version 20240317123456 the time is 12:34"
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

## Configuration

The application uses a flexible configuration system with environment-specific settings:

### Configuration Classes

1. **Config (Base)**: Contains default settings for all environments:
   - Rate limit settings (100 requests per minute)
   - Flask settings (debug, testing)
   - Error handling configuration

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

## Error Handling

The application includes custom error handling, particularly for rate limiting, implemented in `errors.py`:

- Centralized error handler registration
- Detailed error responses with actionable information
- Custom rate limit handler with precise retry times
- Graceful fallback for unexpected errors

## Testing

The application includes comprehensive test suites to verify functionality:

### Test Files

1. **test_app.py**: Tests basic application functionality, including:
   - Health check endpoint
   - Main greeting endpoint
   - Version inclusion
   
2. **test_rate_limit.py**: Tests rate limiting functionality:
   - Global rate limit enforcement
   - Rate limit window timing
   - Rate limit reset behavior

### Running Tests

Tests are run using pytest and are integrated into the CI/CD pipeline:
```bash
pytest srcs/tests --maxfail=1 --disable-warnings -v
```

### Test Features

- Rate limit tests properly handle the shared state between tests
- Tests include detailed assertions with helpful error messages
- Tests are designed to be non-flaky and reliable in CI/CD environments

## CI/CD Pipeline

The project includes a comprehensive Jenkins pipeline defined in `Jenkinsfile`, which automates testing, building, and deployment of the application.

### Jenkinsfile Structure

The Jenkinsfile uses a custom Docker agent defined in `agent/Dockerfile` and leverages utility functions from `includes/cicdUtils.groovy` for modular pipeline code.

### Pipeline Stages

1. **Checkout & Cleanup**: Checks out the code and handles [ci skip] tags
2. **Load Utilities**: Loads utility functions from the includes directory
3. **Load Configuration**: Reads configuration from `jenkins-config.yml`
4. **Pipeline Start**: Initializes GitLab status and sends notifications
5. **Run Tests**: Executes the test suite using pytest
6. **Code Quality Check - Ruff**: Performs static code analysis
7. **Security Check - Bandit**: Performs security scanning
8. **Update Version Information**: Updates version.py and version.info
9. **Build Executable**: Creates a standalone binary using PyInstaller
10. **Archive Executable**: Stores the binary as a Jenkins artifact
11. **Upload to Nexus**: Uploads the binary to Nexus with both 'latest' and timestamp versions
12. **Push Changes & Create Tag**: Updates the repo, commits version changes, and tags the release
13. **Create Merge Request**: Creates a merge request to the main branch

### Code Quality and Security

The pipeline includes robust code quality and security checks:

1. **Ruff Code Analysis**:
   - Runs with all rules enabled (`--select ALL`)
   - Blocks the pipeline if issues are found

2. **Bandit Security Scanning**:
   - Scans for security vulnerabilities
   - Uses increased verbosity for detailed reporting (`-ll -iii`)
   - Blocks the pipeline if medium or high severity issues are found

### Artifact Management

The pipeline integrates with Nexus Repository Manager:

1. **Binary Creation**: Uses PyInstaller to create a standalone executable
2. **Dual Uploads**:
   - Uploads with 'latest' tag for easy access
   - Uploads with timestamp-based version (`YYYYMMDDhhmmss`) for versioning

### Git Integration

The pipeline includes advanced Git integration:

1. **Version Tagging**: Creates a Git tag with the timestamp version
2. **Automated Commits**: Updates and commits version.info with the new version
3. **Merge Request Creation**: Automatically creates a merge request to the main branch
4. **Skip Logic**: Uses [ci skip] detection to prevent recursive builds

### Notifications

The pipeline sends notifications at key points:

1. **GitLab Status Updates**: Updates commit status in GitLab
2. **Telegram Notifications**: Sends messages about build progress and results

### Pipeline Configuration

The pipeline behavior can be controlled via:

1. **jenkins-config.yml**:
   ```yaml
   runTests: true
   runRuffCheck: true
   runBanditCheck: true
   updateVersion: true
   buildExecutable: true
   archiveExecutable: true
   uploadToNexus: true
   pushGitChanges: true
   createMergeRequest: true
   enableGitlabStatus: true
   enableTelegram: true
   ```

2. **Jenkins Parameters**:
   - Boolean parameters corresponding to each stage
   - Override settings for manual builds

## Containerization

The application is containerized at two levels:

1. **Development/CI Container** (agent/Dockerfile):
   - Based on Python 3.9-slim
   - Includes development tools (pytest, ruff, bandit)
   - Used by the Jenkins pipeline

2. **Production Deployment**:
   - Uses the Helm chart to download the standalone binary
   - Base image is ubuntu:22.04
   - Minimal dependencies for security and performance

## Deployment

The application is deployed to Kubernetes using a Helm chart:

1. **Helm Chart Features**:
   - Configurable replica count
   - Customizable agent name
   - Liveness probes for health monitoring
   - Downloads the correct version from Nexus

2. **Deployment Process**:
   - The CI/CD pipeline builds and uploads the binary
   - Manual Helm deployment fetches the binary from Nexus
   - The application runs as a standalone executable

## Project Structure

```
flask-app/
├── Dockerfile                   # Container definition for production
├── Jenkinsfile                  # CI/CD pipeline definition
├── README.md                    # This documentation file
├── RequestRateLimits.md         # Rate limiting documentation
├── agent/                       # CI/CD agent container
│   └── Dockerfile               # Agent container definition 
├── includes/                    # Pipeline utilities
│   └── cicdUtils.groovy         # Reusable pipeline functions
├── jenkins-config.yml           # Pipeline configuration
├── version.info                 # Current application version
└── srcs/                        # Application source code
    ├── __init__.py              # Package marker
    ├── main/                    # Main application code
    │   ├── __init__.py          # Package marker
    │   ├── app.py               # Application factory
    │   ├── config.py            # Configuration management
    │   ├── errors.py            # Error handlers
    │   ├── limiter.py           # Rate limiting logic
    │   ├── routes.py            # HTTP endpoints
    │   └── version.py           # Version management
    ├── requirements.txt         # Dependencies
    └── tests/                   # Test suites
        ├── __init__.py          # Package marker
        ├── test_app.py          # Application tests
        └── test_rate_limit.py   # Rate limiting tests
```

This modular structure promotes:
- **Separation of concerns**: Each module has a specific responsibility
- **Testability**: Components can be tested in isolation
- **Maintainability**: Easy to understand and modify
- **Extensibility**: New features can be added with minimal changes to existing code