# WebGoat Kubernetes Deployment

This project demonstrates a secure deployment of OWASP WebGoat in a Kubernetes environment with CI/CD pipeline integration.

## Project Structure
```
.
├── .github/
│   └── workflows/
│       └── ci.yml              # GitHub Actions workflow
├── kubernetes/
│   ├── deployment.yml          # WebGoat deployment configuration
│   └── service.yml            # WebGoat service configuration
└── README.md                  # Project documentation
```

## Prerequisites

- Docker Desktop with Kubernetes enabled
- kubectl CLI tool
- GitHub account
- Git

## Local Development Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd <repository-name>
```

2. Start Kubernetes cluster:
```bash
# Verify Kubernetes is running
kubectl get nodes
```

3. Create namespace:
```bash
kubectl create namespace webgoat
```

## Kubernetes Configuration

### Deployment Configuration

The deployment configuration (`kubernetes/deployment.yml`) includes:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webgoat
  namespace: webgoat
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webgoat
  template:
    metadata:
      labels:
        app: webgoat
    spec:
      containers:
      - name: webgoat
        image: webgoat/webgoat:latest
        ports:
        - containerPort: 8080
```

### Service Configuration

The service configuration (`kubernetes/service.yml`) includes:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: webgoat
  namespace: webgoat
spec:
  selector:
    app: webgoat
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
```

## CI/CD Pipeline

Our CI/CD pipeline uses GitHub Actions for automated building, testing, and deployment.

### Pipeline Stages

1. **Build Stage**
   - Checkout code
   - Build Docker image
   - Push to container registry

2. **Security Scan Stage**
   - Scan Docker image for vulnerabilities
   - Analyze code for security issues

3. **Deploy Stage**
   - Deploy to Kubernetes cluster
   - Verify deployment status

### GitHub Actions Workflow

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Login to DockerHub
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKER_HUB_USERNAME }}
        password: ${{ secrets.DOCKER_HUB_TOKEN }}
    
    - name: Build and push Docker image
      uses: docker/build-push-action@v4
      with:
        push: true
        tags: ${{ secrets.DOCKER_HUB_USERNAME }}/webgoat:latest
    
    - name: Deploy to Kubernetes
      run: |
        kubectl apply -f kubernetes/
```

## Deployment

1. Deploy the application:
```bash
kubectl apply -f kubernetes/deployment.yml
kubectl apply -f kubernetes/service.yml
```

2. Verify deployment:
```bash
kubectl get pods -n webgoat
kubectl get services -n webgoat
```

3. Access the application:
```bash
kubectl port-forward -n webgoat svc/webgoat 9000:8080
```

Access WebGoat at: http://localhost:9000/WebGoat

## Security Considerations

1. Container Security:
   - Non-root user
   - Read-only filesystem
   - Resource limits

2. Network Security:
   - Internal service exposure only
   - Port restrictions
   - Network policies

3. Access Control:
   - RBAC configuration
   - Service accounts
   - Namespace isolation

## Monitoring

1. Container Health:
   - Liveness probe
   - Readiness probe
   - Startup probe

2. Resource Monitoring:
   - CPU usage
   - Memory usage
   - Network traffic

## Best Practices

1. **Container Images**
   - Use specific versions
   - Regular updates
   - Minimal base images

2. **Configuration**
   - Use ConfigMaps for configuration
   - Use Secrets for sensitive data
   - Resource limits

3. **Security**
   - Regular security scans
   - Image signing
   - Network policies

## Troubleshooting

Common issues and solutions:

1. Pod not starting:
```bash
kubectl describe pod -n webgoat <pod-name>
kubectl logs -n webgoat <pod-name>
```

2. Service not accessible:
```bash
kubectl get svc -n webgoat
kubectl describe svc -n webgoat webgoat
```

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [WebGoat Documentation](https://owasp.org/www-project-webgoat/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
