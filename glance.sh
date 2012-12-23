echo "###############################################"
echo "# installing glance                           #"
echo "###############################################"

sleep 2

apt-get remove -y glance --purge
apt-get autoremove -y --purge
apt-get install -y glance

#fix
sed -i "s|python-keystoneclient>=0.1.2,<0.2|python-keystoneclient>=0.1.2|g" /usr/lib/python2.7/dist-packages/python_glanceclient-0.5.1.egg-info/requires.txt

rm /var/lib/glance/glance.sqlite

mysql -u root -p$PASSWORD -h 10.20.30.40 << EOF
DROP DATABASE IF EXISTS glance;
CREATE DATABASE glance;
GRANT ALL ON glance.* TO 'glance'@'%' IDENTIFIED BY '$PASSWORD';
GRANT ALL ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$PASSWORD';
EOF

cat >> /etc/glance/glance-api-paste.ini <<EOF
admin_tenant_name = service
admin_user = glance
admin_password = $PASSWORD
EOF

cat >> /etc/glance/glance-registry-paste.ini <<EOF

# Use this pipeline for keystone auth
[pipeline:glance-registry-keystone]
pipeline = authtoken context registryapp
EOF

sed -i "s|sqlite:////var/lib/glance/glance.sqlite|mysql://glance:$PASSWORD@10.20.30.40/glance|g" /etc/glance/*.conf
sed -i "s|%SERVICE_TENANT_NAME%|service|g" /etc/glance/*.conf
sed -i "s|%SERVICE_USER%|glance|g" /etc/glance/*.conf
sed -i "s|%SERVICE_PASSWORD%|$PASSWORD|g" /etc/glance/*.conf
sed -i "s|#flavor=|flavor=keystone|g" /etc/glance/*.conf

sed -i "s|#config_file = glance-api-paste.ini|config_file = /etc/glance/glance-api-paste.ini|g" /etc/glance/glance-api.conf
sed -i "s|notifier_strategy = noop|notifier_strategy = rabbit|g" /etc/glance/glance-api.conf
sed -i "s|rabbit_host = localhost|rabbit_host = 10.20.30.40|g" /etc/glance/glance-api.conf
sed -i "s|rabbit_password = guest|rabbit_password = $PASSWORD|g" /etc/glance/glance-api.conf

sed -i "s|#config_file = glance-registry-paste.ini|config_file = /etc/glance/glance-registry-paste.ini|g" /etc/glance/glance-registry.conf

#service glance-api restart
#service glance-registry restart

glance-manage version_control 0
glance-manage db_sync

sleep 3

service glance-api restart
service glance-registry restart

sleep 3

echo "###############################################"
echo "# creating cirros test image                  #"
echo "###############################################"

glance image-create --name cirros --is-public true --container-format bare --disk-format qcow2 --location https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img

glance image-list
