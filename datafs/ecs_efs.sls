{%- from 'datafs/settings.sls' import datafs with context %}

include:
  - datafs

nfs-common:
  pkg.installed: []

/efs:
  mount.mounted:
    - device: {{ grains['az'] }}.{{ datafs.efs_fs }}.efs.{{ grains['region'] }}.amazonaws.com:/
    - opts: vers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2
    - fstype: nfs4
    - mkmnt: True
