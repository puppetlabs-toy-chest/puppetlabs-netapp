require_relative '../spec_helper_acceptance.rb'

describe "nfs" do
  it "make a nfs server" do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_nfs {'vserver-01':
    ensure                   => 'present',
    v3                       => 'enabled',
    v40                      => 'disabled',
    v41                      => 'disabled',
    enable_ejukebox          => 'true',
    auth_sys_extended_groups => 'disabled'
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
  it "modify a nfs server" do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_nfs {'vserver-01':
    enable_ejukebox          => 'false',
    auth_sys_extended_groups => 'enabled'
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
  it "delete a nfs server" do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_nfs {'vserver-01':
    ensure => 'absent'
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
