# Troubleshooting Guide

## Common Issues

### 1. kind Cluster Creation Fails

**Symptom:**
```
ERROR: failed to create cluster: ...
```

**Solutions:**

- **Check Docker is running:**
  ```bash
  docker ps
  ```

- **Check Docker resources:**
  ```bash
  docker info | grep -E "CPUs|Total Memory"
  ```
  Ensure at least 4 CPUs and 8GB RAM are allocated.

- **Delete existing cluster:**
  ```bash
  kind delete cluster --name kamaji
  ```

- **Check for port conflicts:**
  ```bash
  lsof -i :6443
  ```

### 2. cert-manager Installation Issues

**Symptom:**
```
ImagePullBackOff or timeout errors
```

**Solutions:**

- **Check pod status:**
  ```bash
  kubectl get pods -n cert-manager
  kubectl describe pod -n cert-manager <pod-name>
  ```

- **Check events:**
  ```bash
  kubectl get events -n cert-manager --sort-by='.lastTimestamp'
  ```

- **Reinstall cert-manager:**
  ```bash
  kubectl delete namespace cert-manager
  ./scripts/02-install-cert-manager.sh
  ```

**Note:** The script uses official cert-manager manifests from quay.io (not Docker Hub) to avoid rate limiting issues.

### 3. MetalLB IP Pool Issues

**Symptom:**
```
LoadBalancer service stuck in <pending>
```

**Solutions:**

- **Check MetalLB pods:**
  ```bash
  kubectl get pods -n metallb-system
  kubectl logs -n metallb-system -l app=metallb,component=controller
  ```

- **Verify IP pool configuration:**
  ```bash
  kubectl get ipaddresspool -n metallb-system kind-ip-pool -o yaml
  ```

- **Check kind network:**
  ```bash
  docker network inspect kind
  ```

- **Manually configure IP pool:**
  ```bash
  # Get kind network gateway
  GW_IP=$(docker network inspect -f '{{range .IPAM.Config}}{{.Gateway}}{{end}}' kind)
  NET_IP=$(echo "${GW_IP}" | sed -E 's|^([0-9]+\.[0-9]+)\..*$|\1|g')
  
  # Apply custom IP pool
  cat <<EOF | kubectl apply -f -
  apiVersion: metallb.io/v1beta1
  kind: IPAddressPool
  metadata:
    name: kind-ip-pool
    namespace: metallb-system
  spec:
    addresses:
    - ${NET_IP}.255.200-${NET_IP}.255.250
  EOF
  ```

### 4. Kamaji Installation Fails

**Symptom:**
```
Error: failed to install kamaji
```

**Solutions:**

- **Check Helm repositories:**
  ```bash
  helm repo list
  helm repo update
  ```

- **Verify CRDs:**
  ```bash
  kubectl get crds | grep kamaji
  ```

- **Check controller logs:**
  ```bash
  kubectl logs -n kamaji-system -l control-plane=controller-manager
  ```

- **Reinstall Kamaji:**
  ```bash
  helm uninstall kamaji -n kamaji-system
  kubectl delete namespace kamaji-system
  ./scripts/04-install-kamaji.sh
  ```

### 5. Tenant Control Plane Not Ready

**Symptom:**
```
TenantControlPlane stuck in "NotReady" state
```

**Solutions:**

- **Check TCP status:**
  ```bash
  kubectl describe tenantcontrolplane tcp-dev
  ```

- **Check control plane pods:**
  ```bash
  kubectl get pods -l 'kamaji.clastix.io/name=tcp-dev'
  kubectl logs <pod-name>
  ```

- **Check events:**
  ```bash
  kubectl get events --field-selector involvedObject.name=tcp-dev
  ```

- **Verify LoadBalancer IP assigned:**
  ```bash
  kubectl get svc -l 'kamaji.clastix.io/name=tcp-dev'
  ```

- **Delete and recreate:**
  ```bash
  kubectl delete tenantcontrolplane tcp-dev
  kubectl apply -f manifests/tenant-control-planes/tcp-dev.yaml
  ```

### 6. Kubeconfig Extraction Fails

**Symptom:**
```
✗ Secret name not found. Is the TCP ready?
```

**Solutions:**

- **Verify TCP is ready:**
  ```bash
  kubectl get tenantcontrolplane tcp-dev
  ```
  Status should show "Ready: True"

- **Check secret exists:**
  ```bash
  kubectl get secrets | grep tcp-dev
  ```

- **Wait for TCP to be ready:**
  ```bash
  kubectl wait --for=condition=Ready tenantcontrolplane tcp-dev --timeout=600s
  ```

### 7. Resource Exhaustion

**Symptom:**
```
Pods stuck in Pending state
Node pressure warnings
```

**Solutions:**

- **Check node resources:**
  ```bash
  kubectl top nodes
  kubectl describe node
  ```

- **Check pod resource requests:**
  ```bash
  kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].resources.requests}{"\n"}{end}'
  ```

- **Increase Docker resources:**
  - Docker Desktop: Preferences → Resources
  - Allocate more CPU and RAM

- **Reduce tenant control planes:**
  ```bash
  kubectl delete tenantcontrolplane tcp-staging tcp-prod
  ```

### 8. Network Connectivity Issues

**Symptom:**
```
Cannot access tenant API server
Connection refused errors
```

**Solutions:**

- **Verify LoadBalancer IP:**
  ```bash
  kubectl get svc -l 'kamaji.clastix.io/name=tcp-dev'
  ```

- **Test connectivity:**
  ```bash
  # Get LoadBalancer IP
  LB_IP=$(kubectl get svc -l 'kamaji.clastix.io/name=tcp-dev' -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
  
  # Test connection
  curl -k https://${LB_IP}:6443/version
  ```

- **Check MetalLB speaker logs:**
  ```bash
  kubectl logs -n metallb-system -l app=metallb,component=speaker
  ```

## Diagnostic Commands

### Full System Check

```bash
# Run verification script
./scripts/verify.sh

# Check all pods
kubectl get pods -A

# Check all services
kubectl get svc -A

# Check all events (recent)
kubectl get events -A --sort-by='.lastTimestamp' | tail -50

# Check node status
kubectl get nodes -o wide
kubectl describe node
```

### Component-Specific Checks

```bash
# cert-manager
kubectl get pods -n cert-manager
kubectl logs -n cert-manager -l app.kubernetes.io/name=cert-manager

# MetalLB
kubectl get pods -n metallb-system
kubectl get ipaddresspool -n metallb-system
kubectl logs -n metallb-system -l app=metallb

# Kamaji
kubectl get pods -n kamaji-system
kubectl logs -n kamaji-system -l control-plane=controller-manager
kubectl get crds | grep kamaji

# Tenant Control Planes
kubectl get tenantcontrolplanes
kubectl get pods -l 'kamaji.clastix.io/component=control-plane'
```

### Resource Usage

```bash
# Node resources
kubectl top nodes

# Pod resources
kubectl top pods -A

# Docker stats
docker stats --no-stream
```

## Getting Help

If you're still experiencing issues:

1. **Check Kamaji documentation:** https://kamaji.clastix.io/
2. **Search GitHub issues:** https://github.com/clastix/kamaji/issues
3. **Join Kamaji Slack:** https://kubernetes.slack.com/messages/kamaji
4. **Open an issue:** https://github.com/clastix/kamaji/issues/new

### Information to Include

When reporting issues, include:

```bash
# System information
uname -a
docker version
kind version
kubectl version
helm version

# Cluster state
kubectl get all -A
kubectl get events -A --sort-by='.lastTimestamp' | tail -100

# Component logs
kubectl logs -n kamaji-system -l control-plane=controller-manager --tail=200
kubectl describe tenantcontrolplane tcp-dev
```
