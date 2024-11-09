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
    name = "webgoat"
    labels = {
      environment = "development"
      managed-by  = "terraform"
    }
  }
}

# Resource quota for the namespace
resource "kubernetes_resource_quota" "webgoat" {
  metadata {
    name      = "webgoat-quota"
    namespace = kubernetes_namespace.webgoat.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"    = "2"
      "requests.memory" = "4Gi"
      "limits.cpu"      = "4"
      "limits.memory"   = "8Gi"
      "pods"           = "10"
    }
  }
}

# Network policy
resource "kubernetes_network_policy" "webgoat" {
  metadata {
    name      = "webgoat-network-policy"
    namespace = kubernetes_namespace.webgoat.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        app = "webgoat"
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
        port     = "8080"
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress"]
  }
}

# Service Account
resource "kubernetes_service_account" "webgoat" {
  metadata {
    name      = "webgoat-sa"
    namespace = kubernetes_namespace.webgoat.metadata[0].name
  }
}

# Role
resource "kubernetes_role" "webgoat" {
  metadata {
    name      = "webgoat-role"
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
    name      = "webgoat-role-binding"
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
