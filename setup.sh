#!/bin/bash
echo "🚀 Installation de l'infrastructure DevSecOps..."

# 1. ArgoCD
echo "📦 Installation ArgoCD..."
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 2. Nginx Ingress
echo "📦 Installation Nginx Ingress..."
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.hostNetwork=true \
  --set controller.kind=DaemonSet

# 3. Falco
echo "📦 Installation Falco..."
kubectl create namespace falco
helm install falco falcosecurity/falco \
  --namespace falco \
  --set driver.kind=modern_ebpf \
  --set containerSecurityContext.privileged=true \
  --set falcosidekick.enabled=true \
  --set falcosidekick.webui.enabled=true \
  --set tty=true

echo "✅ Installation terminée!"
