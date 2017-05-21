{%- from 'datafs/settings.sls' import datafs with context -%}
#!/usr/bin/env python
# THIS FILE IS MANAGED BY SALT DO NOT CHANGE
"""Script to mount an ebs backup and manage lvm in case the backup consists
of multiple ebs volumes"""

import boto.ec2
import os
import time
import stat
from ebs_hooks import execute_shell_command, execute_hook

HOOKS = {{datafs.restore_hooks}}

BACKUP_TYPE = '{{ grains.env }}-{{ grains.server_type }}'
BACKUP_DEVICES = {{datafs.backup_devices}}
DEVICE_TIMEOUT = 300


def is_block_device(filename):
    """Returns true if filename is a block device"""
    try:
        mode = os.lstat(filename).st_mode
    except OSError:
        return False
    else:
        return stat.S_ISBLK(mode)


def wait_for_block_device(block_device):
    """Waits for a block device to become avaliable to the system"""
    elapsed = 0
    timestep = 10
    while elapsed < DEVICE_TIMEOUT:
        time.sleep(timestep)
        elapsed += 10
        if is_block_device(block_device):
            break
        if elapsed >= DEVICE_TIMEOUT:
            quit("Block device {0} was not ready in time".format(device))


def wait_for_volume(ebs_volume, state):
    """Waits for an ebs volume to reach a certain state"""
    elapsed = 0
    timestep = 10
    while elapsed < DEVICE_TIMEOUT:
        time.sleep(timestep)
        elapsed += 10
        ebs_volume.update()
        if ebs_volume.status == state:
            break
        if elapsed >= DEVICE_TIMEOUT:
            quit("Timeout when waiting for volume {0} to be in state {1}.".format(
                ebs_volume.id, state))

EC2 = boto.ec2.connect_to_region('us-east-1',
                                 aws_access_key_id='{{ datafs.backup_aws_key }}',
                                 aws_secret_access_key='{{ datafs.backup_aws_secret }}')

TIMESTAMP = raw_input('Enter timestamp of backup to restore:')
INSTANCE = boto.utils.get_instance_metadata()['instance-id']
DESCRIPTION = "{0}_{1}".format(BACKUP_TYPE, TIMESTAMP)

try:
    execute_hook(HOOKS, 'before')
    OLD_VOLUMES = EC2.get_all_volumes(
        filters={'attachment.instance-id': INSTANCE})
except Exception, e:
    quit(e.error_message)

execute_shell_command(['umount /data'])
execute_shell_command(['vgchange -an'])

execute_hook(HOOKS, 'during')

for volume in OLD_VOLUMES:
    device = volume.attach_data.device.split('/')[-1]
    snapshot_description = "{0}_{1}".format(DESCRIPTION, device)
    if device in BACKUP_DEVICES:
        try:
            snapshot = EC2.get_all_snapshots(
                filters={'description': snapshot_description})[0]
            new_volume = EC2.create_volume(
                volume.size, volume.zone, snapshot.id, volume.type)
            volume.detach()
            wait_for_volume(volume, 'available')
            volume.delete()
            new_volume.attach(instance_id=INSTANCE,
                              device="/dev/{0}".format(device))
            wait_for_volume(new_volume, 'in-use')
            print "Attached new volume {0} to device {1}".format(new_volume.id, device)
        except Exception, e:
            quit(e.error_message)


for device in BACKUP_DEVICES:
    wait_for_block_device("/dev/{0}".format(device))


execute_shell_command(['pvscan'])
execute_shell_command(['mount /dev/ebsvg/ebslv /data'])

execute_hook(HOOKS, 'after')
