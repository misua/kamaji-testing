# Kamaji Local Setup with Kind

A complete local development environment for [Kamaji](https://kamaji.clastix.io/) - a Kubernetes Control Plane Manager that enables multi-tenant Kubernetes clusters.

## Quick Start

### Prerequisites

Ensure you have the following installed:
- Docker 20.10+
- kind 0.20.0+
- Helm 3.12.0+
- kubectl 1.28.0+

See [docs/PREREQUISITES.md](docs/PREREQUISITES.md) for detailed requirements.

### Installation

Run the automated setup script:

```bash
./scripts/setup.sh
```

This will:
1. Create a kind cluster named "kamaji"
2. Install cert-manager for TLS certificates
3. Install MetalLB for LoadBalancer support
4. Install the Kamaji operator
5. Deploy three tenant control planes (dev, staging, prod)

**Estimated time:** 10-15 minutes

### Verify Installation

```bash
./scripts/verify.sh
```

### Access Tenant Clusters

Extract kubeconfig for each tenant:

```bash
# Dev environment
./scripts/06-extract-kubeconfig.sh tcp-dev
export KUBECONFIG=./kubeconfigs/tcp-dev.kubeconfig
kubectl get nodes

# Staging environment
./scripts/06-extract-kubeconfig.sh tcp-staging
export KUBECONFIG=./kubeconfigs/tcp-staging.kubeconfig
kubectl get nodes

# Prod environment
./scripts/06-extract-kubeconfig.sh tcp-prod
export KUBECONFIG=./kubeconfigs/tcp-prod.kubeconfig
kubectl get nodes
```

## Architecture

```
Docker Host
└── kind Cluster (Management)
    ├── Kamaji Operator
    ├── cert-manager
    ├── MetalLB
    └── Tenant Control Planes (3 clusters)
        ├── tcp-dev (LoadBalancer IP: x.x.x.200)
        │   ├── API Server (pod)
        │   ├── Controller Manager (pod)
        │   ├── Scheduler (pod)
        │   └── etcd (pod)
        ├── tcp-staging (LoadBalancer IP: x.x.x.201)
        │   └── ... (same components)
        └── tcp-prod (LoadBalancer IP: x.x.x.202)
            └── ... (same components)
```

## What is Kamaji?

Kamaji is a Kubernetes Control Plane Manager that:
- Runs Kubernetes control planes as pods within a management cluster
- Enables multi-tenancy with isolated control planes
- Reduces operational overhead and resource consumption
- Provides a lightweight alternative to dedicated control plane VMs

## Directory Structure

```
.
├── scripts/                    # Automation scripts
│   ├── setup.sh               # Master setup script
│   ├── 01-create-kind-cluster.sh
│   ├── 02-install-cert-manager.sh
│   ├── 03-install-metallb.sh
│   ├── 04-install-kamaji.sh
│   ├── 05-deploy-tenant-control-planes.sh
│   ├── 06-extract-kubeconfig.sh
│   ├── verify.sh              # Verification script
│   └── 99-cleanup.sh          # Cleanup script
├── manifests/
│   └── tenant-control-planes/ # TCP manifests
│       ├── tcp-dev.yaml
│       ├── tcp-staging.yaml
│       └── tcp-prod.yaml
├── docs/                      # Documentation
│   ├── PREREQUISITES.md
│   └── TROUBLESHOOTING.md
└── README.md                  # This file
```

## Common Tasks

### View Tenant Control Planes

```bash
kubectl get tenantcontrolplanes
kubectl describe tenantcontrolplane tcp-dev
```

### View Services and IPs

```bash
kubectl get svc -l 'kamaji.clastix.io/name'
```

### Check Component Status

```bash
# cert-manager
kubectl get pods -n certmanager-system

# MetalLB
kubectl get pods -n metallb-system

# Kamaji
kubectl get pods -n kamaji-system

# Tenant control planes
kubectl get pods -l 'kamaji.clastix.io/component=control-plane'
```

### Create Additional Tenant

1. Copy an existing manifest:
   ```bash
   cp manifests/tenant-control-planes/tcp-dev.yaml manifests/tenant-control-planes/tcp-custom.yaml
   ```

2. Edit the manifest (change `metadata.name` and labels)

3. Apply:
   ```bash
   kubectl apply -f manifests/tenant-control-planes/tcp-custom.yaml
   ```

4. Wait for ready:
   ```bash
   kubectl wait --for=condition=Ready tenantcontrolplane tcp-custom --timeout=600s
   ```

5. Extract kubeconfig:
   ```bash
   ./scripts/06-extract-kubeconfig.sh tcp-custom
   ```

### Cleanup

Remove everything:

```bash
./scripts/99-cleanup.sh
```

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues and solutions.

### Quick Diagnostics

```bash
# Check all pods
kubectl get pods -A

# Check events
kubectl get events -A --sort-by='.lastTimestamp'

# Check tenant control plane status
kubectl describe tenantcontrolplane tcp-dev

# Check Kamaji logs
kubectl logs -n kamaji-system -l control-plane=controller-manager --tail=100
```

## Resource Consumption

### Typical Usage (3 Tenant Control Planes)
- **CPU**: ~2.5 cores total
- **RAM**: ~5 GB total
- **Disk**: ~10 GB

### Per Component
- Management cluster: ~1 core, ~2 GB RAM
- Per tenant control plane: ~0.5 cores, ~1 GB RAM

## Limitations

- **Local development only** - not suitable for production
- **Single-node kind cluster** - no high availability
- **Resource constraints** - limited by Docker resources
- **No worker nodes** - tenant clusters have control planes only

## Next Steps

- **Add worker nodes**: Join worker nodes to tenant clusters
- **Monitoring**: Add Prometheus/Grafana for observability
- **GitOps**: Integrate with Flux for automated deployments
- **Alternative datastores**: Try MySQL or PostgreSQL instead of etcd

## References

- [Kamaji Documentation](https://kamaji.clastix.io/)
- [Kamaji on Kind Guide](https://kamaji.clastix.io/getting-started/kamaji-kind/)
- [Kamaji GitHub](https://github.com/clastix/kamaji)
- [kind Documentation](https://kind.sigs.k8s.io/)

## License

This project follows the same license as Kamaji (Apache 2.0).
