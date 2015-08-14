require 'spec_helper_acceptance'

describe 'export_policy' do
  it 'makes a export_policy' do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_export_policy { 'export_policy-test' :
    ensure => present,
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
