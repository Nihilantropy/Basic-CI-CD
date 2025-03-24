#!/bin/bash
# srcs/requirements/Scripts/test_monitoring.sh

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check HTTP endpoints
check_endpoint() {
  local service=$1
  local url=$2
  local expected_code=$3
  
  echo -n "Testing $service endpoint ($url)... "
  
  response=$(curl -s -o /dev/null -w "%{http_code}" $url)
  
  if [ "$response" = "$expected_code" ]; then
    echo -e "${GREEN}OK${NC} (HTTP $response)"
    return 0
  else
    echo -e "${RED}FAILED${NC} (Expected HTTP $expected_code, got HTTP $response)"
    return 1
  fi
}

# Check Prometheus availability
check_endpoint "Prometheus UI" "http://localhost:9090" 200
check_endpoint "Prometheus API" "http://localhost:9090/api/v1/status/config" 200

# Check Grafana availability
check_endpoint "Grafana UI" "http://localhost:3000" 200

# Check Prometheus targets
echo -n "Checking Prometheus targets... "
targets_output=$(curl -s "http://localhost:9090/api/v1/targets" | grep "\"state\":\"up\"")

if [ -n "$targets_output" ]; then
  echo -e "${GREEN}OK${NC} (At least one target is up)"
else
  echo -e "${RED}FAILED${NC} (No targets are up)"
fi

# Check Grafana datasources
echo -n "Checking Grafana authentication... "
auth_status=$(curl -s -o /dev/null -w "%{http_code}" -u "admin:admin" http://localhost:3000/api/datasources)

if [ "$auth_status" = "200" ]; then
  echo -e "${GREEN}OK${NC} (Authentication successful)"
else
  echo -e "${RED}FAILED${NC} (Authentication failed with HTTP $auth_status)"
fi

echo "Monitoring tests completed."