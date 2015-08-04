require 'spec_helper_acceptance'

describe 'iscsi' do
  it 'makes a iscsi' do
    pp=<<-EOS
netapp_iscsi { 'vserveriscsi':
  ensure       => 'present',
  state        => 'on',
  target_alias => 'vserver01',
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'edit a iscsi' do
    pp=<<-EOS
netapp_iscsi { 'vserveriscsi':
  ensure       => 'present',
  state        => 'off',
  target_alias => 'vserver01',
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

 it 'delete a vserveriscsi' do
    pp=<<-EOS
netapp_iscsi { 'vserveriscsi':
  ensure       => 'absent',
  state        => 'on',
  target_alias => 'vserver01',
}
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
