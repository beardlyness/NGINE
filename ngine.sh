#!/usr/bin/env bash
#===============================================================================================================================================
# (C) Copyright 2023 NGINE a project under Hacked LLC.)
#
# Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.gnu.org/licenses/gpl-3.0.en.html
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#===============================================================================================================================================
# title            :NGINE.sh
# description      :This script will make it super easy to setup a LEMP server with selected Addons.
# author           :HACKED LLC.
# contributors     :beard, ksaredfx
# date             :05-16-2024
# version          :0.0.17 Alpha
# os               :Debian/Ubuntu
# usage            :bash ngine.sh
# notes            :If you have any problems feel free to email the maintainer: projects [AT] hacked [DOT] is
#===============================================================================================================================================

# Force check for root
  if ! [ "$(id -u)" = 0 ]; then
    echo """${cyan}""""${bold}""You need to be logged in as root!""${reset}"""
     exit 1
  fi


# Project Mapping
  P_URL="https://raw.githubusercontent.com/beardlyness/NGINE/master/"
  P_NGINX_PACKAGES_URL="http://nginx.org/packages"
  P_NGINX_KEY_URL="https://nginx.org/keys"
  P_PHP_KEY_URL="https://packages.sury.org/php/apt.gpg"
  P_PHP_PACKAGES_URL="https://packages.sury.org/php"
  P_WEB_DIR="/var/www/html"
  P_SSL_DIR="/etc/engine/ssl"
  P_NGINX_CONF_DIR="/etc/nginx/conf.d"
  P_MOD_DIR="/etc/nginx/ngine"
  P_REPO_LIST="/etc/apt/sources.list.d"
  P_KEYRING_DIR="/usr/share/keyrings"
  P_CUSTOM_ERROR_HANDLE_URL="https://github.com/beardlyness/NGINE-Custom-Errors/archive/master.tar.gz"
  P_PHPMyAdmin_DURL="https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip"
  P_PHPMyAdmin_VN="phpMyAdmin-5.2.1-all-languages"
  P_PHPMyAdmin_DIR="phpmyadmin"


# Color for tput
  red=$(tput setaf 1)
  green=$(tput setaf 2)
  yellow=$(tput setaf 3)
  blue=$(tput setaf 4)
  magenta=$(tput setaf 5)
  cyan=$(tput setaf 6)
  white=$(tput setaf 7)

#Functions for tput
  reset=$(tput sgr0)
  blink=$(tput blink)
  bold=$(tput bold)
  reverse=$(tput rev)
  underline=$(tput smul)


# Keeps the system updated
  function upkeep() {
    echo """${cyan}""""${bold}""Performing upkeep of system..""${reset}"""
      apt-get update -y
      apt-get full-upgrade -y
      apt-get dist-upgrade -y
      apt-get clean -y
  }

# Setting up different NGINX branches to prep for install

# Setup for Verifying NGINX PULL via GPG
function nginx_verify() {
  curl "$P_NGINX_KEY_URL"/nginx_signing.key | gpg --dearmor \
  | tee "$P_KEYRING_DIR"/nginx-archive-keyring.gpg >/dev/null
  gpg --dry-run --quiet --import --import-options import-show "$P_KEYRING_DIR"/nginx-archive-keyring.gpg
}

# Setup for Stable Branch of NGINX
  function nginx_stable() {
    echo "deb [signed-by="$P_KEYRING_DIR"/nginx-archive-keyring.gpg] \
    "$P_NGINX_PACKAGES_URL"/"$system" "$flavor" nginx" \
        | tee "$P_REPO_LIST"/nginx.stable.list
    }

# Setup for Expermiental Branch of NGINX
  function nginx_mainline() {
    echo "deb [signed-by="$P_KEYRING_DIR"/nginx-archive-keyring.gpg] \
    "$P_NGINX_PACKAGES_URL"/mainline/"$system" "$flavor" nginx" \
        | tee "$P_REPO_LIST"/nginx.mainline.list
    }

# Attached func for NGINX branch prep.
  function nginx_default() {
    echo """${yellow}""""${bold}""Installing NGINX..""${reset}"""
      apt-get install nginx
      service nginx status
    echo """${yellow}""""${bold}""Raising limit of workers..""${reset}"""
      ulimit -n 65536
      ulimit -a
    echo """${yellow}""""${bold}""Setting up Security Limits..""${reset}"""
      wget -O /etc/security/limits.conf "$P_URL"/etc/security/limits.conf
    echo """${yellow}""""${bold}""Setting up background NGINX workers..""${reset}"""
      wget -O /etc/default/nginx "$P_URL"/etc/default/nginx

  # Attached grab for Domain Name
    read -r -p """${cyan}""""${bold}""Domain Name: (Leave { HTTPS:/// | HTTP:// | WWW. } out of the domain) ""${reset}""" DOMAIN
      if [[ -n "${DOMAIN,,}" ]]
        then
          echo """${yellow}""""${bold}""Setting up configuration file for NGINX..""${reset}"""
            wget -O "$P_NGINX_CONF_DIR"/"$DOMAIN".conf "$P_URL"/etc/conf.d/ssl-nginx-website.conf
          echo """${yellow}""""${bold}""Changing 'server_name foobar' >> server_name '$DOMAIN' ..""${reset}"""
            sed -i 's/server_name foobar/server_name '"$DOMAIN"'/g' "$P_NGINX_CONF_DIR"/"$DOMAIN".conf
            sed -i 's/server_name www.foobar/server_name www.'"$DOMAIN"'/g' "$P_NGINX_CONF_DIR"/"$DOMAIN".conf
          echo """${yellow}""""${bold}""Fixing up the site configuration file for NGINX..""${reset}"""
            sed -i 's/domain/'"$DOMAIN"'/g' "$P_NGINX_CONF_DIR"/"$DOMAIN".conf
          echo """${yellow}""""${bold}""Domain Name has been set to: '$DOMAIN' ""${reset}"""
          echo """${yellow}""""${bold}""Setting up folders..""${reset}"""
            mkdir -p "$P_SSL_DIR"/"$DOMAIN"
            mkdir -p "$P_MOD_DIR"
            mkdir -p "$P_WEB_DIR"/"$DOMAIN"/live
          echo """${yellow}""""${bold}""Grabbing NGINE Includes""${reset}"""
            wget -O "$P_MOD_DIR"/gzip "$P_URL"/"$P_MOD_DIR"/gzip
            wget -O "$P_MOD_DIR"/cache "$P_URL"/"$P_MOD_DIR"/cache
            wget -O "$P_MOD_DIR"/php "$P_URL"/"$P_MOD_DIR"/php
        else
          echo """${red}""""${bold}""Sorry we cannot live on! RIP Dead..""${reset}"""
      fi
    }


# Setup for Custom Errors HTML
  function custom_errors_html() {
    echo """${yellow}""""${bold}""Grabbing Customer Error Controller""${reset}"""
      wget -O "$P_MOD_DIR"/error_handling "$P_URL"/"$P_MOD_DIR"/error_handling_html
      sed -i 's/domain/'"$DOMAIN"'/g' "$P_MOD_DIR"/error_handling
    echo """${yellow}""""${bold}""Setting up basic website template..""${reset}"""
      wget "$P_CUSTOM_ERROR_HANDLE_URL" -O - | tar -xz -C "$P_WEB_DIR"/"$DOMAIN"/live/  && mv "$P_WEB_DIR"/"$DOMAIN"/live/NGINE-Custom-Errors-master/* "$P_WEB_DIR"/"$DOMAIN"/live/
      sed -i 's/domain/'"$DOMAIN"'/g'  "$P_WEB_DIR"/"$DOMAIN"/live/index.html

    #Setup for e_page touch for HTML Error Pages
      pages=( 401.html 403.html 404.html 405.html 406.html 407.html 408.html 414.html 415.html 500.html 502.html 503.html 504.html 505.html 508.html 599.html)
        for e_page in "${pages[@]}"; do
          sed -i 's/domain/'"$DOMAIN"'/g' "$P_WEB_DIR"/"$DOMAIN"/live/errors/html/"$e_page"
        done
    echo """${yellow}""""${bold}""Removing temporary files/folders..""${reset}"""
      rm -rf "$P_WEB_DIR"/"$DOMAIN"/live/NGINE-Custom-Errors-master*
  }

# Setup for Custom Errors PHP
  function custom_errors_php() {
    echo """${yellow}""""${bold}""Grabbing Customer Error Controller""${reset}"""
      wget -O "$P_MOD_DIR"/error_handling "$P_URL"/"$P_MOD_DIR"/error_handling_php
      sed -i 's/domain/'"$DOMAIN"'/g' "$P_MOD_DIR"/error_handling
    echo """${yellow}""""${bold}""Setting up basic website template..""${reset}"""
      wget "$P_CUSTOM_ERROR_HANDLE_URL" -O - | tar -xz -C "$P_WEB_DIR"/"$DOMAIN"/live/  && mv "$P_WEB_DIR"/"$DOMAIN"/live/NGINE-Custom-Errors-master/* "$P_WEB_DIR"/"$DOMAIN"/live/
      sed -i 's/domain/'"$DOMAIN"'/g'  "$P_WEB_DIR"/"$DOMAIN"/live/index.html

    #Setup for e_page touch for PHP Error Pages
      pages=( 401.php 403.php 404.php 405.php 406.php 407.php 408.php 414.php 415.php 500.php 502.php 503.php 504.php 505.php 508.php 599.php )
        for e_page in "${pages[@]}"; do
          sed -i 's/domain/'"$DOMAIN"'/g' "$P_WEB_DIR"/"$DOMAIN"/live/errors/php/"$e_page"
        done
    echo """${yellow}""""${bold}""Removing temporary files/folders..""${reset}"""
      rm -rf "$P_WEB_DIR"/"$DOMAIN"/live/NGINE-Custom-Errors-master*
  }

# Setup for CertBOT
  function CertBOT() {
    echo """${yellow}""""${bold}""Stopping NGINX..""${reset}"""
      service nginx stop
      service nginx status
    echo """${yellow}""""${bold}""Installing and Setting up CertBOT for handling SSL""${reset}"""
      apt-get install certbot
      certbot certonly --standalone --preferred-challenges http -d "$DOMAIN" -d www."$DOMAIN" --agree-tos --rsa-key-size 4096
      CertBOT_LE_DIR="/etc/letsencrypt/live/"$DOMAIN""
      cp "$CertBOT_LE_DIR"/*"" "$P_SSL_DIR/"$DOMAIN""
      mv "$P_SSL_DIR"/"$DOMAIN"/fullchain.pem "$P_SSL_DIR"/"$DOMAIN"/certificate.cert
      mv "$P_SSL_DIR"/"$DOMAIN"/privkey.pem "$P_SSL_DIR"/"$DOMAIN"/ssl.key
      openssl dhparam -out "$P_SSL_DIR"/"$DOMAIN"/dhparam.pem 2048
  }

  function phpmyadmin_install() {
    apt-get install php-json php-mbstring php-xml libmcrypt-dev -y
    wget "$P_PHPMyAdmin_DURL"
    tar -zxvf "$P_PHPMyAdmin_VN".tar.gz
    mv "$P_PHPMyAdmin_VN" "$P_WEB_DIR"/"$DOMAIN"/live/"$P_PHPMyAdmin_DIR"
    cp -pr "$P_WEB_DIR"/"$DOMAIN"/live/"$P_PHPMyAdmin_DIR"/config.sample.inc.php "$P_WEB_DIR"/"$DOMAIN"/live/"$P_PHPMyAdmin_DIR"/config.inc.php
    nano "$P_WEB_DIR"/"$DOMAIN"/live/"$P_PHPMyAdmin_DIR"/config.inc.php
  }

  function phpmyadmin_mariadb_setup() {
    mysql < "$P_WEB_DIR"/"$DOMAIN"/live/"$P_PHPMyAdmin_DIR"/sql/create_tables.sql -u root -p
    mysql -u root -p
  }

  function phpmyadmin_setup() {
    mkdir "$P_WEB_DIR"/"$DOMAIN"/live/"$P_PHPMyAdmin_DIR"/tmp
    chmod 777 "$P_WEB_DIR"/"$DOMAIN"/live/"$P_PHPMyAdmin_DIR"/tmp
    wget -O "$P_MOD_DIR"/phpmyadmin "$P_URL"/"$P_MOD_DIR"/phpmyadmin
    chown -R nginx:nginx "$P_WEB_DIR"/"$DOMAIN"/live/"$P_PHPMyAdmin_DIR"
    service nginx restart
    service nginx status
  }

#Prep for SSL setup for Qualys rating
  function sslqualy() {
    echo """${yellow}""""${bold}""Preparing to setup NGINX to meet Qualys 100% Standards..""${reset}"""
      sed -i 's/ssl_prefer_server_ciphers/#ssl_prefer_server_ciphers/g' "$P_NGINX_CONF_DIR"/"$DOMAIN".conf
      sed -i 's/#ssl_ciphers/ssl_ciphers/g' "$P_NGINX_CONF_DIR"/"$DOMAIN".conf
      sed -i 's/#ssl_ecdh_curve/ssl_ecdh_curve/g' "$P_NGINX_CONF_DIR"/"$DOMAIN".conf
    echo """${yellow}""""${bold}""Generating a 4096 DH Param. This may take a while..""${reset}"""
      openssl dhparam -out "$P_SSL_DIR"/"$DOMAIN"/dhparam.pem 4096
    echo """${yellow}""""${bold}""Restarting NGINX Service...""${reset}"""
      service nginx restart
      service nginx status
  }

  # Setup Verficiation for PHP PULL
    function php_verify() {
      echo """${yellow}""""${bold}""Setting up PHP Branches for install..""${reset}"""
        curl "$P_PHP_KEY_URL" | gpg --dearmor \
        | tee "$P_KEYRING_DIR"/apt.gpg >/dev/null
        gpg --dry-run --quiet --import --import-options import-show "$P_KEYRING_DIR"/apt.gpg
    }

# Setup for PHP INSTALL
    function php_setup() {
      echo "deb [signed-by="$P_KEYRING_DIR"/apt.gpg] \
      "$P_PHP_PACKAGES_URL"/ "$flavor" main" \
          | tee "$P_REPO_LIST"/php.list
    }


#START

# Installing key software to help
  tools=( gnupg gnupg-utils dialog dirmngr socat lsb-release wget curl dialog socat apt-transport-https ca-certificates )
    grab_eware=""
      for e in "${tools[@]}"; do
        if command -v "$e" > /dev/null 2>&1; then
          echo """${green}""""${bold}""Dependency $e is installed..""${reset}"""
        else
          echo """${red}""""${bold}""Dependency $e is not installed..""${reset}"""
          upkeep
          grab_eware="$grab_eware $e"
        fi
      done
    apt-get install $grab_eware

# Grabbing info on active machine.
    flavor=$(lsb_release -cs)
    system=$(lsb_release -i | grep "Distributor ID:" | sed 's/Distributor ID://g' | sed 's/["]//g' | awk '{print tolower($1)}')

# NGINX Dialog Arg main
read -r -p """${cyan}""""${bold}""Do you want to setup NGINX as a Web Server? (Y/Yes | N/No) ""${reset}""" REPLY
  case "${REPLY,,}" in
    [yY]|[yY][eE][sS])
      HEIGHT=20
      WIDTH=120
      CHOICE_HEIGHT=2
      BACKTITLE="NGINE"
      TITLE="NGINX Branch Builds"
      MENU="Choose one of the following Build options:"

      OPTIONS=(1 "Stable"
               2 "Mainline")

      CHOICE=$(dialog --clear \
                      --backtitle "$BACKTITLE" \
                      --title "$TITLE" \
                      --menu "$MENU" \
                      $HEIGHT $WIDTH $CHOICE_HEIGHT \
                      "${OPTIONS[@]}" \
                      2>&1 >/dev/tty)


# Attached Arg for dialogs $CHOICE output
    case $CHOICE in
      1)
        echo """${yellow}""Grabbing Stable build dependencies..""${reset}"""
          upkeep
          nginx_verify
          nginx_stable
          upkeep
          nginx_default
          CertBOT
        ;;

      2)
        echo """${yellow}""""${bold}""Grabbing Mainline build dependencies..""${reset}"""
          upkeep
          nginx_verify
          nginx_mainline
          upkeep
          nginx_default
          CertBOT
        ;;
      esac
  clear

# PHP Dialog Arg main
read -r -p """${cyan}""""${bold}""Do you want to install and setup PHP? (Y/Yes | N/No) ""${reset}""" REPLY
  case "${REPLY,,}" in
    [yY]|[yY][eE][sS])
      HEIGHT=20
      WIDTH=120
      CHOICE_HEIGHT=7
      BACKTITLE="NGINE"
      TITLE="PHP Branch Builds"
      MENU="Choose one of the following Build options:"

      OPTIONS=(1 "8.2"
               2 "8.3")

      CHOICE=$(dialog --clear \
                      --backtitle "$BACKTITLE" \
                      --title "$TITLE" \
                      --menu "$MENU" \
                      $HEIGHT $WIDTH $CHOICE_HEIGHT \
                      "${OPTIONS[@]}" \
                      2>&1 >/dev/tty)


# Attached Arg for dialogs $CHOICE output
    case $CHOICE in
      1)
        echo """${cyan}""""${bold}""Installing PHP 8.2, and its modules..""${reset}"""
          php_verify
          php_setup
          upkeep
           apt install php8.2 php8.2-fpm php8.2-cli php8.2-common php8.2-curl php8.2-mbstring php8.2-mysql php8.2-xml
           custom_errors_php
           sed -i 's/listen.owner = www-data/listen.owner = nginx/g' /etc/php/8.2/fpm/pool.d/www.conf
           sed -i 's/listen.group = www-data/listen.group = nginx/g' /etc/php/8.2/fpm/pool.d/www.conf
           sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/8.2/fpm/php.ini
           sed -i 's/phpx.x-fpm.sock/php8.2-fpm.sock/g' "$P_MOD_DIR"/php
           sed -i 's/phpx.x-fpm.sock/php8.2-fpm.sock/g' "$P_MOD_DIR"/error_handling
           service php8.2-fpm restart
           service php8.2-fpm status
           service nginx restart
           pgrep -v root | pgrep php-fpm | cut -d\  -f1 | sort | uniq
          ;;
      2)
        echo """${cyan}""""${bold}""Installing PHP 8.3, and its modules..""${reset}"""
          php_verify
          php_setup
          upkeep
           apt install php8.3 php8.3-fpm php8.3-cli php8.3-common php8.3-curl php8.3-mbstring php8.3-mysql php8.3-xml
           custom_errors_php
           sed -i 's/listen.owner = www-data/listen.owner = nginx/g' /etc/php/8.3/fpm/pool.d/www.conf
           sed -i 's/listen.group = www-data/listen.group = nginx/g' /etc/php/8.3/fpm/pool.d/www.conf
           sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/8.3/fpm/php.ini
           sed -i 's/phpx.x-fpm.sock/php8.3-fpm.sock/g' "$P_MOD_DIR"/php
           sed -i 's/phpx.x-fpm.sock/php8.3-fpm.sock/g' "$P_MOD_DIR"/error_handling
           service php8.3-fpm restart
           service php8.3-fpm status
           service nginx restart
           pgrep -v root | pgrep php-fpm | cut -d\  -f1 | sort | uniq
          ;;
    esac
clear

# Close Arg for Main Statement.
      ;;
    [nN]|[nN][oO])
      echo """${red}""""${bold}""You have said no? We cannot work without your permission!""${reset}"""
        custom_errors_html
      ;;
    *)
      echo """${yellow}""""${bold}""Invalid response. You okay?""${reset}"""
      ;;
esac



# SQL - MariaDB Dialog Arg main
    read -r -p """${cyan}""""${bold}""Would you like to install and setup MariaDB (Y/Yes | N/No) ""${reset}""" REPLY
      case "${REPLY,,}" in
        [yY]|[yY][eE][sS])
              echo """${cyan}""""${bold}""Setting up MariaDB..""${reset}"""
                apt install mariadb-server
                mysql_secure_installation

# PHPMyAdmin Dialog Arg main
    read -r -p """${cyan}""""${bold}""Would you like to install and setup PHPMyAdmin? (Y/Yes | N/No) ""${reset}""" REPLY
      case "${REPLY,,}" in
        [yY]|[yY][eE][sS])
              echo """${cyan}""""${bold}""Setting up PHPMyAdmin..""${reset}"""
                phpmyadmin_install
                phpmyadmin_mariadb_setup
                phpmyadmin_setup
            ;;
          [nN]|[nN][oO])
            echo """${red}""""${bold}""You have said no? We cannot work without your permission!""${reset}"""
            ;;
          *)
            echo """${yellow}""""${bold}""Invalid response. You okay?""${reset}"""
            ;;
    esac
            ;;
          [nN]|[nN][oO])
            echo """${red}""""${bold}""You have said no? We cannot work without your permission!""${reset}"""
            ;;
          *)
            echo """${yellow}""""${bold}""Invalid response. You okay?""${reset}"""
            ;;
    esac

# SSL Qualys Arg main
    read -r -p """${cyan}""""${bold}""Do you want to setup NGINX to get a 100% Qualys SSL Rating? (Y/Yes | N/No) ""${reset}""" REPLY
      case "${REPLY,,}" in
        [yY]|[yY][eE][sS])
              sslqualy
          ;;
        [nN]|[nN][oO])
            echo """${red}""""${bold}""You have said no? We cannot work without your permission!""${reset}"""
          ;;
        *)
          echo """${yellow}""""${bold}""Invalid response. You okay?""${reset}"""
          ;;
    esac

  # Close Arg for Main Dialog Statement.
        ;;
      [nN]|[nN][oO])
        echo """${red}""""${bold}""You have said no? We cannot work without your permission!""${reset}"""
        ;;
      *)
        echo """${yellow}""""${bold}""Invalid response. You okay?""${reset}"""
        ;;
  esac
