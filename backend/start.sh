#!/bin/bash
set -e

echo "Starting PHP-FPM..."
php-fpm -D

echo "Testing Nginx configuration..."
nginx -t

echo "Starting Nginx..."
nginx -g 'daemon off;'
