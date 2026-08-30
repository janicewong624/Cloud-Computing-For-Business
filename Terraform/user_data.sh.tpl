#!/bin/bash
set -e

dnf install -y httpd php php-mysqli php-mbstring git
systemctl enable --now httpd

cd /tmp
rm -rf app-repo
git clone ${git_repo_url} app-repo

# If your PHP app lives in a subfolder of the repo (e.g. the repo root has
# multiple project folders like the teacher's sample), adjust this path.
APP_SRC="/tmp/app-repo/${app_subdir}"

rm -rf /var/www/html/*
cp -r "$APP_SRC"/* /var/www/html/

mkdir -p /var/www/html/uploads
chown -R apache:apache /var/www/html
chmod -R 775 /var/www/html/uploads

# Environment variables config.php reads for the DB connection. These are
# set in the Apache service environment so PHP's getenv() picks them up.
cat >> /etc/environment <<EOF
DB_HOST=${db_host}
DB_USER=${db_username}
DB_PASS=${db_password}
DB_NAME=${db_name}
AWS_S3_BUCKET=${s3_bucket}
AWS_S3_REGION=${aws_region}
EOF

mkdir -p /etc/systemd/system/httpd.service.d
cat > /etc/systemd/system/httpd.service.d/env.conf <<EOF
[Service]
Environment="DB_HOST=${db_host}"
Environment="DB_USER=${db_username}"
Environment="DB_PASS=${db_password}"
Environment="DB_NAME=${db_name}"
Environment="AWS_S3_BUCKET=${s3_bucket}"
Environment="AWS_S3_REGION=${aws_region}"
EOF

systemctl daemon-reload
systemctl restart httpd
