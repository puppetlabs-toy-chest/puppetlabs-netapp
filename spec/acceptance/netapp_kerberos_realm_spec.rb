require 'spec_helper_acceptance'

describe 'kerberos_realm' do
  it 'makes a kerberos_realm' do
    pp=<<-EOS
netapp_kerberos_realm { 'kerberosrealm1':
  ensure               => 'present',
  admin_server_ip      => '2.2.2.2',
  admin_server_port    => '749',
  clock_skew           => '5',
  kdc_ip               => '2.2.2.2',
  kdc_port             => '88',
  kdc_vendor           => 'other',
  password_server_ip   => '2.2.2.2',
  password_server_port => '464',
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'edit a kerberos_realm' do
    pp=<<-EOS
netapp_kerberos_realm { 'kerberosrealm1':
  ensure               => 'present',
  admin_server_ip      => '2.2.2.2',
  admin_server_port    => '749',
  clock_skew           => '5',
  kdc_ip               => '2.2.2.2',
  kdc_port             => '88',
  kdc_vendor           => 'other',
  password_server_ip   => '2.2.2.2',
  password_server_port => '464',
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

 it 'delete a kerberos_realm' do
    pp=<<-EOS
netapp_kerberos_realm { 'kerberosrealm1':
  ensure               => 'absent',
  admin_server_ip      => '2.2.2.2',
  admin_server_port    => '749',
  clock_skew           => '5',
  kdc_ip               => '2.2.2.2',
  kdc_port             => '88',
  kdc_vendor           => 'other',
  password_server_ip   => '2.2.2.2',
  password_server_port => '464',
}

    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
