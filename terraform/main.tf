################################################################
# Main file of infrastructure.
# Define the resources of AWS required to deploy a K3s cluster.
################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.5.0"
}

# Configuration of AWS provider for a specific region
provider "aws" {
  region = var.region
}

####### Network configuration #######
# Define Virtual Private Cloud
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC-cluster"
  }
}

# Public subnet in Availability Zone A. Subnet for control plane
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidrs[0]
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "k3s-subnet-a"
  }
}

# Private subnet in Availability Zone B. Subnet for worker node
resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidrs[1]
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "k3s-subnet-b"
  }
}

# Private subnet in Availability Zone C. Subnet for worker node
resource "aws_subnet" "private_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidrs[2]
  availability_zone       = var.availability_zones[2]
  map_public_ip_on_launch = false

  tags = {
    Name = "k3s-subnet-c"
  }
}

######### Connectivity ###########
# Internet Gateway to provide Internet access to the public subnet
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "internet-gateway"
  }
}

# Elastic IP for the NAT Gateway
resource "aws_eip" "elastic_ip" {
  domain = "vpc"

  tags = {
    Name = "elastic-ip"
  }
}

# NAT Gateway to provide Internet access to private subnets
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.elastic_ip.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "nat-gateway"
  }

  depends_on = [aws_internet_gateway.internet_gateway]
}

###### Route tables ##########
# Public route table for the control plane subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "public-routetable-control-plane"
  }
}

# Default route from public subnet to Internet Gateway
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

# Associate public subnet A with the public route table
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# Private route table for worker subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-routetable-workers"
  }
}

# Default route from private subnets to Internet through NAT Gateway
resource "aws_route" "private_nat_access" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# Associate subnet B with the private route table
resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# Associate subnet C with the private route table
resource "aws_route_table_association" "private_c" {
  subnet_id      = aws_subnet.private_c.id
  route_table_id = aws_route_table.private.id
}

####### Security Group ########
# Firewall for controlling traffic to the K3s cluster instances
resource "aws_security_group" "k3s_nodes" {
  name        = "${var.project_name}-nodes-secgroup"
  description = "Security Group for the K3s cluster nodes"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-nodes-secgroup"
  }
}

# Allow SSH access only from the administrator public IP
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.k3s_nodes.id

  cidr_ipv4   = var.local_ip
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

# Allow access to the Kubernetes/K3s API only from the administrator public IP
resource "aws_vpc_security_group_ingress_rule" "k3s_api" {
  security_group_id = aws_security_group.k3s_nodes.id

  cidr_ipv4   = var.local_ip
  from_port   = 6443
  to_port     = 6443
  ip_protocol = "tcp"
}

# HTTP access for the API Gateway
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.k3s_nodes.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

# NodePort range for exposing K3s services externally
resource "aws_vpc_security_group_ingress_rule" "nodeport_k3s" {
  security_group_id = aws_security_group.k3s_nodes.id

  cidr_ipv4   = var.local_ip
  from_port   = 30000
  to_port     = 32767
  ip_protocol = "tcp"
}

# Allow internal communication between cluster nodes
resource "aws_vpc_security_group_ingress_rule" "intra_cluster" {
  security_group_id            = aws_security_group.k3s_nodes.id
  referenced_security_group_id = aws_security_group.k3s_nodes.id
  ip_protocol                  = "-1"
}

# Allow all outgoing traffic from cluster nodes
resource "aws_vpc_security_group_egress_rule" "all_outgoing" {
  security_group_id = aws_security_group.k3s_nodes.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

####### EC2 instances ##########
# Control plane instance in Availability Zone A
resource "aws_instance" "control_plane" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.k3s_nodes.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  # Install K3s control plane
  user_data = <<-EOF
              #!/bin/bash
              curl -sfL https://get.k3s.io | K3S_TOKEN=${var.k3s_token} sh -
              EOF

  tags = {
    Name = "${var.project_name}-control-plane"
    Role = "control_plane"
  }
}

# Worker node instance in Availability Zone B
resource "aws_instance" "worker_b" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private_b.id
  vpc_security_group_ids      = [aws_security_group.k3s_nodes.id]
  key_name                    = var.key_name
  associate_public_ip_address = false

  # Install K3s worker node
  user_data = <<-EOF
              #!/bin/bash
              sleep 90
              curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.control_plane.private_ip}:6443 K3S_TOKEN=${var.k3s_token} sh -s -agent
              EOF

  tags = {
    Name = "${var.project_name}-worker-b"
    Role = "worker"
  }
}

# Worker node instance in Availability Zone C
resource "aws_instance" "worker_c" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private_c.id
  vpc_security_group_ids      = [aws_security_group.k3s_nodes.id]
  key_name                    = var.key_name
  associate_public_ip_address = false

  # Install K3s worker node
  user_data = <<-EOF
              #!/bin/bash
              sleep 90
              curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.control_plane.private_ip}:6443 K3S_TOKEN=${var.k3s_token} sh -
              EOF

  tags = {
    Name = "${var.project_name}-worker-c"
    Role = "worker"
  }
}


