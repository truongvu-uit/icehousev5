#!/bin/bash -ex
#
source general_setup.cfg

echo "Cai dat các goi"
apt-get install heat-api heat-api-cfn heat-engine -y

echo "Cau hinh file /etc/heat/heat.conf"
heat=/etc/heat/heat.conf
test -f $heat.orig || cp $heat $heat.orig
rm $heat
touch $heat
cat << EOF >> $heat

[DEFAULT]
verbose = True
log_dir = /var/log/heat

rabbit_host = controller
rabbit_password = RABBIT_PASS

[auth_password]

[clients]

[clients_ceilometer]

[clients_cinder]

[clients_heat]

[clients_keystone]

[clients_neutron]

[clients_nova]

[clients_swift]

[clients_trove]

[database]
# The SQLAlchemy connection string used to connect to the database
connection=mysql://heat:HEAT_DBPASS@controller/heat

[ec2authtoken]
auth_uri=http://controller:5000/v2.0

[heat_api]
###
bind_host=$CON_MGNT_IP

[heat_api_cfn]
###
bind_host=$CON_MGNT_IP

[heat_api_cloudwatch]

[keystone_authtoken]
auth_host=controller
auth_port=35357
auth_protocol=http
auth_uri=http://controller:5000/v2.0
admin_tenant_name=service
admin_user=heat
admin_password=HEAT_PASS

[matchmaker_redis]

[matchmaker_ring]

[paste_deploy]

[revision]

[rpc_notifier2]

[ssl]

EOF

rm /var/lib/heat/heat.sqlite
rm -f /var/lib/heat/heat.sqlite

echo "=====> Tao db"
cat <<EOF | mysql -u root -p$MYSQL_PASS
CREATE DATABASE heat;
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'localhost' IDENTIFIED BY 'HEAT_DBPASS';
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%' IDENTIFIED BY 'HEAT_DBPASS';
EOF

echo "Dong bo"
sleep 5
su -s /bin/sh -c "heat-manage db_sync" heat 
sleep 10 

keystone user-create --name=heat --pass=HEAT_PASS --email=heat@example.com
keystone user-role-add --user=heat --tenant=service --role=admin

keystone service-create --name=heat --type=orchestration --description="Orchestration"
keystone endpoint-create --service-id=$(keystone service-list | awk '/ orchestration / {print $2}') --publicurl=http://$CON_EXT_IP:8004/v1/%\(tenant_id\)s --internalurl=http://controller:8004/v1/%\(tenant_id\)s --adminurl=http://controller:8004/v1/%\(tenant_id\)s

keystone service-create --name=heat-cfn --type=cloudformation --description="Orchestration CloudFormation"
keystone endpoint-create --service-id=$(keystone service-list | awk '/ cloudformation / {print $2}') --publicurl=http://$CON_EXT_IP:8000/v1 --internalurl=http://controller:8000/v1 --adminurl=http://controller:8000/v1

service heat-api restart
service heat-api-cfn restart
service heat-engine restart

echo "Verify the Orchestration service installation"
sleep 3
source demo-openrc.sh
NET_ID=$(nova net-list | awk '/ demo-net / { print $2 }')
heat stack-create -f test-stack.yml -P "ImageID=cirros-0.3.2-x86_64;NetID=$NET_ID" testStack
heat stack-list
echo "Xong Heat"