#!bin/bash
#Start OC
if [ "${OSNAME}" = "debian" ]; then
       apt-get -y install git drush
       apt-get -y install composer
       composer require drush/drush
   else
      yum -y install git drush
      yum -y install composer
      composer require drush/drush
      export VESTA=/usr/local/vesta/
fi
#Firs Conf
user=admin
domain="$(cat /etc/hostname)"
echo "########################################################"
echo "########################################################"
echo "                  START INSTALL                         "
export VESTA=/usr/local/vesta/
SITEDIR="/home/$user/web/$domain/public_html"
rm -rf $SITEDIR/*
#
#mysql_upgrade
rm -f /etc/yum.repos.d/MariaDB10.repo
touch /etc/yum.repos.d/MariaDB10.repo
cat > /etc/yum.repos.d/MariaDB10.repo <<EOF
# MariaDB 10.5
# http://mariadb.org/mariadb/repositories/
[mariadb]
name=MariaDB
baseurl=http://yum.mariadb.org/10.5/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
yum remove -y mariadb-server mariadb mariadb-libs
yum clean all 
yum -y install MariaDB-server MariaDB-client
systemctl start mariadb
systemctl enable mariadb
mysql_upgrade
#
#Drupal
cd $SITEDIR 
wget https://ftp.drupal.org/files/projects/drupal-9.1.10.zip
unzip drupal-9.1.10.zip
mv drupal-9.1.10.zip/* $SITEDIR/
chown -R $user. $SITEDIR
#DATABASE
DBUSERSUFB="dru";
i=0;
while [ $i -lt 99 ]
do
i=$((i+1));
DBUSERSUF="${DBUSERSUFB}${i}";
DBUSER=$user\_$DBUSERSUF;
if [ ! -d "/var/lib/mysql/$DBUSER" ]; then
break;
fi
done
PASSWDDB=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
/usr/local/vesta/bin/v-add-database $user $DBUSERSUF $DBUSERSUF $PASSWDDB mysql
cd $SITEDIR
#password="($PASS)"
password="123"

drush site-install standard --account-name=admin --account-pass=$password --db-url=mysql://$DBUSER:$DBUSER@localhost/$DBUSER -y
drush dl devel, module_filter, admin_menu
drush en devel, module_filter, admin_menu -y
drush dis overlay, toolbar -y
