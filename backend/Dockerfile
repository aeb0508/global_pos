FROM php:8.1-cli

# Install dependencies
RUN apt-get update && apt-get install -y \
    libpq-dev \
    && docker-php-ext-install pdo pdo_mysql \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy application
COPY . /var/www/html

# Set working directory
WORKDIR /var/www/html

EXPOSE 80

# Use PHP built-in server
CMD ["php", "-S", "0.0.0.0:80", "-t", "/var/www/html"]