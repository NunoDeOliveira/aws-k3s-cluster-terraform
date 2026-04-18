############################################################
# Archivo de outputs.This file expose infrastructure values
# when the terraform is apply
############################################################

# VPC ID of the VPc 
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

# CIDR block of the VPC
output "vpc_cidr" {
  description = "CIDR of the VPC"
  value       = aws_vpc.main.cidr_block
}

# IDs of public subnets  
output "subnet_ids" {
  description = "IDs of the public subnets"
  value = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id,
    aws_subnet.public_c.id
  ]
}

# Availability Zones used in the deployment 
output "availability_zones" {
  description = "Availability Zones"
  value = [
    aws_subnet.public_a.availability_zone,
    aws_subnet.public_b.availability_zone,
    aws_subnet.public_c.availability_zone
  ]
}

# ID Group of security of the K3s cluster
output "k3s_security_group_id" {
  description = "ID del security group del clúster"
  value       = aws_security_group.k3s_nodes.id
}

# IP public of the control plane node
output "control_plane_public_ip" {
  description = "Public IP of the control plane node"
  value       = aws_instance.control_plane.public_ip
}

# Public IPs of the worker nodes
output "worker_public_ips" {
  description = "Public IPs of the worker nodes"
  value = [
    aws_instance.worker_a.public_ip,
    aws_instance.worker_c.public_ip
  ]
}
