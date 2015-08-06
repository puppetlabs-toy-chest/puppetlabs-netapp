require 'spec_helper_acceptance'

describe 'kerberos_config' do
  it 'makes a kerberos_config' do
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
}
node 'vserver-01' {
  netapp_kerberos_config { 'vserver01_lif':
    ensure => 'present',
    is_kerberos_enabled => 'true',
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'edit a kerberos_config' do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_kerberos_config { 'vserver01_lif':
    ensure => 'present',
    is_kerberos_enabled => 'false',
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

 it 'delete a kerberos_config' do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_kerberos_config { 'vserver01_lif':
    ensure => 'absent',
    is_kerberos_enabled => 'false',
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
