
require 'puppet/property'

class Puppet::Property::NetappTruthy < Puppet::Property
  def self.truthy_property(desc=nil, trueval=true, falseval=false)
    options = [:true, :false]
    desc "#{desc or 'Undocumented attribute.'}
    Valid options: <#{options.join('|')}>"

    validate do |value|
      unless options.include?(value.to_s.to_sym)
        raise ArgumentError, "#{name} must be one of: #{options.join(', ')}."
      end
    end
    munge do |value|
      case value.to_s.to_sym
      when :true, :enabled, :yes, :ENABLED, :YES, :ON, :on
        trueval
      when :false, :disabled, :no, :DISABLED, :NO, :OFF, :off
        falseval
      end
    end
  end
end
