# Worker Nodes - Setup & Cleanup

## Quick Setup

### 1. Install Prerequisites

```bash
# Install Vagrant and libvirt
sudo apt-get install vagrant libvirt-dev qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils

# Install Vagrant libvirt plugin
vagrant plugin install vagrant-libvirt

# Start libvirt service
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

# Add yourself to libvirt group
sudo usermod -aG libvirt $USER
newgrp libvirt

# Fix file descriptor limits (prevents "too many open files" error)
sudo sysctl fs.inotify.max_user_instances=512
sudo sysctl fs.inotify.max_user_watches=524288
echo "fs.inotify.max_user_instances=512" | sudo tee -a /etc/sysctl.conf
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
```

### 2. Create Worker VMs

```bash
# Navigate to project root
cd /home/sab/Desktop/DEVOPS-INTERVIEWS-SITUATIONALS/kamaji-testing

# Create VMs (downloads box, provisions Kubernetes)
vagrant up --provider=libvirt
```

**Takes 5-10 minutes** - Downloads Ubuntu box, creates VMs, installs Kubernetes.

### 3. Join Workers to Control Planes

```bash
# Still in project root
for tenant in dev staging prod; do
  ./scripts/join-worker.sh ${tenant}
done
```

**Takes 1-2 minutes** - Configures kubelet on each VM to join its tenant cluster.

### 4. Verify Workers

```bash
# From project root: /home/sab/Desktop/DEVOPS-INTERVIEWS-SITUATIONALS/kamaji-testing
for env in dev staging prod; do
  echo "=== tcp-${env} ==="
  kubectl --kubeconfig=scripts/kubeconfigs/tcp-${env}.kubeconfig get nodes
  echo ""
done

# Should show: tcp-{env}-worker   Ready   <none>   1m   v1.28.0
```

### 5. Deploy Demo Apps

```bash
# Deploy nginx to each environment
kubectl --kubeconfig=scripts/kubeconfigs/tcp-dev.kubeconfig apply -f manifests/examples/nginx-dev.yaml
kubectl --kubeconfig=scripts/kubeconfigs/tcp-staging.kubeconfig apply -f manifests/examples/nginx-staging.yaml
kubectl --kubeconfig=scripts/kubeconfigs/tcp-prod.kubeconfig apply -f manifests/examples/nginx-prod.yaml

# Wait for pods to run (Ctrl+C to exit)
kubectl --kubeconfig=scripts/kubeconfigs/tcp-dev.kubeconfig get pods -n demo -w

# Get LoadBalancer IPs
kubectl --kubeconfig=scripts/kubeconfigs/tcp-dev.kubeconfig get svc -n demo
```

### 6. Access Applications

```bash
# Get the external IP from step 5, then:
curl http://<EXTERNAL-IP>

# Or open in browser: http://<EXTERNAL-IP>
# Should show purple page with "DEVELOPMENT Environment"
```

## Cleanup

### Remove Everything

```bash
# Removes: kind cluster + tenant control planes + worker VMs
./scripts/99-cleanup.sh
```

### Remove Only Worker VMs

```bash
# Keeps kind cluster and control planes, removes only VMs
./scripts/08-cleanup-workers.sh
```

### Manual VM Cleanup

```bash
# If scripts fail
cd kamaji-testing
vagrant destroy -f
```

## Troubleshooting

### "Too many open files" error
```bash
# Increase file descriptor limits
sudo sysctl fs.inotify.max_user_instances=512
sudo sysctl fs.inotify.max_user_watches=524288
sudo systemctl restart libvirtd

# Try again
vagrant up --provider=libvirt
```

### Vagrant plugin errors
```bash
# Fix plugin conflicts
vagrant plugin expunge --reinstall

# Or manually clean
rm -rf ~/.vagrant.d/plugins.json ~/.vagrant.d/gems
vagrant plugin install vagrant-libvirt
```

### VMs won't start
```bash
# Check libvirt is running
sudo systemctl status libvirtd

# Restart if needed
sudo systemctl restart libvirtd
```

### Workers show "No resources found"
```bash
# Workers haven't joined yet - run join script
cd /home/sab/Desktop/DEVOPS-INTERVIEWS-SITUATIONALS/kamaji-testing
for tenant in dev staging prod; do
  ./scripts/join-worker.sh ${tenant}
done
```

### Debug worker issues
```bash
# SSH into VM
vagrant ssh tcp-dev-worker

# Check kubelet status
sudo systemctl status kubelet
sudo journalctl -u kubelet -f
```

### Wrong directory errors
```bash
# Always run from project root
cd /home/sab/Desktop/DEVOPS-INTERVIEWS-SITUATIONALS/kamaji-testing

# Then run commands
```

### Clean slate
```bash
# Remove everything and start over
cd /home/sab/Desktop/DEVOPS-INTERVIEWS-SITUATIONALS/kamaji-testing
./scripts/99-cleanup.sh
vagrant destroy -f
sudo systemctl restart libvirtd
```

## What You Get

- ✅ 3 tenant control planes (dev, staging, prod)
- ✅ 3 worker VMs (one per tenant)
- ✅ Pods can actually run
- ✅ LoadBalancer IPs work
- ✅ Browser-accessible nginx demos
- ✅ Complete multi-tenancy demonstration
