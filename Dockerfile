FROM ubuntu:bionic as staging

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y software-properties-common language-pack-en-base \
    && LC_ALL=en_US.UTF-8 \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai  /etc/localtime
RUN add-apt-repository -y ppa:ondrej/php \
&& apt-get update \
&& apt-get install -y mcrypt libmcrypt-dev php7.4-cli php7.4-dev

ADD mcrypt-1.0.3.tgz /tmp
WORKDIR /tmp/mcrypt-1.0.3
RUN phpize  &&  ./configure &&  make  && make install

ADD swoole-4.5.6.tgz /tmp
WORKDIR /tmp/swoole-4.5.6
RUN phpize  &&  ./configure &&  make  && make install

FROM ubuntu:bionic

RUN mv /etc/apt/sources.list /etc/apt/sourses.list.bak
ADD sources.list /etc/apt/sources.list

# Install packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y software-properties-common language-pack-en-base \
    && LC_ALL=en_US.UTF-8 \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai  /etc/localtime
RUN add-apt-repository -y ppa:ondrej/php \
&& apt-get update \
&& apt-get install -y mcrypt libmcrypt-dev php7.4-fpm php7.4-cli php7.4-readline php7.4-mbstring php7.4-zip php7.4-intl php7.4-json php7.4-xml php7.4-curl php7.4-gd php7.4-pdo php7.4-mysql php-imagick php-redis php-mongodb php-memcache php-amqplib php7.4-bcmath --fix-missing \
&& apt-get install -y nginx \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*

COPY --from=staging /usr/lib/php/20190902/mcrypt.so /usr/lib/php/20190902/mcrypt.so
COPY --from=staging /usr/lib/php/20190902/swoole.so /usr/lib/php/20190902/swoole.so

RUN touch /etc/php/7.4/mods-available/mcrypt.ini \
&& echo "extension=mcrypt.so" >> /etc/php/7.4/mods-available/mcrypt.ini \
&& ln -s /etc/php/7.4/mods-available/mcrypt.ini /etc/php/7.4/cli/conf.d/20-mcrypt.ini \
&& ln -s /etc/php/7.4/mods-available/mcrypt.ini /etc/php/7.4/fpm/conf.d/20-mcrypt.ini \
&& touch /etc/php/7.4/mods-available/swoole.ini \
&& echo "extension=swoole.so" >> /etc/php/7.4/mods-available/swoole.ini \
&& ln -s /etc/php/7.4/mods-available/swoole.ini /etc/php/7.4/cli/conf.d/20-swoole.ini \
&& ln -s /etc/php/7.4/mods-available/swoole.ini /etc/php/7.4/fpm/conf.d/20-swoole.ini

# 安装composer
RUN php -r "copy('https://install.phpcomposer.com/installer', 'composer-setup.php');" \
&& php composer-setup.php \
&& php -r "unlink('composer-setup.php');" \
&& mv composer.phar /usr/local/bin/composer \
&& composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/ 


ENTRYPOINT ["/sbin/init"]