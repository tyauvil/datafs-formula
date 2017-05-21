datafs-formula
==============

A SaltStack formula that handles the creation of a generic data system partition, useful for systems with large data requirements - e.g. database services. The default approach here is to create a /data partition with LVM, while providing multiple ways for creating the data partition on different physical devices - e.g. EC2 ephemeral, EC2 EBS, etc...

Available states
================

``datafs``
----------

Installs the required LVM packages and sets up the default assumptions made by
this formula.


``encryption``
----------
Sets up LUKS encryption on all devices that are under this formula's control. This state is included in ec2_ephemeral and ec2_ebs by default and does not need to be applied to the machine.


``ec2_ephemeral``
-----------------

Creates the /data partition on EC2 ephemeral disks.

``ec2_ebs``
-----------
Creates the /data partition with an ebs volumes that are given to this formula via the grains file.

``ec2_ebs_backup``
-----------
Creates a cron job that uses the python script and boto to create tagged backups with an expiration date of 30 days. The backup script itself can be called manually if needed at `/usr/local/sbin/ebs_backup.py`.


``ec2_ebs_restore``
-----------
Creates a restore script called `/usr/local/sbin/ebs_restore.py`. This script accepts a timestamp from the user and will stop and remount the lvm backup once the new volumes are created from the timestamped ebs snapshot. Hooks must be defined in the pillars or grains for a node. For example.

```
datafs:
  config:
    ebs:
      backup_hooks:
        before:
          - /tmp/pass.sh
        during:
          - /tmp/pass.sh
        after:
          - /tmp/pass.sh
       restore_hooks:
         before:
           - /tmp/restore.sh
         during:
           - /tmp/restore.sh
         after:
           - /tmp/restore.sh
```

EBS backup and restore hooks
================
It is sometimes necessary to do something before, during, and after a backup or restore is taking place. The backup and restore scripts


Pillar Format
================

```
datafs:
  config:
    encryption_pass: super_secret123
    encryption_key: |
```

* **encryption_pass** : Passphrase for LUKS device encryption
* **encryption_key**  : What will be put in the key-file on the system so the encrypted devices can be unlocked at boot.


Pillars Format
================

```
services:
  test:
    datafs:
      ebs:
        devices:
          - sdb
          - sdc
        mount_point: /data
```

* **devices**     : ebs devices attached to the instance that should be added to the LVM device
* **mount_point** : The mount point for the LVM volume created from the EBS devices. Defaults to /data

Testing
================

Since this formula has many AWS specific scripts serverspec will only pass by default if you bring this formula up in AWS. To do so you can execute the following command.

```
vagrant up --provider=aws
```

It is possible to test this formula with virtualbox, to do so you must edit the `.vagrant-salt/pillars` file to have the following content.

```
services:
  test:
    datafs:
      ebs:
        devices:
          - sdb
          - sdc
        mount_point: /data
```
