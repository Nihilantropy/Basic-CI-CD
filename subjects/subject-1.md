**1 - Base Environment Setup**  
Create a Docker Compose environment with Jenkins, Nexus, and GitLab.  

**2 - Python Application**  
Develop a Python application using Flask that exposes two endpoints:  
- One endpoint responds with: *"Hello, my name is ... the time is xx:yy"*.  
- A second endpoint for health-check monitoring.  
Containerize the application using a Dockerfile and save all files to the GitLab repository named **"app-flask"**.  

**3 - Jenkins Pipeline**  
- Build the Python component **"app-flask"** using PyInstaller and upload the entire contents of the `dist` folder to a Nexus **RAW repository**.  
- Configure the pipeline to trigger automatically on changes to the **"app-flask"** repository or manually via Jenkins.  

**4 - Helm Chart**  
- Create a Helm Chart that allows configuring the following via `values.yaml`:  
  - Number of deployment replicas.  
  - Agent name (to replace the *"..."* placeholder in the output string).  
- Implement a **Liveness probe** pointing to the health-check endpoint.
- Deployment of the chart will be done **manually**.
*Note: The application will start by downloading the binary from Nexus and executing it.*  

**Kubernetes Setup**:  
Use **K3s**, Docker Desktop’s integrated Kubernetes, or **Minikube**. Ensure thorough documentation is written for both repositories.  
