require 'spec_helper_acceptance'

describe 'aggregate' do
  it 'makes an aggregate' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_aggregate {'aggr3':
    ensure => 'present',
    blocktype => '64_bit',
    checksumstyle => 'block',
    diskcount => '3',
    option_free_space_realloc => 'off',
    nodes => ['VSIM-01']
  }
}
node 'vserver-01' {
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'set an option on an aggregate' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_aggregate {'aggr3':
    ensure => 'present',
    blocktype => '64_bit',
    checksumstyle => 'block',
    diskcount => '3',
    option_free_space_realloc => 'on',
    nodes => ['VSIM-01']
  }
}
node 'vserver-01' {
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'deletes an aggregate' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_aggregate {'aggr3':
    ensure => 'absent',
    blocktype => '64_bit',
    checksumstyle => 'block',
    diskcount => '3',
    nodes => ['VSIM-01']
  }
}
node 'vserver-01' {
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

end
