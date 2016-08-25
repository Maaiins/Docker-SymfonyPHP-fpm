FROM php:5-fpm

MAINTAINER Lauser, Nicolai <nicolai@lauser.info>

ARG proxy

ENV http_proxy ${proxy}
ENV https_proxy ${proxy}

ADD oracle /tmp
ADD symfony.ini /usr/local/etc/php/conf.d/

RUN addgroup app-cache \
    && adduser www-data app-cache \
    && mkdir -p /app

# OCI8 prerequisits
RUN apt-get update \
    && apt-get install -y unzip --no-install-recommends \
    && mkdir -p /usr/lib/oracle/12.1/client64/lib \
    && unzip /tmp/instantclient-basic-linux.x64-12.1.0.2.0.zip -d /tmp \
    && mv /tmp/instantclient_12_1/* /usr/lib/oracle/12.1/client64/lib \
    && rm -rf /tmp/instantclient_12_1 \
    && unzip /tmp/instantclient-sdk-linux.x64-12.1.0.2.0.zip -d /tmp \
    && mv /tmp/instantclient_12_1/* /usr/lib/oracle/12.1/client64/lib \
    && ln -sf /usr/lib/oracle/12.1/client64/lib/libclntsh.so.12.1 /usr/lib/oracle/12.1/client64/lib/libclntsh.so \
    && rm -rf /tmp/instantclient_12_1 /tmp/instantclient-basic-linux.x64-12.1.0.2.0.zip /tmp/instantclient-sdk-linux.x64-12.1.0.2.0.zip \
    && apt-get purge -y --auto-remove unzip \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && apt-get clean

RUN apt-get update \
    && apt-get install -y libaio1 libaio-dev zlib1g-dev libicu-dev g++ --no-install-recommends \
    && if [! -z ${http_proxy} ]; then pear config-set http_proxy ${http_proxy}; fi \
    && printf "\n" | pecl install oci8-1.4.10 apcu-4.0.11 \
    && docker-php-ext-install pdo intl \
    && docker-php-ext-enable oci8 apcu \
    && apt-get purge -y --auto-remove g++ \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && apt-get clean

VOLUME /app
WORKDIR /app

EXPOSE 9000

CMD ["php-fpm", "-F"]
