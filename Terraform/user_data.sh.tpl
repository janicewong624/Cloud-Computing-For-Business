#!/bin/bash
set -euxo pipefail

dnf update -y

%{ if tier == "web" ~}
# ---------------------------------------------------------------------------
# Web tier - pure reverse proxy. Never touches RDS.
# ---------------------------------------------------------------------------
dnf install -y httpd

if ! httpd -M 2>/dev/null | grep -q proxy_http_module; then
  cat <<'MODEOF' > /etc/httpd/conf.modules.d/01-enable-proxy.conf
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so
MODEOF
fi

# Forwards everything to the internal ALB in front of the App tier, so
# healthz.php's real DB-connectivity check stays meaningful end-to-end.
cat <<EOF > /etc/httpd/conf.d/assignment-proxy.conf
ProxyPreserveHost On
ProxyPass "/" "http://${app_alb_dns_name}/"
ProxyPassReverse "/" "http://${app_alb_dns_name}/"
EOF

%{ else ~}
# ---------------------------------------------------------------------------
# App tier - runs the actual PHP app, talks to RDS.
# ---------------------------------------------------------------------------
dnf install -y httpd php php-mysqlnd php-cli jq unzip mariadb105

SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "${secret_arn}" \
  --region "${aws_region}" \
  --query SecretString --output text)

DB_HOST=$(echo "$SECRET_JSON" | jq -r .host)
DB_USER=$(echo "$SECRET_JSON" | jq -r .username)
DB_PASS=$(echo "$SECRET_JSON" | jq -r .password)
DB_NAME=$(echo "$SECRET_JSON" | jq -r .dbname)

# Names match exactly what config.php reads via getenv() - do not rename.
cat <<EOF > /etc/httpd/conf.d/assignment-env.conf
SetEnv DB_HOST "$DB_HOST"
SetEnv DB_USER "$DB_USER"
SetEnv DB_PASS "$DB_PASS"
SetEnv DB_NAME "$DB_NAME"
SetEnv AWS_S3_BUCKET "${artifact_bucket}"
SetEnv AWS_S3_REGION "${aws_region}"
EOF

mkdir -p /var/www/html

if aws s3api head-object --bucket "${artifact_bucket}" --key "${artifact_key}" --region "${aws_region}" >/dev/null 2>&1; then
  aws s3 cp "s3://${artifact_bucket}/${artifact_key}" /tmp/assignment-app.zip --region "${aws_region}"
  rm -rf /var/www/html/*
  unzip -o /tmp/assignment-app.zip -d /var/www/html
  chown -R apache:apache /var/www/html
  chmod 775 /var/www/html/uploads || true
else
  echo "<?php http_response_code(200); echo 'assignment-library-app: bootstrapped, waiting for first deploy.';" \
    > /var/www/html/index.php
  echo "<?php http_response_code(200); header('Content-Type: text/plain'); echo 'ok';" \
    > /var/www/html/healthz.php
fi
%{ endif ~}

systemctl enable httpd
systemctl restart httpd