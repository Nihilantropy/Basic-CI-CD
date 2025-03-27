#!/bin/bash
# Script to test and validate Prometheus queries for Jenkins pipeline metrics
# This script will query Prometheus to verify that the metrics exist and can be queried

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is required for this script. Please install it first."
    echo "You can usually install it with: apt-get install jq, yum install jq, or brew install jq"
    exit 1
fi

# Color definitions for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Set the Prometheus server URL
PROMETHEUS_URL=${PROMETHEUS_URL:-"http://localhost:9090"}

# Basic util function to query Prometheus
query_prometheus() {
    local query=$1
    local description=$2
    local quiet=${3:-false}
    
    [ "$quiet" = "false" ] && echo -e "${BLUE}Testing: ${description}${NC}"
    [ "$quiet" = "false" ] && echo -e "${CYAN}Query: ${query}${NC}"
    
    # URL encode the query
    local encoded_query=$(echo -n "${query}" | jq -s -R -r @uri)
    response=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=${encoded_query}")
    
    # Check if the query was successful
    if echo "$response" | grep -q '"status":"success"'; then
        # Check if there are results
        if echo "$response" | grep -q '"resultType":"vector"' && [[ $(echo "$response" | grep -o '"value":\[[^]]*\]' | wc -l) -gt 0 ]]; then
            [ "$quiet" = "false" ] && echo -e "${GREEN}✓ Success: Data found for query${NC}"
            # Print more detailed data for better understanding
            sample_data=$(echo "$response" | jq -r '.data.result[0:2]' 2>/dev/null || echo "$response" | grep -o '"value":\[[^]]*\]' | head -1)
            [ "$quiet" = "false" ] && echo -e "Sample data: ${sample_data}"
            return 0
        elif echo "$response" | grep -q '"resultType":"matrix"' && [[ $(echo "$response" | grep -o '"values":\[' | wc -l) -gt 0 ]]; then
            [ "$quiet" = "false" ] && echo -e "${GREEN}✓ Success: Range data found for query${NC}"
            [ "$quiet" = "false" ] && echo -e "Range data detected"
            return 0
        else
            [ "$quiet" = "false" ] && echo -e "${YELLOW}✓ Query successful but no data returned${NC}"
            [ "$quiet" = "false" ] && echo "This may be normal if the metric hasn't been recorded yet or the query filters out all data."
            return 2
        fi
    else
        error_msg=$(echo "$response" | jq -r '.error' 2>/dev/null || echo "$response" | grep -o '"error":"[^"]*"' || echo "Unknown error")
        [ "$quiet" = "false" ] && echo -e "${RED}✗ Query failed${NC}"
        [ "$quiet" = "false" ] && echo "Error response: ${error_msg}"
        [ "$quiet" = "false" ] && echo "Full response: ${response}"
        return 1
    fi
}

# Function to check if a metric exists in Prometheus
metric_exists() {
    local metric=$1
    
    # First try using the count approach
    response=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=count(${metric})>0")
    
    if echo "$response" | grep -q '"status":"success"'; then
        # Check if the metric exists
        if echo "$response" | grep -q '"value":\[' && echo "$response" | grep -q '1\]'; then
            return 0  # Metric exists
        fi
    fi
    
    # If count approach fails, try direct query
    response=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=${metric}")
    
    if echo "$response" | grep -q '"status":"success"'; then
        # Check if the response has any values
        if echo "$response" | grep -q '"value":\['; then
            return 0  # Metric exists
        else
            return 1  # Metric doesn't exist
        fi
    else
        return 2  # Query failed
    fi
}

# Main function to run all tests
run_all_tests() {
    local success_count=0
    local empty_count=0
    local error_count=0
    local total_count=0
    
    echo "======================================================================================"
    echo "  PROMETHEUS QUERY VALIDATION SCRIPT FOR JENKINS PIPELINE METRICS"
    echo "======================================================================================"
    echo
    echo "Prometheus URL: ${PROMETHEUS_URL}"
    echo
    
    # # First, check if the basic metrics exist
    # echo "Checking if basic metrics exist..."
    
    # # Core metrics to check existence
    # core_metrics=(
    #     "jenkins_pipeline_started_total"
    #     "jenkins_pipeline_completed_total"
    #     "jenkins_pipeline_duration_milliseconds"
    #     "jenkins_pipeline_stage_started_total"
    #     "jenkins_pipeline_stage_completed_total"
    #     "jenkins_pipeline_stage_duration_milliseconds"
    #     "jenkins_pipeline_ruff_issues_total"
    #     "jenkins_pipeline_bandit_vulnerabilities_total"
    #     "jenkins_pipeline_test_results_total"
    #     "jenkins_pipeline_test_duration_milliseconds"
    #     "jenkins_pipeline_artifact_size_bytes"
    #     "jenkins_pipeline_nexus_upload_status"
    #     "jenkins_pipeline_queue_time_milliseconds"
    #     "jenkins_pipeline_resource_utilization"
    #     "jenkins_pipeline_execution_frequency"
    #     "jenkins_executor_utilization_percent"
    # )
    
    # missing_metrics=()
    
    # for metric in "${core_metrics[@]}"; do
    #     echo -n "Checking metric: ${metric}... "
    #     if metric_exists "$metric"; then
    #         echo -e "${GREEN}Found${NC}"
    #     else
    #         echo -e "${RED}Not found${NC}"
    #         missing_metrics+=("$metric")
    #     fi
    # done
    
    # if [ ${#missing_metrics[@]} -gt 0 ]; then
    #     echo
    #     echo -e "${YELLOW}Warning: The following metrics were not found in Prometheus:${NC}"
    #     for metric in "${missing_metrics[@]}"; do
    #         echo " - $metric"
    #     done
    #     echo
    #     echo "This may be because:"
    #     echo " 1. The pipeline hasn't pushed these metrics yet"
    #     echo " 2. The metrics have a different prefix or naming convention"
    #     echo " 3. The Push Gateway is not properly configured"
    #     echo
    #     echo "Consider running a pipeline with metrics enabled before testing queries."
    #     echo
    # else
    #     echo
    #     echo -e "${GREEN}All core metrics found in Prometheus!${NC}"
    # fi
    
    echo
    echo "======================================================================================"
    echo "  TESTING INDIVIDUAL QUERIES"
    echo "======================================================================================"
    echo
    
    # Define all queries to test along with descriptions
    declare -A queries=(
        # Core Build Information Metrics
        ["jenkins_pipeline_started_total"]="Raw Pipeline Start Data"
        ["sum(jenkins_pipeline_started_total)"]="Total Pipeline Starts"
        ["sum(jenkins_pipeline_started_total) by (job)"]="Pipeline Starts by Job"
        ["jenkins_pipeline_completed_total"]="Raw Pipeline Completion Data"
        ["sum(jenkins_pipeline_completed_total)"]="Total Pipeline Completions"
        ["jenkins_pipeline_duration_milliseconds"]="Pipeline Duration Trend"
        
        # Additional information using available labels
        ["sum(jenkins_pipeline_started_total) by (branch)"]="Pipeline Starts by Branch"
        ["sum(jenkins_pipeline_started_total) by (build)"]="Pipeline Starts by Build Number"
        ["sum(jenkins_pipeline_started_total) by (project)"]="Pipeline Starts by Project"
        
        # System Metrics that might be available
        ["process_cpu_seconds_total"]="CPU Usage Total"
        ["process_resident_memory_bytes"]="Memory Usage"
        ["prometheus_target_interval_length_seconds"]="Scrape Intervals"
        
        # Pushgateway metrics (if available)
        ["push_time_seconds"]="Pushgateway Push Times"
        ["push_failure_time_seconds"]="Pushgateway Failure Times"
        
        # Try finding any metrics with jenkins in the name
        ["count({__name__=~\".*jenkins.*\"})"]="Count of Jenkins-related Metrics"
        ["count({__name__=~\".*pipeline.*\"})"]="Count of Pipeline-related Metrics"
        
        # Try auto-discovered metrics (available in Prometheus)
        ["up"]="Service Up Status"
        ["scrape_duration_seconds"]="Scrape Duration"
        ["scrape_samples_scraped"]="Samples Scraped"
    )
    
    # Test each query
    for query in "${!queries[@]}"; do
        description="${queries[$query]}"
        echo "-------------------------------------------------------------------------------------"
        ((total_count++))
        
        query_prometheus "$query" "$description"
        result=$?
        
        if [ $result -eq 0 ]; then
            ((success_count++))
        elif [ $result -eq 2 ]; then
            ((empty_count++))
        else
            ((error_count++))
        fi
        
        echo
    done
    
    # Display summary
    echo "======================================================================================"
    echo "  QUERY TESTING SUMMARY"
    echo "======================================================================================"
    echo
    echo -e "Total queries tested: ${total_count}"
    echo -e "${GREEN}Successful queries with data: ${success_count}${NC}"
    echo -e "${YELLOW}Successful queries without data: ${empty_count}${NC}"
    echo -e "${RED}Failed queries: ${error_count}${NC}"
    echo
    
    if [ $success_count -eq 0 ]; then
        echo -e "${RED}Warning: No queries returned data. Please ensure:${NC}"
        echo "1. Jenkins pipeline has run with metrics enabled"
        echo "2. Push Gateway is properly configured"
        echo "3. Prometheus is scraping the Push Gateway"
        echo "4. The metrics naming matches your configuration"
    elif [ $success_count -lt $((total_count / 2)) ]; then
        echo -e "${YELLOW}Partial success: Some queries returned data, but many didn't.${NC}"
        echo "Consider running more pipelines to generate additional metrics data."
    else
        echo -e "${GREEN}Success: Most queries returned valid data!${NC}"
        echo "Your metrics collection system is working properly."
    fi
    
    echo
    echo "You can now proceed to creating dashboards with these queries."
}

# Check if Prometheus is accessible
echo "Checking Prometheus server connection at ${PROMETHEUS_URL}..."
# Try to access the Prometheus API endpoint that should always exist
if curl -s "${PROMETHEUS_URL}/api/v1/status/buildinfo" | grep -q "version"; then
    echo -e "${GREEN}Prometheus server is accessible!${NC}"
    echo
    run_all_tests
else
    echo -e "${RED}Error: Cannot connect to Prometheus at ${PROMETHEUS_URL}${NC}"
    echo "Please check the URL and ensure Prometheus is running."
    exit 1
fi