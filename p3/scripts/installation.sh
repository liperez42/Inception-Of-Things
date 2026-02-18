#!/bin/bash

# ----- Clean Start ----- #

echo "Démarrage du nettoyage des installations précédentes..."

echo "Suppression de Docker et de ses dépendances..."
sudo systemctl stop docker
sudo dpkg --configure -a
sudo apt remove --purge -y docker-ce docker-ce-cli containerd.io
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

echo "Suppression des clusters K3D..."
sudo k3d cluster list --no-headers | awk '{print $1}' | xargs -I {} sudo k3d cluster delete {}

echo "Suppression des namespaces Kubernetes..."
sudo kubectl delete namespace argocd dev --ignore-not-found

echo "Suppression des fichiers de configuration Kube..."
sudo rm -rf ~/.kube/config
sudo rm -rf /etc/kubernetes

echo "Suppression des ressources ArgoCD..."
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Suppression de K3D..."
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash -s --uninstall

echo "Nettoyage des fichiers temporaires..."
sudo apt autoremove -y
sudo apt clean

sudo k3d cluster delete IOT-cluster

echo "Nettoyage terminé."
echo "------------ Nettoyage terminé ------------"

#Install Docker
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

#Start Docker
sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl status docker --no-pager

#Adduser
sudo usermod -aG docker $USER
newgrp docker

#Install k3d
echo "lala"
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

#Install  kubectl
echo "ici"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

#Create cluster
echo "ouioui"
sudo k3d cluster create IOT-cluster --port "8080:80@loadbalancer" --port "8888:8888@loadbalancer" --wait
sleep 10

#Create namespaces
sudo kubectl create namespace argocd
sudo kubectl create namespace dev

mkdir -p ~/.kube
k3d kubeconfig get IOT-cluster > ~/.kube/config
chmod 600 ~/.kube/config

kubectl config set-cluster k3d-IOT-cluster --server=https://localhost:35409 --insecure-skip-tls-verify=true

#Install ArgoCD in the namespaces (server-side)
sudo kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

#wait pods Argo CD
sudo kubectl wait --for=condition=Ready pods -n argocd --all --timeout=300s

kubectl port-forward svc/argocd-server -n argocd 8888:443