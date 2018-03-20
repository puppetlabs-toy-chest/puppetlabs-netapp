require 'spec_helper_acceptance'

describe 'lun' do
  it 'makes a lun' do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_volume { 'stuff':
    ensure       => 'present',
    autosize     => 'off',
    exportpolicy => 'default',
    initsize     => '20m',
    junctionpath => 'false',
    snapreserve  => '5',
    state        => 'online',
    aggregate    => 'aggr_new'
  }
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

  it 'resize a lun' do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_volume { 'stuff':
    ensure       => 'present',
    autosize     => 'off',
    exportpolicy => 'default',
    initsize     => '10m',
    junctionpath => 'false',
    snapreserve  => '5',
    state        => 'online',
    aggregate    => 'aggr_new'
  }
  netapp_lun { '/vol/stuff/lun1':
    ensure => 'present',
    size   => '6291456',
    state  => 'online',
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'offline a lun' do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_volume { 'stuff':
    ensure       => 'present',
    autosize     => 'off',
    exportpolicy => 'default',
    initsize     => '20m',
    junctionpath => 'false',
    snapreserve  => '5',
    state        => 'online',
    aggregate    => 'aggr_new'
  }
  netapp_lun { '/vol/stuff/lun1':
    ensure => 'present',
    size   => '6291456',
    state  => 'offline',
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'online a lun' do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_volume { 'stuff':
    ensure       => 'present',
    autosize     => 'off',
    exportpolicy => 'default',
    initsize     => '20m',
    junctionpath => 'false',
    snapreserve  => '5',
    state        => 'online',
    aggregate    => 'aggr_new'
  }
  netapp_lun { '/vol/stuff/lun1':
    ensure => 'present',
    size   => '6291456',
    state  => 'online',
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'deletes a lun' do
    pp=<<-EOS
node 'vsim-01' {
}
node 'vserver-01' {
  netapp_volume { 'stuff':
    ensure       => 'present',
    autosize     => 'off',
    exportpolicy => 'default',
    initsize     => '20m',
    junctionpath => 'false',
    snapreserve  => '5',
    state        => 'online',
    aggregate    => 'aggr_new'
  }
  netapp_lun { '/vol/stuff/lun1':
    ensure => 'absent',
    size   => '6291456',
    state  => 'online',
  }
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

end
