variable "name_prefix" {
  description = "Prefix applied to all resource names in this module."
  type        = string
  default     = "assignment"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  description = "Two availability zones to spread every tier's subnets across."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Web tier - ALB + bastion host."
  type        = list(string)
  default     = ["10.0.0.0/20", "10.0.16.0/20"]
}

variable "private_app_subnet_cidrs" {
  description = "Application tier - ASG/EC2 instances."
  type        = list(string)
  default     = ["10.0.32.0/20", "10.0.48.0/20"]
}

variable "private_db_subnet_cidrs" {
  description = "Database tier - RDS."
  type        = list(string)
  default     = ["10.0.64.0/20", "10.0.80.0/20"]
}
