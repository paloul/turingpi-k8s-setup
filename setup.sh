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

############################################################
# Install Helm - ONLY ON MASTER NODE - ubuntu-rock1
# Fix kubeconfig file to prevent Helm errors
export KUBECONFIG=~/.kube/config
mkdir ~/.kube 2> /dev/null
sudo k3s kubectl config view --raw > "$KUBECONFIG"
chmod 600 "$KUBECONFIG"
echo "KUBECONFIG=$KUBECONFIG" >> /etc/environment

# Create a directory for Helm and navigate into it
mkdir ~/helm && cd helm
# Download Helm installer
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
# Modify permissions for execution
chmod 700 get_helm.sh
# Install Helm
./get_helm.sh

# Verify Helm installation
helm version
############################################################


############################################################
# Install MetalLB - https://metallb.universe.tf/ 
# DO THIS ONLY ON MASTER NODE
# Add MetalLB repository to Helm
helm repo add metallb https://metallb.github.io/metallb

# Check the added repository
helm search repo metallb

# Install metallb with helm
helm upgrade --install metallb metallb/metallb --create-namespace --namespace metallb-system --wait

# Assign IP range for MetalLB from yaml file
kubectl apply -f metallb.yaml

############################################################


############################################################
# Install Longhorn 
# On each node, ensure nfs-common, open-iscsi, and util-linux are installed
apt -y install nfs-common open-iscsi util-linux

# Ensure mount points and a directory are set up for SSDs installed and
# available to each rock-ubuntu host

# Install Longhorn - https://longhorn.io/
# DO THIS ONLY ON THE MASTER NODE
# Add longhorn to the helm  
helm repo add longhorn https://charts.longhorn.io

# Install Longhorn with the UI portal enabled and made available
# via a loadbalancer with the help of MetalLB
# The load balancer IP parameter should be from the pool available to metalLB
# The default data path should point to the mounted location of the SSD /dev/nvme0n1p1->/mnt/nvme0->/data
helm install longhorn longhorn/longhorn --namespace longhorn-system \
 --create-namespace --set defaultSettings.defaultDataPath="/data" \
 --set service.ui.loadBalancerIP="192.168.70.11" --set service.ui.type="LoadBalancer"

############################################################


