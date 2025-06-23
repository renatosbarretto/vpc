# =============================================================================
# OUTPUTS - SPOKE MODULE
# =============================================================================

output "vpc_id" {
  description = "ID of the Spoke VPC"
  value       = aws_vpc.spoke.id
}

output "vpc_cidr" {
  description = "CIDR block of the Spoke VPC"
  value       = aws_vpc.spoke.cidr_block
}

output "vpc_arn" {
  description = "ARN of the Spoke VPC"
  value       = aws_vpc.spoke.arn
}

output "private_subnet_ids" {
  description = "IDs of the private subnets in the Spoke VPC"
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "transit_gateway_attachment_id" {
  description = "ID of the Transit Gateway VPC attachment"
  value       = aws_ec2_transit_gateway_vpc_attachment.spoke.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
}

output "availability_zones" {
  description = "List of Availability Zones used"
  value       = data.aws_availability_zones.available.names
} 