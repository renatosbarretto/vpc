variable "vpc_id" {
  description = "The ID of the VPC to enable flow logs for"
  type        = string
}

variable "log_group_name" {
  description = "The name of the CloudWatch Log Group"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
} 