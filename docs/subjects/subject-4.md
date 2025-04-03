# CI/CD PROJECT - 4

Starting from CI/CD projects 3, integrate the following requirements:

---

## 1 - Sonarqube configuration  
● Implement **Sonarqube** as part of the Jenkins pipeline. Since we are developing a Python application, it’s best to use the appropriate Python tools (e.g., *pysonar-scanner*, coverage, etc.) to analyze the code. Embrace the challenge and explore different options! 🔍

## 2 - Unit tests  
● Introduce some unit tests to make Sonarqube happy! If you don't aim for complete (or almost complete) test coverage, make sure to adjust the *quality gate* accordingly. Test your way to quality! ✅

## 3 - It's time to TERRAFORM  
● Replace your old Kubernetes cluster with a new and much prettier one using **Terraform**. The goal is to have the same structure as in project 3, but shifted to Terraform. This means all your custom resources must be present in the new environment *(Think carefully about what to do with the helm chart... could it be a trap???)*. For simplicity, set up a local Kubernetes cluster using a default provisioner like **kind** (Kubernetes IN Docker) or **Minikube**. Let Terraform handle the provisioning and configuration seamlessly! 🚀

## 4 - Adding Flux  
● Once your Terraform-based cluster is up and running, integrate **Flux** to automate the deployment process. Configure Flux to monitor your GitLab repository for new tags or changes, and trigger an automatic Helm upgrade when a new release is detected. This setup will ensure your deployments are fully automated and continuously in sync with your latest code changes. GitOps for the win! 🔄

## 5 - Documentation
● It's time for some seroius documentation! Imagine you have to give access to someone else to you Terraform managed cluster.

Happy coding and automating! 😊