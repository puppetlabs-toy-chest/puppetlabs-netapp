require 'beaker-rspec'
require 'beaker-puppet_install_helper'

run_puppet_install_helper

RSpec.configure do |c|
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  c.before :suite do
    # Install module and dependencies
    copy_module_to(master, :source => proj_root, :module_name => 'netapp')
    device_conf=<<-EOS
[vsim-01.test.com]
type netapp
url https://vagrant:netapp123@vsim-01
[vserver-01.test.com]
type netapp
url https://vagrant:netapp123@vsim-01/vserver-01
EOS
    create_remote_file(master, File.join(master[:puppetpath], "device.conf"), device_conf)
    on master, puppet('plugin','download','--server',master.to_s)
    on master, puppet('device','-v','--waitforcert','0','--server',master.to_s), {:acceptable_exit_codes => [0,1] }
    on master, puppet('cert','sign','vsim-01.test.com'), {:acceptable_exit_codes => [0,24] }
    on master, puppet('device','-v','--waitforcert','0','--server',master.to_s), {:acceptable_exit_codes => [0,1] }
    on master, puppet('cert','sign','vserver-01.test.com'), {:acceptable_exit_codes => [0,24] }
    on master, puppet('device','-v','--waitforcert','0','--server',master.to_s), {:acceptable_exit_codes => [0,1] }
  end
end

def make_site_pp(pp, path = File.join(master['puppetpath'], 'manifests'))
  on master, "mkdir -p #{path}"
  create_remote_file(master, File.join(path, "site.pp"), pp)
  on master, "chown -R #{master['user']}:#{master['group']} #{path}"
  on master, "chmod -R 0755 #{path}"
  on master, "service #{master['puppetservice']} restart"
end

def run_device(options={:allow_changes => true})
  if options[:allow_changes] == false
    acceptable_exit_codes = 0
  else
    acceptable_exit_codes = [0,2]
  end
  on(master, puppet('device','--verbose','--color','false','--user','root','--trace','--server',master.to_s), { :acceptable_exit_codes => acceptable_exit_codes }) do |result|
    if options[:allow_changes] == false
      expect(result.stdout).to_not match(%r{^Notice: /Stage\[main\]})
    end
    expect(result.stderr).to_not match(%r{^Error:})
    expect(result.stderr).to_not match(%r{^Warning:})
  end
end

def run_resource_on(host, resource_type, resource_title=nil)
  options = {:ENV => {
    'FACTER_url' => "https://vagrant:netapp123@#{host}"
  } }
  if resource_title
    on(master, puppet('resource', resource_type, resource_title, '--trace', options), { :acceptable_exit_codes => 0 }).stdout
  else
    on(master, puppet('resource', resource_type, '--trace', options), { :acceptable_exit_codes => 0 }).stdout
  end
end
