# Copy this file to terraform.tfvars and fill in your own values.
# terraform.tfvars is git-ignored (see .gitignore) - never commit real
# passwords or IPs to a public repo.

key_name    = "Library2"
my_ip_cidr  = "180.75.249.84/32"      # https://checkip.amazonaws.com then add /32
db_password = "admin1234"     # RDS master password - 8+ chars

# Leave blank until you've built and captured your own golden AMI, then set:
# ami_id = "ami-xxxxxxxxxxxxxxxxx"
