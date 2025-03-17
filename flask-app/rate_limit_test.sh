#!/bin/bash
# rate_limit_test.sh
# Script to test rate limiting by sending 150 requests to the API endpoint

# Configuration
API_URL="http://localhost:30080/"
TOTAL_REQUESTS=150
REQUEST_TIMEOUT=5  # Timeout in seconds for each request

# Counters
successful_requests=0
rate_limited_requests=0
other_errors=0

# Arrays to store response times
declare -a response_times
declare -a status_codes

# Timestamp for the log file
timestamp=$(date +%Y%m%d%H%M%S)
log_file="rate_limit_test_${timestamp}.log"

# Create log file with header
echo "Rate Limit Test Results - $(date)" > "${log_file}"
echo "Target URL: ${API_URL}" >> "${log_file}"
echo "Total requests to send: ${TOTAL_REQUESTS}" >> "${log_file}"
echo "----------------------------------------" >> "${log_file}"

# Function to calculate elapsed time
function elapsed_time() {
    local start_time=$1
    local end_time=$2
    echo "$(echo "scale=3; ${end_time} - ${start_time}" | bc)"
}

echo "Starting rate limit test with ${TOTAL_REQUESTS} requests to ${API_URL}"
echo "Results will be logged to ${log_file}"
echo "----------------------------------------"

# Main test loop
for ((i=1; i<=${TOTAL_REQUESTS}; i++)); do
    # Get start time
    start_time=$(date +%s.%N)
    
    # Perform the request and capture status code and headers
    response=$(curl -s -w "%{http_code}\n%{time_total}\n" -o /tmp/response_body_$$ -X GET "${API_URL}" -m ${REQUEST_TIMEOUT})
    status_code=$(echo "${response}" | head -1)
    time_taken=$(echo "${response}" | tail -1)
    
    # Calculate elapsed time
    end_time=$(date +%s.%N)
    elapsed=$(elapsed_time ${start_time} ${end_time})
    
    # Store data
    response_times+=("${elapsed}")
    status_codes+=("${status_code}")
    
    # Process response
    if [[ "${status_code}" == "200" ]]; then
        successful_requests=$((successful_requests + 1))
        result="SUCCESS"
    elif [[ "${status_code}" == "429" ]]; then
        rate_limited_requests=$((rate_limited_requests + 1))
        result="RATE LIMITED"
        
        # Extract retry-after if available
        retry_after=$(cat /tmp/response_body_$$ | grep -o '"retry_after":[0-9]*' | cut -d ':' -f2)
        if [[ -n "${retry_after}" ]]; then
            result="${result} (Retry-After: ${retry_after}s)"
        fi
    else
        other_errors=$((other_errors + 1))
        result="ERROR (${status_code})"
    fi
    
    # Log progress
    log_message="Request ${i}/${TOTAL_REQUESTS}: ${result}, Time: ${elapsed}s"
    echo "${log_message}" >> "${log_file}"
    
    # Display progress every 10 requests
    if ((i % 10 == 0)) || ((i == 1)) || ((i == TOTAL_REQUESTS)); then
        echo "${log_message}"
    fi
    
    # Clean up temp file
    rm -f /tmp/response_body_$$
done

# Calculate success rate and average response time
success_rate=$(echo "scale=2; ${successful_requests} * 100 / ${TOTAL_REQUESTS}" | bc)
total_time=$(echo "${response_times[@]}" | tr ' ' '+' | bc)
avg_response_time=$(echo "scale=3; ${total_time} / ${#response_times[@]}" | bc)

# Write summary to log
echo "----------------------------------------" >> "${log_file}"
echo "Test Summary:" >> "${log_file}"
echo "Total Requests: ${TOTAL_REQUESTS}" >> "${log_file}"
echo "Successful (200): ${successful_requests}" >> "${log_file}"
echo "Rate Limited (429): ${rate_limited_requests}" >> "${log_file}"
echo "Other Errors: ${other_errors}" >> "${log_file}"
echo "Success Rate: ${success_rate}%" >> "${log_file}"
echo "Average Response Time: ${avg_response_time}s" >> "${log_file}"

# Display summary
echo "----------------------------------------"
echo "Test Complete! Summary:"
echo "Total Requests: ${TOTAL_REQUESTS}"
echo "Successful (200): ${successful_requests}"
echo "Rate Limited (429): ${rate_limited_requests}"
echo "Other Errors: ${other_errors}"
echo "Success Rate: ${success_rate}%"
echo "Average Response Time: ${avg_response_time}s"
echo "Detailed results saved to ${log_file}"