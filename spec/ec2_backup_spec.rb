require_relative 'spec_helper'

describe file('/usr/local/sbin/ebs_backup.py') do
  it { should be_file }
  it { should be_grouped_into 'root' }
  it { should be_owned_by 'root' }
  it { should be_mode 700 }
  its(:content) { should match /BACKUP_TYPE = 'base-datafs-vagrant'/}
end

describe file('/usr/local/sbin/ebs_restore.py') do
  it { should be_file }
  it { should be_grouped_into 'root' }
  it { should be_owned_by 'root' }
  it { should be_mode 700 }
  its(:content) { should match /BACKUP_TYPE = 'base-datafs-vagrant'/}
end

describe file('/usr/local/sbin/ebs_hooks.py') do
  it { should be_file }
  it { should be_grouped_into 'root' }
  it { should be_owned_by 'root' }
  it { should be_mode 700 }
end
