# Code Standards and Best Practices

This document outlines the coding standards and best practices for the CI/CD Project. It serves as a reference guide for all contributors to ensure consistency, maintainability, and quality across the codebase.

## Table of Contents

1. [Python Docstring Standards](#python-docstring-standards)
2. [Python Code Style](#python-code-style)
3. [Code Security Best Practices](#code-security-best-practices)
4. [Testing with Pytest](#testing-with-pytest)
5. [Markdown Guidelines](#markdown-guidelines)
6. [Documentation Best Practices](#documentation-best-practices)

## Python Docstring Standards

We follow the Google style docstrings for all Python code.

### Module Docstrings

Each module should begin with a docstring that describes its purpose and contents:

```python
"""Module for handling the metrics collection and exposure in the Flask application.

This module provides functionality to track and expose application metrics using
the Prometheus client library. It includes counter, gauge, and histogram metrics
for request tracking and performance monitoring.
"""
```

### Class Docstrings

Class docstrings should describe the purpose of the class:

```python
class MetricsCollector:
    """Collector for application metrics using Prometheus client.
    
    This class provides methods for registering, incrementing, and exposing
    application metrics. It handles counter initialization, gauge updates,
    and histogram recording.
    
    Attributes:
        counters (dict): Dictionary of Prometheus counters
        gauges (dict): Dictionary of Prometheus gauges
        histograms (dict): Dictionary of Prometheus histograms
    """
```

### Function and Method Docstrings

Functions and methods should document parameters, return values, raised exceptions, and provide a clear description:

```python
def increment_request_count(endpoint_name, status_code):
    """Increment the request counter for the specified endpoint and status.
    
    Args:
        endpoint_name (str): The name of the endpoint that received the request
        status_code (int): The HTTP status code returned by the request
        
    Returns:
        int: The new count value after incrementing
        
    Raises:
        ValueError: If status_code is not a valid HTTP status code
    """
```

### Property Docstrings

For properties, document the property itself, not the getter method:

```python
@property
def uptime_seconds(self):
    """int: The number of seconds the application has been running."""
```

### Additional Guidelines

1. Use imperative mood for descriptions (e.g., "Return" not "Returns")
2. Keep the first line concise and focused
3. Separate the extended description with a blank line
4. Use consistent indentation within docstring blocks
5. Document all public methods, classes, and modules

## Python Code Style

We follow [PEP 8](https://peps.python.org/pep-0008/) for coding style with additional conventions enforced by Ruff.

### Ruff Configuration

Our project uses Ruff for linting with the following configuration:

```toml
# pyproject.toml
[tool.ruff]
select = ["E", "F", "B", "I", "N", "UP", "ANN", "S", "A", "C4", "RET", "SIM", "ARG", "ERA", "PL", "RUF"]
ignore = ["ANN101", "ANN102", "PLR0913"]
line-length = 100
target-version = "py39"
```

### Key Style Guidelines

1. **Imports Organization**:
   - Standard library imports first
   - Third-party imports second
   - Local application imports third
   - Use absolute imports when possible
   - Use `import` statements for packages and modules only

   ```python
   # Correct
   import os
   import sys
   
   from flask import Flask, jsonify
   import prometheus_client
   
   from .metrics import MetricsCollector
   from .config import get_config
   ```

2. **Naming Conventions**:
   - Classes: `CamelCase`
   - Functions, methods, variables: `snake_case`
   - Constants: `UPPER_SNAKE_CASE`
   - Private attributes/methods: prefixed with underscore `_private_method`

3. **Line Length and Formatting**:
   - Maximum line length: 100 characters
   - Use parentheses for line continuation
   - Break long strings with parentheses and quotes
   - Use trailing commas in multi-line structures

   ```python
   # Long string formatting
   message = (
       f"The API has exceeded the allowed {RATE_LIMIT_REQUESTS_PER_MINUTE} "
       f"requests per 60 seconds. Please try again in {time_msg}."
   )
   
   # Long function call
   result = some_function_with_many_arguments(
       argument1,
       argument2,
       named_argument1="value1",
       named_argument2="value2",
   )
   ```

4. **Code Structure**:
   - Use 4 spaces for indentation (no tabs)
   - Separate top-level functions and classes with two blank lines
   - Separate methods within a class with one blank line
   - Use blank lines to indicate logical sections

5. **Type Annotations**:
   - Use type hints for function parameters and return values
   - Import annotations from `__future__` for Python 3.7-3.9 compatibility

   ```python
   from __future__ import annotations
   from typing import Dict, List, Optional, Union
   
   def process_data(input_data: Dict[str, Any]) -> List[str]:
       """Process the input data and return a list of strings."""
   ```

6. **String Formatting**:
   - Use f-strings for string interpolation
   - For logging, use %-formatting to avoid unnecessary computation

   ```python
   # For general use
   message = f"Hello, {name}!"
   
   # For logging
   logger.debug("Processing data for user: %s with id: %d", username, user_id)
   ```

7. **Error Handling**:
   - Use specific exception types
   - Catch only the exceptions you can handle
   - Use context managers for resource management

   ```python
   try:
       value = dictionary[key]
   except KeyError:
       logger.warning("Key %s not found in dictionary", key)
       value = default_value
   ```

## Code Security Best Practices

Security is a critical aspect of our development process. Follow these guidelines to ensure secure code.

### Input Validation

1. **Validate all inputs**:
   - Validate data type, range, format, and length
   - Use schema validation libraries when appropriate
   - Apply whitelisting rather than blacklisting

   ```python
   def process_user_input(user_id):
       """Process user input with proper validation."""
       if not isinstance(user_id, int) or user_id <= 0:
           raise ValueError("User ID must be a positive integer")
       # Continue processing
   ```

2. **SQL Injection Prevention**:
   - Use parameterized queries or ORMs
   - Never concatenate strings to build SQL queries

   ```python
   # Using SQLAlchemy ORM (safe)
   user = db.session.query(User).filter(User.id == user_id).first()
   
   # Using parameterized query (safe)
   cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
   ```

### Secrets Management

1. **Never hardcode secrets**:
   - Use environment variables or secure vaults
   - Don't include credentials in logs or error messages

   ```python
   # Good practice
   api_key = os.environ.get("API_KEY")
   if not api_key:
       logger.error("API key not configured")
       raise ConfigurationError("API key missing")
   ```

2. **Secure defaults**:
   - Applications should be secure by default
   - Make security features opt-out rather than opt-in

### Dependency Management

1. **Keep dependencies updated**:
   - Regularly update dependencies to patch security vulnerabilities
   - Use tools like `safety` to check for known vulnerabilities

2. **Minimize dependencies**:
   - Only include what's necessary
   - Prefer well-maintained, widely-used packages

### Output Encoding

1. **Always encode output**:
   - HTML encode data displayed in web interfaces
   - Use appropriate encoding for different contexts (SQL, JSON, etc.)

### Rate Limiting and DoS Protection

1. **Implement rate limiting**:
   - Limit requests per user/IP
   - Use exponential backoff for retries

   ```python
   @app.route("/api/resource")
   @limiter.limit("100 per minute")
   def api_resource():
       # Resource implementation
   ```

### Additional Security Guidelines

1. **Use HTTPS everywhere**
2. **Implement proper authentication and authorization**
3. **Apply the principle of least privilege**
4. **Validate redirects and forwards**
5. **Set secure HTTP headers**
6. **Log security events**
7. **Conduct regular security reviews**

## Testing with Pytest

We use pytest as our testing framework. Follow these practices for effective testing.

### Test Structure

1. **Organization**:
   - Place tests in a separate `tests` directory
   - Mirror the structure of your application
   - Use `test_` prefix for test modules and functions

   ```
   app/
   ├── __init__.py
   ├── metrics.py
   └── routes.py
   tests/
   ├── __init__.py
   ├── test_metrics.py
   └── test_routes.py
   ```

2. **Test naming**:
   - Name test functions descriptively
   - Include the function name and scenario being tested

   ```python
   def test_increment_counter_with_valid_input():
       """Test that counter increments correctly with valid input."""
   ```

### Fixtures

1. **Use fixtures for setup and teardown**:
   - Define fixtures at the appropriate scope (function, module, session)
   - Use parameterization for testing multiple cases

   ```python
   @pytest.fixture
   def app():
       """Create and configure a Flask app for testing."""
       app = create_app(TestConfig)
       yield app
   
   @pytest.fixture
   def client(app):
       """Create a test client for the app."""
       return app.test_client()
   
   @pytest.mark.parametrize(
       "endpoint,expected_status",
       [
           ("/", 200),
           ("/health", 200),
           ("/metrics", 200),
           ("/nonexistent", 404),
       ],
   )
   def test_endpoints_status(client, endpoint, expected_status):
       """Test that endpoints return expected status codes."""
       response = client.get(endpoint)
       assert response.status_code == expected_status
   ```

### Assertions

1. **Use specific assertions**:
   - Use pytest's built-in assertions
   - Include meaningful error messages

   ```python
   def test_counter_value():
       counter = Counter("test_counter")
       counter.inc(5)
       assert counter._value.get() == 5, "Counter should be incremented by 5"
   ```

### Mocking

1. **Use mocks for external dependencies**:
   - Use `pytest-mock` or `unittest.mock`
   - Only mock what's necessary
   - Verify mock interactions

   ```python
   def test_external_api_call(mocker):
       # Mock the external API
       mock_response = mocker.Mock()
       mock_response.status_code = 200
       mock_response.json.return_value = {"data": "test"}
       
       mocker.patch("requests.get", return_value=mock_response)
       
       # Test the function that uses the external API
       result = fetch_data_from_api()
       
       # Verify the result and the API call
       assert result == {"data": "test"}
       requests.get.assert_called_once_with("https://api.example.com/data")
   ```

### Test Coverage

1. **Aim for high test coverage**:
   - Use coverage tools (`pytest-cov`)
   - Focus on testing complex logic and edge cases
   - Don't pursue 100% coverage at the expense of test quality

   ```bash
   pytest --cov=app tests/
   ```

### Best Practices

1. **Keep tests independent**:
   - Tests should not depend on each other
   - Each test should setup its own state

2. **Make tests deterministic**:
   - Avoid random data without setting a seed
   - Mock time-dependent functions

3. **Test both success and failure cases**:
   - Test that functions behave correctly with valid input
   - Test that functions handle errors appropriately with invalid input

4. **Test performance critical code**:
   - Use benchmarks for performance-sensitive functions
   - Set performance budgets and enforce them in CI

## Markdown Guidelines

### Structure

1. **Use proper heading hierarchy**:
   - Start with a single level-1 heading (`#`)
   - Do not skip heading levels (e.g., don't go from `##` to `####`)
   - Use headers to create a clear document structure

2. **Include a table of contents**:
   - For longer documents, include a table of contents
   - Use reference-style links for the TOC

### Formatting

1. **Lists**:
   - Use `*` for unordered lists
   - Use `1.` for ordered lists
   - Maintain consistent indentation for nested lists (2 spaces)

2. **Code blocks**:
   - Use triple backticks for code blocks
   - Include the language for syntax highlighting
   - Use inline code for referring to code elements in text

3. **Links and references**:
   - Use descriptive link text
   - Prefer reference-style links for readability

4. **Emphasis**:
   - Use `*` or `_` for italics
   - Use `**` or `__` for bold
   - Don't overuse emphasis

### Best Practices

1. **Keep lines length reasonable**:
   - Wrap lines at around 80-100 characters
   - Long URLs can be exceptions

2. **Use tables for structured data**:
   - Align table elements for readability
   - Include header and divider rows

   ```markdown
   | Name        | Type    | Description                      |
   |-------------|---------|----------------------------------|
   | id          | integer | Unique identifier                |
   | name        | string  | User's display name              |
   | created_at  | datetime| Account creation timestamp       |
   ```

3. **Images**:
   - Include alt text for all images
   - Keep image file paths relative to the document

   ```markdown
   ![Application Architecture Diagram](./docs/images/architecture.png)
   ```

4. **Document flow**:
   - Start with an introduction
   - Organize content in a logical flow
   - End with a conclusion or next steps

## Documentation Best Practices

### General Principles

1. **Keep documentation close to code**:
   - Include README.md files in each directory
   - Document architectural decisions in the repository
   - Reference code from documentation and vice versa

2. **Documentation types**:
   - **Reference**: API documentation, configuration options
   - **Tutorials**: Step-by-step instructions for specific tasks
   - **Explanation**: Background information and context
   - **How-to guides**: Task-oriented documentation

3. **Update documentation with code**:
   - Treat documentation as part of the codebase
   - Review documentation changes in pull requests
   - Include documentation in your definition of "done"

### README Files

1. **Project README**:
   - Include project name and description
   - Provide installation instructions
   - Add usage examples
   - List dependencies
   - Include contribution guidelines
   - Specify license information

2. **Component README**:
   - Explain the purpose of the component
   - Document interfaces and dependencies
   - Include usage examples
   - Add performance considerations
   - Note any security implications

### API Documentation

1. **Describe all endpoints**:
   - Include HTTP method, URL, parameters, and response format
   - Document authentication requirements
   - Provide example requests and responses
   - Note rate limiting or other restrictions

2. **Document error responses**:
   - List possible error codes and their meanings
   - Include example error responses
   - Provide guidance on handling errors

### Architecture Documentation

1. **Include diagrams**:
   - Use architecture diagrams for visual understanding
   - Keep diagrams updated with system changes
   - Include legends and explanations

2. **Document decisions**:
   - Record architectural decisions and their rationale
   - Use Architecture Decision Records (ADRs) format
   - Link decisions to requirements or constraints

### Maintenance

1. **Regular reviews**:
   - Schedule periodic documentation reviews
   - Update outdated information
   - Remove deprecated sections

2. **Document versioning**:
   - Clearly indicate documentation version or date
   - Use tags or releases to associate documentation with code versions
   - Note changes between versions

### Style Guide

1. **Use consistent terminology**:
   - Create a glossary of terms
   - Be consistent with technical terms
   - Avoid jargon unless necessary

2. **Be clear and concise**:
   - Write in simple, direct language
   - Use active voice
   - Break long explanations into smaller sections

3. **Use examples**:
   - Include code examples for key concepts
   - Provide practical, real-world examples
   - Show both basic and advanced usage

---

This document serves as a guideline for maintaining high code quality and consistency throughout the project. Following these standards will help ensure that our codebase remains maintainable, secure, and well-documented.