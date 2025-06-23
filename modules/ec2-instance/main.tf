# =============================================================================
# MODULE: EC2 INSTANCE
# Creates a single EC2 instance with a security group for testing
# =============================================================================

# =============================================================================
# DATA SOURCES
# =============================================================================

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# =============================================================================
# IAM FOR SSM
# =============================================================================

resource "aws_iam_role" "ssm_role" {
  name = "${var.instance_name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.instance_name}-ssm-role"
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "${var.instance_name}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

# =============================================================================
# SECURITY GROUP
# =============================================================================

resource "aws_security_group" "instance_sg" {
  name        = "${var.instance_name}-sg"
  description = "Security group for ${var.instance_name} - allows ICMP from hub/spokes and restricted outbound"
  vpc_id      = var.vpc_id

  # Allow ICMP (ping) from hub and all spokes
  ingress {
    description = "Allow ICMP (ping) from hub and spoke networks"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = var.allowed_icmp_cidrs
  }

  # Allow HTTPS outbound for SSM and updates
  egress {
    description = "Allow HTTPS outbound for SSM and system updates"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP outbound for updates (if needed)
  egress {
    description = "Allow HTTP outbound for system updates"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow DNS outbound
  egress {
    description = "Allow DNS outbound"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow DNS outbound (UDP)"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow NTP outbound
  egress {
    description = "Allow NTP outbound"
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.instance_name}-sg"
  })
}


# =============================================================================
# EC2 INSTANCE
# =============================================================================

resource "aws_instance" "this" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  subnet_id     = var.subnet_id
  
  # Security and optimization settings
  ebs_optimized = true
  
  # Metadata service v2 (IMDSv2) - more secure
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"  # IMDSv2
    http_put_response_hop_limit = 1
  }
  
  # Root block device with encryption
  root_block_device {
    encrypted   = true
    volume_size = 8
    volume_type = "gp2"
    
    tags = merge(var.common_tags, {
      Name = "${var.instance_name}-root-volume"
    })
  }
  
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  tags = merge(var.common_tags, {
    Name = var.instance_name
  })
} 