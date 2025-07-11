variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "eu-central-1"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
}

variable "vpc_name" {
  description = "Name of the VPC created for EKS cluster"
  default     = "EKS VPC"
}

variable "vpc_cidr" {
  description = "Custom VPC CIDR where we deploy our resources in"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "eks_cluster_name" {
  description = "Name of the EKS Cluster"
  type        = string
  default     = "DynamoEKS"
}

variable "cluster_service_cidr" {
  description = "The CIDR block for the K8S service network"
  type        = string
  default     = "10.10.0.0/16"
}

variable "eks_cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.33"
}

variable "web_app_node_group_type" {
  type = string
  default = "ON_DEMAND"
}

variable "web_app_node_group_min_size" {
  type = string
  default = "1"
}

variable "web_app_node_group_max_size" {
  type = string
  default = "3"
}

variable "web_app_node_group_desired_size" {
  type = string
  default = "2"
}

variable "postgresql_node_group_type" {
  type = string
  default = "ON_DEMAND"
}

variable "postgresql_node_group_min_size" {
  type = string
  default = "1"
}

variable "postgresql_node_group_max_size" {
  type = string
  default = "3"
}

variable "postgresql_node_group_desired_size" {
  type = string
  default = "2"
}




