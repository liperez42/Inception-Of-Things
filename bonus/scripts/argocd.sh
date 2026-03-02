#Install ArgoCD in the namespaces (server-side)
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo "Argocd installation succeeded !"

#wait pods Argo CD
echo "Waiting for the pods to be ready..."
kubectl wait --for=condition=Ready pods -n argocd --all --timeout=300s

#Apply application
kubectl apply -f /home/liperez/iot/bonus/confs/application.yaml -n argocd

xdg-open http://localhost:8080 & xdg-open http://gitlab.local &

#Get admin password
ARGO_PSW=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo -e "${GREEN}>>>>>> ArgoCD admin password: $ARGO_PSW <<<<<<${NC}"

#Connect to argocd via port 8080
echo "Starting the server connection..."
kubectl port-forward svc/argocd-server -n argocd 8080:443 2>/dev/null &