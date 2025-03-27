#!/bin/bash
# Comprehensive rate limit testing script with metrics validation

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Set the Flask application URL
APP_URL=${APP_URL:-"http://localhost:30080"}
# Set the Prometheus URL
PROM_URL=${PROM_URL:-"http://localhost:9090"}

# Test configuration
TOTAL_REQUESTS=${1:-150}       # Default to 150 requests total (should exceed rate limit)
REQUESTS_PER_SECOND=${2:-10}   # Default to 10 requests per second
ENDPOINT=${3:-"/"}             # Default endpoint to hit
TEST_DURATION=${4:-60}         # Duration to monitor metrics after test (seconds)

# Stats variables
successful_requests=0
rate_limited_requests=0
other_errors=0
start_time=$(date +%s)

# Function to make a request and process the response
make_request() {
    local request_num=$1
    local response_code
    local retry_after
    
    # Capture both status code and headers
    response=$(curl -s -i "$APP_URL$ENDPOINT")
    response_code=$(echo "$response" | grep -E "^HTTP/[0-9.]+ [0-9]+" | awk '{print $2}')
    
    # Check for Retry-After header if rate limited
    if [[ "$response_code" == "429" ]]; then
        retry_after=$(echo "$response" | grep -i "Retry-After" | awk '{print $2}' | tr -d '\r')
    fi
    
    case $response_code in
        200|201)
            echo -n -e "${GREEN}.${NC}"
            ((successful_requests++))
            ;;
        429)
            if [[ -n "$retry_after" ]]; then
                echo -n -e "${RED}R(${retry_after}s)${NC}"
            else
                echo -n -e "${RED}R${NC}"
            fi
            ((rate_limited_requests++))
            ;;
        *)
            echo -n -e "${YELLOW}E(${response_code})${NC}"
            ((other_errors++))
            ;;
    esac
    
    # Print a newline every 25 requests for readability
    if (( request_num % 25 == 0 )); then
        echo " ($request_num)"
    fi
    
    return $response_code
}

# Function to query Prometheus
query_prometheus() {
    local query=$1
    local description=$2
    
    echo -e "${BLUE}Querying: ${description}${NC}"
    
    response=$(curl -s "${PROM_URL}/api/v1/query?query=${query}")
    
    if echo "$response" | grep -q '"status":"success"'; then
        if echo "$response" | grep -q '"value":\['; then
            value=$(echo "$response" | grep -o '"value":\[[^]]*\]' | awk -F '[' '{print $2}' | awk -F ',' '{print $2}' | tr -d '"]')
            echo -e "${GREEN}✓ Value: ${value}${NC}"
            return 0
        else
            echo -e "${YELLOW}No data returned${NC}"
            return 1
        fi
    else
        echo -e "${RED}Query failed${NC}"
        return 2
    fi
}

# Check if app is reachable
echo -e "${BLUE}Checking if Flask app is accessible at ${APP_URL}...${NC}"
if ! curl -s --connect-timeout 3 "$APP_URL/health" | grep -q "healthy"; then
    echo -e "${RED}ERROR: Cannot connect to Flask app at ${APP_URL}${NC}"
    exit 1
fi

# Check if Prometheus is reachable
echo -e "${BLUE}Checking if Prometheus is accessible at ${PROM_URL}...${NC}"
if ! curl -s --connect-timeout 3 "${PROM_URL}/-/healthy" > /dev/null; then
    echo -e "${YELLOW}WARNING: Cannot connect to Prometheus at ${PROM_URL}${NC}"
    echo "Will continue without metrics validation"
    SKIP_METRICS=true
else
    echo -e "${GREEN}✓ Prometheus is accessible${NC}"
    SKIP_METRICS=false
fi

echo -e "${GREEN}✓ Flask app is accessible!${NC}"
echo

# Display test parameters
echo -e "${CYAN}Rate Limit Test Configuration:${NC}"
echo "Total requests:       $TOTAL_REQUESTS"
echo "Requests per second:  $REQUESTS_PER_SECOND"
echo "Target endpoint:      $ENDPOINT"
echo "Target URL:           $APP_URL$ENDPOINT"
echo "Metrics validation:   $(if [[ "$SKIP_METRICS" == "true" ]]; then echo "Disabled"; else echo "Enabled"; fi)"
echo

# Capture initial rate limit metrics if Prometheus is available
if [[ "$SKIP_METRICS" == "false" ]]; then
    echo -e "${CYAN}Capturing initial metrics:${NC}"
    query_prometheus "appflask_rate_limit_hits_total" "Initial rate limit counter"
    initial_rate_limit_count=$value
    query_prometheus "sum(appflask_http_requests_total)" "Initial request counter"
    initial_request_count=$value
    echo
fi

# Calculate expected duration
expected_duration=$((TOTAL_REQUESTS / REQUESTS_PER_SECOND))
echo -e "${BLUE}Test will take approximately ${expected_duration} seconds${NC}"
echo -e "${BLUE}Legend: ${GREEN}.${BLUE} = success, ${RED}R${BLUE} = rate limited, ${YELLOW}E${BLUE} = other error${NC}"
echo

# Perform the test
echo -e "${CYAN}Starting test...${NC}"

# Track the first rate limit occurrence
first_rate_limit_time=0
first_rate_limit_request=0

for ((i=1; i<=TOTAL_REQUESTS; i++)); do
    make_request $i
    response_code=$?
    
    # Track first rate limit occurrence
    if [[ $response_code -eq 429 && $first_rate_limit_time -eq 0 ]]; then
        first_rate_limit_time=$(date +%s)
        first_rate_limit_request=$i
    fi
    
    # Sleep to maintain the requested rate
    # Skip sleep on the last request
    if (( i < TOTAL_REQUESTS )); then
        sleep $(bc -l <<< "scale=4; 1/$REQUESTS_PER_SECOND")
    fi
done

echo  # Final newline after the progress indicators

# Calculate test duration
end_time=$(date +%s)
test_duration=$((end_time - start_time))

# Wait a moment for metrics to be collected
if [[ "$SKIP_METRICS" == "false" ]]; then
    echo -e "${MAGENTA}Waiting 5 seconds for metrics to be collected...${NC}"
    sleep 5
fi

# Display results
echo
echo -e "${CYAN}Test Results:${NC}"
echo "Test duration:        $test_duration seconds"
echo "Successful requests:  $successful_requests"
echo "Rate limited:         $rate_limited_requests"
echo "Other errors:         $other_errors"
echo "Total requests:       $((successful_requests + rate_limited_requests + other_errors))"
echo "Actual request rate:  $(bc -l <<< "scale=2; ($successful_requests + $rate_limited_requests + $other_errors)/$test_duration") requests/second"

if [[ $first_rate_limit_time -gt 0 ]]; then
    rate_limit_time_seconds=$((first_rate_limit_time - start_time))
    echo "Rate limit triggered: After $rate_limit_time_seconds seconds ($first_rate_limit_request requests)"
fi

echo

# Check metrics if Prometheus is available and rate limiting occurred
if [[ "$SKIP_METRICS" == "false" && $rate_limited_requests -gt 0 ]]; then
    echo -e "${CYAN}Validating metrics after test:${NC}"
    query_prometheus "appflask_rate_limit_hits_total" "Final rate limit counter"
    final_rate_limit_count=$value
    
    query_prometheus "sum(appflask_http_requests_total)" "Final request counter"
    final_request_count=$value
    
    # Calculate metric changes
    rate_limit_delta=$(bc <<< "$final_rate_limit_count - $initial_rate_limit_count")
    request_delta=$(bc <<< "$final_request_count - $initial_request_count")
    
    echo
    echo -e "${CYAN}Metrics Analysis:${NC}"
    echo "Rate limit counter increased by: $rate_limit_delta"
    echo "Request counter increased by:    $request_delta"
    
    # Validate metrics against actual results
    if (( $(bc <<< "$rate_limit_delta > 0") )); then
        echo -e "${GREEN}✓ Rate limit metrics are being recorded in Prometheus${NC}"
    else
        echo -e "${YELLOW}⚠ Rate limit metrics didn't increase in Prometheus${NC}"
    fi
    
    # Monitor metrics for a period to see changes
    if [[ $TEST_DURATION -gt 0 ]]; then
        echo
        echo -e "${MAGENTA}Monitoring metrics for ${TEST_DURATION} seconds...${NC}"
        
        # Take measurements every 10 seconds
        intervals=$((TEST_DURATION / 10))
        for ((i=1; i<=intervals; i++)); do
            echo -e "${BLUE}Measurement $i of $intervals (after $(( i * 10 )) seconds):${NC}"
            query_prometheus "appflask_rate_limit_hits_total" "Rate limit counter"
            query_prometheus "sum(appflask_http_requests_total)" "Request counter"
            query_prometheus "appflask_rate_limit_remaining" "Rate limit remaining"
            echo
            
            # Wait for next interval
            if (( i < intervals )); then
                sleep 10
            fi
        done
    fi
fi

# Final assessment
echo -e "${CYAN}Final Assessment:${NC}"

if [[ $rate_limited_requests -gt 0 ]]; then
    echo -e "${GREEN}✓ Rate limiting was successfully triggered!${NC}"
    if [[ "$SKIP_METRICS" == "false" && $(bc <<< "$rate_limit_delta > 0") -eq 1 ]]; then
        echo -e "${GREEN}✓ Rate limit metrics are correctly recorded in Prometheus${NC}"
        echo -e "${BLUE}Check your Grafana dashboard to see the rate limit metrics visualization${NC}"
    fi
else
    echo -e "${YELLOW}⚠ No rate limiting was detected${NC}"
    echo "Possible reasons:"
    echo "1. Rate limit threshold not reached (try increasing requests per second)"
    echo "2. Rate limit window is longer than expected"
    echo "3. Rate limiting is not properly configured in the application"
fi

# Exit with success if rate limiting was detected
if [[ $rate_limited_requests -gt 0 ]]; then
    exit 0
else
    exit 1
fi