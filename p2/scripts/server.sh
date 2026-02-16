#!/bin/sh

apt-get update && apt-get upgrade
apt-get install -y curl

curl -sfL https://get.k3s.io | sh -

sleep 10 

cp /vagrant/confs/app.yaml /home/vagrant/
cp /vagrant/confs/ingress.yaml /home/vagrant/

kubectl apply -f /home/vagrant/app.yaml
kubectl apply -f /home/vagrant/ingress.yaml
