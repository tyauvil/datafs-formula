{%- from 'datafs/settings.sls' import datafs with context %}

include:
  - datafs
  - datafs.encryption

pvcreate_xvdb:
  lvm.pv_present:
    - name: /dev/mapper/xvdb

vgcreate:
  lvm.vg_present:
    - name: datavg
    - devices: /dev/mapper/xvdb

lvcreate:
  cmd.run:
    - name: lvcreate -l 100%FREE -n datalv datavg
    - unless: lvdisplay | grep -q datalv
    - user: root
    - creates: /etc/.salt_datalv_modified

{%- if salt['partition.exists']('/dev/xvdc') %}
/dev/mapper/xvdc:
  lvm.pv_present:
    - unless: pvdisplay | grep -q /dev/mapper/xvdc

vgextend_xvdc:
  cmd.run:
    - name: vgextend datavg /dev/mapper/xvdc
    - user: root
    - unless: pvdisplay | awk '/xvdc/{found=1}; /VG Name/ && found{print $3; exit}' | grep -q datavg
    - watch_in:
      - cmd: lvextend_ephemeral
{%- endif %}

lvextend_ephemeral:
  cmd.wait:
    - name: lvextend -l +100%FREE /dev/datavg/datalv
    - user: root

resize2fs_ephemeral:
  cmd.wait:
    - name: resize2fs /dev/datavg/datalv
    - user: root
    - onlyif: file -sL /dev/datavg/datalv | egrep -q 'ext.* filesystem'
    - watch:
      - cmd: lvextend_ephemeral

mkfs:
  cmd.run:
    - name: mkfs.{{ datafs.fstype }} /dev/datavg/datalv
    - unless: file -sL /dev/datavg/datalv | egrep -q 'ext.* filesystem'
    - user: root
    - creates: /etc/.salt_datalvfs_modified

mount:
  mount.mounted:
    - name: /data
    - device: /dev/datavg/datalv
    - fstype: {{ datafs.fstype }}
    - opts: defaults,auto,noatime,nobootwait
    - dump: 0
    - pass_num: 2
    - mkmnt: True
    - persist: True
    - user: root
