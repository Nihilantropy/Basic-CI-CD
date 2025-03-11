# Rate Limiting Documentation

## Overview

Our API implements rate limiting to ensure fair usage and system stability. This document explains how our rate limiting works, what to expect when limits are reached, and how to handle rate-limited responses in your applications.

## Rate Limit Policy

| Limit | Window | Scope |
|-------|--------|-------|
| 100 requests | 60 seconds (1 minute) | Global - shared across all endpoints |

Rate limits are applied globally across all endpoints in the API. This means that the combined requests to any endpoints count toward the same rate limit.

## Rate Limit Headers

Every API response includes the following rate limit headers:

| Header | Description | Example |
|--------|-------------|---------|
| `X-RateLimit-Limit` | Maximum number of requests allowed in the current window | `100` |
| `X-RateLimit-Remaining` | Number of requests remaining in the current window | `42` |
| `X-RateLimit-Reset` | Unix timestamp (in seconds) when the rate limit window resets | `1709301234` |
| `Retry-After` | HTTP-formatted date or seconds until clients can retry | `Tue, 11 Mar 2025 13:30:45 GMT` |

## Handling Rate Limited Requests

When you exceed the rate limit, the API will:

1. Return a `429 Too Many Requests` HTTP status code
2. Include all the rate limit headers mentioned above
3. The `Retry-After` header will indicate when you can resume making requests

### Example Rate Limited Response

```http
HTTP/1.1 429 Too Many Requests
Content-Type: application/json
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1709301234
Retry-After: Tue, 11 Mar 2025 13:30:45 GMT

{
  "error": "Rate limit exceeded",
  "message": "You have exceeded the rate limit of 100 requests per minute",
  "retry_after": "47 seconds"
}
```

## Best Practices for Handling Rate Limits

### 1. Monitor Rate Limit Headers

Always check the `X-RateLimit-Remaining` header to know how many requests you have left in the current window.

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
    retry_after = response.headers.get('Retry-After')
    # If Retry-After is a timestamp
    if retry_after and retry_after.startswith(('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')):
        # Parse HTTP date and calculate seconds to wait
        retry_date = parsedate_to_datetime(retry_after)
        wait_time = (retry_date - datetime.now()).total_seconds()
    else:
        # If Retry-After is seconds
        wait_time = int(retry_after)
    
    print(f"Rate limited. Waiting {wait_time} seconds before retrying.")
    time.sleep(wait_time)
    # Retry the request after waiting
```

### 3. Distribute Requests

Distribute your requests evenly over time rather than sending them in bursts.

### 4. Optimize API Usage

Minimize unnecessary API calls by:
- Caching responses when appropriate
- Batching operations when possible
- Using bulk endpoints where available

## Frequently Asked Questions

**Q: Does the rate limit apply to all endpoints?**  
A: Yes, our rate limit is global and applies across all endpoints.

**Q: What happens if I exceed the rate limit?**  
A: You'll receive a 429 status code and will need to wait until the rate limit resets before making additional requests.

**Q: How do I know when I can retry after being rate limited?**  
A: Check the `Retry-After` header or the `X-RateLimit-Reset` header in the response.

**Q: Do failed requests count toward the rate limit?**  
A: Yes, all requests, regardless of their success or failure, count toward your rate limit.

**Q: Is there a way to increase my rate limit?**  
A: [Include information about any premium tiers or special access options if applicable]