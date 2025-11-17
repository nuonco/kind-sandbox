# Kind Sandbox for Nuon

This Terraform module provisions a local Kubernetes cluster using [Kind (Kubernetes in Docker)](https://kind.sigs.k8s.io/) for development and testing of Nuon applications. It provides a lightweight alternative to cloud-based sandboxes like EKS or AKS, allowing rapid local iteration.

## Features

- **Local Kubernetes cluster** using Kind
- **Configurable node topology** (control plane + worker nodes)
- **Ingress support** with nginx-ingress controller
- **Metrics collection** with metrics-server
- **Port forwarding** for local access (HTTP/HTTPS)
- **Automatic namespace creation** based on Nuon install ID
- **Helm support** with configurable storage driver

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) or [Podman](https://podman.io/)
- [Terraform](https://www.terraform.io/downloads) >= 1.11
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) CLI (optional, provider handles installation)

## Quick Start

```hcl
module "kind_sandbox" {
  source = "github.com/nuonco/kind-sandbox"

  nuon_id              = "my-install-id"
  public_root_domain   = "example.com"
  internal_root_domain = "internal.example.com"

  tags = {
    environment = "development"
    managed_by  = "nuon"
  }
}
```

## Usage in Seed Apps

Reference this sandbox in your seed app's `sandbox.toml`:

```toml
#:schema https://api.nuon.co/v1/general/config-schema?type=sandbox
terraform_version = "1.11.3"

[public_repo]
directory = "."
repo      = "nuonco/kind-sandbox"
branch    = "main"

[vars]
cluster_name         = "n-{{.nuon.install.id}}"
public_root_domain   = "{{.nuon.inputs.inputs.root_domain}}"
internal_root_domain = "internal.{{.nuon.inputs.inputs.root_domain}}"
```

## Configuration

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `nuon_id` | string | Nuon installation identifier |
| `public_root_domain` | string | Public root domain for the installation |
| `internal_root_domain` | string | Internal root domain for the installation |
| `tags` | map(any) | Tags to apply to resources |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `cluster_name` | string | `""` | Cluster name (defaults to `n-{nuon_id}`) |
| `cluster_version` | string | `"1.32.0"` | Kubernetes version |
| `worker_nodes` | number | `2` | Number of worker nodes |
| `control_plane_nodes` | number | `1` | Number of control plane nodes |
| `ingress_http_port` | number | `80` | Host port for HTTP ingress |
| `ingress_https_port` | number | `443` | Host port for HTTPS ingress |
| `install_metrics_server` | bool | `true` | Install metrics-server |
| `install_ingress_nginx` | bool | `true` | Install ingress-nginx controller |
| `additional_namespaces` | list(string) | `[]` | Additional namespaces to create |
| `helm_driver` | string | `"secret"` | Helm storage driver (`secret` or `configmap`) |
| `additional_tags` | map(any) | `{}` | Additional tags to append |

## Outputs

| Output | Description |
|--------|-------------|
| `cluster` | Cluster connection details (endpoint, certificates, kubeconfig) |
| `namespaces` | List of created Kubernetes namespaces |
| `ingress` | Ingress controller configuration and endpoints |
| `domains` | Domain configuration (public and internal) |
| `nuon_id` | The Nuon installation identifier |
| `tags` | Applied resource tags |

## Component Support

This sandbox supports all Nuon component types:

- ✅ **Helm Charts** - Deploy via Helm provider
- ✅ **Kubernetes Manifests** - Apply via kubectl provider
- ✅ **Container Images** - Pull and run in cluster
- ✅ **Docker Builds** - Build and load into Kind cluster
- ❌ **Terraform Modules** - Limited support (no cloud resources)

## Accessing the Cluster

### Using kubectl

```bash
# Export kubeconfig
export KUBECONFIG=~/.kube/config-n-{install-id}

# Verify cluster access
kubectl cluster-info
kubectl get nodes
```

### Port Forwarding

The cluster exposes ports for local access:

- **HTTP**: `http://localhost:80` (default)
- **HTTPS**: `https://localhost:443` (default)

Configure these with `ingress_http_port` and `ingress_https_port` variables.

## Examples

### Minimal Configuration

```hcl
module "kind_sandbox" {
  source = "github.com/nuonco/kind-sandbox"

  nuon_id              = "test-install"
  public_root_domain   = "test.local"
  internal_root_domain = "internal.test.local"
  tags                 = { env = "test" }
}
```

### High Availability Setup

```hcl
module "kind_sandbox" {
  source = "github.com/nuonco/kind-sandbox"

  nuon_id              = "prod-install"
  public_root_domain   = "prod.local"
  internal_root_domain = "internal.prod.local"

  control_plane_nodes = 3
  worker_nodes        = 4
  cluster_version     = "1.32.0"

  tags = {
    env        = "production-testing"
    managed_by = "nuon"
  }
}
```

### Custom Port Configuration

```hcl
module "kind_sandbox" {
  source = "github.com/nuonco/kind-sandbox"

  nuon_id              = "custom-install"
  public_root_domain   = "custom.local"
  internal_root_domain = "internal.custom.local"

  ingress_http_port  = 8080
  ingress_https_port = 8443

  tags = { env = "dev" }
}
```

### Additional Namespaces

```hcl
module "kind_sandbox" {
  source = "github.com/nuonco/kind-sandbox"

  nuon_id              = "multi-ns-install"
  public_root_domain   = "app.local"
  internal_root_domain = "internal.app.local"

  additional_namespaces = [
    "monitoring",
    "logging",
    "data-processing"
  ]

  tags = { env = "staging" }
}
```

## Limitations

- **No cloud resources**: Cannot provision AWS/Azure/GCP resources
- **Local only**: Cluster runs on your local machine
- **Docker dependency**: Requires Docker or Podman runtime
- **Port conflicts**: Default ports 80/443 must be available
- **Resource constraints**: Limited by local machine resources

## Cleanup

To destroy the cluster:

```bash
terraform destroy
```

This will:
1. Remove all Helm releases
2. Delete Kubernetes namespaces
3. Destroy the Kind cluster
4. Clean up local kubeconfig

## Troubleshooting

### Port Already in Use

If ports 80/443 are occupied, use custom ports:

```hcl
ingress_http_port  = 8080
ingress_https_port = 8443
```

### Docker Not Running

Ensure Docker daemon is running:

```bash
docker ps
```

### Cluster Creation Fails

Check Kind logs:

```bash
kind get clusters
kind export logs --name n-{install-id}
```

### Can't Connect to Cluster

Verify kubeconfig path:

```bash
export KUBECONFIG=~/.kube/config-n-{install-id}
kubectl cluster-info
```

## Contributing

This module follows standard Terraform module conventions. To contribute:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This module is maintained by Nuon and follows the same license as the Nuon platform.

## Support

For issues or questions:
- GitHub Issues: https://github.com/nuonco/kind-sandbox/issues
- Nuon Documentation: https://docs.nuon.co
- Community: https://community.nuon.co
