## Infrastructure Setup with Terraform

### Prerequisites

1. Install required tools:
```bash
# Install Terraform
brew install terraform

# Install Docker Desktop (if not already installed)
brew install --cask docker

# Enable Kubernetes in Docker Desktop
# Open Docker Desktop -> Settings -> Kubernetes -> Enable Kubernetes
```

2. Verify installations:
```bash
terraform version
kubectl version
docker version
```

### Infrastructure Deployment

1. Initialize Terraform:
```bash
cd terraform
terraform init
```

2. Plan the deployment:
```bash
terraform plan -out=tfplan
```

3. Apply the configuration:
```bash
terraform apply tfplan
```

### Infrastructure Components

The Terraform configuration creates:

1. **Namespace Configuration**
   - Dedicated namespace for WebGoat
   - Resource quotas
   - Network policies

2. **Security Setup**
   - RBAC configuration
   - Service accounts
   - Network policies
   - Pod security policies

3. **Resource Management**
   - CPU and memory limits
   - Storage configuration
   - Namespace quotas

### Security Features

1. **Network Security**
   - Isolated namespace
   - Ingress/egress restrictions
   - Pod-to-pod communication rules

2. **Access Control**
   - Role-based access control (RBAC)
   - Service account restrictions
   - Minimal permissions principle

3. **Resource Controls**
   - CPU/memory quotas
   - Pod count limits
   - Storage restrictions

### Customization

You can customize the deployment by modifying the variables in `terraform.tfvars`:

```hcl
environment = "development"
namespace   = "webgoat"
resource_limits = {
  cpu    = "4"
  memory = "8Gi"
}
```

### Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

### Best Practices Implemented

1. **Resource Management**
   - Defined resource quotas
   - Limited pod counts
   - Storage class configuration

2. **Security**
   - Network policies
   - RBAC configuration
   - Service account restrictions

3. **Isolation**
   - Namespace separation
   - Resource quotas
   - Network segmentation
