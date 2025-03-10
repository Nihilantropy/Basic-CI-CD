# CI/CD Pipeline Project

Welcome to the **CI/CD Pipeline Project**! This project demonstrates an end-to-end continuous integration and deployment workflow using industry-standard tools. The pipeline integrates a base environment setup with Jenkins, Nexus, and GitLab, a Python Flask application, a fully automated Jenkins pipeline, and a configurable Helm Chart for Kubernetes deployments.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Base Environment Setup](#base-environment-setup)
- [Python Application](#python-application)
- [Jenkins Pipeline](#jenkins-pipeline)
- [Helm Chart](#helm-chart)
- [Kubernetes Setup](#kubernetes-setup)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

---

## Project Overview

This project streamlines and automates the process of building, testing, packaging, and deploying a Python Flask application. By leveraging Docker Compose, Jenkins, Nexus, GitLab, and Kubernetes, the project offers a robust CI/CD solution that is both scalable and maintainable.

---

## Base Environment Setup

The foundation of the project is built using **Docker Compose**. The environment includes:

- **Jenkins:** Automates builds and pipelines (running on port `8081`).
- **Nexus:** Serves as the artifact repository for built binaries.
- **GitLab:** Hosts the source code and triggers the CI/CD pipeline (accessible at `http://gitlab.local:8080`).

**Setup Steps:**

1. **Clone the repository.**
2. **Launch the environment:**  
   ```bash
   docker-compose up -d
   ```
3. **Verify Services:**
   - Jenkins: [http://localhost:8081](http://localhost:8081)
   - GitLab: [http://gitlab.local:8080](http://gitlab.local:8080)
   - Nexus: (check your configured port)

---

## Python Application

The core application is a Flask-based service that exposes two endpoints:

- **Greeting Endpoint (`/`):**  
  Returns a JSON message:  
  > "Hello, my name is *...* the time is *xx:yy*"

- **Health Check Endpoint (`/health`):**  
  Provides a simple response with a `200 OK` status for monitoring purposes.

**Key Features:**

- **Containerization:**  
  The application is containerized using a `Dockerfile` and stored in the GitLab repository named **"app-flask"**.

- **Development:**  
  Written in Python, the app uses Flask to serve endpoints and dynamically generates responses based on environment variables.

---

## Jenkins Pipeline

The Jenkins Pipeline automates the following steps:

1. **Dependency Installation:**  
   Installs required Python packages along with PyInstaller.

2. **Testing:**  
   Executes a test suite (located in `test/test_app.py`) that validates the health-check endpoint.

3. **Building the Executable:**  
   Uses **PyInstaller** to convert the Python application into a standalone binary, outputting to the `dist` folder.

4. **Artifact Upload:**  
   Uploads the contents of the `dist` folder to a Nexus **RAW repository**.

5. **Trigger Mechanism:**  
   The pipeline is configured to run automatically when changes are pushed to the **"app-flask"** GitLab repository, and it can also be triggered manually through Jenkins.

**Sample Jenkinsfile:**

```groovy
pipeline {
    agent any

    stages {
        stage('Install Dependencies') {
            steps {
                echo "Installing Python packages and PyInstaller..."
                sh 'pip install -r requirements.txt'
                sh 'pip install pyinstaller'
            }
        }
        stage('Run Tests') {
            steps {
                echo "Running tests..."
                sh 'python test/test_app.py'
            }
        }
        stage('Build Executable') {
            steps {
                echo "Building executable using PyInstaller..."
                sh 'pyinstaller --onefile app.py'
            }
        }
        stage('Upload Artifacts') {
            steps {
                echo "Uploading build artifacts to Nexus..."
                // Customize this command to use your Nexus CLI or script
                sh './upload_to_nexus.sh'
            }
        }
    }
}
```

---

## Helm Chart

The Helm Chart is designed for manual deployments of the application on a Kubernetes cluster. It offers:

- **Configurable `values.yaml`:**
  - **`replicaCount`**: Define the number of deployment replicas.
  - **`agentName`**: Customizes the greeting message by replacing the *"..."* placeholder.

- **Liveness Probe:**  
  Configured to monitor the `/health` endpoint, ensuring the application is running as expected.

- **Deployment Process:**  
  On deployment, the application downloads the binary from Nexus and executes it.

**Deployment Command Example:**

```bash
helm install app-flask ./helm-chart -f values.yaml
```

---

## Kubernetes Setup

Deploy the application using your preferred Kubernetes environment:

- **K3s:** Lightweight production-grade Kubernetes.
- **Docker Desktop:** Integrated Kubernetes for local development.
- **Minikube:** A local Kubernetes cluster for testing.

**Steps to Deploy:**

1. **Setup your Kubernetes cluster** (K3s, Docker Desktop, or Minikube).
2. **Configure `kubectl`** to connect to your cluster.
3. **Deploy using Helm:**  
   ```bash
   helm install app-flask ./helm-chart -f values.yaml
   ```
4. **Monitor Deployment:**  
   Ensure that the liveness probe successfully checks the `/health` endpoint.

---

## Getting Started

1. **Clone the Repository:**
   ```bash
   git clone http://gitlab.local:8080/pipeline-project-group/app-flask.git
   cd app-flask
   ```

2. **Start Base Services:**
   ```bash
   docker-compose up -d
   ```

3. **Configure Jenkins:**
   - Create a pipeline job in Jenkins pointing to the GitLab repository.
   - Set up a GitLab webhook to trigger builds on push events.

4. **Deploy to Kubernetes:**
   - Update the `values.yaml` file as needed.
   - Deploy using the Helm chart:
     ```bash
     helm install app-flask ./helm-chart -f values.yaml
     ```

---

## Project Structure

```
.
├── Docs
│   └── Technologies
│       ├── GitLab
│       │   └── GitLab.md
│       ├── Jenkins
│       │   └── Jenkins.md
│       └── Nexus
│           └── Nexus.md
├── flask-app
│   ├── Dockerfile
│   ├── Jenkinsfile
│   ├── README.md
│   └── srcs
│       ├── __init__.py
│       ├── main
│       │   └── app.py
│       ├── requirements.txt
│       └── tests
│           ├── __init__.py
│           └── test_app.py
├── helm
│   ├── flask-app
│   │   ├── Chart.yaml
│   │   ├── templates
│   │   │   ├── configmap.yaml
│   │   │   ├── deployment.yaml
│   │   │   └── service.yaml
│   │   └── values.yaml
│   └── README.md
├── k3s
│   └── service
│       ├── nexus-headless-endpoint.yaml
│       └── nexus-headless-service.yaml
├── Makefile
├── Progress.md
├── README.md
├── srcs
│   ├── docker-compose.yaml
│   └── requirements
│       ├── GitLab
│       │   └── Dockerfile
│       ├── Jenkins
│       │   ├── conf
│       │   │   └── plugins.txt
│       │   └── Dockerfile
│       └── Nexus
│           └── Dockerfile
├── subject.txt
├── TODO
└── Workflow.md

21 directories, 30 files
```

---

## Contributing

Contributions are welcome! Please fork the repository, submit issues, and open pull requests. Ensure that your contributions adhere to the coding standards and include relevant tests.

---

## License

This project is licensed under the [MIT License](LICENSE).

---

Thank you for checking out the **CI/CD Pipeline Project**. If you have any questions or need further assistance, feel free to open an issue or contact the project maintainers.