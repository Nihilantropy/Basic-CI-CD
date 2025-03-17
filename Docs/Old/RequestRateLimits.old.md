# Rate Limiting Documentation

## Overview

Our API implements a global rate limiting mechanism to ensure system stability and protect against DoS attacks. This document explains how our rate limiting works, what to expect when limits are reached, and how to handle rate-limited responses in your applications.

## Rate Limit Policy

| Limit | Window | Scope |
|-------|--------|-------|
| 100 requests | 60 seconds (1 minute) | Global - shared across all endpoints and all clients |

Unlike traditional IP-based rate limiting, our implementation uses a global counter that applies to the entire application. This means:

- The limit of 100 requests per minute applies to the combined traffic from all clients
- All endpoints (including `/` and `/health`) share the same counter
- The rate limit does not differentiate between different IP addresses or user agents

This approach is specifically designed to protect against distributed denial-of-service attacks where requests might come from multiple sources.

## Rate Limit Headers

Every API response includes the following rate limit headers:

| Header | Description | Example |
|--------|-------------|---------|
| `X-RateLimit-Limit` | Maximum number of requests allowed in the current window | `100` |
| `X-RateLimit-Remaining` | Number of requests remaining in the current window | `42` |
| `X-RateLimit-Reset` | Unix timestamp (in seconds) when the rate limit window resets | `1709301234` |
| `Retry-After` | Seconds until clients can retry (when rate limited) | `42` |

## Handling Rate Limited Requests

When the global rate limit is exceeded, the API will:

1. Return a `429 Too Many Requests` HTTP status code
2. Include all the rate limit headers mentioned above
3. Provide a JSON response with detailed information about the rate limit and retry time

### Example Rate Limited Response

```http
HTTP/1.1 429 Too Many Requests
Content-Type: application/json
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1709301234
Retry-After: 42

{
  "code": 429,
  "error": "Rate limit exceeded.",
  "message": "The API has exceeded the allowed 100 requests per 60 seconds. Please try again in 42 seconds.",
  "retry_after": 42
}
```

## Rate Limit Window Behavior

Our rate limiting implementation uses a 60-second moving window that begins when the first rate-limited request occurs:

1. When the application receives more than 100 requests within a minute, it starts returning 429 responses
2. The timestamp of the first rate-limited request is recorded
3. All subsequent requests receive a 429 response with an accurate `Retry-After` value based on the time remaining in the 60-second window
4. After the 60-second window expires, the rate limit resets automatically

This means that if the API experiences a burst of traffic at 12:00:00 that triggers rate limiting, normal service will resume at 12:01:00 regardless of whether requests continued during the rate-limited period.

## Best Practices for Handling Rate Limits

### 1. Monitor Rate Limit Headers

Always check the `X-RateLimit-Remaining` header to know how many requests are left in the current window.

```python
response = requests.get('https://api.example.com/resource')
remaining = int(response.headers.get('X-RateLimit-Remaining', 0))
print(f"Remaining requests: {remaining}")
```

### 2. Implement Backoff Strategies

When you receive a 429 response, use the `Retry-After` header to determine when to retry.

```python
response = requests.get('https://api.example.com/resource')
if response.status_code == 429:
    retry_after = int(response.headers.get('Retry-After', 60))
    print(f"Rate limited. Waiting {retry_after} seconds before retrying.")
    time.sleep(retry_after)
    # Retry the request after waiting
```

### 3. Distribute Requests

Since our rate limit is global across all users, consider:
- Adding delays between your requests
- Implementing client-side throttling
- Batching operations where possible to reduce the total number of requests

### 4. Use the Health Endpoint Sparingly

Remember that calls to `/health` count toward the same global rate limit as your main endpoint calls. In high-traffic scenarios, consider reducing the frequency of health checks.

## Frequently Asked Questions

**Q: Does the rate limit apply to all endpoints?**  
A: Yes, our rate limit is global and applies across all endpoints, including the health check endpoint.

**Q: What happens if I exceed the rate limit?**  
A: You'll receive a 429 status code and will need to wait until the rate limit window resets (60 seconds from when rate limiting began).

**Q: How do I know when I can retry after being rate limited?**  
A: Check the `Retry-After` header in the response. This will tell you exactly how many seconds to wait.

**Q: Do failed requests count toward the rate limit?**  
A: Yes, all requests, regardless of their success or failure, count toward the global rate limit.

**Q: Why use a global rate limit instead of per-IP limiting?**  
A: A global rate limit provides better protection against distributed denial-of-service attacks where requests might come from multiple sources. It ensures the application remains stable under any traffic pattern.

**Q: Is there a way to increase the rate limit?**  
A: The rate limit is configured in the application's settings. For production deployments, this can be adjusted based on the specific requirements and the capacity of your infrastructure.