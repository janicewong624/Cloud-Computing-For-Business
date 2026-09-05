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
  description = "Availability zones to spread subnets across."
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

variable "my_ip_cidr" {
  description = "Your own IP in CIDR form (e.g. 1.2.3.4/32), used to restrict SSH on the bastion host. Get it from https://checkip.amazonaws.com"
  type        = string
}

variable "key_name" {
  description = "Name of an existing EC2 key pair, used only for the bastion host."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for app servers. Bump this later if t3.micro is insufficient - no other changes needed."
  type        = string
  default     = "t3.micro"
}

variable "instance_profile_name" {
  description = "Existing AWS Academy IAM instance profile (cannot create a new one in a Learner Lab account)."
  type        = string
  default     = "LabInstanceProfile"
}

variable "db_name" {
  type    = string
  default = "library_booking_db"
}

variable "db_username" {
  type    = string
  default = "aws_admin"
}

variable "secret_name" {
  type    = string
  default = "assignment-db-credentials"
}

variable "s3_bucket_name" {
  description = "Globally-unique bucket name for room/equipment/book photo uploads."
  type        = string
  default     = "assignment-s3-uploads"
}

variable "artifact_key" {
  description = "S3 object key (within s3_bucket_name) that deploy.yml uploads the app release artifact to."
  type        = string
  default     = "artifacts/library-booking-app.zip"
}

variable "health_check_path" {
  type    = string
  default = "/healthz.php"
}

variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 4
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}
