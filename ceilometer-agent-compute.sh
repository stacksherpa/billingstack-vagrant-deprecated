#apt-get install -y python-software-properties
#add-apt-repository -y ppa:openstack-ubuntu-testing/grizzly-trunk-testing
#apt-get update
#sudo apt-get -o Dpkg::Options::="--force-overwrite" install ceilometer-agent-compute

function install_ceilometer_agent_compute() {
	
#wget http://tarballs.openstack.org/ceilometer/ceilometer-2013.1~g2~20121222.427.tar.gz > /dev/null 2>&1
#tar xfz ceilometer-2013.1~g2~20121222.427.tar.gz
git clone http://github.com/openstack/ceilometer ceilometer-2013.1

cat > /home/vagrant/ceilometer-2013.1/tools/pip-requires << EOF
webob
kombu
iso8601
lockfile
netaddr
argparse
SQLAlchemy>=0.7.3,<=0.7.9
sqlalchemy-migrate>=0.7.2
pymongo>=2.2
eventlet
anyjson>=0.2.4
Flask==0.9
stevedore>=0.6
lxml
EOF

cd /home/vagrant/ceilometer-2013.1/

python setup.py install
	
}

function configure_ceilometer_agent_compute() {
	
cp -r /home/vagrant/ceilometer-2013.1/etc/ceilometer /etc

CEILOMETER_CONF=/etc/ceilometer/ceilometer.conf

mv /etc/ceilometer/ceilometer.conf.sample $CEILOMETER_CONF
sed -i "s|# log_file=<None>|log_file=ceilometer.log|g" $CEILOMETER_CONF
sed -i "s|# log_dir=<None>|log_dir=/var/log/ceilometer|g" $CEILOMETER_CONF
sed -i "s|# database_connection=mongodb://localhost:27017/ceilometer|database_connection=mongodb://10.20.30.40:27017/ceilometer|g" $CEILOMETER_CONF
sed -i "s|# rabbit_hosts=\$rabbit_host:\$rabbit_port|rabbit_hosts=10.20.30.40:5672|g" $CEILOMETER_CONF
sed -i "s|# rabbit_password=guest|rabbit_password=secret0|g" $CEILOMETER_CONF

cat >> $CEILOMETER_CONF << EOF
os_tenant_name=service
os_username=ceilometer
os_password=$PASSWORD
os_auth_url=http://10.20.30.50:5000/v2.0

[keystone_authtoken]
auth_host = 10.20.30.50
auth_port = 5000
auth_protocol = http
admin_tenant_name = service
admin_user = ceilometer
admin_password = $PASSWORD
signing_dirname = /tmp/keystone-signing-ceilometer
EOF

mkdir /var/log/ceilometer
	
}
