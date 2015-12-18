require 'spec_helper_acceptance'

describe 'vserver option' do
  it 'set a vserver option' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_vserver_option { 'flexscale.rewarm':
    ensure => 'present',
    value  => 'off',
  }
}
node 'vserver-01' {
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'set the option back' do
    pp=<<-EOS
node 'vsim-01' {
   netapp_vserver_option { 'flexscale.rewarm':
    ensure => 'present',
    value  => 'on',
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
