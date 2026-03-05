#!/bin/bash

RED='\033[31m'
GREEN='\033[32m'
NC='\033[0m' # No Color

# ----- Clean Start -----
echo "------------ Cleaning previous installations ------------"
sudo ./p3/scripts/clean.sh

# ----- Instalations -----

#Install Docker
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg -y
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
echo "apres update"
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
echo "Docker installation succeeded !"

#Start Docker
echo "Starting docker..."
sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl status docker --no-pager

#Install k3d
echo "Installing k3d..."
sudo curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

#Install  kubectl
echo "Installing kubectl..."
sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# ----- Create and config K3D cluster -----

#Create cluster
echo "Creating cluster..."
sudo k3d cluster create IOT-cluster --port "8888:8888@loadbalancer" --wait
sleep 10

#Create namespaces
echo "Creating namespaces..."
sudo kubectl create namespace argocd
sudo kubectl create namespace dev

#k3d config
rm -rf ~/.kube/config
mkdir -p ~/.kube
k3d kubeconfig get IOT-cluster > ~/.kube/config
chmod 600 ~/.kube/config

#Install ArgoCD in the namespaces (server-side)
sudo kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo "Argocd installation succeeded !"

#wait pods Argo CD
echo "Waiting for the pods to be ready..."
sudo kubectl wait --for=condition=Ready pods -n argocd --all --timeout=300s

#Apply application
sudo kubectl apply -f $PWD/p3/confs/application.yaml -n argocd

#Get admin password
ARGO_PSW=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo -e "${GREEN}>>>>>> ArgoCD admin password: $ARGO_PSW <<<<<<${NC}"

#Connect to argocd via port 8080
echo "Starting the server connection..."
sudo kubectl port-forward svc/argocd-server -n argocd 8080:443 &
