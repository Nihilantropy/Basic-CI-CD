# AppFlask Helm Chart Documentation

## Overview

This Helm chart deploys the AppFlask application to a Kubernetes cluster. AppFlask is a simple Flask-based microservice that exposes a greeting endpoint and a health check endpoint with integrated rate limiting functionality.

## Prerequisites

Before deploying the application using Helm, ensure the following:

1. **Kubernetes Cluster**: A functional cluster accessible via `kubectl`.
2. **Nexus Repository Connection**: The Nexus container must be accessible from your Kubernetes cluster.
   - A headless service is created in the *nexus namespace* pointing to your host's local network IP (e.g., `192.168.1.27`).
   - This enables the application to fetch the executable from Nexus using the appropriate DNS resolution.
3. **Helm**: Helm v3.x installed and configured to work with your cluster.

## Chart Components

The Helm chart deploys the following Kubernetes resources:

1. **Deployment**:
   - Uses a base `ubuntu:22.04` image.
   - Configures replicas and environment variables from `values.yaml`.
   - Executes `launch-flask-app.sh` script, which:
     - Updates the package manager
     - Installs `wget`
     - Downloads the specified version of the executable from Nexus
     - Grants execution permissions
     - Launches the application
   - Implements a liveness probe that checks the `/health` endpoint

2. **Service**:
   - Exposes the application as a NodePort service
   - Uses a configurable port specified in `values.yaml`

3. **ConfigMap**:
   - Contains the startup script (`launch-flask-app.sh`)
   - Handles the download and execution of the AppFlask binary

## Configuration Options

The `values.yaml` file provides the following customization options:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `appVersion` | Version of the AppFlask binary to deploy | `"latest"` |
| `flaskEnv` | Flask environment setting | `"development"` |
| `replicaCount` | Number of application replicas | `2` |
| `agentName` | Name to display in the application's greeting | `"default Agent"` |
| `nodePort` | NodePort for external access | `30080` |

### Version Management

The `appVersion` parameter allows you to specify which version of the AppFlask binary to deploy:

- When set to `"latest"`, the deployment will use the most recent version from Nexus
- When specified (e.g., `"20240317123456"`), the deployment will use that specific version
- Versions are timestamp-based in the format `YYYYMMDDhhmmss`

### Environment Configuration

The `flaskEnv` parameter sets the application environment:

- `"development"`: Enables debugging features
- `"testing"`: Used for running tests
- `"production"`: Optimized for production use
- `"default"`: Falls back to development configuration

## Deployment Instructions

### Installing the Chart

To install the chart with the release name `appflask`:

```bash
helm install appflask ./appflask
```

To install a specific version of the application:

```bash
helm install appflask ./appflask --set appVersion=20240317123456
```

### Upgrading an Existing Deployment

To upgrade an existing deployment with changes to the values:

```bash
helm upgrade appflask ./appflask --set replicaCount=3 --set agentName="AgentSmith"
```

To switch to a different version of the application:

```bash
helm upgrade appflask ./appflask --set appVersion=20240317123456
```

### Uninstalling the Chart

To remove the application and all associated resources:

```bash
helm uninstall appflask
```

## Verification and Testing

### Verifying the Deployment

Check that all pods are running and ready:

```bash
kubectl get pods -l app=appflask
```

Verify the service is properly exposed:

```bash
kubectl get svc appflask-svc
```

### Testing the Application

#### From Inside the Cluster

To test the application from within the cluster:

```bash
kubectl run test-pod --rm -it --image=alpine -- /bin/sh
apk add curl
curl http://appflask-svc.default.svc.cluster.local:5000/
curl http://appflask-svc.default.svc.cluster.local:5000/health
```

#### From Outside the Cluster

To test the application from outside the cluster:

```bash
# Get the node IP and port
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
NODE_PORT=$(kubectl get svc appflask-svc -o jsonpath='{.spec.ports[0].nodePort}')

# Access the application
curl http://$NODE_IP:$NODE_PORT/
curl http://$NODE_IP:$NODE_PORT/health
```

Expected output from the main endpoint:
```json
{
  "message": "Hello, my name is PippoSowlo version 20240317123456 the time is 12:34"
}
```

Expected output from the health endpoint:
```json
{
  "status": "healthy"
}
```

## Rate Limiting

The AppFlask application implements global rate limiting with the following characteristics:

- **Limit**: 100 requests per minute across all endpoints
- **Scope**: Global (applies to all clients and endpoints)
- **Response**: Returns 429 status with retry information when exceeded

The rate limiting protects against DoS attacks and ensures system stability.

## Notes on Nexus Integration

The application is configured to download the binary from Nexus at container startup. The URL pattern is:

```
http://nexus-service.nexus.svc.cluster.local:8082/repository/my-artifacts/WmcA/appflask/{version}/appflask-{version}.bin
```

Where `{version}` is either:
- `latest` (when appVersion is set to "latest")
- A timestamp in the format `YYYYMMDDhhmmss` (when a specific appVersion is specified)

## Troubleshooting

Common issues and their solutions:

1. **Pods failing to start**:
   - Check that the Nexus service is accessible from the Kubernetes cluster
   - Verify the headless service is correctly configured with your host IP

2. **Version not found**:
   - Ensure the specified version exists in your Nexus repository
   - Check the launch script logs with `kubectl logs <pod-name>`

3. **Health check failing**:
   - Investigate application logs with `kubectl logs <pod-name>`
   - Verify the application is running with `kubectl exec -it <pod-name> -- ps aux`

## Security Considerations

The deployment uses a minimal Ubuntu image and downloads only the required binary at runtime. Consider implementing the following security enhancements:

- Use a non-root user in the container
- Implement network policies to restrict pod communication
- Configure resource limits for the deployment