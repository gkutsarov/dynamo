# AWS Infrastructure with Terraform: Full Documentation

# :blue_book: Overview

This repository provisions a complete AWS infrastructure using Terraform. It is designed for deploying a secure and scalable Kubernetes platform with GitOps using ArgoCD. The stack includes EKS, VPC, IAM roles, service accounts, load balancing and secret management.

# :wrench: Key Features:

- **AWS EKS**: Managed Kubernetes cluster with two auto-scaling node groups. One for the web app and one for the database.
- **AWS VPC**: The networking environment where our EKS cluster run. Public and Private subnets, NAT Gateway for Private subnets.
- **AWS IAM Roles**: The Roles + policies which are needed for service accounts to access different AWS resources.
- **AWS Secret Manager**: For storing and fetching secrets securely for our infrastructure/service accounts.
- **ALB**: Deploys ALB Controller in our EKS.
- **SA**: Service Accounts + needed roles and policies which they need to perform certain actions.
- **ArgoCD**: GitOps CD tool which streamlines the process of deploying applications on our cluster.

# :file_folder: Project Structure and File Descriptions

Here’s a breakdown of the key files in this repository:

- **main.tf**
    - Creates AWS IAM role, Kubernetes namespaces and Kubernetes secrets.
    - Manages AWS Secrets Manager entries.
- **eks.tf**
    - Provisions EKS cluster with cluster-level settings
    - Configures two managed node groups - one for **web** and one for **database** applications.
    - Defines cluster add-ons: **coredns, kube-proxy, vpc-cni, aws-ebs-csi-driver**
    - IRSA roles for:
        - ALB Controller
        - EBS CSI Driver
- **vpc.tf**
    - Creates VPC, public & private subnets, route tables, internet & NAT gateway.
    - The subnet IDs are referenced in eks.tf for node placement.
- **alb_controller.tf**
    - Deploys ALB Ingress Controller via Helm with custom values.
    - Binds aws-load-balancer-controller service account to IAM role with necessary permissions.
- **argocd.tf** 
    - Installs ArgoCD into the cluster via Helm
    - Configures repository credentials.
    - Bootstrap initial App of Apps ArgoCD deployment.
- **data.tf**
    - Contains various data miscellaneous resources:
- **terraform.tf**
    - Provider configuration for: AWS, Kubernetes, Helm
    - Ensures Terraform can communicate with all required APIs
- **values.yaml.tpl**
    - Values file as a template used for ArgoCD. Used for dynamically pass the username + password for the GitHub repository.
- **variables.tf**
    - Declares variables used accross modules

# :shield: Security Highlights
- Usage of **IRSA** for fine-grained service account permissions
- Secrets stored in **AWS Secrets Manager** (secrets are not in plain text)
- EKS endpoint access is **CIDR-restricted** 

# Architecture Diagram
```
             +---------------------------+
             |        AWS Account        |
             +-------------+-------------+
			   |
                           |
         +---------------------------------+
         |               VPC               |
         +----------------+----------------+
                          |
              +-----------+-----------+
              |			      |	
              |			      |
   +---------------------------+   +------------------------+
   |      Private Subnet       |   |     Public Subnet      |
   |   (EKS Nodes, Internal)   |   |   (ALB, NAT Gateway)   |
   +---------------------------+   +------------------------+
                |
             IAM (IRSA)
                |
        +---------------+          +-------------------------+
        |   EKS Pods    | <------> |     AWS Services        |
        +---------------+          | (S3, CW, EBS, Secrets)  |
                |                  +-------------------------+
                |
        +---------------+
        |    ArgoCD     |
        |  App of Apps  |
        +---------------+
```

# :hammer_and_wrench: Prerequisites
1. Install required tools
    - **Terraform:** Ensure Terraform is installed. You can download it from the [official website](https://developer.hashicorp.com/terraform/install).
    - **AWS CLI:** Install the AWS Command Line Interface. Follow the [installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
    - **Docker** Ensure Docker Engine is installed. Follow the [installation guide](https://docs.docker.com/engine/install/)
    - **kubectl** Ensure kubectl is installed. Follow the [installation guide](https://kubernetes.io/docs/tasks/tools/)
2. Configure AWS Credentials
Set up your AWS credentials to allow Terraform to authenticate with AWS:
```
aws configure
```
This command will prompt you to enter:
- **AWS Access Key ID**
- **AWS Secret Access Key**
- **Default region name** (e.g us-east-1)

This will create the `~/.aws/credentials` and `~/.aws/config` files with your credentials and configuration.

Alternatively, you can manually create the `~/.aws/credentials` file:
```
[default]
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
```

Terraform will use these credentials by default.

# :nut_and_bolt: Manual Configuration before Deployment (for now)

1. My setup uses an IAM user called *iamadmin* with attach policy *AdministratorAccess*.
![Alt text](imgs/iamadmin%20-%20AWS%20console.png)

You can create the same user or any other user with a different name, but we need to get the ARN for the user.

This is important because in my *main.tf* I am using the ARN of the user.
![Alt text](imgs/main.tf%20iamadmin.png)

Look at line #13. Make sure you put your user ARN there.

2. Manually create ECR repository
In your IDE terminal or simply in your terminal where AWS CLI is configured run:
```
aws ecr create-repository --repository-name python-app --region eu-central-1
```
Pay attention of the output of this command we need to grab the repositoryUri


# :rocket: Deployment Steps
1. **Navigate to the Infrastructure Directory**
```
cd aws_infra
```
2. **Initialize Terraform**
```
terraform init
```
This command initializes the working directory containing Terraform cinfiguration files.

3. **Apply the Terraform Configuration**
```
terraform apply --auto-approve
```
This command applies the Terraform configuration to provision the infrastructure. The `--auto-approve` flag skips the interactive approval prompt.

# :heavy_check_mark: Verification
After deployment, verify that the resources have been created:
- **AWS Console:** Log in to the AWS Management Console and check the resources in the specified region.

# :broom: Cleanup
To destroy the resources created by Terraform:
```
terraform destroy --auto-approve
```
This command will remove all resources defined in your Terraform configuration.
