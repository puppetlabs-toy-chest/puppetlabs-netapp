require 'spec_helper_acceptance'

describe 'netapp_sis_policy' do
  it 'edit a netapp_sis_policy' do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_sis_policy { 'default':
    ensure       => 'present',
    comment      => 'Default policy',
    enabled      => 'true',
    qos_policy   => 'best_effort',
    type         => 'threshold',
    changelog_threshold_percent => '10',
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end


end
