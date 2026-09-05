variable "name_prefix" {
  description = "Prefix applied to all resource names in this module."
  type        = string
  default     = "assignment"
}

variable "vpc_id" {
  description = "VPC ID these security groups belong to."
  type        = string
}

variable "my_ip_cidr" {
  description = "Your own IP in CIDR form (e.g. 1.2.3.4/32), the only source allowed to SSH into the bastion host."
  type        = string
}
