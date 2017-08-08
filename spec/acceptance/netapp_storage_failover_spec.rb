require_relative '../spec_helper_acceptance.rb'

describe "storage_failover" do
  it "modify storage failover" do
    pp=<<-EOS
node 'vsim-01' {
  netapp_storage_failover{'vsim-01':
    auto_giveback => 'false',
    auto_giveback_after_panic => 'false',
    auto_giveback_override_vetoes => 'false'
  }
}
node "vserver-01" {
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
