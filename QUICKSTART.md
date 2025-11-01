# Kamaji Local Setup - Quick Start Guide

**Complete setup in 5 steps. Estimated time: 15 minutes.**

---

## Prerequisites Check

Verify you have the required tools installed:

```bash
docker --version    # Should be 20.10+
kind --version      # Should be 0.20.0+
helm version        # Should be 3.12.0+
kubectl version --client  # Should be 1.28.0+
```

If any tool is missing, see [docs/PREREQUISITES.md](docs/PREREQUISITES.md) for installation instructions.

---

## Step 1: Run the Setup Script

This single command installs everything (kind cluster, cert-manager, MetalLB, Kamaji, and 3 tenant control planes):

```bash
./scripts/setup.sh
```

**What it does:**
- Creates kind cluster named "kamaji"
- Installs cert-manager for TLS certificates
- Installs MetalLB for LoadBalancer support
- Installs Kamaji operator
- Deploys 3 tenant control planes: tcp-dev, tcp-staging, tcp-prod

**Expected output:** Green success messages for each step. Takes 10-15 minutes.

---

## Step 2: Verify Installation

Check that all components are healthy:

```bash
./scripts/verify.sh
```

**Expected output:** All checks should show green ✓ marks.

---

## Step 3: Extract Kubeconfigs

Get kubeconfig files for each tenant cluster:

```bash
# Extract all three kubeconfigs
./scripts/06-extract-kubeconfig.sh tcp-dev
./scripts/06-extract-kubeconfig.sh tcp-staging
./scripts/06-extract-kubeconfig.sh tcp-prod
```

**Output location:** `./kubeconfigs/tcp-dev.kubeconfig`, `tcp-staging.kubeconfig`, `tcp-prod.kubeconfig`

---

## Step 4: Access a Tenant Cluster

Use the dev cluster as an example:

```bash
# Set kubeconfig
export KUBECONFIG=./kubeconfigs/tcp-dev.kubeconfig

# Check cluster access
kubectl cluster-info

# View nodes (control plane only, no workers yet)
kubectl get nodes

# Create a test namespace
kubectl create namespace test

# List namespaces
kubectl get namespaces
```

**Switch to other clusters:**

```bash
# Staging
export KUBECONFIG=./kubeconfigs/tcp-staging.kubeconfig
kubectl get nodes

# Prod
export KUBECONFIG=./kubeconfigs/tcp-prod.kubeconfig
kubectl get nodes
```

---

## Step 5: View Management Cluster Resources

Switch back to the management cluster to see all tenant control planes:

```bash
# Unset tenant kubeconfig
unset KUBECONFIG

# View all tenant control planes
kubectl get tenantcontrolplanes

# View tenant control plane pods
kubectl get pods -l 'kamaji.clastix.io/component=control-plane'

# View LoadBalancer services and IPs
kubectl get svc -l 'kamaji.clastix.io/name'

# View all resources
kubectl get all -A
```

---

## Step 6: Explore Multi-Tenancy (Optional)

Deploy resources to each environment to see complete isolation:

```bash
# Deploy to DEV
export KUBECONFIG=./kubeconfigs/tcp-dev.kubeconfig
kubectl create namespace demo
kubectl create deployment nginx --image=nginx:alpine -n demo
kubectl get all -n demo

# Deploy to STAGING
export KUBECONFIG=./kubeconfigs/tcp-staging.kubeconfig
kubectl create namespace demo
kubectl create deployment nginx --image=nginx:alpine --replicas=2 -n demo
kubectl get all -n demo

# Deploy to PROD
export KUBECONFIG=./kubeconfigs/tcp-prod.kubeconfig
kubectl create namespace demo
kubectl create deployment nginx --image=nginx:alpine --replicas=3 -n demo
kubectl get all -n demo
```

### Verify Complete Isolation

Each cluster is completely isolated - resources in one don't affect the others:

```bash
# Check DEV
export KUBECONFIG=./kubeconfigs/tcp-dev.kubeconfig
kubectl get namespaces
kubectl get deployments -A

# Check STAGING (different resources)
export KUBECONFIG=./kubeconfigs/tcp-staging.kubeconfig
kubectl get namespaces
kubectl get deployments -A

# Check PROD (different resources)
export KUBECONFIG=./kubeconfigs/tcp-prod.kubeconfig
kubectl get namespaces
kubectl get deployments -A
```

### Understanding Control Planes vs Worker Nodes

**Important:** These tenant clusters are **control planes only** - they don't have worker nodes yet. This means:

- ✅ You can create resources (deployments, services, etc.)
- ✅ The API server accepts and stores them
- ✅ Each cluster is completely isolated
- ❌ Pods will stay in "Pending" state (no nodes to schedule on)

To see this:

```bash
export KUBECONFIG=./kubeconfigs/tcp-dev.kubeconfig

# No nodes (control plane only)
kubectl get nodes

# Pods are pending (no nodes to run on)
kubectl get pods -n demo

# But the deployment exists
kubectl get deployment -n demo
```

**This demonstrates Kamaji's multi-tenancy perfectly** - each tenant gets their own isolated Kubernetes API and control plane. Adding worker nodes is covered in the advanced documentation.

---

## What You Have Now

✅ **Management Cluster:** kind cluster running on Docker  
✅ **3 Tenant Control Planes:** Isolated Kubernetes control planes (dev, staging, prod)  
✅ **LoadBalancer IPs:** Each tenant has its own IP address  
✅ **Kubeconfigs:** Access credentials for each tenant cluster  
✅ **Demo Apps:** Nginx deployments with unique content per environment  

---

## Common Commands Reference

```bash
# View tenant control planes
kubectl get tenantcontrolplanes

# Check a specific tenant status
kubectl describe tenantcontrolplane tcp-dev

# View all pods in management cluster
kubectl get pods -A

# Extract kubeconfig for any tenant
./scripts/06-extract-kubeconfig.sh <tenant-name>

# Verify everything is healthy
./scripts/verify.sh

# Clean up everything
./scripts/99-cleanup.sh
```

---

## Next Steps

### Test Multi-Tenancy

Deploy the same application to all three clusters:

```bash
# Deploy to dev
export KUBECONFIG=./kubeconfigs/tcp-dev.kubeconfig
kubectl create deployment nginx --image=nginx
kubectl get pods

# Deploy to staging
export KUBECONFIG=./kubeconfigs/tcp-staging.kubeconfig
kubectl create deployment nginx --image=nginx
kubectl get pods

# Deploy to prod
export KUBECONFIG=./kubeconfigs/tcp-prod.kubeconfig
kubectl create deployment nginx --image=nginx
kubectl get pods
```

### Create Additional Tenant

```bash
# Copy existing manifest
cp manifests/tenant-control-planes/tcp-dev.yaml manifests/tenant-control-planes/tcp-test.yaml

# Edit the file (change name from tcp-dev to tcp-test)
sed -i 's/tcp-dev/tcp-test/g' manifests/tenant-control-planes/tcp-test.yaml

# Apply
kubectl apply -f manifests/tenant-control-planes/tcp-test.yaml

# Wait for ready
kubectl wait --for=condition=Ready tenantcontrolplane tcp-test --timeout=600s

# Extract kubeconfig
./scripts/06-extract-kubeconfig.sh tcp-test
```

---

## Troubleshooting

**If setup fails:**
1. Check error messages in the terminal
2. Run `./scripts/verify.sh` to identify the issue
3. See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for detailed solutions
4. Clean up and retry: `./scripts/99-cleanup.sh` then `./scripts/setup.sh`

**Common issues:**
- **Docker not running:** Start Docker Desktop
- **Insufficient resources:** Allocate more CPU/RAM to Docker (need 4+ CPUs, 8+ GB RAM)
- **Port conflicts:** Check if port 6443 is already in use

---

## Cleanup

When you're done, remove everything:

```bash
./scripts/99-cleanup.sh
```

This deletes the kind cluster and all resources. You can run `./scripts/setup.sh` again anytime to recreate.

---

## Documentation

- **Full README:** [README.md](README.md)
- **Prerequisites:** [docs/PREREQUISITES.md](docs/PREREQUISITES.md)
- **Troubleshooting:** [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- **Kamaji Docs:** https://kamaji.clastix.io/

---

**That's it! You now have a working Kamaji multi-tenant Kubernetes environment running locally.** 🎉
