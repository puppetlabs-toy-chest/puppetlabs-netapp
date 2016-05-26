require 'puppet/provider'
require 'puppet/util/network_device/netapp/device'

class Puppet::Provider::Netapp < Puppet::Provider

  attr_accessor :device
  LUN_RESIZE_ERROR_CODE = 9042 
  def self.transport
    if Facter.value(:url) then
      Puppet.debug "Puppet::Util::NetworkDevice::Netapp: connecting via facter url."
      @device ||= Puppet::Util::NetworkDevice::Netapp::Device.new(Facter.value(:url))
    else
      @device ||= Puppet::Util::NetworkDevice.current
      raise Puppet::Error, "Puppet::Util::NetworkDevice::Netapp: device not initialized #{caller.join("\n")}" unless @device
    end

    @tranport = @device.transport
  end

  def transport
    # this calls the class instance of self.transport instead of the object instance which causes an infinite loop.
    self.class.transport
  end

  # Helper function for simplifying the execution of NetApp API commands, in a similar fashion to the commands function.
  # Arguments should be a hash of 'command name' => 'api command'.
  def self.netapp_commands(command_specs)
    # This is basically stolen from Puppet::Provider#create_class_and_instance_method
    #
    #   A novice was trying to fix a broken lisp machine by turning the
    #   power off and on.  Knight, seeing what the student was doing spoke
    #   sternly- "You can not fix a machine by just power-cycling it with no
    #   understanding of what is going wrong."
    #     Knight turned the machine off and on.
    #       The machine worked.
    command_specs.each do |name, apicommand|
      if ! singleton_class.method_defined?(name)
        meta_def(name) do |*args|
          Puppet.debug("apicommand is a - #{apicommand.class}")
          if apicommand.is_a?(Hash) && apicommand[:iter]
            Puppet.debug("Got an iter request, for #{apicommand[:result_element]} element.")
            result = netapp_itterate(apicommand[:api], apicommand[:result_element])
          else
            Puppet.debug("Args array length = #{args.length}")
            if args.length == 1 and args[0].class == NaElement
              Puppet.debug("Executing invoke_elem with NaElement object.")
              result = transport.invoke_elem(args[0])
            else
              Puppet.debug("Executing api call #{[apicommand, args].flatten.join(' ')}")
              result = transport.invoke(apicommand, *args)
            end
            if result.results_status == 'failed'
              error = result.results_errno
              if error != LUN_RESIZE_ERROR_CODE.to_s
                raise Puppet::Error, "Executing api call #{[apicommand, args].flatten.join(' ')} failed: #{result.results_reason.inspect}"
              end
            end
          end

          # Return the results
          result
        end
      end
      if ! method_defined?(name)
        define_method(name) do |*args|
          self.class.send(name,*args)
        end
      end
    end
  end

  # Helper function for itterating over an itterative api call
  def self.netapp_itterate(api,result_element)
    Puppet.debug("Got to netapp_itterate. API = #{api}, result_element = #{result_element}")

    # Initial vars
    tag = ""
    results = []

    # Itterate over the api
    while !tag.nil?
      # Invoke api request
      Puppet.debug("Invoking: [#{api.inspect}, \"tag\", #{tag.inspect}]")
      output = transport.invoke(api, "tag", tag)
      if output.results_status == 'failed'
        raise Puppet::Error, "Executing api call #{[api,"tag",tag].flatten.join(' ')} failed: #{output.results_reason.inspect}"
      end

      # Check if any results were actually returned
      records_returned = output.child_get_int("num-records")
      if records_returned == 0
        Puppet.debug("No records returned on this call...")
        return
      end

      # Update tag
      tag = output.child_get_string("next-tag")

      # Get the result_element and push into results array
      element = output.child_get(result_element)
      results.push(*element.children_get())
    end

    # We're done itterating
    Puppet.debug("Finished itterating over api. Returning results")
    results
  end

  # Helper function to convert array into Netapp_element
  def netapp_array_to_element(element_name,field_name,values)
    Puppet.debug("Got to netapp_array_to_element. Element_name = #{element_name}, field_name = #{field_name}, values = #{values.inspect}.")

    # Create top-level element
    element = NaElement.new(element_name)

    # Itterate values and add to element
    values.each do |value|
      element.child_add_string(field_name, value)
    end

    Puppet.debug("Constructed element. Returning #{element.inspect}")
    element
  end

end
