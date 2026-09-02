#!/bin/bash
# Runs on an app instance via SSM Run Command (see .github/workflows/db-init.yml).
# Idempotent: skips the import if library_booking_db.users already exists, so
# accidentally re-running the workflow later is a safe no-op instead of
# crashing on duplicate-key errors from schema.sql's seed INSERTs.
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
SECRET_ID="assignment-db-credentials"
SCHEMA_S3_URI="$1"
BUCKET_NAME="${2:-}"

SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_ID" --region "$AWS_REGION" --query SecretString --output text)

DB_HOST=$(echo "$SECRET_JSON" | jq -r .host)
DB_USER=$(echo "$SECRET_JSON" | jq -r .username)
DB_PASS=$(echo "$SECRET_JSON" | jq -r .password)

# schema.sql has three tables with an image_url column: rooms, equipment, books.
rewrite_image_urls() {
  local s3_prefix="https://${BUCKET_NAME}.s3.${AWS_REGION}.amazonaws.com/uploads/"
  for table in rooms equipment books; do
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "library_booking_db" -e \
      "UPDATE ${table} SET image_url = REPLACE(image_url, '/uploads/', '${s3_prefix}') WHERE image_url LIKE '/uploads/%';"
  done
  echo "Updated sample image URLs (rooms/equipment/books) to S3."
}

ALREADY_SEEDED=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -N -e \
  "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='library_booking_db' AND table_name='users'")

if [ "$ALREADY_SEEDED" -gt 0 ]; then
  echo "library_booking_db.users already exists - database already seeded, skipping import."
  if [ -n "$BUCKET_NAME" ]; then
    rewrite_image_urls
  fi
  exit 0
fi

aws s3 cp "$SCHEMA_S3_URI" /tmp/schema.sql --region "$AWS_REGION"
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" < /tmp/schema.sql

if [ -n "$BUCKET_NAME" ]; then
  rewrite_image_urls
fi

echo "Database seeded successfully."
