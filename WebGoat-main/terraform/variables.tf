# variables.tf
variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "development"
}

variable "namespace" {
  description = "Kubernetes namespace for WebGoat"
  type        = string
  default     = "webgoat"
}

variable "resource_limits" {
  description = "Resource limits for namespace"
  type = object({
    cpu    = string
    memory = string
  })
  default = {
    cpu    = "1"
    memory = "1Gi"
  }
}
