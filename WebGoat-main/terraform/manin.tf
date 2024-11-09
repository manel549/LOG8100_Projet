# terraform/main.tf
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

resource "kubernetes_namespace" "webgoat" {
  metadata {
    name = "webgoat"
    labels = {
      environment = "development"
      app        = "webgoat"
    }
  }
}

resource "kubernetes_deployment" "webgoat" {
  metadata {
    name      = "webgoat"
    namespace = kubernetes_namespace.webgoat.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "webgoat"
      }
    }

    template {
      metadata {
        labels = {
          app = "webgoat"
        }
      }

      spec {
        security_context {
          fs_group = 1000
        }
        
        container {
          name  = "webgoat"
          image = "${var.docker_registry}/webgoat:latest"

          port {
            container_port = 8080
            name          = "http"
          }

          port {
            container_port = 9090
            name          = "management"
          }

          security_context {
            run_as_user                = 1000
            run_as_non_root           = true
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
          }

          resources {
            limits = {
              cpu    = "1000m"
              memory = "1Gi"
            }
            requests = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/WebGoat/actuator/health"
              port = 8080
            }
            initial_delay_seconds = 60
            period_seconds       = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "webgoat" {
  metadata {
    name      = "webgoat"
    namespace = kubernetes_namespace.webgoat.metadata[0].name
  }

  spec {
    selector = {
      app = "webgoat"
    }

    port {
      name        = "http"
      port        = 8080
      target_port = 8080
    }

    port {
      name        = "management"
      port        = 9090
      target_port = 9090
    }

    type = "ClusterIP"
  }
}

# terraform/variables.tf
variable "docker_registry" {
  description = "Docker registry path"
  type        = string
  default     = "webgoat"
}

# terraform/outputs.tf
output "namespace" {
  value = kubernetes_namespace.webgoat.metadata[0].name
}

output "service_name" {
  value = kubernetes_service.webgoat.metadata[0].name
}
