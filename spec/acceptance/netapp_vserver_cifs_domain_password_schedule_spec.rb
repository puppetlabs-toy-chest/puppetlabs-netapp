require_relative '../spec_helper_acceptance.rb'

describe "vserver_cifs_domain_password_schedule" do
  it "modify cifs domain password schedule" do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_vserver_cifs_domain_password_schedule {'vserver-01':
   schedule_randomized_minute => '100'
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
