require 'spec_helper_acceptance'

describe 'security_login' do
  it 'makes a security_login' do
    pp=<<-EOS
netapp_security_login {'ontapi:password:cat:VSIM':
  ensure      => present,
  role_name   => 'admin',
  comment     => 'adiasdasdasdadasd',
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'edit a security_login' do
    pp=<<-EOS
netapp_security_login {'ontapi:password:cat:VSIM':
  ensure      => present,
  role_name   => 'admin',
  comment     => 'comment',
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

#lock a login

#change a password

 it 'delete a security_login' do
    pp=<<-EOS
netapp_security_login {'ontapi:password:cat:VSIM':
  ensure      => present,
  role_name   => 'admin',
  comment     => 'comment',
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
