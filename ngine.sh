#!/usr/bin/env bash
#===============================================================================================================================================
# (C) Copyright 2019 NGINE a project under the Crypto World Foundation (https://cryptoworld.is).
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
# author           :The Crypto World Foundation.
# contributors     :beard, ksaredfx
# date             :04-28-2019
# version          :0.0.8 Alpha
# os               :Debian/Ubuntu
# usage            :bash ngine.sh
# notes            :If you have any problems feel free to email the maintainer: beard [AT] cryptoworld [DOT] is
#===============================================================================================================================================

# Force check for root
  if ! [ "$(id -u)" = 0 ]; then
    echo "You need to be logged in as root!"
      exit 1
  fi

# Setting up an update/upgrade global function
  function upkeep() {
    echo "Performing upkeep.."
      apt-get update -y
      apt-get dist-upgrade -y
      apt-get clean -y
  }

  # Setting up different NGINX branches to prep for install
    function nginx_stable() {
        echo deb http://nginx.org/packages/"$system"/ "$flavor" nginx > /etc/apt/sources.list.d/"$flavor".nginx.stable.list
        echo deb-src http://nginx.org/packages/"$system"/ "$flavor" nginx >> /etc/apt/sources.list.d/"$flavor".nginx.stable.list
          wget https://nginx.org/keys/nginx_signing.key
          apt-key add nginx_signing.key
      }

    function nginx_mainline() {
        echo deb http://nginx.org/packages/mainline/"$system"/ "$flavor" nginx > /etc/apt/sources.list.d/"$flavor".nginx.mainline.list
        echo deb-src http://nginx.org/packages/mainline/"$system"/ "$flavor" nginx >> /etc/apt/sources.list.d/"$flavor".nginx.mainline.list
          wget https://nginx.org/keys/nginx_signing.key
          apt-key add nginx_signing.key
      }

  # Attached func for NGINX branch prep.
    function nginx_default() {
      echo "Installing NGINX.."
        apt-get install nginx
        service nginx status
      echo "Raising limit of workers.."
        ulimit -n 65536
        ulimit -a
      echo "Setting up Security Limits.."
        wget -O /etc/security/limits.conf https://raw.githubusercontent.com/beardlyness/NGINE/master/etc/security/limits.conf
      echo "Setting up background NGINX workers.."
        wget -O /etc/default/nginx https://raw.githubusercontent.com/beardlyness/NGINE/master/etc/default/nginx

      # Attached grab for Domain Name
        read -r -p "Domain Name: (Leave { HTTPS:/// | HTTP:// | WWW. } out of the domain) " DOMAIN
          if [[ -n "${DOMAIN,,}" ]]
            then
              echo "Setting up configuration file for NGINX.."
                wget -O /etc/nginx/conf.d/"$DOMAIN".conf https://raw.githubusercontent.com/beardlyness/NGINE/master/etc/conf.d/ssl-nginx-website.conf
              echo "Changing 'server_name foobar' >> server_name '$DOMAIN' .."
                sed -i 's/server_name foobar/server_name '"$DOMAIN"'/g' /etc/nginx/conf.d/"$DOMAIN".conf
                sed -i 's/server_name www.foobar/server_name www.'"$DOMAIN"'/g' /etc/nginx/conf.d/"$DOMAIN".conf
              echo "Fixing up the site configuration file for NGINX.."
                sed -i 's/domain/'"$DOMAIN"'/g' /etc/nginx/conf.d/"$DOMAIN".conf
              echo "Domain Name has been set to: '$DOMAIN' "
              echo "Setting up folders.."
                mkdir -p /etc/engine/ssl/"$DOMAIN"
                mkdir -p /etc/nginx/ngine
                mkdir -p /var/www/html/"$DOMAIN"/live
              echo "Grabbing NGINE Includes"
                wget -O /etc/nginx/ngine/gzip https://raw.githubusercontent.com/beardlyness/NGINE/master/etc/nginx/ngine/gzip
                wget -O /etc/nginx/ngine/cache https://raw.githubusercontent.com/beardlyness/NGINE/master/etc/nginx/ngine/cache
                wget -O /etc/nginx/ngine/php https://raw.githubusercontent.com/beardlyness/NGINE/master/etc/nginx/ngine/php
            else
              echo "Sorry we cannot live on! RIP Dead.."
          fi
    }

    function custom_errors_html() {
          echo "Grabbing Customer Error Controller"
            wget -O /etc/nginx/ngine/error_handling https://raw.githubusercontent.com/beardlyness/NGINE/master/etc/nginx/ngine/error_handling_html
            sed -i 's/domain/'"$DOMAIN"'/g' /etc/nginx/ngine/error_handling
          echo "Setting up basic website template.."
            wget https://github.com/beardlyness/NGINE-Custom-Errors/archive/master.tar.gz -O - | tar -xz -C /var/www/html/"$DOMAIN"/live/  && mv /var/www/html/"$DOMAIN"/live/NGINE-Custom-Errors-master/* /var/www/html/"$DOMAIN"/live/
            sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/index.html
            sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/html/401.html
            sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/html/403.html
            sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/html/404.html
            sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/html/405.html
            sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/html/406.html
            sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/html/407.html
            sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/html/408.html
            sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/html/414.html
            sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/html/415.html
            sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/html/500.html
            sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/html/502.html
            sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/html/503.html
            sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/html/504.html
            sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/html/505.html
            sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/html/508.html
            sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/html/599.html
          echo "Removing temporary files/folders.."
            rm -rf /var/www/html/"$DOMAIN"/live/NGINE-Custom-Errors-master*
    }

    function custom_errors_php() {
      echo "Fixing up the ""$DOMAIN"" NGINX Configuration file.."
        wget -O /etc/nginx/ngine/error_handling https://raw.githubusercontent.com/beardlyness/NGINE/master/etc/nginx/ngine/error_handling_php
        sed -i 's/domain/'"$DOMAIN"'/g' /etc/nginx/ngine/error_handling
      echo "Setting up basic website template.."
        wget https://github.com/beardlyness/NGINE-Custom-Errors/archive/master.tar.gz -O - | tar -xz -C /var/www/html/"$DOMAIN"/live/  && mv /var/www/html/"$DOMAIN"/live/NGINE-Custom-Errors-master/* /var/www/html/"$DOMAIN"/live/
        sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/index.html
        sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/php/401.php
        sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/php/403.php
        sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/php/404.php
        sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/php/405.php
        sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/php/406.php
        sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/php/407.php
        sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/php/408.php
        sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/php/414.php
        sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/php/415.php
        sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/php/500.php
        sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/php/502.php
        sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/php/503.php
        sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/php/504.php
        sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/php/505.php
        sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/php/508.php
        sed -i 's/domain/'"$DOMAIN"'/g'  /var/www/html/"$DOMAIN"/live/errors/php/599.php
      echo "Removing temporary files/folders.."
        rm -rf /var/www/html/"$DOMAIN"/live/NGINE-Custom-Errors-master*
    }

  #Prep for SSL setup & install via ACME.SH script | Check it out here: https://github.com/Neilpang/acme.sh
    function ssldev() {
          echo "Preparing for SSL install.."
            wget -O -  https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh | INSTALLONLINE=1  sh
            reset
            service nginx stop
            openssl dhparam -out /etc/engine/ssl/"$DOMAIN"/dhparam.pem 2048
            bash ~/.acme.sh/acme.sh --issue --standalone -d "$DOMAIN" -d www."$DOMAIN" -ak 4096 -k 4096 --force
            bash ~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
              --key-file    /etc/engine/ssl/"$DOMAIN"/ssl.key \
              --fullchain-file    /etc/engine/ssl/"$DOMAIN"/certificate.cert
    }

    #Prep for SSL setup for Qualys rating
    function sslqualy() {
      echo "Preparing to setup NGINX to meet Qualys 100% Standards.."
        sed -i 's/ssl_prefer_server_ciphers/#ssl_prefer_server_ciphers/g' /etc/nginx/conf.d/"$DOMAIN".conf
        sed -i 's/#ssl_ciphers/ssl_ciphers/g' /etc/nginx/conf.d/"$DOMAIN".conf
        sed -i 's/#ssl_ecdh_curve/ssl_ecdh_curve/g' /etc/nginx/conf.d/"$DOMAIN".conf
      echo "Generating a 4096 DH Param. This may take a while.."
        openssl dhparam -out /etc/engine/ssl/"$DOMAIN"/dhparam.pem 4096
      echo "Restarting NGINX Service..."
        service nginx restart
        service nginx status
    }

  # Setting up different PHP Version branches to prep for install
    function phpdev() {
      echo "Setting up PHP Branches for install.."
        wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add -
      echo "deb https://packages.sury.org/php/ $flavor main" | tee /etc/apt/sources.list.d/php.list
    }

#START

# Checking for multiple "required" pieces of software.
    tools=( lsb_release wget curl dialog socat dirmngr apt-transport-https ca-certificates )
     grab_eware=""
       for e in "${tools[@]}"; do
         if command -v "$e" >/dev/null 2>&1; then
           echo "Dependency $e is installed.."
         else
           echo "Dependency $e is not installed..?"
            upkeep
            grab_eware="$grab_eware $e"
         fi
       done
      apt-get install $grab_eware


    # Grabbing info on active machine.
        flavor=$(lsb_release -cs)
        system=$(lsb_release -i | grep "Distributor ID:" | sed 's/Distributor ID://g' | sed 's/["]//g' | awk '{print tolower($1)}')

# NGINX Arg main
read -r -p "Do you want to setup NGINX as a Web Server? (Y/Yes | N/No) " REPLY
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
        echo "Grabbing Stable build dependencies.."
          nginx_stable
          upkeep
          nginx_default
          ssldev

          # Error_Handling Arg main
          read -r -p "Do you want to setup Custom Error Handling for NGINX? (Y/Yes | N/No) " REPLY
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
                  echo "HTML (Basic Error Reporting)"
                    custom_errors_html
                    service nginx restart
                    service nginx status
                    ;;
                2)
                  echo "PHP (Advance Error Handling)"
                    custom_errors_php
                    service nginx restart
                    service nginx status
                    ;;
              esac
          clear

          # Close Arg for Error_Handling Statement.
                ;;
              [nN]|[nN][oO])
                echo "You have said no? We cannot work without your permission!"
                ;;
              *)
                echo "Invalid response. You okay?"
                ;;
          esac

          ;;
      2)
        echo "Grabbing Mainline build dependencies.."
          nginx_mainline
          upkeep
          nginx_default
          ssldev

          # Error_Handling Arg main
          read -r -p "Do you want to setup Custom Error Handling for NGINX? (Y/Yes | N/No) " REPLY
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
                  echo "HTML (Basic Error Reporting)"
                    custom_errors_html
                    service nginx restart
                    service nginx status
                    ;;
                2)
                  echo "PHP (Advance Error Handling)"
                    custom_errors_php
                    service nginx restart
                    service nginx status
                    ;;
              esac
          clear

          # Close Arg for Error_Handling Statement.
                ;;
              [nN]|[nN][oO])
                echo "You have said no? We cannot work without your permission!"
                ;;
              *)
                echo "Invalid response. You okay?"
                ;;
          esac

          ;;
    esac
clear

# Close Arg for Main Statement.
      ;;
    [nN]|[nN][oO])
      echo "You have said no? We cannot work without your permission!"
      ;;
    *)
      echo "Invalid response. You okay?"
      ;;
esac

# PHP Arg main
read -r -p "Do you want to install and setup PHP? (Y/Yes | N/No) " REPLY
  case "${REPLY,,}" in
    [yY]|[yY][eE][sS])
      HEIGHT=20
      WIDTH=120
      CHOICE_HEIGHT=3
      BACKTITLE="NGINE"
      TITLE="PHP Branch Builds"
      MENU="Choose one of the following Build options:"

      OPTIONS=(1 "7.1"
               2 "7.2"
               3 "7.3")

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
        echo "Installing PHP 7.1, and its modules.."
          phpdev
          upkeep
            apt install php7.1 php7.1-fpm php7.1-cli php7.1-common php7.1-curl php7.1-mbstring php7.1-mysql php7.1-xml
            sed -i 's/listen.owner = www-data/listen.owner = nginx/g' /etc/php/7.1/fpm/pool.d/www.conf
            sed -i 's/listen.group = www-data/listen.group = nginx/g' /etc/php/7.1/fpm/pool.d/www.conf
            sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.1/fpm/php.ini
            sed -i 's/phpx.x-fpm.sock/php7.1-fpm.sock/g' /etc/nginx/ngine/php
            sed -i 's/phpx.x-fpm.sock/php7.1-fpm.sock/g' /etc/nginx/ngine/error_handling
            service php7.1-fpm restart
            service php7.1-fpm status
            service nginx restart
            pgrep -v root | pgrep php-fpm | cut -d\  -f1 | sort | uniq
          ;;
      2)
        echo "Installing PHP 7.2, and its modules.."
          phpdev
          upkeep
            apt install php7.2 php7.2-fpm php7.2-cli php7.2-common php7.2-curl php7.2-mbstring php7.2-mysql php7.2-xml
            sed -i 's/listen.owner = www-data/listen.owner = nginx/g' /etc/php/7.2/fpm/pool.d/www.conf
            sed -i 's/listen.group = www-data/listen.group = nginx/g' /etc/php/7.2/fpm/pool.d/www.conf
            sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.2/fpm/php.ini
            sed -i 's/phpx.x-fpm.sock/php7.2-fpm.sock/g' /etc/nginx/ngine/php
            sed -i 's/phpx.x-fpm.sock/php7.2-fpm.sock/g' /etc/nginx/ngine/error_handling
            service php7.2-fpm restart
            service php7.2-fpm status
            service nginx restart
            pgrep -v root | pgrep php-fpm | cut -d\  -f1 | sort | uniq
          ;;
      3)
        echo "Installing PHP 7.3, and its modules.."
          phpdev
          upkeep
           apt install php7.3 php7.3-fpm php7.3-cli php7.3-common php7.3-curl php7.3-mbstring php7.3-mysql php7.3-xml
           sed -i 's/listen.owner = www-data/listen.owner = nginx/g' /etc/php/7.3/fpm/pool.d/www.conf
           sed -i 's/listen.group = www-data/listen.group = nginx/g' /etc/php/7.3/fpm/pool.d/www.conf
           sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.3/fpm/php.ini
           sed -i 's/phpx.x-fpm.sock/php7.3-fpm.sock/g' /etc/nginx/ngine/php
           sed -i 's/phpx.x-fpm.sock/php7.3-fpm.sock/g' /etc/nginx/ngine/error_handling
           service php7.3-fpm restart
           service php7.3-fpm status
           service nginx restart
           pgrep -v root | pgrep php-fpm | cut -d\  -f1 | sort | uniq
          ;;
    esac
clear

# Close Arg for Main Statement.
      ;;
    [nN]|[nN][oO])
      echo "You have said no? We cannot work without your permission!"
      ;;
    *)
      echo "Invalid response. You okay?"
      ;;
esac

    read -r -p "Would you like to install MySQL/MariaDB, and PHPMyAdmin? (Y/Yes | N/No) " REPLY
      case "${REPLY,,}" in
        [yY]|[yY][eE][sS])
              echo "Setting up MySQL/MariaDB.."
                apt-get install mysql-server
                mysql_secure_installation
              echo "Setting up PHPMyAdmin.."
                apt-get install phpmyadmin
                apt-get install libmcrypt-dev
                ln -s /usr/share/phpmyadmin /var/www/html/"$DOMAIN"/live

                # Changes URL/phpmyadmin >> URL/Custom+String
                read -r -p "Custom PHPMyAdmin URL String: " REPLY
                  if [[ "${REPLY,,}" =~ ^[a-zA-Z0-9_.-]*$ ]]
                    then
                      echo "Changing /var/www/html/""$DOMAIN""/live/phpmyadmin >> /var/www/html/""$DOMAIN""/live/""$REPLY"" "
                        mv /var/www/html/"$DOMAIN"/live/phpmyadmin /var/www/html/"$DOMAIN"/live/"$REPLY"
                      echo "You can now access PHPMyAdmin with Username: 'phpmyadmin' via: https://""$DOMAIN""/""$REPLY"" "
                    else
                      echo "Only Letters & Numbers are allowed."
                  fi
            ;;
          [nN]|[nN][oO])
            echo "You have said no? We cannot work without your permission!"
            ;;
          *)
            echo "Invalid response. You okay?"
            ;;
    esac

    read -r -p "Do you want to setup NGINX to get a 100% Qualys SSL Rating? (Y/Yes | N/No) " REPLY
      case "${REPLY,,}" in
        [yY]|[yY][eE][sS])
              sslqualy
          ;;
        [nN]|[nN][oO])
            echo "You have said no? We cannot work without your permission!"
          ;;
        *)
          echo "Invalid response. You okay?"
          ;;
    esac
