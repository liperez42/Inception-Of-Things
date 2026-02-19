#!/bin/bash

RED='\033[31m'
GREEN='\033[32m'
NC='\033[0m' # No Color

# ----- Clean Start -----
echo "------------ Cleaning previous installations ------------"

#Delete ArgoCD
echo -e "Deleting ArgoCD..."
sudo kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
sudo k3d cluster delete IOT-cluster

echo -e "Deleting ..."
helm uninstall gitlab --namespace gitlab

# Delete Kube config file
echo -e "Deleting Kube config files..."
sudo rm -rf ~/.kube/config
sudo rm -rf /etc/kubernetes

# Delete Kubernetes namespaces
echo -e "Deleting Kubernetes namespaces..."
sudo kubectl delete namespace argocd dev gitlab --ignore-not-found

# Uninstall Helm
echo -e "Uninstall Helm..."
sudo apt-get remove --purge helm -y
sudo rm -f /usr/share/keyrings/helm.gpg
sudo rm -f /etc/apt/sources.list.d/helm-stable-debian.list

# Uninstall K3D
echo -e "Uninstall K3D..."
sudo curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash -s --uninstall

# Removing Docker
echo -e "Deleting Docker..."
sudo systemctl stop docker
sudo dpkg --configure -a
sudo apt remove --purge -y docker-ce docker-ce-cli containerd.io
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

# Apt clean
echo -e "Cleaning apt..."
sudo apt autoremove -y
sudo apt clean

echo -e "${GREEN}------------ Cleaning Done ------------${NC}"

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
echo -e "${GREEN}Docker installation succeeded !${NC}"

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

rm -rf ~/.kube/config
mkdir -p ~/.kube
k3d kubeconfig get IOT-cluster > ~/.kube/config
chmod 600 ~/.kube/config

#Install Helm
sudo apt-get install curl gpg apt-transport-https --yes
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

#Helm repository
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm search repo gitlab 

#Gitlab namespaces
kubectl create namespace gitlab 

#Install Gitlab instance
helm install gitlab gitlab/gitlab \
  --namespace gitlab \
  --set global.hosts.domain=gitlab.local \
  --set certmanager.install=false \
  --set global.ingress.configureCertmanager=false

kubectl wait --for=condition=available deployment

#Install ArgoCD in the namespaces (server-side)
sudo kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo -e "${GREEN}Argocd installation succeeded !${NC}"

#wait pods Argo CD
echo "Waiting for the pods to be ready..."
sudo kubectl wait --for=condition=Ready pods -n argocd --all --timeout=300s

#Apply application
sudo kubectl apply -f ../confs/application.yaml -n argocd

#Connect to argocd via port 8080
echo "Starting the server connection..."
sudo kubectl port-forward svc/argocd-server -n argocd 8080:443


#Get admin password
#kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d