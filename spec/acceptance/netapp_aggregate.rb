require 'spec_helper_acceptance'

describe 'snapmirror' do
  it 'makes a snapmirror' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_aggregate {'aggr3':
    ensure => 'present',
    blocktype => '64_bit',
    checksumstyle => 'block',
    diskcount => '1',
    nodes => ['VSIM-01']
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
