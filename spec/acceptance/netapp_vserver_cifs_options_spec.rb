require_relative '../spec_helper_acceptance.rb'

describe "vserver_cifs_options" do
  it "modify vserver cifs options" do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_vserver_cifs_options {'vserver-01':
    max_mpx => '512',
    smb2_enabled => 'true'
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
