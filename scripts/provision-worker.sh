#!/usr/bin/env bash
set -euo pipefail

# Provision script for Kamaji worker nodes
# This runs inside the VM to set up kubelet and join the tenant control plane

TENANT=$1
WORKER_NAME="tcp-${TENANT}-worker"

echo "==> Provisioning worker node for tenant: ${TENANT}"

# Install required packages
echo "==> Installing dependencies..."
apt-get update -qq
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    socat \
    conntrack \
    ipset \
    >/dev/null 2>&1

# Install containerd
echo "==> Installing containerd..."
apt-get install -y containerd >/dev/null 2>&1

# Configure containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

# Enable systemd cgroup driver
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Restart containerd
systemctl restart containerd
systemctl enable containerd

# Install Kubernetes components (v1.28.0 to match tenant control planes)
echo "==> Installing Kubernetes components..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | \
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | \
    tee /etc/apt/sources.list.d/kubernetes.list

apt-get update -qq
apt-get install -y kubelet=1.28.0-1.1 kubectl=1.28.0-1.1 >/dev/null 2>&1
apt-mark hold kubelet kubectl

# Disable swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Enable IP forwarding
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

modprobe br_netfilter
sysctl --system >/dev/null 2>&1

echo "==> Worker node provisioned successfully"
echo "==> Ready to join tenant control plane: tcp-${TENANT}"
