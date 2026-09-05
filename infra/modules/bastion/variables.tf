variable "name_prefix" {
  type    = string
  default = "assignment"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "public_subnet_id" {
  description = "Public subnet (AZ 1) the bastion sits in, per the diagram."
  type        = string
}

variable "bastion_sg_id" {
  type = string
}

variable "key_name" {
  description = "Existing EC2 key pair name, for SSH into the bastion."
  type        = string
}
