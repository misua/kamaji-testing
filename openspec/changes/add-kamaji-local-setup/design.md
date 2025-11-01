# Design: Kamaji Local Setup with Kind

## Context
Kamaji is a Kubernetes Control Plane Manager that runs control plane components as pods within a management cluster. This design enables local development using kind, which creates Kubernetes clusters using Docker containers as nodes.

**Background:**
- Kamaji requires a management cluster to host tenant control planes
- kind provides a lightweight, fast way to run Kubernetes locally
- MetalLB is needed because kind doesn't natively support LoadBalancer services
- cert-manager handles TLS certificates for Kamaji's webhook configurations

**Constraints:**
- Must run on developer workstations (Linux, macOS, Windows with WSL2)
- Limited to Docker resources available on local machine
- Not suitable for production use - development/learning only

## Goals / Non-Goals

**Goals:**
- Provide reproducible local Kamaji environment
- Enable creation of multiple tenant control planes
- Support testing and learning workflows
- Minimize resource consumption
- Automate setup as much as possible

**Non-Goals:**
- Production-grade high availability
- Multi-node kind cluster (single node sufficient)
- Integration with external cloud providers
- Performance benchmarking infrastructure
- CI/CD pipeline integration (can be added later)

## Decisions

### Decision 1: Use kind over minikube/k3d
**Why:** kind is officially supported by Kamaji documentation, has good Docker integration, and is widely used in Kubernetes development.

**Alternatives considered:**
- minikube: More features but heavier, slower startup
- k3d: Lightweight but less documentation for Kamaji use case
- Docker Desktop Kubernetes: Limited configurability

### Decision 2: Use Bitnami cert-manager Helm chart
**Why:** Kamaji documentation references Bitnami charts, provides consistent installation method.

**Alternatives considered:**
- Official cert-manager manifests: More complex, manual CRD management
- Jetstack Helm chart: Similar but Bitnami is in official docs

### Decision 3: MetalLB for LoadBalancer support
**Why:** Required for exposing tenant control planes with LoadBalancer service type. MetalLB is the standard solution for bare-metal/kind environments.

**Alternatives considered:**
- NodePort services: Less realistic, requires port management
- Ingress only: Doesn't match typical Kamaji deployment patterns
- Port forwarding: Manual, not scalable for multiple tenants

### Decision 4: Script-based automation
**Why:** Shell scripts are simple, portable, and easy to understand for infrastructure setup.

**Alternatives considered:**
- Makefile: Less portable across platforms
- Ansible: Overkill for local setup
- Terraform: Not designed for local kind clusters

### Decision 5: Use default etcd datastore
**Why:** Simplest setup for local development. Alternative datastores (MySQL, PostgreSQL, NATS) add complexity.

**Alternatives considered:**
- MySQL/PostgreSQL: Requires additional containers, configuration
- NATS: Less common, more complex setup

## Architecture

```
┌─────────────────────────────────────────────────┐
│  Docker Host (Developer Workstation)            │
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │  kind Cluster (Management Cluster)         │ │
│  │                                             │ │
│  │  ┌──────────────────┐                      │ │
│  │  │  Kamaji Operator │                      │ │
│  │  └──────────────────┘                      │ │
│  │                                             │ │
│  │  ┌──────────────────┐  ┌─────────────────┐│ │
│  │  │  cert-manager    │  │  MetalLB        ││ │
│  │  └──────────────────┘  └─────────────────┘│ │
│  │                                             │ │
│  │  ┌─────────────────────────────────────┐  │ │
│  │  │  Tenant Control Planes (Pods)       │  │ │
│  │  │  ┌─────────┐  ┌─────────┐           │  │ │
│  │  │  │ TCP-1   │  │ TCP-2   │  ...      │  │ │
│  │  │  │ (etcd)  │  │ (etcd)  │           │  │ │
│  │  │  │ api-srv │  │ api-srv │           │  │ │
│  │  │  │ ctrl-mgr│  │ ctrl-mgr│           │  │ │
│  │  │  │ sched   │  │ sched   │           │  │ │
│  │  │  └─────────┘  └─────────┘           │  │ │
│  │  └─────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

## Component Details

### 1. Kind Cluster
- Single-node cluster named "kamaji"
- Uses default kind configuration
- Provides local-path-provisioner for storage

### 2. cert-manager
- Namespace: `certmanager-system`
- Manages TLS certificates for Kamaji webhooks
- Installed via Bitnami Helm chart

### 3. MetalLB
- Namespace: `metallb-system`
- Provides LoadBalancer IP allocation
- IP pool derived from kind Docker network (e.g., 172.19.255.200-250)
- L2Advertisement for local network

### 4. Kamaji
- Namespace: `kamaji-system`
- Installed via Clastix Helm chart
- Manages TenantControlPlane CRDs
- Default datastore uses etcd

### 5. Tenant Control Planes
- Created via TenantControlPlane custom resources
- Each TCP runs as a set of pods in the management cluster
- Exposed via LoadBalancer services
- kubeconfig extracted from secrets

## Risks / Trade-offs

### Risk: Docker resource exhaustion
**Impact:** Multiple tenant control planes may consume significant CPU/memory
**Mitigation:** 
- Document resource requirements
- Provide cleanup scripts
- Recommend limiting number of concurrent TCPs

### Risk: IP address pool conflicts
**Impact:** MetalLB IP pool may conflict with existing Docker networks
**Mitigation:**
- Auto-detect kind network gateway
- Use high IP range (x.x.255.200-250) to avoid conflicts
- Document manual override procedure

### Risk: Version compatibility
**Impact:** Kamaji, cert-manager, MetalLB versions may become incompatible
**Mitigation:**
- Pin specific versions in scripts
- Document tested version combinations
- Provide upgrade path documentation

### Trade-off: Single-node vs multi-node
**Decision:** Use single-node kind cluster
**Rationale:** Simpler setup, sufficient for development, faster startup
**Cost:** Cannot test node affinity, multi-zone scenarios

### Trade-off: Automation vs flexibility
**Decision:** Provide both automated scripts and manual steps
**Rationale:** Scripts for quick setup, manual steps for learning
**Cost:** More documentation to maintain

## Migration Plan

N/A - This is a new capability with no existing state to migrate.

## Rollback Plan

Complete cleanup:
```bash
kind delete cluster --name kamaji
docker network prune  # if needed
```

## Testing Strategy

### Verification Steps
1. Cluster creation succeeds
2. All system pods reach Running state
3. Kamaji CRDs are installed
4. MetalLB assigns IP addresses
5. Tenant control plane can be created
6. kubeconfig can be extracted and used
7. kubectl commands work against tenant cluster

### Test Scenarios
- Create single tenant control plane
- Create multiple tenant control planes
- Delete and recreate tenant control planes
- Verify resource isolation
- Test kubeconfig access

## Open Questions

1. **Should we support worker node joining?**
   - Requires additional kind clusters or external nodes
   - Adds complexity but provides more realistic testing
   - **Decision:** Document as optional advanced scenario

2. **Should we include monitoring/observability?**
   - Prometheus, Grafana could be useful
   - Adds resource overhead
   - **Decision:** Provide as optional add-on, not in base setup

3. **Should we automate tenant control plane creation?**
   - Could provide sample TCP manifests
   - Risk of cluttering the cluster
   - **Decision:** Provide examples but don't auto-create

4. **Version pinning strategy?**
   - Latest vs specific versions
   - **Decision:** Use specific tested versions, document in README
