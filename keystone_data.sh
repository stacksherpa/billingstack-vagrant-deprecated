TENANT=admin
PASSWORD=secret0

## Define Admin, Member role and OpenstackDemo tenant
TENANT_ID=$(keystone tenant-create --name $TENANT | grep id | awk '{print $4}')
ADMIN_ROLE=$(keystone role-create --name Admin | grep id | awk '{print $4}')
MEMBER_ROLE=$(keystone role-create --name Member | grep id | awk '{print $4}')

# create user admin
ADMIN_USER=$(keystone user-create --name admin --tenant-id $TENANT_ID --pass $PASSWORD --email root@localhost --enabled true | grep id | awk '{print $4}')

# grant Admin role to the admin user in the openstackDemo tenant
keystone user-role-add --user-id $ADMIN_USER --role-id $ADMIN_ROLE --tenant-id $TENANT_ID

## Create Service tenant. This tenant contains all the services that we make known to the service catalog.
SERVICE_TENANT_ID=$(keystone tenant-create --name service | grep id | awk '{print $4}')

# Create services user in Service tenant
GLANCE_ID=$(keystone user-create --name glance --tenant-id $SERVICE_TENANT_ID --pass $PASSWORD --enabled true | grep id | awk '{print $4}')
NOVA_ID=$(keystone user-create --name nova --tenant-id $SERVICE_TENANT_ID --pass $PASSWORD --enabled true | grep id | awk '{print $4}')
EC2_ID=$(keystone user-create --name ec2 --tenant-id $SERVICE_TENANT_ID --pass $PASSWORD --enabled true | grep id | awk '{print $4}')
CINDER_ID=$(keystone user-create --name cinder --tenant-id $SERVICE_TENANT_ID --pass $PASSWORD --enabled true | grep id | awk '{print $4}')
CEILOMETER_ID=$(keystone user-create --name ceilometer --tenant-id $SERVICE_TENANT_ID --pass $PASSWORD --enabled true | grep id | awk '{print $4}')

# Grant admin role for those service user in Service tenant
for ID in $GLANCE_ID $NOVA_ID $EC2_ID $CINDER_ID $CEILOMETER_ID
do
keystone user-role-add --user-id $ID --tenant-id $SERVICE_TENANT_ID --role-id $ADMIN_ROLE
done

## Define services
KEYSTONE_SERVICE_ID=$(keystone service-create --name keystone --type identity --description 'OpenStack Identity Service' | grep 'id ' | awk '{print $4}')
COMPUTE_SERVICE_ID=$(keystone service-create --name nova --type compute --description 'OpenStack Compute Service' | grep id | awk '{print $4}') 
VOLUME_SERVICE_ID=$(keystone service-create --name volume --type volume --description 'OpenStack Volume Service' | grep id | awk '{print $4}')
GLANCE_SERVICE_ID=$(keystone service-create --name glance --type image --description 'OpenStack Image Service'  | grep id | awk '{print $4}')
EC2_SERVICE_ID=$(keystone service-create --name ec2 --type ec2 --description 'EC2 Service' | grep id | awk '{print $4}')
CINDER_SERVICE_ID=$(keystone service-create --name cinder --type volume --description 'Cinder Service' | grep id | awk '{print $4}')
CEILOMETER_SERVICE_ID=$(keystone service-create --name ceilometer --type metering --description 'Ceilometer Service' | grep id | awk '{print $4}')

# Create endpoints to these services

IP=10.20.30.50
REGION=RegionOne

KEYSTONE_IP=$IP
NOVA_IP=$IP
VOLUME_IP=$IP
GLANCE_IP=$IP
EC2_IP=$IP
CEILOMETER_IP=10.20.30.60

NOVA_PUBLIC_URL="http://$NOVA_IP:8774/v2/%(tenant_id)s"
NOVA_ADMIN_URL=$NOVA_PUBLIC_URL
NOVA_INTERNAL_URL=$NOVA_PUBLIC_URL

VOLUME_PUBLIC_URL="http://$VOLUME_IP:8776/v1/%(tenant_id)s"
VOLUME_ADMIN_URL=$VOLUME_PUBLIC_URL
VOLUME_INTERNAL_URL=$VOLUME_PUBLIC_URL

#GLANCE_PUBLIC_URL="http://$GLANCE_IP:9292/v1"
GLANCE_PUBLIC_URL="http://$GLANCE_IP:9292"
GLANCE_ADMIN_URL=$GLANCE_PUBLIC_URL
GLANCE_INTERNAL_URL=$GLANCE_PUBLIC_URL

KEYSTONE_PUBLIC_URL="http://$KEYSTONE_IP:5000/v2.0"
KEYSTONE_ADMIN_URL="http://$KEYSTONE_IP:35357/v2.0"
KEYSTONE_INTERNAL_URL=$KEYSTONE_PUBLIC_URL

EC2_PUBLIC_URL="http://$EC2_IP:8773/services/Cloud"
EC2_ADMIN_URL="http://$EC2_IP:8773/services/Admin"
EC2_INTERNAL_URL=$EC2_PUBLIC_URL

CEILOMETER_PUBLIC_URL="http://$CEILOMETER_IP:8777"
CEILOMETER_ADMIN_URL=$CEILOMETER_PUBLIC_URL
CEILOMETER_INTERNAL_URL=$CEILOMETER_PUBLIC_URL

keystone endpoint-create --region $REGION --service-id $COMPUTE_SERVICE_ID --publicurl $NOVA_PUBLIC_URL --adminurl $NOVA_ADMIN_URL --internalurl $NOVA_INTERNAL_URL
keystone endpoint-create --region $REGION --service-id $VOLUME_SERVICE_ID --publicurl $VOLUME_PUBLIC_URL --adminurl $VOLUME_ADMIN_URL --internalurl $VOLUME_INTERNAL_URL
keystone endpoint-create --region $REGION --service-id $KEYSTONE_SERVICE_ID --publicurl $KEYSTONE_PUBLIC_URL --adminurl $KEYSTONE_ADMIN_URL --internalurl $KEYSTONE_INTERNAL_URL
keystone endpoint-create --region $REGION --service-id $GLANCE_SERVICE_ID --publicurl $GLANCE_PUBLIC_URL --adminurl $GLANCE_ADMIN_URL --internalurl $GLANCE_INTERNAL_URL
keystone endpoint-create --region $REGION --service-id $EC2_SERVICE_ID --publicurl $EC2_PUBLIC_URL --adminurl $EC2_ADMIN_URL --internalurl $EC2_INTERNAL_URL
keystone endpoint-create --region $REGION --service-id $CINDER_SERVICE_ID --publicurl $VOLUME_PUBLIC_URL --adminurl $VOLUME_ADMIN_URL --internalurl $VOLUME_INTERNAL_URL
keystone endpoint-create --region $REGION --service-id $CEILOMETER_SERVICE_ID --publicurl $CEILOMETER_PUBLIC_URL --adminurl $CEILOMETER_ADMIN_URL --internalurl $CEILOMETER_INTERNAL_URL
