module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20" # Use the latest possible version
  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version

  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["130.204.137.163/32"]

  authentication_mode = "API"

  access_entries = {
    eks_admin = {
      principal_arn = aws_iam_role.eks_admin_role.arn

      policy_associations = {
        eks_admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
        eks_cluster_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
  cluster_addons = {

    #Provides DNS for service discovery within the cluster
    coredns = { 
        most_recent = true
    }

    #Supports IAM Roles for Service Accounts. Allows pods to assume IAM roles.
    eks-pod-identity-agent = { 
        most_recent = true
    }

    #Essential for K8S networking, without it pods can't communicate properly in K8S.
    kube-proxy = {
        most_recent = true
    }

    #Integrates Pods with the VPC network. Assign VPC IP address directly to pods.
    vpc-cni = {
        most_recent = true
    }

    #Manages dynamic provisioning of EBS volues to pods. Enables persistent storage for stateful workloads.
    aws-ebs-csi-driver = {
        most_recent = true
        service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
}

vpc_id = module.vpc.vpc_id
subnet_ids = module.vpc.private_subnets
control_plane_subnet_ids = module.vpc.private_subnets

cluster_service_ipv4_cidr = var.cluster_service_cidr

enable_irsa = true

eks_managed_node_group_defaults = {
    instance_types = ["t2.medium", "t2.large", "t2.xlarge"]
}

eks_managed_node_groups = {

    web_app_nodes = {
        name = "web_app_node_group"
        cluster_name = var.eks_cluster_name
        subnet_ids = module.vpc.private_subnets
        ami_type = "AL2023_x86_64_STANDARD"
        min_size = var.web_app_node_group_min_size
        max_size = var.web_app_node_group_max_size
        desired_size = var.web_app_node_group_desired_size
        capacity_type = var.web_app_node_group_type
        ebs_optimized = true
        instance_types = ["t2.large"]
        labels = {
            environment = "production"
            workload = "web"
        }
    }

    database_nodes = {
        name = "postgresql_node_group"
        cluster_name = var.eks_cluster_name
        subnet_ids = module.vpc.private_subnets
        ami_type = "AL2023_x86_64_STANDARD"
        min_size = var.postgresql_node_group_min_size
        max_size = var.postgresql_node_group_max_size
        desired_size = var.postgresql_node_group_desired_size
        capacity_type = var.postgresql_node_group_type
        ebs_optimized = true
        instance_types = ["t2.large"]
        labels = {
            environment = "production"
            workload = "database"
        }
        taints = [
            {
                value = "database"
                effect = "NO_SCHEDULE"
            }
        ]
    }
}
}

module "ebs_csi_irsa_role" {
	source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

	role_name             = "${var.eks_cluster_name}-ebs-csi"
	attach_ebs_csi_policy = true

	oidc_providers = {
		main = {
			provider_arn               = module.eks.oidc_provider_arn
			namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
		}
	}
}

