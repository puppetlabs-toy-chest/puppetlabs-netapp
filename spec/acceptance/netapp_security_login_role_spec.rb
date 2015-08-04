require 'spec_helper_acceptance'

describe 'security_login_role' do
  it 'makes a security_login_role' do
    pp=<<-EOS
netapp_security_login_role { 'vserver:roller:vserver01':
  ensure       => 'present',
  access_level => 'none',
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'edit a security_login_role' do
    pp=<<-EOS
netapp_security_login_role { 'vserver:roller:vserver01':
  ensure       => 'present',
  access_level => 'all',
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

 it 'delete a security_login_role' do
    pp=<<-EOS
netapp_security_login_role { 'vserver:roller:vserver01':
  ensure       => 'absent',
  access_level => 'all',
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
