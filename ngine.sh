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
# description      :This script will make it super easy to setup a LEMP server.
# author           :The Crypto World Foundation.
# contributors     :beard
# date             :03-25-2019
# version          :0.0.3 Alpha
# os               :Debian/Ubuntu
# usage            :bash ngine.sh
# notes            :If you have any problems feel free to email the maintainer: beard [AT] cryptoworld [DOT] is
#===============================================================================================================================================

# Force check for root
  if ! [ $(id -u) = 0 ]; then
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
    function stable(){
        echo deb http://nginx.org/packages/$system/ $flavor nginx > /etc/apt/sources.list.d/$flavor.nginx.stable.list
        echo deb-src http://nginx.org/packages/$system/ $flavor nginx >> /etc/apt/sources.list.d/$flavor.nginx.stable.list
          wget https://nginx.org/keys/nginx_signing.key
          apt-key add nginx_signing.key
      }

    function mainline(){
        echo deb http://nginx.org/packages/mainline/$system/ $flavor nginx > /etc/apt/sources.list.d/$flavor.nginx.mainline.list
        echo deb-src http://nginx.org/packages/mainline/$system/ $flavor nginx >> /etc/apt/sources.list.d/$flavor.nginx.mainline.list
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
      echo "Setting up configuration file for NGINX.."
        wget -O /etc/nginx/conf.d/nginx-website.conf https://raw.githubusercontent.com/beardlyness/NGINE/master/etc/conf.d/ssldev.conf
      echo "Setting up folders.."
        mkdir -p /etc/engine/ssl/live
        mkdir -p /var/www/html/pub/live

        read -r -p "Domain Name: (Leave { HTTPS:/// | HTTP:// | WWW. } out of the domain) " DOMAIN
          if [[ "${DOMAIN,,}" ]]
            then
              echo "Changing 'server_name foobar' >> server_name '$DOMAIN' .."
                sed -i 's/server_name foobar/server_name '$DOMAIN'/g' /etc/nginx/conf.d/nginx-website.conf
              echo "Domain Name has been set to: '$DOMAIN' "
          fi
    }

  #Prep for SSL setup & install via ACME.SH script | Check it out here: https://github.com/Neilpang/acme.sh
    function ssldev() {
          echo "Preparing for SSL install.."
            wget -O -  https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh | INSTALLONLINE=1  sh
            reset
            service nginx stop
            openssl dhparam -out /etc/engine/ssl/live/dhparam.pem 2048
            bash ~/.acme.sh/acme.sh --issue --standalone -d $DOMAIN -d www.$DOMAIN -ak 4096 -k 4096 --force
            bash ~/.acme.sh/acme.sh --install-cert -d $DOMAIN \
              --key-file    /etc/engine/ssl/live/ssl.key \
              --fullchain-file    /etc/engine/ssl/live/certificate.cert \
              --reloadcmd   "service nginx restart"
    }

  # Setting up different PHP Version branches to prep for install
    function phpdev() {
      echo "Setting up PHP Branches for install.."
        wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add -
      echo "deb https://packages.sury.org/php/ $flavor main" | tee /etc/apt/sources.list.d/php.list
    }

    # Grabbing info on active machine.
        flavor=`lsb_release -cs`
        system=`lsb_release -i | grep "Distributor ID:" | sed 's/Distributor ID://g' | sed 's/["]//g' | awk '{print tolower($1)}'`

#START

# Checking for multiple "required" pieces of software.
    if
      echo -e "\033[92mPerforming upkeep of system packages.. \e[0m"
        upkeep
      echo -e "\033[92mChecking software list..\e[0m"

      [ ! -x  /usr/bin/lsb_release ] || [ ! -x  /usr/bin/wget ] || [ ! -x  /usr/bin/apt-transport-https ] || [ ! -x  /usr/bin/dirmngr ] || [ ! -x  /usr/bin/ca-certificates ] || [ ! -x  /usr/bin/dialog ] ; then

        echo -e "\033[92mlsb_release: checking for software..\e[0m"
        echo -e "\033[34mInstalling lsb_release, Please Wait...\e[0m"
          apt-get install lsb-release

        echo -e "\033[92mwget: checking for software..\e[0m"
        echo -e "\033[34mInstalling wget, Please Wait...\e[0m"
          apt-get install wget

        echo -e "\033[92mapt-transport-https: checking for software..\e[0m"
        echo -e "\033[34mInstalling apt-transport-https, Please Wait...\e[0m"
          apt-get install apt-transport-https

        echo -e "\033[92mdirmngr: checking for software..\e[0m"
        echo -e "\033[34mInstalling dirmngr, Please Wait...\e[0m"
          apt-get install dirmngr

        echo -e "\033[92mca-certificates: checking for software..\e[0m"
        echo -e "\033[34mInstalling ca-certificates, Please Wait...\e[0m"
          apt-get install ca-certificates

        echo -e "\033[92mdialog: checking for software..\e[0m"
        echo -e "\033[34mInstalling dialog, Please Wait...\e[0m"
          apt-get install dialog
    fi

# NGINX Arg main
read -r -p "Do you want to setup NGINX as a Web Server? (Y/N) " REPLY
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
          stable
          upkeep
          nginx_default
          ssldev
          ;;
      2)
        echo "Grabbing Mainline build dependencies.."
          mainline
          upkeep
          nginx_default
          ssldev
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
read -r -p "Do you want to install and setup PHP? (Y/N) " REPLY
  case "${REPLY,,}" in
    [yY]|[yY][eE][sS])
      HEIGHT=20
      WIDTH=120
      CHOICE_HEIGHT=4
      BACKTITLE="NGINE"
      TITLE="PHP Branch Builds"
      MENU="Choose one of the following Build options:"

      OPTIONS=(1 "5.6"
               2 "7.1"
               3 "7.2"
               4 "7.3")

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
        echo "Installing PHP 5.6, and its modules.."
          phpdev
          upkeep
            apt install php5.6 php5.6-fpm php5.6-cli php5.6-common php5.6-curl php5.6-mbstring php5.6-mysql php5.6-xml
            sed -i 's/listen.owner = www-data/listen.owner = nginx/g' /etc/php/5.6/fpm/pool.d/www.conf
            sed -i 's/listen.group = www-data/listen.group = nginx/g' /etc/php/5.6/fpm/pool.d/www.conf
            sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/5.6/fpm/php.ini
            sed -i 's/phpx.x-fpm.sock/php5.6-fpm.sock/g' /etc/nginx/conf.d/nginx-website.conf
            service php5.6-fpm restart
            service php5.6-fpm status
            service nginx restart
            ps aux | grep -v root | grep php-fpm | cut -d\  -f1 | sort | uniq
          ;;
      2)
        echo "Installing PHP 7.1, and its modules.."
          phpdev
          upkeep
            apt install php7.1 php7.1-fpm php7.1-cli php7.1-common php7.1-curl php7.1-mbstring php7.1-mysql php7.1-xml
            sed -i 's/listen.owner = www-data/listen.owner = nginx/g' /etc/php/7.1/fpm/pool.d/www.conf
            sed -i 's/listen.group = www-data/listen.group = nginx/g' /etc/php/7.1/fpm/pool.d/www.conf
            sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.1/fpm/php.ini
            sed -i 's/phpx.x-fpm.sock/php7.1-fpm.sock/g' /etc/nginx/conf.d/nginx-website.conf
            service php7.1-fpm restart
            service php7.1-fpm status
            service nginx restart
            ps aux | grep -v root | grep php-fpm | cut -d\  -f1 | sort | uniq
          ;;
      3)
        echo "Installing PHP 7.2, and its modules.."
          phpdev
          upkeep
            apt install php7.2 php7.2-fpm php7.2-cli php7.2-common php7.2-curl php7.2-mbstring php7.2-mysql php7.2-xml
            sed -i 's/listen.owner = www-data/listen.owner = nginx/g' /etc/php/7.2/fpm/pool.d/www.conf
            sed -i 's/listen.group = www-data/listen.group = nginx/g' /etc/php/7.2/fpm/pool.d/www.conf
            sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.2/fpm/php.ini
            sed -i 's/phpx.x-fpm.sock/php7.2-fpm.sock/g' /etc/nginx/conf.d/nginx-website.conf
            service php7.2-fpm restart
            service php7.2-fpm status
            service nginx restart
            ps aux | grep -v root | grep php-fpm | cut -d\  -f1 | sort | uniq
          ;;
      4)
        echo "Installing PHP 7.3, and its modules.."
          phpdev
          upkeep
           apt install php7.3 php7.3-fpm php7.3-cli php7.3-common php7.3-curl php7.3-mbstring php7.3-mysql php7.3-xml
           sed -i 's/listen.owner = www-data/listen.owner = nginx/g' /etc/php/7.3/fpm/pool.d/www.conf
           sed -i 's/listen.group = www-data/listen.group = nginx/g' /etc/php/7.3/fpm/pool.d/www.conf
           sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.3/fpm/php.ini
           sed -i 's/phpx.x-fpm.sock/php7.3-fpm.sock/g' /etc/nginx/conf.d/nginx-website.conf
           service php7.3-fpm restart
           service php7.3-fpm status
           service nginx restart
           ps aux | grep -v root | grep php-fpm | cut -d\  -f1 | sort | uniq
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

    read -r -p "Would you like to install MySQL/MariaDB, and PHPMyAdmin? (Y/N) " REPLY
      case "${REPLY,,}" in
        [yY]|[yY][eE][sS])
              echo "Setting up MySQL/MariaDB.."
                apt-get install mysql-server
                mysql_secure_installation
              echo "Setting up PHPMyAdmin.."
                apt-get install phpmyadmin
                apt-get install libmcrypt-dev
                ln -s /usr/share/phpmyadmin /var/www/html/pub/live

                # Changes URL/phpmyadmin >> URL/Custom+String
                read -r -p "Custom PHPMyAdmin URL String: " REPLY
                  if [[ "${REPLY,,}" =~ ^[a-zA-Z0-9_.-]*$ ]]
                    then
                      echo "Changing /var/www/html/pub/live/phpmyadmin >> /var/www/html/pub/live/'$REPLY' "
                        mv /var/www/html/pub/live/phpmyadmin /var/www/html/pub/live/$REPLY
                      echo "You can now access PHPMyAdmin with Username: 'phpmyadmin' via: https://$DOMAIN/$REPLY"
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
