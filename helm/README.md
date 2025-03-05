# Helm Deployment Documentation

## Prerequisites

Before deploying the application using Helm, ensure the following:

1. **K3s Cluster Running:** The cluster should be operational and accessible via `kubectl`.
2. **Nexus Repository Connection:** Since our Nexus container is running on our host machine with port `8082` exposed, we must ensure the Kubernetes cluster can access it.
   - We achieve this by creating a headless service within the cluster, pointing to our host's local network IP (e.g., `192.168.1.27`), in the *nexus namespace*.
   - This enables the application to fetch the executable from Nexus using the appropriate DNS resolution (`nexus-service.nexus.svc.cluster.local`).

## Helm Chart Overview

The Helm chart will deploy the following Kubernetes resources:

1. **Deployment:**
   - Uses a base `ubuntu:22.04` image.
   - Retrieves the `replicaCount` and `AGENT_NAME` value from `values.yaml`.
   - The container starts by executing the `launch-flask-app.sh` script, which:
     - Updates the package manager (`apt-get`).
     - Installs `wget`.
     - Downloads the executable from Nexus.
     - Grants execution permissions.
     - Launches the application.
   - Liveness Probe ensures the app is running by checking the `/health` endpoint on port `5000` every `10` seconds, with an initial delay of `5` seconds.

2. **NodePort Service:**
   - Exposes the application outside the cluster.
   - The NodePort value can be customized in `values.yaml`.

3. **ConfigMap:**
   - Contains the `launch-flask-app.sh` script responsible for preparing and starting the application.

## Helm Deployment Steps

### Install the Chart
```sh
helm install flask-app ./flask-app
```

### Upgrade the Release
If you make changes to the Helm chart and need to apply them:
```sh
helm upgrade flask-app ./flask-app
```

### Delete the Deployment
```sh
helm uninstall flask-app
```

### Verify Deployment
After deploying, ensure all components are running:
```sh
kubectl get pods -l app=flask-app
kubectl get svc flask-app
```

## Testing the Application

### From Inside the Cluster (Using a Pod)
To check if the application is running, execute:
```sh
kubectl run test-pod --rm -it --image=alpine -- /bin/sh
apk add curl
curl http://flask-app.default.svc.cluster.local:5000/
curl http://flask-app.default.svc.cluster.local:5000/health
```

### From Outside the Cluster (Using NodePort)
Retrieve the external port and node IP:
```sh
kubectl get svc flask-app
```
If the NodePort is `30080` and the worker node IP is `192.168.1.27`, test using:
```sh
curl http://192.168.1.27:30080/
curl http://192.168.1.27:30080/health
```

If everything is working, the app should return JSON responses. 🎉
