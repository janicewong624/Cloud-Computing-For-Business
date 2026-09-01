aws_region  = "us-east-1"
name_prefix = "library-system"

# REQUIRED - fill these in before `terraform apply`:
bastion_allowed_cidr = "27.125.246.17/32" # run `curl ifconfig.me`, append /32
key_name              = "Library2" # create one first: EC2 console -> Key Pairs