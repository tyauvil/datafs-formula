{%- from 'datafs/settings.sls' import datafs with context -%}
#!/usr/bin/env python
# THIS FILE IS MANAGED BY SALT DO NOT CHANGE
"""Creats ebs backups based on infromation provided by salt to ensure backups
are created and named in a standard way"""

import boto.ec2
import time
from datetime import timedelta, datetime
from ebs_hooks import execute_shell_command, execute_hook
from zabbix.sender import ZabbixMetric, ZabbixSender

HOOKS = {{datafs.backup_hooks}}

BACKUP_TYPE = '{{ grains.env }}-{{ grains.server_type }}'
BACKUP_DEVICES = {{datafs.backup_devices}}
MINION_ID = '{{ grains.id }}'

EC2 = boto.ec2.connect_to_region('us-east-1',
                                 aws_access_key_id='{{ datafs.backup_aws_key }}',
                                 aws_secret_access_key='{{ datafs.backup_aws_secret }}')

INSTANCE = boto.utils.get_instance_metadata()['instance-id']
VOLUMES = EC2.get_all_volumes(filters={'attachment.instance-id': INSTANCE})
DESCRIPTION = "{0}_{1}".format(BACKUP_TYPE, time.strftime("%Y%m%d%H%M"))


def report_to_zabbix(state):
    """Report boolean status to zabbix if backup was successful or failed"""
    stats = {'backup_state': state}
    packet = []
    for key, value in stats.items():
        packet.append(ZabbixMetric(MINION_ID, key, value))
    try:
        ZabbixSender(use_config=True).send(packet)
    except Exception, e:
        quit("Unable to send statistics to zabbix. {}".format(e))


def backup_failed(error):
    report_to_zabbix(False)
    quit(error.error_message)

try:
    execute_hook(HOOKS, 'before')
    execute_hook(HOOKS, 'during')
except Exception, e:
    backup_failed(e)


for volume in VOLUMES:
    device = volume.attach_data.device.split('/')[-1]
    legacy_device = device.replace('sd', 'xvd')
    if device in BACKUP_DEVICES or legacy_device in BACKUP_DEVICES:
        snapshot_description = "{0}_{1}".format(DESCRIPTION, device)
        try:
            snapshot = volume.create_snapshot(snapshot_description)
            d = datetime.now() + timedelta(days=30)
            EC2.create_tags(snapshot.id, {'Expires': d.strftime("%Y%m%d%H%M")})
            print "created snapshot {0} for device {1}".format(snapshot.id, device)
        except Exception, e:
            report_to_zabbix(True)

try:
    execute_hook(HOOKS, 'after')
except Exception, e:
    backup_failed(e)
else:
    report_to_zabbix(True)
