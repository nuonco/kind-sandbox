provider "kind" {}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = kind_cluster.this.cluster_ca_certificate
  client_certificate     = kind_cluster.this.client_certificate
  client_key             = kind_cluster.this.client_key
}

provider "helm" {
  kubernetes {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = kind_cluster.this.cluster_ca_certificate
    client_certificate     = kind_cluster.this.client_certificate
    client_key             = kind_cluster.this.client_key
  }

  experiments {
    manifest = true
  }
}

provider "kubectl" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = kind_cluster.this.cluster_ca_certificate
  client_certificate     = kind_cluster.this.client_certificate
  client_key             = kind_cluster.this.client_key
  load_config_file       = false
}
