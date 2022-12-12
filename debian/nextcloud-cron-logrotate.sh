#!/bin/bash
# run it from cron.daily on the docker host side
# Adjust location of status file - below example takes into accont multiple nodes, 
#   logging last status in shared location, hence requiredment for unique ID (file)

#/bin/docker exec -t -u www-data nextcloud /bin/bash -c "/usr/bin/nice -n 19 logrotate -s /data/addons-custom/logrotate.d/status/<THIS_NODE>  /etc/logrotate.d/nextcloud.conf"
/bin/docker exec -t -u www-data nextcloud /bin/bash -c "/usr/bin/nice -n 19 logrotate -s /data/addons-custom/logrotate.d/status/<THIS_NODE>  /data/addons-custom/logrotate.d/nextcloud.log"
