# How to Use: Basic CI/CD Pipeline

This guide provides step-by-step instructions for setting up and using the Basic CI/CD Pipeline project. By following these instructions, you'll be able to:

1. Set up the required infrastructure
2. Configure all components
3. Test the CI/CD pipeline
4. Deploy applications to Kubernetes
5. Troubleshoot common issues

## Table of Contents

- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
  - [Environment Setup](#environment-setup)
  - [Kubernetes Setup](#kubernetes-setup)
- [Service Configuration](#service-configuration)
  - [GitLab Configuration](#gitlab-configuration)
  - [Jenkins Configuration](#jenkins-configuration)
  - [Nexus Configuration](#nexus-configuration)
- [Pipeline Usage](#pipeline-usage)
  - [Creating and Pushing Code](#creating-and-pushing-code)
  - [Triggering the Pipeline](#triggering-the-pipeline)
  - [Monitoring the Pipeline](#monitoring-the-pipeline)
- [Application Deployment](#application-deployment)
  - [Helm Deployment](#helm-deployment)
  - [Verifying the Deployment](#verifying-the-deployment)
  - [Accessing the Application](#accessing-the-application)
  - [Version Management](#version-management)
- [Troubleshooting](#troubleshooting)
  - [Common Issues](#common-issues)
  - [Logs and Debugging](#logs-and-debugging)
- [Advanced Usage](#advanced-usage)
  - [Custom Pipeline Configuration](#custom-pipeline-configuration)
  - [Rate Limit Testing](#rate-limit-testing)
  - [Webhook Configuration](#webhook-configuration)
- [Cleanup](#cleanup)

## Prerequisites

Before starting, ensure you have the following prerequisites installed on your system:

### System Requirements

- **Operating System**: Linux (Ubuntu/Debian recommended), macOS, or Windows with WSL2
- **CPU**: 4+ cores recommended
- **RAM**: 8GB+ recommended (16GB for optimal performance)
- **Storage**: 20GB+ free space

### Required Software

| Software | Minimum Version | Installation Guide |
|----------|-----------------|-------------------|
| Git | 2.x | [git-scm.com](https://git-scm.com/downloads) |
| Docker | 20.10.x | [docs.docker.com](https://docs.docker.com/get-docker/) |
| Docker Compose | 2.x | [docs.docker.com](https://docs.docker.com/compose/install/) |
| kubectl | 1.24+ | [kubernetes.io](https://kubernetes.io/docs/tasks/tools/) |
| Helm | 3.x | [helm.sh](https://helm.sh/docs/intro/install/) |
| K3s, Minikube, or Docker Desktop K8s | Latest | [k3s.io](https://k3s.io/) |

### Network Requirements

- Port `8080` (GitLab)
- Port `8081` (Jenkins)
- Port `8082` (Nexus)
- Port `30080` (Application NodePort)
- DNS entry for `gitlab.local` pointing to localhost (add to `/etc/hosts`)

## Initial Setup

### Environment Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/basic-ci-cd.git
   cd basic-ci-cd
   ```

2. **Edit host configuration**:
   Add the following entry to your `/etc/hosts` file:
   ```
   127.0.0.1 gitlab.local
   ```

3. **Configure environment variables (optional)**:
   Create a `.env` file in the project root (copy from sample if available):
   ```bash
   cp .env.sample .env
   # Edit .env file with your specific settings
   ```

4. **Start the environment**:
   The project includes a Makefile to simplify setup:
   ```bash
   # Start all services
   make all
   
   # If you want to build images separately
   make images
   
   # If you want to start containers separately
   make up
   ```

5. **Verify services are running**:
   ```bash
   make show
   # or
   docker ps
   ```
   
   Check that the following containers are running:
   - gitlab
   - jenkins
   - jenkins-docker (Docker-in-Docker service)
   - nexus

6. **Wait for services to initialize**:
   - GitLab: ~3-5 minutes
   - Jenkins: ~1-2 minutes
   - Nexus: ~2-3 minutes
   
   You can check the logs to monitor initialization:
   ```bash
   docker logs -f gitlab
   docker logs -f jenkins
   docker logs -f nexus
   ```

### Kubernetes Setup

1. **Start your Kubernetes cluster**:
   
   If using K3s:
   ```bash
   curl -sfL https://get.k3s.io | sh -
   # Copy the kubeconfig to the default location
   mkdir -p ~/.kube
   sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
   sudo chown $(id -u):$(id -g) ~/.kube/config
   chmod 600 ~/.kube/config
   ```
   
   If using Minikube:
   ```bash
   minikube start --driver=docker
   ```
   
   If using Docker Desktop, enable Kubernetes in the settings.

2. **Verify Kubernetes connection**:
   ```bash
   kubectl get nodes
   ```

3. **Create Nexus namespace and service**:
   ```bash
   # Create namespace
   kubectl create namespace nexus
   
   # Find your host machine's IP address (not localhost or 127.0.0.1)
   # You need your actual network interface IP address
   ip addr show
   # Look for inet on your main interface (often eth0, en0, or wlan0)
   
   # Edit the Nexus headless endpoint file
   # Replace 192.168.1.27 with your host's IP address
   vi k3s/service/nexus-headless-endpoint.yaml
   
   # Apply the Kubernetes configurations
   kubectl apply -f k3s/service/nexus-headless-service.yaml
   kubectl apply -f k3s/service/nexus-headless-endpoint.yaml
   ```

4. **Verify the Nexus endpoint is configured correctly**:
   ```bash
   kubectl get endpoints -n nexus
   ```

## Service Configuration

### GitLab Configuration

1. **Access GitLab**:
   Open a browser and navigate to http://gitlab.local:8080

2. **Initial login**:
   - Username: `root`
   - Password: Find the initial password in the GitLab logs:
     ```bash
     docker logs gitlab | grep 'Password:'
     ```
   - Or use the password defined in `srcs/requirements/GitLab/.env` (default: `SuperSecurePassword123`)

3. **Change the root password** when prompted

4. **Create a group**:
   - Click on `Groups > Your Groups > New group`
   - Name: `pipeline-project-group`
   - Visibility: `Private`
   - Click `Create group`

5. **Create a project**:
   - Navigate to your new group
   - Click `New project > Create blank project`
   - Name: `pipeline-project`
   - Visibility: `Private`
   - Click `Create project`

6. **Create a personal access token**:
   - Go to your user avatar > `Preferences`
   - Select `Access Tokens` in the sidebar
   - Name: `jenkins-integration`
   - Scopes: Select `api`, `read_repository`, `write_repository`
   - Click `Create personal access token`
   - **Important**: Save the generated token somewhere safe

7. **Configure outbound request settings**:
   - Go to `Admin Area > Settings > Network`
   - Expand `Outbound requests`
   - Check `Allow requests to the local network from webhooks and integrations`
   - Add the following to the `Local IP addresses and domain names that hooks and services can connect to` section:
     ```
     127.0.0.0/8
     10.0.0.0/8
     172.16.0.0/12
     192.168.0.0/16
     jenkins
     ```
   - Save changes

### Jenkins Configuration

1. **Access Jenkins**:
   Open a browser and navigate to http://localhost:8081

2. **Initial login**:
   - Find the initial admin password:
     ```bash
     docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
     ```
   - Enter this password in the Jenkins web interface

3. **Install suggested plugins** when prompted

4. **Create first admin user** when prompted
   - Fill in username, password, and email details
   - Click `Save and Continue`

5. **Configure GitLab integration**:
   - Go to `Manage Jenkins > Configure System`
   - Scroll down to the `GitLab` section
   - Click `Add GitLab Server`
     - Name: `gitlab-local`
     - URL: `http://gitlab:80/`
     - Credentials: Click `Add > Jenkins`
       - Kind: `GitLab API token`
       - API token: Paste your GitLab personal access token
       - ID: `gitlab-personal-access-token`
       - Description: `GitLab API Token`
       - Click `Add`
     - Select the credentials you just added
     - Test the connection by clicking `Test Connection`
   - Click `Save`

6. **Configure Telegram notifications (optional)**:
   - Create a Telegram bot using BotFather and get the token
   - Find your chat ID by messaging @userinfobot
   - Go to `Manage Jenkins > Manage Credentials > Jenkins > Global credentials > Add Credentials`
     - Kind: `Secret text`
     - Secret: Your bot token
     - ID: `telegram-token`
     - Description: `Telegram Bot Token`
     - Click `OK`
   - Add another credential:
     - Kind: `Secret text`
     - Secret: Your chat ID
     - ID: `telegram-chat-id`
     - Description: `Telegram Chat ID`
     - Click `OK`

7. **Configure Nexus credentials**:
   - Go to `Manage Jenkins > Manage Credentials > Jenkins > Global credentials > Add Credentials`
     - Kind: `Username with password`
     - Username: `admin`
     - Password: (will be set up in Nexus section)
     - ID: `bb41509b-d0cc-4f65-94a4-755c22441930` (match the ID in Jenkinsfile)
     - Description: `Nexus Credentials`
     - Click `OK`

8. **Create pipeline job**:
   - Click `New Item`
   - Enter name: `appflask-pipeline`
   - Select `Pipeline`
   - Click `OK`
   - In the configuration page:
     - Check `This project is parameterized`
     - Add Boolean parameters as defined in the Jenkinsfile:
       - `RUN_TESTS` (default: true)
       - `RUN_RUFF_CHECK` (default: true)
       - `RUN_BANDIT_CHECK` (default: true)
       - `UPDATE_VERSION` (default: true)
       - `BUILD_EXECUTABLE` (default: true)
       - `ARCHIVE_EXECUTABLE` (default: true)
       - `UPLOAD_TO_NEXUS` (default: true)
       - `PUSH_GIT_CHANGES` (default: true)
       - `CREATE_MERGE_REQUEST` (default: false)
       - `ENABLE_GITLAB_STATUS` (default: true)
       - `ENABLE_TELEGRAM` (default: false)
     - In the `Pipeline` section:
       - Definition: `Pipeline script from SCM`
       - SCM: `Git`
       - Repository URL: `http://gitlab/pipeline-project-group/pipeline-project.git`
       - Credentials: Click `Add > Jenkins` and create credentials:
         - Kind: `Username with password`
         - Username: Your GitLab username
         - Password: Your GitLab password
         - ID: `gitlab-credentials`
         - Description: `GitLab Credentials`
       - Select the credentials you just added
       - Branch Specifier: `*/main`
       - Script Path: `Jenkinsfile`
     - Click `Save`

### Nexus Configuration

1. **Access Nexus**:
   Open a browser and navigate to http://localhost:8082

2. **Initial login**:
   - Username: `admin`
   - Password: Find the initial password:
     ```bash
     docker exec -it nexus cat /nexus-data/admin.password
     ```
   - Click `Sign in`

3. **Change the admin password** when prompted
   - Set a new password
   - **Important**: Remember this password for Jenkins credentials

4. **Enable anonymous access** (optional for easier testing):
   - Go to `Settings (gear icon) > Security > Anonymous`
   - Check `Allow anonymous users to access the server`
   - Click `Save`

5. **Create a repository for artifacts**:
   - Go to `Settings (gear icon) > Repository > Repositories`
   - Click `Create repository`
   - Select `raw (hosted)`
   - Name: `my-artifacts`
   - Deployment policy: `Allow redeploy`
   - Click `Create repository`

6. **Update Jenkins credentials**:
   - Go back to Jenkins
   - Navigate to `Manage Jenkins > Manage Credentials`
   - Update the Nexus credentials with the new admin password

## Pipeline Usage

### Creating and Pushing Code

1. **Clone the GitLab repository locally**:
   ```bash
   git clone http://gitlab.local:8080/pipeline-project-group/pipeline-project.git
   cd pipeline-project
   ```

2. **Add the Flask application files**:
   - Copy the Flask application folder structure to the repository:
     ```bash
     cp -r /path/to/basic-ci-cd/flask-app/* .
     ```

3. **Commit and push the code**:
   ```bash
   git add .
   git commit -m "Initial commit of Flask application"
   git push origin main
   ```

### Triggering the Pipeline

1. **Manual trigger**:
   - Go to Jenkins at http://localhost:8081
   - Navigate to your pipeline job
   - Click `Build with Parameters`
   - Select/deselect the parameters as needed
   - Click `Build`

2. **Set up GitLab integration for automatic triggers**:
   - In GitLab, go to your project
   - Navigate to `Settings > Integrations`
   - Find and click on `Jenkins CI` in the integrations list
   - Configure the Jenkins integration:
     - Jenkins server URL: `http://jenkins:8080/`
     - Project name: `appflask-pipeline`
     - Username: Your Jenkins username (if authentication is enabled)
     - Password: Your Jenkins password (if authentication is enabled)
   - Under triggers, select `Push events` and `Merge request events`
   - Click `Save changes`
   - Test the integration by clicking `Test > Push events`

### Monitoring the Pipeline

1. **View pipeline progress in Jenkins**:
   - Click on the running build in Jenkins
   - Select `Console Output` to see detailed logs
   - Or use Blue Ocean interface for a visual representation

2. **Check build status in GitLab**:
   - If GitLab integration is set up correctly, you'll see build status in:
     - GitLab commit history
     - GitLab merge requests (if applicable)

3. **Telegram notifications** (if configured):
   - You'll receive messages about pipeline events in your Telegram chat

## Application Deployment

### Helm Deployment

1. **Prepare the Helm chart**:
   - Make sure Helm chart files are present in the repository:
     ```bash
     ls -la helm/flask-app
     ```
   - Update `values.yaml` with your configuration if needed

2. **Deploy the application**:
   ```bash
   # Deploy with default values
   helm install appflask ./helm/flask-app
   
   # Or with custom values
   helm install appflask ./helm/flask-app --set replicaCount=3 --set agentName="MyAgent"
   
   # Or with a specific version (after pipeline has run)
   helm install appflask ./helm/flask-app --set appVersion=20240317123456
   ```

3. **Update an existing deployment**:
   ```bash
   helm upgrade appflask ./helm/flask-app --set replicaCount=3
   ```

### Verifying the Deployment

1. **Check the pods are running**:
   ```bash
   kubectl get pods -l app=appflask
   ```

2. **View pod details and logs**:
   ```bash
   kubectl describe pod <pod-name>
   kubectl logs <pod-name>
   ```

3. **Check the service is created**:
   ```bash
   kubectl get svc appflask-svc
   ```

### Accessing the Application

1. **Get the NodePort and IP**:
   ```bash
   # Get the NodePort
   kubectl get svc appflask-svc -o jsonpath='{.spec.ports[0].nodePort}'
   
   # Get a node IP address
   kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}'
   ```

2. **Access the application endpoints**:
   ```bash
   # Main endpoint
   curl http://<NODE_IP>:<NODE_PORT>/
   
   # Health endpoint
   curl http://<NODE_IP>:<NODE_PORT>/health
   ```

3. **Expected output**:
   - Main endpoint:
     ```json
     {
       "message": "Hello, my name is default Agent version 20240317123456 the time is 12:34"
     }
     ```
   - Health endpoint:
     ```json
     {
       "status": "healthy"
     }
     ```

### Version Management

1. **List available versions in Nexus**:
   - Open http://localhost:8082
   - Browse to `my-artifacts` repository
   - Navigate through the folder structure (WmcA/appflask/)

2. **Deploy a specific version**:
   ```bash
   helm upgrade appflask ./helm/flask-app --set appVersion=<version>
   ```

3. **Deploy the latest version**:
   ```bash
   helm upgrade appflask ./helm/flask-app --set appVersion=latest
   ```

## Troubleshooting

### Common Issues

1. **GitLab integration fails to trigger Jenkins**:
   - Verify Jenkins URL is accessible from GitLab container
   - Check GitLab outbound request settings (allow local network requests)
   - Verify the Jenkins project name matches exactly in the integration settings
   - Check Jenkins logs for authentication issues
   - Ensure the Jenkins GitLab Plugin is properly installed and configured

2. **Jenkins pipeline fails at Nexus upload stage**:
   - Verify Nexus credentials in Jenkins
   - Check Nexus repository exists and is configured correctly
   - Verify Nexus URL is accessible from Jenkins container

3. **Application pods stuck in pending or failing**:
   - Check Kubernetes events:
     ```bash
     kubectl get events --sort-by='.lastTimestamp'
     ```
   - Verify Nexus headless service and endpoint are configured correctly
   - Check pod logs for errors:
     ```bash
     kubectl logs <pod-name>
     ```

4. **Rate limiting issues**:
   - The application has a global rate limit of 100 requests per minute
   - If you hit this limit, you'll receive 429 responses
   - Wait 60 seconds for the limit to reset

### Logs and Debugging

1. **Container logs**:
   ```bash
   docker logs gitlab
   docker logs jenkins
   docker logs nexus
   ```

2. **Kubernetes pod logs**:
   ```bash
   kubectl logs <pod-name>
   ```

3. **Jenkins pipeline logs**:
   - View in Jenkins UI under the build's `Console Output`

4. **Nexus logs**:
   ```bash
   docker exec -it nexus cat /nexus-data/log/nexus.log
   ```

5. **Application debugging**:
   - Set `flaskEnv` to `development` in `values.yaml` for more verbose logs

## Advanced Usage

### Custom Pipeline Configuration

You can customize the pipeline behavior using the `jenkins-config.yml` file:

```yaml
# Jenkins Pipeline Configuration
runTests: true
runRuffCheck: true
runBanditCheck: true
updateVersion: true
buildExecutable: true
archiveExecutable: true
uploadToNexus: true
pushGitChanges: true
createMergeRequest: false
enableGitlabStatus: true
enableTelegram: false
```

Add this file to your repository and commit it to control pipeline behavior.

### Rate Limit Testing

Test the rate limiting functionality with a simple bash script:

```bash
#!/bin/bash
COUNT=0
LIMIT=110
URL="http://<NODE_IP>:<NODE_PORT>/"

echo "Sending $LIMIT requests to $URL"

for i in $(seq 1 $LIMIT); do
  RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null $URL)
  COUNT=$((COUNT + 1))
  echo "Request $COUNT: Status $RESPONSE"
  if [ "$RESPONSE" -eq 429 ]; then
    echo "Rate limit hit after $COUNT requests"
    break
  fi
done

echo "Test complete"
```

### Webhook Configuration

For more advanced webhook settings:

1. **Jenkins-GitLab Integration Settings**:
   - Go to your pipeline job
   - Click `Configure`
   - Under `Build Triggers`, select `Build when a change is pushed to GitLab`
   - Advanced settings allow you to control:
     - Push events
     - Merge request events
     - Branch filtering
     - Comment triggers
   - These settings need to align with the events you've enabled in the GitLab integration

2. **GitLab CI Skip**:
   - Add `[ci skip]` to commit messages to prevent pipeline triggering

## Cleanup

When you're done using the environment:

1. **Stop the containers**:
   ```bash
   make stop
   # or
   docker compose -f srcs/docker-compose.yaml stop
   ```

2. **Remove the containers**:
   ```bash
   make down
   # or
   docker compose -f srcs/docker-compose.yaml down
   ```

3. **Complete cleanup**:
   ```bash
   make prune
   # or
   docker compose -f srcs/docker-compose.yaml down -v
   docker rmi $(docker images -q 'my_*')
   ```

4. **Uninstall Kubernetes resources**:
   ```bash
   helm uninstall appflask
   kubectl delete namespace nexus
   ```

---

Congratulations! You have now set up and used a complete CI/CD pipeline with GitLab, Jenkins, Nexus, and Kubernetes. This pipeline automatically tests, builds, and delivers your application, with the ability to deploy specific versions to your Kubernetes cluster.