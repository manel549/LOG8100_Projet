# main.tf
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Create namespace with resource quotas
resource "kubernetes_namespace" "webgoat" {
  metadata {
    name = var.namespace
    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

resource "kubernetes_resource_quota" "webgoat" {
  metadata {
    name      = "webgoat-quota"
    namespace = kubernetes_namespace.webgoat.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"    = "2"   # CPU demandée maximum
      "requests.memory" = "2Gi" # Mémoire demandée maximum
      "limits.cpu"      = "4"   # Limite CPU maximum
      "limits.memory"   = "4Gi" # Limite mémoire maximum
      "pods"            = "10"  # Nombre de pods maximum
    }
  }
}


# Network policy
resource "kubernetes_network_policy" "webgoat" {
  metadata {
    name      = "${var.namespace}-network-policy"
    namespace = kubernetes_namespace.webgoat.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        app = var.namespace
      }
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.webgoat.metadata[0].name
          }
        }
      }
      ports {
        port     = 8080
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress"]
  }
}

# Service Account
resource "kubernetes_service_account" "webgoat" {
  metadata {
    name      = "${var.namespace}-sa"
    namespace = kubernetes_namespace.webgoat.metadata[0].name
  }
}

# Role
resource "kubernetes_role" "webgoat" {
  metadata {
    name      = "${var.namespace}-role"
    namespace = kubernetes_namespace.webgoat.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services"]
    verbs      = ["get", "list", "watch"]
  }
}

# Role Binding
resource "kubernetes_role_binding" "webgoat" {
  metadata {
    name      = "${var.namespace}-role-binding"
    namespace = kubernetes_namespace.webgoat.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.webgoat.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.webgoat.metadata[0].name
    namespace = kubernetes_namespace.webgoat.metadata[0].name
  }
}

# Storage Class
resource "kubernetes_storage_class" "standard" {
  metadata {
    name = "standard"
  }
  storage_provisioner = "kubernetes.io/no-provisioner"
  reclaim_policy     = "Retain"
}

resource "kubernetes_deployment" "webgoat_app" {
  metadata {
    name      = "webgoat-app"
    namespace = kubernetes_namespace.webgoat.metadata[0].name
    labels = {
      app = "webgoat"
    }
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
        container {
          name  = "webgoat"
          image = "webgoat/webgoat-8.0"
          port {
            container_port = 8080
          }
          resources {
            requests = {
              cpu    = "500m" # 0.5 CPU
              memory = "512Mi"
            }
            limits = {
              cpu    = "1" # 1 CPU
              memory = "1Gi"
            }
          }
        }
      }
    }
  }
}



# Service
resource "kubernetes_service" "webgoat_service" {
  metadata {
    name      = "${var.namespace}-service"
    namespace = kubernetes_namespace.webgoat.metadata[0].name
  }
  spec {
    selector = {
      app = var.namespace
    }
    port {
      port        = 8080
      target_port = 8080
    }
    type = "ClusterIP"
  }
}
