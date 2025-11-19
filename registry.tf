# Local container registry for kind cluster
# This runs a Docker registry container accessible from both the host and the kind cluster
# Based on: https://kind.sigs.k8s.io/docs/user/local-registry/

locals {
  registry_name = var.install_registry ? "kind-registry" : ""
}

resource "docker_container" "registry" {
  count = var.install_registry ? 1 : 0

  name  = local.registry_name
  image = "registry:2"

  restart = "always"

  ports {
    internal = 5000
    external = var.registry_port
    ip       = "127.0.0.1"
  }

  # Start on bridge network, will be connected to kind network after cluster creation
  networks_advanced {
    name = "bridge"
  }

  volumes {
    container_path = "/var/lib/registry"
    host_path      = "/tmp/kind-registry-${local.cluster_name}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Configure registry hosts on all kind nodes
# This allows containerd to resolve localhost:${reg_port} to the registry container
resource "null_resource" "configure_registry_hosts" {
  count = var.install_registry ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      REGISTRY_DIR="/etc/containerd/certs.d/localhost:${var.registry_port}"
      for node in $(kind get nodes --name ${local.cluster_name}); do
        docker exec "$node" mkdir -p "$REGISTRY_DIR"
        cat <<EOF | docker exec -i "$node" cp /dev/stdin "$REGISTRY_DIR/hosts.toml"
      [host."http://${local.registry_name}:5000"]
      EOF
      done
    EOT
  }

  depends_on = [
    kind_cluster.this,
    docker_container.registry
  ]
}

# Connect the registry to the kind network
resource "null_resource" "connect_registry_to_kind_network" {
  count = var.install_registry ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      # Check if registry is already connected to kind network
      if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${local.registry_name}")" = 'null' ]; then
        docker network connect "kind" "${local.registry_name}"
      fi
    EOT
  }

  depends_on = [
    kind_cluster.this,
    docker_container.registry
  ]
}

# Document the local registry via ConfigMap
# https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
resource "kubernetes_config_map" "local_registry_hosting" {
  count = var.install_registry ? 1 : 0

  metadata {
    name      = "local-registry-hosting"
    namespace = "kube-public"
  }

  data = {
    "localRegistryHosting.v1" = <<-EOT
      host: "localhost:${var.registry_port}"
      help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
    EOT
  }

  depends_on = [
    kind_cluster.this,
    null_resource.configure_registry_hosts,
    null_resource.connect_registry_to_kind_network
  ]
}

locals {
  registry_url      = var.install_registry ? "localhost:${var.registry_port}" : ""
  registry_endpoint = var.install_registry ? "http://localhost:${var.registry_port}" : ""
}
