# GitLab Documentation

## Introduction
GitLab is a web-based DevOps platform that provides Git repository management, continuous integration/continuous deployment (CI/CD), issue tracking, and more. It enables teams to collaborate on software development and automate workflows efficiently.

## Key Features
- **Source Code Management**: Git repositories with branch protection, merge requests, and code review.
- **CI/CD Pipelines**: Automate build, test, and deployment workflows.
- **Issue Tracking**: Manage tasks, milestones, and bug reports.
- **Container Registry**: Built-in support for Docker images.
- **Security & Compliance**: Access controls, vulnerability scanning, and audit logs.
- **Integration**: Works with Kubernetes, Jenkins, Nexus, and other DevOps tools.

## Installation

### Prerequisites
- **Linux-based server (Ubuntu, Debian, CentOS, etc.)**
- **Minimum 4GB RAM and 2 CPU cores**
- **PostgreSQL, Redis, and other dependencies (handled automatically in Omnibus installation)**

### Installing GitLab on Ubuntu
```bash
sudo apt update
sudo apt install -y curl openssh-server ca-certificates
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash
sudo apt install gitlab-ee
```

### Configuring GitLab
1. Open **/etc/gitlab/gitlab.rb** and set external URL:
   ```bash
   sudo nano /etc/gitlab/gitlab.rb
   external_url 'http://gitlab.example.com'
   ```
2. Apply the configuration:
   ```bash
   sudo gitlab-ctl reconfigure
   ```
3. Access GitLab at **http://gitlab.example.com**.

### Running GitLab using Docker
```bash
docker run --detach \
  --hostname gitlab.example.com \
  --publish 443:443 --publish 80:80 --publish 22:22 \
  --name gitlab \
  --restart always \
  --volume gitlab-config:/etc/gitlab \
  --volume gitlab-logs:/var/log/gitlab \
  --volume gitlab-data:/var/opt/gitlab \
  gitlab/gitlab-ee:latest
```

## GitLab Repository Management

### Creating a New Repository
1. Navigate to **Projects > New Project**.
2. Choose **Create a Blank Project**.
3. Set project visibility (Private, Internal, Public).
4. Click **Create project**.
5. Clone repository:
   ```bash
   git clone http://gitlab.example.com/group/project.git
   ```

### Managing Branches
- Create a new branch:
  ```bash
  git checkout -b feature-branch
  git push origin feature-branch
  ```
- Merge branches using Merge Requests (MRs) in GitLab UI.

## GitLab CI/CD

### Setting Up CI/CD Pipelines
1. Create a `.gitlab-ci.yml` file in the root of your repository.
2. Define pipeline stages:
   ```yaml
   stages:
     - build
     - test
     - deploy
   ```
3. Add jobs:
   ```yaml
   build:
     stage: build
     script:
       - echo "Building project"

   test:
     stage: test
     script:
       - echo "Running tests"

   deploy:
     stage: deploy
     script:
       - echo "Deploying application"
   ```
4. Push changes, and GitLab will automatically trigger the pipeline.

### Managing Runners
- Install a GitLab Runner on a separate machine:
  ```bash
  curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
  sudo apt install gitlab-runner
  ```
- Register the runner:
  ```bash
  sudo gitlab-runner register
  ```
  Follow the prompts to configure the runner for your project.

## GitLab Security & Access Control

### User Management
- Add users via **Admin Area > Users**.
- Assign roles: Guest, Reporter, Developer, Maintainer, Owner.

### Access Permissions
- Repository-level permissions can be set under **Project Settings > Members**.
- Enable branch protection to restrict modifications to important branches.

## GitLab Integration with Nexus & Jenkins

### Storing Build Artifacts in Nexus
1. Configure GitLab CI/CD to upload artifacts to Nexus:
   ```yaml
   build:
     stage: build
     script:
       - mvn deploy -DrepositoryId=nexus -Durl=http://nexus.example.com/repository/maven-releases/
   ```

### Triggering Jenkins Jobs from GitLab
1. In Jenkins, install the **GitLab Plugin**.
2. Create a new job and configure **Source Code Management > Git** to use your GitLab repository.
3. In GitLab, go to **Settings > Webhooks** and add Jenkins URL:
   ```
   http://jenkins.example.com/gitlab-webhook/
   ```
4. Select trigger events (push, merge requests) and save.

## Backup & Restore

### Creating a Backup
```bash
sudo gitlab-backup create
```

### Restoring a Backup
```bash
sudo gitlab-ctl stop unicorn
sudo gitlab-ctl stop puma
sudo gitlab-ctl stop sidekiq
sudo gitlab-backup restore BACKUP=<timestamp>
sudo gitlab-ctl restart
```

## Conclusion
GitLab is a comprehensive DevOps tool that simplifies source code management, CI/CD automation, and collaboration. By integrating it with Jenkins and Nexus, teams can streamline software development and deployment workflows efficiently.

---

![Documentation](https://about.gitlab.com/resources/?topic=CI%2FCD)