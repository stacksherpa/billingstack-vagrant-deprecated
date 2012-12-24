#apt-get install -y python-software-properties
#add-apt-repository -y ppa:openstack-ubuntu-testing/grizzly-trunk-testing
#apt-get update
#sudo apt-get -o Dpkg::Options::="--force-overwrite" install ceilometer-agent-compute
PASSWORD=secret0
apt-get update

apt-get install -y vim python-setuptools python-greenlet python-openssl python-lxml git

cat > openrc <<EOF
export OS_USERNAME=admin
export OS_TENANT_NAME=admin
export OS_PASSWORD=secret0
export OS_AUTH_URL=http://10.20.30.50:5000/v2.0/
export OS_REGION_NAME=RegionOne
export SERVICE_ENDPOINT="http://10.20.30.50:35357/v2.0"
export SERVICE_TOKEN=secret0
export OS_NO_CACHE=1
EOF

source openrc

#wget http://tarballs.openstack.org/ceilometer/ceilometer-2013.1~g2~20121222.427.tar.gz > /dev/null 2>&1
#tar xfz ceilometer-2013.1~g2~20121222.427.tar.gz
git clone http://github.com/openstack/ceilometer ceilometer-2013.1

sed -i "s|acl.install(app, cfg.CONF)|acl.install(app, dict(cfg.CONF))|g" /home/vagrant/ceilometer-2013.1/ceilometer/api/v1/app.py

cd /home/vagrant/ceilometer-2013.1/

python setup.py install

cp -r etc/ceilometer /etc

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
auth_strategy=keystone

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

/home/vagrant/ceilometer-2013.1/bin/ceilometer-dbsync

sleep 3

ceilometer-agent-central &
ceilometer-collector &
ceilometer-api &

#git clone https://github.com/openstack/python-ceilometerclient

#cd python-ceilometerclient

#python setup.py install

#ceilometer project-list
