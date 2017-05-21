{%- from 'datafs/settings.sls' import datafs with context %}

{% if grains['oscodename'] == 'trusty' %}
include:
  - datafs
  {% if salt['partition.exists']('/dev/mapper/{}'.format(datafs.devices[0])) %}
  - datafs.encryption
  {% endif %}

ebsvg:
  lvm.vg_present:
    {% if salt['partition.exists']('/dev/mapper/{}'.format(datafs.devices[0])) %}
    - devices: /dev/mapper/{{ datafs.devices|first }}
    {% else %}
    - devices: /dev/{{ datafs.devices|first }}
    {% endif %}

ebs_lvcreate:
  cmd.run:
    - name: lvcreate -l 100%FREE -n ebslv ebsvg
    - unless: lvdisplay | grep -q ebslv
    - user: root
    - creates: /etc/.salt_datalv_modified

{% for device in datafs.devices %}
{% if salt['partition.exists']('/dev/mapper/{}'.format(device)) %}
/dev/mapper/{{ device }}:
  lvm.pv_present:
    - unless: pvdisplay | grep -q {{ device }}

vgextend_{{ device }}:
  cmd.run:
    - name: vgextend ebsvg /dev/mapper/{{ device }}
    - user: root
    - unless: pvdisplay | awk '/{{ device }}/{found=1}; /VG Name/ && found{print $3; exit}' | grep -q ebsvg
    - watch_in:
      - cmd: lvextend
{% else %}
/dev/{{ device }}:
  lvm.pv_present:
    - unless: pvdisplay | grep -q {{ device }}

vgextend_{{ device }}:
  cmd.run:
    - name: vgextend ebsvg /dev/{{ device }}
    - user: root
    - unless: pvdisplay | awk '/{{ device }}/{found=1}; /VG Name/ && found{print $3; exit}' | grep -q ebsvg
    - watch_in:
      - cmd: lvextend

{% endif %}
{% endfor %}

lvextend:
  cmd.wait:
    - name: lvextend -l +100%FREE /dev/ebsvg/ebslv
    - user: root

resize2fs:
  cmd.wait:
    - name: resize2fs /dev/ebsvg/ebslv
    - user: root
    - onlyif: file -sL /dev/ebsvg/ebslv | egrep -q 'ext.* filesystem'
    - watch:
      - cmd: lvextend

ebs_mkfs:
  cmd.run:
    - name: mkfs.{{ datafs.fstype }} /dev/ebsvg/ebslv
    - unless: file -sL /dev/ebsvg/ebslv | egrep -q 'ext.* filesystem'
    - user: root
    - creates: /etc/.salt_datalvfs_modified

ebs_mount:
  mount.mounted:
    - name: {{ datafs.mount_point }}
    - device: /dev/ebsvg/ebslv
    - fstype: {{ datafs.fstype }}
    - opts: defaults,auto,noatime,nobootwait
    - dump: 0
    - pass_num: 2
    - mkmnt: True
    - persist: True
    - user: root
{% endif %}

{% if grains['oscodename'] == 'xenial' %}
include:
  - datafs

{% for device in datafs.devices %}
/dev/{{ device }}:
  lvm.pv_present: []
{% endfor %}

ebsvg:
  lvm.vg_present:
    {%- if datafs.devices|length() > 1 %}
    - devices: /dev/{{ datafs.devices|join(',/dev/') }}
    {%- else %}
    - devices: /dev/{{ datafs.devices|first }}
    {% endif %}

ebslv:
  lvm.lv_present:
    - vgname: ebsvg
    - extents: "100%FREE"
    - require:
      - lvm: ebsvg

/dev/mapper/ebsvg-ebslv:
  blockdev.formatted:
    - fs_type: {{ datafs.fstype }}
    - require:
      - lvm: ebslv

{{ datafs.mount_point }}:
  mount.mounted:
    - device: /dev/mapper/ebsvg-ebslv
    - fstype: {{ datafs.fstype }}
    - mkmnt: True
    - opts: defaults,auto,noatime,nofail
    - require:
      - blockdev: /dev/mapper/ebsvg-ebslv
{% endif %}
