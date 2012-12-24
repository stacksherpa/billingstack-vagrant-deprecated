#!/usr/bin/env bash

PASSWORD=secret0

apt-get update

sysctl -w net.ipv4.ip_forward=1

apt-get install -y ubuntu-cloud-keyring

cat > /etc/apt/sources.list.d/folsom.list << EOF
deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/folsom main
EOF

apt-get update

apt-get install -y curl vim mysql-client-core-5.5 python-mysqldb

cat > openrc <<EOF
export OS_USERNAME=admin
export OS_TENANT_NAME=admin
export OS_PASSWORD=$PASSWORD
export OS_AUTH_URL=http://10.20.30.50:5000/v2.0/
export OS_REGION_NAME=RegionOne
export SERVICE_ENDPOINT="http://10.20.30.50:35357/v2.0"
export SERVICE_TOKEN=$PASSWORD
export OS_NO_CACHE=1
EOF

source openrc
source /vagrant/keystone.sh
source /vagrant/glance.sh
source /vagrant/nova.sh
source /vagrant/ceilometer-agent-compute.sh

install_ceilometer_agent_compute

configure_ceilometer_agent_compute

ceilometer-agent-compute &

echo "CEILOMETER AGENT STARTED!"
