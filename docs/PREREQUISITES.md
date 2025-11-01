# Prerequisites

## Required Tools

### Docker
- **Version**: 20.10+ 
- **Purpose**: Container runtime for kind
- **Installation**: https://docs.docker.com/get-docker/
- **Verification**: `docker --version`

### kind (Kubernetes in Docker)
- **Version**: 0.20.0+
- **Purpose**: Local Kubernetes cluster
- **Installation**: https://kind.sigs.k8s.io/docs/user/quick-start/#installation
- **Verification**: `kind --version`

### Helm
- **Version**: 3.12.0+
- **Purpose**: Package manager for Kubernetes
- **Installation**: https://helm.sh/docs/intro/install/
- **Verification**: `helm version`

### kubectl
- **Version**: 1.28.0+
- **Purpose**: Kubernetes CLI
- **Installation**: https://kubernetes.io/docs/tasks/tools/
- **Verification**: `kubectl version --client`

## System Requirements

### Minimum Resources
- **CPU**: 4 cores
- **RAM**: 8 GB
- **Disk**: 20 GB free space
- **OS**: Linux, macOS, or Windows with WSL2

### Recommended Resources
- **CPU**: 6+ cores
- **RAM**: 16 GB
- **Disk**: 30 GB free space

## Resource Consumption

### Management Cluster (kind)
- **CPU**: ~1 core
- **RAM**: ~2 GB

### Per Tenant Control Plane
- **CPU**: ~0.5 cores
- **RAM**: ~1 GB

### Three Tenant Control Planes (dev, staging, prod)
- **Total CPU**: ~2.5 cores (management + 3 TCPs)
- **Total RAM**: ~5 GB (management + 3 TCPs)

## Tested Versions

| Component | Version | Status |
|-----------|---------|--------|
| Docker | 24.0.7 | ✅ Tested |
| kind | 0.20.0 | ✅ Tested |
| Helm | 3.13.0 | ✅ Tested |
| kubectl | 1.28.3 | ✅ Tested |
| Kubernetes (kind) | 1.28.0 | ✅ Tested |
| cert-manager | 1.13.2 | ✅ Tested |
| MetalLB | 0.13.12 | ✅ Tested |
| Kamaji | 0.0.0+latest | ✅ Tested |

## Pre-flight Checks

Run these commands to verify your environment:

```bash
# Check Docker
docker ps

# Check kind
kind version

# Check Helm
helm version

# Check kubectl
kubectl version --client

# Check available resources
docker info | grep -E "CPUs|Total Memory"
```

## Platform-Specific Notes

### Linux
- Ensure your user is in the `docker` group: `sudo usermod -aG docker $USER`
- Log out and back in for group changes to take effect

### macOS
- Docker Desktop must be running
- Allocate sufficient resources in Docker Desktop preferences

### Windows (WSL2)
- Use WSL2 backend for Docker Desktop
- Run all commands from WSL2 terminal
- Ensure WSL2 has sufficient memory allocation
