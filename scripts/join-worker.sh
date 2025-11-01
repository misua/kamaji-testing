#!/usr/bin/env bash
set -euo pipefail

# Script to join a worker VM to its tenant control plane
# Runs on the host machine, copies kubeconfig to VM and configures kubelet

TENANT=$1
WORKER_NAME="tcp-${TENANT}-worker"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KUBECONFIG="${SCRIPT_DIR}/kubeconfigs/tcp-${TENANT}.kubeconfig"

echo "==> Joining ${WORKER_NAME} to tcp-${TENANT} control plane"

# Check if kubeconfig exists
if [ ! -f "${KUBECONFIG}" ]; then
    echo "Error: Kubeconfig not found: ${KUBECONFIG}"
    echo "Run: ./06-extract-kubeconfig.sh tcp-${TENANT}"
    exit 1
fi

# Get control plane endpoint
CP_ENDPOINT=$(kubectl --kubeconfig="${KUBECONFIG}" cluster-info 2>/dev/null | \
    grep "Kubernetes control plane" | \
    sed 's/\x1b\[[0-9;]*m//g' | \
    awk '{print $NF}')

echo "Control plane endpoint: ${CP_ENDPOINT}"

# Get the VM's IP address
VM_IP=$(vagrant ssh "${WORKER_NAME}" -c "hostname -I | awk '{print \$2}'" 2>/dev/null | tr -d '\r')

if [ -z "${VM_IP}" ]; then
    echo "Error: Could not get VM IP address"
    exit 1
fi

echo "Worker VM IP: ${VM_IP}"

# Copy kubeconfig to VM
echo "==> Copying kubeconfig to worker..."
vagrant upload "${KUBECONFIG}" /tmp/kubelet.conf "${WORKER_NAME}"

# Configure kubelet on the worker
echo "==> Configuring kubelet..."
vagrant ssh "${WORKER_NAME}" -c "sudo bash -s" <<'EOSSH'
# Move kubeconfig to proper location
mkdir -p /etc/kubernetes
mv /tmp/kubelet.conf /etc/kubernetes/kubelet.conf
chmod 600 /etc/kubernetes/kubelet.conf

# Create kubelet directories
mkdir -p /var/lib/kubelet

# Create kubelet configuration
cat > /var/lib/kubelet/config.yaml <<EOF
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
clusterDomain: cluster.local
clusterDNS:
  - 10.96.0.10
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
    cacheTTL: 2m0s
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 5m0s
    cacheUnauthorizedTTL: 30s
serverTLSBootstrap: true
tlsCertFile: ""
tlsPrivateKeyFile: ""
EOF

# Create kubelet service drop-in
mkdir -p /etc/systemd/system/kubelet.service.d
cat > /etc/systemd/system/kubelet.service.d/10-kubeadm.conf <<EOF
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
Environment="KUBELET_EXTRA_ARGS=--container-runtime-endpoint=unix:///run/containerd/containerd.sock"
ExecStart=
ExecStart=/usr/bin/kubelet \$KUBELET_KUBECONFIG_ARGS \$KUBELET_CONFIG_ARGS \$KUBELET_EXTRA_ARGS
EOF

# Reload and start kubelet
systemctl daemon-reload
systemctl enable kubelet
systemctl restart kubelet

echo "Kubelet started and configured"
EOSSH

echo "==> Worker ${WORKER_NAME} joined successfully"
echo "==> Check status with: kubectl --kubeconfig=${KUBECONFIG} get nodes"
