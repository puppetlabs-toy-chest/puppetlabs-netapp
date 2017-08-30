require_relative '../spec_helper_acceptance.rb'

describe "storage_array" do
  it "modify a storage array" do
    pp=<<-EOS
node 'vsim-01' {
  netapp_storage_array{ 'VMware_Virtualdisk_1':
    max_queue_depth => '256'
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
