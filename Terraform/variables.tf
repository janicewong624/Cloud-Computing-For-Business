variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to prefix/tag most resources (VPC, subnets, security groups, RDS, EC2 tags). No strict length limit here."
  type        = string
  default     = "library-resource-scheduling"
}

# AWS hard-limits Application Load Balancer names and Target Group names to
# 32 characters - project_name above (28 chars) is already too long once you
# add a suffix like "-external-alb" (13 chars = 41 total, which AWS
# rejects). This separate, short variable is used ONLY for the ALB and
# Target Group names so you can keep project_name long/descriptive
# everywhere else. Keep this at 19 characters or fewer.
variable "short_name" {
  description = "Short name (max 19 chars) used only for ALB/Target Group names, which AWS caps at 32 characters"
  type        = string
  default     = "library"

  validation {
    condition     = length(var.short_name) <= 19
    error_message = "short_name must be 19 characters or fewer so '<short_name>-external-alb' stays under AWS's 32-character ALB name limit."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# AWS Academy Learner Lab accounts almost always only have a pre-existing
# role called "LabInstanceProfile" or "LabRole" available for EC2 - you
# cannot create new IAM roles yourself. Check your lab's "AWS Details" tab
# for the exact name and override it in terraform.tfvars if different.
variable "lab_instance_profile_name" {
  description = "Existing IAM instance profile name available in the Learner Lab account"
  type        = string
  default     = "LabInstanceProfile"
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair (for SSH via the bastion host). Create one in the EC2 console first if you don't have one."
  type        = string
}

variable "web_instance_type" {
  description = "Instance type for the Web Tier ASG"
  type        = string
  default     = "t3.micro"
}

variable "app_instance_type" {
  description = "Instance type for the Application Tier ASG"
  type        = string
  default     = "t3.micro"
}

variable "bastion_instance_type" {
  description = "Instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "library_booking_db"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Master password for RDS - set this in terraform.tfvars, never commit it"
  type        = string
  sensitive   = true
}

variable "git_repo_url" {
  description = "HTTPS URL of your GitHub repo containing the library-resource-scheduling app"
  type        = string
}

variable "asg_min_size" {
  description = "Minimum instances per tier's ASG"
  type        = number
  default     = 1
}

variable "asg_desired_capacity" {
  description = "Desired instances per tier's ASG"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum instances per tier's ASG"
  type        = number
  default     = 4
}