# Flask App CI/CD Pipeline

## 1. Overview
This repository contains a Flask-based application that is built, tested, packaged, and deployed using a CI/CD pipeline managed by Jenkins. The application provides two main endpoints and is deployed in a Kubernetes cluster via Helm.

## 2. Flask Application

### **Why Flask?**
Flask is a lightweight and flexible Python framework suitable for building simple web applications with minimal overhead.

### **Endpoints:**
- `/` – Returns a JSON message with a dynamic agent name and timestamp.
- `/health` – Returns a simple response (`{"status": "healthy"}`) to indicate the application's health.

### **Listening Port & Host:**
- Port: `5000`
- Host: `0.0.0.0` (allows access from any network interface)

### **Template Values in the Root Endpoint:**
```python
jsonify({"message": f"Hello, my name is {agent_name} the time is {time}"})
```
- `agent_name` is set via an environment variable, allowing it to be overridden dynamically (configured in the Helm `values.yaml`).
- `time` is set within the application at runtime.

### **Testing:**
- `pytest` is used to test the `/health` endpoint, ensuring the application is running correctly.

## 3. GitLab Repository & Jenkins Integration

This application is hosted in a GitLab repository, which is connected to Jenkins via an Integration. When a change is pushed to the `developer` branch, GitLab triggers the pipeline by sending a POST request to Jenkins. This ensures automated testing, building, and deployment upon every code update.

## 4. Jenkins Pipeline (Jenkinsfile)

The CI/CD pipeline is defined in the `Jenkinsfile`. It automates testing, building, and deploying the application.

*🚨Important🚨* In this Pipeline we use a `Telegram Bot` to recive libe feedbacks about the pipeline status. To make this work we need 2 credentials set in Jenkins: 
1 - **telegram-bot-token** to store the bot token.
2 - **telegram-bot-chatid** to store the chat id.
[Telegram-Bot-documentation](https://core.telegram.org/bots/tutorial)

### **Pipeline Breakdown:**
1. **Custom Docker Agent:** The pipeline runs inside a custom Docker container defined by a `Dockerfile` at the root of the repository.
2. **Install Dependencies:** Sets up a virtual environment and installs required Python packages.
3. **Run Tests:** Uses `pytest` to validate the `/health` endpoint.
4. **Build Executable:** Uses `pyinstaller` to package the application as a single binary file.
5. **Archive Executable:** Stores the generated binary as a build artifact.
6. **Upload to Nexus:** Uploads the binary to a Nexus repository.
