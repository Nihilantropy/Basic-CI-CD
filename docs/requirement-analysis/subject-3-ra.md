# Subject 3 Requirements Analysis

## Detailed Requirements Breakdown

### 1. Centralized Logging with Prometheus and Grafana
- **Prometheus** will serve as the time-series database for metrics collection
- **Grafana** will provide visualization through customizable dashboards
- The system must track metrics from both the Flask application and Jenkins
- Integration must maintain the existing CI/CD pipeline functionality

### 2. Flask Application Metrics Endpoint
- Create a new `/metrics` endpoint in the Flask application
- Implement basic metrics:
  - Request counts (total and by endpoint)
  - Response time metrics
  - Error rates and status codes
  - Rate limiting statistics
  - Application uptime
  - Version information

### 3. Integrated Dashboards
- **Flask Application Dashboard** must display:
  - Real-time request volume
  - Endpoint usage statistics
  - Error rates
  - Response time distributions
  - Version tracking
  
- **Jenkins Dashboard** must display:
  - Component status (online/offline)
  - Pipeline execution metrics
  - Build success/failure rates
  - Stage duration statistics
  - Recent build outcomes

## Integration Points

### Flask Application Integration
- Add Prometheus client library to `requirements.txt`
- Extend application factory pattern to initialize metrics
- Create `/metrics` endpoint in the existing blueprint structure
- Ensure metrics respect the application's rate limiting configuration

### Jenkins Integration
- Install Prometheus plugin in Jenkins
- Configure metrics exposure in Jenkins configuration
- Ensure metrics are properly secured
- Extend current Jenkinsfile to capture build metrics

### Docker Compose Integration
- Add Prometheus and Grafana containers
- Configure persistent storage volumes
- Set up proper network connectivity
- Maintain compatibility with existing services

### Kubernetes Integration
- Ensure Prometheus can scrape metrics from the deployed Flask application
- Configure service discovery for dynamic deployments

## Metrics Definition

### Flask Application Metrics
- **Request Metrics**:
  - `http_requests_total` (Counter: total requests by endpoint, method, status)
  - `http_request_duration_seconds` (Histogram: response time by endpoint)
  - `http_request_in_flight` (Gauge: concurrent requests)
  
- **Rate Limit Metrics**:
  - `rate_limit_hits_total` (Counter: rate limit occurrences)
  - `rate_limit_remaining` (Gauge: remaining requests in window)
  
- **Application Metrics**:
  - `app_version_info` (Gauge: version information)
  - `app_uptime_seconds` (Gauge: application uptime)
  - `app_start_time_seconds` (Gauge: start timestamp)

### Jenkins Metrics
- **System Metrics**:
  - Jenkins executor utilization
  - Queue length and wait time
  
- **Build Metrics**:
  - Build frequency by job
  - Build duration by job and stage
  - Success/failure rate by job
  - Pipeline stage performance

## Next Steps

1. Create an architecture diagram showing data flow between components
2. Research and document Prometheus and Grafana deployment best practices
3. Define metrics collection strategy and retention policies