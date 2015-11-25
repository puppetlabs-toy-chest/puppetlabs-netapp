require 'spec_helper_acceptance'

describe 'kerberos_config' do
  it 'modify a kerberos_config' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_aggregate {'aggr1':
    ensure                    => 'present',
    blocktype                 => '64_bit',
    checksumstyle             => 'block',
    diskcount                 => '3',
    option_free_space_realloc => 'off',
    nodes                     => ['VSIM-01']
  }
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
  netapp_nfs { 'vserver-01':
    ensure => 'present',
    state  => 'on',
    v3     => 'enabled',
    v40    => 'disabled',
    v41    => 'disabled',
  }
  netapp_kerberos_config { 'nfs_lif':
    ensure                   => 'present',
    is_kerberos_enabled      => 'false',
    #it is not possible to test the following attributes in an automated fashion
    #is_kerberos_enabled     => 'true',
    #keytab_uri              => 'http://127.0.0.1',
    #service_principal_name  => 'nfs/sec.example.com@AUTH.SEC.EXAMPLE.COM',
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
