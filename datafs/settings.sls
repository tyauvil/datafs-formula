{% set service = grains.get('service') %}
{% set p       = pillar.get('datafs', {}) %}
{% set pc      = p.get('config', {}) %}
{% set pcebs   = pc.get('ebs', {}) %}

{% set config = salt['pillar.get']('datafs', {}) %}

{% set ebs_config = config.get('ebs', {}) %}
{% set ebs_devices = ebs_config.get('devices',[]) %}

{%- set datafs = {} %}
{%- do datafs.update( {
  'devices'           : salt['pillar.get']('datafs:ebs:devices',[]),
  'mount_point'       : config.get('mount_point', '/data'),
  'fstype'            : config.get('fstype','ext4'),
  'encryption_key'    : pc.get('encryption_key','abc123zxy'),
  'encryption_pass'   : pc.get('encryption_pass','foobarbazz'),
  'retention_days'    : ebs_config.get('retention_days', '7'),
  'backup_aws_key'    : pcebs.get('backup_aws_key',    'NO_KEY_PROVIDED'),
  'backup_aws_secret' : pcebs.get('backup_aws_secret', 'NO_SECRET_PROVIDED'),
  'backup_devices'    : ebs_config.get('backup_devices', ebs_config.get('devices',[])),
  'restore_hooks'     : ebs_config.get('restore_hooks', {}),
  'backup_hooks'      : ebs_config.get('backup_hooks', {}),
  'efs_fs'            : p.get('efs_fs', 'abc123zxy')
}) %}
