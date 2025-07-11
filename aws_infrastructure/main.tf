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
