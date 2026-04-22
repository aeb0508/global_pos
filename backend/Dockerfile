FROM php:8.1-apache

# Install dependencies
RUN apt-get update && apt-get install -y \
    libpq-dev \
    && docker-php-ext-install pdo pdo_mysql \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Enable mod_rewrite for .htaccess routing
RUN a2enmod rewrite

# Disable all MPM modules except mpm_prefork (default for php-apache)
RUN a2dismod mpm_event mpm_worker || true

# Copy application
COPY . /var/www/html

# Configure Apache to allow .htaccess
RUN sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html

# Set working directory
WORKDIR /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]
