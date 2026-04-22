FROM php:8.1-apache

# Install dependencies
RUN apt-get update && apt-get install -y \
    libpq-dev \
    && docker-php-ext-install pdo pdo_mysql

# Enable mod_rewrite for .htaccess routing
RUN a2enmod rewrite

# Set Apache document root to /app/backend
ENV APACHE_DOCUMENT_ROOT=/app/backend
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Copy application
COPY . /app

# Set proper permissions
RUN chown -R www-data:www-data /app

# Set working directory
WORKDIR /app

EXPOSE 80

CMD ["apache2-foreground"]
