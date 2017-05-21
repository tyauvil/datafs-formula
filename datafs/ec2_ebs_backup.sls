{%- from 'datafs/settings.sls' import datafs with context -%}

include:
  - datafs.ec2_ebs_restore

/usr/local/sbin/ebs_backup.py:
  file.managed:
    - source: salt://datafs/templates/ebs_backup.py
    - template: jinja
    - mode: 700
    - owner: root
    - group: root
  cron.present:
    - user: root
    - minute: random
    - hour: 23
    - identifier: ebs_backup
    - require:
      - file: /usr/local/sbin/ebs_backup.py
