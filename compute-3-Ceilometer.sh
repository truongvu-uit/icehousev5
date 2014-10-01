#!/bin/bash -ex
#
source general_setup.cfg

apt-get install ceilometer-agent-compute -y

echo "Cau hinh file /etc/ceilometer/ceilometer.conf"
ceilo=/etc/ceilometer/ceilometer.conf
test -f $ceilo.orig || cp $ceilo $ceilo.orig
rm $ceilo
touch $ceilo
cat << EOF >> $ceilo
[DEFAULT] 
rabbit_host = controller
rabbit_password = RABBIT_PASS
log_dir = /var/log/ceilometer
sqlite_db=ceilometer.sqlite


[alarm]

[api]

[collector]

[dispatcher_file]

[event]

[matchmaker_redis]

[matchmaker_ring]

[notification]


[publisher]
metering_secret=CEILOMETER_TOKEN

[publisher_rpc]


[rpc_notifier2]

[keystone_authtoken]
auth_host=controller
auth_port=35357
auth_protocol=http
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

service ceilometer-agent-compute restart
echo "xong"