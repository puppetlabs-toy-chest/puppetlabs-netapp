require 'spec_helper_acceptance'

describe 'ldap_config' do
  it 'makes a ldap_config' do
    pp=<<-EOS
netapp_ldap_config { 'ldapclient2':
  ensure => 'present',
  client_enabled => 'true',
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'edit a ldap_config' do
    pp=<<-EOS
netapp_ldap_config { 'ldapclient2':
  ensure => 'present',
  client_enabled => 'false',
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

 it 'delete a ldap_config' do
    pp=<<-EOS
netapp_ldap_config { 'ldapclient2':
  ensure => 'absent',
  client_enabled => 'false',
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
