#!/bin/bash

# Configuration
BASE_URL="http://localhost:5000"  # Change to your app's URL
ENDPOINT="/"                      # Main endpoint to test
HEALTH_ENDPOINT="/health"         # Health check endpoint
REQUESTS=110                      # Send 110 requests (exceeding the 100 limit)
DELAY=0.01                        # Minimal delay between requests
COLORS=true                       # Use colors in output

# Colors for output (if enabled)
if [ "$COLORS" = true ]; then
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color
else
    GREEN=''
    YELLOW=''
    RED=''
    BLUE=''
    CYAN=''
    NC=''
fi

# Create a temporary directory for logs
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/rate_limit_test.log"
echo -e "${BLUE}Test logs will be saved to:${NC} $LOG_FILE"

# Function to log messages both to console and log file
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Function to make a request and return the status code
make_request() {
    local url="$1"
    local req_num="$2"
    
    # Make the request and capture the complete response with headers
    local response=$(curl -s -i "$url")
    
    # Extract status code
    local status=$(echo "$response" | grep -m1 "HTTP/" | awk '{print $2}')
    
    # Extract rate limit headers
    local limit=$(echo "$response" | grep -i "X-RateLimit-Limit:" | tr -d '\r' | awk '{print $2}')
    local remaining=$(echo "$response" | grep -i "X-RateLimit-Remaining:" | tr -d '\r' | awk '{print $2}')
    local retry_after=$(echo "$response" | grep -i "Retry-After:" | tr -d '\r' | awk '{print $2}')
    
    # Set default values if headers not found
    limit=${limit:-"N/A"}
    remaining=${remaining:-"N/A"}
    retry_after=${retry_after:-"N/A"}
    
    # Format output based on status code
    if [ "$status" = "429" ]; then
        log "${RED}Request $req_num: Rate limited (429)${NC} - Limit: $limit, Remaining: $remaining, Retry-After: $retry_after"
    else
        log "${GREEN}Request $req_num: Success ($status)${NC} - Limit: $limit, Remaining: $remaining"
    fi
    
    # Return the status code
    echo "$status"
}

# Function to test if rate limiting applies globally
test_global_rate_limit() {
    log "\n${BLUE}=== Testing Global Rate Limit ===${NC}"
    log "${CYAN}This test verifies that the rate limit applies globally across different endpoints${NC}\n"
    
    # Make requests alternating between endpoints
    for i in $(seq 1 20); do
        if [ $((i % 2)) -eq 0 ]; then
            endpoint="$ENDPOINT"
        else
            endpoint="$HEALTH_ENDPOINT"
        fi
        
        status=$(make_request "${BASE_URL}${endpoint}" "$i [${endpoint}]")
        sleep $DELAY
    done
    
    log "\n${BLUE}If both endpoints started returning 429 after 100 total requests, the rate limit is global.${NC}"
}

# Function to test multi-client scenario (simulating DDoS)
test_multi_client() {
    log "\n${BLUE}=== Testing Multi-Client Scenario (Simulated DDoS) ===${NC}"
    log "${CYAN}This test verifies that rate limiting works even with different User-Agent headers${NC}\n"
    
    # Array of different user agents to simulate different clients
    user_agents=(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15"
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
        "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15"
        "Mozilla/5.0 (iPad; CPU OS 14_0 like Mac OS X) AppleWebKit/605.1.15"
    )
    
    for i in $(seq 1 30); do
        # Select a random user agent
        ua_index=$((RANDOM % ${#user_agents[@]}))
        ua="${user_agents[$ua_index]}"
        
        # Make request with custom User-Agent
        response=$(curl -s -i -H "User-Agent: $ua" "${BASE_URL}${ENDPOINT}")
        
        # Extract status code
        status=$(echo "$response" | grep -m1 "HTTP/" | awk '{print $2}')
        
        # Extract rate limit headers
        remaining=$(echo "$response" | grep -i "X-RateLimit-Remaining:" | tr -d '\r' | awk '{print $2}')
        remaining=${remaining:-"N/A"}
        
        log "Request $i [UA:$ua_index]: Status: $status, Remaining: $remaining"
        sleep $DELAY
    done
    
    log "\n${BLUE}If requests were rate limited regardless of User-Agent, the global rate limit is working.${NC}"
}

# Main test function for overall rate limit
test_rate_limit() {
    log "\n${BLUE}=== Testing Rate Limit Threshold (100 req/min) ===${NC}"
    log "${CYAN}This test sends $REQUESTS requests to verify the 100 req/min limit${NC}\n"
    
    # Variables to track when we hit rate limit
    local first_429_req=0
    local success_count=0
    local rate_limited_count=0
    local status_codes=()
    
    # Make the requests and save the status codes
    for i in $(seq 1 $REQUESTS); do
        local status=$(make_request "${BASE_URL}${ENDPOINT}" "$i")
        status_codes+=("$status")
        sleep $DELAY
    done
    
    # Process the collected status codes to get counts
    for i in "${!status_codes[@]}"; do
        if [ "${status_codes[$i]}" = "429" ]; then
            if [ $first_429_req -eq 0 ]; then
                first_429_req=$((i + 1))
            fi
            rate_limited_count=$((rate_limited_count + 1))
        else
            success_count=$((success_count + 1))
        fi
    done
    
    # Report results
    log "\n${BLUE}Rate Limit Test Results:${NC}"
    log "  Successful requests: ${GREEN}$success_count${NC}"
    log "  Rate limited requests: ${RED}$rate_limited_count${NC}"
    
    if [ $first_429_req -gt 0 ]; then
        log "  First rate limited request: #${YELLOW}$first_429_req${NC}"
    else
        log "  ${RED}Did not hit rate limit after $REQUESTS requests!${NC}"
    fi
    
    # Validate if rate limit threshold is correct
    if [ $success_count -ge 95 ] && [ $success_count -le 105 ] && [ $first_429_req -ge 95 ] && [ $first_429_req -le 105 ]; then
        log "  ${GREEN}✓ Rate limit threshold appears to be correctly set at ~100 requests${NC}"
    else
        log "  ${RED}✗ Rate limit threshold may not be correctly set at 100 requests${NC}"
        log "    Expected ~100 successful requests before rate limiting"
    fi
}

# Test rate limit reset
test_rate_limit_reset() {
    log "\n${BLUE}=== Testing Rate Limit Reset ===${NC}"
    log "${CYAN}This test verifies that the rate limit resets after the time window${NC}\n"
    
    # First, ensure we hit the rate limit
    log "Step 1: Hitting the rate limit with 120 quick requests..."
    for i in $(seq 1 120); do
        curl -s -o /dev/null "${BASE_URL}${ENDPOINT}"
        sleep 0.01
    done
    
    # Check if we're rate limited
    response=$(curl -s -i "${BASE_URL}${ENDPOINT}")
    status=$(echo "$response" | grep -m1 "HTTP/" | awk '{print $2}')
    retry_after=$(echo "$response" | grep -i "Retry-After:" | tr -d '\r' | awk '{print $2}')
    
    if [ "$status" != "429" ]; then
        log "${RED}Failed to trigger rate limit during reset test!${NC}"
        return
    fi
    
    log "Rate limit triggered. Retry-After: $retry_after seconds"
    
    # Wait for rate limit to reset (up to 65 seconds to be safe)
    reset_wait=65
    log "Step 2: Waiting ${YELLOW}$reset_wait seconds${NC} for rate limit to reset..."
    sleep $reset_wait
    
    # Check if rate limit has reset
    response=$(curl -s -i "${BASE_URL}${ENDPOINT}")
    status=$(echo "$response" | grep -m1 "HTTP/" | awk '{print $2}')
    remaining=$(echo "$response" | grep -i "X-RateLimit-Remaining:" | tr -d '\r' | awk '{print $2}')
    remaining=${remaining:-"N/A"}
    
    log "After waiting: Status: $status, Remaining: $remaining"
    
    if [ "$status" != "429" ]; then
        log "${GREEN}✓ Rate limit has reset successfully after waiting${NC}"
    else
        log "${RED}✗ Rate limit did not reset after waiting $reset_wait seconds${NC}"
    fi
}

# Run the tests
log "${BLUE}=====================================================${NC}"
log "${YELLOW}Rate Limit DoS Protection Test - $(date)${NC}"
log "${BLUE}=====================================================${NC}"
log "Testing URL: ${CYAN}${BASE_URL}${NC}"
log "Request limit: ${CYAN}100 per minute${NC}"
log "Test sending: ${CYAN}$REQUESTS requests${NC}"

# Run the individual tests
test_rate_limit
test_global_rate_limit
test_multi_client
test_rate_limit_reset

log "\n${BLUE}=====================================================${NC}"
log "${YELLOW}Test Complete!${NC}"
log "Detailed logs saved to: ${CYAN}$LOG_FILE${NC}"
log "${BLUE}=====================================================${NC}"

# Make sure the app is running before exiting
final_check=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}${HEALTH_ENDPOINT}")
if [ "$final_check" = "200" ]; then
    log "${GREEN}✓ Application is still responding to health checks${NC}"
else
    log "${RED}✗ Application is not responding to health checks (status: $final_check)${NC}"
fi