require 'spec_helper_acceptance'

describe 'netapp_license' do
# it is not possible to test a secret license key in a public test
#  it 'add a netapp_license' do
#    pp=<<-EOS
#node 'vsim-01' {
#  netapp_license { 'snaprestore' :
#    ensure => present,
#    codes  => "saiufbaisubfiuasbfiuabs",
#  }
#}
#node 'vserver-01' {
#}
#    EOS
#    make_site_pp(pp)
#    run_device(:allow_changes => true)
#    run_device(:allow_changes => false)
#  end
#
#  it 'deletes a netapp_license' do
#    pp=<<-EOS
#node 'vsim-01' {
#  netapp_license { 'snaprestore' :
#    ensure => absent,
#    codes  => "saiufbaisubfiuasbfiuabs",
#  }
#}
#node 'vserver-01' {
#}
#    EOS
#    make_site_pp(pp)
#    run_device(:allow_changes => true)
#    run_device(:allow_changes => false)
#  end
end
