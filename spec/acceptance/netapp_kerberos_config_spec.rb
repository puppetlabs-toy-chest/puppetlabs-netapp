require 'spec_helper_acceptance'

describe 'kerberos_config' do
  it 'makes a kerberos_config' do
    pp=<<-EOS
netapp_kerberos_config { 'vserver01_lif':
  ensure => 'present',
  is_kerberos_enabled => 'true',
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'edit a kerberos_config' do
    pp=<<-EOS
netapp_kerberos_config { 'vserver01_lif':
  ensure => 'present',
  is_kerberos_enabled => 'false',
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

 it 'delete a kerberos_config' do
    pp=<<-EOS
netapp_kerberos_config { 'vserver01_lif':
  ensure => 'absent',
  is_kerberos_enabled => 'false',
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
