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
  config_path    = "~/.kube/config"
  config_context = "docker-desktop"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "docker-desktop"
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
      "requests.cpu"    = "2"
      "requests.memory" = "2Gi"
      "limits.cpu"      = "4"
      "limits.memory"   = "4Gi"
      "pods"            = "10"
    }
  }
}

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

resource "kubernetes_service_account" "webgoat" {
  metadata {
    name      = "${var.namespace}-sa"
    namespace = kubernetes_namespace.webgoat.metadata[0].name
  }
}

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

resource "kubernetes_storage_class" "standard" {
  metadata {
    name = "webgoat-storage"
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
              cpu    = "500m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "1"
              memory = "1Gi"
            }
          }
        }
      }
    }
  }
}

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
