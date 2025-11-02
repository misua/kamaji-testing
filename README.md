# Kamaji Local Setup - Complete Guide

Multi-tenant Kubernetes using [Kamaji](https://kamaji.clastix.io/) with worker nodes for running actual workloads.

**Time to complete:** 20-25 minutes

---

## 📋 Prerequisites

```bash
# Check you have these installed:
docker --version      # Need 20.10+
kind --version        # Need 0.20.0+
helm version          # Need 3.12.0+
kubectl version       # Need 1.28.0+
vagrant --version     # Need 2.2.0+ (for worker nodes)
```

**Missing tools?** See [docs/PREREQUISITES.md](docs/PREREQUISITES.md)

---

## 🚀 Setup (Copy & Paste)

### Step 1: Install Management Cluster

```bash
# Run the main setup (creates kind cluster + Kamaji + 3 tenant control planes)
./scripts/setup.sh
```

**Takes:** 10-15 minutes  
**Creates:** tcp-dev, tcp-staging, tcp-prod control planes

### Step 2: Verify Installation

```bash
./scripts/verify.sh
```

**Expected:** All green ✓ checks

### Step 3: Extract Kubeconfigs

```bash
# Get access credentials for each tenant
./scripts/06-extract-kubeconfig.sh tcp-dev
./scripts/06-extract-kubeconfig.sh tcp-staging
./scripts/06-extract-kubeconfig.sh tcp-prod
```

**Output:** `scripts/kubeconfigs/tcp-{env}.kubeconfig`

### Step 4: Add Worker Nodes (NEW!)

```bash
# Install prerequisites for worker VMs
sudo apt-get install vagrant libvirt-dev qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
vagrant plugin install vagrant-libvirt
sudo systemctl start libvirtd

# Fix file limits (prevents "too many open files" error)
sudo sysctl fs.inotify.max_user_instances=512
sudo sysctl fs.inotify.max_user_watches=524288

# Create worker VMs (one per tenant)
vagrant up --provider=libvirt

# Join workers to control planes
for tenant in dev staging prod; do
  ./scripts/join-worker.sh ${tenant}
done
```

**Takes:** 10-15 minutes  
**Creates:** 3 VMs (tcp-dev-worker, tcp-staging-worker, tcp-prod-worker)

### Step 5: Verify Workers Joined

```bash
# Check nodes are Ready
for env in dev staging prod; do
  echo "=== tcp-${env} ==="
  kubectl --kubeconfig=scripts/kubeconfigs/tcp-${env}.kubeconfig get nodes
  echo ""
done
```

**Expected:** Each cluster shows one worker node in "Ready" state

### Step 6: Deploy Demo Apps

```bash
# Deploy nginx to all environments
kubectl --kubeconfig=scripts/kubeconfigs/tcp-dev.kubeconfig apply -f manifests/examples/nginx-dev.yaml
kubectl --kubeconfig=scripts/kubeconfigs/tcp-staging.kubeconfig apply -f manifests/examples/nginx-staging.yaml
kubectl --kubeconfig=scripts/kubeconfigs/tcp-prod.kubeconfig apply -f manifests/examples/nginx-prod.yaml

# Wait for pods to run
kubectl --kubeconfig=scripts/kubeconfigs/tcp-dev.kubeconfig get pods -n demo -w
# Press Ctrl+C when Running

# Get LoadBalancer IPs
for env in dev staging prod; do
  echo "=== tcp-${env} ==="
  kubectl --kubeconfig=scripts/kubeconfigs/tcp-${env}.kubeconfig get svc -n demo
  echo ""
done
```

### Step 7: Access Applications

```bash
# Use the EXTERNAL-IP from step 6
curl http://<EXTERNAL-IP>

# Or open in browser: http://<EXTERNAL-IP>
```

**Expected:**
- Dev: Purple page "DEVELOPMENT Environment"
- Staging: Pink page "STAGING Environment"
- Prod: Blue page "PRODUCTION Environment"

---

## 🧹 Cleanup

```bash
# Remove everything (kind cluster + VMs)
./scripts/99-cleanup.sh

# Or remove only worker VMs (keep control planes)
./scripts/08-cleanup-workers.sh
```

---

## 📚 Additional Info

### Architecture

```
Host Machine
├── kind Cluster (Management - Docker)
│   ├── Kamaji Operator
│   ├── cert-manager
│   ├── MetalLB
│   └── Tenant Control Planes (pods)
│       ├── tcp-dev (API, etcd, scheduler, controller)
│       ├── tcp-staging
│       └── tcp-prod
└── Worker VMs (libvirt/KVM)
    ├── tcp-dev-worker → joins tcp-dev
    ├── tcp-staging-worker → joins tcp-staging
    └── tcp-prod-worker → joins tcp-prod
```

### What You Get

- ✅ 3 isolated tenant Kubernetes clusters
- ✅ Each with dedicated control plane (API server, etcd, scheduler)
- ✅ Each with one worker node (VM) for running pods
- ✅ LoadBalancer IPs for services
- ✅ Demo nginx apps showing environment isolation
- ✅ Full kubectl access to each tenant

### Common Commands

```bash
# View all tenant control planes
kubectl get tenantcontrolplanes

# Check control plane pods
kubectl get pods -l 'kamaji.clastix.io/component=control-plane'

# View LoadBalancer IPs
kubectl get svc -l 'kamaji.clastix.io/name'

# SSH into a worker VM
vagrant ssh tcp-dev-worker

# Check kubelet on worker
vagrant ssh tcp-dev-worker -c "sudo systemctl status kubelet"
```

---

## 🔧 Troubleshooting

**Full guide:** [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | [WORKER-SETUP.md](WORKER-SETUP.md)

**Quick fixes:**

```bash
# Pods stuck Pending? Workers not joined yet
for tenant in dev staging prod; do ./scripts/join-worker.sh ${tenant}; done

# "Too many open files"?
sudo sysctl fs.inotify.max_user_instances=512
sudo sysctl fs.inotify.max_user_watches=524288
sudo systemctl restart libvirtd

# Check logs
kubectl logs -n kamaji-system -l control-plane=controller-manager --tail=50
vagrant ssh tcp-dev-worker -c "sudo journalctl -u kubelet -n 50"
```

---

## 📖 References

- [Kamaji Documentation](https://kamaji.clastix.io/)
- [Kamaji GitHub](https://github.com/clastix/kamaji)
- [kind Documentation](https://kind.sigs.k8s.io/)
- [Vagrant Documentation](https://www.vagrantup.com/docs)
