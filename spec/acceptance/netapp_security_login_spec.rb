require 'spec_helper_acceptance'

describe 'security_login' do
  it 'makes a security_login' do
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
  netapp_security_login {'ontapi:password:cat:VSIM':
    ensure      => present,
    role_name   => 'admin',
    password    => 'sadasd1G!',
    comment     => 'adiasdasdasdadasd',
  }
}
node 'vserver-01' {
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'edit a security_login' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_security_login {'ontapi:password:cat:VSIM':
    ensure      => present,
    role_name   => 'admin',
    comment     => 'comment2',
  }
}
node 'vserver-01' {
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

#lock a login

#change a password

 it 'delete a security_login' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_security_login {'ontapi:password:cat:VSIM':
    ensure      => absent,
    role_name   => 'admin',
    comment     => 'comment',
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
