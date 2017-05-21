/mnt:
  mount.unmounted:
    - persist: True
    - device: /dev/xvdb
    - user: root

lvm_pkgs:
  pkg.installed:
    - name: lvm2

create_data_dir:
  file.directory:
    - name: /data
    - user: root
    - group: root
    - dir_mode: 755
    - unless: file /data &>/dev/null
    - creates: /etc/.salt_data_dir_modified
