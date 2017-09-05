require_relative '../spec_helper_acceptance.rb'

describe "cifs" do
  it 'make a cifs server' do
    pp=<<-EOS
node "vsim-01"{
}
node "vserver-01" {
  netapp_cifs { 'WIPRO_CIFS':
    domain         => 'NTAP.LOCAL',
    admin_username => 'Administrator',
    admin_password => 'P@ssw0rd21',
    ensure         => 'present'
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
  end
  it 'delete a cifs server' do
    pp=<<-EOS
node "vsim-01"{
}
node "vserver-01" {
  netapp_cifs { 'WIPRO_CIFS':
    domain         => 'NTAP.LOCAL',
    admin_username => 'Administrator',
    admin_password => 'P@ssw0rd21',
    ensure         => 'absent'
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
