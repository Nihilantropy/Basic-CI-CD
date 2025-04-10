# How to Use: CI/CD Pipeline with ArgoCD

This guide provides step-by-step instructions for setting up and using the CI/CD Pipeline with ArgoCD GitOps implementation.

## Prerequisites

<<<<<<< HEAD
- Docker v20.10.x+
- Docker Compose v2.x+
- Git v2.x+
- Terraform v1.0.0+
- kubectl v1.24+
- jq (optional, for JSON processing)
=======
- **Docker**: Version 20.10.x or newer
- **Docker Compose**: Version 2.x or newer
- **Git**: Version 2.x or newer
- **Terraform**: Version 1.0.0 or newer
- **kubectl**: Version 1.24+ or newer
- **jq**: For JSON processing in scripts (optional but recommended)
- **DNS entry** for `gitlab.local` pointing to localhost (add to `/etc/hosts`) // TODO remove
>>>>>>> 74173a43ba3c3077d2f6de5356910dcab1698d88

## 1. Base Environment Setup

### 1.1 Clone the Repository
```bash
git clone https://github.com/Nihilantropy/Basic-CI-CD.git
cd basic-ci-cd
```

### 1.2 Start Docker Compose Environment
```bash
make all
```

This starts:
- GitLab (http://localhost:8080)
- Jenkins (http://localhost:8081)
- Nexus (http://localhost:8082)
- Sonarqube (http://localhost:9000)
- Prometheus, Grafana, and other monitoring components

> **Note**: Allow 3-5 minutes for all services to initialize fully.

## 2. Service Configuration

### 2.1 GitLab Setup

<<<<<<< HEAD
1. **Access GitLab**
   - URL: http://localhost:8080
   - Email: `admin@example.com`
   - Password: `SuperSecurePassword123`
=======
1. **Access GitLab**:
   - Open http://localhost:8080
   - Login with username: `root` and the password from `make show` output or `docker logs gitlab | grep 'Password:'`
>>>>>>> 74173a43ba3c3077d2f6de5356910dcab1698d88

2. **Create Project Structure**
   - Create group: `pipeline-project-group`
   - Within that group, create project: `pipeline-project`

3. **Create Access Token**
   - Navigate to User Settings > Access Tokens
   - Create token with scopes: `api`, `read_repository`, `write_repository`
   - Save this token securely for later use

4. **Configure Network Settings**
   - Go to Admin Area > Settings > Network
   - Check "Allow requests to the local network from webhooks and integrations"
   - Add to allowlist: `127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, jenkins`

5. **Configure Local Repository**
   ```bash
   # Clone the repository
   git clone http://localhost:8080/pipeline-project-group/pipeline-project.git
   cd pipeline-project
   
   # Edit Git config to use authentication
   nano .git/config
   # Replace URL with: http://root:<your-access-token>@localhost:8080/pipeline-project-group/pipeline-project.git
   
   # Test with a sample commit
   touch test.txt
   git add test.txt
   git commit -m "Test commit"
   git push
   ```

6. **Connect to Jenkins** (complete after Jenkins setup)
   - In the project, go to Settings > Integrations > Jenkins
   - Check "Active" and "Push events"
   - Jenkins server URL: `http://jenkins:8080`
   - Uncheck "Enable SSL verification"
   - Enter Jenkins credentials
   - Click "Test connection"

### 2.2 Jenkins Setup

1. **Access Jenkins**
   - URL: http://localhost:8081
   - Initial password: `docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword`
   - Complete the setup wizard

2. **Configure GitLab Integration**
   - Go to Manage Jenkins > Configure System
   - Under GitLab section, click "Add GitLab Server"
     - Name: `gitlab-local`
     - URL: `http://gitlab:80/`
     - Add credentials using the GitLab token from earlier
     - Test the connection

3. **Add Nexus Credentials**
   - Go to Manage Jenkins > Manage Credentials > (global) > Add Credentials
   - Select Kind: Username with password
   - ID: `nexus-credentials-id` (must match this exactly)
   - Username: `admin`
   - Password: Your Nexus admin password

4. **Set Up SonarQube Integration**
   - Go to Manage Jenkins > Configure System > SonarQube servers
   - Add a SonarQube server:
     - Name: `SonarQube`
     - Server URL: `http://sonarqube:9000`
   - Go to Credentials > Add > Jenkins
     - Kind: Secret text
     - ID: `sonar-jenkins-token`
     - Secret: Your SonarQube token (from 2.4)

5. **Create Pipeline Job**
   - New Item > Pipeline
   - Name: `appflask-pipeline`
   - Check "Build when a change is pushed to GitLab"
   - In Pipeline section:
     - Definition: Pipeline script from SCM
     - SCM: Git
     - Repository URL: `http://gitlab/pipeline-project-group/pipeline-project`
     - Add credentials (username: `root`, password: your GitLab token)
     - Branch specifier: `*/main`

I'll add a more concise section focusing specifically on these key plugins:

### 2.2.1 Install Required Jenkins Plugins

Before proceeding with Jenkins configuration, ensure the following essential plugins are installed:

1. **Access Plugin Manager**
   - Go to Manage Jenkins > Plugins > Available plugins

2. **Install Required Plugins**
   Search for and install these critical plugins:

   - **GitLab Integration**
     - `gitlab-plugin`: Provides integration with GitLab webhooks and API
   
   - **SonarQube Integration**
     - `sonarqube-scanner`: Enables SonarQube analysis from Jenkins
     - `quality-gates`: Allows Jenkins to check SonarQube quality gates
   
   - **Nexus Integration**
     - `nexus-artifact-uploader`: Allows uploading artifacts to Nexus repository

   - **Metrics Collection**
     - `prometheus`: Exposes Jenkins metrics for Prometheus (leave default configurations)

### 2.3 Nexus Setup

1. **Access Nexus**
   - URL: http://localhost:8082
   - Initial password: `docker exec -it nexus cat /nexus-data/admin.password`
   - Complete the setup wizard

2. **Create Repository**
   - Go to Server Administration > Repositories > Create repository
   - Recipe: `raw (hosted)`
   - Name: `my-artifacts`
   - Deployment policy: `Allow redeploy`
   - Click "Create repository"

### 2.4 SonarQube Setup

1. **Access SonarQube**
   - URL: http://localhost:9000
   - Default credentials: admin/admin
   - Set new password when prompted

2. **Create Project**
   - Go to Projects > Create Project > Manually
   - Project Key: `appflask`
   - Display name: `AppFlask`
   - Click "Set Up"

3. **Generate Authentication Token**
   - Go to your user account > My Account > Security
   - Generate a token with name "Jenkins"
   - Save this token for Jenkins configuration

4. **Configure Quality Gate**
   - Go to Quality Gates
   - Either use the default "Sonar way" or create a custom one
   - For custom projects, adjust conditions as needed for your code quality standards

I'll refactor this section to make it clearer, more organized, and add the TODO sections:

## 3. Kubernetes Setup with Terraform

### 3.1 Configure Terraform Environment

1. **Get your host machine's IP address**:
   ```bash
   hostname -I | awk '{print $1}'
   ```

2. **Update Terraform configuration**:
   ```bash
   # Edit the variables file
   nano terraform/environments/local/terraform.tfvars
   
   # Set your actual IP address (example below)
   host_machine_ip = "192.168.1.x"  # Replace with your IP from step 1
   ```

3. **Configure GitLab authentication for ArgoCD**:
   ```bash
   # Edit the main Terraform file
   nano terraform/main.tf
   
   # Find the argocd module section and update the token reference
   # Option 1: Use token path (more secure)
   argocd_gitlab_token = chomp(file("~/.tokens/gitlab/your-token-file"))
   
   # Option 2: Direct token (less secure, but simpler for testing)
   argocd_gitlab_token = "your-gitlab-personal-token"
   ```

   > **Note**: For production environments, always use secure methods like token files or environment variables instead of hardcoded tokens.

### 3.2 Deploy Kind Cluster

```bash
cd terraform
./scripts/deploy.sh local
```

This will:
- Initialize Terraform
- Create a Kind Kubernetes cluster
- Set up Nexus integration in Kubernetes
- Install and configure ArgoCD

### 3.3 Verify the Deployment

```bash
# Change to the environment directory
cd environments/local

# Configure kubectl to use the new cluster
export KUBECONFIG=$(pwd)/terra-home/.kube/config-tf-local

# Verify cluster nodes
kubectl get nodes

# Check ArgoCD installation
kubectl get pods -n argocd

# Verify Nexus connection
kubectl get service,endpoints -n nexus

# Get a complete overview
kubectl get all -A
```

### 3.4 Access ArgoCD Dashboard

1. **Get the ArgoCD UI URL**:
   ```bash
   echo "ArgoCD UI: http://localhost:30888"
   ```

2. **Retrieve the initial admin password**:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

3. **Access the dashboard**:
   - URL: http://localhost:30888
   - Username: `admin`
   - Password: Output from step 2

## 4. Application Deployment

### 4.1 Push Application Code to GitLab

1. **Clone your GitLab repository**:
   ```bash
   git clone http://localhost:8080/pipeline-project-group/pipeline-project.git
   cd pipeline-project
   ```

2. **Add the application code**:
   ```bash
   # Copy the application files
   cp -r /path/to/basic-ci-cd/appflask/* .
   
   # Commit and push
   git add .
   git commit -m "Initial application commit"
   git push origin main
   ```

### 4.2 Run the CI/CD Pipeline

#### Option 1: Manual Trigger
- Navigate to Jenkins > appflask-pipeline > Build Now

#### Option 2: Automatic Trigger
- Push changes to the repository to trigger the webhook
- Pipeline will start automatically if GitLab webhook is configured correctly

### 4.3 Monitor the Pipeline

1. **Jenkins Dashboard**:
   - View real-time pipeline stages and progress
   - Access console output for detailed logs

2. **Pipeline Configuration Options**:
   Three main parameters can be adjusted:
   - `ENABLE_GITLAB_STATUS`: Updates commit status in GitLab
   - `ENABLE_TELEGRAM`: Sends notifications via Telegram
   - `ENABLE_METRICS`: Collects Prometheus metrics

### 4.4 Verify ArgoCD Deployment

1. **Check Applications in ArgoCD**:
   - Open the ArgoCD UI (http://localhost:30888)
   - Look for the "App of Apps" application
   - Verify both Dev and Prod applications are created

2. **Sync Status and Health**:
   - Green status indicates successful sync
   - Blue sync icons show ongoing synchronization
   - Red indicates sync or health issues

3. **Explore Application Resources**:
   - Click on an application to see deployed Kubernetes resources
   - View resource details, logs, and events

### 4.5 Test Application Endpoints

Test both development and production environments:

```bash
# Development Environment (port 30080)
curl http://localhost:30080/
curl http://localhost:30080/health
curl http://localhost:30080/metrics

# Production Environment (port 30180)
curl http://localhost:30180/
curl http://localhost:30180/health
curl http://localhost:30180/metrics
```

## 5. Ongoing Development Workflow

### 5.1 Make Code Changes

```bash
# Navigate to your repository
cd pipeline-project

# Make and commit changes
# Edit files...
git add .
git commit -m "Update application code"
git push origin main
```

### 5.2 CI/CD Process Flow

The automated pipeline process:
1. **Build**: Jenkins detects changes and triggers the pipeline
2. **Test & Analyze**: Code is tested and analyzed for quality and security
3. **Package**: Application is built and packaged with PyInstaller
4. **Store**: Binary is uploaded to Nexus with version tracking
5. **Deploy**: ArgoCD branch is updated with new version information
6. **Sync**: ArgoCD detects changes and updates the deployment

### 5.3 GitOps with ArgoCD

ArgoCD continuously monitors your Git repository:
- **Automated Sync**: Changes are automatically applied to the cluster
- **Self-Healing**: Divergence from Git state is automatically corrected
- **Resource Tracking**: All Kubernetes resources are tracked and visualized

## 6. Monitoring

### 6.1 Accessing Monitoring Tools

1. **Prometheus** (http://localhost:9090):
   - Query metrics using PromQL
   - Check target status at http://localhost:9090/targets
   - View alerts and rules

2. **Grafana** (http://localhost:3000):
   - Login: admin/admin
   - Pre-configured dashboards:
     - Flask Application Metrics: Application performance and rate limits
     - Jenkins Pipeline Performance: Build statistics and durations
     - Container Monitoring: System resource usage

### 6.2 Testing Metrics Collection

Run the provided test scripts to validate monitoring:

```bash
# Test rate limiting with metrics validation
bash appflask/test_scripts/comprehensive-rate-test.sh

# Validate Prometheus queries
bash appflask/test_scripts/test_query.sh

# Test alerting functionality
bash appflask/test_scripts/alert-testing-script.sh
```

## 7. Troubleshooting

### 7.1 Pipeline Issues

1. **SonarQube Analysis Failures**:
   - Verify SonarQube token in Jenkins credentials
   - Check SonarQube service is running: `docker ps | grep sonarqube`
   - Test connectivity: `curl http://sonarqube:9000/api/system/status`

2. **Nexus Upload Failures**:
   - Confirm Nexus credentials in Jenkins
   - Verify repository exists: http://localhost:8082/#browse/browse:my-artifacts
   - Check network connectivity between Jenkins and Nexus

3. **ArgoCD Branch Update Failures**:
   - Verify GitLab token permissions include repo write access
   - Check for SSH key issues if using SSH for Git
   - Review Jenkins logs for specific Git errors

### 7.2 ArgoCD Issues

1. **Application Out of Sync**:
   ```bash
   # Check ArgoCD application controller logs
   kubectl logs -n argocd deploy/argocd-application-controller
   
   # Check repository server logs
   kubectl logs -n argocd deploy/argocd-repo-server
   ```
   
   - Try manual sync in the UI
   - Verify Git repository is accessible from ArgoCD

2. **Application Health Problems**:
   ```bash
   # Check pod logs in the application namespace
   kubectl logs -n appflask-dev <pod-name>
   
   # Describe resources for details
   kubectl describe deployment -n appflask-dev appflask
   ```

### 7.3 Terraform/Kind Cluster Issues

1. **Terraform Apply Failures**:
   - Ensure host_machine_ip is correct and reachable
   - Check Docker has enough resources (CPU/memory)
   - Review error logs: `terraform apply -debug`

2. **Cluster Access Problems**:
   ```bash
   # Get the correct kubeconfig path
   terraform output -raw kubeconfig_path
   
   # Export and test
   export KUBECONFIG=$(terraform output -raw kubeconfig_path)
   kubectl cluster-info
   ```

## 8. Cleanup

### 8.1 Terraform Cleanup

Remove the Kubernetes cluster and all related resources:

```bash
cd terraform
./scripts/cleanup.sh local
```

### 8.2 Docker Compose Cleanup

```bash
# Stop the containers
make down

# Remove containers, volumes, and images
make prune
```

> **Warning**: The `make prune` command will remove all containers, volumes, and images related to this project. This includes all your setups, configurations, and stored credentials. Only run this when you're ready to completely reset your environment.

## 9. Quick Reference

### 9.1 Service URLs

| Service    | URL                      |
|------------|--------------------------|
| GitLab     | http://localhost:8080    |
| Jenkins    | http://localhost:8081    |
| Nexus      | http://localhost:8082    |
| SonarQube  | http://localhost:9000    |
| Prometheus | http://localhost:9090    |
| Grafana    | http://localhost:3000    |
| ArgoCD     | http://localhost:30888   |

### 9.2 Application Endpoints

| Environment | Base URL               | Available Endpoints |
|-------------|------------------------|---------------------|
| Development | http://localhost:30080 | /, /health, /metrics |
| Production  | http://localhost:30180 | /, /health, /metrics |