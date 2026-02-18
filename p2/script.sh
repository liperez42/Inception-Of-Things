sudo apt update && sudo apt upgrade -y
sudo apt install curl -y

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --write-kubeconfig-mode 644 --node-ip=192.168.56.110" sh -

sleep 10

cp /vagrant/config/ingress.yaml /home/vagrant/ingress.yaml
cp /vagrant/config/deployment.yaml /home/vagrant/deployment.yaml
cp /vagrant/config/service.yaml /home/vagrant/service.yaml

kubectl apply -f ingress.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml