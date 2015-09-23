require 'spec_helper_acceptance'

describe 'security_login_role' do
  it 'makes a security_login_role' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_vserver { 'vserver-01':
    ensure          => present,
    rootvol         => 'vserver_01_root',
    rootvolaggr     => 'aggr1',
    rootvolsecstyle => 'unix',
  }
  netapp_lif { 'nfs_lif':
    ensure        => present,
    homeport      => 'e0c',
    homenode      => 'VSIM-01',
    address       => '10.0.207.5',
    vserver       => 'vserver-01',
    netmask       => '255.255.255.0',
    dataprotocols => ['nfs','cifs'],
  }
  netapp_lif { 'iscsi_lif':
    ensure        => present,
    homeport      => 'e0c',
    homenode      => 'VSIM-01',
    address       => '10.0.207.6',
    vserver       => 'vserver-01',
    netmask       => '255.255.255.0',
    dataprotocols => 'iscsi',
  }
  netapp_security_login_role { 'vserver:roller:vserver-01':
    ensure       => 'present',
  }
}
node 'vserver-01' {
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'edit a security_login_role' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_security_login_role { 'vserver:roller:vserver-01':
    ensure       => 'present',
    access_level => 'all',
  }
}
node 'vserver-01' {
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

 it 'delete a security_login_role' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_security_login_role { 'vserver:roller:vserver-01':
    ensure       => 'absent',
    access_level => 'all',
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
