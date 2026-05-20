variable "cluster_name" {
  description = "Nom du cluster Kubernetes"
  type        = string
  default     = "devsecops-cluster"
}

variable "kubernetes_version" {
  description = "Version de Kubernetes"
  type        = string
  default     = "v1.31.0"
}

variable "worker_nodes" {
  description = "Nombre de noeuds worker"
  type        = number
  default     = 2
}
