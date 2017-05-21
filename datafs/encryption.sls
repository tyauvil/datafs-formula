{%- from 'datafs/settings.sls' import datafs with context %}

/root/.cryptfs_keyfile:
  file.managed:
    - user: root
    - group: root
    - mode: 400
    - contents_pillar: datafs:config:encryption_key

{% set all_devices = ['xvdb','xvdc'] + datafs.devices %}
{% for device in all_devices %}
{% if salt['partition.exists']('/dev/' + device) %}

encrypt_{{ device }}:
  cmd.run:
    - name: echo "{{ datafs.encryption_pass }}" | cryptsetup luksFormat /dev/{{ device }}
    - unless: cryptsetup luksDump /dev/{{ device }}
    - user: root
    - group: root
    - shell: /bin/bash
    - requires:
      - file: /root/.cryptfs_keyfile


add_key_{{ device }}:
  cmd.wait:
    - name: echo "{{ datafs.encryption_pass }}" | cryptsetup luksAddKey /dev/{{ device }} /root/.cryptfs_keyfile
    - user: root
    - group: root
    - shell: /bin/bash
    - watch:
      - file: /root/.cryptfs_keyfile
    - requires:
      - file: /root/.cryptfs_keyfile
      - cmd: encrypt_{{ device }}

open_encrypted_{{ device }}:
  cmd.run:
    - name:  echo "{{ datafs.encryption_pass }}" | cryptsetup open --type luks /dev/{{ device }} {{ device }}
    - creates: /dev/mapper/{{ device }}
    - user: root
    - group: root
    - shell: /bin/bash
    - require:
      - cmd: add_key_{{ device }}

{% endif %}
{% endfor %}

/etc/crypttab:
  file.managed:
    - template: jinja
    - source: salt://datafs/templates/crypttab
    - owner: root
    - group: root
    - mode:  400
