#!/bin/bash

# Configuration
BASE_URL="http://localhost:5000"  # Change to your actual application URL
ENDPOINT="/"                # Change to the endpoint you want to test
REQUESTS=20                      # Number of requests to make (more than your rate limit)
DELAY=0.1                         # Delay between requests in seconds

# Color codes for better readability
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Rate Limit Test - Making $REQUESTS requests to $BASE_URL$ENDPOINT${NC}"
echo -e "${BLUE}==================================================${NC}"

# Counter for rate-limited responses
rate_limited=0

# Track when we first hit the rate limit
first_rate_limit_hit=0

for (( i=1; i<=$REQUESTS; i++ ))
do
    # Make the request and capture headers in a file
    echo -e "${YELLOW}Request $i:${NC}"
    
    # Use curl with various options:
    # -s: silent mode
    # -D -: output headers to stdout
    # -o /dev/null: discard the response body
    # -w: format the output (HTTP status code)
    response=$(curl -s -D - -o /dev/null -w "Status: %{http_code}" $BASE_URL$ENDPOINT)
    
    # Extract status code
    status=$(echo "$response" | grep "Status:" | cut -d' ' -f2)
    
    # Extract rate limit headers
    limit=$(echo "$response" | grep -i "X-RateLimit-Limit:" | tr -d '\r' | cut -d' ' -f2)
    remaining=$(echo "$response" | grep -i "X-RateLimit-Remaining:" | tr -d '\r' | cut -d' ' -f2)
    reset=$(echo "$response" | grep -i "X-RateLimit-Reset:" | tr -d '\r' | cut -d' ' -f2)
    retry_after=$(echo "$response" | grep -i "Retry-After:" | tr -d '\r' | cut -d' ' -f2)
    
    # Display information
    if [ "$status" == "429" ]; then
        # If this is the first time hitting the rate limit, record the time
        if [ $rate_limited -eq 0 ]; then
            first_rate_limit_hit=$(date +%s)
        fi
        
        rate_limited=$((rate_limited + 1))
        echo -e "${RED}Rate limited (429)${NC}"
        
        # Display retry information
        if [ ! -z "$retry_after" ]; then
            if [[ "$retry_after" =~ ^[0-9]+$ ]]; then
                # It's a number of seconds
                echo -e "  ${YELLOW}Retry after: ${retry_after} seconds${NC}"
            else
                # It's a HTTP date format
                echo -e "  ${YELLOW}Retry after: ${retry_after}${NC}"
                # Convert HTTP date to seconds if you want
                # retry_seconds=$(date -d "$retry_after" +%s)
                # echo "  Retry after: $((retry_seconds - $(date +%s))) seconds"
            fi
        fi
        
        if [ ! -z "$reset" ]; then
            # If it's a timestamp, calculate seconds until reset
            if [[ "$reset" =~ ^[0-9]+$ ]]; then
                now=$(date +%s)
                seconds_until_reset=$((reset - now))
                echo -e "  ${YELLOW}Reset in: ${seconds_until_reset} seconds${NC}"
            else
                echo -e "  ${YELLOW}Reset at: ${reset}${NC}"
            fi
        fi
    else
        echo -e "${GREEN}Success (${status})${NC}"
    fi
    
    echo -e "  Limit: ${limit}, Remaining: ${remaining}"
    echo ""
    
    # Small delay between requests
    sleep $DELAY
done

# Summary
echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}Test Complete:${NC}"
echo -e "  Total requests: $REQUESTS"
echo -e "  Rate limited responses: $rate_limited"

# If we hit the rate limit, wait for reset and check if we can make requests again
if [ $rate_limited -gt 0 ] && [ ! -z "$reset" ] && [[ "$reset" =~ ^[0-9]+$ ]]; then
    now=$(date +%s)
    seconds_until_reset=$((reset - now))
    
    if [ $seconds_until_reset -gt 0 ] && [ $seconds_until_reset -lt 60 ]; then
        echo -e "\n${YELLOW}Waiting ${seconds_until_reset} seconds for rate limit to reset...${NC}"
        sleep $((seconds_until_reset + 1))
        
        echo -e "${YELLOW}Making request after reset period...${NC}"
        response=$(curl -s -D - -o /dev/null -w "Status: %{http_code}" $BASE_URL$ENDPOINT)
        status=$(echo "$response" | grep "Status:" | cut -d' ' -f2)
        
        if [ "$status" != "429" ]; then
            echo -e "${GREEN}Success (${status}) - Rate limit has reset!${NC}"
            remaining=$(echo "$response" | grep -i "X-RateLimit-Remaining:" | tr -d '\r' | cut -d' ' -f2)
            echo -e "  Remaining: ${remaining}"
        else
            echo -e "${RED}Still rate limited (429) - Rate limit has not reset yet.${NC}"
        fi
    else
        echo -e "\n${YELLOW}Reset time too long (${seconds_until_reset}s). Skipping reset test.${NC}"
    fi
fi

# Calculate rate limit reset time based on observation
if [ $first_rate_limit_hit -gt 0 ]; then
    # Check approx rate limit window
    now=$(date +%s)
    observed_window=$((now - first_rate_limit_hit))
    echo -e "\n${BLUE}Rate limit analysis:${NC}"
    echo -e "  First hit rate limit at: $(date -d @$first_rate_limit_hit)"
    echo -e "  Observed window so far: ${observed_window} seconds"
    echo -e "  Requests before rate limit: $((REQUESTS - rate_limited))"
fi

echo -e "${BLUE}==================================================${NC}"