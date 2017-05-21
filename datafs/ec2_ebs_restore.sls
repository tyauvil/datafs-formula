{%- from 'datafs/settings.sls' import datafs with context -%}
/usr/local/sbin/ebs_hooks.py:
  file.managed:
    - source: salt://datafs/files/ebs_hooks.py
    - mode: 700
    - owner: root
    - group: root

/usr/local/sbin/ebs_restore.py:
  file.managed:
    - source: salt://datafs/templates/ebs_restore.py
    - template: jinja
    - mode: 700
    - owner: root
    - group: root
