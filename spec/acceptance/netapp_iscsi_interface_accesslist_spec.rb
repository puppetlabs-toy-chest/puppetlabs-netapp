require 'spec_helper_acceptance'

describe 'iscsi_interface_accesslist' do
  it 'makes a iscsi_interface_accesslist' do
    pp=<<-EOS
netapp_iscsi { 'vserver01':
  ensure       => 'present',
  state        => 'on',
  target_alias => 'vserver01',
}
netapp_lif { 'iscsilif':
  ensure               => 'present',
  address              => '1.1.1.1',
  administrativestatus => 'up',
  comment              => '-',
  dataprotocols        => ['iscsi'],
  dnsdomainname        => 'none',
  failoverpolicy       => 'disabled',
  homenode             => 'VSIM-01',
  homeport             => 'e0a',
  isautorevert         => 'false',
  netmask              => '255.255.255.0',
  routinggroupname     => 'd1.1.1.0/24',
}
netapp_iscsi_interface_accesslist { 'iscsilif/iqn.1995-08.com.example:string':
  ensure => 'present',
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

 it 'delete a iscsi_interface_accesslist' do
    pp=<<-EOS
netapp_iscsi_interface_accesslist { 'iscsilif/iqn.1995-08.com.example:string':
  ensure => 'absent',
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
