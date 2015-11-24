require 'spec_helper_acceptance'

describe 'cluster identity' do
  it 'modify netapp_cluster_id' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_cluster_id { 'VSIM':
    ensure   => 'present',
    contact  => 'bill',
    location => 'france',
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
