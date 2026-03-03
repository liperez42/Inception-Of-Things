#!/bin/bash

RED='\033[31m'
GREEN='\033[32m'
BLUE='\033[34m'
NC='\033[0m' # No Color

#Install ArgoCD in the namespaces (server-side)
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo -e "${BLUE}Argocd installation succeeded !${NC}"

#wait pods Argo CD
echo -e "${BLUE}Waiting for the pods to be ready...${NC}"
kubectl wait --for=condition=Ready pods -n argocd --all --timeout=300s

#Apply application
kubectl apply -f $PWD/bonus/confs/application.yaml -n argocd

#Get admin password
ARGO_PSW=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo -e "${GREEN}>>>>>> ArgoCD admin password: $ARGO_PSW <<<<<<${NC}"

#Connect to argocd via port 8080
echo -e "${BLUE}Starting the server connection...${NC}"
kubectl port-forward svc/argocd-server -n argocd 8080:443 2>/dev/null &