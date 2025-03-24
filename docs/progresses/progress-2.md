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

### have to use credentials for git email and username

### Moved all utility functions into separeted file for modularity

### Work on the git lab push stage to utilize not the username and password but the personal-access-token for authentication

### Doing test on developer/main branches. The push of the version is done using GIT_BRANCH var to target the current job branch (e.g. developer)

### Pipeline working! All stages works well, have to correct ruff checks in order to pass the pipeline test phase

---

# Day 4

### Adjusted Jenkinsfile credentials

### Cleaned up environment

### Worked on security enhancement and resource optimization

### Tested groovy string nterpolation

### Adding workspace cleanup (having issue on the notify telegram action if i cleanup workspace)

### Added timeout control

### Studied Jenkins functionality

---

# Day 5

### Corrected a pyinstaller problem (submodules import)

### Setup helm in order to utilize the nexus binary version of the app

### ALL WORKS!

### Made tests, improvement and documentation on how-to-use

### Next: find a way to autodeploy helm chart on new app release