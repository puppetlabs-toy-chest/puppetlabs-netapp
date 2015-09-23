require 'spec_helper_acceptance'

describe 'lun' do
  it 'makes a lun' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_volume { 'stuff':
    ensure       => 'present',
    autosize     => 'off',
    exportpolicy => 'default',
    initsize     => '20m',
    junctionpath => 'false',
    snapreserve  => '5',
    state        => 'online',
  }
}
node 'vserver-01' {
  netapp_lun { '/vol/stuff/lun1':
    ensure => 'present',
    size   => '4194304',
    state  => 'online',
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'delete a lun' do
    pp=<<-EOS
node 'vsim-01' {
  netapp_volume { 'stuff':
    ensure       => 'present',
    autosize     => 'off',
    exportpolicy => 'default',
    initsize     => '20m',
    junctionpath => 'false',
    snapreserve  => '5',
    state        => 'online',
  }
}
node 'vserver-01' {
  netapp_lun { '/vol/stuff/lun1':
    ensure => 'absent',
    size   => '4194308',
    state  => 'online',
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

end
