require 'spec_helper_acceptance'

describe 'iscsi' do
  it 'makes a iscsi' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_vserver { 'vserver-iscsi':
    ensure          => present,
    rootvol         => 'vserver_01_root',
    rootvolaggr     => 'aggr1',
    rootvolsecstyle => 'unix',
  }
}
node 'vserver-01' {  
}
node 'vserver-iscsi' {
  netapp_iscsi { 'vserver-iscsi':
    ensure       => 'present',
    state        => 'on',
    target_alias => 'vserver-iscsi',
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'edit a iscsi' do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
}
node 'vserver-iscsi' {
  netapp_iscsi { 'vserver-iscsi':
    ensure       => 'present',
    state        => 'off',
    target_alias => 'vserver-iscsi',
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'start a vserveriscsi' do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
}
node 'vserver-iscsi' {
  netapp_iscsi { 'vserver-iscsi':
    ensure       => 'present',
    state        => 'on',
    target_alias => 'vserver-iscsi',
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

 it 'delete a vserveriscsi' do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
}
node 'vserver-iscsi' {
  netapp_iscsi { 'vserver-iscsi':
    ensure       => 'absent',
    state        => 'off',
    target_alias => 'vserver-iscsi',
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
