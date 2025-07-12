### Create EKS admin role
resource "aws_iam_role" "eks_admin_role" {
  name = "eks_admin_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          #AWS = "arn:aws:iam::905418146175:user/eks_admin"
          AWS = "arn:aws:iam::905418146175:user/iamadmin"
        }
      },
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = { Service = "eks.amazonaws.com" }
      }
    ]
  })
}

# Create namespace argocd for ArgoCD
resource "kubernetes_namespace" "argocd_namespace" {
  metadata {
    annotations = {
      name = "argocd"
    }
    name = "argocd"
  }
}

## Create k8s secret from the stored secret in AWS, which we will pass to our ArgoCD
resource "kubernetes_secret" "argocd_repo_secret" {
  metadata {
    name      = "github-argo"
    namespace = "argocd"
  }

  data = {
    username = (jsondecode(data.aws_secretsmanager_secret_version.github_token.secret_string)["username"])
    token    = (jsondecode(data.aws_secretsmanager_secret_version.github_token.secret_string)["token"])
  }

}
