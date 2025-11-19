locals {
  cluster_name = var.cluster_name != "" ? var.cluster_name : "n-${var.nuon_id}"
  all_tags     = merge(var.tags, var.additional_tags)

  # Create list of all namespaces to create
  all_namespaces = concat(
    [var.nuon_id],
    var.additional_namespaces
  )

  # Fix endpoint URL to use 127.0.0.1 instead of 0.0.0.0 for certificate validation
  cluster_endpoint = replace(kind_cluster.this.endpoint, "https://0.0.0.0:", "https://127.0.0.1:")
}

# Create the Kind cluster
resource "kind_cluster" "this" {
  name            = local.cluster_name
  kubeconfig_path = pathexpand("~/.kube/config")
  wait_for_ready  = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    containerd_config_patches = var.install_registry ? [
      <<-EOT
      [plugins."io.containerd.grpc.v1.cri".registry]
        config_path = "/etc/containerd/certs.d"
      EOT
    ] : []

    node {
      role  = "control-plane"
      image = "kindest/node:v${var.cluster_version}"

      # Port mapping for Kubernetes API server
      extra_port_mappings {
        container_port = 6443
        host_port      = var.control_plane_port
        protocol       = "TCP"
      }

      kubeadm_config_patches = [
        yamlencode({
          kind = "InitConfiguration"
          nodeRegistration = {
            kubeletExtraArgs = {
              "node-labels" = "ingress-ready=true"
            }
          }
        })
      ]
    }

    # Additional control plane nodes
    dynamic "node" {
      for_each = range(var.control_plane_nodes - 1)
      content {
        role  = "control-plane"
        image = "kindest/node:v${var.cluster_version}"
      }
    }

    # Worker nodes
    dynamic "node" {
      for_each = range(var.worker_nodes)
      content {
        role  = "worker"
        image = "kindest/node:v${var.cluster_version}"
      }
    }
  }
}

# Create Kubernetes namespaces
resource "kubernetes_namespace" "namespaces" {
  for_each = toset(local.all_namespaces)

  metadata {
    name = each.value
    labels = {
      "nuon.co/managed-by" = "nuon"
      "nuon.co/install-id" = var.nuon_id
    }
  }

  depends_on = [kind_cluster.this]
}
