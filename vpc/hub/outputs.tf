# Outputs da VPC Hub

output "vpc_id" {
  description = "ID da VPC Hub"
  value       = aws_vpc.hub.id
}

output "vpc_cidr" {
  description = "CIDR da VPC Hub"
  value       = aws_vpc.hub.cidr_block
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas da VPC Hub"
  value       = aws_subnet.hub_public[*].id
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas da VPC Hub"
  value       = aws_subnet.hub_private[*].id
}

output "transit_gateway_id" {
  description = "ID do Transit Gateway"
  value       = aws_ec2_transit_gateway.hub.id
}

output "transit_gateway_arn" {
  description = "ARN do Transit Gateway"
  value       = aws_ec2_transit_gateway.hub.arn
}

output "nat_gateway_ids" {
  description = "IDs dos NAT Gateways"
  value       = aws_nat_gateway.hub[*].id
}

output "internet_gateway_id" {
  description = "ID do Internet Gateway"
  value       = aws_internet_gateway.hub.id
} 