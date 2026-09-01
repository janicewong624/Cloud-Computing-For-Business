variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix applied to every resource name, per the assignment-{resource} convention."
  type        = string
  default     = "assignment"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across - matches the diagram's us-east-1a / us-east-1b."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# CIDRs below match the diagram's subnet numbering exactly (Public Subnet
# 1/2, Private Subnet 3/4 = web, 5/6 = app, 7/8 = database).
variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/20", "10.0.16.0/20"]
}

variable "web_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.32.0/20", "10.0.48.0/20"]
}

variable "app_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.64.0/20", "10.0.80.0/20"]
}

variable "db_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.160.0/20", "10.0.176.0/20"]
}

variable "instance_type" {
  description = "EC2 instance type for Web/App tier instances. Bump this later if t3.micro is insufficient - no other changes needed."
  type        = string
  default     = "t3.micro"
}

variable "instance_profile_name" {
  description = "Existing AWS Academy IAM instance profile (cannot create a new one in a Learner Lab account)."
  type        = string
  default     = "LabInstanceProfile"
}

variable "bastion_allowed_cidr" {
  description = "Your IP allowed to SSH into the bastion, e.g. \"203.0.113.4/32\". Find yours with `curl ifconfig.me`. Never leave this as 0.0.0.0/0."
  type        = string
}

variable "key_name" {
  description = "Name of an existing EC2 key pair (create one first: EC2 console -> Key Pairs -> Create) used to SSH into the bastion."
  type        = string
}

variable "db_name" {
  type    = string
  default = "library_booking_db"
}

variable "db_username" {
  type    = string
  default = "admin"
}

variable "secret_name" {
  type    = string
  default = "assignment-db-credentials"
}

variable "s3_bucket_name" {
  description = "Globally-unique bucket name prefix for room/equipment/book photo uploads and app release artifacts. The account ID is appended automatically in s3.tf."
  type        = string
  default     = "assignment-s3-uploads"
}

variable "artifact_key" {
  description = "S3 object key that holds the app release zip, pulled by App tier instances at boot."
  type        = string
  default     = "artifacts/assignment-app.zip"
}

variable "health_check_path" {
  type    = string
  default = "/healthz.php"
}

variable "web_asg_min_size" {
  type    = number
  default = 2
}

variable "web_asg_max_size" {
  type    = number
  default = 4
}

variable "web_asg_desired_capacity" {
  type    = number
  default = 2
}

variable "app_asg_min_size" {
  type    = number
  default = 2
}

variable "app_asg_max_size" {
  type    = number
  default = 4
}

variable "app_asg_desired_capacity" {
  type    = number
  default = 2
}