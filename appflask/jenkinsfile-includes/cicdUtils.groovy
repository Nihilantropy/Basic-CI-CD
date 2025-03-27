#!/usr/bin/env groovy

// Helper function to update GitLab status
def updateGitLabStatus(String name, String state) {
    def enableUpdates = env.DO_ENABLE_GITLAB_STATUS?.toBoolean() ?: false

    if (enableUpdates) {
        updateGitlabCommitStatus name: name, state: state
    } else {
        echo "GitLab status updates disabled. Would have set ${name} to ${state}."
    }
}

// Helper function to send notifications
def notify(String message) {
    echo message

    def enableTelegram = env.DO_ENABLE_TELEGRAM?.toBoolean() ?: false

    if (enableTelegram) {
        sendTelegramMessage(message)
    } else {
        echo "Telegram notifications disabled. Would have sent: ${message}"
    }
}

// Send message to Telegram
def sendTelegramMessage(String message) {
    // URL encode the message
    def encodedMessage = URLEncoder.encode(message, "UTF-8")
    
    withCredentials([
        string(credentialsId: 'telegram-token', variable: 'TOKEN'),
        string(credentialsId: 'telegram-chat-id', variable: 'CHAT_ID')
    ]) {
        sh '''
            curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage \
            -d chat_id=${CHAT_ID} \
            -d text="''' + encodedMessage + '''"
        '''
    }
}

// Initialize metrics collection for the build
def initMetrics() {
    def enableMetrics = env.DO_ENABLE_METRICS?.toBoolean() ?: false
    
    if (!enableMetrics) {
        echo "Metrics collection disabled. Skipping metrics initialization."
        return
    }
    
    // Record build start time - used for duration calculation
    env.METRICS_BUILD_START_TIME = System.currentTimeMillis().toString()
    
    // Record some metadata about the build
    env.METRICS_BUILD_ID = "${env.JOB_NAME.replaceAll('[^a-zA-Z0-9_]', '_')}_${env.BUILD_NUMBER}"
    
    // Initialize empty stages array - simple string approach for safety
    env.METRICS_STAGES = "[]"
    
    echo "Metrics initialized for build: ${env.METRICS_BUILD_ID}"
    
    // Get git branch information if available
    def branch = env.GIT_BRANCH ?: "unknown"
    def project = env.JOB_NAME.split('/')[0] ?: "unknown"
    
    // Record build start in Prometheus format
    prometheusMetric(
        "jenkins_pipeline_started_total", 
        "counter", 
        1, 
        [
            "job": env.JOB_NAME, 
            "build": env.BUILD_NUMBER, 
            "branch": branch,
            "project": project
        ]
    )
    
    // Record queue time if available
    if (env.QUEUE_TIME) {
        prometheusMetric(
            "jenkins_pipeline_queue_time_milliseconds",
            "gauge",
            env.QUEUE_TIME as Integer,
            [
                "job": env.JOB_NAME, 
                "build": env.BUILD_NUMBER, 
                "branch": branch
            ]
        )
    }
    
    // Record pipeline execution frequency with trigger information
    def trigger = env.BUILD_CAUSE ?: "manual"
    prometheusMetric(
        "jenkins_pipeline_execution_frequency",
        "counter",
        1,
        [
            "job": env.JOB_NAME,
            "branch": branch,
            "project": project,
            "trigger": trigger
        ]
    )
}

// Helper function to record stage completion
def recordStageCompletion(String stageName, long duration, boolean success) {
    def enableMetrics = env.DO_ENABLE_METRICS?.toBoolean() ?: false
    
    if (!enableMetrics) {
        return
    }
    
    // Get git branch information if available
    def branch = env.GIT_BRANCH ?: "unknown"
    
    // Record stage completion metrics
    prometheusMetric(
        "jenkins_pipeline_stage_completed_total", 
        "counter", 
        1, 
        [
            "job": env.JOB_NAME, 
            "build": env.BUILD_NUMBER, 
            "stage": stageName, 
            "result": success ? "success" : "failure",
            "branch": branch
        ]
    )
    
    // Record stage duration
    prometheusMetric(
        "jenkins_pipeline_stage_duration_milliseconds", 
        "gauge", 
        duration, 
        [
            "job": env.JOB_NAME, 
            "build": env.BUILD_NUMBER, 
            "stage": stageName,
            "branch": branch
        ]
    )
    
    // Using a simpler approach for tracking stages that avoids complex JSON manipulation
    // This is safer in the Jenkins pipeline environment
    echo "Stage ${stageName} completed in ${duration}ms with result: ${success ? 'success' : 'failure'}"
}

// Helper function to output metric in Prometheus format and push to Pushgateway
def prometheusMetric(String name, String type, def value, Map<String,String> labels = [:]) {
    def enableMetrics = env.DO_ENABLE_METRICS?.toBoolean() ?: false
    
    if (!enableMetrics) {
        return
    }
    
    def labelStr = labels.collect { k, v -> 
        "${k}=\"${v.toString().replace('\\', '\\\\').replace('"', '\\"')}\""
    }.join(',')
    
    // Log the metric for console output
    echo "PROMETHEUS_METRIC ${name}{${labelStr}} ${value.toString()}"
    
    // Push to Pushgateway
    pushMetricToGateway(name, type, value, labels)
}

// Record test results metrics
def recordTestResults(int passed, int failed, int skipped) {
    def enableMetrics = env.DO_ENABLE_METRICS?.toBoolean() ?: false
    
    if (!enableMetrics) {
        return
    }
    
    // Get git branch information if available
    def branch = env.GIT_BRANCH ?: "unknown"
    
    // Record test results metrics
    prometheusMetric(
        "jenkins_pipeline_test_results_total",
        "gauge",
        passed,
        [
            "job": env.JOB_NAME,
            "build": env.BUILD_NUMBER,
            "branch": branch,
            "result": "passed"
        ]
    )
    
    prometheusMetric(
        "jenkins_pipeline_test_results_total",
        "gauge",
        failed,
        [
            "job": env.JOB_NAME,
            "build": env.BUILD_NUMBER,
            "branch": branch,
            "result": "failed"
        ]
    )
    
    prometheusMetric(
        "jenkins_pipeline_test_results_total",
        "gauge",
        skipped,
        [
            "job": env.JOB_NAME,
            "build": env.BUILD_NUMBER,
            "branch": branch,
            "result": "skipped"
        ]
    )
}

// Record test duration
def recordTestDuration(long duration) {
    def enableMetrics = env.DO_ENABLE_METRICS?.toBoolean() ?: false
    
    if (!enableMetrics) {
        return
    }
    
    // Get git branch information if available
    def branch = env.GIT_BRANCH ?: "unknown"
    
    // Record test duration metric
    prometheusMetric(
        "jenkins_pipeline_test_duration_milliseconds",
        "gauge",
        duration,
        [
            "job": env.JOB_NAME,
            "build": env.BUILD_NUMBER,
            "branch": branch
        ]
    )
}

// Record code quality metrics - Ruff issues
def recordRuffIssues(int errorCount, int warningCount) {
    def enableMetrics = env.DO_ENABLE_METRICS?.toBoolean() ?: false
    
    if (!enableMetrics) {
        return
    }
    
    // Get git branch information if available
    def branch = env.GIT_BRANCH ?: "unknown"
    
    // Record Ruff issue metrics
    prometheusMetric(
        "jenkins_pipeline_ruff_issues_total",
        "gauge",
        errorCount,
        [
            "job": env.JOB_NAME,
            "build": env.BUILD_NUMBER,
            "severity": "error",
            "branch": branch
        ]
    )
    
    prometheusMetric(
        "jenkins_pipeline_ruff_issues_total",
        "gauge",
        warningCount,
        [
            "job": env.JOB_NAME,
            "build": env.BUILD_NUMBER,
            "severity": "warning",
            "branch": branch
        ]
    )
}

// Record code security metrics - Bandit vulnerabilities
def recordBanditVulnerabilities(int highCount, int mediumCount, int lowCount) {
    def enableMetrics = env.DO_ENABLE_METRICS?.toBoolean() ?: false
    
    if (!enableMetrics) {
        return
    }
    
    // Get git branch information if available
    def branch = env.GIT_BRANCH ?: "unknown"
    
    // Record Bandit vulnerability metrics
    prometheusMetric(
        "jenkins_pipeline_bandit_vulnerabilities_total",
        "gauge",
        highCount,
        [
            "job": env.JOB_NAME,
            "build": env.BUILD_NUMBER,
            "severity": "high",
            "branch": branch
        ]
    )
    
    prometheusMetric(
        "jenkins_pipeline_bandit_vulnerabilities_total",
        "gauge",
        mediumCount,
        [
            "job": env.JOB_NAME,
            "build": env.BUILD_NUMBER,
            "severity": "medium",
            "branch": branch
        ]
    )
    
    prometheusMetric(
        "jenkins_pipeline_bandit_vulnerabilities_total",
        "gauge",
        lowCount,
        [
            "job": env.JOB_NAME,
            "build": env.BUILD_NUMBER,
            "severity": "low",
            "branch": branch
        ]
    )
}

// Record artifact metrics
def recordArtifactSize(String artifactId, long sizeBytes) {
    def enableMetrics = env.DO_ENABLE_METRICS?.toBoolean() ?: false
    
    if (!enableMetrics) {
        return
    }
    
    // Get git branch information if available
    def branch = env.GIT_BRANCH ?: "unknown"
    
    // Record artifact size metric
    prometheusMetric(
        "jenkins_pipeline_artifact_size_bytes",
        "gauge",
        sizeBytes,
        [
            "job": env.JOB_NAME,
            "build": env.BUILD_NUMBER,
            "artifact_id": artifactId,
            "branch": branch
        ]
    )
}

// Record Nexus upload status
def recordNexusUploadStatus(String artifactId, String version, boolean success) {
    def enableMetrics = env.DO_ENABLE_METRICS?.toBoolean() ?: false
    
    if (!enableMetrics) {
        return
    }
    
    // Get git branch information if available
    def branch = env.GIT_BRANCH ?: "unknown"
    
    // Record Nexus upload status metric
    prometheusMetric(
        "jenkins_pipeline_nexus_upload_status",
        "gauge",
        success ? 1 : 0,
        [
            "job": env.JOB_NAME,
            "build": env.BUILD_NUMBER,
            "artifact_id": artifactId,
            "version": version,
            "branch": branch,
            "status": success ? "1" : "0"
        ]
    )
}

// Record resource utilization
def recordResourceUtilization(String resourceType, double value) {
    def enableMetrics = env.DO_ENABLE_METRICS?.toBoolean() ?: false
    
    if (!enableMetrics) {
        return
    }
    
    // Get git branch information if available
    def branch = env.GIT_BRANCH ?: "unknown"
    
    // Record resource utilization metric
    prometheusMetric(
        "jenkins_pipeline_resource_utilization",
        "gauge",
        value,
        [
            "job": env.JOB_NAME,
            "build": env.BUILD_NUMBER,
            "resource": resourceType,
            "branch": branch
        ]
    )
}

// Record executor utilization
def recordExecutorUtilization(String executorName, double utilizationPercent) {
    def enableMetrics = env.DO_ENABLE_METRICS?.toBoolean() ?: false
    
    if (!enableMetrics) {
        return
    }
    
    // Record executor utilization metric
    prometheusMetric(
        "jenkins_executor_utilization_percent",
        "gauge",
        utilizationPercent,
        [
            "job": env.JOB_NAME,
            "executor": executorName
        ]
    )
}

// Finalize metrics collection at the end of the build
def finalizeMetrics(String result) {
    def enableMetrics = env.DO_ENABLE_METRICS?.toBoolean() ?: false
    
    if (!enableMetrics) {
        echo "Metrics collection disabled. Skipping metrics finalization."
        return
    }
    
    def buildEndTime = System.currentTimeMillis()
    def buildDuration = buildEndTime - (env.METRICS_BUILD_START_TIME as Long)
    
    // Get git branch information if available
    def branch = env.GIT_BRANCH ?: "unknown"
    def project = env.JOB_NAME.split('/')[0] ?: "unknown"
    
    // Record build result metrics
    prometheusMetric(
        "jenkins_pipeline_completed_total", 
        "counter", 
        1, 
        [
            "job": env.JOB_NAME, 
            "build": env.BUILD_NUMBER, 
            "result": result,
            "branch": branch,
            "project": project
        ]
    )
    
    // Record build duration
    prometheusMetric(
        "jenkins_pipeline_duration_milliseconds", 
        "gauge", 
        buildDuration, 
        [
            "job": env.JOB_NAME, 
            "build": env.BUILD_NUMBER,
            "branch": branch,
            "project": project
        ]
    )
    
    // Log stages summary if any were recorded
    try {
        def stages = readJSON text: env.METRICS_STAGES
        if (stages.size() > 0) {
            echo "Stage performance summary:"
            stages.each { stage ->
                echo "- ${stage.name}: ${stage.duration}ms"
                
                // Record individual stage metrics
                prometheusMetric(
                    "jenkins_pipeline_stage_duration_milliseconds", 
                    "gauge", 
                    stage.duration, 
                    [
                        "job": env.JOB_NAME, 
                        "build": env.BUILD_NUMBER, 
                        "stage": stage.name,
                        "branch": branch
                    ]
                )
            }
        }
    } catch (Exception e) {
        echo "Error summarizing stage metrics: ${e.getMessage()}"
    }
    
    echo "Build metrics finalized for: ${env.METRICS_BUILD_ID}"
}

// Send metric to Pushgateway
def pushMetricToGateway(String name, String type, def value, Map<String,String> labels = [:]) {
    def enableMetrics = env.DO_ENABLE_METRICS?.toBoolean() ?: false
    
    if (!enableMetrics) {
        return
    }
    
    // Create labels string for metric content
    def labelStr = labels.collect { k, v -> 
        "${k}=\"${v.toString().replace('\\', '\\\\').replace('"', '\\"')}\""
    }.join(',')
    
    // Log metric for debugging
    echo "Pushing metric: ${name}{${labelStr}} ${value.toString()}"
    
    // Create job name that's URL-safe
    def jobNameSafe = env.JOB_NAME.replaceAll('[^a-zA-Z0-9_]', '_')
    def buildNumber = env.BUILD_NUMBER
    
    // Prepare metric in Prometheus text format
    def metricData = ""
    
    // Handle different metric types
    if (type == "counter") {
        metricData = """
# TYPE ${name} counter
${name}{${labelStr}} ${value.toString()}
"""
    } else if (type == "gauge") {
        metricData = """
# TYPE ${name} gauge
${name}{${labelStr}} ${value.toString()}
"""
    } else {
        echo "Unsupported metric type: ${type}"
        return
    }
    
    // Write metric to a temporary file
    def tempFile = "metric_${name}_${System.currentTimeMillis()}.txt"
    writeFile file: tempFile, text: metricData
    
    // Push to Pushgateway using curl with correct URL format
    sh """
        echo "Pushing to http://pushgateway:9091/metrics/job/${jobNameSafe}/instance/${buildNumber}"
        curl -s --data-binary @${tempFile} http://pushgateway:9091/metrics/job/${jobNameSafe}/instance/${buildNumber}
        rm ${tempFile}
    """
}

/* Main pipeline utility functions */

// Enhanced runStage function with built-in metrics collection
def runStage(String stageName, String notificationMessage, Closure stageBody) {
    def enableMetrics = env.DO_ENABLE_METRICS?.toBoolean() ?: false
    def stageStartTime = 0
    
    // Get git branch information if available
    def branch = env.GIT_BRANCH ?: "unknown"
    
    // Conditionally record stage start
    if (enableMetrics) {
        stageStartTime = System.currentTimeMillis()
        prometheusMetric(
            "jenkins_pipeline_stage_started_total", 
            "counter", 
            1, 
            [
                "job": env.JOB_NAME, 
                "build": env.BUILD_NUMBER, 
                "stage": stageName,
                "branch": branch
            ]
        )
    }
    
    // Update GitLab status
    updateGitLabStatus(stageName, 'running')
    
    try {
        // Send notification
        notify("Jenkins: ${notificationMessage}")
        
        // Execute the stage body
        stageBody()
        
        // Conditionally record stage success
        if (enableMetrics) {
            def stageDuration = System.currentTimeMillis() - stageStartTime
            recordStageCompletion(stageName, stageDuration, true)
        }
        
        // Update GitLab status
        updateGitLabStatus(stageName, 'success')
        
        // Send success notification
        notify("Jenkins: ${stageName} completed successfully ✅")
        
    } catch (Exception e) {
        // Conditionally record stage failure
        if (enableMetrics) {
            def stageDuration = System.currentTimeMillis() - stageStartTime
            recordStageCompletion(stageName, stageDuration, false)
        }
        
        // Update GitLab status for failure
        updateGitLabStatus(stageName, 'failed')
        
        // Format error message
        def errorLog = e.getMessage()
        notify("Jenkins: ${stageName} failed ❌\n${errorLog}")
        
        // Rethrow the exception to ensure the pipeline fails
        error "${stageName} failed. Pipeline interrupted."
    }
}

// Other utility functions from the original file...
def updateVersionInfo() {
    echo "Updating version info and committing changes..."
    
    def timestamp = env.TIMESTAMP
    def gitBranch = env.GIT_BRANCH

    // Add and commit version-related changes
    sh """
        git add version.info
        git commit -m "Update version to ${timestamp} [ci skip]"
    """
    
    withCredentials([string(credentialsId: 'gitlab-personal-access-token', variable: 'GITLAB_TOKEN')]) {
        sh """
            git push http://oauth2:\${GITLAB_TOKEN}@gitlab/pipeline-project-group/pipeline-project.git HEAD:refs/heads/${gitBranch}
        """
    }
    
    echo "Version info updated on branch ${gitBranch}"
}

def createReleaseTag() {
    echo "Creating and pushing release tag..."
    
    def timestamp = env.TIMESTAMP
    sh """
        # Create tag with proper syntax
        git tag -a ${timestamp} -m "Release ${timestamp}"
    """
    
    withCredentials([string(credentialsId: 'gitlab-personal-access-token', variable: 'GITLAB_TOKEN')]) {
        sh """
            git push http://oauth2:\${GITLAB_TOKEN}@gitlab/pipeline-project-group/pipeline-project.git refs/tags/${timestamp}
        """
    }
    
    echo "Release tag ${timestamp} created and pushed"
}

def createMergeRequest(String gitLabHost, String projectPath, String sourceBranch, String targetBranch, String title, String description) {
    echo "Creating merge request from ${sourceBranch} to ${targetBranch}..."
    
    // GitLab's API requires URL-encoded values
    def encodedTitle = URLEncoder.encode(title, "UTF-8")
    def encodedDescription = URLEncoder.encode(description, "UTF-8")
    
    withCredentials([string(credentialsId: 'gitlab-personal-access-token', variable: 'GITLAB_TOKEN')]) {
        def response = sh(script: '''
            curl -s -X POST \
            -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
            "http://''' + gitLabHost + '''/api/v4/projects/''' + URLEncoder.encode(projectPath, "UTF-8") + '''/merge_requests" \
            -d "source_branch=''' + sourceBranch + '''" \
            -d "target_branch=''' + targetBranch + '''" \
            -d "title=''' + encodedTitle + '''" \
            -d "description=''' + encodedDescription + '''" \
            -d "remove_source_branch=false"
        ''', returnStdout: true).trim()
        
        echo "Merge request creation completed"
        return response
    }
}

return this