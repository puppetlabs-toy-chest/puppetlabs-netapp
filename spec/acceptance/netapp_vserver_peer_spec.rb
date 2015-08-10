require 'spec_helper_acceptance'

describe 'vserver_peer' do
  it 'makes a vserver_peer' do
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
  netapp_vserver { 'bs0':
    ensure          => present,
    rootvol         => 'bs0_root',
    rootvolaggr     => 'aggr1',
    rootvolsecstyle => 'unix',
  }
  netapp_vserver { 'bs4':
    ensure          => present,
    rootvol         => 'bs4_root',
    rootvolaggr     => 'aggr1',
    rootvolsecstyle => 'unix',
  }
  netapp_vserver_peer { 'bs0:bs4':
    ensure       => 'present',
    applications => ['snapmirror'],
    peer_cluster => 'VSIM',
  }
}
node 'vserver-01' {
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'edit a vserver_peer' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_vserver_peer { 'bs0:bs4':
    ensure       => 'present',
    applications => ['file_copy'],
  }
}
node 'vserver-01' {
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

 it 'delete a vserver_peer' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_vserver_peer { 'bs0:bs4':
    ensure       => 'absent',
    applications => ['snapmirror'],
    peer_cluster => 'VSIM',
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
