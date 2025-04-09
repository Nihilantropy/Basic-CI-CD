# How to Use: CI/CD Pipeline with ArgoCD

This guide provides step-by-step instructions for setting up and using the CI/CD Pipeline with ArgoCD GitOps implementation. This guide focuses on the current project architecture which uses Terraform to provision a Kind Kubernetes cluster and ArgoCD for GitOps deployments.

## Prerequisites

- **Docker**: Version 20.10.x or newer
- **Docker Compose**: Version 2.x or newer
- **Git**: Version 2.x or newer
- **Terraform**: Version 1.0.0 or newer
- **kubectl**: Version 1.24+ or newer
- **jq**: For JSON processing in scripts (optional but recommended)
- **DNS entry** for `gitlab.local` pointing to localhost (add to `/etc/hosts`)

## 1. Base Environment Setup

### 1.1 Clone the Repository

```bash
git clone https://github.com/Nihilantropy/Basic-CI-CD.git
cd basic-ci-cd
```

### 1.2 Configure Host Entry

Add the following to your `/etc/hosts` file:
```
127.0.0.1 gitlab.local
```

This will resolve gitlab.local to the localhost ip address

### 1.3 Start Docker Compose Environment

Launch all required services using the provided Makefile:
```bash
make all
```

This starts:
- GitLab (http://gitlab.local:8080)
- Jenkins (http://localhost:8081)
- Nexus (http://localhost:8082)
- Sonarqube (http://localhost:9000)
- Prometheus, Grafana, and other monitoring components

Wait for all services to initialize (can take 3-5 minutes).

## 2. Service Configuration

### 2.1 GitLab Configuration

1. **Access GitLab**:
   - Open http://gitlab.local:8080
   - Login with username: `root` and the password from `make show` output or `docker logs gitlab | grep 'Password:'`

2. **Create Project Group and Repository**:
   - Create group: `pipeline-project-group`
   - Create project: `pipeline-project`

3. **Create Personal Access Token**:
   - Go to User Settings > Access Tokens
   - Create token with `api`, `read_repository`, `write_repository` scopes
   - Save the token securely - you'll need it for Jenkins and ArgoCD

4. **Configure Outbound Requests**:
   - Go to Admin Area > Settings > Network
   - Enable "Allow requests to the local network from webhooks and integrations"
   - Add local networks to the allowlist: `127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, jenkins`
  
5. **Clone the repository and configure**
   - clone the repository using `git clone http://gitlab.local/pipeline-project-group/pipeline-project.git`
   - go into the repo with `cd pipeline-project`
   - now we have to configure the git config to enable authenticated push and use the correct port using `nano .git/config`
   - replace the repo url with this one: url = http://root:<your-access-token>@gitlab.local:8080/pipeline-project-group/pipeline-project.git (replace <your-access-token> with YOUR access token)
   - try to create a file, commit and push to the repo for test
  
6. **Enable integration with Jenkins** (configure jenkins first)
   - Go to the pipeline-project settings
   - Go to Integrations and search Jenkins
   - Select Active, Push (trigger) and input `http://jenkins:8080` in the Jenkins server url section
   - Disable ssl verification
   - Input Jenkins username and password of the jenkins user

### 2.2 Jenkins Configuration

1. **Access Jenkins**:
   - Open http://localhost:8081
   - Get initial password: `docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword`
   - Complete the setup wizard and create admin user

2. **Configure GitLab Integration**:
   - Go to Manage Jenkins > Configure System
   - Add GitLab Server:
     - Name: `gitlab-local`
     - URL: `http://gitlab:80/`
     - Credentials: Add GitLab API token from previous step
     - Test connection

3. **Configure Nexus Credentials**:
   - Go to Manage Jenkins > Manage Credentials > Add Credentials
   - Kind: `Username with password`
   - ID: `bb41509b-d0cc-4f65-94a4-755c22441930`
   - Username: `admin`
   - Password: Nexus admin password (see next section)

4. **Configure Sonarqube Integration**:
   - Go to Manage Jenkins > Configure System > SonarQube servers
   - Add SonarQube:
     - Name: `SonarQube`
     - Server URL: `http://sonarqube:9000`
   - Add SonarQube Token credential (after Sonarqube setup)

5. **Create Pipeline Job**:
   - Name: `appflask-pipeline`
   - Type: Pipeline
   - Git lab connection: gitlab-local
   - Repository name: `pipeline-project-group/pipeline-project`
   - Build when a change is pushed to GitLab: enable, select push events trigger

### 2.3 Nexus Configuration

1. **Access Nexus**:
   - Open http://localhost:8082
   - Get initial password: `docker exec -it nexus cat /nexus-data/admin.password`
   - Complete setup and set new admin password

2. **Create Repository**:
   - Go to Server Administration > Repositories > Create repository
   - Choose recipe: `raw (hosted)`
   - Name: `my-artifacts`
   - Set Deployment policy: `Allow redeploy`
   - Save

### 2.4 Sonarqube Configuration

1. **Access Sonarqube**:
   - Open http://localhost:9000
   - Login with default credentials (admin/admin)
   - Create a new password

2. **Create Project**:
   - Create a new project manually
   - Project Key: `appflask`
   - Display name: `AppFlask`

3. **Generate Authentication Token**:
   - Go to My Account > Security > Generate Token
   - Save the token for Jenkins configuration

4. **Configure Quality Gate**:
   - Go to Quality Gates
   - Create or modify the default quality gate

## 3. Kubernetes Setup with Terraform

### 3.1 Update Terraform Variables

Edit `terraform/environments/local/terraform.tfvars`:
```bash
# Set your host machine's actual IP address
host_machine_ip = "192.168.1.x"  # Change this to your IP
```

### 3.2 Deploy Kind Cluster

```bash
cd terraform
./scripts/deploy.sh local
```

This script:
1. Initializes Terraform
2. Creates a Kind Kubernetes cluster
3. Configures Kubernetes resources for Nexus integration
4. Installs and configures ArgoCD

After deployment, you can check the status of your resources:

```bash
# Change workspace
cd environments/local

# use the local kube-config
export KUBECONFIG=\terra-home/.kube/config-tf-local # Important to use the kind cluster in your shell session

# View the local cluster
kubectl get nodes

# Check Flux installation
kubectl get pods -n flux-system

# Verify Nexus connection
kubectl get service,endpoints -n nexus

kubectl get all -A
```

### 3.3 Access ArgoCD

```bash
# Get the node IP (usually your host IP)
NODE_IP=$(hostname -I | awk '{print $1}')

# ArgoCD UI URL
echo "ArgoCD UI: http://$NODE_IP:30888"

# Get ArgoCD initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Access the ArgoCD UI with:
- Username: `admin`
- Password: from the command above

## 4. Application Deployment

### 4.1 Push Application Code to GitLab

1. **Clone the GitLab Repository**:
   ```bash
   git clone http://gitlab.local:8080/pipeline-project-group/pipeline-project.git
   cd pipeline-project
   ```

2. **Add Application Files**:
   ```bash
   # Copy application files from your dev environment
   cp -r /path/to/basic-ci-cd/appflask/* .
   git add .
   git commit -m "Initial application commit"
   git push origin main
   ```

### 4.2 Trigger CI/CD Pipeline

1. **Manual Trigger**:
   - Go to Jenkins > appflask-pipeline > Build Now

2. **Automatic Trigger**:
   - Push changes to the repository
   - Configure webhook in GitLab if not already set

### 4.3 Monitor Pipeline Progress

1. **Jenkins UI**:
   - View build progress and logs in Jenkins
   - Check console output for detailed information

2. **Pipeline Parameters**:
   The pipeline only supports configuring:
   - `ENABLE_GITLAB_STATUS`: Enable/disable GitLab commit status updates
   - `ENABLE_TELEGRAM`: Enable/disable Telegram notifications
   - `ENABLE_METRICS`: Enable/disable Prometheus metrics collection

### 4.4 Verify ArgoCD Deployment

1. **Check Applications**:
   - In ArgoCD UI, view the App of Apps application
   - Verify child applications (dev and prod) are created

2. **Sync Status**:
   - Applications should automatically sync
   - Check sync status and health in the UI

3. **View Application Details**:
   - Click on an application to see its resources
   - View Kubernetes resources and their status

### 4.5 Test Application Endpoints

```bash
# Dev environment
curl http://$NODE_IP:30080/
curl http://$NODE_IP:30080/health
curl http://$NODE_IP:30080/metrics

# Prod environment
curl http://$NODE_IP:30180/
curl http://$NODE_IP:30180/health
curl http://$NODE_IP:30180/metrics
```

## 5. Ongoing Development Workflow

1. **Make Code Changes**:
   ```bash
   # Make changes to the application code
   git add .
   git commit -m "Update application"
   git push origin main
   ```

2. **CI/CD Process**:
   - Jenkins pipeline triggers automatically
   - Code is tested, analyzed, built, and packaged
   - Binary is uploaded to Nexus
   - ArgoCD branch is updated
   - ArgoCD detects changes and syncs applications

3. **ArgoCD Sync Policy**:
   - ArgoCD automatically syncs applications when changes are detected
   - Applications self-heal if cluster state diverges from Git definition

## 6. Monitoring

### 6.1 Prometheus and Grafana

1. **Access Prometheus**:
   - Open http://localhost:9090
   - Check targets at http://localhost:9090/targets

2. **Access Grafana**:
   - Open http://localhost:3000
   - Login with admin/admin
   - View dashboards for:
     - Flask Application Metrics
     - Jenkins Pipeline Performance
     - Container Monitoring

### 6.2 Test Metrics Collection

Use the provided test scripts:
```bash
# Test rate limiting and metrics
bash appflask/test_scripts/comprehensive-rate-test.sh

# Test Prometheus queries
bash appflask/test_scripts/test_query.sh

# Test alerting
bash appflask/test_scripts/alert-testing-script.sh
```

## 7. Troubleshooting

### 7.1 Pipeline Issues

1. **Sonarqube Analysis Fails**:
   - Verify Sonarqube token in Jenkins credentials
   - Check Sonarqube is running and accessible from Jenkins

2. **Nexus Upload Fails**:
   - Verify Nexus credentials in Jenkins
   - Check Nexus repository exists and is accessible

3. **ArgoCD Branch Update Fails**:
   - Check GitLab credentials and permissions
   - Verify branch exists or can be created

### 7.2 ArgoCD Issues

1. **Application Out of Sync**:
   - Check ArgoCD logs: `kubectl logs -n argocd deploy/argocd-application-controller`
   - Manually sync the application in the UI
   - Verify Git repository is accessible

2. **Application Health Issues**:
   - View application resources in ArgoCD UI
   - Check pod logs: `kubectl logs -n <namespace> <pod-name>`

### 7.3 Terraform/Kind Cluster Issues

1. **Terraform Apply Fails**:
   - Check host_machine_ip is set correctly
   - Ensure Docker has sufficient resources
   - Look for specific error messages

2. **Cluster Not Accessible**:
   - Verify kubeconfig: `terraform output kubeconfig_path`
   - Export KUBECONFIG: `export KUBECONFIG=$(terraform output -raw kubeconfig_path)`

## 8. Cleanup

### 8.1 Terraform Cleanup

```bash
cd terraform
./scripts/cleanup.sh local
```

### 8.2 Docker Compose Cleanup

```bash
make down   # Stop containers
make prune  # Remove containers, volumes, and images
```

## 9. Key Paths and URLs

### 9.1 Services

- GitLab: http://gitlab.local:8080
- Jenkins: http://localhost:8081
- Nexus: http://localhost:8082
- Sonarqube: http://localhost:9000
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000
- ArgoCD: http://<NODE_IP>:30888

### 9.2 Application Endpoints

- Dev environment: http://<NODE_IP>:30080
- Prod environment: http://<NODE_IP>:30180
