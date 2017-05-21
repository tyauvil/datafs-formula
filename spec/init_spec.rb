# for serverspec documentation: http://serverspec.org/
require_relative 'spec_helper'

pkgs = ['lvm2']

pkgs.each do |pkg|
  describe package("#{pkg}") do
    it { should be_installed }
  end
end

describe file('/data') do
  it { should be_directory }
  it { should be_mode 755 }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_readable }
end
