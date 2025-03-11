### **1. Base Environment Setup**

**Objective**: Set up a Docker Compose environment with Jenkins, Nexus, and GitLab to automate the development and deployment process.

#### Steps:
1. **Define Infrastructure**: 
   - **Jenkins**: Used for building and deploying the Flask application.
   - **Nexus**: Stores the built binary files and artifacts (e.g., from PyInstaller).
   - **GitLab**: Hosts the repository and integrates with Jenkins to trigger builds.

2. **Docker Compose Setup**: 
   - Create a `docker-compose.yml` file to define the services:
     - **Jenkins**: For automation and pipeline.
     - **Nexus**: For artifact storage.
     - **GitLab**: To handle the version control and CI/CD webhook triggering.

3. **Define Networking**:
   - Ensure that the services can communicate with each other. Set internal network links so Jenkins can access GitLab and Nexus to trigger builds and store artifacts.

4. **Persistent Volumes**:
   - Set up Docker volumes for Jenkins, Nexus, and GitLab to store data persistently.

5. **Test the Setup**:
   - Ensure that all services (Jenkins, Nexus, and GitLab) are up and running via Docker Compose.
   - Verify connectivity between Jenkins and Nexus (to upload files) and GitLab (for triggering CI/CD).

6. **Documentation**:
   - Write the **README.md** explaining how to set up the Docker Compose environment, run the containers, and verify each service.
   - Include any specific configurations (e.g., ports, environment variables) in the documentation.

---

### **2. Python Application Development**

**Objective**: Develop a Flask application that provides two endpoints and containerize it.

#### Steps:
1. **Setup Python Environment**:
   - Create a virtual environment and install Flask as the primary dependency.
   
2. **Develop Flask App**:
   - **First Endpoint**: A basic route (`/`) that returns a string including the current time. Example: `"Hello, my name is Flask, the time is xx:yy"`.
   - **Health Check Endpoint**: A simple `/health` route that responds with a 200 OK status for health monitoring.

3. **GitLab Repository**:
   - Create a GitLab repository named **"app-flask"**.
   - Push the Flask app code and Dockerfile to the GitLab repository.
   - Ensure the repository structure is clear and organized (e.g., `app.py`, `requirements.txt`, `Dockerfile`).

4. **Documentation**:
   - Write **README.md** to explain:
     - Flask application structure.
     - How to run the app locally.
     - How to build the Docker container.
     - Link to the GitLab repository for developers.

---

### **3. Jenkins Pipeline Setup**

**Objective**: Automate the build process of the Flask app and upload the binary to Nexus using Jenkins.

#### Steps:
1. **Install Jenkins Plugins**:
   - Install necessary plugins in Jenkins:
     - GitLab Plugin (for integration with GitLab).
     - Docker Pipeline (for building Docker images).
     - Nexus Artifact Uploader (for pushing files to Nexus).

2. **Create Jenkins Pipeline**:
   - Define a **Jenkinsfile** to automate the following tasks:
     - Checkout the **app-flask** repository.
     - Build the Flask app with PyInstaller to generate a binary.
     - Upload the binary to Nexus (in a RAW repository).

3. **Use docker agent**
   - Define a Dockerfile at the repo root to:
     - use a custom docker container for each stage of the pipeline
     - ensure a secure and containerized environment
   
   Example Jenkinsfile:
   ```groovy
   pipeline {
       agent docker

       environment {
           NEXUS_URL = "http://nexus:8081/repository/raw-repository/"
           NEXUS_REPO = "raw-repository"
       }

       stages {
           stage('Checkout') {
               steps {
                   git 'https://gitlab.com/<your-repo>/app-flask.git'
               }
           }

           stage('Build with PyInstaller') {
               steps {
                   script {
                       sh 'pip install -r requirements.txt'
                       sh 'pyinstaller --onefile app.py'
                   }
               }
           }

           stage('Upload to Nexus') {
               steps {
                   script {
                       def file = findFiles(glob: 'dist/*')
                       sh """
                           curl -v -u <username>:<password> --upload-file ${file} ${NEXUS_URL}${file}
                       """
                   }
               }
           }
       }
   }
   ```

34. **Configure Webhook in GitLab**:
   - Set up a webhook in GitLab to trigger the Jenkins job whenever changes are pushed to the **app-flask** repository.

5. **Documentation**:
   - Document the Jenkins pipeline configuration and the steps required to trigger it manually or automatically through GitLab.
   - Include troubleshooting tips if the pipeline fails to trigger or upload the artifact.

---

### **4. Helm Chart for Kubernetes Deployment**

**Objective**: Create a Helm chart to deploy the Flask app to Kubernetes with configurable replicas and agent name, and implement a Liveness probe.

#### Steps:
1. **Create Helm Chart**:
   - Initialize a Helm chart (`helm create flask-app`).
   - Modify the chart's `values.yaml` to include configurable values for the number of replicas and agent name.

   Example `values.yaml`:
   ```yaml
   replicaCount: 2
   agentName: "Agent1"
   ```

2. **Modify Deployment Template**:
   - Update the `deployment.yaml` template to use the `replicaCount` and `agentName` values from `values.yaml`.
   - Implement a **Liveness Probe** that points to the `/health` endpoint for monitoring.
   
   Example deployment snippet:
   ```yaml
   spec:
     replicas: {{ .Values.replicaCount }}
     containers:
       - name: flask-app
         image: "nexus_host:8081/repository/raw-repository/app-flask:latest"
         livenessProbe:
           httpGet:
             path: /health
             port: 5000
   ```

3. **Download from Nexus**:
   - Ensure that the application will download the binary from Nexus before execution.

4. **Manually Deploy Helm Chart**:
   - Once the Helm chart is ready, deploy it manually using `helm install flask-app ./flask-app`.

5. **Verify Deployment**:
   - Check that the Flask app is running, scaled according to `replicaCount`, and that the Liveness probe is passing.

6. **Documentation**:
   - Write a comprehensive **README.md** for the Helm chart repository:
     - How to configure `values.yaml`.
     - Instructions to manually deploy the chart.
     - Troubleshooting steps for deployment and liveness probe configuration.

---

### **Kubernetes Setup**

**Objective**: Set up a local Kubernetes environment using K3s, Docker Desktop’s Kubernetes, or Minikube for testing the deployment.

#### Steps:
1. **Choose Kubernetes Setup**:
   - For development and testing, choose K3s, Minikube, or Docker Desktop’s integrated Kubernetes.
   
2. **Configure the Kubernetes Cluster**:
   - Install and configure the chosen Kubernetes setup.
   - Ensure `kubectl` is configured to interact with the local Kubernetes cluster.

3. **Deploy Helm Chart**:
   - Follow the Helm deployment steps from the previous section to deploy the application to Kubernetes.

4. **Test the Application**:
   - Verify that the Flask app is running as expected, with the correct number of replicas and the Liveness probe working.

---

### **Final Documentation**

1. **General Documentation**:
   - Create a **complete documentation** for the entire project, including setup, development, CI/CD pipeline, Kubernetes deployment, and troubleshooting.
   - Ensure that all steps are clearly explained with examples, commands, and configuration files.

2. **Repository-specific Documentation**:
   - For the **app-flask** repository: Include how to run, build, and test the Flask app.
   - For the **Helm chart repository**: Include how to deploy and configure the application in Kubernetes.

This workflow outlines the structure and implementation steps for each part of the project, ensuring that the process is clear, organized, and easily executable in a real-world scenario.