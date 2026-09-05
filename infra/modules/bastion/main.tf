# A small, optional EC2 instance in the public subnet, matching the
# architecture diagram's documented manual-access path into the private
# tiers. Not used by the CI/CD pipeline itself - deploy.yml never touches
# it, since app instances self-deploy from S3 on boot and don't need SSH.
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.bastion_sg_id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = {
    Name = "${var.name_prefix}-bastion"
  }
}
