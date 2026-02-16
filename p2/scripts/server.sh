#! /bin/sh

apt-get update
apt-get install -y curl

export INSTALL_K3S_EXEC="server --write-kubeconfig-mode 644 --advertise-address=192.168.56.110 --node-ip=192.168.56.110"
curl -sfL https://get.k3s.io | sh -

sleep 10

cp /vagrant/confs/app.yaml /home/vagrant
cp /vagrant/confs/service.yaml /home/vagrant
cp /vagrant/confs/ingress.yaml /home/vagrant

kubectl apply -f /home/vagrant/app.yaml
kubectl apply -f /home/vagrant/service.yaml
kubectl apply -f /home/vagrant/ingress.yaml
