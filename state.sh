PASSWORD=secret0

apt-get update

cat << EOF | debconf-set-selections
mysql-server-5.5 mysql-server/root_password password $PASSWORD
mysql-server-5.5 mysql-server/root_password_again password $PASSWORD
mysql-server-5.5 mysql-server/start_on_boot boolean true
EOF

apt-get -y install vim mysql-server rabbitmq-server mongodb

sed -i '/^bind-address/s/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf

mysql -u root -p$PASSWORD << EOF
GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY '$PASSWORD' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

service mysql restart

#/usr/bin/mysql_secure_installation

rabbitmqctl change_password guest $PASSWORD

sed -i '/^bind_ip/s/127.0.0.1/0.0.0.0/g' /etc/mongodb.conf

service mongodb restart
