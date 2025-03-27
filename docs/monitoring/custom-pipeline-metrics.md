# Jenkins Pipeline Custom Metrics Document

## Core Build Information Metrics

1. **Pipeline Start**
   - **Metric Name**: `jenkins_pipeline_started_total`
   - **Type**: Counter
   - **Labels**: 
     - `job`: Jenkins job name
     - `build`: Build number
     - `branch`: Git branch
     - `project`: Project name
   - **Description**: Incremented when a pipeline starts
   - **Query**: `jenkins_pipeline_started_total{job="appflask-pipeline"}`

2. **Pipeline Completion**
   - **Metric Name**: `jenkins_pipeline_completed_total`
   - **Type**: Counter
   - **Labels**: 
     - `job`: Jenkins job name
     - `build`: Build number
     - `branch`: Git branch
     - `project`: Project name
     - `result`: Build result (success, failure, aborted)
   - **Description**: Incremented when a pipeline completes
   - **Query**: `sum by (result) (jenkins_pipeline_completed_total{job="appflask-pipeline"})`

3. **Pipeline Duration**
   - **Metric Name**: `jenkins_pipeline_duration_milliseconds`
   - **Type**: Gauge
   - **Labels**: 
     - `job`: Jenkins job name
     - `build`: Build number
     - `branch`: Git branch
     - `project`: Project name
   - **Description**: Total duration of the pipeline in milliseconds
   - **Query**: `jenkins_pipeline_duration_milliseconds{job="appflask-pipeline"}`

## Stage-Specific Metrics

4. **Stage Start**
   - **Metric Name**: `jenkins_pipeline_stage_started_total`
   - **Type**: Counter
   - **Labels**: 
     - `job`: Jenkins job name
     - `build`: Build number
     - `stage`: Stage name
     - `branch`: Git branch
   - **Description**: Incremented when a pipeline stage starts
   - **Query**: `jenkins_pipeline_stage_started_total{job="appflask-pipeline"}`

5. **Stage Completion**
   - **Metric Name**: `jenkins_pipeline_stage_completed_total`
   - **Type**: Counter
   - **Labels**: 
     - `job`: Jenkins job name
     - `build`: Build number
     - `stage`: Stage name
     - `branch`: Git branch
     - `result`: Stage result (success, failure)
   - **Description**: Incremented when a pipeline stage completes
   - **Query**: `sum by (stage, result) (jenkins_pipeline_stage_completed_total{job="appflask-pipeline"})`

6. **Stage Duration**
   - **Metric Name**: `jenkins_pipeline_stage_duration_milliseconds`
   - **Type**: Gauge
   - **Labels**: 
     - `job`: Jenkins job name
     - `build`: Build number
     - `stage`: Stage name
     - `branch`: Git branch
   - **Description**: Duration of each stage in milliseconds
   - **Query**: `jenkins_pipeline_stage_duration_milliseconds{job="appflask-pipeline"}`
   - **Query for Average Duration by Stage**: `avg by (stage) (jenkins_pipeline_stage_duration_milliseconds{job="appflask-pipeline"})`

## Code Quality Metrics

7. **Ruff Issue Count**
   - **Metric Name**: `jenkins_pipeline_ruff_issues_total`
   - **Type**: Gauge
   - **Labels**: 
     - `job`: Jenkins job name
     - `build`: Build number
     - `severity`: Issue severity (error, warning)
     - `branch`: Git branch
   - **Description**: Number of issues found by Ruff
   - **Query**: `jenkins_pipeline_ruff_issues_total{job="appflask-pipeline"}`

8. **Bandit Vulnerability Count**
   - **Metric Name**: `jenkins_pipeline_bandit_vulnerabilities_total`
   - **Type**: Gauge
   - **Labels**: 
     - `job`: Jenkins job name
     - `build`: Build number
     - `severity`: Vulnerability severity (high, medium, low)
     - `branch`: Git branch
   - **Description**: Number of vulnerabilities found by Bandit
   - **Query**: `jenkins_pipeline_bandit_vulnerabilities_total{job="appflask-pipeline", severity="high"}`

## Test Metrics

9. **Test Results**
   - **Metric Name**: `jenkins_pipeline_test_results_total`
   - **Type**: Gauge
   - **Labels**: 
     - `job`: Jenkins job name
     - `build`: Build number
     - `branch`: Git branch
     - `result`: Test result (passed, failed, skipped)
   - **Description**: Number of tests by result
   - **Query**: `jenkins_pipeline_test_results_total{job="appflask-pipeline", result="passed"}`

10. **Test Duration**
    - **Metric Name**: `jenkins_pipeline_test_duration_milliseconds`
    - **Type**: Gauge
    - **Labels**: 
      - `job`: Jenkins job name
      - `build`: Build number
      - `branch`: Git branch
    - **Description**: Duration of the test stage in milliseconds
    - **Query**: `jenkins_pipeline_test_duration_milliseconds{job="appflask-pipeline"}`

## Artifact Metrics

11. **Artifact Size**
    - **Metric Name**: `jenkins_pipeline_artifact_size_bytes`
    - **Type**: Gauge
    - **Labels**: 
      - `job`: Jenkins job name
      - `build`: Build number
      - `artifact_id`: Artifact identifier
      - `branch`: Git branch
    - **Description**: Size of build artifacts in bytes
    - **Query**: `jenkins_pipeline_artifact_size_bytes{job="appflask-pipeline", artifact_id="appflask"}`

12. **Nexus Upload Status**
    - **Metric Name**: `jenkins_pipeline_nexus_upload_status`
    - **Type**: Gauge
    - **Labels**: 
      - `job`: Jenkins job name
      - `build`: Build number
      - `artifact_id`: Artifact identifier
      - `version`: Artifact version
      - `branch`: Git branch
      - `status`: Upload status (1=success, 0=failure)
    - **Description**: Status of Nexus artifact uploads
    - **Query**: `jenkins_pipeline_nexus_upload_status{job="appflask-pipeline", status="1"}`

## Pipeline Performance Metrics

13. **Queue Time**
    - **Metric Name**: `jenkins_pipeline_queue_time_milliseconds`
    - **Type**: Gauge
    - **Labels**: 
      - `job`: Jenkins job name
      - `build`: Build number
      - `branch`: Git branch
    - **Description**: Time spent in queue before pipeline execution
    - **Query**: `jenkins_pipeline_queue_time_milliseconds{job="appflask-pipeline"}`

14. **Resource Utilization**
    - **Metric Name**: `jenkins_pipeline_resource_utilization`
    - **Type**: Gauge
    - **Labels**: 
      - `job`: Jenkins job name
      - `build`: Build number
      - `resource`: Resource type (cpu, memory)
      - `branch`: Git branch
    - **Description**: Resource utilization during pipeline execution
    - **Query for CPU**: `jenkins_pipeline_resource_utilization{job="appflask-pipeline", resource="cpu"}`
    - **Query for Memory**: `jenkins_pipeline_resource_utilization{job="appflask-pipeline", resource="memory"}`

## Jenkins System Metrics

15. **Pipeline Frequency**
    - **Metric Name**: `jenkins_pipeline_execution_frequency`
    - **Type**: Counter
    - **Labels**: 
      - `job`: Jenkins job name
      - `branch`: Git branch
      - `project`: Project name
      - `trigger`: Trigger type (scheduled, manual, webhook)
    - **Description**: Count of pipeline executions by trigger type
    - **Query**: `rate(jenkins_pipeline_execution_frequency{job="appflask-pipeline"}[24h])`

16. **Executor Utilization**
    - **Metric Name**: `jenkins_executor_utilization_percent`
    - **Type**: Gauge
    - **Labels**: 
      - `job`: Jenkins job name
      - `executor`: Executor name
    - **Description**: Executor utilization percentage
    - **Query**: `jenkins_executor_utilization_percent * 100`

These metrics will provide comprehensive visibility into the Jenkins pipeline performance and health, allowing for effective monitoring and optimization of the CI/CD process.

---

# Jenkins Pipeline Dashboard Pseudo-Code

## Dashboard Overview
- **Title**: "Jenkins Pipeline Performance Dashboard"
- **Description**: "Comprehensive view of CI/CD pipeline performance, stage metrics, and system health"
- **Time Range**: Default to last 24 hours, with quick selectors for 6h, 12h, 3d, 7d
- **Auto-refresh**: Every 1 minute
- **Variables**:
  - `job`: Multi-select dropdown of all Jenkins jobs
  - `branch`: Multi-select dropdown of git branches

## Layout Structure
- **Top Row**: KPI Stats and System Health (Height: 4)
- **Middle Row**: Pipeline Performance (Height: 8)
- **Bottom Section**: Stage Performance (Height: 10)

## Panel Definitions

### Row 1: KPI Stats and System Health (4 panels in 1 row)

#### Panel 1: Total Pipeline Executions
- **Type**: Stat panel
- **Title**: "Total Pipeline Executions"
- **Description**: "Total number of pipeline executions"
- **Query**: `sum(jenkins_pipeline_started_total)`
- **Size**: Width 6, Height 4
- **Format**: Number (no units)
- **Thresholds**: None (informational only)
- **Visualization**: Number with sparkline showing trend

#### Panel 2: Success Rate by Stage
- **Type**: Gauge panel
- **Title**: "Stage Success Rate"
- **Description**: "Percentage of stages that complete successfully"
- **Query**: `count(jenkins_pipeline_stage_completed_total{result="success"}) / count(jenkins_pipeline_stage_completed_total) * 100`
- **Size**: Width 6, Height 4
- **Format**: Percentage
- **Thresholds**: 
  - 0-50%: Red
  - 50-80%: Yellow
  - 80-100%: Green
- **Visualization**: Gauge with value text

#### Panel 3: Jenkins Service Health
- **Type**: Stat panel
- **Title**: "Jenkins Service Health"
- **Description**: "Up/Down status of Jenkins service"
- **Query**: `up{job="jenkins"}`
- **Size**: Width 6, Height 4
- **Format**: Boolean
- **Thresholds**: 
  - 0: Red ("Offline")
  - 1: Green ("Online")
- **Visualization**: Text and color background

#### Panel 4: Jenkins Resource Usage
- **Type**: Gauge panel
- **Title**: "Jenkins Memory Usage"
- **Description**: "Current memory usage of Jenkins server"
- **Query**: `process_resident_memory_bytes{job="jenkins"} / 1024 / 1024 / 1024`
- **Size**: Width 6, Height 4
- **Format**: Gigabytes
- **Thresholds**: 
  - 0-2 GB: Green
  - 2-3 GB: Yellow
  - >3 GB: Red
- **Visualization**: Gauge

### Row 2: Pipeline Performance (2 panels in 1 row)

#### Panel 5: Pipeline Executions Over Time
- **Type**: Time series
- **Title**: "Pipeline Executions Over Time"
- **Description**: "Number of pipeline executions over time"
- **Query**: `sum(increase(jenkins_pipeline_started_total[$__interval])) by (job)`
- **Size**: Width 12, Height 8
- **Format**: Number
- **Visualization**: Line graph
- **Legend**: Bottom, showing job names
- **Stack**: False
- **Fill opacity**: 4

#### Panel 6: Pipeline Executions by Branch
- **Type**: Bar chart
- **Title**: "Pipeline Executions by Branch"
- **Description**: "Distribution of pipeline executions across branches"
- **Query**: `sum(jenkins_pipeline_started_total) by (branch)`
- **Size**: Width 12, Height 8
- **Format**: Number
- **Sort**: Descending
- **Visualization**: Horizontal bars
- **Legend**: Right
- **Color Mode**: By value (gradient)

### Row 3: Stage Performance (3 panels in 1 row)

#### Panel 7: Average Stage Duration by Stage
- **Type**: Bar chart
- **Title**: "Average Stage Duration by Stage"
- **Description**: "Average duration of each pipeline stage in milliseconds"
- **Query**: `avg(jenkins_pipeline_stage_duration_milliseconds) by (stage)`
- **Size**: Width 8, Height 10
- **Format**: Milliseconds
- **Visualization**: Horizontal bar chart
- **Sort**: By duration (descending)
- **Legend**: None
- **Color Mode**: By value (gradient blue)
- **Thresholds**: None

#### Panel 8: Stage Duration Timeline
- **Type**: Time series
- **Title**: "Stage Duration Timeline"
- **Description**: "Duration of each stage over time"
- **Query**: `jenkins_pipeline_stage_duration_milliseconds`
- **Size**: Width 8, Height 10
- **Format**: Milliseconds
- **Visualization**: Line graph
- **Legend**: Bottom, showing stage names
- **Stack**: False
- **Fill opacity**: 2

#### Panel 9: Stage Completion Status
- **Type**: Pie chart
- **Title**: "Stage Completion Status"
- **Description**: "Distribution of stage results (success/failure)"
- **Query**: `count(jenkins_pipeline_stage_completed_total) by (result)`
- **Size**: Width 8, Height 10
- **Visualization**: Pie chart
- **Legend**: Right
- **Color Mode**: By value
  - success: Green
  - failure: Red
  - others: Yellow

## Annotations

- **Jenkins Builds**: 
  - **Name**: "Jenkins Builds"
  - **Data source**: Prometheus
  - **Query**: `changes(jenkins_pipeline_started_total[1m]) > 0`
  - **Text**: "Job: {{job}}, Branch: {{branch}}"
  - **Enabled**: True

## Dashboard Settings

- **Timezone**: Default to browser timezone
- **Editable**: True
- **Tags**: ["jenkins", "pipeline", "ci-cd"]
- **Time Picker**: Visible
- **Variables Editor**: Hidden
- **Graph Tooltip**: Shared crosshair
- **Row Collapsible**: True

This pseudo-code structure provides a comprehensive blueprint for a Grafana dashboard that focuses on the Jenkins pipeline metrics we confirmed are available in your Prometheus instance. The layout is designed to provide clear visibility into pipeline execution, stage performance, and system health while maintaining an organized and intuitive interface.