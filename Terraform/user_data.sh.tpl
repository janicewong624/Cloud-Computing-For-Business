#!/bin/bash
yum update -y
yum install -y httpd php php-mysqlnd
systemctl start httpd
systemctl enable httpd

echo "<h1>Welcome to Library Resource Scheduling System</h1>" > /var/www/html/index.html