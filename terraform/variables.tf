###########################################################
# File of variables. Define the configurable parameters
# of the infrastructure.
###########################################################

# Region of AWS infrastructure
variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

# CIDR block of the main VPC
variable "vpc_cidr" {
  description = "CIDR block of the main VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# CIDR blocks of the public subnets
variable "subnet_cidrs" {
  description = "CIDR blocks of the public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

# Availability Zones for subnet
variable "availability_zones" {
  description = "Availability Zones for subredes"
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

# Number of instances in the cluster
variable "instance_count" {
  description = "Number of EC2 instances in the cluster"
  type        = number
  default     = 3
}

# Type of EC2 instance. In this case t3.small
variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
  default     = "t3.small"
}

# ID of the AMI image chosen for the instances
variable "ami_id" {
  description = "AMI ID for the instances EC2"
  type        = string
}

# Name of the AWS key pair used for SSH access.
variable "key_name" {
  description = "Name of the AWS key pair"
  type        = string
}

# Public IP of the administrator in CIDR notation
variable "my_ip" {
  description = "Public IP authorized for SSH access"
  type        = string
}

# Prefix for naming the project resources.
variable "project_name" {
  description = "Prefix for naming the project resources"
  type        = string
  default     = "k3s-cluster"
}
