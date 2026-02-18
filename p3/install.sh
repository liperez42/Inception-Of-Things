#!/bin/bash

# ----- Clean Start ----- #

echo "Démarrage du nettoyage des installations précédentes..."

# 1. Supprimer les conteneurs Docker et les configurations
echo "Suppression de Docker et de ses dépendances..."
sudo systemctl stop docker
sudo dpkg --configure -a
sudo apt remove --purge -y docker-ce docker-ce-cli containerd.io
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

# 2. Supprimer les clusters K3D existants
echo "Suppression des clusters K3D..."
sudo k3d cluster list --no-headers | awk '{print $1}' | xargs -I {} sudo k3d cluster delete {}

# 3. Supprimer les namespaces Kubernetes
echo "Suppression des namespaces Kubernetes..."
sudo kubectl delete namespace argocd dev --ignore-not-found

# 4. Supprimer les fichiers de configuration Kubernetes
echo "Suppression des fichiers de configuration Kube..."
sudo rm -rf ~/.kube/config
sudo rm -rf /etc/kubernetes

# 5. Supprimer ArgoCD
echo "Suppression des ressources ArgoCD..."
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 6. Désinstallation de Kubernetes et K3D
echo "Suppression de K3D..."
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash -s --uninstall

# 7. Nettoyage des fichiers résiduels
echo "Nettoyage des fichiers temporaires..."
sudo apt autoremove -y
sudo apt clean

echo "Nettoyage terminé."
echo "------------ Nettoyage terminé ------------"

# Installe les dépendances
sudo apt update
sudo apt install -y ca-certificates curl gnupg

# Ajoute la clé GPG officielle de Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Ajoute le dépôt Docker pour Debian Bookworm
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installe Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sleep 10

#Redemarre Docker
sudo systemctl restart docker
sudo systemctl enable docker
echo "COUCOU COUCOU"

#Adduser
sudo usermod -aG docker $USER
# newgrp docker
echo "HAHAHAHAHAHAHAHAHAH"

#Reinstalle k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo "LALILALA"
sleep 10

#Cree le cluster k3d
echo "Suppression du cluster K3D..."
sudo k3d cluster delete test >> /tmp/k3d_log.txt 2>&1
sleep 10 
echo "Création du cluster K3D..."

echo "Vérification du fichier de log"
ls -l /tmp/k3d_log.txt

while ! kubectl cluster-info > /dev/null 2>&1; do
  echo "En attente de l'initialisation du cluster..."
  sleep 5
done

#Configure kubectl
k3d kubeconfig get IOT-cluster > ~/.kube/config

sleep 10

#Create namespaces
sudo kubectl create namespace argocd
sudo kubectl create namespace dev

sleep 10

#Install ArgoCD in the namespaces (server-side)
sudo kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

#wait pods Argo CD
sudo kubectl wait --for=condition=Ready pods -n argocd --all --timeout=300s