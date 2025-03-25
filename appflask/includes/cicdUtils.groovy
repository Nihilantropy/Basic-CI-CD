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
    env.METRICS_BUILD_START_TIME = System.currentTimeMillis()
    
    // Record some metadata about the build
    env.METRICS_BUILD_ID = "${env.JOB_NAME.replaceAll('[^a-zA-Z0-9_]', '_')}_${env.BUILD_NUMBER}"
    
    // Track stages and their timings - use empty JSON array
    env.METRICS_STAGES = "[]" 
    
    echo "Metrics initialized for build: ${env.METRICS_BUILD_ID}"
    
    // Record build start in Prometheus format
    prometheusMetric("jenkins_pipeline_started_total", "counter", 1, ["job": env.JOB_NAME, "build": env.BUILD_NUMBER])
}

// Helper function to output metric in Prometheus format
def prometheusMetric(String name, String type, def value, Map<String,String> labels = [:]) {
    def enableMetrics = env.DO_ENABLE_METRICS?.toBoolean() ?: false
    
    if (!enableMetrics) {
        return
    }
    
    def labelStr = labels.collect { k, v -> 
        "${k}=\"${v.toString().replace('\\', '\\\\').replace('"', '\\"')}\""
    }.join(',')
    
    echo "PROMETHEUS_METRIC ${name}{${labelStr}} ${value.toString()}"
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
    
    // Record build result metrics
    prometheusMetric(
        "jenkins_pipeline_completed_total", 
        "counter", 
        1, 
        ["job": env.JOB_NAME, "build": env.BUILD_NUMBER, "result": result]
    )
    
    // Record build duration
    prometheusMetric(
        "jenkins_pipeline_duration_milliseconds", 
        "gauge", 
        buildDuration, 
        ["job": env.JOB_NAME, "build": env.BUILD_NUMBER]
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
                    ["job": env.JOB_NAME, "build": env.BUILD_NUMBER, "stage": stage.name]
                )
            }
        }
    } catch (Exception e) {
        echo "Error summarizing stage metrics: ${e.getMessage()}"
    }
    
    echo "Build metrics finalized for: ${env.METRICS_BUILD_ID}"
}

// Enhanced runStage function with built-in metrics collection
def runStage(String stageName, String notificationMessage, Closure stageBody) {
    def enableMetrics = env.DO_ENABLE_METRICS?.toBoolean() ?: false
    def stageStartTime = 0
    
    // Conditionally record stage start
    if (enableMetrics) {
        stageStartTime = System.currentTimeMillis()
        prometheusMetric(
            "jenkins_pipeline_stage_started_total", 
            "counter", 
            1, 
            ["job": env.JOB_NAME, "build": env.BUILD_NUMBER, "stage": stageName]
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

// Helper function to record stage completion
def recordStageCompletion(String stageName, long duration, boolean success) {
    def enableMetrics = env.DO_ENABLE_METRICS?.toBoolean() ?: false
    
    if (!enableMetrics) {
        return
    }
    
    // Record stage completion metrics
    prometheusMetric(
        "jenkins_pipeline_stage_completed_total", 
        "counter", 
        1, 
        [
            "job": env.JOB_NAME, 
            "build": env.BUILD_NUMBER, 
            "stage": stageName, 
            "result": success ? "success" : "failure"
        ]
    )
    
    // Record stage duration
    prometheusMetric(
        "jenkins_pipeline_stage_duration_milliseconds", 
        "gauge", 
        duration, 
        ["job": env.JOB_NAME, "build": env.BUILD_NUMBER, "stage": stageName]
    )
    
    // Store stage metrics in our stages array
    try {
        def stages = readJSON text: env.METRICS_STAGES
        stages.add([
            name: stageName,
            duration: duration,
            success: success
        ])
        env.METRICS_STAGES = writeJSON(json: stages, returnText: true)
    } catch (Exception e) {
        echo "Error recording stage metrics: ${e.getMessage()}"
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