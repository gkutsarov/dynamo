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

resource "kubernetes_namespace" "postgresql_namespace" {
  metadata {
    annotations = {
      name = "postgresql"
    }
    name = "postgresql"
  }
}

resource "kubernetes_namespace" "python_app_namespace" {
  metadata {
    annotations = {
      name = "python-app"
    }
    name = "python-app"
  }
}

# Creating a k8s secret in the namespace where our python-app resides so it can connect to the Postgresql
resource "kubernetes_secret" "python_app_to_postgresql" {
  metadata {
    name = "python-app-to-postgresql"
    namespace = "python-app"
  }
  data = {
    password          = base64encode("mypassword") #Password for auth.username defined in dynamo_apps/postgresql-app.yaml
    postgres-password = base64encode("mypassword") #Password for the postgres superuser (if used)
  }
}

# Changing the defaul DB password for Postgresql - needs to be in the same namespace
resource "kubernetes_secret" "postgresql_secret" {
  metadata {
    name = "postgresqlsecret"
    namespace = "postgresql"
  }
  data = {
    password          = base64encode("mypassword") #Password for auth.username defined in dynamo_apps/postgresql-app.yaml
    postgres-password = base64encode("mypassword") #Password for the postgres superuser (if used)
  }
}
