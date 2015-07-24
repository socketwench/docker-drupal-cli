FROM ubuntu:12.04

MAINTAINER Leonid Makarov <leonid.makarov@blinkreaction.com>

# Set timezone and locale.
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Prevent services autoload (http://jpetazzo.github.io/2013/10/06/policy-rc-d-do-not-start-services-automatically/)
RUN echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

# Adding https://launchpad.net/~ondrej/+archive/ubuntu/php5 PPA repo for php5.6
RUN echo "deb http://ppa.launchpad.net/ondrej/php5-5.6/ubuntu precise main " >> /etc/apt/sources.list

# Basic packages
RUN \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes install \
    supervisor curl wget zip git mysql-client pv apt-transport-https \
    --no-install-recommends && \
    # Cleanup
    DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Apache Utilities

RUN \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes install \
    apache2-utils \
    --no-install-recommends && \
    # Cleanup
    DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# PHP packages
RUN \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes install \
    php5-common php5-cli php-pear php5-mysql php5-imagick php5-mcrypt \
    php5-curl php5-gd php5-sqlite php5-json php5-memcache php5-intl \
    --no-install-recommends && \
    # Cleanup
    DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Adding NodeJS repo (for up-to-date versions)
# This command is a stripped down version of "curl --silent --location https://deb.nodesource.com/setup_0.12 | bash -"
RUN curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    echo 'deb https://deb.nodesource.com/node_0.12 precise main' > /etc/apt/sources.list.d/nodesource.list && \
    echo 'deb-src https://deb.nodesource.com/node_0.12 precise main' >> /etc/apt/sources.list.d/nodesource.list

# Other language packages and dependencies
RUN \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes install \
    ruby1.9.1-full rlwrap nodejs \
    --no-install-recommends && \
    # Cleanup
    DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Bundler
RUN gem install bundler

# Grunt, Bower
RUN npm install -g grunt-cli bower

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Drush and Drupal Console
RUN composer global require drush/drush:7.* && \
    curl -LSs http://drupalconsole.com/installer | php && \
    mv console.phar /usr/local/bin/drupal

# PHP settings changes
RUN sed -i 's/memory_limit = .*/memory_limit = 512M/' /etc/php5/cli/php.ini && \
    sed -i 's/max_execution_time = .*/max_execution_time = 300/' /etc/php5/cli/php.ini

WORKDIR /var/www

# Add Composer bin directory to PATH
ENV PATH /root/.composer/vendor/bin:$PATH

# Home directory for bundle installs
ENV BUNDLE_PATH .bundler

# SSH settigns
COPY config/.ssh /root/.ssh
# Drush settings
COPY config/.drush /root/.drush

# Startup script
COPY ./startup.sh /opt/startup.sh
RUN chmod +x /opt/startup.sh

# Starter script
ENTRYPOINT ["/opt/startup.sh"]

# By default, launch supervisord to keep the container running.
CMD /usr/bin/supervisord -n
