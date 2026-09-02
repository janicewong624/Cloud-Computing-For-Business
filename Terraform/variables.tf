variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used as a prefix on every resource"
  type        = string
  default     = "library-booking"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the two public subnets (ALB + build EC2), one per AZ"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the two private subnets (RDS + ASG instances), one per AZ"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "Two AZs to spread subnets across"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# ---------------------------------------------------------------------------
# EC2 / ASG
# ---------------------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type for the ASG"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of an existing EC2 key pair, used only for the temporary build instance (ASG instances are private, no SSH)"
  type        = string
}

variable "ami_id" {
  description = "AMI ID to launch. Leave blank on first apply to use the latest Amazon Linux 2023 AMI; after you bake your own golden AMI (see README), set this to your custom AMI ID."
  type        = string
  default     = ""
}

variable "instance_profile_name" {
  description = "Existing IAM instance profile to attach to EC2 instances (e.g. the AWS Academy Learner Lab's 'LabInstanceProfile'). Leave blank if you have permission to create your own role instead."
  type        = string
  default     = "LabInstanceProfile"
}

variable "asg_min_size" {
  type    = number
  default = 1
}

variable "asg_max_size" {
  type    = number
  default = 3
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}

variable "asg_target_cpu" {
  description = "Target average CPU % for the target-tracking scaling policy"
  type        = number
  default     = 60
}

variable "my_ip_cidr" {
  description = "Your own IP in CIDR form (e.g. 1.2.3.4/32), used to restrict SSH on the temporary build instance. Get it from https://checkip.amazonaws.com"
  type        = string
}

# ---------------------------------------------------------------------------
# RDS
# ---------------------------------------------------------------------------

variable "db_name" {
  type    = string
  default = "library_booking_db"
}

variable "db_username" {
  type    = string
  default = "aws_admin"
}

variable "db_password" {
  description = "Master password for RDS. Pass via terraform.tfvars (git-ignored) or TF_VAR_db_password env var - never commit this."
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_engine" {
  description = "'mysql' for RDS MySQL, or 'aurora-mysql' for Aurora MySQL"
  type        = string
  default     = "mysql"
}

# ---------------------------------------------------------------------------
# S3
# ---------------------------------------------------------------------------

variable "s3_bucket_prefix" {
  description = "Prefix for the S3 bucket name (a random suffix is appended so it's globally unique)"
  type        = string
  default     = "library-booking-uploads"
}
