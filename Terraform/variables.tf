variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC CIDR block"
}

variable "my_ip" {
  type        = string
  default     = "180.75.249.84/0" # 建议在 tfvars 中替换为你的本地真实 IP/32
  description = "Your public IP for SSH access"
}

variable "db_password" {
  type        = string
  default     = "AdminPass12345!"
  sensitive   = true
  description = "Master password for RDS"
}

variable "ami_id" {
  type        = string
  default     = "ami-0c7217cdde317cfec" # 替换为你目标 Region 的 Amazon Linux AMI
  description = "AMI ID for EC2 Launch Template"
}