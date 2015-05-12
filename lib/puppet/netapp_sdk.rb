# hax: add lib/puppet/netapp_sdk to RUBYLIB
$:.unshift File.join(File.dirname(__FILE__), 'netapp_sdk')
require 'NaServer'
