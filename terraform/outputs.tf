output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version"
  value       = module.eks.cluster_version
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for IRSA"
  value       = module.eks.cluster_oidc_issuer_url
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "argocd_port_forward" {
  description = "Command to port-forward ArgoCD"
  value       = "kubectl port-forward svc/argocd-server -n ${var.argocd_namespace} 8080:443"
}

output "argocd_admin_password" {
  description = "Command to retrieve ArgoCD admin password"
  value       = "kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
  sensitive   = true
}

output "gateway_lb_hostname" {
  description = "Command to get the NLB hostname from Envoy Gateway"
  value       = "kubectl get gateway bookstore-gateway -n default -o jsonpath='{.status.addresses[0].value}'"
}

output "useful_commands" {
  description = "Useful commands for managing the cluster"
  value = {
    get_nodes        = "kubectl get nodes"
    get_pods_all     = "kubectl get pods -A"
    get_app_pods     = "kubectl get pods -n mern-devops"
    argocd_apps      = "kubectl get applications -n ${var.argocd_namespace}"
    gateway_status   = "kubectl get gateway -A"
    httproute_status = "kubectl get httproute -A"
  }
}
