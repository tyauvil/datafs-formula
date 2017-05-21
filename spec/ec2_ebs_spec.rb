require_relative 'spec_helper'

describe lvm_volume('ebslv') do
  it { should exist }
  it { should be_available }
  it { should have_segments '2' }
end
