#!/usr/bin/env bash
#===============================================================================================================================================
# (C) Copyright 2021 NGINE a project under Hacked LLC.)
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
# date             :06-30-2021
# version          :0.0.13 Alpha
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
  P_WEB_DIR="/var/www/html"
  P_SSL_DIR="/etc/engine/ssl"
  P_NGINX_CONF_DIR="/etc/nginx/conf.d"
  P_MOD_DIR="/etc/nginx/ngine"
  P_REPO_LIST="/etc/apt/sources.list.d"


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

# Setup for Stable Branch of NGINX
  function nginx_stable() {
      echo deb http://nginx.org/packages/"$system"/ "$flavor" nginx > "$P_REPO_LIST"/"$flavor".nginx.stable.list
      echo deb-src http://nginx.org/packages/"$system"/ "$flavor" nginx >> "$P_REPO_LIST"/"$flavor".nginx.stable.list
        wget https://nginx.org/keys/nginx_signing.key
        apt-key add nginx_signing.key
    }

# Setup for Expermiental Branch of NGINX
  function nginx_mainline() {
      echo deb http://nginx.org/packages/mainline/"$system"/ "$flavor" nginx > "$P_REPO_LIST"/"$flavor".nginx.mainline.list
      echo deb-src http://nginx.org/packages/mainline/"$system"/ "$flavor" nginx >> "$P_REPO_LIST"/"$flavor".nginx.mainline.list
        wget https://nginx.org/keys/nginx_signing.key
        apt-key add nginx_signing.key
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
      wget https://github.com/beardlyness/NGINE-Custom-Errors/archive/master.tar.gz -O - | tar -xz -C "$P_WEB_DIR"/"$DOMAIN"/live/  && mv "$P_WEB_DIR"/"$DOMAIN"/live/NGINE-Custom-Errors-master/* "$P_WEB_DIR"/"$DOMAIN"/live/
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
      wget https://github.com/beardlyness/NGINE-Custom-Errors/archive/master.tar.gz -O - | tar -xz -C "$P_WEB_DIR"/"$DOMAIN"/live/  && mv "$P_WEB_DIR"/"$DOMAIN"/live/NGINE-Custom-Errors-master/* "$P_WEB_DIR"/"$DOMAIN"/live/
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

# Setup for different PHP Version Branches for install
  function phpdev() {
    echo """${yellow}""""${bold}""Setting up PHP Branches for install..""${reset}"""
      wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add -
    echo "deb https://packages.sury.org/php/ $flavor main" | tee "$P_REPO_LIST"/php.list
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
          nginx_stable
          upkeep
          nginx_default
          CertBOT

# Error_Handling Dialog Arg main
          read -r -p """${cyan}""""${bold}""Do you want to setup Custom Error Handling for NGINX? (Y/Yes | N/No) ""${reset}""" REPLY
            case "${REPLY,,}" in
              [yY]|[yY][eE][sS])
                HEIGHT=20
                WIDTH=120
                CHOICE_HEIGHT=2
                BACKTITLE="NGINE"
                TITLE="NGINX Custom Error Handling"
                MENU="Choose one of the following Error Handling options:"

                OPTIONS=(1 "HTML (Basic Error Reporting)"
                         2 "PHP (Advance Error Handling)")

                CHOICE=$(dialog --clear \
                                --backtitle "$BACKTITLE" \
                                --title "$TITLE" \
                                --menu "$MENU" \
                                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                                "${OPTIONS[@]}" \
                                2>&1 >/dev/tty)


          # Attached Arg for dialogs $CHOICE output for Error_Handling
              case $CHOICE in
                1)
                  echo """${yellow}""""${bold}""HTML (Basic Error Reporting)""${reset}"""
                    custom_errors_html
                    service nginx restart
                    service nginx status
                    ;;
                2)
                  echo """${yellow}""""${bold}""PHP (Advance Error Handling)""${reset}"""
                    custom_errors_php
                    service nginx restart
                    service nginx status
                    ;;
              esac
          clear

          # Close Arg for Error_Handling Statement.
                ;;
              [nN]|[nN][oO])
                echo """${red}""""${bold}""You have said no? We cannot work without your permission!""${reset}"""
                ;;
              *)
                echo """${yellow}""""${bold}""Invalid response. You okay?""${reset}"""
                ;;
          esac

          ;;
      2)
        echo """${yellow}""""${bold}""Grabbing Mainline build dependencies..""${reset}"""
          nginx_mainline
          upkeep
          nginx_default
          CertBOT

# Error_Handling Arg main
          read -r -p """${cyan}""""${bold}""Do you want to setup Custom Error Handling for NGINX? (Y/Yes | N/No) ""${reset}""" REPLY
            case "${REPLY,,}" in
              [yY]|[yY][eE][sS])
                HEIGHT=20
                WIDTH=120
                CHOICE_HEIGHT=2
                BACKTITLE="NGINE"
                TITLE="NGINX Custom Error Handling"
                MENU="Choose one of the following Error Handling options:"

                OPTIONS=(1 "HTML (Basic Error Reporting)"
                         2 "PHP (Advance Error Handling)")

                CHOICE=$(dialog --clear \
                                --backtitle "$BACKTITLE" \
                                --title "$TITLE" \
                                --menu "$MENU" \
                                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                                "${OPTIONS[@]}" \
                                2>&1 >/dev/tty)


          # Attached Arg for dialogs $CHOICE output for Error_Handling
              case $CHOICE in
                1)
                  echo """${yellow}""""${bold}""HTML (Basic Error Reporting)""${reset}"""
                    custom_errors_html
                    service nginx restart
                    service nginx status
                    ;;
                2)
                  echo """${yellow}""""${bold}""PHP (Advance Error Handling)""${reset}"""
                    custom_errors_php
                    service nginx restart
                    service nginx status
                    ;;
              esac
          clear

          # Close Arg for Error_Handling Statement.
                ;;
              [nN]|[nN][oO])
                echo """${red}""""${bold}""You have said no? We cannot work without your permission!""${reset}"""
                ;;
              *)
                echo """${yellow}""""${bold}""Invalid response. You okay?""${reset}"""
                ;;
          esac

          ;;
    esac
clear

# Close Arg for Main Dialog Statement.
      ;;
    [nN]|[nN][oO])
      echo """${red}""""${bold}""You have said no? We cannot work without your permission!""${reset}"""
      ;;
    *)
      echo """${yellow}""""${bold}""Invalid response. You okay?""${reset}"""
      ;;
esac

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

      OPTIONS=(1 "5.6"
               2 "7.0"
               3 "7.1"
               4 "7.2"
               5 "7.3"
               6 "7.4"
               7 "8.0")

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
        echo """${cyan}""""${bold}""Installing PHP 5.6, and its modules..""${reset}"""
          phpdev
          upkeep
            apt install php5.6 php5.6-fpm php5.6-cli php5.6-common php5.6-curl php5.6-mbstring php5.6-mysql php5.6-xml
            sed -i 's/listen.owner = www-data/listen.owner = nginx/g' /etc/php/5.6/fpm/pool.d/www.conf
            sed -i 's/listen.group = www-data/listen.group = nginx/g' /etc/php/5.6/fpm/pool.d/www.conf
            sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/5.6/fpm/php.ini
            sed -i 's/phpx.x-fpm.sock/php5.6-fpm.sock/g' "$P_MOD_DIR"/php
            sed -i 's/phpx.x-fpm.sock/php5.6-fpm.sock/g' "$P_MOD_DIR"/error_handling
            service php5.6-fpm restart
            service php5.6-fpm status
            service nginx restart
            pgrep -v root | pgrep php-fpm | cut -d\  -f1 | sort | uniq
          ;;
      2)
        echo """${cyan}""""${bold}""Installing PHP 7.0, and its modules..""${reset}"""
          phpdev
          upkeep
            apt install php7.0 php7.0-fpm php7.0-cli php7.0-common php7.0-curl php7.0-mbstring php7.0-mysql php7.0-xml
            sed -i 's/listen.owner = www-data/listen.owner = nginx/g' /etc/php/7.0/fpm/pool.d/www.conf
            sed -i 's/listen.group = www-data/listen.group = nginx/g' /etc/php/7.0/fpm/pool.d/www.conf
            sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.0/fpm/php.ini
            sed -i 's/phpx.x-fpm.sock/php7.0-fpm.sock/g' "$P_MOD_DIR"/php
            sed -i 's/phpx.x-fpm.sock/php7.0-fpm.sock/g' "$P_MOD_DIR"/error_handling
            service php7.0-fpm restart
            service php7.0-fpm status
            service nginx restart
            pgrep -v root | pgrep php-fpm | cut -d\  -f1 | sort | uniq
          ;;
      3)
        echo """${cyan}""""${bold}""Installing PHP 7.1, and its modules..""${reset}"""
          phpdev
          upkeep
            apt install php7.1 php7.1-fpm php7.1-cli php7.1-common php7.1-curl php7.1-mbstring php7.1-mysql php7.1-xml
            sed -i 's/listen.owner = www-data/listen.owner = nginx/g' /etc/php/7.1/fpm/pool.d/www.conf
            sed -i 's/listen.group = www-data/listen.group = nginx/g' /etc/php/7.1/fpm/pool.d/www.conf
            sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.1/fpm/php.ini
            sed -i 's/phpx.x-fpm.sock/php7.1-fpm.sock/g' "$P_MOD_DIR"/php
            sed -i 's/phpx.x-fpm.sock/php7.1-fpm.sock/g' "$P_MOD_DIR"/error_handling
            service php7.1-fpm restart
            service php7.1-fpm status
            service nginx restart
            pgrep -v root | pgrep php-fpm | cut -d\  -f1 | sort | uniq
          ;;
      4)
        echo """${cyan}""""${bold}""Installing PHP 7.2, and its modules..""${reset}"""
          phpdev
          upkeep
            apt install php7.2 php7.2-fpm php7.2-cli php7.2-common php7.2-curl php7.2-mbstring php7.2-mysql php7.2-xml
            sed -i 's/listen.owner = www-data/listen.owner = nginx/g' /etc/php/7.2/fpm/pool.d/www.conf
            sed -i 's/listen.group = www-data/listen.group = nginx/g' /etc/php/7.2/fpm/pool.d/www.conf
            sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.2/fpm/php.ini
            sed -i 's/phpx.x-fpm.sock/php7.2-fpm.sock/g' "$P_MOD_DIR"/php
            sed -i 's/phpx.x-fpm.sock/php7.2-fpm.sock/g' "$P_MOD_DIR"/error_handling
            service php7.2-fpm restart
            service php7.2-fpm status
            service nginx restart
            pgrep -v root | pgrep php-fpm | cut -d\  -f1 | sort | uniq
          ;;
      5)
        echo """${cyan}""""${bold}""Installing PHP 7.3, and its modules..""${reset}"""
          phpdev
          upkeep
            apt install php7.3 php7.3-fpm php7.3-cli php7.3-common php7.3-curl php7.3-mbstring php7.3-mysql php7.3-xml
            sed -i 's/listen.owner = www-data/listen.owner = nginx/g' /etc/php/7.3/fpm/pool.d/www.conf
            sed -i 's/listen.group = www-data/listen.group = nginx/g' /etc/php/7.3/fpm/pool.d/www.conf
            sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.3/fpm/php.ini
            sed -i 's/phpx.x-fpm.sock/php7.3-fpm.sock/g' "$P_MOD_DIR"/php
            sed -i 's/phpx.x-fpm.sock/php7.3-fpm.sock/g' "$P_MOD_DIR"/error_handling
            service php7.3-fpm restart
            service php7.3-fpm status
            service nginx restart
            pgrep -v root | pgrep php-fpm | cut -d\  -f1 | sort | uniq
          ;;
      6)
        echo """${cyan}""""${bold}""Installing PHP 7.4, and its modules..""${reset}"""
          phpdev
          upkeep
           apt install php7.4 php7.4-fpm php7.4-cli php7.4-common php7.4-curl php7.4-mbstring php7.4-mysql php7.4-xml
           sed -i 's/listen.owner = www-data/listen.owner = nginx/g' /etc/php/7.4/fpm/pool.d/www.conf
           sed -i 's/listen.group = www-data/listen.group = nginx/g' /etc/php/7.4/fpm/pool.d/www.conf
           sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.4/fpm/php.ini
           sed -i 's/phpx.x-fpm.sock/php7.4-fpm.sock/g' "$P_MOD_DIR"/php
           sed -i 's/phpx.x-fpm.sock/php7.4-fpm.sock/g' "$P_MOD_DIR"/error_handling
           service php7.4-fpm restart
           service php7.4-fpm status
           service nginx restart
           pgrep -v root | pgrep php-fpm | cut -d\  -f1 | sort | uniq
          ;;
      7)
        echo """${cyan}""""${bold}""Installing PHP 8.0, and its modules..""${reset}"""
          phpdev
          upkeep
           apt install php8.0 php8.0-fpm php8.0-cli php8.0-common php8.0-curl php8.0-mbstring php8.0-mysql php8.0-xml
           sed -i 's/listen.owner = www-data/listen.owner = nginx/g' /etc/php/8.0/fpm/pool.d/www.conf
           sed -i 's/listen.group = www-data/listen.group = nginx/g' /etc/php/8.0/fpm/pool.d/www.conf
           sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/8.0/fpm/php.ini
           sed -i 's/phpx.x-fpm.sock/php8.0-fpm.sock/g' "$P_MOD_DIR"/php
           sed -i 's/phpx.x-fpm.sock/php8.0-fpm.sock/g' "$P_MOD_DIR"/error_handling
           service php8.0-fpm restart
           service php8.0-fpm status
           service nginx restart
           pgrep -v root | pgrep php-fpm | cut -d\  -f1 | sort | uniq
          ;;
    esac
clear

# Close Arg for Main Statement.
      ;;
    [nN]|[nN][oO])
      echo """${red}""""${bold}""You have said no? We cannot work without your permission!""${reset}"""
      ;;
    *)
      echo """${yellow}""""${bold}""Invalid response. You okay?""${reset}"""
      ;;
esac

# SQL & PHPMyAdmin Dialog Arg main
    read -r -p """${cyan}""""${bold}""Would you like to install MySQL/MariaDB, and PHPMyAdmin? (Y/Yes | N/No) ""${reset}""" REPLY
      case "${REPLY,,}" in
        [yY]|[yY][eE][sS])
              echo """${cyan}""""${bold}""Setting up MySQL/MariaDB..""${reset}"""
                apt-get install mysql-server
                mysql_secure_installation
              echo """${cyan}""""${bold}""Setting up PHPMyAdmin..""${reset}"""
                apt-get install phpmyadmin
                apt-get install libmcrypt-dev
                ln -s /usr/share/phpmyadmin "$P_WEB_DIR"/"$DOMAIN"/live

              # Changes URL/phpmyadmin >> URL/Custom+String
                read -r -p """${cyan}""""${bold}""Custom PHPMyAdmin URL String: ""${reset}""" REPLY
                  if [[ "${REPLY,,}" =~ ^[a-zA-Z0-9_.-]*$ ]]
                    then
                      echo """${cyan}""""${bold}""Changing ""$P_WEB_DIR""/""$DOMAIN""/live/phpmyadmin >> ""$P_WEB_DIR""/""$DOMAIN""/live/""$REPLY"" ""${reset}"""
                        mv "$P_WEB_DIR"/"$DOMAIN"/live/phpmyadmin "$P_WEB_DIR"/"$DOMAIN"/live/"$REPLY"
                      echo """${cyan}""""${bold}""You can now access PHPMyAdmin with Username: 'phpmyadmin' via: https://""$DOMAIN""/""$REPLY"" ""${reset}"""
                    else
                      echo """${yellow}""""${bold}""Only Letters & Numbers are allowed.""${reset}"""
                  fi
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
