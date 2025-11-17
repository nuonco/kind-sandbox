# Required Variables
variable "nuon_id" {
  description = "The Nuon installation identifier"
  type        = string
}

variable "cluster_name" {
  description = "The name of the Kind cluster. Defaults to nuon_id if not provided."
  type        = string
  default     = ""
}

variable "public_root_domain" {
  description = "The public root domain for the installation"
  type        = string
}

variable "internal_root_domain" {
  description = "The internal root domain for the installation"
  type        = string
}

# Cluster Configuration
variable "cluster_version" {
  description = "Kubernetes version for the Kind cluster"
  type        = string
  default     = "1.32.0"
}

variable "worker_nodes" {
  description = "Number of worker nodes to create in the Kind cluster"
  type        = number
  default     = 2
}

variable "control_plane_nodes" {
  description = "Number of control plane nodes to create in the Kind cluster"
  type        = number
  default     = 1
}

# Port Mappings
variable "ingress_http_port" {
  description = "Host port to map to container port 80 for HTTP ingress"
  type        = number
  default     = 80
}

variable "ingress_https_port" {
  description = "Host port to map to container port 443 for HTTPS ingress"
  type        = number
  default     = 443
}

# Optional Features
variable "install_metrics_server" {
  description = "Whether to install metrics-server in the cluster"
  type        = bool
  default     = true
}

variable "install_ingress_nginx" {
  description = "Whether to install ingress-nginx controller in the cluster"
  type        = bool
  default     = true
}

# Namespaces
variable "additional_namespaces" {
  description = "Additional Kubernetes namespaces to create (nuon_id namespace is created automatically)"
  type        = list(string)
  default     = []
}

# Tags
variable "tags" {
  description = "A map of tags to apply to resources for taxonomic purposes"
  type        = map(any)
}

variable "additional_tags" {
  description = "Additional tags to append to the default tags"
  type        = map(any)
  default     = {}
}

# Helm Configuration
variable "helm_driver" {
  description = "The backend storage driver for Helm. Valid values are 'configmap' or 'secret'"
  type        = string
  default     = "secret"
}
