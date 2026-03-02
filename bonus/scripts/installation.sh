#!/bin/bash

RED='\033[31m'
GREEN='\033[32m'
NC='\033[0m' # No Color

# ----- Clean Start -----
echo "------------ Cleaning previous installations ------------"

# Delete ArgoCD
echo -e "Deleting ArgoCD..."
if kubectl get ns argocd &> /dev/null; then
  sudo kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
fi
if k3d cluster list | grep -q "IOT-cluster"; then
  sudo k3d cluster delete IOT-cluster
fi

# Uninstall gitlab
echo -e "Uninstall gitlab..."
if helm list -n gitlab &> /dev/null; then
  helm uninstall gitlab --namespace gitlab
fi

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
if command -v helm &> /dev/null; then
  sudo systemctl stop docker
  sudo dpkg --configure -a
  sudo apt remove --purge -y docker-ce docker-ce-cli containerd.io
  sudo rm -rf /var/lib/docker
  sudo rm -rf /var/lib/containerd
fi

# Apt clean
echo -e "Cleaning apt..."
sudo apt autoremove -y
sudo apt clean

echo -e "${GREEN}------------ Cleaning Done ------------${NC}"

# exit

# ----- Instalations -----

#Install Docker
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
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
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

#Install  kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

kubectl config set-cluster k3d-IOT-cluster --insecure-skip-tls-verify=true --server=https://0.0.0.0:6443

# ----- Create and config K3D cluster -----

#Create cluster
echo "Creating cluster..."
k3d cluster create IOT-cluster --port "8888:8888@loadbalancer" --wait
sleep 10

#Create namespaces
echo "Creating namespaces..."
kubectl create namespace argocd
kubectl create namespace dev
kubectl create namespace gitlab 

#k3d config
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

#Helm gitlab repository
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm search repo gitlab 

#Install Gitlab instance
helm install gitlab gitlab/gitlab -f confs/gitlab-values.yaml --namespace gitlab

kubectl wait --for=condition=Ready pods -n gitlab --all --timeout=300s 

#Get gitlab password
GITLAB_PSW=$(kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" | base64 -d)
echo -e "${GREEN}>>>>>> Gitlab root password: $GITLAB_PSW <<<<<<${NC}"

sudo kubectl port-forward -n gitlab svc/gitlab-webservice-default 80:8181 &