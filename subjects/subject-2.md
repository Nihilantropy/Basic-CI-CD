# CI/CD PROJECT - 2

Building upon CI/CD Project-1, integrate the following requirements:

---

## 1 - Update the Flask Application

- Implement a request rate limiting system on the APIs, allowing a maximum of 100 requests per minute
- Add the application version to the API message: "Hello, my name is ... version ### the time is XX:YY"

The application version will be available in the `version.info` file

---

## 2 - Update the Jenkins Pipeline

Add the following steps before the Compilation stage:

1. Bug checking using `ruff check`, selecting all rules. If issues are found in this step, interrupt the pipeline
2. Use `bandit` to perform a SAST (Static Application Security Testing) check of the code. If issues with Medium or High severity are found in this step, interrupt the pipeline

In case of success, proceed with Compilation and update the Nexus upload step, inserting the generated file with the "latest" postfix and a copy of the file with the timestamp postfix "yearmonthday hour minutes seconds":
- appflask-latest
- appflask-20250310220648

Subsequently, save the timestamp code "yearmonthday hour minutes seconds" in the `version.info` file and push the changes to the repository. Once the push is completed, generate a TAG in the repository with the value of the timestamp code "yearmonthday hour minutes seconds"

The progress of the Jenkins pipeline stages must be visible directly from GitLab

---

## 3 - Deployment with Helm

Add the ability to choose which version of the application to use