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

# :pick: Building the docker image for our application

1. Once you have cloned the repo navigate to **flask_crup_app**
```
cd flask_crud_app
```
2. Once inside run the following command. Which will build our image and tag it **python-app**
```
docker build -t python-app .
```
![Alt text](imgs/building%20docker%20image.png)
3. To see the image or all docker images run:
```
docker images
```
![Alt text](imgs/listing%20docker%20images.png)

4. Leave the docker image for now. We would need it later.


# :nut_and_bolt: Manual Configuration before Deployment (for now)

1. My setup uses an IAM user called **iamadmin** with attach policy **AdministratorAccess**.
![Alt text](imgs/iamadmin%20-%20AWS%20console.png)

You can create the same user or any other user with a different name, but we need to get the ARN for the user.

This is important because in my **main.tf** I am using the ARN of the user.
Look at line #13. Make sure you put your user ARN there.

![Alt text](imgs/main.tf%20iamadmin.png)

2. Manually create ECR repository
In your IDE terminal or simply in your terminal where AWS CLI is configured run:
```
aws ecr create-repository --repository-name python-app --region eu-central-1
```
Pay attention of the output of this command we need to grab the **repositoryUri**
The ECR repository will look something like this:
```
116529247286.dkr.ecr.eu-central-1.amazonaws.com
```

Login to your ECR with the command below but replace [URI_PLACEHOLDER] with your actual URI

```
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin [URI_PLACEHOLDER]
```

Tag your already build docker image with (Optional step)
```
docker tag python-app:latest 116529247286.dkr.ecr.eu-central-1.amazonaws.com/python-app:latest 
```

Push your docker image to the ECR repository
```
docker push 116529247286.dkr.ecr.eu-central-1.amazonaws.com/python-app:latest
```

# :pick: EKS Endpoint Access Configuration
1. In eks.tf file line #9 **cluster_endpoint_public_access_cidrs** to be equal to your IP address.
![Alt text](imgs/eks_ip_access.png)

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
The setup at the moment will prompt you to enter a value for postgre_password variable. This value is once for our python app to authenticate to the database and another time 

This value is used to create two Kubernetes secrets one in python-app namespace which our app uses to authenticate to the database and another secret in postgresql namespace which we create a password for our database user and alter the default postgresql password for the postgre user.
![Alt text](imgs/terraform%20apply%20.png)

This command applies the Terraform configuration to provision the infrastructure. The `--auto-approve` flag skips the interactive approval prompt.

# :gear: Database and Application Configuration
I am using ArgoCD to deploy my application and postgresql. Check **argocd.tf** file
ArgoCD is configured to monitor **https://github.com/gkutsarov/dynamo_apps** repo.
In the **bootstrap** repo I am creating application manifests .yaml files which use helm charts to deploy the applications.

For the Postgresql there are 2 files. **postgresql-app.yaml** which uses the official Helm chart for the application which I have modifies with parameters for my use case.
Creating the following:
![Alt text](imgs/postgresql_app.png)

I use another file **postgresql-init-configmap.yaml** of type configmap with which I am creating a table called **students** during the creation of the database pod.

![Alt text](imgs/postgresql-configmap.png)

For my Python app we are doing the same with **python-app.yaml**. Creating an application manifest which points to **python_app** repository where my custom Helm chart is.
This way the application manifests uses **Chart.yaml** to install my application with **templates** files **deployment.yaml**, **service.yaml**, **ingress.yaml**.

In the **values.yaml** we pass the values we want/need to the **deployment.yaml**

It is important to note that you shold use your ECR repository which we created earlier.

![Alt text](imgs/python-app.png)
![Alt text](imgs/python-app-values.png)

# :heavy_check_mark: Verification and Accessing the EKS cluster
After deployment, to access the cluster we need to assume the role which we created in **main.tf** for our **iamadmin** user.
Replace the ARN with yours in the command below and execute it:
```
aws eks update-kubeconfig --region eu-central-1 --name DynamoEKS --role-arn arn:aws:iam::[YOUR_ARN]:role/eks_admin_role
```

![Alt text](imgs/kubectl%20role.png)

After deployment, verify that the resources have been created:
- **AWS Console:** Log in to the AWS Management Console and check the resources in the specified region.

# :star: Further Improvements

1. Create a bastion host to connect to from which we have access to the EKS cluster.
2. Network Policy for the Postgresql to limit the connections only from the python-app namespace.
3. Image tag for the docker image not to be always the **latest** but auto increment or commit sha variable
4. Deploy ECR with Terraform

# :broom: Cleanup
To destroy the resources created by Terraform:
```
terraform destroy --auto-approve
```
This command will remove all resources defined in your Terraform configuration.
