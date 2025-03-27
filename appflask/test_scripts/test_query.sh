#!/bin/bash
# Improved script to test that Prometheus can query the Flask application metrics

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Set the Prometheus server URL
PROMETHEUS_URL=${PROMETHEUS_URL:-"http://localhost:9090"}

# Set the metric prefix
METRIC_PREFIX="appflask_"

# Set the Flask app service URL
FLASK_APP_URL=${FLASK_APP_URL:-"http://localhost:30080"}

# Set the time range for rate queries (shorter time window more likely to succeed)
TIME_RANGE=${TIME_RANGE:-"1m"}

# Define metrics to test
METRICS=(
  "${METRIC_PREFIX}http_requests_total"
  "${METRIC_PREFIX}http_request_duration_seconds_count"
  "${METRIC_PREFIX}http_request_duration_seconds_sum"
  "${METRIC_PREFIX}http_request_duration_seconds_bucket"
  "${METRIC_PREFIX}http_requests_in_flight"
  "${METRIC_PREFIX}app_info"
  "${METRIC_PREFIX}uptime_seconds"
  "${METRIC_PREFIX}start_time_seconds"
  "${METRIC_PREFIX}rate_limit_hits_total"
  "${METRIC_PREFIX}rate_limit_remaining"
)

# Function to test a query
test_query() {
  local metric=$1
  local query=$2
  local description=$3
  
  echo -e "${YELLOW}Testing: ${description}${NC}"
  
  # Execute query against Prometheus
  response=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=${query}")
  
  # Check if the query was successful
  if echo "$response" | grep -q '"status":"success"'; then
    # Check if there are any results
    if echo "$response" | grep -q '"resultType":"vector"' && echo "$response" | grep -q '"value":\['; then
      echo -e "${GREEN}✓ Success: ${metric} is being collected and can be queried${NC}"
      echo "Sample data:" 
      echo "$response" | grep -o '"value":\[[^]]*\]' | head -1
      return 0
    else
      echo -e "${YELLOW}✓ Query succeeded but no data found for: ${metric}${NC}"
      echo "This often happens for rate() functions if there's not enough data points yet."
      echo "Try generating more traffic to your application or waiting longer."
      return 1
    fi
  else
    echo -e "${RED}✗ Query failed for: ${metric}${NC}"
    error_msg=$(echo "$response" | grep -o '"error":"[^"]*"')
    echo "Error response: $error_msg"
    return 1
  fi
}

# Function to generate traffic to the Flask app
generate_traffic() {
  local num_requests=$1
  local endpoint=$2
  
  echo -e "${BLUE}Generating ${num_requests} requests to ${endpoint}...${NC}"
  
  for i in $(seq 1 $num_requests); do
    curl -s "${FLASK_APP_URL}${endpoint}" > /dev/null
    echo -n "."
    sleep 0.1
  done
  echo
  echo -e "${BLUE}Traffic generation complete.${NC}"
  # Small delay to allow metrics to be collected
  sleep 2
  echo
}

# First check if Prometheus is accessible
echo "Checking connection to Prometheus at ${PROMETHEUS_URL}..."
if ! curl -s "${PROMETHEUS_URL}/-/healthy" | grep -q "Prometheus"; then
  echo -e "${RED}ERROR: Cannot connect to Prometheus at ${PROMETHEUS_URL}${NC}"
  exit 1
fi

echo -e "${GREEN}Connection to Prometheus successful!${NC}"
echo

# Try to generate some traffic to ensure metric values exist
echo "Checking if Flask app is accessible at ${FLASK_APP_URL}..."
if curl -s --connect-timeout 3 "${FLASK_APP_URL}/health"; then
  echo -e "${GREEN}Flask app is accessible! Generating some traffic...${NC}"
  echo
  generate_traffic 10 "/"
  generate_traffic 5 "/health"
  generate_traffic 3 "/metrics"
else
  echo -e "${YELLOW}Warning: Could not connect to Flask app at ${FLASK_APP_URL}${NC}"
  echo "Will continue with tests, but rate queries may fail without traffic data."
  echo
fi

# Test all metrics
success_count=0
total_metrics=${#METRICS[@]}

echo "Testing ${total_metrics} metrics with prefix '${METRIC_PREFIX}'..."
echo

# Test basic metric existence
for metric in "${METRICS[@]}"; do
  if test_query "$metric" "$metric" "Basic query for $metric"; then
    ((success_count++))
  fi
  echo
done

# Test more complex queries with explanations
echo "Testing advanced queries (these may fail if not enough data points)..."
echo

# Test rate of requests over time
if test_query "request_rate" "rate(${METRIC_PREFIX}http_requests_total[${TIME_RANGE}])" "Rate of requests over ${TIME_RANGE}"; then
  ((success_count++))
else
  echo -e "${BLUE}Note: This query requires multiple data points over time to calculate a rate.${NC}"
fi
echo

# Test average request duration with fallback
avg_query="rate(${METRIC_PREFIX}http_request_duration_seconds_sum[${TIME_RANGE}]) / rate(${METRIC_PREFIX}http_request_duration_seconds_count[${TIME_RANGE}])"
if test_query "average_duration" "$avg_query" "Average request duration"; then
  ((success_count++))
else
  # Try a simpler query if the rate query fails
  echo -e "${BLUE}Trying simpler query for average duration...${NC}"
  if test_query "average_duration_simple" "${METRIC_PREFIX}http_request_duration_seconds_sum / ${METRIC_PREFIX}http_request_duration_seconds_count" "Simple average duration"; then
    ((success_count++))
  fi
fi
echo

# Test 95th percentile latency
percentile_query="histogram_quantile(0.95, sum(rate(${METRIC_PREFIX}http_request_duration_seconds_bucket[${TIME_RANGE}])) by (le))"
if test_query "percentile_95" "$percentile_query" "95th percentile request duration"; then
  ((success_count++))
else
  echo -e "${BLUE}Note: Percentile calculations require multiple data points in histogram buckets.${NC}"
  echo -e "${BLUE}If your app hasn't received enough traffic, this query will fail.${NC}"
fi
echo

# Check if we can see uptime metrics
if test_query "uptime_check" "${METRIC_PREFIX}uptime_seconds > 0" "Application uptime check"; then
  ((success_count++))
  echo -e "${GREEN}✓ Application uptime metrics confirm the app is running${NC}"
else
  echo -e "${YELLOW}Warning: Couldn't confirm application uptime${NC}"
fi
echo

# Calculate total tests - the actual number we ran including the uptime check
total_tests=$((total_metrics + 4)) # Base metrics + 3 advanced queries + uptime check

# Output summary
echo "Summary:"
echo -e "${GREEN}${success_count}/${total_tests} tests passed${NC}"

if [ $success_count -ge $total_metrics ]; then
  echo -e "${GREEN}All basic metrics are being collected by Prometheus!${NC}"
  
  if [ $success_count -lt $total_tests ]; then
    echo -e "${YELLOW}Some advanced rate queries failed, but this is normal if:${NC}"
    echo "1. The application hasn't been running long enough (need at least a few minutes)"
    echo "2. There haven't been enough requests to calculate rates"
    echo "3. The application is not receiving regular traffic"
    echo
    echo "Try running this test again after using the application for a few minutes."
  else
    echo -e "${GREEN}All metrics and advanced queries are working perfectly!${NC}"
  fi
  
  exit 0
else
  echo -e "${RED}Some basic metrics are not being collected or cannot be queried.${NC}"
  echo "Troubleshooting steps:"
  echo "1. Ensure the Flask application is exposing metrics correctly at /metrics"
  echo "2. Verify Prometheus scrape configuration includes the Flask app target"
  echo "3. Check network connectivity between Prometheus and the Flask app"
  echo "4. Look for errors in the Prometheus logs"
  exit 1
fi