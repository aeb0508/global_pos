#!/bin/sh
set -e

echo "=== Starting Global POS Backend ==="

echo "Starting PHP-FPM..."
php-fpm -D
echo "PHP-FPM started successfully"

echo "Testing Nginx configuration..."
nginx -t
echo "Nginx configuration is valid"

echo "Starting Nginx..."
exec nginx -g "daemon off;"
