require_relative '../spec_helper_acceptance.rb'

describe "system_node_autosupport" do
  it "modify autosupport configuration" do
    pp=<<-EOS
node 'vsim-01' {
  netapp_system_node_autosupport{'vsim-01':
    periodic_tx_window => '1h'
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
