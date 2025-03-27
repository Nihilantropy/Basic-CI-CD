#!/bin/bash
# Script to test Prometheus alerts for Flask rate limits

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Set URLs
PROMETHEUS_URL=${PROMETHEUS_URL:-"http://localhost:9090"}
ALERTMANAGER_URL=${ALERTMANAGER_URL:-"http://localhost:9093"}
FLASK_APP_URL=${FLASK_APP_URL:-"http://localhost:30080"}

# Check if Prometheus is accessible
echo -e "${BLUE}Checking Prometheus connection...${NC}"
if ! curl -s "${PROMETHEUS_URL}/-/healthy" > /dev/null; then
    echo -e "${RED}ERROR: Cannot connect to Prometheus at ${PROMETHEUS_URL}${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Prometheus is accessible${NC}"

# Check if Alertmanager is accessible
echo -e "${BLUE}Checking Alertmanager connection...${NC}"
if ! curl -s "${ALERTMANAGER_URL}/-/healthy" > /dev/null; then
    echo -e "${YELLOW}WARNING: Cannot connect to Alertmanager at ${ALERTMANAGER_URL}${NC}"
    echo "Alert notifications may not work, but we can still check alert status in Prometheus"
else
    echo -e "${GREEN}✓ Alertmanager is accessible${NC}"
fi

# Check for existing alerts
echo -e "${BLUE}Checking for existing alerts...${NC}"
ALERTS=$(curl -s "${PROMETHEUS_URL}/api/v1/alerts")
if echo "$ALERTS" | grep -q "FlaskRateLimitExceeded"; then
    echo -e "${YELLOW}Alert 'FlaskRateLimitExceeded' is already defined${NC}"
else
    echo -e "${GREEN}No existing rate limit alerts found${NC}"
fi

# Check current rate limit counter value
echo -e "${BLUE}Checking current rate limit counter value...${NC}"
COUNTER_RESPONSE=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=appflask_rate_limit_hits_total")
if echo "$COUNTER_RESPONSE" | grep -q '"resultType":"vector"'; then
    COUNTER_VALUE=$(echo "$COUNTER_RESPONSE" | grep -o '"value":\[[^]]*\]' | awk -F '[' '{print $2}' | awk -F ',' '{print $2}' | tr -d '"]')
    echo -e "Current counter value: ${CYAN}${COUNTER_VALUE}${NC}"
    
    if (( $(echo "$COUNTER_VALUE >= 200" | bc -l) )); then
        echo -e "${RED}Counter already exceeds alert threshold of 200${NC}"
        echo "You may need to reset the counter or adjust the alert threshold"
    else
        REMAINING=$(echo "200 - $COUNTER_VALUE" | bc)
        echo -e "${GREEN}Need ${REMAINING} more rate limit hits to trigger alert${NC}"
    fi
else
    echo -e "${RED}Failed to retrieve counter value${NC}"
    echo "Response: $COUNTER_RESPONSE"
fi

# Function to generate traffic and hit rate limits
generate_traffic() {
    local target_count=$1
    local current_count=$(echo "$COUNTER_VALUE" | bc 2>/dev/null || echo "0")
    local needed=$(echo "$target_count - $current_count" | bc 2>/dev/null || echo "1000")
    
    # If needed is negative or zero, set a minimum
    if (( $(echo "$needed <= 0" | bc -l) )); then
        needed=50  # Generate at least some traffic
    fi
    
    echo -e "${CYAN}Generating traffic to hit rate limit ${needed} times...${NC}"
    echo -e "${YELLOW}This may take a while depending on your rate limit configuration${NC}"
    
    # Track progress
    local starting_count=$current_count
    local last_count=$starting_count
    local hits_generated=0
    local start_time=$(date +%s)
    
    # Make many requests as fast as possible to trigger rate limits
    for ((i=1; i<=needed*5; i++)); do
        # Every 50 requests, check if we've hit enough rate limits
        if (( i % 50 == 0 )); then
            # Query the current counter value
            CURRENT_RESPONSE=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=appflask_rate_limit_hits_total")
            if echo "$CURRENT_RESPONSE" | grep -q '"resultType":"vector"'; then
                CURRENT_VALUE=$(echo "$CURRENT_RESPONSE" | grep -o '"value":\[[^]]*\]' | awk -F '[' '{print $2}' | awk -F ',' '{print $2}' | tr -d '"]')
                
                # Calculate how many new hits we've generated
                hits_generated=$(echo "$CURRENT_VALUE - $starting_count" | bc 2>/dev/null || echo "0")
                
                # Show progress
                new_since_last=$(echo "$CURRENT_VALUE - $last_count" | bc 2>/dev/null || echo "0")
                last_count=$CURRENT_VALUE
                
                echo -e "${BLUE}Progress: ${hits_generated}/${needed} rate limit hits (+${new_since_last} new)${NC}"
                
                # If we've hit enough rate limits, break
                if (( $(echo "$hits_generated >= $needed" | bc -l) )); then
                    echo -e "${GREEN}✓ Generated enough rate limit hits!${NC}"
                    break
                fi
            fi
        fi
        
        # Make a request that will eventually trigger rate limiting
        curl -s -o /dev/null "$FLASK_APP_URL/"
        
        # Add a small delay to avoid overwhelming the system
        sleep 0.05
    done
    
    # Calculate final statistics
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo -e "${GREEN}Traffic generation complete${NC}"
    echo "Duration: ${duration} seconds"
    echo "Rate limit hits generated: ${hits_generated}"
    echo "Requests per second: $(echo "scale=2; (${i})/${duration}" | bc)"
}

# Ask if user wants to generate traffic to trigger alert
echo
echo -e "${CYAN}Do you want to generate traffic to trigger the alert? (y/n)${NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    generate_traffic 200
    
    # Check if alert has been triggered
    echo
    echo -e "${BLUE}Checking if alert has been triggered...${NC}"
    echo -e "${YELLOW}Note: It may take up to 1 minute for the alert to fire${NC}"
    
    # Wait for alert evaluation
    echo -e "${BLUE}Waiting 90 seconds for alert evaluation...${NC}"
    for i in {1..3}; do
        echo -e "${BLUE}Checking alert status (attempt $i of 3)...${NC}"
        ALERTS=$(curl -s "${PROMETHEUS_URL}/api/v1/alerts")
        
        if echo "$ALERTS" | grep -q "FlaskRateLimitExceeded"; then
            echo -e "${GREEN}✓ Alert 'FlaskRateLimitExceeded' has been triggered!${NC}"
            alert_state=$(echo "$ALERTS" | grep -o '"state":"[^"]*"' | head -1 | awk -F '"' '{print $4}')
            echo -e "Alert state: ${CYAN}${alert_state}${NC}"
            
            # If Alertmanager is accessible, check for firing alerts there too
            if curl -s "${ALERTMANAGER_URL}/-/healthy" > /dev/null; then
                AM_ALERTS=$(curl -s "${ALERTMANAGER_URL}/api/v2/alerts")
                if echo "$AM_ALERTS" | grep -q "FlaskRateLimitExceeded"; then
                    echo -e "${GREEN}✓ Alert is also visible in Alertmanager${NC}"
                fi
            fi
            
            break
        else
            echo -e "${YELLOW}Alert not triggered yet${NC}"
            sleep 30
        fi
    done
    
    # Final check of counter value
    FINAL_RESPONSE=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=appflask_rate_limit_hits_total")
    if echo "$FINAL_RESPONSE" | grep -q '"resultType":"vector"'; then
        FINAL_VALUE=$(echo "$FINAL_RESPONSE" | grep -o '"value":\[[^]]*\]' | awk -F '[' '{print $2}' | awk -F ',' '{print $2}' | tr -d '"]')
        echo -e "Final counter value: ${CYAN}${FINAL_VALUE}${NC}"
    fi
else
    echo -e "${YELLOW}Skipping traffic generation${NC}"
fi

# Instructions for checking alerts in Grafana
echo
echo -e "${CYAN}To view alerts in Grafana:${NC}"
echo "1. Go to Grafana at http://localhost:3000"
echo "2. Navigate to Alerting > Alert rules"
echo "3. You should see the 'FlaskRateLimitExceeded' alert if it's been triggered"
echo
echo -e "${CYAN}To reset the counter for future testing:${NC}"
echo "You would need to restart your Flask application"