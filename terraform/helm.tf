terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "0.4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = kind_cluster.devsecops.endpoint
    client_certificate     = kind_cluster.devsecops.client_certificate
    client_key             = kind_cluster.devsecops.client_key
    cluster_ca_certificate = kind_cluster.devsecops.cluster_ca_certificate
  }
}

provider "kubectl" {
  host                   = kind_cluster.devsecops.endpoint
  client_certificate     = kind_cluster.devsecops.client_certificate
  client_key             = kind_cluster.devsecops.client_key
  cluster_ca_certificate = kind_cluster.devsecops.cluster_ca_certificate
  load_config_file       = false
}

# ArgoCD
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  wait             = true

  depends_on = [kind_cluster.devsecops]
}

# Nginx Ingress
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  wait             = true

  set {
    name  = "controller.hostNetwork"
    value = "true"
  }

  set {
    name  = "controller.kind"
    value = "DaemonSet"
  }

  depends_on = [kind_cluster.devsecops]
}

# Falco
resource "helm_release" "falco" {
  name             = "falco"
  repository       = "https://falcosecurity.github.io/charts"
  chart            = "falco"
  namespace        = "falco"
  create_namespace = true
  wait             = false

  set {
    name  = "driver.kind"
    value = "modern_ebpf"
  }

  set {
    name  = "containerSecurityContext.privileged"
    value = "true"
  }

  set {
    name  = "falco.watch_config_files"
    value = "false"
  }

  set {
    name  = "falcosidekick.enabled"
    value = "true"
  }

  set {
    name  = "falcosidekick.webui.enabled"
    value = "true"
  }

  set {
    name  = "tty"
    value = "true"
  }

  depends_on = [kind_cluster.devsecops]
}

# Prometheus + Grafana
resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  wait             = false

  set {
    name  = "grafana.adminPassword"
    value = "devsecops123"
  }

  set {
    name  = "grafana.enabled"
    value = "true"
  }

  set {
    name  = "prometheus.prometheusSpec.retention"
    value = "7d"
  }

  depends_on = [kind_cluster.devsecops]
}

# Loki
resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki-stack"
  namespace        = "monitoring"
  create_namespace = false
  wait             = false

  set {
    name  = "grafana.enabled"
    value = "false"
  }

  set {
    name  = "prometheus.enabled"
    value = "false"
  }

  set {
    name  = "loki.persistence.enabled"
    value = "false"
  }

  depends_on = [helm_release.prometheus]
}

resource "kubectl_manifest" "applicationset" {
  yaml_body = file("${path.module}/../gitops/applicationset.yaml")
  depends_on = [helm_release.argocd]
}
