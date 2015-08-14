require 'spec_helper_acceptance'

describe 'volume' do
#  it 'makes a volume' do
#    pp=<<-EOS
#node 'vsim-01' {
#}
#node 'vserver-01' {
#  netapp_volume {'volumename':
#    aggregate => 'aggr1',
#    ensure => present,
#  }
#}
#    EOS
#    make_site_pp(pp)
#    run_device(:allow_changes => true)
#    run_device(:allow_changes => false)
#  end
#
#  it 'deletes a volume' do
#    pp=<<-EOS
#node 'vsim-01' {
#}
#node 'vserver-01' {
#  netapp_volume {'volumename':
#    aggregate => 'aggr1',
#    ensure => absent,
#  }
#}
#    EOS
#    make_site_pp(pp)
#    run_device(:allow_changes => true)
#    run_device(:allow_changes => false)
#  end
#
  it 'makes a volume offline and delete' do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_volume {'vol_offline':
    aggregate => 'aggr1',
    state  => 'offline',
    ensure => present,
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)

    pp2=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_volume {'vol_offline':
    aggregate => 'aggr1',
    state  => 'offline',
    ensure => absent,
  }
}
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
