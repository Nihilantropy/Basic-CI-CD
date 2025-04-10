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

/**
 * Prepares version.info file update without committing
 * @return True if successful, false otherwise
 */
def prepareVersionInfo() {
    echo "Preparing version.info update to ${env.TIMESTAMP}..."
    
    try {
        // Update the version.info file
        writeFile file: 'version.info', text: env.TIMESTAMP
        
        // Stage the file
        sh "git add version.info"
        echo "Successfully prepared version.info update"
        return true
    } catch (Exception e) {
        echo "Error preparing version.info: ${e.message}"
        return false
    }
}

/**
 * Prepares Helm Chart.yaml appVersion update without committing
 * @return True if successful, false otherwise
 */
def prepareHelmChartVersion() {
    echo "Preparing Helm chart appVersion update to ${env.TIMESTAMP}..."
    
    def chartFile = "helm/appflask/Chart.yaml"
    
    // Check if the Chart.yaml file exists
    if (!fileExists(chartFile)) {
        echo "Warning: ${chartFile} not found! Skipping helm chart update."
        return false
    }
    
    try {
        // Read the current Chart.yaml content
        def chartYaml = readFile(chartFile)
        
        // Update the appVersion field, preserving the format and other content
        def updatedChartYaml
        if (chartYaml.contains("appVersion:")) {
            // Replace existing appVersion line
            updatedChartYaml = chartYaml.replaceAll(/appVersion:.*/, "appVersion: \"${env.TIMESTAMP}\"")
        } else {
            // If appVersion doesn't exist, add it at the end
            updatedChartYaml = chartYaml.trim() + "\n\n# Updated by Jenkins pipeline\nappVersion: \"${env.TIMESTAMP}\"\n"
        }
        
        // Write the updated content back to the file
        writeFile file: chartFile, text: updatedChartYaml
        
        // Stage the changes
        sh "git add ${chartFile}"
        
        echo "Successfully prepared Helm chart appVersion update"
        return true
    } catch (Exception e) {
        echo "Error preparing Helm chart version: ${e.message}"
        return false
    }
}

/**
 * Commits all staged changes and pushes to the repository
 * @param commitMessage The commit message
 * @return True if successful, false otherwise
 */
def commitAndPushChanges(String commitMessage) {
    echo "Committing and pushing changes: ${commitMessage}"
    
    try {
        // Check if there are any staged changes
        def hasChanges = sh(script: "git diff --staged --quiet || echo 'changes'", returnStdout: true).trim()
        
        if (hasChanges == 'changes') {
            // Commit the changes with the provided message
            sh """
                git commit -m "${commitMessage} [ci skip]"
            """
            
            // Push the changes
            withCredentials([string(credentialsId: 'gitlab-personal-access-token', variable: 'GITLAB_TOKEN')]) {
                sh """
                    git push http://oauth2:\${GITLAB_TOKEN}@gitlab/pipeline-project-group/pipeline-project.git HEAD:${env.GIT_BRANCH.replaceAll('^origin/', '')}
                """
            }
            
            echo "Successfully committed and pushed changes"
            return true
        } else {
            echo "No changes to commit"
            return false
        }
    } catch (Exception e) {
        echo "Error committing and pushing changes: ${e.message}"
        return false
    }
}

def createReleaseTag() {
    echo "Creating and pushing release tags..."
    
    def timestamp = env.TIMESTAMP
    sh """
        # Create timestamp tag with proper syntax
        git tag -a ${timestamp} -m "Release ${timestamp}"
        
        # Create or update 'latest' tag to point to the same commit
        git tag -f latest -m "Latest release (${timestamp})"
    """
    
    withCredentials([string(credentialsId: 'gitlab-personal-access-token', variable: 'GITLAB_TOKEN')]) {
        sh """
            # Push the timestamp tag
            git push http://oauth2:\${GITLAB_TOKEN}@gitlab/pipeline-project-group/pipeline-project.git refs/tags/${timestamp}
            
            # Force push the latest tag (since we're updating it)
            git push -f http://oauth2:\${GITLAB_TOKEN}@gitlab/pipeline-project-group/pipeline-project.git refs/tags/latest
        """
    }
    
    echo "Release tags ${timestamp} and 'latest' created and pushed"
}

def updateArgoCDBranch(String argoCDBranch, String version) {
    // Store current state to return to later
    def currentBranch = env.GIT_BRANCH.replaceAll('^origin/', '')
    def originalCommit = sh(script: "git rev-parse HEAD", returnStdout: true).trim()
    
    echo "Updating ArgoCD branch '${argoCDBranch}' with version ${version} from ${currentBranch}..."
    
    // Verify argocd-apps directory exists
    if (!fileExists('argocd-apps/')) {
        error "argocd-apps directory not found in the current branch"
    }
    
    // Set up Git identity
    sh "git config user.name 'Jenkins Pipeline'"
    sh "git config user.email 'jenkins@example.com'"
    
    withCredentials([string(credentialsId: 'gitlab-personal-access-token', variable: 'GITLAB_TOKEN')]) {
        def gitlabUrl = "http://oauth2:\${GITLAB_TOKEN}@gitlab/pipeline-project-group/pipeline-project.git"
        
        try {
            // Step 1: Delete remote branch if it exists
            echo "Deleting remote branch ${argoCDBranch} if it exists..."
            sh """
                git push ${gitlabUrl} --delete ${argoCDBranch} || true
            """
            
            // Step 2: Create a new branch
            echo "Creating new branch ${argoCDBranch}..."
            sh "git checkout -b ${argoCDBranch}"
            
            // Step 3: Remove everything except argocd-apps directory and .git
            echo "Isolating argocd-apps directory..."
            sh """
                # Find and remove all files/dirs except argocd-apps/ and .git/
                find . -mindepth 1 -maxdepth 1 -not -name '.git' -not -name 'argocd-apps' -exec rm -rf {} \\;
                
                # Update version in Helm charts
                if [ -f argocd-apps/helm/appflask/Chart.yaml ]; then
                    # Update appVersion in Chart.yaml
                    sed -i 's/appVersion: .*/appVersion: "${version}"/g' argocd-apps/helm/appflask/Chart.yaml
                    
                    # Create or update version.info file
                    echo "${version}" > argocd-apps/helm/appflask/version.info
                fi
                
                # Add a simple README
                echo "# ArgoCD Application Definitions\\n\\nThis branch contains the ArgoCD App of Apps structure for deployment via ArgoCD.\\n\\nLast updated: \$(date)\\nVersion: ${version}\\nSource: ${currentBranch}" > README.md
            """
            
            // Stage and commit the changes
            echo "Committing changes..."
            sh """
                git add -A
                git commit -m "Update ArgoCD application definitions to version ${version} from ${currentBranch}"
            """
            
            // Push the new branch
            echo "Pushing branch to remote repository..."
            sh """
                git push -f ${gitlabUrl} ${argoCDBranch}
            """
            
            echo "Successfully created fresh ${argoCDBranch} branch with latest ArgoCD application definitions"
            return true
            
        } catch (Exception e) {
            echo "Failed to update ArgoCD branch: ${e.message}"
            throw e
        } finally {
            // Return to original state
            sh "git checkout ${originalCommit}"
        }
    }
}

return this