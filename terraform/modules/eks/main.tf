module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  endpoint_public_access = true

  # Grants whoever runs `apply` cluster-admin via an EKS access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids
  control_plane_subnet_ids = var.control_plane_subnet_ids

  # The module's node_security_group_recommended_rules only opens the control plane -> node
  # path for a fixed list of "known" webhook ports (443, 10250, 4443, 10251, 6443, 8443,
  # 9443 - metrics-server/Karpenter/ALB controller/etc). Istio's sidecar-injector and
  # validating webhooks run on 15017, which isn't in that list, so without this the API
  # server can never reach istiod's webhook - every pod create in an injection-enabled
  # namespace fails with "context deadline exceeded" regardless of istiod's own health.
  node_security_group_additional_rules = {
    ingress_cluster_istio_webhook = {
      description                   = "Cluster API to node 15017/tcp (Istio webhook)"
      protocol                      = "tcp"
      from_port                     = 15017
      to_port                       = 15017
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      # block_device_mappings replaces the whole default mapping, so
      # volume_size/type have to be repeated here alongside encrypted
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size = 20
            volume_type = "gp3"
            encrypted   = true
          }
        }
      }
    }
  }

  tags = var.tags
}
