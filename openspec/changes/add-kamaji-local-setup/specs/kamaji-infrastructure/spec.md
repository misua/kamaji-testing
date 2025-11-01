# Kamaji Infrastructure Specification

## ADDED Requirements

### Requirement: Kind Cluster Provisioning
The system SHALL provide automated provisioning of a kind (Kubernetes in Docker) cluster suitable for running Kamaji.

#### Scenario: Successful cluster creation
- **WHEN** the user executes the cluster creation script
- **THEN** a kind cluster named "kamaji" is created
- **AND** the cluster reaches a ready state within 2 minutes
- **AND** kubectl can successfully connect to the cluster

#### Scenario: Cluster already exists
- **WHEN** the user executes the cluster creation script
- **AND** a cluster named "kamaji" already exists
- **THEN** the script detects the existing cluster
- **AND** skips creation without error
- **AND** validates the existing cluster is functional

#### Scenario: Cluster cleanup
- **WHEN** the user executes the cleanup script
- **THEN** the kind cluster is deleted
- **AND** all associated Docker containers are removed
- **AND** the Docker network is cleaned up

### Requirement: Certificate Manager Installation
The system SHALL install and configure cert-manager to provide TLS certificate management for Kamaji webhooks.

#### Scenario: cert-manager installation
- **WHEN** the cert-manager installation script is executed
- **THEN** cert-manager is installed via Bitnami Helm chart
- **AND** cert-manager is deployed to the "certmanager-system" namespace
- **AND** all cert-manager pods reach Running state within 3 minutes
- **AND** CRDs for Certificate, Issuer, and ClusterIssuer are created

#### Scenario: cert-manager validation
- **WHEN** cert-manager installation completes
- **THEN** webhook configurations are functional
- **AND** the cert-manager controller can issue certificates
- **AND** the system can verify cert-manager readiness

### Requirement: LoadBalancer Service Support
The system SHALL provide LoadBalancer service support using MetalLB for exposing tenant control planes.

#### Scenario: MetalLB installation
- **WHEN** the MetalLB installation script is executed
- **THEN** MetalLB is installed to the "metallb-system" namespace
- **AND** MetalLB speaker and controller pods reach Running state
- **AND** the system is ready to allocate LoadBalancer IPs

#### Scenario: IP address pool configuration
- **WHEN** the IP pool configuration script is executed
- **THEN** the kind Docker network gateway IP is auto-detected
- **AND** an IPAddressPool resource is created with a /24 subnet range
- **AND** the IP range uses high addresses (x.x.255.200-250) to avoid conflicts
- **AND** an L2Advertisement resource is created for local network advertisement

#### Scenario: LoadBalancer IP allocation
- **WHEN** a service of type LoadBalancer is created
- **THEN** MetalLB assigns an IP from the configured pool
- **AND** the IP is accessible from the Docker host
- **AND** the service is reachable at the assigned IP

### Requirement: Kamaji Operator Installation
The system SHALL install and configure the Kamaji operator for managing tenant control planes.

#### Scenario: Kamaji installation
- **WHEN** the Kamaji installation script is executed
- **THEN** the Clastix Helm repository is added
- **AND** Kamaji is installed to the "kamaji-system" namespace
- **AND** the Kamaji controller pod reaches Running state within 2 minutes
- **AND** TenantControlPlane and Datastore CRDs are created

#### Scenario: Kamaji validation
- **WHEN** Kamaji installation completes
- **THEN** the Kamaji controller is operational
- **AND** the system can list Kamaji CRDs
- **AND** webhook configurations are functional
- **AND** the default datastore is available

### Requirement: Tenant Control Plane Lifecycle
The system SHALL support creation, management, and deletion of tenant control planes.

#### Scenario: Single tenant control plane creation
- **WHEN** a TenantControlPlane resource is applied
- **THEN** Kamaji creates control plane pods (api-server, controller-manager, scheduler)
- **AND** an etcd datastore is provisioned
- **AND** the control plane reaches Ready state within 5 minutes
- **AND** a LoadBalancer service is created with an assigned IP
- **AND** a kubeconfig secret is generated

#### Scenario: Multiple tenant control planes
- **WHEN** three TenantControlPlane resources are created (dev, staging, prod)
- **THEN** each tenant control plane is isolated
- **AND** each has its own LoadBalancer IP
- **AND** each has its own kubeconfig
- **AND** control planes do not interfere with each other
- **AND** all three control planes can run simultaneously

#### Scenario: Kubeconfig extraction
- **WHEN** the kubeconfig extraction script is executed with a tenant name
- **THEN** the kubeconfig is retrieved from the secret
- **AND** the kubeconfig is decoded and saved to a file
- **AND** kubectl can authenticate using the extracted kubeconfig
- **AND** kubectl commands work against the tenant control plane

#### Scenario: Tenant control plane deletion
- **WHEN** a TenantControlPlane resource is deleted
- **THEN** all associated pods are terminated
- **AND** the LoadBalancer service is removed
- **AND** the kubeconfig secret is deleted
- **AND** the datastore is cleaned up

### Requirement: Setup Automation
The system SHALL provide automated scripts for complete environment setup and teardown.

#### Scenario: Complete setup execution
- **WHEN** the master setup script is executed
- **THEN** all components are installed in the correct order
- **AND** each step validates successful completion before proceeding
- **AND** progress is logged to the console
- **AND** the entire setup completes within 10 minutes on typical hardware

#### Scenario: Idempotent execution
- **WHEN** the setup script is executed multiple times
- **THEN** already-installed components are detected and skipped
- **AND** missing components are installed
- **AND** no errors occur from duplicate installations

#### Scenario: Error handling
- **WHEN** a setup step fails
- **THEN** the error is logged with details
- **AND** the script stops execution
- **AND** cleanup instructions are provided
- **AND** the user can retry after fixing the issue

#### Scenario: Complete teardown
- **WHEN** the teardown script is executed
- **THEN** all tenant control planes are deleted
- **AND** the kind cluster is destroyed
- **AND** Docker resources are cleaned up
- **AND** the system returns to pre-installation state

### Requirement: Verification and Validation
The system SHALL provide verification scripts to validate the installation and functionality.

#### Scenario: Component verification
- **WHEN** the verification script is executed
- **THEN** kind cluster status is checked
- **AND** cert-manager pods are verified as Running
- **AND** MetalLB pods are verified as Running
- **AND** Kamaji controller is verified as Running
- **AND** all CRDs are confirmed present
- **AND** a summary report is displayed

#### Scenario: Functional testing
- **WHEN** the functional test script is executed
- **THEN** a test tenant control plane is created
- **AND** the control plane reaches Ready state
- **AND** kubeconfig is extracted successfully
- **AND** kubectl commands work against the tenant cluster
- **AND** the test tenant control plane is cleaned up

### Requirement: Documentation
The system SHALL provide comprehensive documentation for setup, usage, and troubleshooting.

#### Scenario: Quick start guide
- **WHEN** a user reads the README
- **THEN** prerequisites are clearly listed
- **AND** installation steps are provided
- **AND** a simple example is included
- **AND** the user can complete setup in under 15 minutes

#### Scenario: Troubleshooting guide
- **WHEN** a user encounters an issue
- **THEN** common problems are documented
- **AND** diagnostic commands are provided
- **AND** solutions or workarounds are explained
- **AND** links to upstream documentation are included

#### Scenario: Architecture documentation
- **WHEN** a user wants to understand the system
- **THEN** component relationships are explained
- **AND** architecture diagrams are provided
- **AND** data flow is documented
- **AND** design decisions are justified
