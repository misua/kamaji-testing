# Kamaji Local Setup Proposal - Quick Reference

## Overview
This proposal defines the implementation of a local Kamaji development environment using kind (Kubernetes in Docker). Kamaji is a Hosted Control Plane Manager that allows you to run multiple Kubernetes control planes as pods within a management cluster.

## What is Kamaji?
Kamaji enables you to:
- Run Kubernetes control planes as pods instead of dedicated VMs
- Manage multiple tenant clusters from a single management cluster
- Reduce operational overhead and resource consumption
- Test multi-tenant Kubernetes scenarios locally

## Proposal Structure

### 📄 Files Created
- **proposal.md** - High-level overview and impact analysis
- **design.md** - Architectural decisions and technical details
- **tasks.md** - Implementation checklist (10 sections, 50+ tasks)
- **specs/kamaji-infrastructure/spec.md** - Formal requirements and scenarios

### 🎯 Key Components
1. **kind cluster** - Management cluster running in Docker
2. **cert-manager** - TLS certificate management for webhooks
3. **MetalLB** - LoadBalancer support for tenant control planes
4. **Kamaji operator** - Control plane lifecycle management
5. **Tenant Control Planes** - Isolated Kubernetes control planes as pods

## Architecture Summary

```
Docker Host
└── kind Cluster (Management)
    ├── Kamaji Operator
    ├── cert-manager
    ├── MetalLB
    └── Tenant Control Planes (3 clusters: dev, staging, prod)
        ├── TCP-dev (LoadBalancer IP: x.x.x.200)
        │   ├── API Server (pod)
        │   ├── Controller Manager (pod)
        │   ├── Scheduler (pod)
        │   └── etcd (pod)
        ├── TCP-staging (LoadBalancer IP: x.x.x.201)
        │   └── ... (same components)
        └── TCP-prod (LoadBalancer IP: x.x.x.202)
            └── ... (same components)
```

## Implementation Phases

### Phase 1: Foundation (Tasks 1-2)
- Prerequisites documentation
- kind cluster setup and validation

### Phase 2: Dependencies (Tasks 3-4)
- cert-manager installation
- MetalLB with IP pool configuration

### Phase 3: Kamaji (Task 5)
- Kamaji operator installation
- CRD validation

### Phase 4: Tenant Management (Task 6)
- Tenant control plane creation
- kubeconfig extraction
- Multi-tenant workflows

### Phase 5: Automation (Tasks 7-8)
- Master setup script
- Complete documentation

### Phase 6: Validation (Task 9)
- Verification scripts
- Functional tests

## Requirements Highlights

The specification defines 8 major requirements:

1. **Kind Cluster Provisioning** - Automated cluster creation with validation
2. **Certificate Manager Installation** - TLS for Kamaji webhooks
3. **LoadBalancer Service Support** - MetalLB with auto-detected IP pools
4. **Kamaji Operator Installation** - Control plane manager setup
5. **Tenant Control Plane Lifecycle** - Create, manage, delete TCPs
6. **Setup Automation** - Idempotent scripts with error handling
7. **Verification and Validation** - Health checks and functional tests
8. **Documentation** - Quick start, troubleshooting, architecture

## Key Design Decisions

### ✅ Chosen Approaches
- **kind** over minikube/k3d (official Kamaji support)
- **Bitnami cert-manager** (matches Kamaji docs)
- **MetalLB** for LoadBalancer (standard for bare-metal/kind)
- **Shell scripts** for automation (simple, portable)
- **Default etcd** datastore (simplest for local dev)

### ⚠️ Trade-offs
- Single-node cluster (faster, simpler, but no multi-zone testing)
- Auto-detected IP pools (convenient, but may need manual override)
- Version pinning (stability over latest features)

## Prerequisites

Required tools:
- Docker (for kind)
- kind (Kubernetes in Docker)
- helm (package manager)
- kubectl (Kubernetes CLI)

Recommended resources:
- 4+ CPU cores
- 8+ GB RAM
- 20+ GB disk space

## Expected Outcomes

After implementation, users will be able to:
1. Run `./setup.sh` to create complete Kamaji environment
2. Deploy three tenant control planes (dev, staging, prod) with provided manifests
3. Extract kubeconfig for each tenant cluster
4. Access and manage all three clusters independently
5. Test multi-tenant scenarios with realistic dev/staging/prod workflow
6. Verify isolation between the three environments
7. Clean up with `./teardown.sh`

## Validation Status

✅ **Proposal validated successfully**
```bash
openspec validate add-kamaji-local-setup --strict
# Result: Change 'add-kamaji-local-setup' is valid
```

## Next Steps

1. **Review** - Stakeholders review proposal, design, and requirements
2. **Approve** - Get approval to proceed with implementation
3. **Implement** - Follow tasks.md checklist sequentially
4. **Test** - Run verification scripts and functional tests
5. **Document** - Complete user-facing documentation
6. **Archive** - Move to archive after deployment

## Reference Documentation

- Kamaji Official: https://kamaji.clastix.io
- Kamaji on Kind Guide: https://kamaji.clastix.io/getting-started/kamaji-kind/
- Kamaji GitHub: https://github.com/clastix/kamaji
- kind Documentation: https://kind.sigs.k8s.io

## Questions or Issues?

Refer to:
- `design.md` - Technical decisions and alternatives
- `specs/kamaji-infrastructure/spec.md` - Detailed requirements
- `tasks.md` - Implementation checklist
