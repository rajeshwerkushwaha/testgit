#!/bin/bash

# OS VERSION: Ubuntu Server 14.04.x LTS
# ARCH: x32_64

# Project Fedena Automated Installation Script
# =============================================
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# First we check if the user is 'root' before allowing installation to commence
if [ $UID -ne 0 ]; then
    echo "Install failed! To install you must be logged in as 'root', please try again."
    exit 1
fi

# Ensure the installer is launched and can only be launched on Ubuntu 14.04
BITS=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
if [ -f /etc/lsb-release ]; then
  OS=$(cat /etc/lsb-release | grep DISTRIB_ID | sed 's/^.*=//')
  VER=$(cat /etc/lsb-release | grep DISTRIB_RELEASE | sed 's/^.*=//')
else
  OS=$(uname -s)
  VER=$(uname -r)
fi
echo "Detected : $OS  $VER  $BITS"
if [ "$OS" = "Ubuntu" ] && [ "$VER" = "14.04" ]; then
  echo "Ok."
else
  echo "Sorry. We have detected that you are NOT running Ubuntu 14.04.*" 
  echo "Installation halted!"
  exit 1;
fi

# Display the 'welcome' splash/user warning info..
echo -e ""
echo -e "##############################################################"
echo -e "# Welcome to the Fedena 2.3 Auto Installer for Ubuntu        #"
echo -e "# Server 14.04.x LTS                                         #"
echo -e "#                                                            #"
echo -e "# Please make sure your VPS provider hasn't pre-installed    #"
echo -e "# any Ruby or MySQL packages.                                #"
echo -e "#                                                            #"
echo -e "# If you are installing on a physical machine where the OS   #"
echo -e "# has been installed by yourself please make sure you only   #"
echo -e "# installed Ubuntu Server with no extra packages.            #"
echo -e "#                                                            #"
echo -e "# If you selected additional options during the Ubuntu       #"
echo -e "# install please consider reinstalling without them.         #"
echo -e "#                                                            #"
echo -e "# For support, e-mail: n3rve@n3rve.com                       #"
echo -e "#                                                            #"
echo -e "##############################################################"
echo -e ""

sleep 15

# Let's get the package index updated
# This may be redundant, but there's no way to tell  
apt-get update
apt-get install -y ruby1.8 rails rubygems

# Installing Unzip
apt-get install -y unzip

echo "Downgrading Rubygems ... Fedena 2.3 requires v=1.3.7"
gem install rubygems-update -v=1.3.7
update_rubygems --version=1.3.7

echo "Installing the MySQL server ..."
sleep 2
export DEBIAN_FRONTEND=noninteractive
apt-get -q -y install  mysql-server mysql-client libmysql-ruby
sleep 3
mysqladmin -u root password foradian
echo "MySQL password set as 'foradian'"
sleep 2

echo "Updating GEMs."
sleep 2
gem install rails -v=2.3.5 --no-ri --no-rdoc
gem uninstall rake -Iax
gem install rake -v=0.8.7 --no-ri --no-rdoc
gem install i18n -v 0.4.2 --no-ri --no-rdoc
gem install rush -v 0.6.8 --no-ri --no-rdoc
gem install mongrel -v=1.1.5 --no-ri --no-rdoc

# We securely download Fedena from the content distribution network at n3rve.com
echo "Securely connecting to n3rve.com to download Project Fedena 2.3"
sleep 3
echo "Access credentials sent"
sleep 2
wget http://cdn.n3rve.com/secure/dl/fedena/2.3/fedena_2.3.zip --user=fedena23 --password='vEf879AC5vp44Ab'
sleep 5
echo "Un-archiving & preparing Fedena for installation"
sleep 2
unzip *.zip
cd ~/fedena-v2.3-bundle-linux/
sleep 1
rake gems:install
echo "Creating Database"
rake db:create
sleep 1
echo "Executing migrating task!"
rake db:migrate
sleep 2
echo "Populating MySQL Tables"
rake fedena:plugins:install_all
sleep 2 
echo "Cleaning up ..."
sleep 3
rm ../fedena_2.3.zip
echo "Fixing Permissions ..."
sleep 1
chmod +x script*
sleep 1
echo "Starting a GNU Screen session"
sleep 2
screen -d -m mongrel_rails start -e production -p 8088
echo "Installation complete. Visit http://<your-server-ip.com:8088"
echo "Login with admin / admin123."
echo "For the professional version of Fedena, contact: n3rve@n3rve.com"
cd ../ && rm -- "$0"
