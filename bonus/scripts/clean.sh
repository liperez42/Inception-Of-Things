#!/bin/bash

RED='\033[31m'
GREEN='\033[32m'
BLUE='\033[34m'
NC='\033[0m' # No Color

# ----- Clean Start -----
echo -e "${GREEN}------------ Cleaning previous installations ------------${NC}"

# Delete ArgoCD
echo -e "${BLUE}Deleting ArgoCD...${NC}"
if kubectl get ns argocd &> /dev/null; then
  sudo kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
fi
if k3d cluster list | grep -q "IOT-cluster"; then
  sudo k3d cluster delete IOT-cluster
fi

# Uninstall gitlab
echo -e "${BLUE}Uninstall gitlab...${NC}"
if helm list -n gitlab &> /dev/null; then
  helm uninstall gitlab --namespace gitlab
fi

# Delete Kubernetes namespaces
echo -e "${BLUE}Deleting Kubernetes namespaces...${NC}"
sudo kubectl delete namespace argocd dev gitlab --ignore-not-found

# Uninstall Helm
echo -e "${BLUE}Uninstall Helm...${NC}"
sudo apt-get remove --purge helm -y
sudo rm -f /usr/share/keyrings/helm.gpg
sudo rm -f /etc/apt/sources.list.d/helm-stable-debian.list

echo -e "Uninstall K3D..."
if command -v k3d &> /dev/null; then
    curl -s -o /tmp/k3d_install.sh https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh
    chmod +x /tmp/k3d_install.sh
    /tmp/k3d_install.sh --uninstall
    rm -f /tmp/k3d_install.sh
    echo -e "K3D uninstalled."
fi

# Removing Docker
echo -e "${BLUE}Deleting Docker...${NC}"
if command -v helm &> /dev/null; then
  sudo systemctl stop docker
  sudo dpkg --configure -a
  sudo apt remove --purge -y docker-ce docker-ce-cli containerd.io
  sudo rm -rf /var/lib/docker
  sudo rm -rf /var/lib/containerd
fi

# Apt clean
echo -e "${BLUE}Cleaning apt...${NC}"
sudo apt autoremove -y
sudo apt clean

echo -e "${GREEN}------------ Cleaning Done ------------${NC}"