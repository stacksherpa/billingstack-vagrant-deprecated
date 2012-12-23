echo "###############################################"
echo "# installing nova                             #"
echo "###############################################"

sleep 2

apt-get remove -y nova-compute nova-compute-qemu nova-volume nova-novncproxy novnc nova-api nova-ajax-console-proxy nova-cert nova-consoleauth nova-doc nova-scheduler nova-network
apt-get autoremove -y --purge
apt-get install -y nova-compute nova-compute-qemu nova-volume nova-novncproxy novnc nova-api nova-ajax-console-proxy nova-cert nova-consoleauth nova-doc nova-scheduler nova-network

#apt-get -y install guestmount

mysql -u root -p$PASSWORD -h 10.20.30.40 << EOF
DROP DATABASE IF EXISTS nova;
CREATE DATABASE nova;
GRANT ALL ON nova.* TO 'nova'@'%' IDENTIFIED BY '$PASSWORD';
GRANT ALL ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$PASSWORD';
EOF

#FLATDHCP

sudo apt-get install bridge-utils

#ip link set eth1 promisc on

cat >> /etc/network/interfaces << EOF
# The loopback network interface
# auto lo
# iface lo inet loopback

# The primary network interface
# auto eth0
# iface eth0 inet dhcp

# auto eth1
# iface eth1 inet dhcp
                    
# Bridge network interface for VM networks 
# auto br100 
# iface br100 inet static 
# address 10.20.30.50 
# netmask 255.255.255.0 
# bridge_stp off
# bridge_fd 0
EOF

# /etc/init.d/networking restart

cat > /etc/nova/nova.conf << EOF
[DEFAULT]
#force_dhcp_release=True
#iscsi_helper=tgtadm
#libvirt_use_virtio_for_bridges=True
#connection_type=libvirt
#root_helper=sudo nova-rootwrap /etc/nova/rootwrap.conf
#ec2_private_dns_show_ip=True
#api_paste_config=/etc/nova/api-paste.ini
#volumes_path=/var/lib/nova/volumes

# logs / state
verbose=True
logdir=/var/log/nova
state_path=/var/lib/nova
lock_path=/var/lock/nova
rootwrap_config=/etc/nova/rootwrap.conf

# scheduler
# compute_scheduler_driver=nova.scheduler.filter_scheduler.FilterScheduler
compute_scheduler_driver=nova.scheduler.simple.SimpleScheduler


# volumes (nova-volume)

volume_driver=nova.volume.driver.ISCSIDriver
volume_group=nova-volumes
volume_name_template=volume-%s
iscsi_helper=tgtadm

# database

sql_connection=mysql://nova:$PASSWORD@10.20.30.40/nova

# compute

libvirt_type=qemu
compute_driver=libvirt.LibvirtDriver
instance_name_template=instance-%08x
api_paste_config=/etc/nova/api-paste.ini

# COMPUTE/APIS: if you have separate configs for separate services
# this flag is required for both nova-api and nova-compute
allow_resize_to_same_host=True

# APIS
osapi_compute_extension=nova.api.openstack.compute.contrib.standard_extensions
ec2_dmz_host=10.20.30.50
s3_host=10.20.30.50

# RABBITMQ
rabbit_host=10.20.30.40
rabbit_password=$PASSWORD

# glance
image_service=nova.image.glance.GlanceImageService
glance_api_servers=10.20.30.50:9292

# network (nova-network)

network_manager=nova.network.manager.FlatDHCPManager
force_dhcp_release=True
dhcpbridge_flagfile=/etc/nova/nova.conf
dhcpbridge=/usr/bin/nova-dhcpbridge
firewall_driver=nova.virt.libvirt.firewall.IptablesFirewallDriver
my_ip=10.20.30.50
public_interface=br100
flat_interface=eth1
flat_network_bridge=br100
fixed_range=10.0.0.0/24

# novnc console
novncproxy_base_url=http://10.20.30.50:6080/vnc_auto.html
vncserver_proxyclient_address=10.20.30.50
vncserver_listen=10.20.30.50

# ceilometer

instance_usage_audit=True
instance_usage_audit_period=hour
notification_driver=nova.openstack.common.notifier.rabbit_notifier
notification_driver=ceilometer.compute.nova_notifier

# AUTHENTICATION
auth_strategy=keystone
[keystone_authtoken]
auth_host = 10.20.30.50
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = nova
admin_password = $PASSWORD
signing_dirname = /tmp/keystone-signing-nova
EOF

sed -i "s|%SERVICE_TENANT_NAME%|service|g" /etc/nova/api-paste.ini
sed -i "s|%SERVICE_USER%|nova|g" /etc/nova/api-paste.ini
sed -i "s|%SERVICE_PASSWORD%|$PASSWORD|g" /etc/nova/api-paste.ini

dd if=/dev/zero of=/var/lib/nova/nova-volumes.img bs=1M seek=20k count=0
vgcreate nova-volumes $(sudo losetup --show -f /var/lib/nova/nova-volumes.img)

nova-manage db sync

sleep 3

service nova-api restart
service nova-compute restart
service nova-network restart
service nova-scheduler restart
service nova-novncproxy restart
service nova-volume restart
service libvirt-bin restart
/etc/init.d/rabbitmq-server restart

nova-manage service list

sleep 2

nova-manage network create private --fixed_range_v4=10.0.0.0/24 --bridge_interface=br100 --num_networks=1 --network_size=256

nova boot --image cirros --flavor 1 --poll cirros
nova list
