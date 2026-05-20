output "cluster_name" {
  description = "Nom du cluster créé"
  value       = kind_cluster.devsecops.name
}

output "kubeconfig" {
  description = "Kubeconfig pour accéder au cluster"
  value       = kind_cluster.devsecops.kubeconfig
  sensitive   = true
}
