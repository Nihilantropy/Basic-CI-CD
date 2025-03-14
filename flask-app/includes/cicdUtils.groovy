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

// Helper function to execute a stage with proper error handling
def runStage(String stageName, String notificationMessage, Closure stageBody) {

    updateGitLabStatus(stageName, 'running')
    try {
        notify("Jenkins: ${notificationMessage}")
        stageBody()
        updateGitLabStatus(stageName, 'success')
        notify("Jenkins: ${stageName} completed successfully ✅")
    } catch (Exception e) {
        updateGitLabStatus(stageName, 'failed')
        def errorLog = e.getMessage()
        notify("Jenkins: ${stageName} failed ❌\n")
        error "${stageName} failed. Pipeline interrupted."
    }
}

def updateVersionInfo() {
    echo "Updating version info and committing changes..."
    
    def timestamp = env.TIMESTAMP
    def gitBranch = env.GIT_BRANCH

    // Add and commit version-related changes - no sensitive data here, can use string interpolation
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
    // Create tag - no sensitive data here
    sh """
        # Create tag with proper syntax
        git tag -a ${timestamp} -m "Release ${timestamp}"
    """
    
    // For GitLab, use oauth2 as the username with the token
    withCredentials([string(credentialsId: 'gitlab-personal-access-token', variable: 'GITLAB_TOKEN')]) {
        sh """
            git push http://oauth2:\${GITLAB_TOKEN}@gitlab/pipeline-project-group/pipeline-project.git refs/tags/${timestamp}
        """
    }
    
    echo "Release tag ${timestamp} created and pushed"
}

// Helper function to create a merge request
def createMergeRequest(String gitLabHost, String projectPath, String sourceBranch, String targetBranch, String title, String description) {
    echo "Creating merge request from ${sourceBranch} to ${targetBranch}..."
    
    // GitLab's API requires URL-encoded values
    def encodedTitle = URLEncoder.encode(title, "UTF-8")
    def encodedDescription = URLEncoder.encode(description, "UTF-8")
    
    // Use withCredentials to securely access the token
    withCredentials([string(credentialsId: 'gitlab-personal-access-token', variable: 'GITLAB_TOKEN')]) {
        // Using curl with single quotes to prevent token exposure in logs
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