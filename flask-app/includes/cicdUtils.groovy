#!/usr/bin/env groovy

// Helper function to update GitLab status
def updateGitLabStatus(String name, String state, Boolean enableUpdates) {
    if (enableUpdates) {
        updateGitlabCommitStatus name: name, state: state
    } else {
        echo "GitLab status updates disabled. Would have set ${name} to ${state}."
    }
}

// Helper function to send notifications
def notify(String message, Boolean enableTelegram) {
    echo message
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
def runStage(String stageName, String notificationMessage, Boolean enableGitLabStatus, Boolean enableTelegram, Closure stageBody) {
    updateGitLabStatus(stageName, 'running', enableGitLabStatus)
    try {
        notify("Jenkins: ${notificationMessage}", enableTelegram)
        stageBody()
        updateGitLabStatus(stageName, 'success', enableGitLabStatus)
        notify("Jenkins: ${stageName} completed successfully ✅", enableTelegram)
    } catch (Exception e) {
        updateGitLabStatus(stageName, 'failed', enableGitLabStatus)
        def errorLog = e.getMessage()
        notify("Jenkins: ${stageName} failed ❌\n", enableTelegram)
        error "${stageName} failed. Pipeline interrupted."
    }
}

// Helper function to update version info and commit changes
def updateVersionInfo(String gitRepoUrl, String timestamp, String gitBranch) {
    echo "Updating version info and committing changes..."
    
    // Add, commit, and push version-related changes to current branch
    sh "git add version.info"
    sh "git commit -m 'Update version to ${timestamp} [ci skip]'"
    sh "git push ${gitRepoUrl} HEAD:refs/heads/${gitBranch}"
    
    echo "Version info updated on branch ${gitBranch}"
}

// Helper function to create and push tag
def createReleaseTag(String gitRepoUrl, String timestamp) {
    echo "Creating and pushing release tag..."
    
    sh """
        # Create tag with proper syntax
        git tag -a ${timestamp} -m "Release ${timestamp}"
        
        # Push the tag
        git push ${gitRepoUrl} refs/tags/${timestamp}
        
        echo "Release tag ${timestamp} created and pushed"
    """
}

return this