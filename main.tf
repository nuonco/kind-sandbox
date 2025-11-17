locals {
  cluster_name = var.cluster_name != "" ? var.cluster_name : "n-${var.nuon_id}"
  all_tags     = merge(var.tags, var.additional_tags)

  # Create list of all namespaces to create
  all_namespaces = concat(
    [var.nuon_id],
    var.additional_namespaces
  )
}

# Create the Kind cluster
resource "kind_cluster" "this" {
  name            = local.cluster_name
  kubeconfig_path = pathexpand("~/.kube/config-${local.cluster_name}")
  wait_for_ready  = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role  = "control-plane"
      image = "kindest/node:v${var.cluster_version}"

      # Port mappings for ingress
      extra_port_mappings {
        container_port = 80
        host_port      = var.ingress_http_port
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 443
        host_port      = var.ingress_https_port
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
