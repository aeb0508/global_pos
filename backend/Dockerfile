FROM php:8.1-fpm

# Install dependencies and Nginx
RUN apt-get update && apt-get install -y \
    libpq-dev \
    nginx \
    && docker-php-ext-install pdo pdo_mysql \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy application
COPY . /var/www/html

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html

# Create Nginx configuration
RUN echo 'server { \n\
    listen 80; \n\
    root /var/www/html; \n\
    index index.php index.html; \n\
    location / { \n\
        try_files $uri $uri/ /index.php?$query_string; \n\
    } \n\
    location ~ \.php$ { \n\
        fastcgi_pass 127.0.0.1:9000; \n\
        fastcgi_index index.php; \n\
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \n\
        include fastcgi_params; \n\
    } \n\
}' > /etc/nginx/sites-available/default

# Set working directory
WORKDIR /var/www/html

EXPOSE 80

# Start both PHP-FPM and Nginx
CMD php-fpm -D && nginx -g 'daemon off;'
