require_relative '../spec_helper_acceptance.rb'

describe "netapp_net_dns" do
  it 'makes a net DNS server' do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_net_dns {'vserver-01':
    domains => ["abc.com", "xyz.com"],
    state   => 'enabled',
    name_servers => '10.193.0.250'
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
  it "modify a net DNS server" do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_net_dns {'vserver-01':
    domains => ["wipro.com", "netapp.com"],
    state   => 'enabled',
    name_servers => ['10.193.0.150', '10.193.0.160']
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
