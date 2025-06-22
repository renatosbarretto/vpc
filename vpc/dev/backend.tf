terraform {
  backend "s3" {
    bucket         = "terraform-state-684120556098"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
} 