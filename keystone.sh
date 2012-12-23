echo "###############################################"
echo "# installing keystone                         #"
echo "###############################################"

sleep 2

apt-get install -y keystone
rm /var/lib/keystone/keystone.db
mysql -u root -p$PASSWORD -h 10.20.30.40 << EOF
DROP DATABASE IF EXISTS keystone;
CREATE DATABASE keystone;
GRANT ALL ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$PASSWORD';
GRANT ALL ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$PASSWORD';
EOF

KEYSTONE_CONF=/etc/keystone/keystone.conf
sed -i "s|# admin_token = ADMIN|admin_token = $PASSWORD|g" $KEYSTONE_CONF
sed -i "s|sqlite:////var/lib/keystone/keystone.db|mysql://keystone:$PASSWORD@10.20.30.40/keystone|g" $KEYSTONE_CONF
sed -i "s|# verbose = False|verbose = True|g" $KEYSTONE_CONF
sed -i "s|# debug = False|debug = True|g" $KEYSTONE_CONF
sed -i "s|#token_format = PKI|token_format = UUID|g" $KEYSTONE_CONF

keystone-manage db_sync

sleep 3

service keystone restart

echo "###############################################"
echo "# keystone data ...                           #"
echo "###############################################"

sleep 5

source /vagrant/keystone_data.sh
