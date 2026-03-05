#!/bin/bash

RED='\033[31m'
GREEN='\033[32m'
BLUE='\033[34m'
NC='\033[0m' # No Color

# ----- Clean Start -----
sudo ./bonus/scripts/clean.sh

# ----- Instalations -----

#Install Docker
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
echo -e "${BLUE}Docker installation succeeded !${NC}"

#Start Docker
echo -e "${BLUE}Starting docker...${NC}"
sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl status docker --no-pager

#Install k3d
echo -e "${BLUE}Installing k3d...${NC}"
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

#Install  kubectl
echo -e "${BLUE}Installing kubectl...${NC}"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

kubectl config set-cluster k3d-IOT-cluster --insecure-skip-tls-verify=true --server=https://0.0.0.0:6443

# ----- Create and config K3D cluster -----

#Create cluster
echo -e "${BLUE}Creating cluster...${NC}"
k3d cluster create IOT-cluster --port "8888:8888@loadbalancer" --wait
sleep 10

#Create namespaces
echo -e "${BLUE}Creating namespaces...${NC}"
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
helm install gitlab gitlab/gitlab -f $PWD/bonus/confs/gitlab-values.yaml --namespace gitlab

kubectl wait --for=condition=Ready pods -n gitlab --all --timeout=300s 

#Get gitlab password
GITLAB_PSW=$(kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" | base64 -d)
echo -e "${GREEN}>>>>>> Gitlab root password: $GITLAB_PSW <<<<<<${NC}"
echo "export GITLAB_PSW='$GITLAB_PSW'" > /tmp/gitlab_vars.sh

sudo kubectl port-forward -n gitlab svc/gitlab-webservice-default 80:8181 &
