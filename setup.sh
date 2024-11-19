#!/bin/bash

# Setup Master Node on ubuntu-rock1
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --disable servicelb --token kelda-araneae --node-ip 192.168.68.68 --disable-cloud-controller --disable local-storage 

# Setup Worker nodes ubuntu-rock2, ubuntu-rock3, ubuntu-rock4
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.68.68:6443 K3S_TOKEN=kelda-araneae sh -

# Set worker labels on all
kubectl label nodes ubuntu-rock1 kubernetes.io/role=worker
kubectl label nodes ubuntu-rock2 kubernetes.io/role=worker
kubectl label nodes ubuntu-rock3 kubernetes.io/role=worker
kubectl label nodes ubuntu-rock4 kubernetes.io/role=worker