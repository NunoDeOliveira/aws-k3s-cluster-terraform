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
  value = [aws_subnet.public_a.id,
    aws_subnet.private_b.id,
    aws_subnet.private_c.id
  ]
}

# Availability Zones used in the deployment 
output "availability_zones" {
  description = "Availability Zones"
  value = [
    aws_subnet.public_a.availability_zone,
    aws_subnet.private_b.availability_zone,
    aws_subnet.private_c.availability_zone
  ]
}

# ID Group of security of the K3s cluster
output "k3s_security_group_id" {
  description = "ID del security group del clúster"
  value       = aws_security_group.k3s_nodes.id
}

# IP public of the control plane
output "control_plane_public_IP" {
  description = "Public IP of the control plane"
  value       = aws_instance.control_plane.public_ip
}

# Private IPs of the worker nodes
output "worker_private_IPs" {
  description = "Private IPs of the worker nodes"
  value = [
    aws_instance.worker_b.private_ip,
    aws_instance.worker_c.private_ip
  ]
}
