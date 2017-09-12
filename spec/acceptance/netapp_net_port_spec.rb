require_relative '../spec_helper_acceptance.rb'

describe "net_port" do
  it "modify a port" do
    pp=<<-EOS
node 'vsim-01' {
  netapp_net_port{'vsim-01@e0a':
    flowcontrol_admin => 'none'
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
