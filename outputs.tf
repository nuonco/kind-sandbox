output "cluster" {
  description = "Kind cluster information"
  value = {
    name                   = kind_cluster.this.name
    endpoint               = kind_cluster.this.endpoint
    cluster_ca_certificate = kind_cluster.this.cluster_ca_certificate
    client_certificate     = kind_cluster.this.client_certificate
    client_key             = kind_cluster.this.client_key
    kubeconfig             = kind_cluster.this.kubeconfig
    kubeconfig_path        = kind_cluster.this.kubeconfig_path
    version                = var.cluster_version
  }
  sensitive = true
}

output "namespaces" {
  description = "List of Kubernetes namespaces created in the cluster"
  value       = [for ns in kubernetes_namespace.namespaces : ns.metadata[0].name]
}

output "ingress" {
  description = "Ingress controller configuration"
  value = {
    enabled    = var.install_ingress_nginx
    http_port  = var.ingress_http_port
    https_port = var.ingress_https_port
    endpoint   = var.install_ingress_nginx ? "http://localhost:${var.ingress_http_port}" : ""
  }
}

output "domains" {
  description = "Domain configuration for the installation"
  value = {
    public_root_domain   = var.public_root_domain
    internal_root_domain = var.internal_root_domain
  }
}

output "nuon_id" {
  description = "The Nuon installation identifier"
  value       = var.nuon_id
}

output "cluster_type" {
  description = "The Nuon installation identifier"
  value       = "kind"
}

output "tags" {
  description = "Tags applied to resources"
  value       = local.all_tags
}

output "registry" {
  description = "Container registry information"
  value = {
    enabled       = var.install_registry
    registry_url  = local.registry_url
    registry_endpoint = local.registry_endpoint
    registry_port = var.registry_port
    # For local registry, no authentication is required by default
    auth_required = false
    # Instructions for pushing images
    usage = var.install_registry ? "docker tag <image> ${local.registry_url}/<image>:<tag> && docker push ${local.registry_url}/<image>:<tag>" : ""
  }
}
