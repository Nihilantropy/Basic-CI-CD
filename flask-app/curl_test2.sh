#!/bin/bash

# Change this to your Flask app URL
BASE_URL="http://localhost:5000"

# Function to make a request and print rate limit information
make_request() {
    echo -e "\n--- Request #$1 ---"
    response=$(curl -s -i "$BASE_URL/")
    
    # Get status code
    status_code=$(echo "$response" | grep -oP "HTTP/\d+\.\d+ \K\d+")
    echo "Status Code: $status_code"
    
    # Print rate limit headers
    echo "Rate Limit Headers:"
    echo "$response" | grep -i "ratelimit\|retry" | sed 's/^/  /'
    
    # Print response body
    body=$(echo "$response" | sed -n -e '/^\r$/,$p' | sed '1d')
    echo "Response Body:"
    echo "$body" | python3 -m json.tool | sed 's/^/  /'
    
    # Return status code for checking rate limit
    echo $status_code
}

echo "Starting rate limit test..."

# First phase: Make requests until we hit the rate limit
count=1
status=200

while [ "$status" -ne 429 ] && [ $count -le 200 ]; do
    status=$(make_request $count)
    ((count++))
    
    # Small delay to avoid overwhelming the server
    sleep 0.1
done

if [ $count -ge 200 ]; then
    echo "Made 200 requests without hitting rate limit. Check your configuration."
    exit 1
fi

echo -e "\nHit rate limit! Now we'll check the countdown..."

# Extract retry-after value from response
response=$(curl -s "$BASE_URL/")
retry_after=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin).get('retry_after', 60))")

# Use smaller value between retry_after and 60
if [ $retry_after -gt 60 ]; then
    wait_time=60
else
    wait_time=$retry_after
fi

echo "Will check every 1 seconds for $wait_time seconds"

# Second phase: Make periodic requests to see the countdown
end_time=$(($(date +%s) + wait_time))
while [ $(date +%s) -lt $end_time ]; do
    make_request "countdown"
    sleep 1
done

# Final phase: Confirm rate limit reset
echo -e "\nRate limit should be reset or close to reset. Making final request:"
make_request "final"

echo -e "\nTest completed!"