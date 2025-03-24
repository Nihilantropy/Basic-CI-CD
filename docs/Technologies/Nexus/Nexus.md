# Nexus Repository Manager Documentation

## Introduction
Nexus Repository Manager is a powerful artifact repository used for storing, managing, and distributing build artifacts, dependencies, and container images. It supports various repository formats, including Maven, npm, PyPI, Docker, and raw file storage.

## Key Features
- **Artifact Storage**: Stores and manages build artifacts efficiently.
- **Repository Formats**: Supports Maven, npm, PyPI, Docker, Helm, and more.
- **Integration with CI/CD**: Works with Jenkins, GitLab CI, and other automation tools.
- **Access Control**: Role-based access and permissions.
- **Proxy & Caching**: Acts as a proxy for external repositories like Maven Central.
- **Security & Compliance**: Vulnerability scanning and policy enforcement.

## Installation

### Prerequisites
- **Java 8 or higher**
- **Docker (optional for containerized deployment)**
- **Minimum 4GB RAM and 10GB disk space**

### Installation on Linux (Ubuntu/Debian)
```bash
wget -O nexus.tar.gz https://download.sonatype.com/nexus/3/latest-unix.tar.gz
tar -xvzf nexus.tar.gz
mv nexus-* nexus
sudo adduser --system --group nexus
sudo chown -R nexus:nexus nexus
```

### Running Nexus
```bash
cd nexus
./bin/nexus start
```
Access Nexus via **http://localhost:8081**

### Installation using Docker
```bash
docker run -d --name nexus -p 8081:8081 -v nexus-data:/nexus-data sonatype/nexus3
```

## Initial Setup
1. Open **http://localhost:8081**.
2. Log in using the default credentials:
   - Username: `admin`
   - Password: Retrieved from:
     ```bash
     cat /nexus-data/admin.password
     ```
3. Change the admin password and configure settings.

## Repository Management

### Creating a New Repository
1. Navigate to **Admin > Repository**.
2. Click **Create repository**.
3. Select the repository format (Maven, npm, Docker, etc.).
4. Configure storage, deployment, and access settings.
5. Save the repository.

### Repository Types
- **Hosted**: Stores internal artifacts.
- **Proxy**: Caches external repositories like Maven Central.
- **Group**: Aggregates multiple repositories into a single endpoint.

## Uploading Artifacts

### Using Nexus UI
1. Go to **Browse > Select Repository**.
2. Click **Upload artifact**.
3. Select files and enter artifact details.
4. Click **Upload**.

### Using cURL
```bash
curl -u admin:password --upload-file myfile.zip "http://localhost:8081/repository/raw-hosted/myfile.zip"
```

## Integration with CI/CD

### Jenkins Nexus Integration
1. Install the **Nexus Artifact Uploader Plugin**.
2. Configure Nexus credentials in **Manage Jenkins > Credentials**.
3. Add Nexus artifact upload in the Jenkins pipeline:
   ```groovy
   nexusArtifactUploader(
       nexusVersion: 'nexus3',
       protocol: 'http',
       nexusUrl: 'http://localhost:8081',
       repository: 'raw-hosted',
       credentialsId: 'nexus-creds',
       groupId: 'com.example',
       artifactId: 'app',
       version: '1.0',
       packaging: 'zip',
       file: 'target/app.zip'
   )
   ```

## Security & Access Control

### User & Role Management
1. Go to **Security > Users & Roles**.
2. Create new users and assign roles.
3. Configure permissions for repository access.

### Enabling Anonymous Access
1. Navigate to **Security > Anonymous Access**.
2. Enable or disable anonymous read access.

## Backup & Recovery

### Backup Nexus Data
```bash
tar -czvf nexus_backup.tar.gz /nexus-data
```

### Restore Backup
1. Stop Nexus:
   ```bash
   ./bin/nexus stop
   ```
2. Extract backup:
   ```bash
   tar -xzvf nexus_backup.tar.gz -C /nexus-data
   ```
3. Restart Nexus:
   ```bash
   ./bin/nexus start
   ```

## Conclusion
Nexus Repository Manager is an essential tool for managing build artifacts and dependencies in modern DevOps workflows. By integrating it with CI/CD pipelines, development teams can ensure secure and efficient artifact management.

---

![Documentation](https://www.sonatype.com/products/sonatype-nexus-repository)
