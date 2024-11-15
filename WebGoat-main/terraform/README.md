
## Infrastructure Setup with Terraform for WebGoat Deployment

### Prerequisites

1. **Install Required Tools**:
   Ensure the following tools are installed and properly configured:

   ```bash
   # Install Terraform
   brew install terraform

   # Install Docker Desktop (if not already installed)
   brew install --cask docker

   # Enable Kubernetes in Docker Desktop
   # Open Docker Desktop -> Settings -> Kubernetes -> Enable Kubernetes
   ```

2. **Verify Installations**:
   Confirm that the necessary tools are installed and operational:
   ```bash
   terraform version
   kubectl version --client
   docker version
   ```

---

### Infrastructure Deployment

1. **Navigate to the Terraform Directory**:
   ```bash
   cd terraform
   ```

2. **Initialize Terraform**:
   Initialize Terraform to download the required providers and modules:
   ```bash
   terraform init
   ```

3. **Plan the Deployment**:
   Generate a detailed execution plan to verify changes:
   ```bash
   terraform plan -out=tfplan
   ```

4. **Apply the Configuration**:
   Deploy the infrastructure using Terraform:
   ```bash
   terraform apply tfplan
   ```

---

### Infrastructure Components

The Terraform configuration deploys the following resources:

1. **Namespace Configuration**:
   - A dedicated namespace (`webgoat`) for the WebGoat application.
   - Resource quotas to manage CPU, memory, and pod limits.

2. **Security Features**:
   - **RBAC Configuration**: Role-based access control for namespaces and pods.
   - **Service Accounts**: Isolated service account for the WebGoat deployment.
   - **Network Policies**: Policies to control ingress and egress traffic for pods.

3. **Application Deployment**:
   - A `Deployment` resource to manage WebGoat application pods.
   - A `Service` to expose the WebGoat application on port `8080`.

4. **Resource Quotas and Limits**:
   - Limits for CPU and memory usage per pod and namespace.
   - Restrictions on the number of pods allowed in the namespace.

---

### Accessing WebGoat

1. **Using `kubectl port-forward`**:
   Forward the WebGoat service to your local machine to access it:
   ```bash
   kubectl port-forward -n webgoat svc/webgoat-service 8080:8080
   ```
   Access the application in your browser at [http://localhost:8080](http://localhost:8080).

2. **Verify Deployment**:
   Check the status of the pods and services:
   ```bash
   # List pods
   kubectl get pods -n webgoat

   # Check services
   kubectl get services -n webgoat
   ```

---

### Customization

You can tailor the deployment by modifying the `terraform.tfvars` file:
```hcl
environment = "development"
namespace   = "webgoat"
resource_limits = {
  cpu    = "1"
  memory = "1Gi"
}
```

---

### Cleanup

To destroy all resources and clean up the environment:
```bash
terraform destroy
```

---

### Best Practices Implemented

1. **Resource Management**:
   - Defined CPU and memory limits for efficient usage.
   - Enforced resource quotas for namespace isolation.

2. **Security Enhancements**:
   - Role-based access control (RBAC) for secure access.
   - Network policies to restrict traffic within the namespace.
   - Service accounts with minimal permissions.

3. **Application Isolation**:
   - Deployed WebGoat in a dedicated namespace.
   - Segregated resources to avoid cross-environment interference.
