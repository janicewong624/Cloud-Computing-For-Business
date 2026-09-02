#!/bin/bash
# Runs once on first boot of every instance launched from this launch
# template. If you've already baked a golden AMI with the app + packages
# pre-installed (recommended - see README), you can trim this down to just
# the .env-writing part below, since yum/git steps become unnecessary.
set -e

yum update -y
yum install -y httpd php php-mysqlnd git

systemctl enable httpd
systemctl start httpd

# Deploy the app if it isn't already baked into the AMI.
if [ ! -f /var/www/html/config.php ]; then
  rm -rf /var/www/html/*
  git clone https://github.com/janicewong624/Cloud-Computing-For-Business.git /tmp/app
  cp -r /tmp/app/* /var/www/html/
fi

# Write .env with the real RDS + S3 values, filled in by Terraform.
cat > /var/www/html/.env <<EOF
DB_HOST=${db_host}
DB_USER=${db_user}
DB_PASS=${db_pass}
DB_NAME=${db_name}
AWS_S3_BUCKET=${s3_bucket}
AWS_S3_REGION=${s3_region}
EOF

chown -R apache:apache /var/www/html
systemctl restart httpd
