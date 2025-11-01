# Proposal: Add Kamaji Local Setup with Kind

## Why
Enable local development and testing of Kamaji (Hosted Control Plane Manager for Kubernetes) using kind (Kubernetes in Docker). This provides a lightweight, reproducible environment for learning and experimenting with multi-tenant Kubernetes control planes without requiring cloud infrastructure.

## What Changes
- Create kind cluster configuration optimized for Kamaji
- Install and configure cert-manager for TLS certificate management
- Deploy MetalLB for LoadBalancer service support in kind
- Configure IP address pool for tenant control plane services
- Install Kamaji operator via Helm
- Provide scripts and documentation for creating tenant control planes
- Add verification and testing procedures

## Impact
- Affected specs: `kamaji-infrastructure` (new capability)
- Affected code: New infrastructure scripts, configuration files, and documentation
- Dependencies: docker, kind, helm, kubectl
- No breaking changes - this is a net-new capability
