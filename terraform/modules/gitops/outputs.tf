output "argocd_namespace" { value = var.argocd_namespace }
output "argocd_url_note"  { value = "http://<NLB-hostname>/argocd  (get NLB: kubectl get gateway bookstore-gateway -n default -o jsonpath='{.status.addresses[0].value}')" }
