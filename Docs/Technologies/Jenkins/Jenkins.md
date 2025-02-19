# Jenkins Documentation

## Introduction
Jenkins is an open-source automation server used for continuous integration and continuous delivery (CI/CD). It enables developers to automate the building, testing, and deployment of applications, making the software development process more efficient and reliable.

## Key Features
- **Open-Source**: Free and extensible with a vast plugin ecosystem.
- **Continuous Integration & Deployment**: Automates code integration, testing, and deployment.
- **Pipeline as Code**: Uses Jenkinsfile to define CI/CD pipelines.
- **Scalability**: Supports master-agent architecture for distributed builds.
- **Extensive Plugin Support**: Over 1,500 plugins for integration with various tools.
- **Cross-Platform**: Runs on Windows, macOS, and Linux.

## Installation

### Prerequisites
- **Java (JDK 11 or later)**
- **Docker (Optional, for containerized deployment)**
- **Git (For source control integration)**

### Installation on Linux (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install openjdk-11-jdk -y
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
echo "deb http://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list
sudo apt update
sudo apt install jenkins -y
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

### Installation on Docker
```bash
docker run -d --name jenkins -p 8080:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home jenkins/jenkins:lts
```

## Initial Setup
1. Access Jenkins via **http://localhost:8080**.
2. Retrieve the initial admin password:
   ```bash
   cat /var/jenkins_home/secrets/initialAdminPassword
   ```
3. Install suggested plugins.
4. Create an admin user.

## Jenkins Pipeline
Jenkins Pipelines define automated workflows using **Jenkinsfile**.

### Example Jenkinsfile
```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                echo 'Building...'
            }
        }
        stage('Test') {
            steps {
                echo 'Running tests...'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying...'
            }
        }
    }
}
```

## Plugin Management
### Installing Plugins
1. Go to **Manage Jenkins** > **Manage Plugins**.
2. Search for the required plugin.
3. Install and restart Jenkins.

### Recommended Plugins
- **Pipeline**: Enables declarative and scripted pipelines.
- **Git**: Integrates with Git repositories.
- **Docker**: Supports containerized builds.
- **Blue Ocean**: Enhances UI for pipelines.
- **Nexus Artifact Uploader**: Uploads artifacts to Nexus repositories.

## Jenkins Security & Authentication
### Enabling Security
1. Go to **Manage Jenkins** > **Configure Global Security**.
2. Enable **Jenkins’ Own User Database**.
3. Restrict anonymous access.
4. Configure **Role-Based Access Control (RBAC)**.

### Integrating with GitLab Authentication
- Install **GitLab Authentication Plugin**.
- Configure OAuth application in GitLab.
- Add GitLab credentials in Jenkins.

## Jenkins Distributed Builds
### Setting Up an Agent
1. Install Java on the agent machine.
2. Configure SSH access from the Jenkins master.
3. Add the agent node in **Manage Jenkins** > **Manage Nodes**.
4. Start the agent using the provided command.

## Jenkins with Nexus Repository
1. Install **Nexus Artifact Uploader Plugin**.
2. Configure a **Nexus Repository Manager**.
3. Add a step in the pipeline to upload artifacts:
   ```groovy
   nexusArtifactUploader(
       nexusVersion: 'nexus3',
       protocol: 'http',
       nexusUrl: 'nexus.local:8081',
       repository: 'raw-releases',
       credentialsId: 'nexus-creds',
       groupId: 'com.example',
       artifactId: 'app',
       version: '1.0',
       packaging: 'zip',
       file: 'target/app.zip'
   )
   ```

## Jenkins Backup & Recovery
### Backup
- Use **ThinBackup Plugin**.
- Backup **/var/jenkins_home** directory:
  ```bash
  tar -cvzf jenkins_backup.tar.gz /var/jenkins_home
  ```

### Restore
1. Stop Jenkins:
   ```bash
   sudo systemctl stop jenkins
   ```
2. Extract backup:
   ```bash
   tar -xvzf jenkins_backup.tar.gz -C /var/jenkins_home
   ```
3. Restart Jenkins:
   ```bash
   sudo systemctl start jenkins
   ```

## Conclusion
Jenkins is a powerful automation server that enhances software development efficiency. By leveraging pipelines, plugins, and integrations, teams can streamline their CI/CD workflows.

---

Would you like additional sections or specific use cases added?

