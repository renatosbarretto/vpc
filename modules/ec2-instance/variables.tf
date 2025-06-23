variable "instance_name" {
  description = "Name for the EC2 instance and related resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the instance will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be created"
  type        = string
}

variable "allowed_icmp_cidrs" {
  description = "List of CIDR blocks to allow ICMP (ping) from"
  type        = list(string)
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
} 