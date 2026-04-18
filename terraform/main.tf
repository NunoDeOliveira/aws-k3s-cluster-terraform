################################################################
# Main file of infrastructure.                                
# Define the resouces of aws requiered to deploy a K3s cluster.
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

# configuration of provider aws for a specifically region
provider "aws" {
  region = var.region
}

###### VPC configuration #######
# Define la VPC principal que contendrá toda la infraestructura.
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-k3s"
  }
}


# Subred pública en la Availability Zone A. Subnet for nodo worker
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidrs[0]
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "k3s-subnet-a"
  }
}

# Subred pública en la Availability Zone B. Subnet for nodo control plane
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidrs[1]
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "k3s-subnet-b"
  }
}

# Subred pública en la Availability Zone C. Subnet for nodo worker
resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidrs[2]
  availability_zone       = var.availability_zones[2]
  map_public_ip_on_launch = true

  tags = {
    Name = "k3s-subnet-c"
  }
}

###### Connectivity ##########
# Internet Gateway for provide internet access to instances
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "infra-igw"
  }
}

# Router table for public subnets, asociated with the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "k3s-public-rt"
  }
}

# Defaut route for provide outbound internet access 
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Asociate subnet A with the public route table
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# Asociate subnet B with the public route table
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Acosociate subnet C with the public route table
resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}

###### Security Group ######
# Work as a firewall for control the traffic of instances
resource "aws_security_group" "k3s_nodes" {
  name        = "${var.project_name}-nodes-sg"
  description = "Grupo de seguridad para los nodos del clúster K3s"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-nodes-sg"
  }
}

# Allows ssh access only from the administrator public IP
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.k3s_nodes.id

  cidr_ipv4   = var.my_ip
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

# Alows access to the Kubernetes API port
resource "aws_vpc_security_group_ingress_rule" "k3s_api" {
  security_group_id = aws_security_group.k3s_nodes.id

  cidr_ipv4   = var.my_ip
  from_port   = 6443
  to_port     = 6443
  ip_protocol = "tcp"
}

# Allow communication beteewn nodes of the cluster
resource "aws_vpc_security_group_ingress_rule" "intra_cluster" {
  security_group_id            = aws_security_group.k3s_nodes.id
  referenced_security_group_id = aws_security_group.k3s_nodes.id
  ip_protocol                  = "-1"
}

# Allows all the traffic from the cluster to internet
resource "aws_vpc_security_group_egress_rule" "all_outgoing" {
  security_group_id = aws_security_group.k3s_nodes.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

####### Instancias EC2 ##########
# Instace of worker node deployed in subnet A
resource "aws_instance" "worker_a" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.k3s_nodes.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-worker-a"
    Role = "worker"
  }
}

# Instace of control plane deployed in subnet B.
resource "aws_instance" "control_plane" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_b.id
  vpc_security_group_ids      = [aws_security_group.k3s_nodes.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-control-plane"
    Role = "control-plane"
  }
}

# Instace of worker node deployed in subnet C.
resource "aws_instance" "worker_c" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_c.id
  vpc_security_group_ids      = [aws_security_group.k3s_nodes.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-worker-c"
    Role = "worker"
  }
}
