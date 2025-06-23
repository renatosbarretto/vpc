# =============================================================================
# VARIABLES - MAIN CONFIGURATION
# =============================================================================

variable "number_of_azs" {
  description = "Number of Availability Zones to use"
  type        = number
  default     = 2
  validation {
    condition     = var.number_of_azs >= 1 && var.number_of_azs <= 4
    error_message = "Number of AZs must be between 1 and 4."
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Owner       = "DevOps Team"
    CostCenter  = "Infrastructure"
    Application = "Network Infrastructure"
  }
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
} 