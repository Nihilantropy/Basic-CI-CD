### What i learned

---

## **Day 1**

#### **What is CI/CD**

#### **Basic pipeline concepts**

#### **What is GitLab**

#### **What is Jenkins**

#### **What is Nexus**

### **Started building docker-compose env and python flask-app for the CI/CD project**

### **Startet a video about Git Lab demo project**

---

## **Day 2**

### **Adjusted images and containers for more stability (adjusted volumes path, services images pull tags, custom images names)

### **Created Makefile to streamline the docker setup**

## **Entered Git Lab container configuration**
#### **Added user and groups**

### **Created Repo 'pipeline-project'**

### **Generated 'access token' for crea user to interact with the repository 'pipeline-project'**

### **Pushed python app to 'pipeline-project' repo on the local git lab instance**

## **Entered Jenkins configuration**
#### **Added user**

### **Generated 'access token' to communicate with git lab instance**

*problem* -> GitLab WebHooks (nor integration) are not working. Problem is in gitlab configuration (Default deny WebHook from localhost or private network -docker-)
