require 'spec_helper_acceptance'

describe 'snapmirror' do
  it 'makes a snapmirror' do
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
  netapp_vserver { 'vs0':
    ensure          => present,
    rootvol         => 'vs0_root',
    rootvolaggr     => 'aggr1',
    rootvolsecstyle => 'unix',
  }
  netapp_vserver { 'vs4':
      ensure          => present,
      rootvol         => 'vs4_root',
      rootvolaggr     => 'aggr1',
      rootvolsecstyle => 'unix',
    }
  netapp_vserver_peer { 'vs0:vs4':
    ensure       => 'present',
    applications => ['snapmirror'],
    peer_cluster => 'VSIM',
  }
  netapp_snapmirror { 'vs4:vs4_root':
    ensure            => 'present',
    max_transfer_rate => '0',
    relationship_type => 'data_protection',
    source_location   => 'vs0:vs0_root',
  }
}
node 'vserver-01' {
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'edit a snapmirror' do
    pp=<<-EOS
node 'vsim-01' {  
  netapp_snapmirror { 'vs4:vs4_root':
    ensure            => 'present',
    max_transfer_rate => '0',
    relationship_type => 'data_protection',
    source_location   => 'vs0:vs0_root',
  }
}
node 'vserver-01' {
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

 it 'delete a snapmirror' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_snapmirror { 'vs4:vs4_root':
    ensure            => 'absent',
    max_transfer_rate => '0',
    relationship_type => 'data_protection',
    source_location   => 'vs0:vs0_root',
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
