resource "kind_cluster" "devsecops" {
  name            = var.cluster_name
  wait_for_ready  = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role  = "control-plane"
      image = "kindest/node:${var.kubernetes_version}"
      extra_mounts {
        host_path      = "/tmp/falco"
        container_path = "/tmp/falco"
      }
    }

    node {
      role  = "worker"
      image = "kindest/node:${var.kubernetes_version}"
    }

    node {
      role  = "worker"
      image = "kindest/node:${var.kubernetes_version}"
    }
  }
}
