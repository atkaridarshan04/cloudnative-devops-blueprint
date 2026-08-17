# Terraform — EKS infra

Terraform for the EKS cluster this project's ArgoCD/Istio/book-store stack
runs on: VPC, EKS (managed node group), the AWS Load Balancer Controller,
and the EBS CSI driver. Everything above the cluster (Istio, Gateway API,
cert-manager, ArgoCD apps, book-store) is GitOps-managed from `argocd/`, not
Terraform.

## Layout

```
terraform/
├── bootstrap/              # one-time: creates the S3 state bucket (own local state)
├── modules/
│   ├── vpc/                # VPC, public/private/intra subnets
│   ├── eks/                # EKS cluster + managed node group
│   ├── irsa-role/          # shared IRSA trust-policy + role, used by the two below
│   ├── ingress-controller/ # aws-load-balancer-controller helm release + its IRSA role
│   └── ebs-csi/            # aws-ebs-csi-driver EKS addon + its IRSA role
├── locals.tf               # single source of truth for cluster/node config
├── main.tf                 # wires vpc -> eks -> ingress-controller / ebs-csi
├── outputs.tf
├── providers.tf            # backend, aws/helm provider config
└── README.md
```

## Prerequisites

- Terraform >= 1.10 (needed for native S3 state locking)
- AWS credentials, active in your shell
- `kubectl`

## 1. Bootstrap remote state

```
cd bootstrap
terraform init
terraform apply
terraform output state_bucket
```

Copy that bucket name into `../providers.tf`'s `backend "s3" { bucket = "..." }`
(backend blocks can't use variables, so this has to be pasted in literally).

## 2. Init & apply the main infra

```
cd ..
terraform init
terraform plan
terraform apply
```

Creates the VPC (public/private/intra subnets across 2 AZs), the EKS
cluster, a managed node group, the AWS Load Balancer Controller (helm,
IRSA-based IAM), and the EBS CSI driver (EKS addon, IRSA-based IAM).

## 3. Connect kubectl

```
aws eks update-kubeconfig --name cndb-eks --region ap-south-1
kubectl get nodes
```

Works immediately — `enable_cluster_creator_admin_permissions = true` grants
whoever ran `apply` cluster-admin via an access entry.

## 4. Everything else: GitOps

Install ArgoCD, apply the AppProjects and `argocd/root-application.yml` per
`argocd/root-application.yml`'s own comment. From there ArgoCD brings up
Istio, the Gateway API CRDs + Gateway, cert-manager, and the book-store apps
from `argocd/applications/`.

### TLS

The Gateway (`gateway/gateway-api.yml`) only asks the AWS Load Balancer
Controller for an **NLB** — TLS terminates at Envoy/Istio, not at the load
balancer. The cert comes from cert-manager + Let's Encrypt via a Cloudflare
DNS-01 solver (`gateway/cluster-issuer.yml`, `gateway/certificate.yml`),
landing in the `wildcard-tls` secret Envoy uses. ACM isn't part of this
flow — it only attaches to AWS-terminated TLS, which this setup doesn't use.

### DNS

The NLB only exists once the Gateway is applied through ArgoCD (`kubectl
apply` time, not `terraform apply` time), so the DNS record has to be
created after the fact:

```
kubectl get svc -n mern-devops -l istio.io/gateway-name=istio-gateway
```

Take that hostname and add a CNAME in Cloudflare for `*.cndb.atkaridarshan.online`.

## 5. Tear down

```
terraform destroy
```

The bootstrap S3 bucket is outside all of this (separate state) — remove it
yourself from `bootstrap/` only if you're done with the account for good.
