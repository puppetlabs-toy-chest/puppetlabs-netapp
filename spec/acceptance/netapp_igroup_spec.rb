require 'spec_helper_acceptance'

describe 'igroup' do
  it 'makes a igroup' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_vserver { 'vserver-01':
    ensure          => present,
    rootvol         => 'vserver_01_root',
    rootvolaggr     => 'aggr1',
    rootvolsecstyle => 'unix',
  }
}
node 'vserver-01' {
  netapp_igroup { 'test_igroup':
    ensure     => 'present',
    group_type => 'mixed',
    os_type    => 'linux',
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'adds initiator to an igroup' do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_igroup { 'test_igroup':
    ensure     => 'present',
    group_type => 'mixed',
    os_type    => 'linux',
    members    => ['eui.0123456789abcdef'],
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'removes initiator from an igroup' do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_igroup { 'test_igroup':
    ensure     => 'present',
    group_type => 'mixed',
    os_type    => 'linux',
    members    => [],
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'binds an igroup to a portset' do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_igroup { 'test_igroup':
    ensure     => 'present',
    group_type => 'mixed',
    os_type    => 'linux',
    portset    => 'wipro_portset'
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'unbind an igroup from a portset' do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_igroup { 'test_igroup':
    ensure     => 'present',
    group_type => 'mixed',
    os_type    => 'linux',
    portset    => 'false'
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'deletes an igroup' do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_igroup { 'test_igroup':
    ensure     => 'absent',
    group_type => 'mixed',
    os_type    => 'linux',
    portset    => 'false',
    force      => 'true',
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

end
