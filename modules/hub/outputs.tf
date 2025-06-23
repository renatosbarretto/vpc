# =============================================================================
# OUTPUTS - HUB MODULE
# =============================================================================

output "vpc_id" {
  description = "ID of the Hub VPC"
  value       = aws_vpc.hub.id
}

output "vpc_cidr" {
  description = "CIDR block of the Hub VPC"
  value       = aws_vpc.hub.cidr_block
}

output "vpc_arn" {
  description = "ARN of the Hub VPC"
  value       = aws_vpc.hub.arn
}

output "public_subnet_ids" {
  description = "IDs of the public subnets in the Hub VPC"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets in the Hub VPC"
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.hub.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.hub[*].id
}

output "nat_gateway_public_ips" {
  description = "Public IPs of the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = aws_ec2_transit_gateway.hub.id
}

output "transit_gateway_arn" {
  description = "ARN of the Transit Gateway"
  value       = aws_ec2_transit_gateway.hub.arn
}

output "transit_gateway_attachment_id" {
  description = "ID of the Transit Gateway VPC attachment for the Hub"
  value       = aws_ec2_transit_gateway_vpc_attachment.hub.id
}

output "transit_gateway_route_table_id" {
  description = "ID of the default Transit Gateway route table"
  value       = aws_ec2_transit_gateway.hub.association_default_route_table_id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

output "availability_zones" {
  description = "List of Availability Zones used"
  value       = data.aws_availability_zones.available.names
} 