# Install ingress-nginx controller
# resource "helm_release" "ingress_nginx" {
#   count = var.install_ingress_nginx ? 1 : 0
#
#   name             = "ingress-nginx"
#   repository       = "https://kubernetes.github.io/ingress-nginx"
#   chart            = "ingress-nginx"
#   version          = "4.11.3"
#   namespace        = "ingress-nginx"
#   create_namespace = true
#
#   values = [
#     yamlencode({
#       controller = {
#         service = {
#           type = "NodePort"
#         }
#         hostPort = {
#           enabled = true
#         }
#         nodeSelector = {
#           "ingress-ready" = "true"
#         }
#         tolerations = [
#           {
#             key      = "node-role.kubernetes.io/control-plane"
#             operator = "Equal"
#             effect   = "NoSchedule"
#           }
#         ]
#       }
#     })
#   ]
#
#   depends_on = [kind_cluster.this]
# }
