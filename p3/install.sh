#!/bin/bash

# ----- Clean Start ----- #

echo "Cleaning previous installations..."

# 1. Docker
echo "Deleting Docker and depedancies..."
sudo systemctl stop docker 2>/dev/null
sudo dpkg --configure -a
sudo apt remove --purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

# 2. K3D
echo "Deleting K3D clusters..."
k3d cluster delete --all 2>/dev/null

# 3. Kubernetes
echo "Deleting Kubernetes configuration files..."
rm -rf ~/.kube/config

echo "------------ Cleaning done ------------"

#!/bin/bash

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

#Create cluster
echo "Creating cluster..."
sudo k3d cluster create IOT-cluster --port 8888:8888@loadbalancer --wait
sleep 10

#Create namespaces
echo "Creating namespaces..."
sudo kubectl create namespace argocd
sudo kubectl create namespace dev

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
sudo kubectl apply -f application.yaml -n argocd

#Connect to argocd via port 8080
echo "Starting the server connection..."
sudo kubectl port-forward svc/argocd-server -n argocd 8080:443


#Get admin password
#kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
