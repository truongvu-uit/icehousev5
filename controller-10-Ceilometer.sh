#!/bin/bash -ex
#
source general_setup.cfg

apt-get install ceilometer-api ceilometer-collector ceilometer-agent-central ceilometer-agent-notification ceilometer-alarm-evaluator ceilometer-alarm-notifier python-ceilometerclient -y

apt-get install mongodb-server -y

echo "Cau hinh file /etc/mongodb.conf"
mongo=/etc/heat/mongodb.conf
test -f $mongo.orig || cp $mongo $mongo.orig
rm $mongo
touch $mongo
cat << EOF >> $mongo
dbpath=/var/lib/mongodb
logpath=/var/log/mongodb/mongodb.log
logappend=true
bind_ip=$CON_MGNT_IP
journal=true
EOF

service mongodb restart
sleep 5
#Create the database and a ceilometer database user
mongo --host controller --eval 'db = db.getSiblingDB("ceilometer"); db.addUser({user: "ceilometer", pwd: "CEILOMETER_DBPASS", roles: [ "readWrite", "dbAdmin" ]})'

echo "Cau hinh file /etc/ceilometer/ceilometer.conf"
ceilo=/etc/ceilometer/ceilometer.conf
test -f $ceilo.orig || cp $ceilo $ceilo.orig
rm $ceilo
touch $ceilo
cat << EOF >> $ceilo

[DEFAULT] 
rabbit_host=controller
rabbit_password=RABBIT_PASS
log_dir=/var/log/ceilometer
auth_strategy=keystone
sqlite_db=ceilometer.sqlite

[alarm]

[api]

[collector]

[database]
# The SQLAlchemy connection string used to connect to the
# database (string value)
backend=sqlalchemy
connection=mongodb://ceilometer:CEILOMETER_DBPASS@controller:27017/ceilometer

[dispatcher_file]

[event]

[matchmaker_redis]

[matchmaker_ring]

[notification]


[publisher]
# Secret value for signing metering messages (string value)
metering_secret=CEILOMETER_TOKEN

[publisher_rpc]


[rpc_notifier2]


[keystone_authtoken]
auth_host=controller
auth_port=35357
auth_protocol=http
auth_uri=http://controller:5000
admin_tenant_name=service
admin_user=ceilometer
admin_password=CEILOMETER_PASS

[service_credentials]
os_auth_url=http://controller:5000/v2.0
os_username=ceilometer
os_tenant_name=service
os_password=CEILOMETER_PASS

[ssl]

[vmware]

EOF

keystone user-create --name=ceilometer --pass=CEILOMETER_PASS --email=ceilometer@example.com
keystone user-role-add --user=ceilometer --tenant=service --role=admin

keystone service-create --name=ceilometer --type=metering --description="Telemetry"
keystone endpoint-create --service-id=$(keystone service-list | awk '/ metering / {print $2}') --publicurl=http://$CON_EXT_IP:8777 --internalurl=http://controller:8777 --adminurl=http://controller:8777

service ceilometer-agent-central restart
service ceilometer-agent-notification restart
service ceilometer-api restart
service ceilometer-collector restart
service ceilometer-alarm-evaluator restart
service ceilometer-alarm-notifier restart
echo "XOng"

