require 'spec_helper_acceptance'

describe 'vserver' do
  it 'makes a vserver' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_vserver { 'test_vserver':
    ensure          => present,
    rootvol         => 'test_vserver_root',
    rootvolaggr     => 'aggr1',
    rootvolsecstyle => 'unix',
    comment         => 'hey',
    ipspace         => 'Default',
  }
}
node 'vserver-01' {
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'edit a vserver' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_vserver { 'test_vserver':
    ensure  => 'present',
    comment => 'new comment',
  }
}
node 'vserver-01' {
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'stop a vserver' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_vserver { 'test_vserver':
    ensure  => 'present',
    comment => 'new comment',
    state   => 'stopped',
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
