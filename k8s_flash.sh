#!/bin/bash

# This script sets up a Kubernetes control plane server using kubeadm.
# Author: Mir Islam <mislam@mirislam.com>
# Distro: Ubuntu 22.04.1 LTS
# CPU/Mem: 4vCPU/4GiB

# Reference: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/

# NOTE: Update to the latest security patches before proceeding.
# sudo apt-get update && sudo apt-get upgrade

# Step 1: Disable swap
sudo sh -c 'grep -v swap /etc/fstab > /tmp/fstab.new; mv /tmp/fstab.new /etc/fstab'
sudo swapoff -a

# Step 2: Configure port forwarding and enable br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/modules-load.d/br-netfilter.conf
br_netfilter
EOF

sudo sh -c 'echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables'

# Step 3: Apply sysctl settings without reboot
sudo sysctl --system

# Step 4: Install containerd
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

# Install Docker and containerd
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Step 5: Verify Docker installation
sudo docker run hello-world

# Step 6: Update containerd configuration to use systemd
sudo sh -c 'containerd config default > /etc/containerd/config.toml'
sudo sed -i -e "s/SystemdCgroup = false/SystemdCgroup = true/g" /etc/containerd/config.toml

# Step 7: Restart containerd
sudo systemctl restart containerd

# Step 8: Install kubeadm, kubelet, and kubectl
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Step 9: Enable and start kubelet
sudo systemctl enable --now kubelet

# if this a node exit out now
if [ "$1" = "node" ]; then
    echo "This is a node. Not running kubeadm init"
    exit 0
fi

# Step 10: Initialize the Kubernetes control plane
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Step 11: Configure kubectl for the current user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Step 12: Install a CNI (Flannel)
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Sleep 10
echo Sleeping 10 seconds for pods to startup
sleep 10

# Verify installation. 8 pods should be running
kubectl get pods --all-namespaces

# Congratulations! Your control plane server setup is complete.

# To create a worker node, follow steps 1 to 9 on the worker node.
# Or run this script with the "node" argument
# Then, run the following command on the control plane node:
# sudo kubeadm token create --print-join-command
# Copy and run the output command on the worker node to join the cluster.

