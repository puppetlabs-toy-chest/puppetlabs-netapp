#!/usr/bin/env ruby

source "https://rubygems.org"


gem 'rake'

group :test do
  gem 'puppet'
  gem 'rspec-puppet', '>=1.0.1'
  gem 'puppetlabs_spec_helper', '~>0.4.0'
  gem 'puppet-lint'
  gem 'puppet-syntax'
  gem 'librarian-puppet'
  gem 'beaker-rspec'
  gem 'beaker-puppet_install_helper'
  gem 'simplecov', :require => false, :platforms => [:ruby_19, :ruby_20]
  #gem 'pry'
  #gem 'pry-byebug'
  #if ENV.key?('TEAMCITY_VERSION')
  #  gem 'simplecov-teamcity-summary', :require => false, :platforms => [:ruby_19, :ruby_20]
  #end
end
