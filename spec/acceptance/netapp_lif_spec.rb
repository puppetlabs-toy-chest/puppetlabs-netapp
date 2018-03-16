require 'spec_helper_acceptance'

describe 'netapp_lif' do
  it 'makes a netapp_lif' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_lif { 'vserver-01_liftest' :
    ensure         => present,
    homeport       => 'e0c',
    homenode       => 'VSIM-01',
    address        => '192.168.0.1',
    vserver        => 'vserver-01',
    netmask        => '255.255.255.0',
    firewallpolicy => 'mgmt',
    dataprotocols  => ['nfs'],
  }
}
node 'vserver-01' {
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'modifies a netapp_lif' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_lif { 'vserver-01_liftest' :
    ensure         => present,
    homeport       => 'e0c',
    homenode       => 'VSIM-01',
    address        => '192.168.0.2',
    vserver        => 'vserver-01',
    netmask        => '255.255.255.0',
    firewallpolicy => 'mgmt',
    dataprotocols  => ['nfs'],
  }
}
node 'vserver-01' {
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'deletes a netapp_lif' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_lif { 'vserver-01_liftest' :
    ensure         => absent,
    homeport       => 'e0c',
    homenode       => 'VSIM-01',
    address        => '192.168.0.2',
    vserver        => 'vserver-01',
    netmask        => '255.255.255.0',
    firewallpolicy => 'mgmt',
    dataprotocols  => ['nfs'],
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
