# 🚀 Terraform Hub and Spoke Architecture on AWS

This project deploys a scalable and secure Hub and Spoke network architecture on AWS using Terraform. It leverages AWS Transit Gateway to interconnect multiple VPCs (spokes) through a central VPC (hub), providing centralized connectivity, security, and management.

![Architecture Diagram](https://user-images.githubusercontent.com/10996348/123456789-abcdef.png) 
*(Note: Replace with a real architecture diagram URL)*

---

## 🎯 Architecture Overview

The architecture consists of:

-   **Hub VPC**: A central VPC that provides shared services and connectivity.
    -   Contains public subnets for external access (e.g., via Bastion Hosts).
    -   Contains private subnets for shared services like NAT Gateways, security appliances, and monitoring tools.
    -   Hosts an **Internet Gateway** for outbound and inbound internet traffic.
    -   Uses **NAT Gateways** to allow resources in private subnets to access the internet without being publicly exposed.

-   **Spoke VPCs**: Isolated VPCs for different environments (e.g., dev, staging, prod) or applications.
    -   Typically contain only private subnets to enhance security.
    -   All traffic to the internet, to other spokes, or to on-premises networks is routed through the Hub VPC via the Transit Gateway.

-   **AWS Transit Gateway (TGW)**: Acts as a cloud router, simplifying network topology.
    -   All VPCs are attached to the TGW.
    -   A dedicated TGW Route Table controls traffic flow between the hub, spokes, and other connected networks.

---

## ✅ Features

-   **Modular Design**: Fully modularized code (`hub`, `spoke`, `ec2-instance`, `vpc-flow-logs`).
-   **Centralized Egress**: All spoke traffic to the internet is routed through NAT Gateways in the Hub.
-   **Isolated Environments**: Spokes are isolated from each other by default; inter-spoke routing can be enabled in the TGW.
-   **Remote State Management**: Securely manages Terraform state using an S3 bucket and DynamoDB for locking.
-   **Automated Documentation**: Module documentation is automatically generated using `terraform-docs`.
-   **Observability**: VPC Flow Logs are enabled for all VPCs and sent to CloudWatch Logs.
-   **Governance**: Consistent tagging across all resources for cost management and ownership tracking.

---

## 🛠️ How to Run This Project

### Prerequisites

-   [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) v1.0+
-   An AWS account with appropriate permissions.
-   AWS CLI configured with credentials.

### 1. Configure the Backend

The backend infrastructure (S3 bucket and DynamoDB table) is managed in the `/backend` directory.

> **Note**: This step only needs to be done once.

```bash
# Navigate to the backend directory
cd backend

# Initialize Terraform
terraform init

# Apply the configuration to create the S3 bucket and DynamoDB table
terraform apply
```

### 2. Configure the Main Infrastructure

All configuration for the network is in the root directory.

-   **Customize `locals.tf`**:
    -   Update the `spokes` map to define your VPC spokes.
    -   Update tag values like `CostCenter`, `Owner`, etc.
-   **Customize `variables.tf`**:
    -   Review default values and add any new variables as needed.

### 3. Deploy

```bash
# Initialize Terraform in the root directory
# This will configure the S3 backend.
terraform init

# Review the execution plan
terraform plan

# Apply the configuration
terraform apply
```

### 4. Destroy

To avoid ongoing costs, you can destroy the infrastructure.

```bash
# Destroy the network infrastructure
terraform destroy

# (Optional) Destroy the backend infrastructure
cd backend
terraform destroy
```

</rewritten_file>