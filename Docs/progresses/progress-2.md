# Day 1

### Project & Team Organization

### Rate limiting in flask application (https://flask-limiter.readthedocs.io/en/stable/)

### Created a more modular and scalable project structure for flask-app

### Created different types of env, custom via FLASK_ENV var by name values ("development", "production", "testing")

### Created app specific tests for routes and rate limits (can be run with pytest)

### Using blueprint for app routes

### Utilizing version.info file for flask-app version tag

### Switched to global request rate limits (all addressed, all endpoints)

### Using centralized and customizable values in config.py to update request rate limits and default retry time

### Worked on bash script to test rate limits reliability

### Updated Dockerfile for custom docker agent for Jenkins pipeline

### Flask app is done! Next: Jenkins pipeline

---

# Day 2

### Find a tool to perform simulate DOS attack in order to test flask-app rate limit (Using Gatling Open Source)

### Developed Jenkinsfile pipeline:
    1. added ruff stage
    2. added bandit stage
    3. instert gilab stage post request for instant feedback
    4. added version.info changes directly to the gitlab repo from the Jenkinsfile stage
    5. added parameters to have controlled pipeline testing stages using jenkins-config.yml file
    6. switched to more modular Jenkinsfile, with reusable functions for all stages

### testing pipeline using controlled stages version, binary upload on nexus and gitlab push changes on version.info file

### Pipeline live update on the gitlab repo working!

## NEXT: working on the Jenkinsfile -> Gitlab push
    
---

# Day 3

### Worked on Jenkinsfile - GitLab push requests

### Updated Docker agent to share host network to allow communication with gitlab from inside container agent

### Push request now work!

### Workin on push request filtering using [ci skip] (or equivalent) filter keyword in commit message

### Trying to find a way to optimize resources

### Pipeline working! have to use credentials for git email and username