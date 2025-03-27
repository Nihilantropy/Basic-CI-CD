#!/bin/bash
# Script to test rate limiting by generating controlled traffic to Flask app

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Set the Flask application URL
APP_URL=${APP_URL:-"http://localhost:30080"}

# Test configuration
TOTAL_REQUESTS=${1:-150}       # Default to 150 requests total (should exceed rate limit)
REQUESTS_PER_SECOND=${2:-5}    # Default to 5 requests per second
ENDPOINT=${3:-"/"}             # Default endpoint to hit

# Stats variables
successful_requests=0
rate_limited_requests=0
other_errors=0
start_time=$(date +%s)

# Function to make a request and process the response
make_request() {
    local request_num=$1
    local response=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL$ENDPOINT")
    
    case $response in
        200|201)
            echo -n -e "${GREEN}.${NC}"
            ((successful_requests++))
            ;;
        429)
            echo -n -e "${RED}R${NC}"
            ((rate_limited_requests++))
            ;;
        *)
            echo -n -e "${YELLOW}E${NC}"
            ((other_errors++))
            ;;
    esac
    
    # Print a newline every 50 requests for readability
    if (( request_num % 50 == 0 )); then
        echo " ($request_num)"
    fi
}

# Check if app is reachable
echo -e "${BLUE}Checking if Flask app is accessible at ${APP_URL}...${NC}"
if ! curl -s --connect-timeout 3 "$APP_URL/health" | grep -q "healthy"; then
    echo -e "${RED}ERROR: Cannot connect to Flask app at ${APP_URL}${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Flask app is accessible!${NC}"
echo

# Display test parameters
echo -e "${CYAN}Rate Limit Test Configuration:${NC}"
echo "Total requests:       $TOTAL_REQUESTS"
echo "Requests per second:  $REQUESTS_PER_SECOND"
echo "Target endpoint:      $ENDPOINT"
echo "Target URL:           $APP_URL$ENDPOINT"
echo

# Calculate expected duration
expected_duration=$((TOTAL_REQUESTS / REQUESTS_PER_SECOND))
echo -e "${BLUE}Test will take approximately ${expected_duration} seconds${NC}"
echo -e "${BLUE}Legend: ${GREEN}.${BLUE} = success, ${RED}R${BLUE} = rate limited, ${YELLOW}E${BLUE} = other error${NC}"
echo

# Perform the test
echo -e "${CYAN}Starting test...${NC}"
for ((i=1; i<=TOTAL_REQUESTS; i++)); do
    make_request $i
    
    # Sleep to maintain the requested rate
    # Skip sleep on the last request
    if (( i < TOTAL_REQUESTS )); then
        sleep $(bc -l <<< "scale=4; 1/$REQUESTS_PER_SECOND")
    fi
done

echo  # Final newline after the progress indicators

# Calculate test duration
end_time=$(date +%s)
duration=$((end_time - start_time))

# Check Prometheus for rate limit counter
echo
echo -e "${CYAN}Checking Prometheus for rate limit metrics...${NC}"
rate_limit_count=$(curl -s "http://localhost:9090/api/v1/query?query=appflask_rate_limit_hits_total" | grep -o '"value":\[[^]]*\]' | head -1)

# Display results
echo
echo -e "${CYAN}Results:${NC}"
echo "Test duration:        $duration seconds"
echo "Successful requests:  $successful_requests"
echo "Rate limited:         $rate_limited_requests"
echo "Other errors:         $other_errors"
echo "Total requests:       $((successful_requests + rate_limited_requests + other_errors))"
echo "Actual request rate:  $(bc -l <<< "scale=2; ($successful_requests + $rate_limited_requests + $other_errors)/$duration") requests/second"
echo

# Check if rate limiting was triggered
if [ $rate_limited_requests -gt 0 ]; then
    echo -e "${GREEN}✓ Rate limiting was successfully triggered!${NC}"
    echo "Prometheus rate limit counter: $rate_limit_count"
    echo -e "${BLUE}Check your Grafana dashboard to see the rate limit metrics visualization${NC}"
else
    echo -e "${YELLOW}⚠ No rate limiting was detected${NC}"
    echo "Possible reasons:"
    echo "1. Rate limit threshold not reached (try increasing requests per second)"
    echo "2. Rate limit window is longer than expected"
    echo "3. Rate limiting is not properly configured in the application"
fi