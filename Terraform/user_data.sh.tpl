#!/bin/bash
set -e

dnf install -y httpd php php-fpm php-mysqli php-mbstring git
systemctl enable --now httpd
systemctl enable --now php-fpm

cd /tmp
rm -rf app-repo
git clone ${git_repo_url} app-repo

APP_SRC="/tmp/app-repo/${app_subdir}"

rm -rf /var/www/html/*
cp -r "$APP_SRC"/* /var/www/html/

mkdir -p /var/www/html/uploads
chown -R apache:apache /var/www/html
chmod -R 775 /var/www/html/uploads

cat >> /etc/php-fpm.d/www.conf <<EOF

env[DB_HOST] = ${db_host}
env[DB_USER] = ${db_username}
env[DB_PASS] = ${db_password}
env[DB_NAME] = ${db_name}
env[AWS_S3_BUCKET] = ${s3_bucket}
env[AWS_S3_REGION] = ${aws_region}
EOF

sed -i 's/^;clear_env = no/clear_env = no/' /etc/php-fpm.d/www.conf

systemctl restart php-fpm
systemctl restart httpd