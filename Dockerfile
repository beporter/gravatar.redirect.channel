FROM php:8.4-apache

RUN a2enmod rewrite
RUN docker-php-ext-install opcache && docker-php-ext-enable opcache
